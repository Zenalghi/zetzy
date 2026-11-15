import 'dart:math';
import 'dart:ui' as ui;

import 'package:confetti/confetti.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/core/utils/platform_detector.dart';
import 'package:zetzy/core/utils/time_formatter.dart';
import 'package:zetzy/core/widgets/platform_badge.dart';
import 'package:zetzy/l10n/app_localizations.dart';

/// Displays celebratory win/game-over summary with Confetti & Share Score card (PRD 71A, 73A).
Future<void> showGameResultDialog({
  required BuildContext context,
  required GameType gameType,
  required DifficultyLevel difficulty,
  required bool isWon,
  required int durationMs,
  required int score,
  bool isDraw = false,
  bool isNewRecord = false,
  bool isPractice = false,
  List<({String label, String value})> extraMetrics = const [],
  int rewindSteps = 1,
  VoidCallback? onRewindContinue,
  required VoidCallback onPlayAgain,
  required VoidCallback onExit,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _GameResultDialog(
      gameType: gameType,
      difficulty: difficulty,
      isWon: isWon,
      isDraw: isDraw,
      durationMs: durationMs,
      score: score,
      isNewRecord: isNewRecord,
      isPractice: isPractice,
      extraMetrics: extraMetrics,
      rewindSteps: rewindSteps,
      onRewindContinue: onRewindContinue,
      onPlayAgain: onPlayAgain,
      onExit: onExit,
    ),
  );
}

class _GameResultDialog extends StatefulWidget {
  const _GameResultDialog({
    required this.gameType,
    required this.difficulty,
    required this.isWon,
    required this.isDraw,
    required this.durationMs,
    required this.score,
    required this.isNewRecord,
    required this.isPractice,
    required this.extraMetrics,
    this.rewindSteps = 1,
    this.onRewindContinue,
    required this.onPlayAgain,
    required this.onExit,
  });

  final GameType gameType;
  final DifficultyLevel difficulty;
  final bool isWon;
  final bool isDraw;
  final int durationMs;
  final int score;
  final bool isNewRecord;
  final bool isPractice;
  final List<({String label, String value})> extraMetrics;
  final int rewindSteps;
  final VoidCallback? onRewindContinue;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  @override
  State<_GameResultDialog> createState() => _GameResultDialogState();
}

class _GameResultDialogState extends State<_GameResultDialog> {
  late final ConfettiController _confetti;
  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    if (widget.isWon) {
      _confetti.play();
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _shareScoreCard(AppLocalizations l10n) async {
    final text =
        'Zetzy • ${widget.gameType.localizedTitle(l10n)} '
        '(${widget.difficulty.localizedLabel(l10n)})\n'
        '${widget.isWon ? l10n.victory : (widget.isDraw ? l10n.draw : l10n.gameOver)} '
        '| ${l10n.timeLabel}: ${TimeFormatter.formatMs(widget.durationMs)} '
        '| ${l10n.scoreLabel}: ${widget.score}';

    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final bytes = byteData.buffer.asUint8List();
          await SharePlus.instance.share(
            ShareParams(
              text: text,
              files: [
                XFile.fromData(
                  bytes,
                  mimeType: 'image/png',
                  name: 'zetzy_score.png',
                ),
              ],
            ),
          );
          return;
        }
      }
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.copied)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;

    final title = widget.isDraw
        ? l10n.draw
        : (widget.isWon ? l10n.victory : l10n.gameOver);
    final accentColor = widget.isWon
        ? p.success
        : (widget.isDraw ? p.warning : p.danger);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                RepaintBoundary(
                  key: _cardKey,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  widget.difficulty.badgeAsset,
                                  width: 28,
                                  height: 28,
                                  errorBuilder: (_, _, _) =>
                                      Icon(widget.gameType.icon, color: p.accent),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Zetzy • ${widget.gameType.localizedTitle(l10n)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: p.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            PlatformBadge(
                              platform: PlatformDetector.currentPlatform,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Icon(
                          widget.isWon
                              ? Icons.emoji_events_rounded
                              : (widget.isDraw
                                    ? Icons.handshake_rounded
                                    : Icons.sentiment_dissatisfied_rounded),
                          size: 48,
                          color: accentColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: p.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.difficulty.level}. ${widget.difficulty.localizedLabel(l10n)}'
                          '${widget.isPractice ? ' (${l10n.practiceMode})' : ''}',
                          style: TextStyle(color: p.textSecondary),
                        ),
                        if (widget.isNewRecord && !widget.isPractice) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: p.accent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: p.accent),
                            ),
                            child: Text(
                              l10n.newRecord,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: p.accent,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: p.surfaceElevated,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _MetricRow(
                                label: l10n.timeLabel,
                                value: TimeFormatter.formatMs(widget.durationMs),
                                mono: true,
                              ),
                              const SizedBox(height: 8),
                              _MetricRow(
                                label: l10n.scoreLabel,
                                value: '${widget.score}',
                                mono: true,
                              ),
                              for (final m in widget.extraMetrics) ...[
                                const SizedBox(height: 8),
                                _MetricRow(
                                  label: m.label,
                                  value: m.value,
                                  mono: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (widget.onRewindContinue != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onRewindContinue!();
                      },
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: Text(
                        l10n.practiceRewindContinue(widget.rewindSteps),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: p.surface,
                          foregroundColor: p.textPrimary,
                          side: BorderSide(color: p.border),
                        ),
                        onPressed: () => _shareScoreCard(l10n),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: Text(l10n.shareScore),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: widget.onRewindContinue != null
                          ? OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: p.surface,
                                foregroundColor: p.textPrimary,
                                side: BorderSide(color: p.border),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                widget.onPlayAgain();
                              },
                              icon: const Icon(Icons.replay_rounded, size: 18),
                              label: Text(l10n.playAgain),
                            )
                          : FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                widget.onPlayAgain();
                              },
                              icon: const Icon(Icons.replay_rounded, size: 18),
                              label: Text(l10n.playAgain),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: p.surface,
                      foregroundColor: p.textPrimary,
                      side: BorderSide(color: p.border),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onExit();
                    },
                    icon: const Icon(Icons.home_rounded, size: 18),
                    label: Text(l10n.backToHome),
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
        ConfettiWidget(
          confettiController: _confetti,
          blastDirection: pi / 2,
          emissionFrequency: 0.06,
          numberOfParticles: 24,
          gravity: 0.25,
          colors: [p.accent, p.accentSecondary, p.warning, p.success],
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    this.mono = false,
  });

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: p.textSecondary, fontSize: 13)),
        Text(
          value,
          style: mono
              ? ZetzyThemes.monoStyle(fontSize: 14, color: p.textPrimary)
              : TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary),
        ),
      ],
    );
  }
}
