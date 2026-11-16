import 'dart:convert';

import 'package:bishop/bishop.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/constants/supabase_schema.dart';
import 'package:zetzy/core/utils/avatar_compressor.dart';
import 'package:zetzy/data/models/feedback_entry.dart';
import 'package:zetzy/data/models/game_record.dart';
import 'package:zetzy/data/models/stats_summary.dart';
import 'package:zetzy/data/models/user_profile.dart';
import 'package:zetzy/data/remote/supabase_config_loader_stub.dart'
    if (dart.library.io) 'package:zetzy/data/remote/supabase_config_loader_io.dart';
import 'package:zetzy/features/games/chess/chess_matchmaking.dart';

/// Thrown when optional matchmaking SQL tables/RPCs have not yet been applied
/// in the connected Supabase project so callers can fall back cleanly.
class SupabaseMissingSchemaException implements Exception {
  const SupabaseMissingSchemaException();
}

/// Wraps Supabase Auth, PostgREST, Storage, RPCs, and Realtime Chess channels.
/// Falls back cleanly when `SUPABASE_URL` / `SUPABASE_ANON_KEY` are unset.
class SupabaseService {
  bool _initialized = false;

  bool get isAvailable => _initialized;

  SupabaseClient? get _client => isAvailable ? Supabase.instance.client : null;

  Future<void> initialize() async {
    if (_initialized) return;

    var url = SupabaseConfig.normalizeUrl(SupabaseConfig.url);
    var anonKey = SupabaseConfig.anonKey.trim();

    if (url.isEmpty || anonKey.isEmpty) {
      final devConfig = loadDevSupabaseConfig();
      if (devConfig != null) {
        url = devConfig.url;
        anonKey = devConfig.anonKey;
      }
    }

    if (url.isEmpty || anonKey.isEmpty) return;

    try {
      await Supabase.initialize(
        url: url,
        publishableKey: anonKey,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('Supabase init skipped: $e');
    }
  }

  User? get currentAuthUser => _client?.auth.currentUser;

  Future<UserProfile?> fetchCurrentProfile() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return null;

    final data = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (data == null) return null;
    return UserProfile.fromSupabase(data);
  }

  Future<UserProfile> register({
    required String username,
    required String password,
    String? recoveryPhrase,
  }) async {
    final client = _requireClient();
    final email = ValidationRules.dummyEmailFor(username);
    final res = await client.auth.signUp(email: email, password: password);
    final user = res.user;
    if (user == null) {
      throw StateError('Registration did not return a user.');
    }
    if (res.session == null) {
      throw StateError(
        'Registration succeeded, but no active session was created. '
        'Ensure "Confirm email" is disabled in Supabase Auth settings.',
      );
    }

    final recoveryHash = (recoveryPhrase != null && recoveryPhrase.isNotEmpty)
        ? _hashPhrase(recoveryPhrase)
        : null;

    await client.from('profiles').upsert({
      'id': user.id,
      'username': username,
      'recovery_hash': recoveryHash,
      'chess_elo': 1000,
      'unlocked_levels': {
        for (final g in GameType.values)
          g.id: DifficultyLevel.defaultUnlockedLevel,
      },
    });

    await _enforceSingleActiveSession();
    return (await fetchCurrentProfile()) ??
        UserProfile(id: user.id, username: username, isGuest: false);
  }

  Future<UserProfile> signIn({
    required String username,
    required String password,
  }) async {
    final client = _requireClient();
    final email = ValidationRules.dummyEmailFor(username);
    await client.auth.signInWithPassword(email: email, password: password);
    await _enforceSingleActiveSession();
    return (await fetchCurrentProfile()) ??
        UserProfile(
          id: client.auth.currentUser!.id,
          username: username,
          isGuest: false,
        );
  }

  /// PRD 17B: Log out any other active sessions on other devices.
  Future<void> _enforceSingleActiveSession() async {
    try {
      await _client?.auth.signOut(scope: SignOutScope.others);
    } catch (e) {
      debugPrint('Single session enforcement skipped: $e');
    }
  }

  Future<void> signOut() async {
    await _client?.auth.signOut();
  }

  /// PRD 14B: Update display username in `public.profiles`.
  Future<void> updateUsername(String newUsername) async {
    final client = _requireClient();
    final uid = client.auth.currentUser!.id;
    await client
        .from('profiles')
        .update({
          'username': newUsername,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', uid);
  }

  /// PRD 13B: Verify old password first, then update password.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final client = _requireClient();
    final email = client.auth.currentUser?.email;
    if (email == null) throw StateError('No active user session.');

    await client.auth.signInWithPassword(email: email, password: oldPassword);
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// PRD 16B: Enable or disable hashed recovery phrase.
  Future<void> setRecoveryPhrase(String? phrase) async {
    final client = _requireClient();
    final uid = client.auth.currentUser!.id;
    await client
        .from('profiles')
        .update({
          'recovery_hash':
              (phrase == null || phrase.isEmpty) ? null : _hashPhrase(phrase),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', uid);
  }

  /// PRD 16B: Reset forgotten password without email via RPC.
  Future<bool> resetPasswordWithRecovery({
    required String username,
    required String recoveryPhrase,
    required String newPassword,
  }) async {
    final client = _requireClient();
    final result = await client.rpc(
      'reset_password_with_recovery',
      params: {
        'p_username': username,
        'p_recovery_phrase': recoveryPhrase,
        'p_new_password': newPassword,
      },
    );
    return result == true;
  }

  /// PRD 15C: Compress image to 256x256 PNG and upload to `avatars` bucket.
  Future<String> uploadAvatar(Uint8List rawBytes) async {
    final client = _requireClient();
    final uid = client.auth.currentUser!.id;
    final compressed = await compute(
      AvatarCompressor.compressTo256Png,
      rawBytes,
    );
    if (compressed == null) {
      throw ArgumentError('Unsupported image format.');
    }

    final objectPath = '$uid/avatar.png';
    await client.storage
        .from('avatars')
        .uploadBinary(
          objectPath,
          compressed,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/png',
          ),
        );

    final publicUrl =
        '${client.storage.from('avatars').getPublicUrl(objectPath)}'
        '?t=${DateTime.now().millisecondsSinceEpoch}';

    await client
        .from('profiles')
        .update({'avatar_url': publicUrl})
        .eq('id', uid);
    return publicUrl;
  }

  Future<void> updateProgression({
    required Map<GameType, int> unlockedLevels,
    int? chessElo,
  }) async {
    final client = _client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return;

    final payload = <String, dynamic>{
      'unlocked_levels': {
        for (final entry in unlockedLevels.entries) entry.key.id: entry.value,
      },
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (chessElo != null) {
      payload['chess_elo'] = chessElo;
    }
    await client.from('profiles').update(payload).eq('id', uid);
  }

  Future<void> uploadGameRecord(GameRecord record) async {
    final client = _requireClient();
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not authenticated.');

    await client.from('game_records').insert({
      'id': record.id,
      'user_id': uid,
      'game_type': record.gameType.id,
      'difficulty': record.difficulty,
      'is_won': record.isWon,
      'score': record.score,
      'duration_ms': record.durationMs < 3000 ? 3000 : record.durationMs,
      'platform': record.platform,
      'metadata': record.metadata,
      'played_at': record.playedAt.toIso8601String(),
    });
  }

  Future<List<GameRecord>> _queryLeaderboardRecords({
    required GameType gameType,
    required int difficulty,
    String? userId,
    required bool sortByScoreFirst,
    required int limit,
    required int offset,
  }) async {
    final client = _client;
    if (client == null || limit <= 0) return [];

    var query = client
        .from('game_records')
        .select('*, profiles(username, avatar_url)')
        .eq('game_type', gameType.id)
        .eq('difficulty', difficulty);

    if (userId != null) {
      query = query.eq('user_id', userId);
    }
    if (gameType != GameType.snake) {
      query = query.eq('is_won', true);
    }

    final ordered = sortByScoreFirst
        ? query
              .order('score', ascending: false)
              .order('duration_ms', ascending: true)
        : query
              .order('duration_ms', ascending: true)
              .order('score', ascending: false);

    final rows = await ordered
        .order('id', ascending: true)
        .range(offset, offset + limit - 1);

    return (rows as List)
        .map((e) => GameRecord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<GameRecord>> fetchGlobalLeaderboard({
    required GameType gameType,
    required int difficulty,
    int limit = 20,
    int offset = 0,
  }) => _queryLeaderboardRecords(
    gameType: gameType,
    difficulty: difficulty,
    sortByScoreFirst: true,
    limit: limit,
    offset: offset,
  );

  /// Fetches the signed-in user's personal best records from `game_records`
  /// so "My Best" stays synced across devices without duplicating match rows
  /// inside `profiles.account_data`.
  Future<List<GameRecord>> fetchMyBestRecords({
    required String userId,
    required GameType gameType,
    required int difficulty,
    int limit = 20,
    int offset = 0,
  }) => _queryLeaderboardRecords(
    gameType: gameType,
    difficulty: difficulty,
    userId: userId,
    sortByScoreFirst: gameType == GameType.snake || gameType == GameType.chess,
    limit: limit,
    offset: offset,
  );

  Future<List<UserProfile>> fetchChessEloLeaderboard({
    int limit = 20,
    int offset = 0,
  }) async {
    final client = _client;
    if (client == null || limit <= 0) return [];

    final rows = await client
        .from('profiles')
        .select()
        .order('chess_elo', ascending: false)
        .order('id', ascending: true)
        .range(offset, offset + limit - 1);

    return (rows as List)
        .map(
          (e) => UserProfile.fromSupabase(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<void> resetRemoteStats() async {
    final client = _client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return;
    await client.from('game_records').delete().eq('user_id', uid);
    Map<String, dynamic> currentData = {};
    try {
      final existing = await client
          .from('profiles')
          .select('account_data')
          .eq('id', uid)
          .maybeSingle();
      if (existing != null && existing['account_data'] is Map) {
        currentData = Map<String, dynamic>.from(existing['account_data'] as Map);
      }
    } catch (_) {}
    currentData['stats'] = StatsSummary.empty.toJson();
    await client
        .from('profiles')
        .update({
          'chess_elo': 1000,
          'unlocked_levels': {
            for (final g in GameType.values)
              g.id: DifficultyLevel.defaultUnlockedLevel,
          },
          'account_data': currentData,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', uid);
  }

  /// Syncs profile settings &/or statistics summary inside `profiles.account_data`.
  Future<Map<String, dynamic>?> updateAccountData({
    Map<String, dynamic>? settingsJson,
    StatsSummary? statsSummary,
    Map<String, dynamic>? baseAccountData,
  }) async {
    final client = _client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return null;

    final nextData = Map<String, dynamic>.from(baseAccountData ?? const {});
    if (nextData.isEmpty) {
      try {
        final existing = await client
            .from('profiles')
            .select('account_data')
            .eq('id', uid)
            .maybeSingle();
        if (existing != null && existing['account_data'] is Map) {
          nextData.addAll(
            Map<String, dynamic>.from(existing['account_data'] as Map),
          );
        }
      } catch (_) {}
    }

    if (settingsJson != null) {
      nextData['settings'] = settingsJson;
    }
    if (statsSummary != null) {
      nextData['stats'] = statsSummary.toJson();
    }

    await client
        .from('profiles')
        .update({
          'account_data': nextData,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', uid);
    return nextData;
  }

  Future<void> _cleanupExpiredFeedbacks() async {
    final client = _client;
    if (client == null) return;
    try {
      await client.rpc('cleanup_expired_feedbacks');
    } catch (_) {}
  }

  /// Fetches the authenticated player's own feedback items (newest first).
  Future<List<FeedbackEntry>> fetchMyFeedbacks() async {
    final client = _client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return const [];

    await _cleanupExpiredFeedbacks();
    final rows = await client
        .from('feedbacks')
        .select('*, profiles!feedbacks_user_id_fkey(username, avatar_url)')
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((e) => FeedbackEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((entry) => !entry.isExpired())
        .toList();
  }

  /// Admin-only paginated feedback inbox (20 items per page, newest first).
  Future<List<FeedbackEntry>> fetchAllFeedbacks({
    int limit = 20,
    int offset = 0,
  }) async {
    final client = _client;
    if (client == null || client.auth.currentUser == null || limit <= 0) {
      return const [];
    }

    await _cleanupExpiredFeedbacks();
    final rows = await client
        .from('feedbacks')
        .select('*, profiles!feedbacks_user_id_fkey(username, avatar_url)')
        .order('created_at', ascending: false)
        .order('id', ascending: true)
        .range(offset, offset + limit - 1);

    return (rows as List)
        .map((e) => FeedbackEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((entry) => !entry.isExpired())
        .toList();
  }

  Future<FeedbackEntry> createFeedback({
    required String message,
    required String appVersion,
  }) async {
    final client = _requireClient();
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not authenticated.');

    final inserted = await client
        .from('feedbacks')
        .insert({
          'user_id': uid,
          'message': message.trim(),
          'app_version': appVersion.trim().isEmpty ? '0.0.0' : appVersion.trim(),
        })
        .select('*, profiles!feedbacks_user_id_fkey(username, avatar_url)')
        .single();
    return FeedbackEntry.fromJson(Map<String, dynamic>.from(inserted));
  }

  Future<FeedbackEntry> updateFeedbackMessage({
    required String feedbackId,
    required String message,
  }) async {
    final client = _requireClient();
    final updated = await client
        .from('feedbacks')
        .update({
          'message': message.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', feedbackId)
        .select('*, profiles!feedbacks_user_id_fkey(username, avatar_url)')
        .single();
    return FeedbackEntry.fromJson(Map<String, dynamic>.from(updated));
  }

  Future<void> deleteFeedback(String feedbackId) async {
    final client = _requireClient();
    await client.from('feedbacks').delete().eq('id', feedbackId);
  }

  /// Admin one-time review (`approved` / `rejected`) with optional single reply.
  Future<FeedbackEntry> reviewFeedback({
    required String feedbackId,
    required FeedbackStatus decision,
    String? adminReply,
  }) async {
    assert(decision.isResolved, 'Admin decision must be approved or rejected');
    final client = _requireClient();
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not authenticated.');
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final trimmedReply = adminReply?.trim();

    final updated = await client
        .from('feedbacks')
        .update({
          'status': decision.id,
          'admin_reply':
              (trimmedReply == null || trimmedReply.isEmpty) ? null : trimmedReply,
          'reviewed_by': uid,
          'reviewed_at': nowIso,
          'updated_at': nowIso,
        })
        .eq('id', feedbackId)
        .select('*, profiles!feedbacks_user_id_fkey(username, avatar_url)')
        .single();
    return FeedbackEntry.fromJson(Map<String, dynamic>.from(updated));
  }

  Future<void> deleteAccount() async {
    final client = _requireClient();
    await client.rpc('delete_own_account');
    await client.auth.signOut();
  }

  /// Creates a Supabase Realtime channel for Online Chess room codes.
  RealtimeChannel? createChessRoomChannel(
    String roomCode, {
    String presenceKey = '',
  }) {
    final client = _client;
    if (client == null) return null;
    return client.channel(
      'chess_room_$roomCode',
      opts: RealtimeChannelConfig(
        self: false,
        key: presenceKey,
        enabled: presenceKey.isNotEmpty,
      ),
    );
  }

  /// Creates a Supabase Realtime Presence channel for Random Chess matchmaking.
  RealtimeChannel? createChessMatchmakingChannel(
    String timeControlName, {
    String presenceKey = '',
  }) {
    final client = _client;
    if (client == null) return null;
    return client.channel(
      'chess_mm_queue_$timeControlName',
      opts: RealtimeChannelConfig(
        self: false,
        key: presenceKey,
        enabled: true,
      ),
    );
  }

  /// Calls the atomic Postgres matchmaking RPC when deployed in Supabase.
  Future<MatchAssignment?> matchmakeChess({
    required String timeControlName,
    int? searchRadius,
    int waitSeconds = 0,
  }) async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) return null;

    try {
      final raw = await client.rpc(
        'matchmake_chess',
        params: {
          'p_time_control': timeControlName,
          'p_search_radius': searchRadius,
          'p_wait_seconds': waitSeconds,
        },
      );
      Map<String, dynamic>? row;
      if (raw is Map) {
        row = Map<String, dynamic>.from(raw);
      } else if (raw is List && raw.isNotEmpty && raw.first is Map) {
        row = Map<String, dynamic>.from(raw.first as Map);
      }
      if (row == null || row['status'] != 'matched') return null;

      final colorRaw = row['assigned_color']?.toString().toLowerCase();
      final assignedColor =
          (colorRaw == 'b' || colorRaw == 'black' || colorRaw == '1')
          ? Bishop.black
          : Bishop.white;

      return MatchAssignment(
        matchId: row['match_id']?.toString(),
        roomCode: (row['room_code'] ?? '').toString(),
        assignedColor: assignedColor,
        opponentUserId: (row['opponent_id'] ?? '').toString(),
        opponentUsername: (row['opponent_username'] ?? 'opponent').toString(),
        opponentAvatarUrl: row['opponent_avatar_url'] as String?,
        opponentElo: (row['opponent_elo'] as num?)?.toInt() ?? 1000,
        timeControlName: timeControlName,
        viaServerRpc: true,
      );
    } on PostgrestException catch (e) {
      if (_isMissingSchemaError(e)) {
        throw const SupabaseMissingSchemaException();
      }
      rethrow;
    }
  }

  Future<void> cancelChessMatchmaking() async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) return;
    try {
      await client.rpc('cancel_chess_matchmaking');
    } on PostgrestException catch (e) {
      if (_isMissingSchemaError(e)) return;
      rethrow;
    }
  }

  /// Settles a completed ranked Find Match game atomically on Postgres when RPC exists.
  Future<({int newElo, int eloDelta, String status})?> finishRankedChessMatch({
    required String matchId,
    required int? winnerColour,
    required bool isDraw,
    required int moveCount,
    required String pgn,
  }) async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) return null;
    try {
      final raw = await client.rpc(
        'finish_ranked_chess_match',
        params: {
          'p_match_id': matchId,
          'p_winner_colour': winnerColour,
          'p_is_draw': isDraw,
          'p_move_count': moveCount,
          'p_pgn': pgn,
        },
      );
      Map<String, dynamic>? row;
      if (raw is Map) {
        row = Map<String, dynamic>.from(raw);
      } else if (raw is List && raw.isNotEmpty && raw.first is Map) {
        row = Map<String, dynamic>.from(raw.first as Map);
      }
      if (row == null) return null;
      return (
        newElo: (row['new_elo'] as num?)?.toInt() ?? 1000,
        eloDelta: (row['elo_delta'] as num?)?.toInt() ?? 0,
        status: (row['status'] ?? 'finished').toString(),
      );
    } on PostgrestException catch (e) {
      if (_isMissingSchemaError(e)) return null;
      rethrow;
    }
  }

  bool _isMissingSchemaError(PostgrestException e) {
    final code = (e.code ?? '').toUpperCase();
    final msg = e.message.toLowerCase();
    return code == 'PGRST202' ||
        code == '42883' ||
        code == '42P01' ||
        msg.contains('could not find the function') ||
        msg.contains('does not exist');
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError(
        'Supabase is not configured. Pass SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
    return client;
  }

  String _hashPhrase(String phrase) {
    final bytes = utf8.encode(phrase.trim());
    return sha256.convert(bytes).toString();
  }
}
