import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/core/widgets/game_type_icon.dart';
import 'package:zetzy/data/local/settings_repository.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

/// Shared builders for per-game settings controls used in both Profile cards and
/// the mid-game quick settings sheet.
abstract final class GameSettingsControls {
  /// Builds shared audio, haptics, and wakelock toggles.
  static List<Widget> sharedAudioFeedback(
    AppSettings settings,
    SettingsNotifier ctrl,
    ZetzyPalette p,
    AppLocalizations l10n, {
    required bool hasAudio,
    bool includeBgm = true,
  }) => [
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: settings.sfxEnabled,
      onChanged: ctrl.setSfx,
      title: Text(l10n.settingsAudioSfx),
      subtitle: hasAudio
          ? null
          : Text(
              l10n.settingsAudioPending,
              style: TextStyle(fontSize: 11, color: p.textSecondary),
            ),
    ),
    if (includeBgm)
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: settings.bgmEnabled,
        onChanged: ctrl.setBgm,
        title: Text(l10n.settingsAudioBgm),
      ),
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: settings.hapticsEnabled,
      onChanged: ctrl.setHaptics,
      title: Text(l10n.settingsHaptics),
    ),
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: settings.wakelockEnabled,
      onChanged: ctrl.setWakelock,
      title: Text(l10n.settingsWakelock),
    ),
  ];

  /// Builds live-safe Sudoku controls (Auto-Finish, threshold, highlight, notes).
  static List<Widget> sudoku(
    AppSettings settings,
    SettingsNotifier ctrl,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) => [
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: settings.sudokuAutoFinish,
      onChanged: ctrl.setSudokuAutoFinish,
      title: Text(l10n.settingsSudokuAutoFinish),
      subtitle: Text(
        l10n.settingsSudokuAutoFinishDesc,
        style: TextStyle(fontSize: 12, color: p.textSecondary),
      ),
    ),
    if (settings.sudokuAutoFinish) ...[
      const SizedBox(height: 4),
      Text(
        l10n.settingsSudokuAutoFinishThreshold,
        style: TextStyle(fontSize: 12, color: p.textSecondary),
      ),
      const SizedBox(height: 8),
      SegmentedButton<int>(
        selected: {settings.sudokuAutoFinishThreshold},
        onSelectionChanged: (sel) => ctrl.setSudokuAutoFinishThreshold(sel.first),
        segments: [
          for (final count in const [5, 7])
            ButtonSegment(
              value: count,
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  l10n.sudokuRemainingCellsOption(count),
                  softWrap: false,
                  maxLines: 1,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
    ],
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: settings.sudokuHighlightSameDigits,
      onChanged: ctrl.setSudokuHighlightSameDigits,
      title: Text(l10n.settingsSudokuHighlightSame),
    ),
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: settings.sudokuAutoClearNotes,
      onChanged: ctrl.setSudokuAutoClearNotes,
      title: Text(l10n.settingsSudokuAutoClearNotes),
    ),
  ];

  /// Builds live-safe Chess controls (piece style, Auto-Queen, move hints, coordinates).
  static List<Widget> chess(
    AppSettings settings,
    SettingsNotifier ctrl,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) => [
    Text(
      l10n.settingsChessPieces,
      style: TextStyle(fontSize: 12, color: p.textSecondary),
    ),
    const SizedBox(height: 8),
    Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final set in ChessPieceSet.values)
          ChoiceChip(
            selected: settings.chessPieceSet == set,
            onSelected: (_) => ctrl.setChessPieceSet(set),
            label: Text(set.label),
          ),
      ],
    ),
    const SizedBox(height: 6),
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: settings.chessAutoQueen,
      onChanged: ctrl.setChessAutoQueen,
      title: Text(l10n.settingsChessAutoQueen),
    ),
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: settings.chessShowLegalMoves,
      onChanged: ctrl.setChessShowLegalMoves,
      title: Text(l10n.settingsChessLegalMoves),
    ),
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: settings.chessShowCoordinates,
      onChanged: ctrl.setChessShowCoordinates,
      title: Text(l10n.settingsChessCoordinates),
    ),
  ];

  /// Builds live-safe Minesweeper controls (Quick Chord on revealed numbers).
  static List<Widget> minesweeper(
    AppSettings settings,
    SettingsNotifier ctrl,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) => [
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: settings.minesweeperQuickChord,
      onChanged: ctrl.setMinesweeperQuickChord,
      title: Text(l10n.settingsMinesweeperQuickChord),
      subtitle: Text(
        l10n.settingsMinesweeperQuickChordDesc,
        style: TextStyle(fontSize: 12, color: p.textSecondary),
      ),
    ),
  ];

  /// Builds live-safe Snake controls (touch layout and arena grid overlay).
  static List<Widget> snake(
    AppSettings settings,
    SettingsNotifier ctrl,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) => [
    Text(
      l10n.settingsSnakeControl,
      style: TextStyle(fontSize: 12, color: p.textSecondary),
    ),
    const SizedBox(height: 8),
    SegmentedButton<SnakeControlMode>(
      selected: {settings.snakeControlMode},
      onSelectionChanged: (sel) => ctrl.setSnakeControl(sel.first),
      segments: [
        ButtonSegment(
          value: SnakeControlMode.swipe,
          label: Text(l10n.settingsSnakeSwipe),
        ),
        ButtonSegment(
          value: SnakeControlMode.dpad,
          label: Text(l10n.settingsSnakeDpad),
        ),
        ButtonSegment(
          value: SnakeControlMode.splitTap,
          label: Text(l10n.settingsSnakeSplit),
        ),
      ],
    ),
    const SizedBox(height: 6),
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: settings.snakeShowGridLines,
      onChanged: ctrl.setSnakeShowGridLines,
      title: Text(l10n.settingsSnakeGridLines),
    ),
  ];
}

/// Opens a mid-game modal bottom sheet containing only settings that can be
/// applied safely during an active session for [gameType].
Future<void> showInGameSettingsSheet({
  required BuildContext context,
  required GameType gameType,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _InGameSettingsSheet(gameType: gameType),
  );
}

class _InGameSettingsSheet extends ConsumerWidget {
  const _InGameSettingsSheet({required this.gameType});

  final GameType gameType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final hasAudio = ref.watch(audioServiceProvider).hasAudioAssets;

    final gameControls = switch (gameType) {
      GameType.sudoku => GameSettingsControls.sudoku(settings, ctrl, p, l10n),
      GameType.chess => GameSettingsControls.chess(settings, ctrl, p, l10n),
      GameType.minesweeper => GameSettingsControls.minesweeper(
        settings,
        ctrl,
        p,
        l10n,
      ),
      GameType.snake => GameSettingsControls.snake(settings, ctrl, p, l10n),
    };

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: Material(
          color: p.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            side: BorderSide(color: p.border, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: p.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: GameTypeIcon(
                        game: gameType,
                        size: 20,
                        color: p.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.settingsInGameTitle} • ${gameType.localizedTitle(l10n)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            l10n.settingsInGameSubtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: p.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...gameControls,
                      const Divider(height: 22),
                      Text(
                        l10n.settingsTheme,
                        style: TextStyle(fontSize: 12, color: p.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final mode in ZetzyThemeMode.values)
                            ChoiceChip(
                              selected: settings.themeMode == mode,
                              onSelected: (_) => ctrl.setTheme(mode),
                              label: Text(mode.localizedName(l10n)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...GameSettingsControls.sharedAudioFeedback(
                        settings,
                        ctrl,
                        p,
                        l10n,
                        hasAudio: hasAudio,
                        includeBgm: false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
