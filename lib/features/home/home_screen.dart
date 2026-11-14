import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/core/utils/time_formatter.dart';
import 'package:zetzy/core/widgets/difficulty_selector_sheet.dart';
import 'package:zetzy/core/widgets/tactile_card.dart';
import 'package:zetzy/data/models/auto_save_slot.dart';
import 'package:zetzy/features/games/chess/chess_screen.dart';
import 'package:zetzy/features/games/minesweeper/minesweeper_screen.dart';
import 'package:zetzy/features/games/snake/snake_screen.dart';
import 'package:zetzy/features/games/sudoku/sudoku_screen.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _launchNewGame(
    BuildContext context,
    WidgetRef ref,
    GameType gameType,
  ) async {
    final user = ref.read(authProvider);
    final selection = await showDifficultySelector(
      context: context,
      gameType: gameType,
      maxUnlockedLevel: user.unlockedFor(gameType),
    );
    if (selection == null || !context.mounted) return;

    await _pushGameScreen(
      context: context,
      gameType: gameType,
      difficulty: selection.difficulty,
      isPractice: selection.isPractice,
    );
  }

  Future<void> _resumeGame(
    BuildContext context,
    AutoSaveSlot slot,
  ) async {
    await _pushGameScreen(
      context: context,
      gameType: slot.gameType,
      difficulty: DifficultyLevel.fromLevel(slot.difficulty),
      resumeSlot: slot,
    );
  }

  Future<void> _pushGameScreen({
    required BuildContext context,
    required GameType gameType,
    required DifficultyLevel difficulty,
    bool isPractice = false,
    AutoSaveSlot? resumeSlot,
  }) {
    final Widget screen = switch (gameType) {
      GameType.sudoku => SudokuScreen(
        difficulty: difficulty,
        isPractice: isPractice,
        resumeSlot: resumeSlot,
      ),
      GameType.chess => ChessScreen(
        difficulty: difficulty,
        isPractice: isPractice,
        resumeSlot: resumeSlot,
      ),
      GameType.minesweeper => MinesweeperScreen(
        difficulty: difficulty,
        isPractice: isPractice,
        resumeSlot: resumeSlot,
      ),
      GameType.snake => SnakeScreen(
        difficulty: difficulty,
        isPractice: isPractice,
        resumeSlot: resumeSlot,
      ),
    };

    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider);
    final slots = ref.watch(autoSaveSlotsProvider);
    final pendingQueue = ref.watch(pendingQueueCountProvider).value ?? 0;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              AssetPaths.appIcon,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.appTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  l10n.homeSubtitle,
                                  style: TextStyle(
                                    color: p.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: p.surfaceElevated,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: p.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  user.isGuest
                                      ? Icons.offline_bolt_rounded
                                      : Icons.verified_user_rounded,
                                  size: 16,
                                  color: user.isGuest ? p.warning : p.accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  user.isGuest
                                      ? l10n.profileGuest
                                      : '@${user.username}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (user.isGuest || pendingQueue > 0) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (user.isGuest)
                              _InfoPill(
                                icon: Icons.cloud_off_rounded,
                                text: l10n.guestModeBanner,
                                color: p.textSecondary,
                              ),
                            if (pendingQueue > 0)
                              _InfoPill(
                                icon: Icons.sync_rounded,
                                text: l10n.syncQueuePending(pendingQueue),
                                color: p.warning,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 500,
                    mainAxisExtent: 236,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate((context, idx) {
                    final game = GameType.values[idx];
                    final slot = slots[game];
                    return _GameBentoCard(
                      game: game,
                      slot: slot,
                      unlockedLevel: user.unlockedFor(game),
                      onNewGame: () => _launchNewGame(context, ref, game),
                      onContinue: slot != null
                          ? () => _resumeGame(context, slot)
                          : null,
                    );
                  }, childCount: GameType.values.length),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

class _GameBentoCard extends StatelessWidget {
  const _GameBentoCard({
    required this.game,
    required this.slot,
    required this.unlockedLevel,
    required this.onNewGame,
    this.onContinue,
  });

  final GameType game;
  final AutoSaveSlot? slot;
  final int unlockedLevel;
  final VoidCallback onNewGame;
  final VoidCallback? onContinue;

  Widget _gamePreviewIcon(ZetzyPalette p) => switch (game) {
    GameType.sudoku => Icon(Icons.grid_on_rounded, size: 32, color: p.accent),
    GameType.chess => Icon(Icons.castle_rounded, size: 32, color: p.accentSecondary),
    GameType.minesweeper => Image.asset(
      AssetPaths.mineNormal,
      width: 32,
      height: 32,
    ),
    GameType.snake => Image.asset(
      AssetPaths.snakeApple,
      width: 32,
      height: 32,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;

    return TactileCard(
      onTap: onNewGame,
      glowColor: p.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border),
                ),
                child: _gamePreviewIcon(p),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.localizedTitle(l10n),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Unlocked: Lv. 1–$unlockedLevel',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: p.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              game.localizedSubtitle(l10n),
              style: TextStyle(color: p.textSecondary, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              if (onContinue != null && slot != null) ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text(
                      '${l10n.continueGame} (${TimeFormatter.formatMs(slot!.elapsedMs)})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onNewGame,
                  child: Text(l10n.newGame),
                ),
              ] else
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onNewGame,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text(l10n.play),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
