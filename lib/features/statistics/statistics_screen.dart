import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/core/utils/time_formatter.dart';
import 'package:zetzy/core/widgets/tactile_card.dart';
import 'package:zetzy/data/models/game_record.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final recordsAsync = ref.watch(localRecordsProvider);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: recordsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (records) {
              final totalPlayed = records.length;
              final wins = records.where((r) => r.isWon).length;
              final winRate = totalPlayed == 0 ? 0.0 : (wins / totalPlayed) * 100;
              final totalDurationMs = records.fold<int>(
                0,
                (sum, r) => sum + r.durationMs,
              );
              final avgMs =
                  totalPlayed == 0 ? 0 : totalDurationMs ~/ totalPlayed;
              final bestStreak = _computeBestStreak(records);
              final totalXp = _computeTotalXp(records);
              final playerLevel = 1 + (totalXp ~/ 250);
              final levelProgress = (totalXp % 250) / 250.0;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    l10n.navStatistics,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TactileCard(
                    glowColor: p.accent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.statsPlayerLevel(playerLevel),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              l10n.statsXp(totalXp),
                              style: ZetzyThemes.monoStyle(
                                fontSize: 15,
                                color: p.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: levelProgress,
                            minHeight: 10,
                            backgroundColor: p.surfaceElevated,
                            color: p.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount:
                        MediaQuery.sizeOf(context).width > 640 ? 3 : 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.85,
                    children: [
                      _MetricTile(
                        label: l10n.statsTotalGames,
                        value: '$totalPlayed',
                        color: p.textPrimary,
                      ),
                      _MetricTile(
                        label: l10n.statsTotalWins,
                        value: '$wins',
                        color: p.success,
                      ),
                      _MetricTile(
                        label: l10n.statsWinRate,
                        value: '${winRate.toStringAsFixed(1)}%',
                        color: p.accent,
                      ),
                      _MetricTile(
                        label: l10n.statsBestStreak,
                        value: '$bestStreak',
                        color: p.warning,
                      ),
                      _MetricTile(
                        label: l10n.statsTotalTime,
                        value: TimeFormatter.formatTotalDuration(
                          totalDurationMs,
                        ),
                        color: p.accentSecondary,
                      ),
                      _MetricTile(
                        label: l10n.statsAvgTime,
                        value: TimeFormatter.formatMs(avgMs),
                        color: p.textPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TactileCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.statsChartTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 140,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _StatsBarChartPainter(
                              records: records.take(20).toList().reversed.toList(),
                              palette: p,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final game in GameType.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _GameBreakdownCard(
                        game: game,
                        records: records
                            .where((r) => r.gameType == game)
                            .toList(),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  int _computeBestStreak(List<GameRecord> records) {
    final sorted = List<GameRecord>.from(records)
      ..sort((a, b) => a.playedAt.compareTo(b.playedAt));
    var best = 0;
    var current = 0;
    for (final r in sorted) {
      if (r.isWon) {
        current++;
        best = max(best, current);
      } else {
        current = 0;
      }
    }
    return best;
  }

  int _computeTotalXp(List<GameRecord> records) {
    var xp = 0;
    for (final r in records) {
      if (r.isWon) {
        xp += DifficultyLevel.fromLevel(r.difficulty).xpReward;
      } else {
        xp += 5;
      }
    }
    return xp;
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
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
    return TactileCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: p.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: ZetzyThemes.monoStyle(fontSize: 18, color: color),
          ),
        ],
      ),
    );
  }
}

class _GameBreakdownCard extends StatelessWidget {
  const _GameBreakdownCard({required this.game, required this.records});
  final GameType game;
  final List<GameRecord> records;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final total = records.length;
    final won = records.where((r) => r.isWon).length;
    final totalMs = records.fold<int>(0, (s, r) => s + r.durationMs);

    return TactileCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(game.icon, color: p.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.localizedTitle(l10n),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${l10n.statsTotalGames}: $total • ${l10n.statsTotalWins}: $won',
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            TimeFormatter.formatTotalDuration(totalMs),
            style: ZetzyThemes.monoStyle(fontSize: 13, color: p.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _StatsBarChartPainter extends CustomPainter {
  _StatsBarChartPainter({required this.records, required this.palette});
  final List<GameRecord> records;
  final ZetzyPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'No match history yet',
          style: TextStyle(color: palette.textSecondary, fontSize: 13),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
      );
      return;
    }

    final maxDur = records.map((r) => r.durationMs).reduce(max).clamp(1000, 9999999);
    final slotW = size.width / records.length;
    final barW = max(4.0, slotW * 0.62);

    for (var i = 0; i < records.length; i++) {
      final r = records[i];
      final h = max(12.0, (r.durationMs / maxDur) * (size.height - 16));
      final x = i * slotW + (slotW - barW) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h, barW, h),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = r.isWon ? palette.success : palette.danger,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StatsBarChartPainter oldDelegate) => true;
}
