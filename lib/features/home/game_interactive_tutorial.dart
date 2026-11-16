import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

/// Full-screen, hands-on tutorial that mirrors each game's in-game layout.
///
/// Every step starts PAUSED with a coach explanation. After the player taps
/// "Got it", the exact button/tile they must press blinks, and the step only
/// advances when that blinking target is pressed (e.g. Sudoku: tap the cell,
/// then press digit 5 on the number pad).
class GameInteractiveTutorialScreen extends ConsumerWidget {
  const GameInteractiveTutorialScreen({
    super.key,
    required this.game,
    required this.onStartRealGame,
  });

  final GameType game;
  final VoidCallback onStartRealGame;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return switch (game) {
      GameType.sudoku => _SudokuTutorial(onStartRealGame: onStartRealGame),
      GameType.minesweeper => _MinesweeperTutorial(
        onStartRealGame: onStartRealGame,
      ),
      GameType.chess => _ChessTutorial(
        onStartRealGame: onStartRealGame,
        pieceSet: settings.chessPieceSet,
      ),
      GameType.snake => _SnakeTutorial(
        onStartRealGame: onStartRealGame,
        controlMode: settings.snakeControlMode,
      ),
    };
  }
}

// ── Shared Tutorial Engine ───────────────────────────────────────────────────

class _TutorialAction {
  const _TutorialAction({
    required this.target,
    required this.prompt,
    this.apply,
  });

  /// Id of the widget that must be pressed (it blinks while active).
  final String target;
  final String prompt;
  final FutureOr<void> Function()? apply;
}

class _TutorialStep {
  const _TutorialStep({
    required this.title,
    required this.explanation,
    required this.actions,
    this.onEnter,
  });

  final String title;
  final String explanation;
  final List<_TutorialAction> actions;

  /// Prepares the board (position, emphasis) when the step becomes active.
  final VoidCallback? onEnter;
}

abstract class _TutorialWidget extends StatefulWidget {
  const _TutorialWidget({required this.onStartRealGame});
  final VoidCallback onStartRealGame;
}

abstract class _TutorialBaseState<W extends _TutorialWidget> extends State<W> {
  int _stepIndex = 0;
  int _actionIndex = 0;
  bool _paused = true;
  bool _busy = false;
  bool _completed = false;
  bool _entered = false;
  String? _wrongHint;
  late List<_TutorialStep> _steps;

  String gameName(AppLocalizations l10n);
  List<_TutorialStep> createSteps(AppLocalizations l10n);
  Widget buildBoard(ZetzyPalette p, AppLocalizations l10n);
  Widget buildControls(ZetzyPalette p, AppLocalizations l10n);
  String? wrongHintFor(String id, AppLocalizations l10n) => null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    _steps = createSteps(l10n);
    if (!_entered) {
      _entered = true;
      _steps.first.onEnter?.call();
    }
  }

  _TutorialAction get _currentAction =>
      _steps[_stepIndex].actions[_actionIndex];

  /// The id that is currently blinking, or null while paused/animating.
  String? get blinkTarget =>
      (_paused || _busy || _completed) ? null : _currentAction.target;

  /// Wraps an interactive element so it blinks when it is the active target.
  Widget tappable(
    String id,
    Widget child, {
    double radius = 12,
  }) {
    final active = blinkTarget == id;
    return _Blink(
      key: ValueKey(active ? 'tutorial_blink_target' : 'tut_$id'),
      active: active,
      radius: radius,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => handleTap(id),
        child: child,
      ),
    );
  }

  Future<void> handleTap(String id) async {
    if (_busy || _completed) return;
    final l10n = AppLocalizations.of(context)!;
    if (_paused) {
      setState(() => _wrongHint = l10n.tutorialReadTipFirst);
      return;
    }
    if (id != _currentAction.target) {
      setState(
        () => _wrongHint =
            wrongHintFor(id, l10n) ?? l10n.tutorialTapBlinking,
      );
      return;
    }

    setState(() {
      _wrongHint = null;
      _busy = true;
    });
    final result = _currentAction.apply?.call();
    if (result is Future) await result;
    if (!mounted) return;

    setState(() {
      _busy = false;
      final step = _steps[_stepIndex];
      if (_actionIndex < step.actions.length - 1) {
        _actionIndex++;
      } else if (_stepIndex < _steps.length - 1) {
        _stepIndex++;
        _actionIndex = 0;
        _paused = true;
        _steps[_stepIndex].onEnter?.call();
      } else {
        _completed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.tutorialExitTooltip,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.tutorialAppBarTitle(gameName(l10n))),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                '${math.min(_stepIndex + 1, _steps.length)} / ${_steps.length}',
                style: ZetzyThemes.monoStyle(fontSize: 13, color: p.accent),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      value:
                          (_stepIndex + (_completed ? 1 : 0)) / _steps.length,
                      backgroundColor: p.surfaceElevated,
                      color: p.accent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _completed
                      ? _buildCompletionCard(p, l10n)
                      : _buildCoachCard(p, l10n),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: buildBoard(p, l10n)),
                            const SizedBox(height: 10),
                            buildControls(p, l10n),
                          ],
                        ),
                        if (_paused && !_completed)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => handleTap('__paused__'),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.38),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.pause_circle_filled_rounded,
                                    size: 56,
                                    color: Colors.white.withValues(alpha: 0.85),
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
          ),
        ),
      ),
    );
  }

  Widget _buildCoachCard(ZetzyPalette p, AppLocalizations l10n) {
    final step = _steps[_stepIndex];
    final badgeColor = _paused ? p.warning : p.accent;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: badgeColor, width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _paused
                      ? l10n.tutorialPausedBadge
                      : l10n.tutorialTryItBadge,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
              const Spacer(),
              if (!_paused && step.actions.length > 1)
                Text(
                  l10n.tutorialActionProgress(
                    _actionIndex + 1,
                    step.actions.length,
                  ),
                  style: TextStyle(fontSize: 11, color: p.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            step.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            _paused ? step.explanation : _currentAction.prompt,
            style: const TextStyle(fontSize: 12.5, height: 1.4),
          ),
          if (_wrongHint != null) ...[
            const SizedBox(height: 6),
            Text(
              _wrongHint!,
              style: TextStyle(fontSize: 12, color: p.warning),
            ),
          ],
          if (_paused) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('tutorial_resume_action_btn'),
                onPressed: () => setState(() {
                  _paused = false;
                  _wrongHint = null;
                }),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(l10n.tutorialGotItBtn),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletionCard(ZetzyPalette p, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.accent, width: 1.3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded, size: 40, color: p.accent),
          const SizedBox(height: 4),
          Text(
            l10n.tutorialCompleteTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.tutorialCompleteBody(gameName(l10n)),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: p.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const ValueKey('tutorial_finish_close_btn'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.tutorialDoneBtn),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('tutorial_play_real_btn'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onStartRealGame();
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(l10n.tutorialPlayNowBtn),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pulsing accent border + glow used to mark the element the player must press.
class _Blink extends StatefulWidget {
  const _Blink({
    super.key,
    required this.active,
    required this.child,
    this.radius = 12,
  });

  final bool active;
  final Widget child;
  final double radius;

  @override
  State<_Blink> createState() => _BlinkState();
}

class _BlinkState extends State<_Blink> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _Blink oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.active && _ctrl.isAnimating) {
      _ctrl
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    final accent = context.palette.accent;
    final radius = BorderRadius.circular(widget.radius);
    return AnimatedBuilder(
      animation: _ctrl,
      child: widget.child,
      builder: (context, child) {
        final v = Curves.easeInOut.transform(_ctrl.value);
        return Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.55 * v),
                blurRadius: 14 * v,
                spreadRadius: 1.5 * v,
              ),
            ],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            color: accent.withValues(alpha: 0.08 + 0.22 * v),
            border: Border.all(
              color: accent.withValues(alpha: 0.4 + 0.6 * v),
              width: 2.5,
            ),
          ),
          child: child,
        );
      },
    );
  }
}

Widget _hudChip(ZetzyPalette p, IconData icon, String text, {Color? color}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? p.accent),
          const SizedBox(width: 5),
          Text(
            text,
            style: ZetzyThemes.monoStyle(fontSize: 12, color: p.textPrimary),
          ),
        ],
      ),
    );

// ── Sudoku: select cell → press digit on the number pad ─────────────────────

class _SudokuTutorial extends _TutorialWidget {
  const _SudokuTutorial({required super.onStartRealGame});

  @override
  State<_SudokuTutorial> createState() => _SudokuTutorialState();
}

class _SudokuTutorialState extends _TutorialBaseState<_SudokuTutorial> {
  static const List<int> _solution = [
    5, 3, 4, 6, 7, 8, 9, 1, 2, //
    6, 7, 2, 1, 9, 5, 3, 4, 8, //
    1, 9, 8, 3, 4, 2, 5, 6, 7, //
    8, 5, 9, 7, 6, 1, 4, 2, 3, //
    4, 2, 6, 8, 5, 3, 7, 9, 1, //
    7, 1, 3, 9, 2, 4, 8, 5, 6, //
    9, 6, 1, 5, 3, 7, 2, 8, 4, //
    2, 8, 7, 4, 1, 9, 6, 3, 5, //
    3, 4, 5, 2, 8, 6, 1, 7, 9, //
  ];
  static const int _centerIdx = 40;
  static const int _rowCellA = 1;
  static const int _rowCellB = 2;
  static const int _clueIdx = 73;

  late final List<int> _values = [
    for (var i = 0; i < 81; i++)
      (i == _centerIdx || i == _rowCellA || i == _rowCellB) ? 0 : _solution[i],
  ];
  final Set<int> _filled = {};
  final Map<int, Set<int>> _notes = {};
  Set<int> _emphasis = {};
  int? _clue;
  int? _selected;
  bool _notesMode = false;

  @override
  String gameName(AppLocalizations l10n) => l10n.gameSudoku;

  void _fill(int idx, int digit) {
    _values[idx] = digit;
    _filled.add(idx);
    _notes.remove(idx);
  }

  @override
  List<_TutorialStep> createSteps(AppLocalizations l10n) => [
    _TutorialStep(
      title: l10n.tutSudokuS1Title,
      explanation: l10n.tutSudokuS1Exp,
      onEnter: () {
        _emphasis = {
          for (var r = 3; r < 6; r++)
            for (var c = 3; c < 6; c++) r * 9 + c,
        };
      },
      actions: [
        _TutorialAction(
          target: 'cell_$_centerIdx',
          prompt: l10n.tutSudokuS1A1,
          apply: () => _selected = _centerIdx,
        ),
        _TutorialAction(
          target: 'digit_5',
          prompt: l10n.tutSudokuS1A2,
          apply: () => _fill(_centerIdx, 5),
        ),
      ],
    ),
    _TutorialStep(
      title: l10n.tutSudokuS2Title,
      explanation: l10n.tutSudokuS2Exp,
      onEnter: () {
        _selected = null;
        _emphasis = {for (var c = 0; c < 9; c++) c};
      },
      actions: [
        _TutorialAction(
          target: 'act_notes',
          prompt: l10n.tutSudokuS2A1,
          apply: () => _notesMode = true,
        ),
        _TutorialAction(
          target: 'cell_$_rowCellA',
          prompt: l10n.tutSudokuS2A2,
          apply: () => _selected = _rowCellA,
        ),
        _TutorialAction(
          target: 'digit_3',
          prompt: l10n.tutSudokuS2A3,
          apply: () => (_notes[_rowCellA] ??= {}).add(3),
        ),
        _TutorialAction(
          target: 'digit_4',
          prompt: l10n.tutSudokuS2A4,
          apply: () => (_notes[_rowCellA] ??= {}).add(4),
        ),
      ],
    ),
    _TutorialStep(
      title: l10n.tutSudokuS3Title,
      explanation: l10n.tutSudokuS3Exp,
      onEnter: () {
        _selected = null;
        _emphasis = {for (var r = 0; r < 9; r++) r * 9 + _rowCellA};
        _clue = _clueIdx;
      },
      actions: [
        _TutorialAction(
          target: 'act_notes',
          prompt: l10n.tutSudokuS3A1,
          apply: () => _notesMode = false,
        ),
        _TutorialAction(
          target: 'cell_$_rowCellA',
          prompt: l10n.tutSudokuS3A2,
          apply: () => _selected = _rowCellA,
        ),
        _TutorialAction(
          target: 'digit_3',
          prompt: l10n.tutSudokuS3A3,
          apply: () => _fill(_rowCellA, 3),
        ),
        _TutorialAction(
          target: 'cell_$_rowCellB',
          prompt: l10n.tutSudokuS3A4,
          apply: () {
            _selected = _rowCellB;
            _emphasis = {for (var c = 0; c < 9; c++) c};
            _clue = null;
          },
        ),
        _TutorialAction(
          target: 'digit_4',
          prompt: l10n.tutSudokuS3A5,
          apply: () {
            _fill(_rowCellB, 4);
            _selected = null;
            _emphasis = {};
          },
        ),
      ],
    ),
  ];

  @override
  String? wrongHintFor(String id, AppLocalizations l10n) {
    if (id.startsWith('digit_') && _currentAction.target.startsWith('cell_')) {
      return l10n.tutSudokuWrongCellFirst;
    }
    if (id.startsWith('cell_') && _currentAction.target.startsWith('digit_')) {
      return l10n.tutSudokuWrongPressDigit;
    }
    return null;
  }

  @override
  Widget buildBoard(ZetzyPalette p, AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 18,
                  color: p.danger,
                ),
              ),
            const Spacer(),
            _hudChip(p, Icons.school_rounded, l10n.tutorialHudLabel),
            const SizedBox(width: 6),
            _hudChip(p, Icons.timer_outlined, '00:00'),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final size = (c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight)
                  .clamp(120.0, 460.0);
              return Center(child: _buildGrid(p, size));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(ZetzyPalette p, double size) {
    final cell = (size - 4) / 9;
    final selectedDigit = _selected != null ? _values[_selected!] : 0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.textSecondary, width: 2),
      ),
      child: Column(
        children: [
          for (var r = 0; r < 9; r++)
            Row(
              children: [
                for (var c = 0; c < 9; c++)
                  _buildCell(p, r * 9 + c, r, c, cell, selectedDigit),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCell(
    ZetzyPalette p,
    int idx,
    int r,
    int c,
    double size,
    int selectedDigit,
  ) {
    final value = _values[idx];
    final isSelected = _selected == idx;
    final isClue = _clue == idx;
    final sameDigit = selectedDigit > 0 && value == selectedDigit;
    final bg = isSelected
        ? p.accent.withValues(alpha: 0.34)
        : isClue
        ? p.warning.withValues(alpha: 0.38)
        : sameDigit
        ? p.accent.withValues(alpha: 0.2)
        : _emphasis.contains(idx)
        ? p.accent.withValues(alpha: 0.12)
        : Colors.transparent;

    Widget content;
    if (value > 0) {
      content = Text(
        '$value',
        style: ZetzyThemes.monoStyle(
          fontSize: size * 0.52,
          color: _filled.contains(idx) ? p.accent : p.textPrimary,
        ),
      );
    } else if (_notes[idx]?.isNotEmpty ?? false) {
      final notes = _notes[idx]!;
      content = GridView.count(
        crossAxisCount: 3,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var d = 1; d <= 9; d++)
            Center(
              child: Text(
                notes.contains(d) ? '$d' : '',
                style: TextStyle(
                  fontSize: size * 0.24,
                  height: 1,
                  color: p.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      );
    } else {
      content = const SizedBox.shrink();
    }

    return tappable(
      'cell_$idx',
      Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            right: c < 8
                ? BorderSide(
                    color: c % 3 == 2 ? p.textSecondary : p.border,
                    width: c % 3 == 2 ? 1.6 : 0.5,
                  )
                : BorderSide.none,
            bottom: r < 8
                ? BorderSide(
                    color: r % 3 == 2 ? p.textSecondary : p.border,
                    width: r % 3 == 2 ? 1.6 : 0.5,
                  )
                : BorderSide.none,
          ),
        ),
        child: content,
      ),
      radius: 2,
    );
  }

  @override
  Widget buildControls(ZetzyPalette p, AppLocalizations l10n) {
    Widget action(String id, IconData icon, String label, {bool on = false}) {
      final color = on ? p.accent : p.textPrimary;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: tappable(
            id,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: on ? p.accent.withValues(alpha: 0.16) : p.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: on ? p.accent : p.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 21, color: color),
                  const SizedBox(height: 2),
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
            radius: 14,
          ),
        ),
      );
    }

    final keyHeight = (MediaQuery.sizeOf(context).height * 0.088)
        .clamp(56.0, 68.0);
    final digitFontSize = (keyHeight * 0.46).clamp(24.0, 32.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            action('act_undo', Icons.undo_rounded, l10n.sudokuUndoNotes),
            action('act_erase', Icons.backspace_outlined, l10n.sudokuErase),
            action(
              'act_notes',
              Icons.edit_note_rounded,
              l10n.sudokuNotes,
              on: _notesMode,
            ),
            action(
              'act_hint',
              Icons.lightbulb_outline_rounded,
              '${l10n.sudokuHint} (3)',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var d = 1; d <= 9; d++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: tappable(
                    'digit_$d',
                    Container(
                      height: keyHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.border),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$d',
                          style: ZetzyThemes.monoStyle(
                            fontSize: digitFontSize,
                            fontWeight: FontWeight.w600,
                            color: p.textPrimary,
                          ).copyWith(height: 1.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Minesweeper: Dig / Flag / ? tools + real tile styling ───────────────────

class _MinesweeperTutorial extends _TutorialWidget {
  const _MinesweeperTutorial({required super.onStartRealGame});

  @override
  State<_MinesweeperTutorial> createState() => _MinesweeperTutorialState();
}

class _MinesweeperTutorialState
    extends _TutorialBaseState<_MinesweeperTutorial> {
  static const int _n = 5;
  static const Set<int> _mines = {1, 5}; // (0,1) and (1,0)

  final Set<int> _revealed = {};
  final Map<int, String> _marks = {};
  Set<int> _emphasis = {};
  String _tool = 'dig';

  @override
  String gameName(AppLocalizations l10n) => l10n.gameMinesweeper;

  int _adjacent(int idx) {
    final r = idx ~/ _n, c = idx % _n;
    var count = 0;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final rr = r + dr, cc = c + dc;
        if (rr < 0 || cc < 0 || rr >= _n || cc >= _n) continue;
        if (_mines.contains(rr * _n + cc)) count++;
      }
    }
    return count;
  }

  @override
  List<_TutorialStep> createSteps(AppLocalizations l10n) => [
    _TutorialStep(
      title: l10n.tutMineS1Title,
      explanation: l10n.tutMineS1Exp,
      actions: [
        _TutorialAction(
          target: 'cell_12',
          prompt: l10n.tutMineS1A1,
          apply: () => _revealed.addAll([
            for (var i = 0; i < _n * _n; i++)
              if (i != 0 && !_mines.contains(i)) i,
          ]),
        ),
      ],
    ),
    _TutorialStep(
      title: l10n.tutMineS2Title,
      explanation: l10n.tutMineS2Exp,
      onEnter: () => _emphasis = {2},
      actions: [
        _TutorialAction(
          target: 'tool_flag',
          prompt: l10n.tutMineS2A1,
          apply: () => _tool = 'flag',
        ),
        _TutorialAction(
          target: 'cell_1',
          prompt: l10n.tutMineS2A2,
          apply: () => _marks[1] = 'flag',
        ),
      ],
    ),
    _TutorialStep(
      title: l10n.tutMineS3Title,
      explanation: l10n.tutMineS3Exp,
      onEnter: () => _emphasis = {6},
      actions: [
        _TutorialAction(
          target: 'tool_question',
          prompt: l10n.tutMineS3A1,
          apply: () => _tool = 'question',
        ),
        _TutorialAction(
          target: 'cell_0',
          prompt: l10n.tutMineS3A2,
          apply: () => _marks[0] = 'question',
        ),
      ],
    ),
    _TutorialStep(
      title: l10n.tutMineS4Title,
      explanation: l10n.tutMineS4Exp,
      onEnter: () => _emphasis = {10},
      actions: [
        _TutorialAction(
          target: 'tool_flag',
          prompt: l10n.tutMineS4A1,
          apply: () => _tool = 'flag',
        ),
        _TutorialAction(
          target: 'cell_5',
          prompt: l10n.tutMineS4A2,
          apply: () => _marks[5] = 'flag',
        ),
      ],
    ),
    _TutorialStep(
      title: l10n.tutMineS5Title,
      explanation: l10n.tutMineS5Exp,
      onEnter: () => _emphasis = {6},
      actions: [
        _TutorialAction(
          target: 'tool_dig',
          prompt: l10n.tutMineS5A1,
          apply: () => _tool = 'dig',
        ),
        _TutorialAction(
          target: 'cell_0',
          prompt: l10n.tutMineS5A2,
          apply: () {
            _marks.remove(0);
            _revealed.add(0);
            _emphasis = {};
          },
        ),
      ],
    ),
  ];

  @override
  String? wrongHintFor(String id, AppLocalizations l10n) {
    if (id.startsWith('cell_') && _currentAction.target.startsWith('tool_')) {
      return l10n.tutMineWrongSwitchTool;
    }
    return null;
  }

  Color _numberColor(ZetzyPalette p, int n) => switch (n) {
    1 => const Color(0xFF38BDF8),
    2 => const Color(0xFF4ADE80),
    3 => const Color(0xFFFB7185),
    _ => p.textPrimary,
  };

  @override
  Widget buildBoard(ZetzyPalette p, AppLocalizations l10n) {
    final flags = _marks.values.where((m) => m == 'flag').length;
    return Column(
      children: [
        Row(
          children: [
            _hudChip(p, Icons.brightness_7_rounded, '${_mines.length}'),
            const SizedBox(width: 6),
            _hudChip(p, Icons.flag_rounded, '$flags/${_mines.length}'),
            const Spacer(),
            _hudChip(p, Icons.timer_outlined, '00:00'),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final maxSide =
                  (c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight) - 14;
              final cell = (maxSide / _n).clamp(24.0, 62.0);
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.border, width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var r = 0; r < _n; r++)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var col = 0; col < _n; col++)
                              _buildTile(p, r * _n + col, cell),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTile(ZetzyPalette p, int idx, double size) {
    final revealed = _revealed.contains(idx);
    final mark = _marks[idx];
    final emphasized = _emphasis.contains(idx);
    Widget? content;
    if (revealed) {
      final n = _adjacent(idx);
      if (n > 0) {
        content = Text(
          '$n',
          style: ZetzyThemes.monoStyle(
            fontSize: size * 0.45,
            color: _numberColor(p, n),
          ),
        );
      }
    } else if (mark == 'flag') {
      content = Padding(
        padding: EdgeInsets.all(size * 0.16),
        child: Image.asset(AssetPaths.mineFlag),
      );
    } else if (mark == 'question') {
      content = Padding(
        padding: EdgeInsets.all(size * 0.16),
        child: Image.asset(AssetPaths.mineQuestion),
      );
    }

    return tappable(
      'cell_$idx',
      Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(1),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: revealed ? p.boardDark : p.boardLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: emphasized ? p.warning : p.border.withValues(alpha: 0.6),
            width: emphasized ? 2.2 : 0.8,
          ),
        ),
        child: content,
      ),
      radius: 6,
    );
  }

  @override
  Widget buildControls(ZetzyPalette p, AppLocalizations l10n) {
    Widget tool(String id, String value, Widget icon, String label) {
      final on = _tool == value;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: tappable(
            id,
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: on ? p.accent.withValues(alpha: 0.18) : p.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: on ? p.accent : p.border,
                  width: on ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (on) ...[
                    Icon(Icons.check_rounded, size: 15, color: p.accent),
                    const SizedBox(width: 3),
                  ],
                  icon,
                  const SizedBox(width: 5),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: on ? p.accent : p.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tool(
          'tool_dig',
          'dig',
          Icon(Icons.hardware_rounded, size: 18, color: p.textPrimary),
          l10n.mineModeDig,
        ),
        tool(
          'tool_flag',
          'flag',
          Image.asset(AssetPaths.mineFlag, width: 16, height: 16),
          l10n.mineModeFlag,
        ),
        tool(
          'tool_question',
          'question',
          Image.asset(AssetPaths.mineQuestion, width: 16, height: 16),
          l10n.mineModeQuestion,
        ),
      ],
    );
  }
}

// ── Chess: tap piece → see highlighted legal moves (red = capture) → move ───

class _ChessTutorial extends _TutorialWidget {
  const _ChessTutorial({
    required super.onStartRealGame,
    required this.pieceSet,
  });

  final ChessPieceSet pieceSet;

  @override
  State<_ChessTutorial> createState() => _ChessTutorialState();
}

class _ChessTutorialState extends _TutorialBaseState<_ChessTutorial> {
  static const String _files = 'abcdefgh';

  Map<String, String> _pos = {};
  String? _selected;
  List<String> _moves = [];
  List<String> _captures = [];
  List<String> _special = [];
  List<String> _lastMove = [];
  bool _showPromo = false;
  String? _matedKing;

  @override
  String gameName(AppLocalizations l10n) => l10n.gameChess;

  void _select(
    String sq, {
    List<String> moves = const [],
    List<String> captures = const [],
    List<String> special = const [],
  }) {
    _selected = sq;
    _moves = moves;
    _captures = captures;
    _special = special;
  }

  void _clearSelection() {
    _selected = null;
    _moves = [];
    _captures = [];
    _special = [];
  }

  void _move(String from, String to) {
    final piece = _pos.remove(from);
    if (piece != null) _pos[to] = piece;
    _lastMove = [from, to];
    _clearSelection();
  }

  @override
  List<_TutorialStep> createSteps(AppLocalizations l10n) => [
    _TutorialStep(
      title: l10n.tutChessS1Title,
      explanation: l10n.tutChessS1Exp,
      onEnter: () {
        _pos = {
          'e1': 'wK',
          'h2': 'wP',
          'g2': 'wP',
          'd4': 'wN',
          'e8': 'bK',
          'f5': 'bQ',
          'a7': 'bP',
          'b7': 'bP',
        };
        _lastMove = [];
        _clearSelection();
      },
      actions: [
        _TutorialAction(
          target: 'sq_d4',
          prompt: l10n.tutChessS1A1,
          apply: () => _select(
            'd4',
            moves: ['b3', 'b5', 'c2', 'c6', 'e2', 'e6', 'f3'],
            captures: ['f5'],
          ),
        ),
        _TutorialAction(
          target: 'sq_f5',
          prompt: l10n.tutChessS1A2,
          apply: () => _move('d4', 'f5'),
        ),
      ],
    ),
    _TutorialStep(
      title: l10n.tutChessS2Title,
      explanation: l10n.tutChessS2Exp,
      onEnter: () {
        _pos = {
          'e1': 'wK',
          'h1': 'wR',
          'f2': 'wP',
          'g2': 'wP',
          'h2': 'wP',
          'e8': 'bK',
          'd7': 'bP',
          'e7': 'bP',
        };
        _lastMove = [];
        _clearSelection();
      },
      actions: [
        _TutorialAction(
          target: 'sq_e1',
          prompt: l10n.tutChessS2A1,
          apply: () => _select(
            'e1',
            moves: ['d1', 'd2', 'e2', 'f1'],
            special: ['g1'],
          ),
        ),
        _TutorialAction(
          target: 'sq_g1',
          prompt: l10n.tutChessS2A2,
          apply: () {
            _move('e1', 'g1');
            final rook = _pos.remove('h1');
            if (rook != null) _pos['f1'] = rook;
          },
        ),
      ],
    ),
    _TutorialStep(
      title: l10n.tutChessS3Title,
      explanation: l10n.tutChessS3Exp,
      onEnter: () {
        _pos = {
          'e1': 'wK',
          'e5': 'wP',
          'a2': 'wP',
          'e8': 'bK',
          'd5': 'bP',
          'h7': 'bP',
        };
        _lastMove = ['d7', 'd5'];
        _clearSelection();
      },
      actions: [
        _TutorialAction(
          target: 'sq_e5',
          prompt: l10n.tutChessS3A1,
          apply: () => _select('e5', moves: ['e6'], captures: ['d6']),
        ),
        _TutorialAction(
          target: 'sq_d6',
          prompt: l10n.tutChessS3A2,
          apply: () {
            _move('e5', 'd6');
            _pos.remove('d5');
          },
        ),
      ],
    ),
    _TutorialStep(
      title: l10n.tutChessS4Title,
      explanation: l10n.tutChessS4Exp,
      onEnter: () {
        _pos = {
          'g1': 'wK',
          'a7': 'wP',
          'h8': 'bK',
          'g7': 'bP',
          'h7': 'bP',
        };
        _lastMove = [];
        _clearSelection();
      },
      actions: [
        _TutorialAction(
          target: 'sq_a7',
          prompt: l10n.tutChessS4A1,
          apply: () => _select('a7', moves: ['a8']),
        ),
        _TutorialAction(
          target: 'sq_a8',
          prompt: l10n.tutChessS4A2,
          apply: () {
            _move('a7', 'a8');
            _showPromo = true;
          },
        ),
        _TutorialAction(
          target: 'promo_Q',
          prompt: l10n.tutChessS4A3,
          apply: () {
            _pos['a8'] = 'wQ';
            _showPromo = false;
            _matedKing = 'h8';
          },
        ),
      ],
    ),
  ];

  @override
  String? wrongHintFor(String id, AppLocalizations l10n) {
    final sq = id.startsWith('sq_') ? id.substring(3) : null;
    if (sq != null && (_moves.contains(sq) || _special.contains(sq))) {
      return l10n.tutChessWrongOtherLegal;
    }
    if (sq != null &&
        _currentAction.target.startsWith('sq_') &&
        _selected == null) {
      return l10n.tutChessWrongTapPieceFirst;
    }
    return null;
  }

  @override
  Widget buildBoard(ZetzyPalette p, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, c) {
        final maxInner =
            ((c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight) - 4)
                .clamp(152.0, 456.0);
        final sq = (maxInner / 8).floorToDouble();
        final boardSide = sq * 8;
        return Center(
          child: Container(
            width: boardSide + 4,
            height: boardSide + 4,
            decoration: BoxDecoration(
              border: Border.all(color: p.border, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                for (var rank = 8; rank >= 1; rank--)
                  Row(
                    children: [
                      for (var f = 0; f < 8; f++)
                        _buildSquare(p, '${_files[f]}$rank', f, rank, sq),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSquare(
    ZetzyPalette p,
    String name,
    int file,
    int rank,
    double size,
  ) {
    final isDark = (file + rank - 1).isEven;
    var bg = isDark ? p.boardDark : p.boardLight;
    if (_lastMove.contains(name)) {
      bg = Color.alphaBlend(p.warning.withValues(alpha: 0.38), bg);
    }
    if (_selected == name) {
      bg = Color.alphaBlend(p.accent.withValues(alpha: 0.5), bg);
    }
    final isCapture = _captures.contains(name);
    if (isCapture || _matedKing == name) {
      bg = Color.alphaBlend(p.danger.withValues(alpha: 0.5), bg);
    }
    final piece = _pos[name];
    final coordColor = isDark ? p.boardLight : p.boardDark;

    return tappable(
      'sq_$name',
      Container(
        width: size,
        height: size,
        color: bg,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (piece != null)
              Padding(
                padding: EdgeInsets.all(size * 0.08),
                child: SvgPicture.asset(
                  widget.pieceSet.pieceAsset(piece[0], piece[1]),
                ),
              ),
            if (_moves.contains(name))
              Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
              ),
            if (isCapture)
              Container(
                width: size * 0.86,
                height: size * 0.86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: p.danger, width: 3),
                ),
              ),
            if (_special.contains(name))
              Container(
                width: size * 0.7,
                height: size * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.accent.withValues(alpha: 0.3),
                  border: Border.all(color: p.accent, width: 2),
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: size * 0.42,
                  color: p.accent,
                ),
              ),
            if (file == 0)
              Positioned(
                left: 2,
                top: 1,
                child: Text(
                  '$rank',
                  style: TextStyle(fontSize: size * 0.18, color: coordColor),
                ),
              ),
            if (rank == 1)
              Positioned(
                right: 2,
                bottom: 0,
                child: Text(
                  _files[file],
                  style: TextStyle(fontSize: size * 0.18, color: coordColor),
                ),
              ),
          ],
        ),
      ),
      radius: 2,
    );
  }

  @override
  Widget buildControls(ZetzyPalette p, AppLocalizations l10n) {
    if (_showPromo) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.tutChessPromoLabel,
            style: TextStyle(fontSize: 12, color: p.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final code in ['Q', 'R', 'B', 'N'])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: tappable(
                      'promo_$code',
                      Container(
                        height: 58,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: p.border),
                        ),
                        child: SvgPicture.asset(
                          widget.pieceSet.pieceAsset('w', code),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    }

    final status = _matedKing != null
        ? l10n.tutChessCheckmateStatus
        : l10n.tutChessWhiteToMove;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _matedKing != null ? p.accent : p.border,
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            widget.pieceSet.pieceAsset('w', 'K'),
            width: 22,
            height: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _matedKing != null ? p.accent : p.textPrimary,
              ),
            ),
          ),
          Text(
            widget.pieceSet.label,
            style: TextStyle(fontSize: 11, color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Snake: steer with the player's own control mode (Swipe / D-Pad / Split) ─

class _SnakeTutorial extends _TutorialWidget {
  const _SnakeTutorial({
    required super.onStartRealGame,
    required this.controlMode,
  });

  final SnakeControlMode controlMode;

  @override
  State<_SnakeTutorial> createState() => _SnakeTutorialState();
}

class _SnakeTutorialState extends _TutorialBaseState<_SnakeTutorial> {
  static const int _grid = 8;
  static const Duration _stepDelay = Duration(milliseconds: 170);

  List<(int, int)> _body = [(3, 4), (3, 3), (3, 2)];
  String _dir = 'right';
  int _score = 0;
  final Map<(int, int), String> _items = {
    (1, 4): 'apple',
    (1, 7): 'scissors',
    (3, 6): 'poison',
    (2, 5): 'wall',
    (5, 7): 'golden',
  };

  @override
  String gameName(AppLocalizations l10n) => l10n.gameSnake;

  bool get _split => widget.controlMode == SnakeControlMode.splitTap;

  String _controlTarget(String absolute, String relative) =>
      _split ? 'turn_$relative' : 'dir_$absolute';

  String _controlPrompt(
    AppLocalizations l10n,
    String absolute,
    String relative,
  ) => switch (widget.controlMode) {
    SnakeControlMode.dpad => l10n.tutSnakePromptDpad(_dirLabel(l10n, absolute)),
    SnakeControlMode.splitTap =>
      relative == 'left'
          ? l10n.tutSnakePromptSplitLeft
          : l10n.tutSnakePromptSplitRight,
    SnakeControlMode.swipe =>
      l10n.tutSnakePromptSwipe(_dirLabel(l10n, absolute)),
  };

  String _dirLabel(AppLocalizations l10n, String d) => switch (d) {
    'up' => l10n.tutSnakeDirUp,
    'down' => l10n.tutSnakeDirDown,
    'left' => l10n.tutSnakeDirLeft,
    _ => l10n.tutSnakeDirRight,
  };

  Future<void> _moveAlong(List<(int, int)> path, String newDir) async {
    _dir = newDir;
    for (final cell in path) {
      await Future<void>.delayed(_stepDelay);
      if (!mounted) return;
      setState(() {
        _body.insert(0, cell);
        final item = _items.remove(cell);
        switch (item) {
          case 'apple':
            _score += 10;
          case 'golden':
            _score += 30;
          case 'scissors':
            _body.removeLast();
            if (_body.length > 3) _body = _body.sublist(0, 3);
          default:
            _body.removeLast();
        }
      });
    }
  }

  @override
  List<_TutorialStep> createSteps(AppLocalizations l10n) => [
    _TutorialStep(
      title: l10n.tutSnakeS1Title,
      explanation: l10n.tutSnakeS1Exp,
      actions: [
        _TutorialAction(
          target: _controlTarget('up', 'left'),
          prompt: _controlPrompt(l10n, 'up', 'left'),
          apply: () => _moveAlong([(2, 4), (1, 4)], 'up'),
        ),
      ],
    ),
    _TutorialStep(
      title: l10n.tutSnakeS2Title,
      explanation: l10n.tutSnakeS2Exp,
      actions: [
        _TutorialAction(
          target: _controlTarget('right', 'right'),
          prompt: _controlPrompt(l10n, 'right', 'right'),
          apply: () => _moveAlong([(1, 5), (1, 6), (1, 7)], 'right'),
        ),
      ],
    ),
    _TutorialStep(
      title: l10n.tutSnakeS3Title,
      explanation: l10n.tutSnakeS3Exp,
      actions: [
        _TutorialAction(
          target: _controlTarget('down', 'right'),
          prompt: _controlPrompt(l10n, 'down', 'right'),
          apply: () => _moveAlong([(2, 7), (3, 7), (4, 7), (5, 7)], 'down'),
        ),
      ],
    ),
  ];

  @override
  String? wrongHintFor(String id, AppLocalizations l10n) {
    const opposite = {
      'up': 'down',
      'down': 'up',
      'left': 'right',
      'right': 'left',
    };
    if (id == 'dir_${opposite[_dir]}') {
      return l10n.tutSnakeWrongUTurn;
    }
    return null;
  }

  void _onSwipe(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond;
    if (v.distance < 80) return;
    final dir = v.dx.abs() > v.dy.abs()
        ? (v.dx > 0 ? 'right' : 'left')
        : (v.dy > 0 ? 'down' : 'up');
    handleTap('dir_$dir');
  }

  IconData _arrow(String d) => switch (d) {
    'up' => Icons.keyboard_arrow_up_rounded,
    'down' => Icons.keyboard_arrow_down_rounded,
    'left' => Icons.keyboard_arrow_left_rounded,
    _ => Icons.keyboard_arrow_right_rounded,
  };

  @override
  Widget buildBoard(ZetzyPalette p, AppLocalizations l10n) {
    final modeLabel = switch (widget.controlMode) {
      SnakeControlMode.swipe => l10n.settingsSnakeSwipe,
      SnakeControlMode.dpad => l10n.settingsSnakeDpad,
      SnakeControlMode.splitTap => l10n.settingsSnakeSplit,
    };
    final swipeTarget =
        widget.controlMode == SnakeControlMode.swipe &&
            (blinkTarget?.startsWith('dir_') ?? false)
        ? blinkTarget!.substring(4)
        : null;

    return Column(
      children: [
        Row(
          children: [
            _hudChip(p, Icons.star_rounded, '$_score'),
            const SizedBox(width: 6),
            _hudChip(p, Icons.straighten_rounded, '${_body.length}'),
            const Spacer(),
            _hudChip(p, Icons.sports_esports_rounded, modeLabel),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final maxInner =
                  ((c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight) - 4)
                      .clamp(152.0, 436.0);
              final cell = (maxInner / _grid).floorToDouble();
              final innerSide = cell * _grid;
              Widget arena = Container(
                width: innerSide + 4,
                height: innerSide + 4,
                decoration: BoxDecoration(
                  color: p.boardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.border, width: 2),
                ),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        for (var r = 0; r < _grid; r++)
                          Row(
                            children: [
                              for (var col = 0; col < _grid; col++)
                                _buildCell(p, (r, col), cell - 0.5),
                            ],
                          ),
                      ],
                    ),
                    if (swipeTarget != null)
                      Center(
                        child: tappable(
                          'dir_$swipeTarget',
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: p.surface.withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _arrow(swipeTarget),
                              size: 44,
                              color: p.accent,
                            ),
                          ),
                          radius: 32,
                        ),
                      ),
                  ],
                ),
              );
              if (widget.controlMode == SnakeControlMode.swipe) {
                arena = GestureDetector(onPanEnd: _onSwipe, child: arena);
              }
              return Center(child: arena);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCell(ZetzyPalette p, (int, int) pos, double size) {
    final bodyIdx = _body.indexOf(pos);
    final item = _items[pos];
    Widget? content;
    Color? color;
    if (bodyIdx == 0) {
      color = p.snakeHead;
      content = Icon(_arrow(_dir), size: size * 0.7, color: p.boardDark);
    } else if (bodyIdx > 0) {
      color = p.snakeBody;
    } else if (item != null) {
      final asset = switch (item) {
        'apple' => AssetPaths.snakeApple,
        'golden' => AssetPaths.snakeGolden,
        'scissors' => AssetPaths.snakeScissors,
        'poison' => AssetPaths.snakePoison,
        _ => AssetPaths.snakeWall,
      };
      content = Padding(
        padding: EdgeInsets.all(item == 'wall' ? 0 : size * 0.08),
        child: Image.asset(asset),
      );
    }
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(0.25),
      decoration: BoxDecoration(
        color: color ?? p.boardLight.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(bodyIdx >= 0 ? 5 : 2),
      ),
      alignment: Alignment.center,
      child: content,
    );
  }

  @override
  Widget buildControls(ZetzyPalette p, AppLocalizations l10n) {
    switch (widget.controlMode) {
      case SnakeControlMode.dpad:
        Widget btn(String d) => tappable(
          'dir_$d',
          Container(
            width: 58,
            height: 48,
            decoration: BoxDecoration(
              color: p.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border),
            ),
            child: Icon(_arrow(d), color: p.textPrimary),
          ),
          radius: 14,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            btn('up'),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [btn('left'), const SizedBox(width: 52), btn('right')],
            ),
            const SizedBox(height: 4),
            btn('down'),
          ],
        );
      case SnakeControlMode.splitTap:
        Widget half(String side, IconData icon, String label) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: tappable(
              'turn_$side',
              Container(
                height: 64,
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: p.textPrimary),
                    Text(label, style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              radius: 14,
            ),
          ),
        );
        return Row(
          children: [
            half('left', Icons.rotate_left_rounded, l10n.tutSnakeCtrlLeftSide),
            half(
              'right',
              Icons.rotate_right_rounded,
              l10n.tutSnakeCtrlRightSide,
            ),
          ],
        );
      case SnakeControlMode.swipe:
        return Text(
          l10n.tutSnakeSwipeHint,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: p.textSecondary),
        );
    }
  }
}
