import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/constants/supabase_schema.dart';
import 'package:zetzy/core/utils/avatar_compressor.dart';
import 'package:zetzy/data/models/game_record.dart';
import 'package:zetzy/data/models/user_profile.dart';

/// Wraps Supabase Auth, PostgREST, Storage, RPCs, and Realtime Chess channels.
/// Falls back cleanly when `SUPABASE_URL` / `SUPABASE_ANON_KEY` are unset.
class SupabaseService {
  bool _initialized = false;

  bool get isAvailable => _initialized && SupabaseConfig.isConfigured;

  SupabaseClient? get _client => isAvailable ? Supabase.instance.client : null;

  Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured || _initialized) return;
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
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
    final compressed = AvatarCompressor.compressTo256Png(rawBytes);
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

  Future<List<GameRecord>> fetchGlobalLeaderboard({
    required GameType gameType,
    required int difficulty,
  }) async {
    final client = _client;
    if (client == null) return [];

    var query = client
        .from('game_records')
        .select('*, profiles(username, avatar_url)')
        .eq('game_type', gameType.id)
        .eq('difficulty', difficulty);

    if (gameType != GameType.snake) {
      query = query.eq('is_won', true);
    }

    final rows = await query
        .order('score', ascending: false)
        .order('duration_ms', ascending: true)
        .limit(100);

    return (rows as List)
        .map((e) => GameRecord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<UserProfile>> fetchChessEloLeaderboard() async {
    final client = _client;
    if (client == null) return [];

    final rows = await client
        .from('profiles')
        .select()
        .order('chess_elo', ascending: false)
        .limit(100);

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
    await client
        .from('profiles')
        .update({
          'chess_elo': 1000,
          'unlocked_levels': {
            for (final g in GameType.values)
              g.id: DifficultyLevel.defaultUnlockedLevel,
          },
        })
        .eq('id', uid);
  }

  Future<void> deleteAccount() async {
    final client = _requireClient();
    await client.rpc('delete_own_account');
    await client.auth.signOut();
  }

  /// Creates a Supabase Realtime channel for Online Chess room codes.
  RealtimeChannel? createChessRoomChannel(String roomCode) {
    final client = _client;
    if (client == null) return null;
    return client.channel(
      'chess_room_$roomCode',
      opts: const RealtimeChannelConfig(self: false),
    );
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
