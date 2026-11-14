import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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
import 'package:zetzy/features/games/snake/snake_controller.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

class SnakeScreen extends ConsumerStatefulWidget {
  const SnakeScreen({
    super.key,
    required this.difficulty,
    this.isPractice = false,
    this.resumeSlot,
  });

  final DifficultyLevel difficulty;
  final bool isPractice;
  final AutoSaveSlot? resumeSlot;

  @override
  ConsumerState<SnakeScreen> createState() => _SnakeScreenState();
}

class _SnakeScreenState extends ConsumerState<SnakeScreen> {
  late final SnakeController _controller;
  final FocusNode _focusNode = FocusNode();

  ui.Image? _appleImg;
  ui.Image? _goldenImg;
  ui.Image? _scissorsImg;
  ui.Image? _poisonImg;
  ui.Image? _wallImg;

  @override
  void initState() {
    super.initState();
    _controller = SnakeController(
      audio: ref.read(audioServiceProvider),
      haptics: ref.read(hapticServiceProvider),
      onFinished: _handleGameFinished,
      onAutoSave: (slot) {
        if (!mounted) return;
        ref.read(autoSaveSlotsProvider.notifier).saveSlot(slot);
      },
    );

    if (widget.resumeSlot != null) {
      _controller.restoreFromSlot(widget.resumeSlot!);
    } else {
      _controller.startNew(
        difficulty: widget.difficulty,
        isPractice: widget.isPractice,
      );
    }

    _loadSprites();
  }

  Future<void> _loadSprites() async {
    Future<ui.Image?> load(String path) async {
      try {
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        return frame.image;
      } catch (_) {
        return null;
      }
    }

    final results = await Future.wait([
      load(AssetPaths.snakeApple),
      load(AssetPaths.snakeGolden),
      load(AssetPaths.snakeScissors),
      load(AssetPaths.snakePoison),
      load(AssetPaths.snakeWall),
    ]);
    if (!mounted) return;
    setState(() {
      _appleImg = results[0];
      _goldenImg = results[1];
      _scissorsImg = results[2];
      _poisonImg = results[3];
      _wallImg = results[4];
    });
  }

  Future<void> _handleGameFinished(SnakeGameState finalState) async {
    await ref.read(autoSaveSlotsProvider.notifier).clearSlot(GameType.snake);
    final isNewRecord = await ref
        .read(scoreSyncControllerProvider)
        .recordGameResult(
          gameType: GameType.snake,
          difficulty: finalState.difficulty.level,
          isWon: finalState.isWon,
          score: finalState.score,
          durationMs: finalState.elapsedMs,
          isPractice: finalState.isPractice,
          metadata: {
            'length': finalState.snake.length,
            'foods_eaten': finalState.foodsEaten,
          },
        );

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await showGameResultDialog(
      context: context,
      gameType: GameType.snake,
      difficulty: finalState.difficulty,
      isWon: finalState.isWon,
      durationMs: finalState.elapsedMs,
      score: finalState.score,
      isNewRecord: isNewRecord,
      isPractice: finalState.isPractice,
      extraMetrics: [
        (label: l10n.snakeLength, value: '${finalState.snake.length}'),
      ],
      onPlayAgain: () => _controller.startNew(
        difficulty: finalState.difficulty,
        isPractice: finalState.isPractice,
      ),
      onExit: () => Navigator.of(context).pop(),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      _controller.queueDirection(SnakeDirection.up);
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyS) {
      _controller.queueDirection(SnakeDirection.down);
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.keyA) {
      _controller.queueDirection(SnakeDirection.left);
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      _controller.queueDirection(SnakeDirection.right);
    } else if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.keyP) {
      if (_controller.state.isPaused) {
        _controller.resume();
      } else {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    if (!_controller.state.isGameOver) {
      ref.read(autoSaveSlotsProvider.notifier).saveSlot(_controller.exportSlot());
    }
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);

    return GameLifecycleGuard(
      onAutoPause: () => _controller.pause(),
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              '${l10n.gameSnake} • ${widget.difficulty.localizedLabel(l10n)}',
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
                              Expanded(
                                child: Center(
                                  child: _buildArena(
                                    s,
                                    p,
                                    settings.snakeControlMode,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              SizedBox(
                                width: 290,
                                child: _buildSidebar(
                                  s,
                                  p,
                                  l10n,
                                  settings.snakeControlMode,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            _buildCompactHud(s, p, l10n),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Center(
                                child: _buildArena(
                                  s,
                                  p,
                                  settings.snakeControlMode,
                                ),
                              ),
                            ),
                            if (!PlatformDetector.isDesktopOrWeb &&
                                settings.snakeControlMode ==
                                    SnakeControlMode.dpad) ...[
                              const SizedBox(height: 8),
                              _buildVirtualDpad(p),
                            ] else if (PlatformDetector.isDesktopOrWeb) ...[
                              const SizedBox(height: 6),
                              Text(
                                l10n.snakeDesktopHint,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: p.textSecondary,
                                ),
                              ),
                            ],
                          ],
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

  Widget _buildCompactHud(
    SnakeGameState s,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StatChip(
              label: l10n.scoreLabel,
              value: '${s.score}',
              color: p.accent,
            ),
            _StatChip(
              label: l10n.snakeLength,
              value: '${s.snake.length}',
              color: p.accentSecondary,
            ),
            _StatChip(
              label: l10n.snakeSpeed,
              value: '${(1000 / s.tickMs).toStringAsFixed(1)}/s',
              color: p.textPrimary,
            ),
          ],
        ),
        if (s.hasStarvation) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                l10n.snakeStarvation,
                style: TextStyle(fontSize: 11, color: p.textSecondary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: s.starvationProgress,
                    minHeight: 8,
                    backgroundColor: p.surfaceElevated,
                    color: s.starvationProgress < 0.3
                        ? p.danger
                        : p.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (s.isPoisoned)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.snakeDebuffReversed,
              style: TextStyle(
                color: p.danger,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        if (s.warningObstacles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.snakeObstacleWarning,
              style: TextStyle(
                color: p.warning,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSidebar(
    SnakeGameState s,
    ZetzyPalette p,
    AppLocalizations l10n,
    SnakeControlMode controlMode,
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
          _buildCompactHud(s, p, l10n),
          const Divider(height: 24),
          Text(
            l10n.snakeDesktopHint,
            style: TextStyle(color: p.textSecondary, fontSize: 13),
          ),
          const Spacer(),
          _buildVirtualDpad(p),
        ],
      ),
    );
  }

  Widget _buildArena(
    SnakeGameState s,
    ZetzyPalette p,
    SnakeControlMode controlMode,
  ) {
    Widget board = AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: p.boardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: s.wrapWalls ? p.accent.withValues(alpha: 0.5) : p.danger.withValues(alpha: 0.65),
            width: 2.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          painter: _SnakeBoardPainter(
            state: s,
            palette: p,
            appleImg: _appleImg,
            goldenImg: _goldenImg,
            scissorsImg: _scissorsImg,
            poisonImg: _poisonImg,
            wallImg: _wallImg,
          ),
        ),
      ),
    );

    if (controlMode == SnakeControlMode.splitTap) {
      board = GestureDetector(
        onTapDown: (details) {
          final box = context.findRenderObject() as RenderBox?;
          final width = box?.size.width ?? 300;
          _controller.turnRelative(details.globalPosition.dx > width / 2);
        },
        child: board,
      );
    } else {
      board = GestureDetector(
        onPanUpdate: (details) {
          if (details.delta.distance < 6) return;
          if (details.delta.dx.abs() > details.delta.dy.abs()) {
            _controller.queueDirection(
              details.delta.dx > 0 ? SnakeDirection.right : SnakeDirection.left,
            );
          } else {
            _controller.queueDirection(
              details.delta.dy > 0 ? SnakeDirection.down : SnakeDirection.up,
            );
          }
        },
        child: board,
      );
    }
    return board;
  }

  Widget _buildVirtualDpad(ZetzyPalette p) {
    Widget btn(IconData icon, SnakeDirection dir) => IconButton.filledTonal(
      onPressed: () => _controller.queueDirection(dir),
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: p.surfaceElevated,
        foregroundColor: p.textPrimary,
        minimumSize: const Size(52, 46),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.keyboard_arrow_up_rounded, SnakeDirection.up),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            btn(Icons.keyboard_arrow_left_rounded, SnakeDirection.left),
            const SizedBox(width: 48),
            btn(Icons.keyboard_arrow_right_rounded, SnakeDirection.right),
          ],
        ),
        const SizedBox(height: 4),
        btn(Icons.keyboard_arrow_down_rounded, SnakeDirection.down),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: p.textSecondary)),
          Text(
            value,
            style: ZetzyThemes.monoStyle(fontSize: 14, color: color),
          ),
        ],
      ),
    );
  }
}

class _SnakeBoardPainter extends CustomPainter {
  _SnakeBoardPainter({
    required this.state,
    required this.palette,
    this.appleImg,
    this.goldenImg,
    this.scissorsImg,
    this.poisonImg,
    this.wallImg,
  });

  final SnakeGameState state;
  final ZetzyPalette palette;
  final ui.Image? appleImg;
  final ui.Image? goldenImg;
  final ui.Image? scissorsImg;
  final ui.Image? poisonImg;
  final ui.Image? wallImg;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / state.gridSize;
    final cellH = size.height / state.gridSize;

    // Subtle checkerboard
    final lightPaint = Paint()..color = palette.boardLight.withValues(alpha: 0.2);
    for (var y = 0; y < state.gridSize; y++) {
      for (var x = 0; x < state.gridSize; x++) {
        if ((x + y).isEven) {
          canvas.drawRect(
            Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH),
            lightPaint,
          );
        }
      }
    }

    // Warning shadows for upcoming dynamic obstacles (2s preview)
    if (state.warningObstacles.isNotEmpty) {
      final warnPaint = Paint()
        ..color = palette.warning.withValues(alpha: 0.35);
      for (final w in state.warningObstacles) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w.x * cellW + 2, w.y * cellH + 2, cellW - 4, cellH - 4),
            const Radius.circular(4),
          ),
          warnPaint,
        );
      }
    }

    // Obstacles
    for (final o in state.obstacles) {
      final rect = Rect.fromLTWH(o.x * cellW + 1, o.y * cellH + 1, cellW - 2, cellH - 2);
      if (wallImg != null) {
        paintImage(canvas: canvas, rect: rect, image: wallImg!, fit: BoxFit.cover);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()..color = palette.border,
        );
      }
    }

    // Apple
    _drawItem(
      canvas,
      state.apple,
      cellW,
      cellH,
      appleImg,
      palette.danger,
    );

    // Special Item
    final sp = state.specialItem;
    if (sp != null) {
      final (img, fallbackColor) = switch (sp.kind) {
        SnakeSpecialKind.golden => (goldenImg, palette.warning),
        SnakeSpecialKind.scissors => (scissorsImg, palette.accentSecondary),
        SnakeSpecialKind.poison => (poisonImg, Colors.purpleAccent),
      };
      _drawItem(canvas, sp.point, cellW, cellH, img, fallbackColor);
    }

    // Connected smooth snake body (PRD 66B)
    if (state.snake.isNotEmpty) {
      final bodyPaint = Paint()
        ..color = palette.snakeBody
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = cellW * 0.78
        ..style = PaintingStyle.stroke;

      if (state.snake.length > 1) {
        final path = Path();
        for (var i = 0; i < state.snake.length; i++) {
          final curr = state.snake[i];
          final cx = (curr.x + 0.5) * cellW;
          final cy = (curr.y + 0.5) * cellH;
          if (i == 0) {
            path.moveTo(cx, cy);
          } else {
            final prev = state.snake[i - 1];
            // Break line when wrapping around edges
            if ((curr.x - prev.x).abs() > 1 || (curr.y - prev.y).abs() > 1) {
              path.moveTo(cx, cy);
            } else {
              path.lineTo(cx, cy);
            }
          }
        }
        canvas.drawPath(path, bodyPaint);
      }

      // Head with directional eyes
      final head = state.snake.first;
      final headCenter = Offset((head.x + 0.5) * cellW, (head.y + 0.5) * cellH);
      canvas.drawCircle(
        headCenter,
        cellW * 0.44,
        Paint()..color = palette.snakeHead,
      );

      final eyeOffset = cellW * 0.16;
      final forward = cellW * 0.14;
      final dx = state.direction.dx.toDouble();
      final dy = state.direction.dy.toDouble();
      final px = -dy;
      final py = dx;

      final eye1 = headCenter + Offset(dx * forward + px * eyeOffset, dy * forward + py * eyeOffset);
      final eye2 = headCenter + Offset(dx * forward - px * eyeOffset, dy * forward - py * eyeOffset);
      final whitePaint = Paint()..color = Colors.white;
      final pupilPaint = Paint()..color = Colors.black;
      canvas.drawCircle(eye1, cellW * 0.1, whitePaint);
      canvas.drawCircle(eye2, cellW * 0.1, whitePaint);
      canvas.drawCircle(eye1 + Offset(dx * 1.2, dy * 1.2), cellW * 0.05, pupilPaint);
      canvas.drawCircle(eye2 + Offset(dx * 1.2, dy * 1.2), cellW * 0.05, pupilPaint);
    }
  }

  void _drawItem(
    Canvas canvas,
    GridPoint pt,
    double cellW,
    double cellH,
    ui.Image? image,
    Color fallback,
  ) {
    final rect = Rect.fromLTWH(
      pt.x * cellW + cellW * 0.1,
      pt.y * cellH + cellH * 0.1,
      cellW * 0.8,
      cellH * 0.8,
    );
    if (image != null) {
      paintImage(canvas: canvas, rect: rect, image: image, fit: BoxFit.contain);
    } else {
      canvas.drawOval(rect, Paint()..color = fallback);
    }
  }

  @override
  bool shouldRepaint(covariant _SnakeBoardPainter oldDelegate) => true;
}
