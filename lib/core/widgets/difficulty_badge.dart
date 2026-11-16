import 'package:material_ui/material_ui.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/core/widgets/game_type_icon.dart';
import 'package:zetzy/core/widgets/tactile_card.dart';
import 'package:zetzy/data/models/game_record.dart';
import 'package:zetzy/data/models/user_profile.dart';
import 'package:zetzy/l10n/app_localizations.dart';

/// Crisp nearest-neighbor pixel-art renderer for difficulty tier crest badges.
class DifficultyBadgeImage extends StatelessWidget {
  const DifficultyBadgeImage({
    super.key,
    required this.difficulty,
    required this.size,
    this.locked = false,
    this.showGlow = false,
    this.glowColor,
  });

  final DifficultyLevel difficulty;
  final double size;
  final bool locked;
  final bool showGlow;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tint = glowColor ?? _tierAccentColor(difficulty, p);

    Widget img = Image.asset(
      difficulty.badgeAsset,
      width: size,
      height: size,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, _, _) => CircleAvatar(
        radius: size / 2,
        backgroundColor: p.accent,
        child: Text(
          '${difficulty.level}',
          style: TextStyle(
            fontSize: (size * 0.4).clamp(10.0, 48.0),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );

    if (locked) {
      img = Opacity(opacity: 0.42, child: img);
    }

    if (!showGlow && !locked) return img;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (showGlow && !locked)
          Container(
            width: size * 0.92,
            height: size * 0.92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: tint.withValues(alpha: 0.34),
                  blurRadius: size * 0.32,
                  spreadRadius: size * 0.02,
                ),
              ],
            ),
          ),
        img,
        if (locked && size >= 36)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: EdgeInsets.all((size * 0.08).clamp(3.0, 6.0)),
              decoration: BoxDecoration(
                color: p.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: p.border),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: (size * 0.24).clamp(11.0, 22.0),
                color: p.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

Color _tierAccentColor(DifficultyLevel diff, ZetzyPalette p) => switch (diff) {
  DifficultyLevel.chill => const Color(0xFF4ADE80),
  DifficultyLevel.easy => const Color(0xFF38BDF8),
  DifficultyLevel.normal => p.accentSecondary,
  DifficultyLevel.high => p.warning,
  DifficultyLevel.pro => const Color(0xFFA855F7),
  DifficultyLevel.nightmare => p.danger,
  DifficultyLevel.god => const Color(0xFFFACC15),
};

/// Summarizes badge conquest & unlock counts across the 4 Zetzy games.
class BadgeProgressSummary {
  BadgeProgressSummary.fromData({
    required this.user,
    required List<GameRecord> records,
  }) : winsByGameAndLevel = _countWins(records);

  final UserProfile user;
  final Map<(GameType, int), int> winsByGameAndLevel;

  static Map<(GameType, int), int> _countWins(List<GameRecord> records) {
    final counts = <(GameType, int), int>{};
    for (final r in records) {
      if (!r.isWon) continue;
      final key = (r.gameType, r.difficulty);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  int winsFor(GameType game, DifficultyLevel diff) =>
      winsByGameAndLevel[(game, diff.level)] ?? 0;

  bool isUnlocked(GameType game, DifficultyLevel diff) =>
      user.unlockedFor(game) >= diff.level;

  bool isUnlockedAnywhere(DifficultyLevel diff) =>
      diff.level <= DifficultyLevel.defaultUnlockedLevel ||
      GameType.values.any((g) => isUnlocked(g, diff));

  int gamesWonFor(DifficultyLevel diff) =>
      GameType.values.where((g) => winsFor(g, diff) > 0).length;

  int get conqueredTierCount => DifficultyLevel.values
      .where((d) => gamesWonFor(d) > 0)
      .length;

  DifficultyLevel? get highestConqueredTier {
    for (final d in DifficultyLevel.values.reversed) {
      if (gamesWonFor(d) > 0) return d;
    }
    return null;
  }
}

/// Interactive 7-tier Rank Badges showcase card for Profile/Statistics.
class DifficultyBadgeShowcaseCard extends StatelessWidget {
  const DifficultyBadgeShowcaseCard({
    super.key,
    required this.summary,
  });

  final BadgeProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;

    return TactileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.military_tech_rounded,
                  size: 18,
                  color: p.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.badgesTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      l10n.badgesSubtitle,
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: p.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.border),
                ),
                child: Text(
                  l10n.badgesConqueredCount(summary.conqueredTierCount, 7),
                  style: ZetzyThemes.monoStyle(
                    fontSize: 11,
                    color: summary.conqueredTierCount > 0
                        ? p.accent
                        : p.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final diff in DifficultyLevel.values)
                  _BadgeThumbTile(
                    difficulty: diff,
                    unlocked: summary.isUnlockedAnywhere(diff),
                    wonGames: summary.gamesWonFor(diff),
                    onTap: () => showDifficultyBadgeInspectDialog(
                      context: context,
                      initialDifficulty: diff,
                      summary: summary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeThumbTile extends StatelessWidget {
  const _BadgeThumbTile({
    required this.difficulty,
    required this.unlocked,
    required this.wonGames,
    required this.onTap,
  });

  final DifficultyLevel difficulty;
  final bool unlocked;
  final int wonGames;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final conquered = wonGames > 0;
    final tierColor = _tierAccentColor(difficulty, p);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: conquered
                ? tierColor.withValues(alpha: 0.1)
                : p.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: conquered ? tierColor.withValues(alpha: 0.55) : p.border,
              width: conquered ? 1.3 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DifficultyBadgeImage(
                difficulty: difficulty,
                size: 46,
                locked: !unlocked,
                showGlow: conquered,
                glowColor: tierColor,
              ),
              const SizedBox(height: 6),
              Text(
                difficulty.localizedLabel(l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: unlocked ? p.textPrimary : p.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                conquered ? '$wonGames/4 ✓' : 'Lv ${difficulty.level}',
                style: ZetzyThemes.monoStyle(
                  fontSize: 10,
                  color: conquered ? tierColor : p.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens an interactive high-resolution modal showing the crisp enlarged crest
/// medal and per-game mastery status without duplicating badges per game.
Future<void> showDifficultyBadgeInspectDialog({
  required BuildContext context,
  required DifficultyLevel initialDifficulty,
  BadgeProgressSummary? summary,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _DifficultyBadgeInspectDialog(
      initialDifficulty: initialDifficulty,
      summary: summary,
    ),
  );
}

class _DifficultyBadgeInspectDialog extends StatefulWidget {
  const _DifficultyBadgeInspectDialog({
    required this.initialDifficulty,
    this.summary,
  });

  final DifficultyLevel initialDifficulty;
  final BadgeProgressSummary? summary;

  @override
  State<_DifficultyBadgeInspectDialog> createState() =>
      _DifficultyBadgeInspectDialogState();
}

class _DifficultyBadgeInspectDialogState
    extends State<_DifficultyBadgeInspectDialog> {
  late DifficultyLevel _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialDifficulty;
  }

  void _step(int delta) {
    const all = DifficultyLevel.values;
    final nextIdx = (_current.index + delta).clamp(0, all.length - 1);
    setState(() => _current = all[nextIdx]);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final tierColor = _tierAccentColor(_current, p);
    final summary = widget.summary;
    final unlockedAnywhere = summary?.isUnlockedAnywhere(_current) ?? true;
    final prevLabel = _current.level > 1
        ? DifficultyLevel.fromLevel(_current.level - 1).localizedLabel(l10n)
        : '';

    final subtitleText = !unlockedAnywhere
        ? l10n.lockedLevelHint(prevLabel)
        : (_current.level <= DifficultyLevel.defaultUnlockedLevel
              ? l10n.badgeAvailableAllGames
              : l10n.badgeUnlockedChallenge);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: tierColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tierColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      '+${_current.xpReward} XP',
                      style: ZetzyThemes.monoStyle(
                        fontSize: 12,
                        color: tierColor,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _current.index > 0 ? () => _step(-1) : null,
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  ),
                  Expanded(
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutBack,
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: DifficultyBadgeImage(
                          key: ValueKey(_current),
                          difficulty: _current,
                          size: 160,
                          locked: !unlockedAnywhere,
                          showGlow: unlockedAnywhere,
                          glowColor: tierColor,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _current.index < DifficultyLevel.values.length - 1
                        ? () => _step(1)
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${_current.level}. ${_current.localizedLabel(l10n)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitleText,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: p.textSecondary),
              ),
              if (summary != null) ...[
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemW = (constraints.maxWidth - 8) / 2;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final g in GameType.values)
                          _buildGameStatusChip(
                            game: g,
                            summary: summary,
                            width: itemW,
                            tierColor: tierColor,
                            p: p,
                            l10n: l10n,
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameStatusChip({
    required GameType game,
    required BadgeProgressSummary summary,
    required double width,
    required Color tierColor,
    required ZetzyPalette p,
    required AppLocalizations l10n,
  }) {
    final wins = summary.winsFor(game, _current);
    final unlocked = summary.isUnlocked(game, _current);
    final statusText = wins > 0
        ? l10n.badgeWonCount(wins)
        : (unlocked ? l10n.badgeStatusOpen : l10n.badgeStatusLocked);

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: wins > 0
            ? tierColor.withValues(alpha: 0.12)
            : p.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: wins > 0 ? tierColor.withValues(alpha: 0.5) : p.border,
        ),
      ),
      child: Row(
        children: [
          GameTypeIcon(
            game: game,
            size: 16,
            color: unlocked ? p.textPrimary : p.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.localizedTitle(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: unlocked ? p.textPrimary : p.textSecondary,
                  ),
                ),
                Text(
                  statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: wins > 0 ? tierColor : p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            wins > 0
                ? Icons.check_circle_rounded
                : (unlocked
                      ? Icons.lock_open_rounded
                      : Icons.lock_outline_rounded),
            size: 15,
            color: wins > 0 ? tierColor : p.textSecondary,
          ),
        ],
      ),
    );
  }
}
