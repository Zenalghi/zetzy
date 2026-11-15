import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/core/utils/platform_detector.dart';
import 'package:zetzy/core/widgets/anti_cheat_pause_overlay.dart';
import 'package:zetzy/core/widgets/game_lifecycle_guard.dart';
import 'package:zetzy/core/widgets/game_timer_badge.dart';
import 'package:zetzy/core/widgets/win_result_dialog.dart';
import 'package:zetzy/data/models/auto_save_slot.dart';
import 'package:zetzy/features/games/minesweeper/minesweeper_controller.dart';
import 'package:zetzy/features/games/minesweeper/minesweeper_engine.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

class MinesweeperScreen extends ConsumerStatefulWidget {
  const MinesweeperScreen({
    super.key,
    required this.difficulty,
    this.isPractice = false,
    this.resumeSlot,
  });

  final DifficultyLevel difficulty;
  final bool isPractice;
  final AutoSaveSlot? resumeSlot;

  @override
  ConsumerState<MinesweeperScreen> createState() => _MinesweeperScreenState();
}

class _MinesweeperScreenState extends ConsumerState<MinesweeperScreen> {
  late final MinesweeperController _controller;
  late final AutoSaveSlotsNotifier _autoSaveSlots;
  final TransformationController _transformCtrl = TransformationController();
  final FocusNode _focusNode = FocusNode();
  bool _spaceHeld = false;
  bool _isPanningPointer = false;
  Offset? _lastPanPos;

  @override
  void initState() {
    super.initState();
    _autoSaveSlots = ref.read(autoSaveSlotsProvider.notifier);
    _controller = MinesweeperController(
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

  Future<void> _handleGameFinished(MinesweeperGameState finalState) async {
    await ref
        .read(autoSaveSlotsProvider.notifier)
        .clearSlot(GameType.minesweeper);

    // Higher score = higher 3BV * 100 or bonus for speed
    final score = finalState.isWon
        ? (finalState.bbbv * 100 +
              (finalState.bbbvPerSec * 100).round())
        : 0;

    final isNewRecord = await ref
        .read(scoreSyncControllerProvider)
        .recordGameResult(
          gameType: GameType.minesweeper,
          difficulty: finalState.difficulty.level,
          isWon: finalState.isWon,
          score: score,
          durationMs: finalState.elapsedMs,
          isPractice: finalState.isPractice,
          metadata: {
            '3bv': finalState.bbbv,
            '3bv_s': double.parse(finalState.bbbvPerSec.toStringAsFixed(2)),
          },
        );

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.read(settingsProvider);
    final canRewind =
        finalState.isPractice &&
        !finalState.isWon &&
        settings.practiceRewindOnLoss &&
        finalState.canPracticeUndo;
    await showGameResultDialog(
      context: context,
      gameType: GameType.minesweeper,
      difficulty: finalState.difficulty,
      isWon: finalState.isWon,
      durationMs: finalState.elapsedMs,
      score: score,
      isNewRecord: isNewRecord,
      isPractice: finalState.isPractice,
      extraMetrics: [
        (label: l10n.mine3bv, value: '${finalState.bbbv}'),
        (
          label: l10n.mine3bvSec,
          value: finalState.bbbvPerSec.toStringAsFixed(2),
        ),
      ],
      rewindSteps: settings.practiceRewindSteps,
      onRewindContinue: canRewind
          ? () => _controller.practiceRewind(settings.practiceRewindSteps)
          : null,
      onPlayAgain: () {
        _transformCtrl.value = Matrix4.identity();
        _controller.startNew(
          difficulty: finalState.difficulty,
          isPractice: finalState.isPractice,
        );
      },
      onExit: () => Navigator.of(context).pop(),
    );
  }

  @override
  void dispose() {
    if (_controller.state.hasStarted && !_controller.state.isGameOver) {
      _autoSaveSlots.saveSlot(_controller.exportSlot());
    }
    _transformCtrl.dispose();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _zoomBy(double factor, Offset focalPoint) {
    final current = _transformCtrl.value.clone();
    final scale = current.getMaxScaleOnAxis();
    final nextScale = (scale * factor).clamp(0.7, 3.2);
    final appliedFactor = nextScale / scale;
    final matrix = Matrix4.identity()
      ..translateByDouble(focalPoint.dx, focalPoint.dy, 0, 1)
      ..scaleByDouble(appliedFactor, appliedFactor, 1, 1)
      ..translateByDouble(-focalPoint.dx, -focalPoint.dy, 0, 1);
    _transformCtrl.value = matrix * current;
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
        onKeyEvent: (event) {
          if (event.logicalKey == LogicalKeyboardKey.space) {
            _spaceHeld = event is KeyDownEvent || event is KeyRepeatEvent;
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              '${l10n.gameMinesweeper} • ${widget.difficulty.localizedLabel(l10n)}',
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
                              Expanded(child: _buildInteractiveBoard(s, p)),
                              const SizedBox(width: 18),
                              SizedBox(
                                width: 312,
                                child: _buildSidebar(s, p, l10n),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: _buildHeaderRow(s, p, l10n),
                          ),
                          Expanded(child: _buildInteractiveBoard(s, p)),
                          _buildBottomToolbar(s, p, l10n),
                        ],
                      );
                    },
                  ),
                  AntiCheatPauseOverlay(
                    isPaused: s.isPaused && !s.isGameOver,
                    onResume: () => _controller.resume(),
                    onRestart: () {
                      _transformCtrl.value = Matrix4.identity();
                      _controller.startNew(
                        difficulty: widget.difficulty,
                        isPractice: widget.isPractice,
                      );
                    },
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

  Widget _buildHeaderRow(
    MinesweeperGameState s,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(AssetPaths.mineNormal, width: 18, height: 18),
              const SizedBox(width: 6),
              Text(
                '${s.remainingMines}',
                style: ZetzyThemes.monoStyle(fontSize: 15, color: p.textPrimary),
              ),
            ],
          ),
        ),
        if (s.shieldRemaining > 0) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: p.success.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.success),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(AssetPaths.mineShield, width: 16, height: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l10n.mineShieldActive,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: p.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (s.isPractice) ...[
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: l10n.practiceUndo,
            onPressed: s.canPracticeUndo && !s.isPaused
                ? _controller.practiceUndo
                : null,
            icon: const Icon(Icons.undo_rounded, size: 18),
          ),
        ],
        const SizedBox(width: 8),
        IconButton.outlined(
          tooltip: 'Reset Zoom',
          onPressed: () => _transformCtrl.value = Matrix4.identity(),
          icon: const Icon(Icons.center_focus_strong_rounded, size: 18),
        ),
      ],
    );
  }

  Widget _buildSidebar(
    MinesweeperGameState s,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderRow(s, p, l10n),
          const SizedBox(height: 16),
          _buildToolSegments(s, p, l10n),
          const SizedBox(height: 16),
          Text(
            l10n.mineDesktopHint,
            style: TextStyle(fontSize: 12, color: p.textSecondary),
          ),
          const Spacer(),
          if (s.isPractice) ...[
            OutlinedButton.icon(
              onPressed: s.canPracticeUndo && !s.isPaused
                  ? _controller.practiceUndo
                  : null,
              icon: const Icon(Icons.undo_rounded),
              label: Text(l10n.practiceUndo),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: () {
              _transformCtrl.value = Matrix4.identity();
              _controller.startNew(
                difficulty: widget.difficulty,
                isPractice: widget.isPractice,
              );
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.restart),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar(
    MinesweeperGameState s,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToolSegments(s, p, l10n),
            if (PlatformDetector.isDesktopOrWeb)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.mineDesktopHint,
                  style: TextStyle(fontSize: 11, color: p.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolSegments(
    MinesweeperGameState s,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) {
    return SegmentedButton<MineTapTool>(
      selected: {s.tool},
      onSelectionChanged: (set) => _controller.setTool(set.first),
      segments: [
        ButtonSegment(
          value: MineTapTool.dig,
          icon: const Icon(Icons.hardware_rounded, size: 18),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(l10n.mineModeDig, softWrap: false, maxLines: 1),
          ),
        ),
        ButtonSegment(
          value: MineTapTool.flag,
          icon: Image.asset(AssetPaths.mineFlag, width: 16, height: 16),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(l10n.mineModeFlag, softWrap: false, maxLines: 1),
          ),
        ),
        ButtonSegment(
          value: MineTapTool.question,
          icon: Image.asset(AssetPaths.mineQuestion, width: 16, height: 16),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(l10n.mineModeQuestion, softWrap: false, maxLines: 1),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveBoard(MinesweeperGameState s, ZetzyPalette p) {
    const double cellSize = 36.0;
    final boardWidth = s.cols * cellSize;
    final boardHeight = s.rows * cellSize;

    // Desktop & Web Listener for Scroll Zoom, Middle/Space+Drag Pan, Right-Click Flag
    return Listener(
      onPointerSignal: (signal) {
        if (signal is PointerScrollEvent) {
          final factor = signal.scrollDelta.dy < 0 ? 1.12 : 0.89;
          _zoomBy(factor, signal.localPosition);
        }
      },
      onPointerDown: (event) {
        if (event.buttons == kMiddleMouseButton ||
            (_spaceHeld && event.buttons == kPrimaryMouseButton)) {
          _isPanningPointer = true;
          _lastPanPos = event.localPosition;
        }
      },
      onPointerMove: (event) {
        if (_isPanningPointer && _lastPanPos != null) {
          final delta = event.localPosition - _lastPanPos!;
          _lastPanPos = event.localPosition;
          final next = _transformCtrl.value.clone()
            ..translateByDouble(delta.dx, delta.dy, 0, 1);
          _transformCtrl.value = next;
        }
      },
      onPointerUp: (_) {
        _isPanningPointer = false;
        _lastPanPos = null;
      },
      child: InteractiveViewer(
        transformationController: _transformCtrl,
        minScale: 0.65,
        maxScale: 3.2,
        boundaryMargin: const EdgeInsets.all(120),
        constrained: false,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.border, width: 1.5),
          ),
          child: SizedBox(
            width: boardWidth,
            height: boardHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var r = 0; r < s.rows; r++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var c = 0; c < s.cols; c++)
                        _MineCellTile(
                          cell: s.grid[r][c],
                          size: cellSize,
                          palette: p,
                          onTap: () => _controller.onCellTap(r, c),
                          onSecondaryOrLongPress: () =>
                              _controller.onCellLongPressOrRightClick(r, c),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MineCellTile extends StatelessWidget {
  const _MineCellTile({
    required this.cell,
    required this.size,
    required this.palette,
    required this.onTap,
    required this.onSecondaryOrLongPress,
  });

  final MineCell cell;
  final double size;
  final ZetzyPalette palette;
  final VoidCallback onTap;
  final VoidCallback onSecondaryOrLongPress;

  Color _numberColor(int n) => switch (n) {
    1 => const Color(0xFF38BDF8),
    2 => const Color(0xFF4ADE80),
    3 => const Color(0xFFFB7185),
    4 => const Color(0xFFA78BFA),
    5 => const Color(0xFFF59E0B),
    6 => const Color(0xFF2DD4BF),
    7 => palette.textPrimary,
    _ => palette.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final bgColor = cell.isExploded
        ? palette.danger.withValues(alpha: 0.35)
        : (cell.isRevealed ? palette.boardDark : palette.boardLight);

    Widget? content;
    if (cell.isDefused) {
      content = Padding(
        padding: const EdgeInsets.all(4),
        child: Image.asset(AssetPaths.mineDefused),
      );
    } else if (cell.isRevealed && cell.isMine) {
      content = Padding(
        padding: const EdgeInsets.all(4),
        child: Image.asset(
          cell.isExploded ? AssetPaths.mineExploded : AssetPaths.mineNormal,
        ),
      );
    } else if (cell.isRevealed && cell.adjacentMines > 0) {
      content = Center(
        child: Text(
          '${cell.adjacentMines}',
          style: ZetzyThemes.monoStyle(
            fontSize: 16,
            color: _numberColor(cell.adjacentMines),
          ),
        ),
      );
    } else if (!cell.isRevealed) {
      if (cell.mark == MineCellMark.flag) {
        content = Padding(
          padding: const EdgeInsets.all(5),
          child: Image.asset(AssetPaths.mineFlag),
        );
      } else if (cell.mark == MineCellMark.question) {
        content = Padding(
          padding: const EdgeInsets.all(5),
          child: Image.asset(AssetPaths.mineQuestion),
        );
      }
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onSecondaryOrLongPress,
      onSecondaryTap: onSecondaryOrLongPress,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: palette.border.withValues(alpha: cell.isRevealed ? 0.35 : 0.8),
            width: 0.8,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: content,
      ),
    );
  }
}
