import 'dart:async';
import 'dart:math';

import 'package:bishop/bishop.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zetzy/data/models/user_profile.dart';
import 'package:zetzy/data/remote/supabase_service.dart';

/// Describes a discrete ELO search expansion step in Chess matchmaking.
@immutable
class MatchmakingTier {
  const MatchmakingTier({
    required this.stage,
    required this.minWaitSec,
    required this.radius,
  });

  final int stage;
  final int minWaitSec;
  final int? radius; // null => nearest available across [400..3500]
}

@immutable
class MatchSearchTicket {
  const MatchSearchTicket({
    required this.userId,
    required this.username,
    required this.chessElo,
    required this.timeControlName,
    required this.waitSeconds,
    this.avatarUrl,
  });

  final String userId;
  final String username;
  final int chessElo;
  final String timeControlName;
  final int waitSeconds;
  final String? avatarUrl;
}

@immutable
class MatchCandidate {
  const MatchCandidate({
    required this.userId,
    required this.username,
    required this.chessElo,
    required this.timeControlName,
    required this.waitSeconds,
    this.avatarUrl,
  });

  final String userId;
  final String username;
  final int chessElo;
  final String timeControlName;
  final int waitSeconds;
  final String? avatarUrl;
}

@immutable
class MatchAssignment {
  const MatchAssignment({
    required this.roomCode,
    required this.assignedColor,
    required this.opponentUserId,
    required this.opponentUsername,
    required this.opponentElo,
    required this.timeControlName,
    required this.viaServerRpc,
    this.matchId,
    this.opponentAvatarUrl,
  });

  final String? matchId;
  final String roomCode;
  final int assignedColor; // Bishop.white or Bishop.black
  final String opponentUserId;
  final String opponentUsername;
  final String? opponentAvatarUrl;
  final int opponentElo;
  final String timeControlName;
  final bool viaServerRpc;
}

@immutable
class MatchWindowSnapshot {
  const MatchWindowSnapshot({
    required this.minElo,
    required this.maxElo,
    required this.isUnbounded,
    required this.radius,
    required this.stage,
    required this.totalStages,
  });

  final int minElo;
  final int maxElo;
  final bool isUnbounded;
  final int? radius;
  final int stage;
  final int totalStages;
}

/// Pure, deterministic expanding-range ELO matchmaking logic.
abstract final class ChessMatchmakingEngine {
  static const int minEloBound = 400;
  static const int maxEloBound = 3500;
  static const int softAcceptWaitSec = 16;

  static const List<MatchmakingTier> tiers = [
    MatchmakingTier(stage: 1, minWaitSec: 0, radius: 50),
    MatchmakingTier(stage: 2, minWaitSec: 8, radius: 120),
    MatchmakingTier(stage: 3, minWaitSec: 16, radius: 250),
    MatchmakingTier(stage: 4, minWaitSec: 25, radius: 500),
    MatchmakingTier(stage: 5, minWaitSec: 35, radius: 1000),
    MatchmakingTier(stage: 6, minWaitSec: 45, radius: null),
  ];

  static MatchmakingTier tierForWaitSeconds(int waitSeconds) {
    final safeWait = max(0, waitSeconds);
    var active = tiers.first;
    for (final tier in tiers) {
      if (safeWait >= tier.minWaitSec) {
        active = tier;
      }
    }
    return active;
  }

  static MatchWindowSnapshot windowFor({
    required int myElo,
    required int waitSeconds,
  }) {
    final clampedElo = myElo.clamp(minEloBound, maxEloBound);
    final tier = tierForWaitSeconds(waitSeconds);
    final radius = tier.radius;
    if (radius == null) {
      return MatchWindowSnapshot(
        minElo: minEloBound,
        maxElo: maxEloBound,
        isUnbounded: true,
        radius: null,
        stage: tier.stage,
        totalStages: tiers.length,
      );
    }
    return MatchWindowSnapshot(
      minElo: (clampedElo - radius).clamp(minEloBound, maxEloBound),
      maxElo: (clampedElo + radius).clamp(minEloBound, maxEloBound),
      isUnbounded: false,
      radius: radius,
      stage: tier.stage,
      totalStages: tiers.length,
    );
  }

  static bool areCompatible({
    required MatchCandidate a,
    required MatchCandidate b,
  }) {
    if (a.userId.isEmpty || b.userId.isEmpty || a.userId == b.userId) {
      return false;
    }
    if (a.timeControlName != b.timeControlName) {
      return false;
    }

    final diff = (a.chessElo - b.chessElo).abs();
    final radiusA = tierForWaitSeconds(a.waitSeconds).radius;
    final radiusB = tierForWaitSeconds(b.waitSeconds).radius;

    if (radiusA == null && radiusB == null) {
      return true;
    }
    if (radiusA == null) {
      return b.waitSeconds >= softAcceptWaitSec || diff <= radiusB!;
    }
    if (radiusB == null) {
      return a.waitSeconds >= softAcceptWaitSec || diff <= radiusA;
    }
    return diff <= radiusA && diff <= radiusB;
  }

  /// Picks the closest ELO opponent among compatible waiting candidates.
  static MatchCandidate? selectBestOpponent({
    required MatchSearchTicket me,
    required List<MatchCandidate> candidates,
  }) {
    final meCandidate = MatchCandidate(
      userId: me.userId,
      username: me.username,
      avatarUrl: me.avatarUrl,
      chessElo: me.chessElo,
      timeControlName: me.timeControlName,
      waitSeconds: me.waitSeconds,
    );

    final compatible = candidates
        .where((c) => areCompatible(a: meCandidate, b: c))
        .toList();
    if (compatible.isEmpty) return null;

    compatible.sort((a, b) {
      final diffA = (a.chessElo - me.chessElo).abs();
      final diffB = (b.chessElo - me.chessElo).abs();
      final diffCmp = diffA.compareTo(diffB);
      if (diffCmp != 0) return diffCmp;
      final waitCmp = b.waitSeconds.compareTo(a.waitSeconds);
      if (waitCmp != 0) return waitCmp;
      return a.userId.compareTo(b.userId);
    });
    return compatible.first;
  }
}

@immutable
class ChessMatchmakingState {
  const ChessMatchmakingState({
    required this.isSearching,
    required this.myElo,
    required this.waitSeconds,
    required this.window,
    required this.timeControlName,
    this.usingRealtimeFallback = false,
    this.errorMessage,
  });

  factory ChessMatchmakingState.idle({int myElo = 1000}) {
    return ChessMatchmakingState(
      isSearching: false,
      myElo: myElo,
      waitSeconds: 0,
      window: ChessMatchmakingEngine.windowFor(myElo: myElo, waitSeconds: 0),
      timeControlName: 'blitz5',
    );
  }

  final bool isSearching;
  final int myElo;
  final int waitSeconds;
  final MatchWindowSnapshot window;
  final String timeControlName;
  final bool usingRealtimeFallback;
  final String? errorMessage;

  ChessMatchmakingState copyWith({
    bool? isSearching,
    int? myElo,
    int? waitSeconds,
    MatchWindowSnapshot? window,
    String? timeControlName,
    bool? usingRealtimeFallback,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChessMatchmakingState(
      isSearching: isSearching ?? this.isSearching,
      myElo: myElo ?? this.myElo,
      waitSeconds: waitSeconds ?? this.waitSeconds,
      window: window ?? this.window,
      timeControlName: timeControlName ?? this.timeControlName,
      usingRealtimeFallback:
          usingRealtimeFallback ?? this.usingRealtimeFallback,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Manages live expanding-window Chess matchmaking via Postgres RPC with
/// automatic fallback to Supabase Realtime Presence lobby when SQL RPCs are
/// not yet deployed.
class ChessMatchmakingSession extends ChangeNotifier {
  ChessMatchmakingSession({
    required this._supabase,
    required this.onMatched,
  });

  final SupabaseService _supabase;
  final void Function(MatchAssignment assignment) onMatched;

  ChessMatchmakingState _state = ChessMatchmakingState.idle();
  ChessMatchmakingState get state => _state;

  Timer? _tickTimer;
  Timer? _pollTimer;
  RealtimeChannel? _lobbyChannel;
  UserProfile? _profile;
  DateTime? _startedAtUtc;
  int _waitSeconds = 0;
  bool _rpcPollInFlight = false;
  bool _useRealtimeFallback = false;
  bool _disposed = false;
  int _searchGen = 0;

  String? _pendingOfferTarget;
  String? _pendingOfferRoom;
  int? _pendingOfferHostColor;
  DateTime? _pendingOfferSentAt;

  Future<void> startSearch({
    required UserProfile profile,
    required String timeControlName,
  }) async {
    await cancelSearch();
    if (_disposed) return;

    final gen = ++_searchGen;
    _profile = profile;
    _startedAtUtc = DateTime.now().toUtc();
    _waitSeconds = 0;
    _useRealtimeFallback = false;
    _pendingOfferTarget = null;
    _pendingOfferRoom = null;
    _pendingOfferHostColor = null;
    _pendingOfferSentAt = null;

    _state = ChessMatchmakingState(
      isSearching: true,
      myElo: profile.chessElo,
      waitSeconds: 0,
      window: ChessMatchmakingEngine.windowFor(
        myElo: profile.chessElo,
        waitSeconds: 0,
      ),
      timeControlName: timeControlName,
    );
    notifyListeners();

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed || !_state.isSearching || _searchGen != gen) return;
      _waitSeconds = max(timer.tick, _wallClockWaitSeconds());
      final elapsed = _waitSeconds;
      _state = _state.copyWith(
        waitSeconds: elapsed,
        window: ChessMatchmakingEngine.windowFor(
          myElo: _state.myElo,
          waitSeconds: elapsed,
        ),
      );
      notifyListeners();

      if (_useRealtimeFallback) {
        _evaluatePresenceCandidates(gen);
      }
    });

    await _pollRpcOrSwitchToFallback(gen);
    if (_disposed || !_state.isSearching || _searchGen != gen) return;

    if (!_useRealtimeFallback) {
      _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _pollRpcOrSwitchToFallback(gen);
      });
    }
  }

  Future<void> cancelSearch() async {
    _searchGen++;
    _stopTimers();
    final wasRpc = _state.isSearching && !_useRealtimeFallback;
    await _leaveLobbyChannel();

    if (!_disposed) {
      _state = ChessMatchmakingState.idle(myElo: _state.myElo);
      notifyListeners();
    }

    if (wasRpc) {
      try {
        await _supabase.cancelChessMatchmaking();
      } catch (_) {
        // Ignore cleanup errors when cancelling.
      }
    }
  }

  int _wallClockWaitSeconds() {
    final started = _startedAtUtc;
    if (started == null) return 0;
    return max(0, DateTime.now().toUtc().difference(started).inSeconds);
  }

  int _currentWaitSeconds() => max(_waitSeconds, _wallClockWaitSeconds());

  Future<void> _pollRpcOrSwitchToFallback(int gen) async {
    if (_disposed || !_state.isSearching || _searchGen != gen) return;
    if (_rpcPollInFlight || _useRealtimeFallback) return;

    _rpcPollInFlight = true;
    try {
      final elapsed = _currentWaitSeconds();
      final window = ChessMatchmakingEngine.windowFor(
        myElo: _state.myElo,
        waitSeconds: elapsed,
      );
      final assignment = await _supabase.matchmakeChess(
        timeControlName: _state.timeControlName,
        searchRadius: window.radius,
        waitSeconds: elapsed,
      );
      if (_disposed || !_state.isSearching || _searchGen != gen) return;

      if (assignment != null) {
        await _completeMatch(gen, assignment);
      }
    } on SupabaseMissingSchemaException {
      if (_disposed || !_state.isSearching || _searchGen != gen) return;
      await _activateRealtimeFallback(gen);
    } catch (e) {
      if (_disposed || !_state.isSearching || _searchGen != gen) return;
      _state = _state.copyWith(errorMessage: '$e');
      notifyListeners();
    } finally {
      _rpcPollInFlight = false;
    }
  }

  Future<void> _activateRealtimeFallback(int gen) async {
    if (_useRealtimeFallback || _disposed || _searchGen != gen) return;
    _useRealtimeFallback = true;
    _pollTimer?.cancel();
    _pollTimer = null;

    _state = _state.copyWith(usingRealtimeFallback: true, clearError: true);
    notifyListeners();

    final profile = _profile;
    if (profile == null) return;

    final ch = _supabase.createChessMatchmakingChannel(
      _state.timeControlName,
      presenceKey: profile.id,
    );
    if (ch == null) {
      return;
    }
    _lobbyChannel = ch;

    ch
        .onPresenceSync((_) => _evaluatePresenceCandidates(gen))
        .onPresenceJoin((_) => _evaluatePresenceCandidates(gen))
        .onBroadcast(
          event: 'mm_offer',
          callback: (payload) => _handleOffer(gen, payload),
        )
        .onBroadcast(
          event: 'mm_accept',
          callback: (payload) => _handleAccept(gen, payload),
        )
        .subscribe((status, _) async {
          if (status == RealtimeSubscribeStatus.subscribed &&
              !_disposed &&
              _state.isSearching &&
              _searchGen == gen) {
            await ch.track({
              'user_id': profile.id,
              'username': profile.username,
              'avatar_url': profile.avatarUrl,
              'chess_elo': profile.chessElo,
              'time_control': _state.timeControlName,
              'joined_at_ms':
                  (_startedAtUtc ?? DateTime.now().toUtc())
                      .millisecondsSinceEpoch,
            });
            _evaluatePresenceCandidates(gen);
          }
        });
  }

  void _evaluatePresenceCandidates(int gen) {
    if (_disposed || !_state.isSearching || _searchGen != gen) return;
    final ch = _lobbyChannel;
    final me = _profile;
    if (ch == null || me == null) return;

    // Clear stale pending offer after 4 seconds.
    if (_pendingOfferSentAt != null &&
        DateTime.now().toUtc().difference(_pendingOfferSentAt!).inSeconds >= 4) {
      _pendingOfferTarget = null;
      _pendingOfferRoom = null;
      _pendingOfferHostColor = null;
      _pendingOfferSentAt = null;
    }
    if (_pendingOfferTarget != null) return;

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final candidates = <MatchCandidate>[];
    for (final entry in ch.presenceState()) {
      for (final presence in entry.presences) {
        final data = presence.payload;
        final uid = (data['user_id'] ?? '').toString();
        if (uid.isEmpty || uid == me.id) continue;
        final tc = (data['time_control'] ?? '').toString();
        if (tc != _state.timeControlName) continue;
        final joinedMs = (data['joined_at_ms'] as num?)?.toInt() ?? nowMs;
        final waitSec = max(0, (nowMs - joinedMs) ~/ 1000);
        candidates.add(
          MatchCandidate(
            userId: uid,
            username: (data['username'] ?? 'player').toString(),
            avatarUrl: data['avatar_url'] as String?,
            chessElo: (data['chess_elo'] as num?)?.toInt() ?? 1000,
            timeControlName: tc,
            waitSeconds: waitSec,
          ),
        );
      }
    }

    final myTicket = MatchSearchTicket(
      userId: me.id,
      username: me.username,
      avatarUrl: me.avatarUrl,
      chessElo: me.chessElo,
      timeControlName: _state.timeControlName,
      waitSeconds: _currentWaitSeconds(),
    );
    final best = ChessMatchmakingEngine.selectBestOpponent(
      me: myTicket,
      candidates: candidates,
    );
    if (best == null) return;

    // Deterministic initiator: smaller userId initiates so only one room spawns.
    if (me.id.compareTo(best.userId) >= 0) return;

    final roomCode = _generateRoomCode();
    final myColor = Random().nextBool() ? Bishop.white : Bishop.black;
    _pendingOfferTarget = best.userId;
    _pendingOfferRoom = roomCode;
    _pendingOfferHostColor = myColor;
    _pendingOfferSentAt = DateTime.now().toUtc();

    ch.sendBroadcastMessage(
      event: 'mm_offer',
      payload: {
        'initiator_id': me.id,
        'initiator_username': me.username,
        'initiator_avatar_url': me.avatarUrl,
        'initiator_elo': me.chessElo,
        'target_id': best.userId,
        'room_code': roomCode,
        'host_color': myColor,
        'time_control': _state.timeControlName,
      },
    );
  }

  void _handleOffer(int gen, Map<String, dynamic> payload) {
    if (_disposed || !_state.isSearching || _searchGen != gen) return;
    final me = _profile;
    final ch = _lobbyChannel;
    if (me == null || ch == null) return;

    final targetId = (payload['target_id'] ?? '').toString();
    final initiatorId = (payload['initiator_id'] ?? '').toString();
    if (targetId != me.id || initiatorId.isEmpty || initiatorId == me.id) {
      return;
    }
    final tc = (payload['time_control'] ?? '').toString();
    if (tc != _state.timeControlName) return;

    final roomCode = (payload['room_code'] ?? '').toString();
    final hostColor = (payload['host_color'] as num?)?.toInt() ?? Bishop.white;
    if (roomCode.isEmpty) return;

    final myColor = hostColor == Bishop.white ? Bishop.black : Bishop.white;
    final opponentElo = (payload['initiator_elo'] as num?)?.toInt() ?? 1000;
    final opponentUsername =
        (payload['initiator_username'] ?? 'opponent').toString();
    final opponentAvatar = payload['initiator_avatar_url'] as String?;

    ch.sendBroadcastMessage(
      event: 'mm_accept',
      payload: {
        'initiator_id': initiatorId,
        'target_id': me.id,
        'target_username': me.username,
        'target_avatar_url': me.avatarUrl,
        'target_elo': me.chessElo,
        'room_code': roomCode,
      },
    );

    _completeMatch(
      gen,
      MatchAssignment(
        roomCode: roomCode,
        assignedColor: myColor,
        opponentUserId: initiatorId,
        opponentUsername: opponentUsername,
        opponentAvatarUrl: opponentAvatar,
        opponentElo: opponentElo,
        timeControlName: _state.timeControlName,
        viaServerRpc: false,
      ),
    );
  }

  void _handleAccept(int gen, Map<String, dynamic> payload) {
    if (_disposed || !_state.isSearching || _searchGen != gen) return;
    final me = _profile;
    if (me == null) return;

    final initiatorId = (payload['initiator_id'] ?? '').toString();
    final targetId = (payload['target_id'] ?? '').toString();
    final roomCode = (payload['room_code'] ?? '').toString();
    if (initiatorId != me.id ||
        targetId != _pendingOfferTarget ||
        roomCode != _pendingOfferRoom) {
      return;
    }

    final myColor = _pendingOfferHostColor ?? Bishop.white;
    final opponentUsername =
        (payload['target_username'] ?? 'opponent').toString();
    final opponentAvatar = payload['target_avatar_url'] as String?;
    final opponentElo = (payload['target_elo'] as num?)?.toInt() ?? 1000;

    _completeMatch(
      gen,
      MatchAssignment(
        roomCode: roomCode,
        assignedColor: myColor,
        opponentUserId: targetId,
        opponentUsername: opponentUsername,
        opponentAvatarUrl: opponentAvatar,
        opponentElo: opponentElo,
        timeControlName: _state.timeControlName,
        viaServerRpc: false,
      ),
    );
  }

  Future<void> _completeMatch(int gen, MatchAssignment assignment) async {
    if (_disposed || _searchGen != gen) return;
    _searchGen++;
    _stopTimers();
    await _leaveLobbyChannel();

    if (!_disposed) {
      _state = ChessMatchmakingState.idle(myElo: _state.myElo);
      notifyListeners();
      onMatched(assignment);
    }
  }

  Future<void> _leaveLobbyChannel() async {
    final ch = _lobbyChannel;
    _lobbyChannel = null;
    if (ch != null) {
      try {
        await ch.untrack();
      } catch (_) {}
      try {
        await ch.unsubscribe();
      } catch (_) {}
    }
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  void _stopTimers() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _searchGen++;
    _stopTimers();
    _lobbyChannel?.unsubscribe();
    _lobbyChannel = null;
    super.dispose();
  }
}
