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

enum ChessPlayMode { vsAi, passAndPlay, online }

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

  bool get canUndo =>
      mode == ChessPlayMode.vsAi &&
      difficulty.level <= 4 &&
      moveSans.length >= 2 &&
      !isAiThinking &&
      !isGameOver;

  ChessUiState copyWith({
    bool? flipped,
    int? turn,
    int? selectedSquare,
    bool clearSelected = false,
    Set<int>? legalTargets,
    int? lastFrom,
    int? lastTo,
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
    bool? isDraw,
    String? onlineRoomCode,
    bool? onlineWaiting,
    List<Move>? pendingPromotionMoves,
    bool clearPromotion = false,
  }) {
    return ChessUiState(
      difficulty: difficulty,
      isPractice: isPractice,
      mode: mode,
      timeControl: timeControl,
      playerColor: playerColor,
      flipped: flipped ?? this.flipped,
      turn: turn ?? this.turn,
      selectedSquare:
          clearSelected ? null : (selectedSquare ?? this.selectedSquare),
      legalTargets: legalTargets ?? this.legalTargets,
      lastFrom: lastFrom ?? this.lastFrom,
      lastTo: lastTo ?? this.lastTo,
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
      winnerColour: winnerColour ?? this.winnerColour,
      isDraw: isDraw ?? this.isDraw,
      onlineRoomCode: onlineRoomCode ?? this.onlineRoomCode,
      onlineWaiting: onlineWaiting ?? this.onlineWaiting,
      pendingPromotionMoves: clearPromotion
          ? null
          : (pendingPromotionMoves ?? this.pendingPromotionMoves),
    );
  }
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
  Game get game => _game;

  Timer? _timer;
  RealtimeChannel? _channel;
  final List<(int?, int?)> _moveSqHistory = [];
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
  }) {
    _stopTimer();
    _leaveOnlineRoom();
    _moveSqHistory.clear();
    _game = Game(variant: Variant.standard());

    final resolvedColor = switch (colorPref) {
      ChessColorPref.white => Bishop.white,
      ChessColorPref.black => Bishop.black,
      ChessColorPref.random =>
        Random().nextBool() ? Bishop.white : Bishop.black,
    };

    final activeRoom = mode == ChessPlayMode.online
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
      onlineWaiting: mode == ChessPlayMode.online,
      pendingPromotionMoves: null,
    );

    if (mode == ChessPlayMode.online && activeRoom != null) {
      _joinOnlineRoom(activeRoom, isHost: isHost);
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
    final s = slot.stateJson;
    final diff = DifficultyLevel.fromLevel(slot.difficulty);
    final pgn = s['pgn'] as String?;
    final fen = s['fen'] as String?;

    if (pgn != null && pgn.trim().isNotEmpty) {
      try {
        _game = Game.fromPgn(pgn);
      } catch (_) {
        _game = Game(variant: Variant.standard(), fen: fen);
      }
    } else {
      _game = Game(variant: Variant.standard(), fen: fen);
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
    if (_state.mode == ChessPlayMode.online &&
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

    final ok = _game.makeMove(move);
    if (!ok) return;

    _moveSqHistory.add((move.from, move.to));

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
    );
    _recomputeMaterialAndCaptures();

    if (_state.mode == ChessPlayMode.online && !fromRemote) {
      _channel?.sendBroadcastMessage(
        event: 'chess_move',
        payload: {'alg': alg},
      );
    }

    if (_checkGameEnd()) return;
    notifyListeners();

    if (_state.mode == ChessPlayMode.vsAi && _game.turn != _state.playerColor) {
      _triggerAiMove();
    }
  }

  Future<void> _triggerAiMove() async {
    _state = _state.copyWith(isAiThinking: true);
    notifyListeners();

    final alg = await ChessAiEngine.findBestMoveAlgebraic(
      fen: _game.fen,
      level: _state.difficulty.level,
    );

    if (_state.isGameOver) return;
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
    final nextSans = _state.moveSans.length >= 2
        ? _state.moveSans.sublist(0, _state.moveSans.length - 2)
        : <String>[];
    final lastPair = _moveSqHistory.isNotEmpty ? _moveSqHistory.last : (null, null);

    _state = _state.copyWith(
      turn: _game.turn,
      clearSelected: true,
      legalTargets: const {},
      lastFrom: lastPair.$1,
      lastTo: lastPair.$2,
      inCheck: _game.inCheck,
      moveSans: nextSans,
    );
    _recomputeMaterialAndCaptures();
    _haptics.selection();
    notifyListeners();
  }

  void resign() {
    if (_state.isGameOver) return;
    final loser = _state.mode == ChessPlayMode.passAndPlay
        ? _game.turn
        : _state.playerColor;
    final winner = loser.opponent;
    if (_state.mode == ChessPlayMode.online) {
      _channel?.sendBroadcastMessage(
        event: 'chess_resign',
        payload: {'winner': winner},
      );
    }
    _endGame(winnerColour: winner, isDraw: false);
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

  void _endGame({required int? winnerColour, required bool isDraw}) {
    _stopTimer();
    _leaveOnlineRoom();
    final playerWon = !isDraw && winnerColour == _state.playerColor;
    _audio.playSfx(playerWon ? ZetzySfx.gameWin : ZetzySfx.mineExplode);
    _state = _state.copyWith(
      isGameOver: true,
      winnerColour: winnerColour,
      isDraw: isDraw,
      isAiThinking: false,
    );
    notifyListeners();
    onFinished(_state);
  }

  void _recomputeMaterialAndCaptures() {
    const startCounts = {'P': 8, 'N': 2, 'B': 2, 'R': 2, 'Q': 1};
    const pieceValues = {'P': 1, 'N': 3, 'B': 3, 'R': 5, 'Q': 9};
    final whiteOnBoard = <String, int>{};
    final blackOnBoard = <String, int>{};
    var whiteMat = 0;
    var blackMat = 0;

    for (var rank = 0; rank < 8; rank++) {
      for (var file = 0; file < 8; file++) {
        final sq = _game.board[_game.size.square(file, rank)];
        if (sq.isEmpty) continue;
        final sym = _game.variant.pieces[sq.type].symbol.toUpperCase();
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

  void _joinOnlineRoom(String code, {required bool isHost}) {
    final ch = _supabase.createChessRoomChannel(code);
    if (ch == null) {
      _state = _state.copyWith(onlineWaiting: false);
      return;
    }
    _channel = ch;
    ch
        .onBroadcast(
          event: 'chess_join',
          callback: (payload) {
            if (_state.onlineWaiting) {
              _state = _state.copyWith(onlineWaiting: false);
              notifyListeners();
              ch.sendBroadcastMessage(
                event: 'chess_ready',
                payload: {'hostColor': _state.playerColor},
              );
            }
          },
        )
        .onBroadcast(
          event: 'chess_ready',
          callback: (payload) {
            _state = _state.copyWith(onlineWaiting: false);
            notifyListeners();
          },
        )
        .onBroadcast(
          event: 'chess_move',
          callback: (payload) {
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
            final winner = (payload['winner'] as num?)?.toInt();
            _endGame(winnerColour: winner, isDraw: false);
          },
        )
        .subscribe((status, _) {
          if (status == RealtimeSubscribeStatus.subscribed && !isHost) {
            ch.sendBroadcastMessage(event: 'chess_join', payload: {});
            _state = _state.copyWith(onlineWaiting: false);
            notifyListeners();
          }
        });
  }

  void _leaveOnlineRoom() {
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
        _state.mode == ChessPlayMode.online) {
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
    _leaveOnlineRoom();
    super.dispose();
  }
}
