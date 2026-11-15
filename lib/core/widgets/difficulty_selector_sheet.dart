import 'package:material_ui/material_ui.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/l10n/app_localizations.dart';

class DifficultySelection {
  const DifficultySelection({
    required this.difficulty,
    required this.isPractice,
  });

  final DifficultyLevel difficulty;
  final bool isPractice;
}

/// Bottom sheet / dialog to pick 1 of 7 difficulty levels + Practice Mode toggle.
Future<DifficultySelection?> showDifficultySelector({
  required BuildContext context,
  required GameType gameType,
  required int maxUnlockedLevel,
  DifficultyLevel initialLevel = DifficultyLevel.normal,
}) {
  return showModalBottomSheet<DifficultySelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _DifficultySelectorSheet(
      gameType: gameType,
      maxUnlockedLevel: maxUnlockedLevel,
      initialLevel: initialLevel,
    ),
  );
}

class _DifficultySelectorSheet extends StatefulWidget {
  const _DifficultySelectorSheet({
    required this.gameType,
    required this.maxUnlockedLevel,
    required this.initialLevel,
  });

  final GameType gameType;
  final int maxUnlockedLevel;
  final DifficultyLevel initialLevel;

  @override
  State<_DifficultySelectorSheet> createState() =>
      _DifficultySelectorSheetState();
}

class _DifficultySelectorSheetState extends State<_DifficultySelectorSheet> {
  late DifficultyLevel _selected;
  bool _practice = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialLevel.level <= widget.maxUnlockedLevel
        ? widget.initialLevel
        : DifficultyLevel.chill;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: p.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(widget.gameType.icon, color: p.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${widget.gameType.localizedTitle(l10n)} — ${l10n.selectDifficulty}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: DifficultyLevel.values.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final diff = DifficultyLevel.values[index];
                      final isLocked = diff.level > widget.maxUnlockedLevel;
                      final isSelected = diff == _selected;
                      final prevLabel = diff.level > 1
                          ? DifficultyLevel.fromLevel(
                              diff.level - 1,
                            ).localizedLabel(l10n)
                          : '';

                      return InkWell(
                        onTap: isLocked
                            ? null
                            : () => setState(() => _selected = diff),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? p.accent.withValues(alpha: 0.14)
                                : p.surfaceElevated,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? p.accent : p.border,
                              width: isSelected ? 1.6 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Opacity(
                                opacity: isLocked ? 0.38 : 1,
                                child: Image.asset(
                                  diff.badgeAsset,
                                  width: 32,
                                  height: 32,
                                  errorBuilder: (_, _, _) => CircleAvatar(
                                    radius: 16,
                                    backgroundColor: p.accent,
                                    child: Text('${diff.level}'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${diff.level}. ${diff.localizedLabel(l10n)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: isLocked
                                            ? p.textSecondary
                                            : p.textPrimary,
                                      ),
                                    ),
                                    if (isLocked)
                                      Text(
                                        l10n.lockedLevelHint(prevLabel),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: p.warning,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isLocked)
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 18,
                                  color: p.textSecondary,
                                )
                              else
                                Text(
                                  '+${diff.xpReward} XP',
                                  style: ZetzyThemes.monoStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? p.accent
                                        : p.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  type: MaterialType.transparency,
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _practice,
                    onChanged: (v) => setState(() => _practice = v),
                    title: Text(
                      l10n.practiceMode,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      l10n.practiceModeDesc,
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(
                    DifficultySelection(
                      difficulty: _selected,
                      isPractice: _practice,
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.play),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
