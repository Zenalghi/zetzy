import 'dart:math';

import 'package:bishop/bishop.dart';
import 'package:flutter/foundation.dart';

/// Pure-Dart Alpha-Beta + Quiescence + Piece-Square Tables AI engine running
/// in a background Isolate (`compute`). Designed to scale across Levels 1..7.
abstract final class ChessAiEngine {
  static const List<int> aiRatings = [700, 950, 1200, 1450, 1750, 2050, 2400];

  static int aiRatingForLevel(int level) =>
      aiRatings[(level - 1).clamp(0, aiRatings.length - 1)];

  /// Computes ELO rating update using standard K=32 formula.
  static int calculateNewElo({
    required int currentElo,
    required int opponentElo,
    required double score, // 1.0 win, 0.5 draw, 0.0 loss
  }) {
    const k = 32.0;
    final expected =
        1.0 / (1.0 + pow(10.0, (opponentElo - currentElo) / 400.0));
    return (currentElo + k * (score - expected)).round().clamp(400, 3500);
  }

  static Future<String?> findBestMoveAlgebraic({
    required String fen,
    required int level,
  }) async {
    return compute(_searchEntry, {'fen': fen, 'level': level});
  }

  static String? _searchEntry(Map<String, dynamic> args) {
    final fen = args['fen'] as String;
    final level = (args['level'] as int).clamp(1, 7);
    final game = Game(variant: Variant.standard(), fen: fen);
    final legalMoves = game.generateLegalMoves();
    if (legalMoves.isEmpty) return null;

    final rng = Random();
    if (level == 1 && rng.nextDouble() < 0.65) {
      return game.toAlgebraic(legalMoves[rng.nextInt(legalMoves.length)]);
    }

    final (maxDepth, timeLimitMs, useQuiescence) = switch (level) {
      1 => (1, 150, false),
      2 => (1, 250, false),
      3 => (2, 450, false),
      4 => (3, 750, false),
      5 => (3, 1200, true),
      6 => (4, 1800, true),
      _ => (5, 2800, true),
    };

    final deadline = DateTime.now().millisecondsSinceEpoch + timeLimitMs;
    final player = game.turn;
    final ordered = _orderMoves(game, legalMoves);

    Move bestMove = ordered.first;
    for (var depth = 1; depth <= maxDepth; depth++) {
      var currentBest = ordered.first;
      var bestScore = -999999;
      final scores = <Move, int>{};

      for (final move in ordered) {
        game.makeMove(move, false);
        final score = -_alphaBeta(
          game: game,
          depth: depth - 1,
          alpha: -999999,
          beta: 999999,
          player: game.turn,
          useQuiescence: useQuiescence,
          deadlineMs: deadline,
        );
        game.undo();
        scores[move] = score;
        if (score > bestScore) {
          bestScore = score;
          currentBest = move;
        }
        if (DateTime.now().millisecondsSinceEpoch >= deadline && depth > 1) {
          return game.toAlgebraic(bestMove);
        }
      }

      // Level 2 slight inaccuracy noise
      if (level == 2 && ordered.length > 1 && rng.nextDouble() < 0.25) {
        ordered.sort((a, b) => (scores[b] ?? 0).compareTo(scores[a] ?? 0));
        bestMove = ordered[min(1, ordered.length - 1)];
      } else {
        bestMove = currentBest;
        ordered.sort((a, b) => (scores[b] ?? 0).compareTo(scores[a] ?? 0));
      }

      // Stop early if forced mate found
      if (bestScore > 80000 && player == game.turn) break;
    }

    return game.toAlgebraic(bestMove);
  }

  static int _alphaBeta({
    required Game game,
    required int depth,
    required int alpha,
    required int beta,
    required Colour player,
    required bool useQuiescence,
    required int deadlineMs,
  }) {
    if (game.drawn) return 0;
    final res = game.result;
    if (res is WonGame) {
      return res.winner == player ? (90000 + depth) : (-90000 - depth);
    }

    final moves = game.generateLegalMoves();
    if (moves.isEmpty) {
      return game.inCheck ? (-90000 - depth) : 0;
    }

    if (depth <= 0) {
      if (useQuiescence) {
        return _quiescence(game, alpha, beta, player, 3);
      }
      return _evaluateBoard(game, player);
    }

    final ordered = _orderMoves(game, moves);
    var a = alpha;
    var best = -999999;

    for (final m in ordered) {
      game.makeMove(m, false);
      final val = -_alphaBeta(
        game: game,
        depth: depth - 1,
        alpha: -beta,
        beta: -a,
        player: player.opponent,
        useQuiescence: useQuiescence,
        deadlineMs: deadlineMs,
      );
      game.undo();

      if (val > best) best = val;
      if (best > a) a = best;
      if (a >= beta) break;
      if (DateTime.now().millisecondsSinceEpoch >= deadlineMs) break;
    }
    return best;
  }

  static int _quiescence(
    Game game,
    int alpha,
    int beta,
    Colour player,
    int maxQDepth,
  ) {
    final standPat = _evaluateBoard(game, player);
    if (standPat >= beta || maxQDepth <= 0) return standPat;
    var a = max(alpha, standPat);

    final captures = game
        .generateLegalMoves()
        .where((m) => m.capture)
        .toList();
    final ordered = _orderMoves(game, captures);

    for (final m in ordered) {
      game.makeMove(m, false);
      final score = -_quiescence(game, -beta, -a, player.opponent, maxQDepth - 1);
      game.undo();
      if (score >= beta) return beta;
      if (score > a) a = score;
    }
    return a;
  }

  static List<Move> _orderMoves(Game game, List<Move> moves) {
    final list = List<Move>.from(moves);
    list.sort((a, b) {
      final scoreA = _movePriority(game, a);
      final scoreB = _movePriority(game, b);
      return scoreB.compareTo(scoreA);
    });
    return list;
  }

  static int _movePriority(Game game, Move move) {
    var score = 0;
    if (move is StandardMove) {
      if (move.capture && move.capturedPiece != null) {
        final victimVal =
            game.variant.pieces[move.capturedPiece!.type].value;
        final attacker = game.board[move.from];
        final attackerVal =
            attacker.isNotEmpty ? game.variant.pieces[attacker.type].value : 100;
        score += 10 * victimVal - attackerVal;
      }
      if (move.promotion) score += 800;
    }
    return score;
  }

  static const _pawnTable = [
    0, 0, 0, 0, 0, 0, 0, 0,
    50, 50, 50, 50, 50, 50, 50, 50,
    10, 10, 20, 30, 30, 20, 10, 10,
    5, 5, 10, 27, 27, 10, 5, 5,
    0, 0, 0, 24, 24, 0, 0, 0,
    5, -5, -10, 0, 0, -10, -5, 5,
    5, 10, 10, -20, -20, 10, 10, 5,
    0, 0, 0, 0, 0, 0, 0, 0,
  ];

  static const _knightTable = [
    -50, -40, -30, -30, -30, -30, -40, -50,
    -40, -20, 0, 0, 0, 0, -20, -40,
    -30, 0, 10, 15, 15, 10, 0, -30,
    -30, 5, 15, 20, 20, 15, 5, -30,
    -30, 0, 15, 20, 20, 15, 0, -30,
    -30, 5, 10, 15, 15, 10, 5, -30,
    -40, -20, 0, 5, 5, 0, -20, -40,
    -50, -40, -30, -30, -30, -30, -40, -50,
  ];

  static int _evaluateBoard(Game game, Colour player) {
    var score = 0;
    final size = game.size;
    for (var rank = 0; rank < 8; rank++) {
      for (var file = 0; file < 8; file++) {
        final sqIdx = size.square(file, rank);
        final sq = game.board[sqIdx];
        if (sq.isEmpty) continue;

        final colour = sq.colour;
        final def = game.variant.pieces[sq.type];
        var val = def.value;

        final tableRank = colour == Bishop.white ? (7 - rank) : rank;
        final tblIdx = tableRank * 8 + file;
        final sym = def.symbol.toUpperCase();
        if (sym == 'P') {
          val += _pawnTable[tblIdx];
        } else if (sym == 'N') {
          val += _knightTable[tblIdx];
        } else if (sym == 'B' || sym == 'Q') {
          // Mild center control bonus
          final centerDist = (3.5 - file).abs() + (3.5 - rank).abs();
          val += ((7 - centerDist) * 4).round();
        }

        if (colour == player) {
          score += val;
        } else {
          score -= val;
        }
      }
    }
    return score;
  }
}
