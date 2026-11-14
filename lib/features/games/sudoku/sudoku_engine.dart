import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:zetzy/core/constants/app_constants.dart';

class SudokuPuzzle {
  const SudokuPuzzle({required this.puzzle, required this.solution});
  final List<int> puzzle; // 81 ints (0 = empty)
  final List<int> solution; // 81 ints (1..9)
}

/// Real-time Sudoku generator (Isolate for Levels 1..6) and 17-clue Master Seed
/// transformer for Level 7 (PRD 36B).
abstract final class SudokuEngine {
  /// Verified 17-clue minimal Sudoku master seeds (uniquely solvable).
  static const List<String> _master17Seeds = [
    '000000010400000000020000000000050407008000300001090000300400200050100000000806000',
    '000000012000035000000600070700000300000400800100000000000120000080000040050000600',
    '000700000100000000000430200000000006000509000000000418000081000002000050040000300',
  ];

  static int cluesForDifficulty(DifficultyLevel diff) => switch (diff) {
    DifficultyLevel.chill => 48,
    DifficultyLevel.easy => 42,
    DifficultyLevel.normal => 36,
    DifficultyLevel.high => 31,
    DifficultyLevel.pro => 27,
    DifficultyLevel.nightmare => 23,
    DifficultyLevel.god => 17,
  };

  /// Generates a puzzle asynchronously (off the UI thread for Levels 1-6).
  static Future<SudokuPuzzle> generateAsync(DifficultyLevel diff) async {
    if (diff == DifficultyLevel.god) {
      return _generateFromMasterSeed();
    }
    return compute(_generateRealtime, diff.level);
  }

  static SudokuPuzzle _generateFromMasterSeed([Random? random]) {
    final rng = random ?? Random();
    final seedStr = _master17Seeds[rng.nextInt(_master17Seeds.length)];
    final basePuzzle = seedStr.split('').map(int.parse).toList();
    final baseSolution = List<int>.from(basePuzzle);
    _solve(baseSolution, rng);

    // Mathematical equivalence transformations:
    // 1. Digit permutation (1..9)
    final digits = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(rng);
    int mapDigit(int d) => d == 0 ? 0 : digits[d - 1];

    // 2. Band/stack & row/col permutations within bands
    final rowPerm = _shuffledBandIndices(rng);
    final colPerm = _shuffledBandIndices(rng);
    final transpose = rng.nextBool();

    final puzzle = List<int>.filled(81, 0);
    final solution = List<int>.filled(81, 0);

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final sr = transpose ? colPerm[c] : rowPerm[r];
        final sc = transpose ? rowPerm[r] : colPerm[c];
        final srcIdx = sr * 9 + sc;
        final dstIdx = r * 9 + c;
        puzzle[dstIdx] = mapDigit(basePuzzle[srcIdx]);
        solution[dstIdx] = mapDigit(baseSolution[srcIdx]);
      }
    }

    return SudokuPuzzle(puzzle: puzzle, solution: solution);
  }

  static List<int> _shuffledBandIndices(Random rng) {
    final bands = [0, 1, 2]..shuffle(rng);
    final result = <int>[];
    for (final b in bands) {
      final rows = [0, 1, 2]..shuffle(rng);
      for (final r in rows) {
        result.add(b * 3 + r);
      }
    }
    return result;
  }

  static SudokuPuzzle _generateRealtime(int level) {
    final rng = Random();
    final solution = List<int>.filled(81, 0);
    _solve(solution, rng);

    final puzzle = List<int>.from(solution);
    final targetClues = cluesForDifficulty(DifficultyLevel.fromLevel(level));
    final indices = List<int>.generate(81, (i) => i)..shuffle(rng);

    var clues = 81;
    for (final idx in indices) {
      if (clues <= targetClues) break;
      final backup = puzzle[idx];
      puzzle[idx] = 0;
      if (_countSolutions(List<int>.from(puzzle), limit: 2) != 1) {
        puzzle[idx] = backup;
      } else {
        clues--;
      }
    }

    return SudokuPuzzle(puzzle: puzzle, solution: solution);
  }

  static bool _solve(List<int> board, Random rng) {
    var bestIdx = -1;
    var bestCandidates = <int>[];

    for (var i = 0; i < 81; i++) {
      if (board[i] != 0) continue;
      final r = i ~/ 9;
      final c = i % 9;
      final cands = <int>[];
      for (var v = 1; v <= 9; v++) {
        if (_isSafe(board, r, c, v)) cands.add(v);
      }
      if (cands.isEmpty) return false;
      if (bestIdx == -1 || cands.length < bestCandidates.length) {
        bestIdx = i;
        bestCandidates = cands;
        if (cands.length == 1) break;
      }
    }

    if (bestIdx == -1) return true;
    bestCandidates.shuffle(rng);

    for (final val in bestCandidates) {
      board[bestIdx] = val;
      if (_solve(board, rng)) return true;
      board[bestIdx] = 0;
    }
    return false;
  }

  static int _countSolutions(List<int> board, {int limit = 2}) {
    var bestIdx = -1;
    var bestCandidates = <int>[];

    for (var i = 0; i < 81; i++) {
      if (board[i] != 0) continue;
      final r = i ~/ 9;
      final c = i % 9;
      final cands = <int>[];
      for (var v = 1; v <= 9; v++) {
        if (_isSafe(board, r, c, v)) cands.add(v);
      }
      if (cands.isEmpty) return 0;
      if (bestIdx == -1 || cands.length < bestCandidates.length) {
        bestIdx = i;
        bestCandidates = cands;
        if (cands.length == 1) break;
      }
    }

    if (bestIdx == -1) return 1;
    var total = 0;
    for (final v in bestCandidates) {
      board[bestIdx] = v;
      total += _countSolutions(board, limit: limit - total);
      board[bestIdx] = 0;
      if (total >= limit) return total;
    }
    return total;
  }

  static bool _isSafe(List<int> board, int row, int col, int val) {
    for (var i = 0; i < 9; i++) {
      if (board[row * 9 + i] == val) return false;
      if (board[i * 9 + col] == val) return false;
    }
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        if (board[(br + r) * 9 + (bc + c)] == val) return false;
      }
    }
    return true;
  }

  /// Checks whether cell [index] conflicts with any other cell in row/col/box.
  static bool hasConflict(List<int> board, int index) {
    final val = board[index];
    if (val == 0) return false;
    final row = index ~/ 9;
    final col = index % 9;
    for (var i = 0; i < 9; i++) {
      if (i != col && board[row * 9 + i] == val) return true;
      if (i != row && board[i * 9 + col] == val) return true;
    }
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        final idx = (br + r) * 9 + (bc + c);
        if (idx != index && board[idx] == val) return true;
      }
    }
    return false;
  }
}
