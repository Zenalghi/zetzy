import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/services/audio_service.dart';
import 'package:zetzy/core/services/haptic_service.dart';
import 'package:zetzy/data/models/auto_save_slot.dart';
import 'package:zetzy/features/games/minesweeper/minesweeper_engine.dart';

enum MineTapTool { dig, flag, question }

@immutable
class MinesweeperGameState {
  const MinesweeperGameState({
    required this.difficulty,
    required this.isPractice,
    required this.grid,
    required this.totalMines,
    required this.hasStarted,
    required this.shieldRemaining,
    required this.tool,
    required this.elapsedMs,
    required this.isPaused,
    required this.isGameOver,
    required this.isWon,
    required this.bbbv,
    this.practiceHistoryCount = 0,
  });

  final DifficultyLevel difficulty;
  final bool isPractice;
  final List<List<MineCell>> grid;
  final int totalMines;
  final bool hasStarted;
  final int shieldRemaining;
  final MineTapTool tool;
  final int elapsedMs;
  final bool isPaused;
  final bool isGameOver;
  final bool isWon;
  final int bbbv;
  final int practiceHistoryCount;

  bool get canPracticeUndo => isPractice && practiceHistoryCount > 0;

  int get rows => grid.length;
  int get cols => grid.isEmpty ? 0 : grid[0].length;

  int get flagsPlaced {
    var count = 0;
    for (final row in grid) {
      for (final cell in row) {
        if (cell.mark == MineCellMark.flag || cell.isDefused) count++;
      }
    }
    return count;
  }

  int get remainingMines => totalMines - flagsPlaced;

  int get wrongFlagCount {
    var count = 0;
    for (final row in grid) {
      for (final cell in row) {
        if (!cell.isMine && cell.mark == MineCellMark.flag) count++;
      }
    }
    return count;
  }

  double get bbbvPerSec {
    if (elapsedMs <= 0 || bbbv <= 0) return 0;
    return bbbv / (elapsedMs / 1000.0);
  }

  MinesweeperGameState copyWith({
    List<List<MineCell>>? grid,
    bool? hasStarted,
    int? shieldRemaining,
    MineTapTool? tool,
    int? elapsedMs,
    bool? isPaused,
    bool? isGameOver,
    bool? isWon,
    int? bbbv,
    int? practiceHistoryCount,
  }) {
    return MinesweeperGameState(
      difficulty: difficulty,
      isPractice: isPractice,
      grid: grid ?? this.grid,
      totalMines: totalMines,
      hasStarted: hasStarted ?? this.hasStarted,
      shieldRemaining: shieldRemaining ?? this.shieldRemaining,
      tool: tool ?? this.tool,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      isPaused: isPaused ?? this.isPaused,
      isGameOver: isGameOver ?? this.isGameOver,
      isWon: isWon ?? this.isWon,
      bbbv: bbbv ?? this.bbbv,
      practiceHistoryCount: practiceHistoryCount ?? this.practiceHistoryCount,
    );
  }
}

class _MineSnapshot {
  const _MineSnapshot({
    required this.grid,
    required this.hasStarted,
    required this.shieldRemaining,
    required this.elapsedMs,
    required this.bbbv,
  });

  final List<List<MineCell>> grid;
  final bool hasStarted;
  final int shieldRemaining;
  final int elapsedMs;
  final int bbbv;
}

class MinesweeperController extends ChangeNotifier {
  MinesweeperController({
    required this._audio,
    required this._haptics,
    required this.onFinished,
    required this.onAutoSave,
  });

  final AudioService _audio;
  final HapticService _haptics;
  final void Function(MinesweeperGameState finalState) onFinished;
  final void Function(AutoSaveSlot slot) onAutoSave;

  Timer? _timer;
  final List<_MineSnapshot> _practiceHistory = [];
  late MinesweeperGameState _state;
  MinesweeperGameState get state => _state;

  void startNew({
    required DifficultyLevel difficulty,
    required bool isPractice,
  }) {
    _stopTimer();
    _practiceHistory.clear();
    final spec = MinesweeperSpec.forDifficulty(difficulty);
    _state = MinesweeperGameState(
      difficulty: difficulty,
      isPractice: isPractice,
      grid: MinesweeperEngine.createEmptyGrid(spec.rows, spec.cols),
      totalMines: spec.mines,
      hasStarted: false,
      shieldRemaining: spec.hasShield ? 1 : 0,
      tool: MineTapTool.dig,
      elapsedMs: 0,
      isPaused: false,
      isGameOver: false,
      isWon: false,
      bbbv: 0,
    );
    notifyListeners();
  }

  void restoreFromSlot(AutoSaveSlot slot) {
    _stopTimer();
    _practiceHistory.clear();
    final s = slot.stateJson;
    final diff = DifficultyLevel.fromLevel(slot.difficulty);
    final rawGrid = (s['grid'] as List?) ?? [];
    final grid = rawGrid
        .map(
          (row) => (row as List)
              .map(
                (c) => MineCell.fromJson(Map<String, dynamic>.from(c as Map)),
              )
              .toList(),
        )
        .toList();

    _state = MinesweeperGameState(
      difficulty: diff,
      isPractice: s['isPractice'] == true,
      grid: grid,
      totalMines:
          (s['totalMines'] as num?)?.toInt() ??
          MinesweeperSpec.forDifficulty(diff).mines,
      hasStarted: s['hasStarted'] == true,
      shieldRemaining: (s['shieldRemaining'] as num?)?.toInt() ?? 0,
      tool: MineTapTool.dig,
      elapsedMs: slot.elapsedMs,
      isPaused: s['hasStarted'] == true,
      isGameOver: false,
      isWon: false,
      bbbv: (s['bbbv'] as num?)?.toInt() ?? 0,
    );
    notifyListeners();
  }

  AutoSaveSlot exportSlot() {
    return AutoSaveSlot(
      gameType: GameType.minesweeper,
      difficulty: _state.difficulty.level,
      elapsedMs: _state.elapsedMs,
      updatedAt: DateTime.now().toUtc(),
      stateJson: {
        'isPractice': _state.isPractice,
        'totalMines': _state.totalMines,
        'hasStarted': _state.hasStarted,
        'shieldRemaining': _state.shieldRemaining,
        'bbbv': _state.bbbv,
        'grid': _state.grid
            .map((row) => row.map((c) => c.toJson()).toList())
            .toList(),
      },
    );
  }

  void setTool(MineTapTool tool) {
    _state = _state.copyWith(tool: tool);
    notifyListeners();
  }

  void onCellTap(int r, int c) {
    if (_state.isPaused || _state.isGameOver) return;
    final cell = _state.grid[r][c];

    // Chording if tapping an already revealed numbered cell
    if (cell.isRevealed) {
      if (cell.adjacentMines > 0) {
        _chord(r, c);
      }
      return;
    }

    switch (_state.tool) {
      case MineTapTool.dig:
        _digCell(r, c);
      case MineTapTool.flag:
        toggleMark(r, c, explicitFlag: true);
      case MineTapTool.question:
        toggleMark(r, c, explicitQuestion: true);
    }
  }

  void onCellLongPressOrRightClick(int r, int c) {
    if (_state.isPaused || _state.isGameOver) return;
    final cell = _state.grid[r][c];
    if (cell.isRevealed) {
      if (cell.adjacentMines > 0) _chord(r, c);
      return;
    }
    toggleMark(r, c);
  }

  void toggleMark(
    int r,
    int c, {
    bool explicitFlag = false,
    bool explicitQuestion = false,
  }) {
    final cell = _state.grid[r][c];
    if (cell.isRevealed || cell.isDefused) return;
    _pushPracticeSnapshot();

    final MineCellMark nextMark;
    if (explicitFlag) {
      nextMark = cell.mark == MineCellMark.flag
          ? MineCellMark.none
          : MineCellMark.flag;
    } else if (explicitQuestion) {
      nextMark = cell.mark == MineCellMark.question
          ? MineCellMark.none
          : MineCellMark.question;
    } else {
      nextMark = switch (cell.mark) {
        MineCellMark.none => MineCellMark.flag,
        MineCellMark.flag => MineCellMark.question,
        MineCellMark.question => MineCellMark.none,
      };
    }

    final nextGrid = _cloneGrid(_state.grid);
    nextGrid[r][c] = cell.copyWith(mark: nextMark);
    _audio.playSfx(ZetzySfx.mineFlag);
    _haptics.selection();
    _state = _state.copyWith(
      grid: nextGrid,
      practiceHistoryCount: _practiceHistory.length,
    );
    notifyListeners();
  }

  void _digCell(int r, int c) {
    final initialTarget = _state.grid[r][c];
    if (_state.hasStarted &&
        (initialTarget.isRevealed ||
            initialTarget.mark == MineCellMark.flag ||
            initialTarget.isDefused)) {
      return;
    }
    _pushPracticeSnapshot();

    var grid = _cloneGrid(_state.grid);
    var hasStarted = _state.hasStarted;
    var bbbv = _state.bbbv;

    if (!hasStarted) {
      grid = MinesweeperEngine.populateMines(
        rows: _state.rows,
        cols: _state.cols,
        mineCount: _state.totalMines,
        firstRow: r,
        firstCol: c,
        difficultyLevel: _state.difficulty.level,
      );
      bbbv = MinesweeperEngine.compute3BV(grid);
      hasStarted = true;
      _startTimer();
    }

    final target = grid[r][c];
    if (target.isRevealed ||
        target.mark == MineCellMark.flag ||
        target.isDefused) {
      return;
    }

    if (target.isMine) {
      if (_state.shieldRemaining > 0) {
        // Defuse shield absorbs the mine! (PRD 54B)
        grid[r][c] = target.copyWith(
          isDefused: true,
          isRevealed: true,
          mark: MineCellMark.none,
        );
        _audio.playSfx(ZetzySfx.mineShield);
        _haptics.heavy();
        _state = _state.copyWith(
          grid: grid,
          hasStarted: hasStarted,
          bbbv: bbbv,
          shieldRemaining: _state.shieldRemaining - 1,
          practiceHistoryCount: _practiceHistory.length,
        );
        _checkWin();
        return;
      }

      // Explode and reveal all mines
      _revealAllMines(grid, explodedRow: r, explodedCol: c);
      _state = _state.copyWith(
        grid: grid,
        hasStarted: hasStarted,
        bbbv: bbbv,
        practiceHistoryCount: _practiceHistory.length,
      );
      _endGame(won: false);
      return;
    }

    _floodReveal(grid, r, c);
    _audio.playSfx(ZetzySfx.mineDig);
    _haptics.light();
    _state = _state.copyWith(
      grid: grid,
      hasStarted: hasStarted,
      bbbv: bbbv,
      practiceHistoryCount: _practiceHistory.length,
    );
    _checkWin();
  }

  void _chord(int r, int c) {
    final center = _state.grid[r][c];
    if (!center.isRevealed || center.adjacentMines == 0) return;

    var flagOrDefused = 0;
    final toOpen = <(int, int)>[];
    for (final (nr, nc) in MinesweeperEngine.neighbors(
      _state.rows,
      _state.cols,
      r,
      c,
    )) {
      final n = _state.grid[nr][nc];
      if (n.mark == MineCellMark.flag || n.isDefused) {
        flagOrDefused++;
      } else if (!n.isRevealed) {
        toOpen.add((nr, nc));
      }
    }

    if (flagOrDefused != center.adjacentMines || toOpen.isEmpty) return;
    _pushPracticeSnapshot();

    final grid = _cloneGrid(_state.grid);
    var shield = _state.shieldRemaining;
    for (final (nr, nc) in toOpen) {
      final cell = grid[nr][nc];
      if (cell.isMine) {
        if (shield > 0) {
          shield--;
          grid[nr][nc] = cell.copyWith(
            isDefused: true,
            isRevealed: true,
            mark: MineCellMark.none,
          );
          _audio.playSfx(ZetzySfx.mineShield);
          _haptics.heavy();
        } else {
          _revealAllMines(grid, explodedRow: nr, explodedCol: nc);
          _state = _state.copyWith(
            grid: grid,
            shieldRemaining: shield,
            practiceHistoryCount: _practiceHistory.length,
          );
          _endGame(won: false);
          return;
        }
      } else {
        _floodReveal(grid, nr, nc);
      }
    }
    _audio.playSfx(ZetzySfx.mineDig);
    _haptics.light();
    _state = _state.copyWith(
      grid: grid,
      shieldRemaining: shield,
      practiceHistoryCount: _practiceHistory.length,
    );
    _checkWin();
  }

  void _pushPracticeSnapshot() {
    if (!_state.isPractice) return;
    if (_practiceHistory.length >= 35) {
      _practiceHistory.removeAt(0);
    }
    _practiceHistory.add(
      _MineSnapshot(
        grid: _cloneGrid(_state.grid),
        hasStarted: _state.hasStarted,
        shieldRemaining: _state.shieldRemaining,
        elapsedMs: _state.elapsedMs,
        bbbv: _state.bbbv,
      ),
    );
  }

  void practiceUndo() => practiceRewind(1);

  void practiceRewind(int steps) {
    if (!_state.isPractice || _practiceHistory.isEmpty) return;
    final count = min(steps.clamp(1, 3), _practiceHistory.length);
    _MineSnapshot? chosen;
    for (var i = 0; i < count; i++) {
      chosen = _practiceHistory.removeLast();
    }
    if (chosen == null) return;

    _state = _state.copyWith(
      grid: _cloneGrid(chosen.grid),
      hasStarted: chosen.hasStarted,
      shieldRemaining: chosen.shieldRemaining,
      elapsedMs: chosen.elapsedMs,
      bbbv: chosen.bbbv,
      isPaused: false,
      isGameOver: false,
      isWon: false,
      practiceHistoryCount: _practiceHistory.length,
    );
    _haptics.selection();
    notifyListeners();
    if (chosen.hasStarted) {
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  void _floodReveal(List<List<MineCell>> grid, int startR, int startC) {
    final q = Queue<(int, int)>()..add((startR, startC));
    while (q.isNotEmpty) {
      final (r, c) = q.removeFirst();
      final cell = grid[r][c];
      if (cell.isRevealed ||
          cell.isMine ||
          cell.mark == MineCellMark.flag) {
        continue;
      }
      grid[r][c] = cell.copyWith(isRevealed: true, mark: MineCellMark.none);
      if (cell.adjacentMines == 0) {
        for (final (nr, nc) in MinesweeperEngine.neighbors(
          grid.length,
          grid[0].length,
          r,
          c,
        )) {
          if (!grid[nr][nc].isRevealed && !grid[nr][nc].isMine) {
            q.add((nr, nc));
          }
        }
      }
    }
  }

  void _revealAllMines(
    List<List<MineCell>> grid, {
    int? explodedRow,
    int? explodedCol,
  }) {
    for (var r = 0; r < grid.length; r++) {
      for (var c = 0; c < grid[0].length; c++) {
        final cell = grid[r][c];
        if (cell.isMine && !cell.isDefused) {
          grid[r][c] = cell.copyWith(
            isRevealed: true,
            isExploded: r == explodedRow && c == explodedCol,
          );
        }
      }
    }
  }

  void _checkWin() {
    for (final row in _state.grid) {
      for (final cell in row) {
        if (!cell.isMine && !cell.isRevealed) {
          notifyListeners();
          return;
        }
      }
    }
    final revealedGrid = _cloneGrid(_state.grid);
    _revealAllMines(revealedGrid);
    _state = _state.copyWith(grid: revealedGrid);
    _endGame(won: true);
  }

  void _endGame({required bool won}) {
    _stopTimer();
    _audio.playSfx(won ? ZetzySfx.gameWin : ZetzySfx.mineExplode);
    if (won) {
      _haptics.medium();
    } else {
      _haptics.heavy();
    }
    _state = _state.copyWith(isGameOver: true, isWon: won);
    notifyListeners();
    onFinished(_state);
  }

  void pause({bool save = true}) {
    if (_state.isGameOver || _state.isPaused || !_state.hasStarted) return;
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
    if (_state.hasStarted) _startTimer();
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_state.isPaused || _state.isGameOver) return;
      _state = _state.copyWith(elapsedMs: _state.elapsedMs + 50);
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  List<List<MineCell>> _cloneGrid(List<List<MineCell>> source) =>
      source.map((r) => List<MineCell>.from(r)).toList();

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
