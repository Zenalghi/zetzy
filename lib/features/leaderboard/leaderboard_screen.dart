import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/core/utils/time_formatter.dart';
import 'package:zetzy/core/widgets/platform_badge.dart';
import 'package:zetzy/core/widgets/tactile_card.dart';
import 'package:zetzy/data/models/game_record.dart';
import 'package:zetzy/data/models/user_profile.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  GameType _game = GameType.sudoku;
  DifficultyLevel _difficulty = DifficultyLevel.normal;
  int _tabIndex = 0; // 0: Global, 1: My Best, 2: Chess ELO

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final supa = ref.watch(supabaseServiceProvider);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.navLeaderboard,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<int>(
                  selected: {_tabIndex},
                  onSelectionChanged: (s) => setState(() => _tabIndex = s.first),
                  segments: [
                    ButtonSegment(
                      value: 0,
                      label: Text(l10n.leaderboardGlobal),
                      icon: const Icon(Icons.public_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text(l10n.leaderboardMyBest),
                      icon: const Icon(Icons.person_outline_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: 2,
                      label: Text(l10n.leaderboardChessElo),
                      icon: const Icon(Icons.castle_rounded, size: 18),
                    ),
                  ],
                ),
                if (_tabIndex != 2) ...[
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final g in GameType.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              selected: _game == g,
                              onSelected: (_) => setState(() => _game = g),
                              avatar: Icon(g.icon, size: 16),
                              label: Text(g.localizedTitle(l10n)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final d in DifficultyLevel.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              selected: _difficulty == d,
                              onSelected: (_) =>
                                  setState(() => _difficulty = d),
                              avatar: Image.asset(
                                d.badgeAsset,
                                width: 18,
                                height: 18,
                                errorBuilder: (_, _, _) => const SizedBox(),
                              ),
                              label: Text('${d.level}. ${d.localizedLabel(l10n)}'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: _tabIndex == 2
                      ? _buildChessEloList(supa.isAvailable, p, l10n)
                      : _tabIndex == 0
                      ? _buildGlobalRecordsList(supa.isAvailable, p, l10n)
                      : _buildMyBestList(p, l10n),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyBestList(ZetzyPalette p, AppLocalizations l10n) {
    final asyncRecords = ref.watch(localRecordsProvider);
    return asyncRecords.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (all) {
        final filtered = all
            .where(
              (r) => r.gameType == _game && r.difficulty == _difficulty.level,
            )
            .where((r) => _game == GameType.snake || r.isWon)
            .toList();
        filtered.sort((a, b) {
          if (_game == GameType.snake || _game == GameType.chess) {
            final cmp = b.score.compareTo(a.score);
            return cmp != 0 ? cmp : a.durationMs.compareTo(b.durationMs);
          }
          return a.durationMs.compareTo(b.durationMs);
        });
        return _renderRecordList(filtered.take(100).toList(), p, l10n);
      },
    );
  }

  Widget _buildGlobalRecordsList(
    bool supaReady,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) {
    if (!supaReady) {
      return _OfflineNotice(
        message: l10n.settingsSupabaseLocalOnly,
        fallback: _buildMyBestList(p, l10n),
      );
    }

    return FutureBuilder<List<GameRecord>>(
      future: ref.read(supabaseServiceProvider).fetchGlobalLeaderboard(
        gameType: _game,
        difficulty: _difficulty.level,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _buildMyBestList(p, l10n);
        }
        return _renderRecordList(snap.data ?? const [], p, l10n);
      },
    );
  }

  Widget _buildChessEloList(
    bool supaReady,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) {
    final user = ref.watch(authProvider);
    if (!supaReady) {
      return ListView(
        children: [
          TactileCard(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: p.accent.withValues(alpha: 0.2),
                child: Text('#1', style: TextStyle(color: p.accent)),
              ),
              title: Text('@${user.username}'),
              subtitle: Text(l10n.settingsSupabaseLocalOnly),
              trailing: Text(
                '${user.chessElo} ELO',
                style: ZetzyThemes.monoStyle(fontSize: 16, color: p.accent),
              ),
            ),
          ),
        ],
      );
    }

    return FutureBuilder<List<UserProfile>>(
      future: ref.read(supabaseServiceProvider).fetchChessEloLeaderboard(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data ?? const [];
        if (list.isEmpty) {
          return Center(
            child: Text(
              l10n.leaderboardEmpty,
              style: TextStyle(color: p.textSecondary),
            ),
          );
        }
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final prof = list[i];
            return TactileCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Text(
                      '#${i + 1}',
                      style: ZetzyThemes.monoStyle(
                        fontSize: 14,
                        color: i < 3 ? p.accent : p.textSecondary,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: prof.avatarUrl != null
                        ? NetworkImage(prof.avatarUrl!)
                        : null,
                    child: prof.avatarUrl == null
                        ? Text(prof.username.substring(0, 1).toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '@${prof.username}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${prof.chessElo}',
                    style: ZetzyThemes.monoStyle(
                      fontSize: 15,
                      color: p.accent,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _renderRecordList(
    List<GameRecord> records,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) {
    if (records.isEmpty) {
      return Center(
        child: Text(
          l10n.leaderboardEmpty,
          style: TextStyle(color: p.textSecondary),
        ),
      );
    }

    return ListView.separated(
      itemCount: records.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final r = records[idx];
        return TactileCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  '#${idx + 1}',
                  style: ZetzyThemes.monoStyle(
                    fontSize: 14,
                    color: idx < 3 ? p.accent : p.textSecondary,
                  ),
                ),
              ),
              PlatformBadge(platform: r.platform, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${r.username}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${l10n.scoreLabel}: ${r.score}',
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                TimeFormatter.formatMs(r.durationMs),
                style: ZetzyThemes.monoStyle(
                  fontSize: 14,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice({required this.message, required this.fallback});
  final String message;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: p.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.border),
          ),
          child: Text(
            message,
            style: TextStyle(fontSize: 12, color: p.textSecondary),
          ),
        ),
        Expanded(child: fallback),
      ],
    );
  }
}
