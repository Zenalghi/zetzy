import 'dart:async';
import 'dart:math';

import 'package:bishop/bishop.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/services/audio_service.dart';
import 'package:zetzy/core/services/haptic_service.dart';
import 'package:zetzy/data/models/auto_save_slot.dart';
import 'package:zetzy/data/remote/supabase_service.dart';
import 'package:zetzy/features/games/chess/chess_ai.dart';

enum ChessPlayMode {
  vsAi,
  passAndPlay,
  findMatch,
  online;

  bool get isOnlineMultiplayer =>
      this == ChessPlayMode.findMatch || this == ChessPlayMode.online;

  bool get isRankedMode =>
      this == ChessPlayMode.vsAi || this == ChessPlayMode.findMatch;
}

enum ChessColorPref { white, black, random }

enum ChessTimeControl {
  untimed(0),
  bullet1(60000),
  blitz3(180000),
  blitz5(300000),
  rapid10(600000);

  const ChessTimeControl(this.initialMs);
  final int initialMs;
}

@immutable
class ChessUiState {
  static const int minRankedOnlinePlies = 4;

  const ChessUiState({
    required this.difficulty,
    required this.isPractice,
    required this.mode,
    required this.timeControl,
    required this.playerColor,
    required this.flipped,
    required this.turn,
    required this.selectedSquare,
    required this.legalTargets,
    required this.lastFrom,
    required this.lastTo,
    required this.inCheck,
    required this.isAiThinking,
    required this.whiteTimeMs,
    required this.blackTimeMs,
    required this.elapsedMs,
    required this.moveSans,
    required this.capturedByWhite,
    required this.capturedByBlack,
    required this.materialAdvantage,
    required this.isPaused,
    required this.isGameOver,
    required this.winnerColour,
    required this.isDraw,
    required this.onlineRoomCode,
    required this.onlineWaiting,
    required this.pendingPromotionMoves,
    this.practiceHistoryCount = 0,
    this.onlineMatchId,
    this.opponentUserId,
    this.opponentUsername,
    this.opponentAvatarUrl,
    this.opponentElo,
    this.isAbortedUnrated = false,
    this.reviewPly,
  });

  final DifficultyLevel difficulty;
  final bool isPractice;
  final ChessPlayMode mode;
  final ChessTimeControl timeControl;
  final int playerColor; // Bishop.white or Bishop.black
  final bool flipped;
  final int turn;
  final int? selectedSquare;
  final Set<int> legalTargets;
  final int? lastFrom;
  final int? lastTo;
  final bool inCheck;
  final bool isAiThinking;
  final int whiteTimeMs;
  final int blackTimeMs;
  final int elapsedMs;
  final List<String> moveSans;
  final List<String> capturedByWhite; // e.g. ['P', 'N']
  final List<String> capturedByBlack;
  final int materialAdvantage; // >0 white ahead, <0 black ahead
  final bool isPaused;
  final bool isGameOver;
  final int? winnerColour;
  final bool isDraw;
  final String? onlineRoomCode;
  final bool onlineWaiting;
  final List<Move>? pendingPromotionMoves;
  final int practiceHistoryCount;
  final String? onlineMatchId;
  final String? opponentUserId;
  final String? opponentUsername;
  final String? opponentAvatarUrl;
  final int? opponentElo;
  final bool isAbortedUnrated;
  final int? reviewPly;

  int get effectiveReviewPly => reviewPly ?? moveSans.length;
  bool get isReviewingHistory => reviewPly != null;
  bool get canReviewBack => isGameOver && effectiveReviewPly > 0;
  bool get canReviewForward => isGameOver && effectiveReviewPly < moveSans.length;

  bool get canUndo =>
      mode == ChessPlayMode.vsAi &&
      difficulty.level <= 4 &&
      moveSans.length >= 2 &&
      !isAiThinking &&
      !isGameOver;

  bool get canPracticeUndo =>
      isPractice &&
      !mode.isOnlineMultiplayer &&
      practiceHistoryCount > 0 &&
      !isAiThinking;

  ChessUiState copyWith({
    ChessTimeControl? timeControl,
    int? playerColor,
    bool? flipped,
    int? turn,
    int? selectedSquare,
    bool clearSelected = false,
    Set<int>? legalTargets,
    int? lastFrom,
    int? lastTo,
    bool clearLastMove = false,
    bool? inCheck,
    bool? isAiThinking,
    int? whiteTimeMs,
    int? blackTimeMs,
    int? elapsedMs,
    List<String>? moveSans,
    List<String>? capturedByWhite,
    List<String>? capturedByBlack,
    int? materialAdvantage,
    bool? isPaused,
    bool? isGameOver,
    int? winnerColour,
    bool clearWinner = false,
    bool? isDraw,
    String? onlineRoomCode,
    bool? onlineWaiting,
    List<Move>? pendingPromotionMoves,
    bool clearPromotion = false,
    int? practiceHistoryCount,
    String? onlineMatchId,
    String? opponentUserId,
    String? opponentUsername,
    String? opponentAvatarUrl,
    int? opponentElo,
    bool? isAbortedUnrated,
    int? reviewPly,
    bool clearReviewPly = false,
  }) {
    return ChessUiState(
      difficulty: difficulty,
      isPractice: isPractice,
      mode: mode,
      timeControl: timeControl ?? this.timeControl,
      playerColor: playerColor ?? this.playerColor,
      flipped: flipped ?? this.flipped,
      turn: turn ?? this.turn,
      selectedSquare:
          clearSelected ? null : (selectedSquare ?? this.selectedSquare),
      legalTargets: legalTargets ?? this.legalTargets,
      lastFrom: clearLastMove ? null : (lastFrom ?? this.lastFrom),
      lastTo: clearLastMove ? null : (lastTo ?? this.lastTo),
      inCheck: inCheck ?? this.inCheck,
      isAiThinking: isAiThinking ?? this.isAiThinking,
      whiteTimeMs: whiteTimeMs ?? this.whiteTimeMs,
      blackTimeMs: blackTimeMs ?? this.blackTimeMs,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      moveSans: moveSans ?? this.moveSans,
      capturedByWhite: capturedByWhite ?? this.capturedByWhite,
      capturedByBlack: capturedByBlack ?? this.capturedByBlack,
      materialAdvantage: materialAdvantage ?? this.materialAdvantage,
      isPaused: isPaused ?? this.isPaused,
      isGameOver: isGameOver ?? this.isGameOver,
      winnerColour: clearWinner ? null : (winnerColour ?? this.winnerColour),
      isDraw: isDraw ?? this.isDraw,
      onlineRoomCode: onlineRoomCode ?? this.onlineRoomCode,
      onlineWaiting: onlineWaiting ?? this.onlineWaiting,
      pendingPromotionMoves: clearPromotion
          ? null
          : (pendingPromotionMoves ?? this.pendingPromotionMoves),
      practiceHistoryCount: practiceHistoryCount ?? this.practiceHistoryCount,
      onlineMatchId: onlineMatchId ?? this.onlineMatchId,
      opponentUserId: opponentUserId ?? this.opponentUserId,
      opponentUsername: opponentUsername ?? this.opponentUsername,
      opponentAvatarUrl: opponentAvatarUrl ?? this.opponentAvatarUrl,
      opponentElo: opponentElo ?? this.opponentElo,
      isAbortedUnrated: isAbortedUnrated ?? this.isAbortedUnrated,
      reviewPly: clearReviewPly ? null : (reviewPly ?? this.reviewPly),
    );
  }
}

class _ChessTimelineSnapshot {
  const _ChessTimelineSnapshot({
    required this.fen,
    required this.lastFrom,
    required this.lastTo,
    required this.inCheck,
  });

  final String fen;
  final int? lastFrom;
  final int? lastTo;
  final bool inCheck;
}

class _ChessPracticeSnapshot {
  const _ChessPracticeSnapshot({
    required this.fen,
    required this.turn,
    required this.moveSans,
    required this.moveSqHistory,
    required this.whiteTimeMs,
    required this.blackTimeMs,
    required this.elapsedMs,
  });

  final String fen;
  final int turn;
  final List<String> moveSans;
  final List<(int?, int?)> moveSqHistory;
  final int whiteTimeMs;
  final int blackTimeMs;
  final int elapsedMs;
}

class ChessController extends ChangeNotifier {
  ChessController({
    required this._audio,
    required this._haptics,
    required this._supabase,
    required this._autoQueen,
    required this.onFinished,
    required this.onAutoSave,
  });

  final AudioService _audio;
  final HapticService _haptics;
  final SupabaseService _supabase;
  bool _autoQueen;
  final void Function(ChessUiState finalState) onFinished;
  final void Function(AutoSaveSlot slot) onAutoSave;

  late Game _game;
  Game? _reviewGame;
  Game get game => _reviewGame ?? _game;
  String get livePgn => _game.pgn();

  Timer? _timer;
  Timer? _disconnectGraceTimer;
  RealtimeChannel? _channel;
  final List<(int?, int?)> _moveSqHistory = [];
  final List<_ChessPracticeSnapshot> _practiceHistory = [];
  final List<_ChessTimelineSnapshot> _timelineSnapshots = [];
  int _generation = 0;
  String? _localUserId;
  String? _localUsername;
  String? _localAvatarUrl;
  int _localChessElo = 1000;
  late ChessUiState _state;
  ChessUiState get state => _state;

  void setAutoQueen(bool value) {
    _autoQueen = value;
  }

  void startNew({
    required DifficultyLevel difficulty,
    required bool isPractice,
    required ChessPlayMode mode,
    required ChessColorPref colorPref,
    required ChessTimeControl timeControl,
    String? roomCode,
    bool isHost = true,
    String? matchId,
    String? localUserId,
    String? localUsername,
    String? localAvatarUrl,
    int localChessElo = 1000,
    String? opponentUserId,
    String? opponentUsername,
    String? opponentAvatarUrl,
    int? opponentElo,
  }) {
    _stopTimer();
    _cancelDisconnectTimer();
    _leaveOnlineRoom();
    _moveSqHistory.clear();
    _practiceHistory.clear();
    _timelineSnapshots.clear();
    _reviewGame = null;
    _generation++;
    _game = Game(variant: Variant.standard());
    _timelineSnapshots.add(
      _ChessTimelineSnapshot(
        fen: _game.fen,
        lastFrom: null,
        lastTo: null,
        inCheck: false,
      ),
    );

    _localUserId = localUserId;
    _localUsername = localUsername;
    _localAvatarUrl = localAvatarUrl;
    _localChessElo = localChessElo;

    final resolvedColor = switch (colorPref) {
      ChessColorPref.white => Bishop.white,
      ChessColorPref.black => Bishop.black,
      ChessColorPref.random =>
        Random().nextBool() ? Bishop.white : Bishop.black,
    };

    final activeRoom = mode.isOnlineMultiplayer
        ? (roomCode ?? _generateRoomCode())
        : null;

    _state = ChessUiState(
      difficulty: difficulty,
      isPractice: isPractice,
      mode: mode,
      timeControl: timeControl,
      playerColor: resolvedColor,
      flipped: resolvedColor == Bishop.black,
      turn: _game.turn,
      selectedSquare: null,
      legalTargets: const {},
      lastFrom: null,
      lastTo: null,
      inCheck: false,
      isAiThinking: false,
      whiteTimeMs: timeControl.initialMs,
      blackTimeMs: timeControl.initialMs,
      elapsedMs: 0,
      moveSans: const [],
      capturedByWhite: const [],
      capturedByBlack: const [],
      materialAdvantage: 0,
      isPaused: false,
      isGameOver: false,
      winnerColour: null,
      isDraw: false,
      onlineRoomCode: activeRoom,
      onlineWaiting: mode.isOnlineMultiplayer,
      pendingPromotionMoves: null,
      onlineMatchId: matchId,
      opponentUserId: opponentUserId,
      opponentUsername: opponentUsername,
      opponentAvatarUrl: opponentAvatarUrl,
      opponentElo: opponentElo,
    );

    if (mode.isOnlineMultiplayer && activeRoom != null) {
      _joinOnlineRoom(
        activeRoom,
        isHost: isHost,
        isMatchmade: mode == ChessPlayMode.findMatch,
      );
    }

    notifyListeners();
    _startTimer();

    if (mode == ChessPlayMode.vsAi && resolvedColor == Bishop.black) {
      _triggerAiMove();
    }
  }

  void restoreFromSlot(AutoSaveSlot slot) {
    _stopTimer();
    _leaveOnlineRoom();
    _moveSqHistory.clear();
    _practiceHistory.clear();
    _timelineSnapshots.clear();
    _reviewGame = null;
    _generation++;
    final s = slot.stateJson;
    final diff = DifficultyLevel.fromLevel(slot.difficulty);
    final pgn = s['pgn'] as String?;
    final fen = s['fen'] as String?;

    if (pgn != null && pgn.trim().isNotEmpty) {
      try {
        _game = Game.fromPgn(pgn);
        final walk = Game.fromPgn(pgn);
        final reversed = <_ChessTimelineSnapshot>[
          _ChessTimelineSnapshot(
            fen: walk.fen,
            lastFrom: null,
            lastTo: null,
            inCheck: walk.inCheck,
          ),
        ];
        while (walk.canUndo) {
          walk.undo();
          reversed.add(
            _ChessTimelineSnapshot(
              fen: walk.fen,
              lastFrom: null,
              lastTo: null,
              inCheck: walk.inCheck,
            ),
          );
        }
        _timelineSnapshots.addAll(reversed.reversed);
      } catch (_) {
        _game = Game(variant: Variant.standard(), fen: fen);
        _timelineSnapshots.add(
          _ChessTimelineSnapshot(
            fen: _game.fen,
            lastFrom: null,
            lastTo: null,
            inCheck: _game.inCheck,
          ),
        );
      }
    } else {
      _game = Game(variant: Variant.standard(), fen: fen);
      _timelineSnapshots.add(
        _ChessTimelineSnapshot(
          fen: _game.fen,
          lastFrom: null,
          lastTo: null,
          inCheck: _game.inCheck,
        ),
      );
    }

    final mode = ChessPlayMode.values.firstWhere(
      (m) => m.name == s['mode'],
      orElse: () => ChessPlayMode.vsAi,
    );
    final tc = ChessTimeControl.values.firstWhere(
      (t) => t.name == s['timeControl'],
      orElse: () => ChessTimeControl.untimed,
    );
    final playerColor = (s['playerColor'] as num?)?.toInt() ?? Bishop.white;

    _state = ChessUiState(
      difficulty: diff,
      isPractice: s['isPractice'] == true,
      mode: mode,
      timeControl: tc,
      playerColor: playerColor,
      flipped: playerColor == Bishop.black,
      turn: _game.turn,
      selectedSquare: null,
      legalTargets: const {},
      lastFrom: null,
      lastTo: null,
      inCheck: _game.inCheck,
      isAiThinking: false,
      whiteTimeMs: (s['whiteTimeMs'] as num?)?.toInt() ?? tc.initialMs,
      blackTimeMs: (s['blackTimeMs'] as num?)?.toInt() ?? tc.initialMs,
      elapsedMs: slot.elapsedMs,
      moveSans: ((s['moveSans'] as List?) ?? []).cast<String>(),
      capturedByWhite: const [],
      capturedByBlack: const [],
      materialAdvantage: 0,
      isPaused: true,
      isGameOver: false,
      winnerColour: null,
      isDraw: false,
      onlineRoomCode: null,
      onlineWaiting: false,
      pendingPromotionMoves: null,
    );
    _recomputeMaterialAndCaptures();
    notifyListeners();
  }

  AutoSaveSlot exportSlot() {
    return AutoSaveSlot(
      gameType: GameType.chess,
      difficulty: _state.difficulty.level,
      elapsedMs: _state.elapsedMs,
      updatedAt: DateTime.now().toUtc(),
      stateJson: {
        'isPractice': _state.isPractice,
        'mode': _state.mode.name,
        'timeControl': _state.timeControl.name,
        'playerColor': _state.playerColor,
        'fen': _game.fen,
        'pgn': _game.pgn(),
        'whiteTimeMs': _state.whiteTimeMs,
        'blackTimeMs': _state.blackTimeMs,
        'moveSans': _state.moveSans,
      },
    );
  }

  void flipBoard() {
    _state = _state.copyWith(flipped: !_state.flipped);
    notifyListeners();
  }

  void onSquareTap(int squareIdx) {
    if (_state.isPaused ||
        _state.isGameOver ||
        _state.isAiThinking ||
        _state.onlineWaiting) {
      return;
    }

    if (_state.mode == ChessPlayMode.vsAi && _game.turn != _state.playerColor) {
      return;
    }
    if (_state.mode.isOnlineMultiplayer &&
        _game.turn != _state.playerColor) {
      return;
    }

    final selected = _state.selectedSquare;
    if (selected != null && _state.legalTargets.contains(squareIdx)) {
      final matchingMoves = _game
          .generateLegalMoves()
          .where((m) => m.from == selected && m.to == squareIdx)
          .toList();
      if (matchingMoves.isEmpty) return;

      if (matchingMoves.length > 1 && matchingMoves.any((m) => m.promotion)) {
        if (_autoQueen) {
          final queenMove = matchingMoves.firstWhere(
            (m) => _game.variant.pieces[m.promoPiece!].symbol.toUpperCase() == 'Q',
            orElse: () => matchingMoves.first,
          );
          _executeMove(queenMove);
        } else {
          _state = _state.copyWith(pendingPromotionMoves: matchingMoves);
          notifyListeners();
        }
      } else {
        _executeMove(matchingMoves.first);
      }
      return;
    }

    // Tapping the currently selected piece again clears selection and move guides
    if (selected == squareIdx) {
      _state = _state.copyWith(clearSelected: true, legalTargets: const {});
      _haptics.selection();
      notifyListeners();
      return;
    }

    // Select own piece
    final sq = _game.board[squareIdx];
    if (sq.isNotEmpty && sq.colour == _game.turn) {
      final legal = _game
          .generateLegalMoves()
          .where((m) => m.from == squareIdx)
          .map((m) => m.to)
          .toSet();
      _state = _state.copyWith(
        selectedSquare: squareIdx,
        legalTargets: legal,
      );
      _haptics.selection();
      notifyListeners();
      return;
    }

    _state = _state.copyWith(clearSelected: true, legalTargets: const {});
    notifyListeners();
  }

  void completePromotion(Move move) {
    _state = _state.copyWith(clearPromotion: true);
    _executeMove(move);
  }

  void cancelPromotion() {
    _state = _state.copyWith(
      clearPromotion: true,
      clearSelected: true,
      legalTargets: const {},
    );
    notifyListeners();
  }

  void _executeMove(Move move, {bool fromRemote = false}) {
    final san = _game.toSan(move);
    final alg = _game.toAlgebraic(move);
    final isCapture = move.capture;
    final preFen = _game.fen;
    final preTurn = _game.turn;

    final ok = _game.makeMove(move);
    if (!ok) return;

    if (_state.isPractice && !_state.mode.isOnlineMultiplayer) {
      if (_practiceHistory.length >= 40) {
        _practiceHistory.removeAt(0);
      }
      _practiceHistory.add(
        _ChessPracticeSnapshot(
          fen: preFen,
          turn: preTurn,
          moveSans: List<String>.from(_state.moveSans),
          moveSqHistory: List<(int?, int?)>.from(_moveSqHistory),
          whiteTimeMs: _state.whiteTimeMs,
          blackTimeMs: _state.blackTimeMs,
          elapsedMs: _state.elapsedMs,
        ),
      );
    }

    _moveSqHistory.add((move.from, move.to));
    _timelineSnapshots.add(
      _ChessTimelineSnapshot(
        fen: _game.fen,
        lastFrom: move.from,
        lastTo: move.to,
        inCheck: _game.inCheck,
      ),
    );

    if (_game.inCheck) {
      _audio.playSfx(ZetzySfx.chessCheck);
      _haptics.heavy();
    } else if (isCapture) {
      _audio.playSfx(ZetzySfx.chessCapture);
      _haptics.medium();
    } else {
      _audio.playSfx(ZetzySfx.chessMove);
      _haptics.light();
    }

    final nextSans = [..._state.moveSans, san];
    _state = _state.copyWith(
      turn: _game.turn,
      clearSelected: true,
      legalTargets: const {},
      lastFrom: move.from,
      lastTo: move.to,
      inCheck: _game.inCheck,
      moveSans: nextSans,
      practiceHistoryCount: _practiceHistory.length,
    );
    _recomputeMaterialAndCaptures();

    if (_state.mode.isOnlineMultiplayer && !fromRemote) {
      _channel?.sendBroadcastMessage(
        event: 'chess_move',
        payload: {'alg': alg, 'color': preTurn},
      );
    }

    if (_checkGameEnd()) return;
    notifyListeners();

    if (_state.mode == ChessPlayMode.vsAi && _game.turn != _state.playerColor) {
      _triggerAiMove();
    }
  }

  Future<void> _triggerAiMove() async {
    final gen = _generation;
    _state = _state.copyWith(isAiThinking: true);
    notifyListeners();

    final alg = await ChessAiEngine.findBestMoveAlgebraic(
      fen: _game.fen,
      level: _state.difficulty.level,
    );

    if (gen != _generation || _state.isGameOver) return;
    _state = _state.copyWith(isAiThinking: false);
    if (alg != null) {
      final move = _game.getMove(alg);
      if (move != null) {
        _executeMove(move);
        return;
      }
    }
    notifyListeners();
  }

  /// PRD 43A: Undo allowed vs AI on Levels 1-4, disabled on 5-7.
  void undoVsAi() {
    if (!_state.canUndo) return;
    if (_game.canUndo) _game.undo();
    if (_game.canUndo) _game.undo();
    if (_moveSqHistory.length >= 2) {
      _moveSqHistory.removeLast();
      _moveSqHistory.removeLast();
    }
    if (_timelineSnapshots.length >= 3) {
      _timelineSnapshots.removeLast();
      _timelineSnapshots.removeLast();
    }
    if (_state.isPractice && _practiceHistory.length >= 2) {
      _practiceHistory.removeLast();
      _practiceHistory.removeLast();
    }
    final nextSans = _state.moveSans.length >= 2
        ? _state.moveSans.sublist(0, _state.moveSans.length - 2)
        : <String>[];
    final lastPair =
        _moveSqHistory.isNotEmpty ? _moveSqHistory.last : (null, null);

    _state = _state.copyWith(
      turn: _game.turn,
      clearSelected: true,
      legalTargets: const {},
      lastFrom: lastPair.$1,
      lastTo: lastPair.$2,
      clearLastMove: lastPair.$1 == null,
      inCheck: _game.inCheck,
      moveSans: nextSans,
      practiceHistoryCount: _practiceHistory.length,
    );
    _recomputeMaterialAndCaptures();
    _haptics.selection();
    notifyListeners();
  }

  void practiceUndo() => practiceRewind(1);

  void practiceRewind(int steps) {
    if (!_state.isPractice ||
        _state.mode.isOnlineMultiplayer ||
        _practiceHistory.isEmpty) {
      return;
    }
    _generation++;
    final targetSteps = steps.clamp(1, 3);
    _ChessPracticeSnapshot? chosen;

    if (_state.mode == ChessPlayMode.vsAi) {
      var playerTurnsUndone = 0;
      while (_practiceHistory.isNotEmpty) {
        final snap = _practiceHistory.removeLast();
        chosen = snap;
        if (snap.turn == _state.playerColor) {
          playerTurnsUndone++;
          if (playerTurnsUndone >= targetSteps) break;
        }
      }
    } else {
      final count = min(targetSteps, _practiceHistory.length);
      for (var i = 0; i < count; i++) {
        chosen = _practiceHistory.removeLast();
      }
    }

    if (chosen == null) return;
    _restorePracticeSnapshot(chosen);
  }

  void _restorePracticeSnapshot(_ChessPracticeSnapshot snap) {
    var whiteMs = snap.whiteTimeMs;
    var blackMs = snap.blackTimeMs;
    if (_state.isGameOver && _state.timeControl != ChessTimeControl.untimed) {
      if (snap.turn == Bishop.white && whiteMs < 10000) {
        whiteMs = min(_state.timeControl.initialMs, 10000);
      }
      if (snap.turn == Bishop.black && blackMs < 10000) {
        blackMs = min(_state.timeControl.initialMs, 10000);
      }
    }

    _game = Game(variant: Variant.standard(), fen: snap.fen);
    _reviewGame = null;
    while (_timelineSnapshots.length > snap.moveSans.length + 1) {
      _timelineSnapshots.removeLast();
    }
    _moveSqHistory
      ..clear()
      ..addAll(snap.moveSqHistory);
    final lastPair =
        _moveSqHistory.isNotEmpty ? _moveSqHistory.last : (null, null);

    _state = _state.copyWith(
      turn: _game.turn,
      clearSelected: true,
      legalTargets: const {},
      lastFrom: lastPair.$1,
      lastTo: lastPair.$2,
      clearLastMove: lastPair.$1 == null,
      inCheck: _game.inCheck,
      isAiThinking: false,
      whiteTimeMs: whiteMs,
      blackTimeMs: blackMs,
      elapsedMs: snap.elapsedMs,
      moveSans: List<String>.from(snap.moveSans),
      isPaused: false,
      isGameOver: false,
      clearWinner: true,
      isDraw: false,
      clearPromotion: true,
      clearReviewPly: true,
      practiceHistoryCount: _practiceHistory.length,
    );
    _recomputeMaterialAndCaptures();
    _haptics.selection();
    notifyListeners();
    _startTimer();

    if (_state.mode == ChessPlayMode.vsAi && _game.turn != _state.playerColor) {
      _triggerAiMove();
    }
  }

  void resign() {
    if (_state.isGameOver) return;
    final loser = _state.mode == ChessPlayMode.passAndPlay
        ? _game.turn
        : _state.playerColor;
    final winner = loser.opponent;
    if (_state.mode.isOnlineMultiplayer) {
      _channel?.sendBroadcastMessage(
        event: 'chess_resign',
        payload: {'winner': winner, 'resignerColor': loser},
      );
    }
    _endGame(winnerColour: winner, isDraw: false, isResignOrAbandon: true);
  }

  bool _checkGameEnd() {
    final result = _game.result;
    if (result == null && !_game.gameOver) return false;
    if (result is WonGame) {
      _endGame(winnerColour: result.winner, isDraw: false);
      return true;
    }
    _endGame(winnerColour: null, isDraw: true);
    return true;
  }

  void _endGame({
    required int? winnerColour,
    required bool isDraw,
    bool isResignOrAbandon = false,
  }) {
    _generation++;
    _stopTimer();
    _cancelDisconnectTimer();
    _leaveOnlineRoom();

    final abortedTooShort =
        _state.mode.isOnlineMultiplayer &&
        _state.moveSans.length < ChessUiState.minRankedOnlinePlies &&
        (isResignOrAbandon || _game.result is! WonGame);

    final playerWon =
        !abortedTooShort && !isDraw && winnerColour == _state.playerColor;
    _audio.playSfx(playerWon ? ZetzySfx.gameWin : ZetzySfx.mineExplode);
    _reviewGame = null;
    _state = _state.copyWith(
      isGameOver: true,
      winnerColour: abortedTooShort ? null : winnerColour,
      clearWinner: abortedTooShort || winnerColour == null,
      isDraw: !abortedTooShort && isDraw,
      isAiThinking: false,
      isAbortedUnrated: abortedTooShort,
      clearReviewPly: true,
    );
    notifyListeners();
    onFinished(_state);
  }

  /// Navigates to a historical ply in post-game move review without altering
  /// the completed live game record.
  void jumpToReviewPly(int ply) {
    if (!_state.isGameOver || _timelineSnapshots.isEmpty) return;
    final totalPlies = _state.moveSans.length;
    final targetPly = ply.clamp(0, totalPlies);

    if (targetPly == totalPlies) {
      _reviewGame = null;
      final lastPair =
          _moveSqHistory.isNotEmpty ? _moveSqHistory.last : (null, null);
      _state = _state.copyWith(
        clearReviewPly: true,
        turn: _game.turn,
        clearSelected: true,
        legalTargets: const {},
        lastFrom: lastPair.$1,
        lastTo: lastPair.$2,
        clearLastMove: lastPair.$1 == null,
        inCheck: _game.inCheck,
      );
      _recomputeMaterialAndCaptures();
      notifyListeners();
      return;
    }

    final offset = totalPlies - (_timelineSnapshots.length - 1);
    final snapIdx = targetPly - offset;
    if (snapIdx < 0 || snapIdx >= _timelineSnapshots.length) return;
    final snap = _timelineSnapshots[snapIdx];
    _reviewGame = Game(variant: Variant.standard(), fen: snap.fen);
    _state = _state.copyWith(
      reviewPly: targetPly,
      turn: _reviewGame!.turn,
      clearSelected: true,
      legalTargets: const {},
      lastFrom: snap.lastFrom,
      lastTo: snap.lastTo,
      clearLastMove: snap.lastFrom == null,
      inCheck: snap.inCheck,
    );
    _recomputeMaterialAndCaptures();
    notifyListeners();
  }

  void reviewFirst() => jumpToReviewPly(0);
  void reviewPrev() => jumpToReviewPly(_state.effectiveReviewPly - 1);
  void reviewNext() => jumpToReviewPly(_state.effectiveReviewPly + 1);
  void reviewLast() => jumpToReviewPly(_state.moveSans.length);

  void _recomputeMaterialAndCaptures() {
    const startCounts = {'P': 8, 'N': 2, 'B': 2, 'R': 2, 'Q': 1};
    const pieceValues = {'P': 1, 'N': 3, 'B': 3, 'R': 5, 'Q': 9};
    final activeGame = game;
    final whiteOnBoard = <String, int>{};
    final blackOnBoard = <String, int>{};
    var whiteMat = 0;
    var blackMat = 0;

    for (var rank = 0; rank < 8; rank++) {
      for (var file = 0; file < 8; file++) {
        final sq = activeGame.board[activeGame.size.square(file, rank)];
        if (sq.isEmpty) continue;
        final sym = activeGame.variant.pieces[sq.type].symbol.toUpperCase();
        final v = pieceValues[sym] ?? 0;
        if (sq.colour == Bishop.white) {
          whiteMat += v;
          whiteOnBoard[sym] = (whiteOnBoard[sym] ?? 0) + 1;
        } else {
          blackMat += v;
          blackOnBoard[sym] = (blackOnBoard[sym] ?? 0) + 1;
        }
      }
    }

    final capByWhite = <String>[];
    final capByBlack = <String>[];
    for (final entry in startCounts.entries) {
      final lostBlack = max(0, entry.value - (blackOnBoard[entry.key] ?? 0));
      for (var i = 0; i < lostBlack; i++) {
        capByWhite.add(entry.key);
      }
      final lostWhite = max(0, entry.value - (whiteOnBoard[entry.key] ?? 0));
      for (var i = 0; i < lostWhite; i++) {
        capByBlack.add(entry.key);
      }
    }

    _state = _state.copyWith(
      capturedByWhite: capByWhite,
      capturedByBlack: capByBlack,
      materialAdvantage: whiteMat - blackMat,
    );
  }

  void _cancelDisconnectTimer() {
    _disconnectGraceTimer?.cancel();
    _disconnectGraceTimer = null;
  }

  void _joinOnlineRoom(
    String code, {
    required bool isHost,
    bool isMatchmade = false,
  }) {
    final ch = _supabase.createChessRoomChannel(
      code,
      presenceKey: _localUserId ?? '',
    );
    if (ch == null) {
      _state = _state.copyWith(onlineWaiting: false);
      return;
    }
    _channel = ch;
    ch
        .onPresenceSync((_) {
          if (!isMatchmade || !_state.onlineWaiting) return;
          final states = ch.presenceState();
          final hasOpponent = states.any(
            (s) =>
                s.key.isNotEmpty &&
                (_localUserId == null || s.key != _localUserId),
          );
          if (hasOpponent) {
            _state = _state.copyWith(onlineWaiting: false);
            notifyListeners();
          }
        })
        .onPresenceJoin((payload) {
          if (payload.key.isEmpty || payload.key == _localUserId) return;
          _cancelDisconnectTimer();
          if (isMatchmade && _state.onlineWaiting) {
            _state = _state.copyWith(onlineWaiting: false);
            notifyListeners();
          }
        })
        .onPresenceLeave((payload) {
          if (_state.isGameOver ||
              _state.onlineWaiting ||
              !_state.mode.isOnlineMultiplayer) {
            return;
          }
          if (payload.key.isEmpty || payload.key == _localUserId) return;
          if (_state.opponentUserId != null &&
              _state.opponentUserId!.isNotEmpty &&
              payload.key != _state.opponentUserId) {
            return;
          }
          if (payload.currentPresences.isNotEmpty) return;

          _cancelDisconnectTimer();
          _disconnectGraceTimer = Timer(const Duration(seconds: 10), () {
            if (_state.isGameOver ||
                _state.onlineWaiting ||
                !_state.mode.isOnlineMultiplayer) {
              return;
            }
            _endGame(
              winnerColour: _state.playerColor,
              isDraw: false,
              isResignOrAbandon: true,
            );
          });
        })
        .onBroadcast(
          event: 'chess_host_here',
          callback: (payload) {
            if (isMatchmade || isHost || !_state.onlineWaiting) return;
            ch.sendBroadcastMessage(
              event: 'chess_join',
              payload: {
                'userId': _localUserId,
                'username': _localUsername,
                'avatarUrl': _localAvatarUrl,
                'chessElo': _localChessElo,
              },
            );
          },
        )
        .onBroadcast(
          event: 'chess_join',
          callback: (payload) {
            if (isMatchmade || !isHost) return;
            final guestUserId = payload['userId'] as String?;
            final guestUsername = payload['username'] as String?;
            final guestAvatarUrl = payload['avatarUrl'] as String?;
            final guestElo = (payload['chessElo'] as num?)?.toInt();

            _state = _state.copyWith(
              onlineWaiting: false,
              opponentUserId: guestUserId ?? _state.opponentUserId,
              opponentUsername: guestUsername ?? _state.opponentUsername,
              opponentAvatarUrl: guestAvatarUrl ?? _state.opponentAvatarUrl,
              opponentElo: guestElo ?? _state.opponentElo,
            );
            notifyListeners();
            ch.sendBroadcastMessage(
              event: 'chess_ready',
              payload: {
                'hostColor': _state.playerColor,
                'timeControl': _state.timeControl.name,
                'userId': _localUserId,
                'username': _localUsername,
                'avatarUrl': _localAvatarUrl,
                'chessElo': _localChessElo,
              },
            );
          },
        )
        .onBroadcast(
          event: 'chess_ready',
          callback: (payload) {
            if (isMatchmade || isHost) return;
            final hostColor = (payload['hostColor'] as num?)?.toInt();
            final guestColor = hostColor == Bishop.black
                ? Bishop.white
                : Bishop.black;
            final tcName = payload['timeControl'] as String?;
            final syncedTc = ChessTimeControl.values.firstWhere(
              (t) => t.name == tcName,
              orElse: () => _state.timeControl,
            );
            final hostUserId = payload['userId'] as String?;
            final hostUsername = payload['username'] as String?;
            final hostAvatarUrl = payload['avatarUrl'] as String?;
            final hostElo = (payload['chessElo'] as num?)?.toInt();

            final shouldSyncClock =
                _state.moveSans.isEmpty && syncedTc != _state.timeControl;
            _state = _state.copyWith(
              timeControl: shouldSyncClock ? syncedTc : null,
              whiteTimeMs: shouldSyncClock ? syncedTc.initialMs : null,
              blackTimeMs: shouldSyncClock ? syncedTc.initialMs : null,
              playerColor: guestColor,
              flipped: guestColor == Bishop.black,
              onlineWaiting: false,
              opponentUserId: hostUserId ?? _state.opponentUserId,
              opponentUsername: hostUsername ?? _state.opponentUsername,
              opponentAvatarUrl: hostAvatarUrl ?? _state.opponentAvatarUrl,
              opponentElo: hostElo ?? _state.opponentElo,
            );
            notifyListeners();
          },
        )
        .onBroadcast(
          event: 'chess_peer_ready',
          callback: (payload) {
            if (!isMatchmade) return;
            final senderId = payload['userId'] as String?;
            if (_localUserId != null &&
                senderId != null &&
                senderId == _localUserId) {
              return;
            }
            if (_state.onlineWaiting) {
              _state = _state.copyWith(onlineWaiting: false);
              notifyListeners();
            }
            if (payload['isReply'] != true) {
              ch.sendBroadcastMessage(
                event: 'chess_peer_ready',
                payload: {
                  'isReply': true,
                  'userId': _localUserId,
                  'color': _state.playerColor,
                },
              );
            }
          },
        )
        .onBroadcast(
          event: 'chess_move',
          callback: (payload) {
            if (!_state.mode.isOnlineMultiplayer || _state.isGameOver) return;
            if (_game.turn == _state.playerColor) return;
            final alg = payload['alg'] as String?;
            if (alg == null) return;
            final move = _game.getMove(alg);
            if (move != null) {
              _executeMove(move, fromRemote: true);
            }
          },
        )
        .onBroadcast(
          event: 'chess_resign',
          callback: (payload) {
            if (!_state.mode.isOnlineMultiplayer || _state.isGameOver) return;
            final resignerColor = (payload['resignerColor'] as num?)?.toInt();
            if (resignerColor != null && resignerColor == _state.playerColor) {
              return;
            }
            _endGame(
              winnerColour: _state.playerColor,
              isDraw: false,
              isResignOrAbandon: true,
            );
          },
        )
        .subscribe((status, _) {
          if (status != RealtimeSubscribeStatus.subscribed) return;
          if (_localUserId != null && _localUserId!.isNotEmpty) {
            unawaited(
              ch.track({
                'user_id': _localUserId,
                'username': _localUsername ?? 'player',
                'chess_elo': _localChessElo,
              }),
            );
          }
          if (isMatchmade) {
            ch.sendBroadcastMessage(
              event: 'chess_peer_ready',
              payload: {
                'isReply': false,
                'userId': _localUserId,
                'color': _state.playerColor,
              },
            );
          } else if (isHost) {
            ch.sendBroadcastMessage(
              event: 'chess_host_here',
              payload: {'hostColor': _state.playerColor},
            );
          } else {
            ch.sendBroadcastMessage(
              event: 'chess_join',
              payload: {
                'userId': _localUserId,
                'username': _localUsername,
                'avatarUrl': _localAvatarUrl,
                'chessElo': _localChessElo,
              },
            );
          }
        });
  }

  void _leaveOnlineRoom() {
    _cancelDisconnectTimer();
    _channel?.unsubscribe();
    _channel = null;
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  void pause({bool save = true}) {
    if (_state.isGameOver ||
        _state.isPaused ||
        _state.mode.isOnlineMultiplayer) {
      return;
    }
    _stopTimer();
    _state = _state.copyWith(isPaused: true);
    if (save) {
      onAutoSave(exportSlot());
    }
    notifyListeners();
  }

  void resume() {
    if (_state.isGameOver || !_state.isPaused) return;
    _state = _state.copyWith(isPaused: false);
    notifyListeners();
    _startTimer();
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_state.isPaused || _state.isGameOver || _state.onlineWaiting) return;
      final nextElapsed = _state.elapsedMs + 100;
      var nextWhite = _state.whiteTimeMs;
      var nextBlack = _state.blackTimeMs;

      if (_state.timeControl != ChessTimeControl.untimed) {
        if (_game.turn == Bishop.white) {
          nextWhite = max(0, nextWhite - 100);
          if (nextWhite == 0) {
            _state = _state.copyWith(
              elapsedMs: nextElapsed,
              whiteTimeMs: 0,
            );
            _endGame(winnerColour: Bishop.black, isDraw: false);
            return;
          }
        } else {
          nextBlack = max(0, nextBlack - 100);
          if (nextBlack == 0) {
            _state = _state.copyWith(
              elapsedMs: nextElapsed,
              blackTimeMs: 0,
            );
            _endGame(winnerColour: Bishop.white, isDraw: false);
            return;
          }
        }
      }

      _state = _state.copyWith(
        elapsedMs: nextElapsed,
        whiteTimeMs: nextWhite,
        blackTimeMs: nextBlack,
      );
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    _cancelDisconnectTimer();
    if (_channel != null &&
        !_state.isGameOver &&
        !_state.onlineWaiting &&
        _state.mode.isOnlineMultiplayer) {
      final resigner = _state.playerColor;
      final winner = resigner == Bishop.white ? Bishop.black : Bishop.white;
      _channel!.sendBroadcastMessage(
        event: 'chess_resign',
        payload: {'winner': winner, 'resignerColor': resigner},
      );
    }
    _leaveOnlineRoom();
    super.dispose();
  }
}
