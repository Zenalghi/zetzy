import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/services/audio_service.dart';
import 'package:zetzy/core/services/haptic_service.dart';
import 'package:zetzy/data/models/auto_save_slot.dart';
import 'package:zetzy/features/games/sudoku/sudoku_engine.dart';

@immutable
class SudokuGameState {
  const SudokuGameState({
    required this.difficulty,
    required this.isPractice,
    required this.givens,
    required this.values,
    required this.solution,
    required this.notes,
    required this.errorCells,
    required this.selectedCell,
    required this.lockedDigit,
    required this.notesMode,
    required this.maxLives,
    required this.livesLeft,
    required this.mistakes,
    required this.hintsLeft,
    required this.elapsedMs,
    required this.isLoading,
    required this.isPaused,
    required this.isGameOver,
    required this.isWon,
    required this.canUndoNote,
  });

  final DifficultyLevel difficulty;
  final bool isPractice;
  final List<int> givens;
  final List<int> values;
  final List<int> solution;
  final List<Set<int>> notes;
  final Set<int> errorCells;
  final int? selectedCell;
  final int? lockedDigit;
  final bool notesMode;
  final int maxLives; // 0 = unlimited
  final int livesLeft;
  final int mistakes;
  final int hintsLeft;
  final int elapsedMs;
  final bool isLoading;
  final bool isPaused;
  final bool isGameOver;
  final bool isWon;
  final bool canUndoNote;

  bool get unlimitedLives => isPractice || maxLives == 0;
  bool get checksAnswerKeyImmediately => difficulty.level <= 4;

  /// Cells that are given clues, or already answered correctly in levels 1–4,
  /// cannot be overwritten or erased.
  bool isCellLocked(int index) =>
      givens[index] != 0 ||
      (checksAnswerKeyImmediately && values[index] == solution[index]);

  int? get highlightedDigit {
    if (lockedDigit != null) return lockedDigit;
    if (selectedCell != null && values[selectedCell!] != 0) {
      return values[selectedCell!];
    }
    return null;
  }

  int countDigit(int digit) {
    var count = 0;
    for (final v in values) {
      if (v == digit) count++;
    }
    return count;
  }

  SudokuGameState copyWith({
    List<int>? values,
    List<Set<int>>? notes,
    Set<int>? errorCells,
    int? selectedCell,
    bool clearSelected = false,
    int? lockedDigit,
    bool clearLockedDigit = false,
    bool? notesMode,
    int? livesLeft,
    int? mistakes,
    int? hintsLeft,
    int? elapsedMs,
    bool? isLoading,
    bool? isPaused,
    bool? isGameOver,
    bool? isWon,
    bool? canUndoNote,
  }) {
    return SudokuGameState(
      difficulty: difficulty,
      isPractice: isPractice,
      givens: givens,
      values: values ?? this.values,
      solution: solution,
      notes: notes ?? this.notes,
      errorCells: errorCells ?? this.errorCells,
      selectedCell: clearSelected ? null : (selectedCell ?? this.selectedCell),
      lockedDigit: clearLockedDigit ? null : (lockedDigit ?? this.lockedDigit),
      notesMode: notesMode ?? this.notesMode,
      maxLives: maxLives,
      livesLeft: livesLeft ?? this.livesLeft,
      mistakes: mistakes ?? this.mistakes,
      hintsLeft: hintsLeft ?? this.hintsLeft,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      isLoading: isLoading ?? this.isLoading,
      isPaused: isPaused ?? this.isPaused,
      isGameOver: isGameOver ?? this.isGameOver,
      isWon: isWon ?? this.isWon,
      canUndoNote: canUndoNote ?? this.canUndoNote,
    );
  }
}

class SudokuController extends ChangeNotifier {
  SudokuController({
    required this._audio,
    required this._haptics,
    required this.onFinished,
    required this.onAutoSave,
  });

  final AudioService _audio;
  final HapticService _haptics;
  final void Function(SudokuGameState finalState) onFinished;
  final void Function(AutoSaveSlot slot) onAutoSave;

  Timer? _timer;
  final List<List<Set<int>>> _notesUndoStack = [];
  late SudokuGameState _state;
  SudokuGameState get state => _state;

  static int maxLivesFor(DifficultyLevel diff, bool isPractice) {
    if (isPractice || diff.level == 1) return 0; // Unlimited
    if (diff.level <= 3) return 5;
    if (diff.level <= 5) return 3;
    if (diff.level == 6) return 2;
    return 1; // Level 7: Sudden Death
  }

  Future<void> startNew({
    required DifficultyLevel difficulty,
    required bool isPractice,
  }) async {
    _stopTimer();
    _notesUndoStack.clear();
    final lives = maxLivesFor(difficulty, isPractice);

    _state = SudokuGameState(
      difficulty: difficulty,
      isPractice: isPractice,
      givens: List.filled(81, 0),
      values: List.filled(81, 0),
      solution: List.filled(81, 0),
      notes: List.generate(81, (_) => <int>{}),
      errorCells: const {},
      selectedCell: null,
      lockedDigit: null,
      notesMode: false,
      maxLives: lives,
      livesLeft: lives,
      mistakes: 0,
      hintsLeft: 3,
      elapsedMs: 0,
      isLoading: true,
      isPaused: false,
      isGameOver: false,
      isWon: false,
      canUndoNote: false,
    );
    notifyListeners();

    final generated = await SudokuEngine.generateAsync(difficulty);
    _state = SudokuGameState(
      difficulty: difficulty,
      isPractice: isPractice,
      givens: generated.puzzle,
      values: List<int>.from(generated.puzzle),
      solution: generated.solution,
      notes: List.generate(81, (_) => <int>{}),
      errorCells: const {},
      selectedCell: null,
      lockedDigit: null,
      notesMode: false,
      maxLives: lives,
      livesLeft: lives,
      mistakes: 0,
      hintsLeft: 3,
      elapsedMs: 0,
      isLoading: false,
      isPaused: false,
      isGameOver: false,
      isWon: false,
      canUndoNote: false,
    );
    notifyListeners();
    _startTimer();
  }

  void restoreFromSlot(AutoSaveSlot slot) {
    _stopTimer();
    _notesUndoStack.clear();
    final s = slot.stateJson;
    final diff = DifficultyLevel.fromLevel(slot.difficulty);
    final isPractice = s['isPractice'] == true;
    final maxLives = maxLivesFor(diff, isPractice);

    final givens = ((s['givens'] as List?) ?? []).map((e) => (e as num).toInt()).toList();
    final values = ((s['values'] as List?) ?? []).map((e) => (e as num).toInt()).toList();
    final solution = ((s['solution'] as List?) ?? []).map((e) => (e as num).toInt()).toList();
    final notesRaw = (s['notes'] as List?) ?? [];
    final notes = List.generate(81, (i) {
      if (i >= notesRaw.length) return <int>{};
      return (notesRaw[i] as List).map((e) => (e as num).toInt()).toSet();
    });

    _state = SudokuGameState(
      difficulty: diff,
      isPractice: isPractice,
      givens: givens,
      values: values,
      solution: solution,
      notes: notes,
      errorCells: ((s['errorCells'] as List?) ?? [])
          .map((e) => (e as num).toInt())
          .toSet(),
      selectedCell: null,
      lockedDigit: null,
      notesMode: false,
      maxLives: maxLives,
      livesLeft: (s['livesLeft'] as num?)?.toInt() ?? maxLives,
      mistakes: (s['mistakes'] as num?)?.toInt() ?? 0,
      hintsLeft: (s['hintsLeft'] as num?)?.toInt() ?? 3,
      elapsedMs: slot.elapsedMs,
      isLoading: false,
      isPaused: true,
      isGameOver: false,
      isWon: false,
      canUndoNote: false,
    );
    notifyListeners();
  }

  AutoSaveSlot exportSlot() {
    return AutoSaveSlot(
      gameType: GameType.sudoku,
      difficulty: _state.difficulty.level,
      elapsedMs: _state.elapsedMs,
      updatedAt: DateTime.now().toUtc(),
      stateJson: {
        'isPractice': _state.isPractice,
        'givens': _state.givens,
        'values': _state.values,
        'solution': _state.solution,
        'notes': _state.notes.map((n) => n.toList()).toList(),
        'errorCells': _state.errorCells.toList(),
        'livesLeft': _state.livesLeft,
        'mistakes': _state.mistakes,
        'hintsLeft': _state.hintsLeft,
      },
    );
  }

  void selectCell(int index) {
    if (_state.isLoading || _state.isPaused || _state.isGameOver) return;
    _state = _state.copyWith(selectedCell: index);
    if (_state.lockedDigit != null) {
      _applyDigitToCell(index, _state.lockedDigit!);
    } else {
      notifyListeners();
    }
  }

  void moveSelection(int dRow, int dCol) {
    final current = _state.selectedCell ?? 0;
    final r = ((current ~/ 9) + dRow).clamp(0, 8);
    final c = ((current % 9) + dCol).clamp(0, 8);
    _state = _state.copyWith(selectedCell: r * 9 + c);
    notifyListeners();
  }

  void toggleNotesMode() {
    _state = _state.copyWith(notesMode: !_state.notesMode);
    notifyListeners();
  }

  void toggleDigitLock(int digit) {
    if (_state.lockedDigit == digit) {
      _state = _state.copyWith(clearLockedDigit: true);
    } else {
      _state = _state.copyWith(lockedDigit: digit);
    }
    _haptics.selection();
    notifyListeners();
  }

  void onDigitTap(int digit) {
    if (_state.isLoading || _state.isPaused || _state.isGameOver) return;
    if (_state.lockedDigit == digit) {
      _state = _state.copyWith(clearLockedDigit: true);
      notifyListeners();
      return;
    }
    if (_state.lockedDigit != null) {
      _state = _state.copyWith(lockedDigit: digit);
      notifyListeners();
      return;
    }
    final sel = _state.selectedCell;
    if (sel == null) {
      // Digit-first quick selection if no cell chosen yet
      _state = _state.copyWith(lockedDigit: digit);
      notifyListeners();
      return;
    }
    _applyDigitToCell(sel, digit);
  }

  void _applyDigitToCell(int index, int digit) {
    if (_state.isCellLocked(index)) return;

    if (_state.notesMode) {
      if (_state.values[index] != 0) return;
      _pushNotesUndo();
      final nextNotes = _cloneNotes(_state.notes);
      if (nextNotes[index].contains(digit)) {
        nextNotes[index].remove(digit);
      } else {
        nextNotes[index].add(digit);
      }
      _audio.playSfx(ZetzySfx.sudokuTap);
      _haptics.selection();
      _state = _state.copyWith(
        notes: nextNotes,
        canUndoNote: _notesUndoStack.isNotEmpty,
      );
      notifyListeners();
      return;
    }

    // Standard digit entry
    final nextValues = List<int>.from(_state.values);
    final nextErrors = Set<int>.from(_state.errorCells);
    final nextNotes = _cloneNotes(_state.notes);

    if (nextValues[index] == digit) {
      // Toggle off same number unless locked
      return;
    }

    nextValues[index] = digit;
    nextNotes[index].clear();

    var nextLives = _state.livesLeft;
    var nextMistakes = _state.mistakes;

    if (_state.checksAnswerKeyImmediately) {
      if (digit != _state.solution[index]) {
        nextErrors.add(index);
        nextMistakes++;
        _audio.playSfx(ZetzySfx.errorBuzz);
        _haptics.heavy();
        if (!_state.unlimitedLives) {
          nextLives--;
        }
      } else {
        nextErrors.remove(index);
        _removePeerNotes(nextNotes, index, digit);
        _audio.playSfx(ZetzySfx.sudokuTap);
        _haptics.light();
      }
    } else {
      // Level 5-7: conflict-only detection (PRD 30C)
      _recomputeConflicts(nextValues, nextErrors);
      _removePeerNotes(nextNotes, index, digit);
      if (nextErrors.contains(index)) {
        _audio.playSfx(ZetzySfx.errorBuzz);
        _haptics.medium();
      } else {
        _audio.playSfx(ZetzySfx.sudokuTap);
        _haptics.light();
      }
    }

    _state = _state.copyWith(
      values: nextValues,
      notes: nextNotes,
      errorCells: nextErrors,
      livesLeft: nextLives,
      mistakes: nextMistakes,
    );

    if (!_state.unlimitedLives && nextLives <= 0) {
      _endGame(won: false);
      return;
    }

    _checkCompletion();
  }

  void eraseSelected() {
    final idx = _state.selectedCell;
    if (idx == null || _state.isPaused || _state.isGameOver) return;
    if (_state.isCellLocked(idx)) return;

    final nextValues = List<int>.from(_state.values);
    final nextErrors = Set<int>.from(_state.errorCells);
    if (nextValues[idx] != 0) {
      nextValues[idx] = 0;
      nextErrors.remove(idx);
      if (!_state.checksAnswerKeyImmediately) {
        _recomputeConflicts(nextValues, nextErrors);
      }
    } else if (_state.notes[idx].isNotEmpty) {
      _pushNotesUndo();
      final nextNotes = _cloneNotes(_state.notes);
      nextNotes[idx].clear();
      _state = _state.copyWith(
        notes: nextNotes,
        canUndoNote: _notesUndoStack.isNotEmpty,
      );
      notifyListeners();
      return;
    }

    _state = _state.copyWith(values: nextValues, errorCells: nextErrors);
    notifyListeners();
  }

  /// PRD 35B: Undo ONLY reverses pencil notes, never value mistakes.
  void undoNotes() {
    if (_notesUndoStack.isEmpty || _state.isPaused || _state.isGameOver) {
      return;
    }
    final previousNotes = _notesUndoStack.removeLast();
    _state = _state.copyWith(
      notes: previousNotes,
      canUndoNote: _notesUndoStack.isNotEmpty,
    );
    _haptics.selection();
    notifyListeners();
  }

  /// PRD 34C: Up to 3 free hints per game.
  void useHint() {
    if (_state.hintsLeft <= 0 ||
        _state.isLoading ||
        _state.isPaused ||
        _state.isGameOver) {
      return;
    }

    int? target = _state.selectedCell;
    if (target == null ||
        _state.givens[target] != 0 ||
        _state.values[target] == _state.solution[target]) {
      target = null;
      for (var i = 0; i < 81; i++) {
        if (_state.values[i] != _state.solution[i]) {
          target = i;
          break;
        }
      }
    }
    if (target == null) return;

    final digit = _state.solution[target];
    final nextValues = List<int>.from(_state.values)..[target] = digit;
    final nextErrors = Set<int>.from(_state.errorCells)..remove(target);
    final nextNotes = _cloneNotes(_state.notes);
    nextNotes[target].clear();
    _removePeerNotes(nextNotes, target, digit);

    if (!_state.checksAnswerKeyImmediately) {
      _recomputeConflicts(nextValues, nextErrors);
    }

    _audio.playSfx(ZetzySfx.sudokuTap);
    _haptics.medium();

    _state = _state.copyWith(
      values: nextValues,
      notes: nextNotes,
      errorCells: nextErrors,
      selectedCell: target,
      hintsLeft: _state.hintsLeft - 1,
    );
    _checkCompletion();
  }

  void _checkCompletion() {
    if (_state.values.contains(0)) {
      notifyListeners();
      return;
    }

    // Check if board has any conflicts
    for (var i = 0; i < 81; i++) {
      if (SudokuEngine.hasConflict(_state.values, i)) {
        if (!_state.checksAnswerKeyImmediately) {
          final nextErrors = <int>{};
          _recomputeConflicts(_state.values, nextErrors);
          _state = _state.copyWith(errorCells: nextErrors);
        }
        notifyListeners();
        return;
      }
    }

    // Valid solved Sudoku!
    _endGame(won: true);
  }

  void _removePeerNotes(List<Set<int>> notes, int index, int digit) {
    final row = index ~/ 9;
    final col = index % 9;
    for (var i = 0; i < 9; i++) {
      notes[row * 9 + i].remove(digit);
      notes[i * 9 + col].remove(digit);
    }
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        notes[(br + r) * 9 + (bc + c)].remove(digit);
      }
    }
  }

  void _recomputeConflicts(List<int> values, Set<int> errors) {
    errors.clear();
    for (var i = 0; i < 81; i++) {
      if (SudokuEngine.hasConflict(values, i)) {
        errors.add(i);
      }
    }
  }

  void _pushNotesUndo() {
    _notesUndoStack.add(_cloneNotes(_state.notes));
    if (_notesUndoStack.length > 40) {
      _notesUndoStack.removeAt(0);
    }
  }

  List<Set<int>> _cloneNotes(List<Set<int>> src) =>
      src.map((s) => Set<int>.from(s)).toList();

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
    if (_state.isLoading || _state.isGameOver || _state.isPaused) return;
    _stopTimer();
    _state = _state.copyWith(isPaused: true);
    if (save) {
      onAutoSave(exportSlot());
    }
    notifyListeners();
  }

  void resume() {
    if (_state.isLoading || _state.isGameOver || !_state.isPaused) return;
    _state = _state.copyWith(isPaused: false);
    notifyListeners();
    _startTimer();
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_state.isPaused || _state.isGameOver || _state.isLoading) return;
      _state = _state.copyWith(elapsedMs: _state.elapsedMs + 50);
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
    super.dispose();
  }
}
