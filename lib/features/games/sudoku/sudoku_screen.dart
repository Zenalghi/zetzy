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

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await showGameResultDialog(
      context: context,
      gameType: GameType.sudoku,
      difficulty: finalState.difficulty,
      isWon: finalState.isWon,
      durationMs: finalState.elapsedMs,
      score: score,
      isNewRecord: isNewRecord,
      isPractice: finalState.isPractice,
      extraMetrics: [
        (label: l10n.mistakesLabel, value: '${finalState.mistakes}'),
      ],
      onPlayAgain: () => _controller.startNew(
        difficulty: finalState.difficulty,
        isPractice: finalState.isPractice,
      ),
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
                                    _buildActionToolbar(s, p, l10n),
                                    const SizedBox(height: 16),
                                    _buildDigitPad(s, p),
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
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Column(
                            children: [
                              _buildStatusRow(s, p, l10n),
                              const SizedBox(height: 8),
                              Expanded(child: Center(child: _buildGrid(s, p))),
                              const SizedBox(height: 8),
                              _buildActionToolbar(s, p, l10n),
                              const SizedBox(height: 8),
                              _buildDigitPad(s, p),
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
      constraints: const BoxConstraints(maxWidth: 520, maxHeight: 520),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.accent.withValues(alpha: 0.6), width: 2),
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
        ),
      ),
    );
  }

  Widget _buildCell({
    required SudokuGameState s,
    required ZetzyPalette p,
    required int row,
    required int col,
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
    final isError = s.errorCells.contains(idx);
    final box = (row ~/ 3) * 3 + (col ~/ 3);
    final isRelated = row == selRow || col == selCol || box == selBox;
    final isSameDigit = highlightDigit != null && val == highlightDigit;

    Color bg = p.surface;
    if (isSelected) {
      bg = p.accent.withValues(alpha: 0.30);
    } else if (isSameDigit) {
      bg = p.accentSecondary.withValues(alpha: 0.24);
    } else if (isRelated) {
      bg = p.surfaceElevated;
    }

    final rightThick = (col + 1) % 3 == 0 && col != 8;
    final bottomThick = (row + 1) % 3 == 0 && row != 8;

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
                          ? p.accent.withValues(alpha: 0.5)
                          : p.border,
                      width: rightThick ? 2 : 0.6,
                    ),
              bottom: row == 8
                  ? BorderSide.none
                  : BorderSide(
                      color: bottomThick
                          ? p.accent.withValues(alpha: 0.5)
                          : p.border,
                      width: bottomThick ? 2 : 0.6,
                    ),
            ),
          ),
          child: val != 0
              ? Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$val',
                      style: ZetzyThemes.monoStyle(
                        fontSize: 22,
                        fontWeight: isGiven ? FontWeight.w800 : FontWeight.w600,
                        color: isError
                            ? p.danger
                            : (isGiven ? p.textPrimary : p.accent),
                      ),
                    ),
                  ),
                )
              : _buildNotesGrid(s.notes[idx], p),
        ),
      ),
    );
  }

  Widget _buildNotesGrid(Set<int> cellNotes, ZetzyPalette p) {
    if (cellNotes.isEmpty) return const SizedBox.expand();
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(2),
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
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              cellNotes.contains(r * 3 + c + 1)
                                  ? '${r * 3 + c + 1}'
                                  : '',
                              style: ZetzyThemes.monoStyle(
                                fontSize: 9,
                                color: p.textSecondary,
                              ),
                            ),
                          ),
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
              label: l10n.sudokuUndoNotes,
              enabled: s.canUndoNote,
              onTap: _controller.undoNotes,
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

  Widget _buildDigitPad(SudokuGameState s, ZetzyPalette p) {
    return Row(
      children: [
        for (var d = 1; d <= 9; d++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _DigitKey(
                digit: d,
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? p.accent.withValues(alpha: 0.16) : p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? p.accent : p.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(fontSize: 10, color: color),
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
    required this.isLocked,
    required this.isCompleted,
    required this.palette,
    required this.onTap,
    required this.onLongPress,
  });

  final int digit;
  final bool isLocked;
  final bool isCompleted;
  final ZetzyPalette palette;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isCompleted && !isLocked ? 0.32 : 1.0,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isLocked
                ? palette.accent.withValues(alpha: 0.22)
                : palette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLocked ? palette.accent : palette.border,
              width: isLocked ? 1.8 : 1,
            ),
          ),
          child: Center(
            child: Text(
              '$digit',
              style: ZetzyThemes.monoStyle(
                fontSize: 20,
                color: isLocked ? palette.accent : palette.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
