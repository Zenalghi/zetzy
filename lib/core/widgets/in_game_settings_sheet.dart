import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/services/audio_service.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/core/widgets/game_type_icon.dart';
import 'package:zetzy/data/local/settings_repository.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

/// Shared builders for per-game settings controls used in both Profile cards and
/// the mid-game quick settings sheet.
abstract final class GameSettingsControls {
  /// Single-line scale-down label so equal-width segments stay crisp on narrow screens.
  static Widget segmentLabel(String label) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(label, softWrap: false, maxLines: 1),
  );

  /// Renders an inline setting row with a wrapping label on the left and a
  /// right-aligned equal-width [SegmentedButton] that never overflows narrow screens.
  static Widget inlineSegmentedRow<T extends Object>({
    required String label,
    TextStyle? labelStyle,
    required T selected,
    required ValueChanged<T> onSelected,
    required List<(T value, String text)> options,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final selectorWidth = (constraints.maxWidth * 0.56).clamp(140.0, 230.0);
      return Row(
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          const SizedBox(width: 12),
          SizedBox(
            width: selectorWidth,
            child: SegmentedButton<T>(
              expandedInsets: EdgeInsets.zero,
              selected: {selected},
              onSelectionChanged: (sel) => onSelected(sel.first),
              segments: [
                for (final (value, text) in options)
                  ButtonSegment(value: value, label: segmentLabel(text)),
              ],
            ),
          ),
        ],
      );
    },
  );

  /// Renders the 6-skin theme selector in a balanced 2×3 expanded grid.
  static Widget themePicker({
    required ZetzyThemeMode selected,
    required ValueChanged<ZetzyThemeMode> onSelected,
    required AppLocalizations l10n,
    bool abyssalAlterEgo = false,
  }) => Builder(
    builder: (context) {
      final p = context.palette;
      const modes = ZetzyThemeMode.values;
      return Column(
        children: [
          for (var i = 0; i < modes.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ThemeOptionButton(
                    mode: modes[i],
                    selected: selected == modes[i],
                    useAlterEgo:
                        modes[i] == ZetzyThemeMode.abyssalCyan &&
                        abyssalAlterEgo,
                    palette: p,
                    l10n: l10n,
                    onTap: () => onSelected(modes[i]),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: i + 1 < modes.length
                      ? _ThemeOptionButton(
                          mode: modes[i + 1],
                          selected: selected == modes[i + 1],
                          useAlterEgo:
                              modes[i + 1] == ZetzyThemeMode.abyssalCyan &&
                              abyssalAlterEgo,
                          palette: p,
                          l10n: l10n,
                          onTap: () => onSelected(modes[i + 1]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ],
      );
    },
  );

  static Widget _buildBgmTrackChips({
    required List<String> trackFilenames,
    required String favoriteTrack,
    required String? selectedTrack,
    required bool isFavoritePicker,
    required ValueChanged<String> onSelected,
    required ZetzyPalette p,
    required AppLocalizations l10n,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      const spacing = 8.0;
      const columns = 3;
      final itemWidth =
          ((constraints.maxWidth - spacing * (columns - 1)) / columns)
              .clamp(84.0, 220.0);
      return SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: spacing,
          runSpacing: 6,
          children: [
            for (final fileName in trackFilenames)
              Builder(
                builder: (_) {
                  final isFav = AudioService.isFavoriteBgm(
                    fileName,
                    favoriteTrack,
                  );
                  final isSelected = isFavoritePicker
                      ? isFav
                      : AudioService.trackMatches(
                          fileName,
                          selectedTrack ?? '',
                        );
                  final trackNum =
                      int.tryParse(AudioService.trackDisplayNumber(fileName)) ??
                      1;
                  return SizedBox(
                    width: itemWidth,
                    child: ChoiceChip(
                      selected: isSelected,
                      onSelected: (_) => onSelected(fileName),
                      avatar: isFavoritePicker
                          ? Icon(
                              isFav
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 15,
                              color: isFav ? p.accent : p.textSecondary,
                            )
                          : (isFav
                                ? Icon(
                                    Icons.star_rounded,
                                    size: 15,
                                    color: p.accent,
                                  )
                                : null),
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(
                          l10n.bgmTrackLabel(trackNum),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    },
  );

  /// Builds shared audio, haptics, and wakelock toggles.
  static List<Widget> sharedAudioFeedback(
    AppSettings settings,
    SettingsNotifier ctrl,
    ZetzyPalette p,
    AppLocalizations l10n, {
    required bool hasAudio,
    AudioService? audioService,
    bool includeBgm = true,
  }) {
    final trackFilenames = (audioService != null &&
            audioService.bgmTracks.isNotEmpty)
        ? audioService.bgmTracks
            .map((path) => path.split('/').last)
            .toList(growable: false)
        : const <String>[
            '1.mp3',
            '2.mp3',
            '3.mp3',
            '4.mp3',
            '5.mp3',
            '6.mp3',
            '7.mp3',
            '8.mp3',
            '9.mp3',
          ];

    return [
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
      if (includeBgm) ...[
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.music_note_rounded,
              size: 18,
              color: settings.bgmMode == BgmMode.off
                  ? p.textSecondary
                  : p.accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.settingsAudioBgm,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (settings.bgmMode != BgmMode.off)
              _buildActiveBgmPill(settings, audioService, p, l10n),
          ],
        ),
        const SizedBox(height: 8),
        SegmentedButton<BgmMode>(
          expandedInsets: EdgeInsets.zero,
          selected: {settings.bgmMode},
          onSelectionChanged: (sel) => ctrl.setBgmMode(sel.first),
          segments: [
            ButtonSegment(
              value: BgmMode.off,
              label: segmentLabel(l10n.bgmModeOff),
            ),
            ButtonSegment(
              value: BgmMode.auto,
              label: segmentLabel(l10n.bgmModeAuto),
            ),
            ButtonSegment(
              value: BgmMode.manual,
              label: segmentLabel(l10n.bgmModeManual),
            ),
          ],
        ),
        if (settings.bgmMode == BgmMode.auto) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.bgmAutoDesc(
                    int.tryParse(
                          AudioService.trackDisplayNumber(
                            settings.favoriteBgmTrack,
                          ),
                        ) ??
                        5,
                  ),
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
              ),
              if (audioService != null && audioService.bgmTracks.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton.outlined(
                  visualDensity: VisualDensity.compact,
                  tooltip: l10n.bgmNextTrack,
                  onPressed: ctrl.skipNextBgm,
                  icon: const Icon(Icons.skip_next_rounded, size: 18),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.bgmFavoriteTrackLabel,
            style: TextStyle(fontSize: 12, color: p.textSecondary),
          ),
          const SizedBox(height: 6),
          _buildBgmTrackChips(
            trackFilenames: trackFilenames,
            favoriteTrack: settings.favoriteBgmTrack,
            selectedTrack: null,
            isFavoritePicker: true,
            onSelected: ctrl.setFavoriteBgmTrack,
            p: p,
            l10n: l10n,
          ),
        ] else if (settings.bgmMode == BgmMode.manual) ...[
          const SizedBox(height: 10),
          _buildBgmTrackChips(
            trackFilenames: trackFilenames,
            favoriteTrack: settings.favoriteBgmTrack,
            selectedTrack: settings.bgmTrack,
            isFavoritePicker: false,
            onSelected: ctrl.setBgmTrack,
            p: p,
            l10n: l10n,
          ),
        ],
        const SizedBox(height: 8),
      ],
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: settings.hapticsEnabled,
        onChanged: ctrl.setHaptics,
        title: Text(l10n.settingsHaptics),
      ),
      if (settings.hapticsEnabled) ...[
        const SizedBox(height: 2),
        Text(
          l10n.settingsHapticIntensity,
          style: TextStyle(fontSize: 12, color: p.textSecondary),
        ),
        const SizedBox(height: 8),
        SegmentedButton<HapticIntensity>(
          expandedInsets: EdgeInsets.zero,
          selected: {settings.hapticIntensity},
          onSelectionChanged: (sel) => ctrl.setHapticIntensity(sel.first),
          segments: [
            ButtonSegment(
              value: HapticIntensity.light,
              label: segmentLabel(l10n.hapticLight),
            ),
            ButtonSegment(
              value: HapticIntensity.medium,
              label: segmentLabel(l10n.hapticMedium),
            ),
            ButtonSegment(
              value: HapticIntensity.strong,
              label: segmentLabel(l10n.hapticStrong),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: settings.wakelockEnabled,
        onChanged: ctrl.setWakelock,
        title: Text(l10n.settingsWakelock),
      ),
    ];
  }

  static Widget _buildActiveBgmPill(
    AppSettings settings,
    AudioService? audioService,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) {
    Widget badgeFor(String? assetPath) {
      final raw = assetPath ??
          (settings.bgmMode == BgmMode.manual ? settings.bgmTrack : null);
      if (raw == null) return const SizedBox.shrink();
      final numVal = int.tryParse(AudioService.trackDisplayNumber(raw));
      if (numVal == null) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: p.accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: p.accent.withValues(alpha: 0.35)),
        ),
        child: Text(
          l10n.bgmNowPlaying(numVal),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: p.accent,
          ),
        ),
      );
    }

    if (audioService == null) {
      return badgeFor(null);
    }
    return ValueListenableBuilder<String?>(
      valueListenable: audioService.currentBgmNotifier,
      builder: (context, activePath, _) => badgeFor(activePath),
    );
  }

  /// Builds live-safe Sudoku controls (Auto-Finish, threshold, highlight, notes).
  static List<Widget> sudoku(
    AppSettings settings,
    SettingsNotifier ctrl,
    ZetzyPalette p,
    AppLocalizations l10n, {
    bool smartNotesEligible = true,
  }) => [
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
      const SizedBox(height: 6),
      inlineSegmentedRow<int>(
        label: l10n.settingsSudokuAutoFinishThreshold,
        labelStyle: TextStyle(fontSize: 13, color: p.textSecondary),
        selected: settings.sudokuAutoFinishThreshold,
        onSelected: ctrl.setSudokuAutoFinishThreshold,
        options: [
          for (final count in const [5, 7])
            (count, l10n.sudokuRemainingCellsOption(count)),
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
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: settings.sudokuShowStreakStats,
      onChanged: ctrl.setSudokuShowStreakStats,
      title: Text(l10n.settingsSudokuStreakStats),
      subtitle: Text(
        l10n.settingsSudokuStreakStatsDesc,
        style: TextStyle(fontSize: 12, color: p.textSecondary),
      ),
    ),
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: settings.sudokuSmartCandidateNotes,
      onChanged:
          smartNotesEligible ? ctrl.setSudokuSmartCandidateNotes : null,
      title: Text(l10n.settingsSudokuSmartNotes),
      subtitle: Text(
        l10n.settingsSudokuSmartNotesDesc,
        style: TextStyle(fontSize: 12, color: p.textSecondary),
      ),
    ),
  ];

  /// Builds live-safe Chess controls (piece style, Auto-Queen, hints, coords, confirm).
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
    SegmentedButton<ChessPieceSet>(
      expandedInsets: EdgeInsets.zero,
      selected: {settings.chessPieceSet},
      onSelectionChanged: (sel) => ctrl.setChessPieceSet(sel.first),
      segments: [
        for (final set in ChessPieceSet.values)
          ButtonSegment(
            value: set,
            label: segmentLabel(set.label),
          ),
      ],
    ),
    const SizedBox(height: 10),
    Text(
      l10n.settingsChessMoveConfirm,
      style: TextStyle(fontSize: 12, color: p.textSecondary),
    ),
    const SizedBox(height: 8),
    SegmentedButton<ChessMoveConfirmMode>(
      expandedInsets: EdgeInsets.zero,
      selected: {settings.chessMoveConfirmMode},
      onSelectionChanged: (sel) => ctrl.setChessMoveConfirmMode(sel.first),
      segments: [
        ButtonSegment(
          value: ChessMoveConfirmMode.off,
          label: segmentLabel(l10n.settingsChessConfirmOff),
        ),
        ButtonSegment(
          value: ChessMoveConfirmMode.fastOnly,
          label: segmentLabel(l10n.settingsChessConfirmFast),
        ),
        ButtonSegment(
          value: ChessMoveConfirmMode.always,
          label: segmentLabel(l10n.settingsChessConfirmAlways),
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
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: settings.chessAutoFlipPassPlay,
      onChanged: ctrl.setChessAutoFlipPassPlay,
      title: Text(l10n.settingsChessAutoFlipPassPlay),
    ),
  ];

  /// Builds live-safe Minesweeper controls (Quick Chord, Swap Tap/Flag).
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
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: settings.minesweeperSwapTapFlag,
      onChanged: ctrl.setMinesweeperSwapTapFlag,
      title: Text(l10n.settingsMinesweeperSwapTapFlag),
      subtitle: Text(
        l10n.settingsMinesweeperSwapTapFlagDesc,
        style: TextStyle(fontSize: 12, color: p.textSecondary),
      ),
    ),
  ];

  /// Builds live-safe Snake controls (touch layout, grid overlay, assist overlay).
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
      expandedInsets: EdgeInsets.zero,
      selected: {settings.snakeControlMode},
      onSelectionChanged: (sel) => ctrl.setSnakeControl(sel.first),
      segments: [
        ButtonSegment(
          value: SnakeControlMode.swipe,
          label: segmentLabel(l10n.settingsSnakeSwipe),
        ),
        ButtonSegment(
          value: SnakeControlMode.dpad,
          label: segmentLabel(l10n.settingsSnakeDpad),
        ),
        ButtonSegment(
          value: SnakeControlMode.splitTap,
          label: segmentLabel(l10n.settingsSnakeSplit),
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
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: settings.snakeAssistOverlay,
      onChanged: ctrl.setSnakeAssistOverlay,
      title: Text(l10n.settingsSnakeAssistOverlay),
      subtitle: Text(
        l10n.settingsSnakeAssistOverlayDesc,
        style: TextStyle(fontSize: 12, color: p.textSecondary),
      ),
    ),
  ];
}

/// Opens a mid-game modal bottom sheet containing only settings that can be
/// applied safely during an active session for [gameType].
Future<void> showInGameSettingsSheet({
  required BuildContext context,
  required GameType gameType,
  bool sudokuSmartNotesEligible = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _InGameSettingsSheet(
      gameType: gameType,
      sudokuSmartNotesEligible: sudokuSmartNotesEligible,
    ),
  );
}

class _InGameSettingsSheet extends ConsumerWidget {
  const _InGameSettingsSheet({
    required this.gameType,
    this.sudokuSmartNotesEligible = true,
  });

  final GameType gameType;
  final bool sudokuSmartNotesEligible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final hasAudio = ref.watch(audioServiceProvider).hasAudioAssets;

    final gameControls = switch (gameType) {
      GameType.sudoku => GameSettingsControls.sudoku(
        settings,
        ctrl,
        p,
        l10n,
        smartNotesEligible: sudokuSmartNotesEligible,
      ),
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
                      GameSettingsControls.themePicker(
                        selected: settings.themeMode,
                        onSelected: ctrl.setTheme,
                        l10n: l10n,
                        abyssalAlterEgo: settings.abyssalCyanAlterEgo,
                      ),
                      const SizedBox(height: 8),
                      ...GameSettingsControls.sharedAudioFeedback(
                        settings,
                        ctrl,
                        p,
                        l10n,
                        hasAudio: hasAudio,
                        audioService: ref.watch(audioServiceProvider),
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

class _ThemeOptionButton extends StatelessWidget {
  const _ThemeOptionButton({
    required this.mode,
    required this.selected,
    required this.useAlterEgo,
    required this.palette,
    required this.l10n,
    required this.onTap,
  });

  final ZetzyThemeMode mode;
  final bool selected;
  final bool useAlterEgo;
  final ZetzyPalette palette;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final swatch = ZetzyThemes.paletteFor(mode, abyssalAlterEgo: useAlterEgo);
    final br = BorderRadius.circular(12);
    return Material(
      color: selected
          ? palette.accent.withValues(alpha: 0.16)
          : palette.surfaceElevated.withValues(alpha: 0.65),
      shape: RoundedRectangleBorder(
        borderRadius: br,
        side: BorderSide(
          color: selected ? palette.accent : palette.border,
          width: selected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: br,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [swatch.background, swatch.surfaceElevated],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: swatch.accent, width: 2.0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    mode.localizedName(l10n),
                    softWrap: false,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? palette.accent : palette.textPrimary,
                    ),
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 4),
                Icon(
                  useAlterEgo
                      ? Icons.auto_awesome_rounded
                      : Icons.check_rounded,
                  size: 15,
                  color: palette.accent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
