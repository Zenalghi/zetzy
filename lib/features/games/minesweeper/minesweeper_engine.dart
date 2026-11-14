import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:zetzy/core/constants/app_constants.dart';

enum MineCellMark { none, flag, question }

@immutable
class MineCell {
  const MineCell({
    required this.row,
    required this.col,
    this.isMine = false,
    this.isRevealed = false,
    this.isExploded = false,
    this.isDefused = false,
    this.mark = MineCellMark.none,
    this.adjacentMines = 0,
  });

  final int row;
  final int col;
  final bool isMine;
  final bool isRevealed;
  final bool isExploded;
  final bool isDefused;
  final MineCellMark mark;
  final int adjacentMines;

  MineCell copyWith({
    bool? isMine,
    bool? isRevealed,
    bool? isExploded,
    bool? isDefused,
    MineCellMark? mark,
    int? adjacentMines,
  }) {
    return MineCell(
      row: row,
      col: col,
      isMine: isMine ?? this.isMine,
      isRevealed: isRevealed ?? this.isRevealed,
      isExploded: isExploded ?? this.isExploded,
      isDefused: isDefused ?? this.isDefused,
      mark: mark ?? this.mark,
      adjacentMines: adjacentMines ?? this.adjacentMines,
    );
  }

  Map<String, dynamic> toJson() => {
    'r': row,
    'c': col,
    'm': isMine,
    'rev': isRevealed,
    'exp': isExploded,
    'def': isDefused,
    'mk': mark.index,
    'adj': adjacentMines,
  };

  factory MineCell.fromJson(Map<String, dynamic> j) => MineCell(
    row: (j['r'] as num).toInt(),
    col: (j['c'] as num).toInt(),
    isMine: j['m'] == true,
    isRevealed: j['rev'] == true,
    isExploded: j['exp'] == true,
    isDefused: j['def'] == true,
    mark: MineCellMark.values[(j['mk'] as num?)?.toInt() ?? 0],
    adjacentMines: (j['adj'] as num?)?.toInt() ?? 0,
  );
}

class MinesweeperSpec {
  const MinesweeperSpec(this.rows, this.cols, this.mines, this.hasShield);
  final int rows;
  final int cols;
  final int mines;
  final bool hasShield;

  static MinesweeperSpec forDifficulty(DifficultyLevel diff) => switch (diff) {
    DifficultyLevel.chill => const MinesweeperSpec(8, 8, 8, true),
    DifficultyLevel.easy => const MinesweeperSpec(9, 9, 12, true),
    DifficultyLevel.normal => const MinesweeperSpec(12, 12, 24, false),
    DifficultyLevel.high => const MinesweeperSpec(16, 16, 40, false),
    DifficultyLevel.pro => const MinesweeperSpec(20, 16, 68, false),
    DifficultyLevel.nightmare => const MinesweeperSpec(24, 18, 96, false),
    DifficultyLevel.god => const MinesweeperSpec(28, 22, 138, false),
  };
}

/// Minesweeper board generator, chording solver check, and 3BV calculator.
abstract final class MinesweeperEngine {
  static List<List<MineCell>> createEmptyGrid(int rows, int cols) {
    return List.generate(
      rows,
      (r) => List.generate(cols, (c) => MineCell(row: r, col: c)),
    );
  }

  /// Places mines after first click; tries deduction-friendly layouts on Level 1-4.
  static List<List<MineCell>> populateMines({
    required int rows,
    required int cols,
    required int mineCount,
    required int firstRow,
    required int firstCol,
    required int difficultyLevel,
    Random? random,
  }) {
    final rng = random ?? Random();
    final maxAttempts = difficultyLevel <= 4 ? 18 : 1;

    List<List<MineCell>> bestGrid = createEmptyGrid(rows, cols);
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final candidate = _generateRandomBoard(
        rows: rows,
        cols: cols,
        mineCount: mineCount,
        firstRow: firstRow,
        firstCol: firstCol,
        keepNeighborsClear: difficultyLevel <= 4,
        rng: rng,
      );
      bestGrid = candidate;
      if (difficultyLevel > 4 ||
          _isLogicallySolvable(candidate, firstRow, firstCol)) {
        return candidate;
      }
    }
    return bestGrid;
  }

  static List<List<MineCell>> _generateRandomBoard({
    required int rows,
    required int cols,
    required int mineCount,
    required int firstRow,
    required int firstCol,
    required bool keepNeighborsClear,
    required Random rng,
  }) {
    final candidates = <(int, int)>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (keepNeighborsClear) {
          if ((r - firstRow).abs() <= 1 && (c - firstCol).abs() <= 1) continue;
        } else {
          if (r == firstRow && c == firstCol) continue;
        }
        candidates.add((r, c));
      }
    }
    candidates.shuffle(rng);
    final mineSet = candidates.take(min(mineCount, candidates.length)).toSet();

    final grid = createEmptyGrid(rows, cols);
    for (final (r, c) in mineSet) {
      grid[r][c] = grid[r][c].copyWith(isMine: true);
    }

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (grid[r][c].isMine) continue;
        var adj = 0;
        for (final (nr, nc) in neighbors(rows, cols, r, c)) {
          if (grid[nr][nc].isMine) adj++;
        }
        grid[r][c] = grid[r][c].copyWith(adjacentMines: adj);
      }
    }
    return grid;
  }

  static Iterable<(int, int)> neighbors(
    int rows,
    int cols,
    int r,
    int c,
  ) sync* {
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = r + dr;
        final nc = c + dc;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
          yield (nr, nc);
        }
      }
    }
  }

  /// Calculates Bechtel's Board Benchmark Value (3BV) for speedrun scoring.
  static int compute3BV(List<List<MineCell>> grid) {
    final rows = grid.length;
    final cols = grid[0].length;
    final visited = List.generate(rows, (_) => List.filled(cols, false));
    var bbbv = 0;

    // 1. Count zero-openings and mark all cells uncovered by their flood fill.
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final cell = grid[r][c];
        if (!cell.isMine && cell.adjacentMines == 0 && !visited[r][c]) {
          bbbv++;
          final q = Queue<(int, int)>()..add((r, c));
          visited[r][c] = true;
          while (q.isNotEmpty) {
            final (cr, cc) = q.removeFirst();
            if (grid[cr][cc].adjacentMines == 0) {
              for (final (nr, nc) in neighbors(rows, cols, cr, cc)) {
                if (!visited[nr][nc] && !grid[nr][nc].isMine) {
                  visited[nr][nc] = true;
                  if (grid[nr][nc].adjacentMines == 0) {
                    q.add((nr, nc));
                  }
                }
              }
            }
          }
        }
      }
    }

    // 2. Count remaining unvisited non-mine cells.
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (!grid[r][c].isMine && !visited[r][c]) {
          bbbv++;
        }
      }
    }
    return max(1, bbbv);
  }

  /// Lightweight logical-deduction check (single-cell + basic subset).
  static bool _isLogicallySolvable(
    List<List<MineCell>> grid,
    int startR,
    int startC,
  ) {
    final rows = grid.length;
    final cols = grid[0].length;
    final opened = List.generate(rows, (_) => List.filled(cols, false));
    final flagged = List.generate(rows, (_) => List.filled(cols, false));

    void flood(int sr, int sc) {
      final q = Queue<(int, int)>()..add((sr, sc));
      opened[sr][sc] = true;
      while (q.isNotEmpty) {
        final (r, c) = q.removeFirst();
        if (grid[r][c].adjacentMines == 0) {
          for (final (nr, nc) in neighbors(rows, cols, r, c)) {
            if (!opened[nr][nc] && !grid[nr][nc].isMine) {
              opened[nr][nc] = true;
              if (grid[nr][nc].adjacentMines == 0) q.add((nr, nc));
            }
          }
        }
      }
    }

    flood(startR, startC);

    var progressed = true;
    while (progressed) {
      progressed = false;
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          if (!opened[r][c] || grid[r][c].adjacentMines == 0) continue;
          final closedNeighbors = <(int, int)>[];
          var flagCount = 0;
          for (final (nr, nc) in neighbors(rows, cols, r, c)) {
            if (flagged[nr][nc]) {
              flagCount++;
            } else if (!opened[nr][nc]) {
              closedNeighbors.add((nr, nc));
            }
          }
          if (closedNeighbors.isEmpty) continue;
          if (grid[r][c].adjacentMines - flagCount == closedNeighbors.length) {
            for (final (nr, nc) in closedNeighbors) {
              flagged[nr][nc] = true;
              progressed = true;
            }
          } else if (flagCount == grid[r][c].adjacentMines) {
            for (final (nr, nc) in closedNeighbors) {
              if (!grid[nr][nc].isMine) {
                flood(nr, nc);
                progressed = true;
              }
            }
          }
        }
      }
    }

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (!grid[r][c].isMine && !opened[r][c]) return false;
      }
    }
    return true;
  }
}
