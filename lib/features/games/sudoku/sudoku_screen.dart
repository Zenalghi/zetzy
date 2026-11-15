import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/core/widgets/anti_cheat_pause_overlay.dart';
import 'package:zetzy/core/widgets/game_lifecycle_guard.dart';
import 'package:zetzy/core/widgets/game_timer_badge.dart';
import 'package:zetzy/core/widgets/win_result_dialog.dart';
import 'package:zetzy/data/models/auto_save_slot.dart';
import 'package:zetzy/features/games/sudoku/sudoku_controller.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

class SudokuScreen extends ConsumerStatefulWidget {
  const SudokuScreen({
    super.key,
    required this.difficulty,
    this.isPractice = false,
    this.resumeSlot,
  });

  final DifficultyLevel difficulty;
  final bool isPractice;
  final AutoSaveSlot? resumeSlot;

  @override
  ConsumerState<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends ConsumerState<SudokuScreen> {
  late final SudokuController _controller;
  late final AutoSaveSlotsNotifier _autoSaveSlots;
  final FocusNode _focusNode = FocusNode();
  ({SudokuGameState state, int score, bool isNewRecord})? _finishedSummary;

  @override
  void initState() {
    super.initState();
    _autoSaveSlots = ref.read(autoSaveSlotsProvider.notifier);
    _controller = SudokuController(
      audio: ref.read(audioServiceProvider),
      haptics: ref.read(hapticServiceProvider),
      onFinished: _handleGameFinished,
      onAutoSave: (slot) => _autoSaveSlots.saveSlot(slot),
    );

    if (widget.resumeSlot != null) {
      _controller.restoreFromSlot(widget.resumeSlot!);
    } else {
      _controller.startNew(
        difficulty: widget.difficulty,
        isPractice: widget.isPractice,
      );
    }
  }

  void _startNewGame() {
    _finishedSummary = null;
    _controller.startNew(
      difficulty: widget.difficulty,
      isPractice: widget.isPractice,
    );
  }

  Future<void> _handleGameFinished(SudokuGameState finalState) async {
    await ref.read(autoSaveSlotsProvider.notifier).clearSlot(GameType.sudoku);

    final speedBonus = (300000 / (finalState.elapsedMs + 1000)).round();
    final score = finalState.isWon
        ? (finalState.difficulty.level * 200 + speedBonus - finalState.mistakes * 25)
            .clamp(10, 10000)
        : 0;

    final isNewRecord = await ref
        .read(scoreSyncControllerProvider)
        .recordGameResult(
          gameType: GameType.sudoku,
          difficulty: finalState.difficulty.level,
          isWon: finalState.isWon,
          score: score,
          durationMs: finalState.elapsedMs,
          isPractice: finalState.isPractice,
          metadata: {'mistakes': finalState.mistakes},
        );

    final summary = (state: finalState, score: score, isNewRecord: isNewRecord);
    _finishedSummary = summary;

    if (!mounted) return;
    await _showResultDialog(summary);
  }

  Future<void> _showResultDialog(
    ({SudokuGameState state, int score, bool isNewRecord}) summary,
  ) async {
    final finalState = summary.state;
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.read(settingsProvider);
    final canRewind =
        finalState.isPractice &&
        !finalState.isWon &&
        settings.practiceRewindOnLoss &&
        finalState.canUndoPractice;
    await showGameResultDialog(
      context: context,
      gameType: GameType.sudoku,
      difficulty: finalState.difficulty,
      isWon: finalState.isWon,
      durationMs: finalState.elapsedMs,
      score: summary.score,
      isNewRecord: summary.isNewRecord,
      isPractice: finalState.isPractice,
      extraMetrics: [
        (label: l10n.mistakesLabel, value: '${finalState.mistakes}'),
      ],
      rewindSteps: settings.practiceRewindSteps,
      onRewindContinue: canRewind
          ? () {
              _finishedSummary = null;
              _controller.undoPractice(steps: settings.practiceRewindSteps);
            }
          : null,
      onReviewBoard: () {},
      onPlayAgain: _startNewGame,
      onExit: () => Navigator.of(context).pop(),
    );
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final k = event.logicalKey;
    final digits = {
      LogicalKeyboardKey.digit1: 1,
      LogicalKeyboardKey.digit2: 2,
      LogicalKeyboardKey.digit3: 3,
      LogicalKeyboardKey.digit4: 4,
      LogicalKeyboardKey.digit5: 5,
      LogicalKeyboardKey.digit6: 6,
      LogicalKeyboardKey.digit7: 7,
      LogicalKeyboardKey.digit8: 8,
      LogicalKeyboardKey.digit9: 9,
      LogicalKeyboardKey.numpad1: 1,
      LogicalKeyboardKey.numpad2: 2,
      LogicalKeyboardKey.numpad3: 3,
      LogicalKeyboardKey.numpad4: 4,
      LogicalKeyboardKey.numpad5: 5,
      LogicalKeyboardKey.numpad6: 6,
      LogicalKeyboardKey.numpad7: 7,
      LogicalKeyboardKey.numpad8: 8,
      LogicalKeyboardKey.numpad9: 9,
    };
    if (digits.containsKey(k)) {
      _controller.onDigitTap(digits[k]!);
    } else if (k == LogicalKeyboardKey.backspace ||
        k == LogicalKeyboardKey.delete) {
      _controller.eraseSelected();
    } else if (k == LogicalKeyboardKey.keyN) {
      _controller.toggleNotesMode();
    } else if (k == LogicalKeyboardKey.arrowUp) {
      _controller.moveSelection(-1, 0);
    } else if (k == LogicalKeyboardKey.arrowDown) {
      _controller.moveSelection(1, 0);
    } else if (k == LogicalKeyboardKey.arrowLeft) {
      _controller.moveSelection(0, -1);
    } else if (k == LogicalKeyboardKey.arrowRight) {
      _controller.moveSelection(0, 1);
    }
  }

  @override
  void dispose() {
    if (!_controller.state.isLoading && !_controller.state.isGameOver) {
      _autoSaveSlots.saveSlot(_controller.exportSlot());
    }
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;

    return GameLifecycleGuard(
      onAutoPause: () => _controller.pause(),
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              '${l10n.gameSudoku} • ${widget.difficulty.localizedLabel(l10n)}',
            ),
            actions: [
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => Row(
                  children: [
                    GameTimerBadge(
                      elapsedMs: _controller.state.elapsedMs,
                      isPaused: _controller.state.isPaused,
                    ),
                    IconButton(
                      onPressed: () {
                        if (_controller.state.isPaused) {
                          _controller.resume();
                        } else {
                          _controller.pause();
                        }
                      },
                      icon: Icon(
                        _controller.state.isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final s = _controller.state;
              if (s.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 760;
                      if (isWide) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(child: Center(child: _buildGrid(s, p))),
                              const SizedBox(width: 24),
                              SizedBox(
                                width: 360,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildStatusRow(s, p, l10n),
                                    const SizedBox(height: 16),
                                    if (s.isGameOver)
                                      _buildReviewBar(s, p, l10n)
                                    else ...[
                                      _buildActionToolbar(s, p, l10n),
                                      const SizedBox(height: 16),
                                      _buildDigitPad(s, p, keyHeight: 62),
                                      const SizedBox(height: 12),
                                      Text(
                                        l10n.sudokuDigitLockHint,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: p.textSecondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final digitKeyHeight =
                          (constraints.maxHeight * 0.092).clamp(52.0, 70.0);

                      return SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: _buildStatusRow(s, p, l10n),
                              ),
                              const SizedBox(height: 8),
                              Expanded(child: Center(child: _buildGrid(s, p))),
                              const SizedBox(height: 10),
                              if (s.isGameOver)
                                _buildReviewBar(s, p, l10n)
                              else ...[
                                _buildActionToolbar(s, p, l10n),
                                const SizedBox(height: 8),
                                _buildDigitPad(s, p, keyHeight: digitKeyHeight),
                                const SizedBox(height: 4),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  AntiCheatPauseOverlay(
                    isPaused: s.isPaused && !s.isGameOver,
                    onResume: () {
                      _controller.resume();
                      _focusNode.requestFocus();
                    },
                    onRestart: () => _controller.startNew(
                      difficulty: widget.difficulty,
                      isPractice: widget.isPractice,
                    ),
                    onQuit: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    SudokuGameState s,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.favorite_rounded,
              size: 18,
              color: s.unlimitedLives ? p.accent : p.danger,
            ),
            const SizedBox(width: 6),
            Text(
              s.unlimitedLives
                  ? '${l10n.sudokuLives}: ∞'
                  : '${l10n.sudokuLives}: ${s.livesLeft}/${s.maxLives}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
          ],
        ),
        if (!s.checksAnswerKeyImmediately)
          Flexible(
            child: InkWell(
              onTap: () => _showConflictModeDialog(p, l10n),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: p.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        l10n.sudokuConflictOnlyNote,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: p.warning,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.info_outline_rounded,
                      size: 13,
                      color: p.warning,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showConflictModeDialog(ZetzyPalette p, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.border),
        ),
        title: Row(
          children: [
            Icon(Icons.rule_rounded, color: p.warning, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.sudokuConflictGuideTitle,
                style: TextStyle(
                  color: p.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            l10n.sudokuConflictGuideBody,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(SudokuGameState s, ZetzyPalette p) {
    final sel = s.selectedCell;
    final selRow = sel != null ? sel ~/ 9 : -1;
    final selCol = sel != null ? sel % 9 : -1;
    final selBox = sel != null ? (selRow ~/ 3) * 3 + (selCol ~/ 3) : -1;
    final highlightDigit = s.highlightedDigit;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 580, maxHeight: 580),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardSize = math.min(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            final cellSize = boardSize / 9.0;

            return Container(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: p.accent.withValues(alpha: 0.65),
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var r = 0; r < 9; r++)
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var c = 0; c < 9; c++)
                            _buildCell(
                              s: s,
                              p: p,
                              row: r,
                              col: c,
                              cellSize: cellSize,
                              sel: sel,
                              selRow: selRow,
                              selCol: selCol,
                              selBox: selBox,
                              highlightDigit: highlightDigit,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCell({
    required SudokuGameState s,
    required ZetzyPalette p,
    required int row,
    required int col,
    required double cellSize,
    required int? sel,
    required int selRow,
    required int selCol,
    required int selBox,
    required int? highlightDigit,
  }) {
    final idx = row * 9 + col;
    final val = s.values[idx];
    final isGiven = s.givens[idx] != 0;
    final isSelected = sel == idx;
    final isWrongEntry = s.isGameOver && val != 0 && val != s.solution[idx];
    final showSolutionCell =
        s.isGameOver && s.showSolutionInReview && (val == 0 || isWrongEntry);
    final displayVal = showSolutionCell ? s.solution[idx] : val;
    final isError = s.errorCells.contains(idx) || isWrongEntry;
    final box = (row ~/ 3) * 3 + (col ~/ 3);
    final isRelated =
        sel != null && (row == selRow || col == selCol || box == selBox);
    final isSameDigit = highlightDigit != null && displayVal == highlightDigit;

    Color bg = p.surface;
    if (isWrongEntry) {
      bg = p.danger.withValues(alpha: 0.16);
    } else if (showSolutionCell) {
      bg = p.success.withValues(alpha: 0.14);
    } else if (isSelected) {
      bg = p.accent.withValues(alpha: 0.38);
    } else if (isSameDigit) {
      bg = p.accent.withValues(alpha: 0.22);
    } else if (isRelated) {
      bg = p.surfaceElevated;
    }

    final rightThick = (col + 1) % 3 == 0 && col != 8;
    final bottomThick = (row + 1) % 3 == 0 && row != 8;
    final digitFontSize = (cellSize * 0.62).clamp(16.0, 40.0);
    final noteFontSize = (cellSize * 0.26).clamp(8.5, 16.0);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _controller.selectCell(idx);
          _focusNode.requestFocus();
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              right: col == 8
                  ? BorderSide.none
                  : BorderSide(
                      color: rightThick
                          ? p.accent.withValues(alpha: 0.55)
                          : p.border,
                      width: rightThick ? 2 : 0.6,
                    ),
              bottom: row == 8
                  ? BorderSide.none
                  : BorderSide(
                      color: bottomThick
                          ? p.accent.withValues(alpha: 0.55)
                          : p.border,
                      width: bottomThick ? 2 : 0.6,
                    ),
            ),
          ),
          child: showSolutionCell && isWrongEntry
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$displayVal',
                          style: ZetzyThemes.monoStyle(
                            fontSize: digitFontSize,
                            fontWeight: FontWeight.w700,
                            color: p.success,
                          ).copyWith(height: 1.0),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      top: 1,
                      child: Text(
                        '$val',
                        style: ZetzyThemes.monoStyle(
                          fontSize: (cellSize * 0.26).clamp(8.0, 13.0),
                          fontWeight: FontWeight.w700,
                          color: p.danger,
                        ).copyWith(
                          height: 1.0,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                )
              : displayVal != 0
              ? Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$displayVal',
                      style: ZetzyThemes.monoStyle(
                        fontSize: digitFontSize,
                        fontWeight: isGiven ? FontWeight.w700 : FontWeight.w600,
                        color: showSolutionCell
                            ? p.success
                            : isError
                            ? p.danger
                            : (isGiven ? p.textPrimary : p.accent),
                      ).copyWith(height: 1.0),
                    ),
                  ),
                )
              : _buildNotesGrid(
                  s.notes[idx],
                  p,
                  fontSize: noteFontSize,
                  highlightDigit: highlightDigit,
                ),
        ),
      ),
    );
  }

  Widget _buildNotesGrid(
    Set<int> cellNotes,
    ZetzyPalette p, {
    required double fontSize,
    required int? highlightDigit,
  }) {
    if (cellNotes.isEmpty) return const SizedBox.expand();
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var r = 0; r < 3; r++)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < 3; c++)
                      Expanded(
                        child: Builder(
                          builder: (_) {
                            final noteDigit = r * 3 + c + 1;
                            final hasNote = cellNotes.contains(noteDigit);
                            final isHighlighted =
                                hasNote && highlightDigit == noteDigit;
                            return Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  hasNote ? '$noteDigit' : '',
                                  style: ZetzyThemes.monoStyle(
                                    fontSize: fontSize,
                                    fontWeight: isHighlighted
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isHighlighted
                                        ? p.accent
                                        : p.textSecondary,
                                  ).copyWith(height: 1.0),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewBar(
    SudokuGameState s,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) {
    final summary = _finishedSummary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (s.isWon ? p.success : p.danger).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!s.isWon) ...[
            Row(
              children: [
                Icon(Icons.visibility_outlined, size: 17, color: p.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.sudokuMistakeReviewHint,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: s.showSolutionInReview
                    ? p.accent.withValues(alpha: 0.14)
                    : p.surfaceElevated,
                foregroundColor:
                    s.showSolutionInReview ? p.accent : p.textPrimary,
                side: BorderSide(
                  color: s.showSolutionInReview ? p.accent : p.border,
                ),
              ),
              onPressed: _controller.toggleReviewSolution,
              icon: Icon(
                s.showSolutionInReview
                    ? Icons.visibility_off_outlined
                    : Icons.auto_fix_high_outlined,
                size: 18,
              ),
              label: Text(
                s.showSolutionInReview
                    ? l10n.sudokuHideSolution
                    : l10n.sudokuShowSolution,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              if (summary != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showResultDialog(summary),
                    icon: const Icon(Icons.assessment_outlined, size: 18),
                    label: Text(l10n.viewResult),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: _startNewGame,
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: Text(l10n.playAgain),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionToolbar(
    SudokuGameState s,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _ActionIcon(
              icon: Icons.undo_rounded,
              label: s.isPractice ? l10n.practiceUndo : l10n.sudokuUndoNotes,
              enabled: s.isPractice ? s.canUndoPractice : s.canUndoNote,
              onTap: s.isPractice
                  ? _controller.undoPractice
                  : _controller.undoNotes,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _ActionIcon(
              icon: Icons.backspace_outlined,
              label: l10n.sudokuErase,
              onTap: _controller.eraseSelected,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _ActionIcon(
              icon: Icons.edit_note_rounded,
              label: l10n.sudokuNotes,
              active: s.notesMode,
              onTap: _controller.toggleNotesMode,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _ActionIcon(
              icon: Icons.lightbulb_outline_rounded,
              label: '${l10n.sudokuHint} (${s.hintsLeft})',
              enabled: s.hintsLeft > 0,
              onTap: _controller.useHint,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDigitPad(
    SudokuGameState s,
    ZetzyPalette p, {
    required double keyHeight,
  }) {
    final activeHighlight = s.highlightedDigit;
    return Row(
      children: [
        for (var d = 1; d <= 9; d++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: _DigitKey(
                digit: d,
                height: keyHeight,
                isHighlighted: activeHighlight == d,
                isLocked: s.lockedDigit == d,
                isCompleted: s.countDigit(d) >= 9,
                palette: p,
                onTap: () {
                  _controller.onDigitTap(d);
                  _focusNode.requestFocus();
                },
                onLongPress: () {
                  _controller.toggleDigitLock(d);
                  _focusNode.requestFocus();
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = !enabled
        ? p.textSecondary.withValues(alpha: 0.4)
        : (active ? p.accent : p.textPrimary);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: active ? p.accent.withValues(alpha: 0.16) : p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? p.accent : p.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey({
    required this.digit,
    required this.height,
    required this.isHighlighted,
    required this.isLocked,
    required this.isCompleted,
    required this.palette,
    required this.onTap,
    required this.onLongPress,
  });

  final int digit;
  final double height;
  final bool isHighlighted;
  final bool isLocked;
  final bool isCompleted;
  final ZetzyPalette palette;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final digitFontSize = (height * 0.46).clamp(24.0, 32.0);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: isCompleted && !isHighlighted ? 0.42 : 1.0,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: isHighlighted
                ? palette.accent.withValues(alpha: isLocked ? 0.26 : 0.18)
                : palette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlighted ? palette.accent : palette.border,
              width: isLocked ? 2.0 : (isHighlighted ? 1.5 : 1.0),
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$digit',
                    style: ZetzyThemes.monoStyle(
                      fontSize: digitFontSize,
                      fontWeight: isHighlighted
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isHighlighted
                          ? palette.accent
                          : palette.textPrimary,
                    ).copyWith(height: 1.0),
                  ),
                ),
              ),
              if (isLocked)
                Positioned(
                  top: 4,
                  right: 5,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: palette.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
