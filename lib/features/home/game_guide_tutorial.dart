import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/core/widgets/game_type_icon.dart';
import 'package:zetzy/features/home/game_interactive_tutorial.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

/// Opens the slideable visual guide modal for [game].
/// From any slide, the user can either close the guide or launch the
/// pause-and-explain interactive tutorial.
Future<void> showGameGuideModal(
  BuildContext context, {
  required GameType game,
  required VoidCallback onStartRealGame,
}) => showDialog<void>(
  context: context,
  barrierDismissible: true,
  builder: (_) => _GameGuideDialog(
    game: game,
    onStartTutorial: () {
      Navigator.of(context).pop();
      showGameInteractiveTutorial(
        context,
        game: game,
        onStartRealGame: onStartRealGame,
      );
    },
  ),
);

/// Opens the full-screen interactive tutorial that mirrors the in-game layout
/// (board + real controls), pausing to explain each step before the player
/// performs it on the blinking target.
Future<void> showGameInteractiveTutorial(
  BuildContext context, {
  required GameType game,
  required VoidCallback onStartRealGame,
}) => Navigator.of(context).push<void>(
  MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => GameInteractiveTutorialScreen(
      game: game,
      onStartRealGame: onStartRealGame,
    ),
  ),
);

class _GuideSlideData {
  const _GuideSlideData({
    required this.badge,
    required this.title,
    required this.description,
    required this.bullets,
    required this.visualBuilder,
  });

  final String badge;
  final String title;
  final String description;
  final List<String> bullets;
  final Widget Function(ZetzyPalette p, AppLocalizations l10n) visualBuilder;
}

class _GameGuideDialog extends ConsumerStatefulWidget {
  const _GameGuideDialog({
    required this.game,
    required this.onStartTutorial,
  });

  final GameType game;
  final VoidCallback onStartTutorial;

  @override
  ConsumerState<_GameGuideDialog> createState() => _GameGuideDialogState();
}

class _GameGuideDialogState extends ConsumerState<_GameGuideDialog> {
  final PageController _pageCtrl = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  List<_GuideSlideData> _slides(
    AppLocalizations l10n,
    ChessPieceSet pieceSet,
  ) => switch (widget.game) {
    GameType.sudoku => _sudokuSlides(l10n),
    GameType.minesweeper => _minesweeperSlides(l10n),
    GameType.chess => _chessSlides(l10n, pieceSet),
    GameType.snake => _snakeSlides(l10n),
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final pieceSet = ref.watch(settingsProvider).chessPieceSet;
    final slides = _slides(l10n, pieceSet);

    return Dialog(
      backgroundColor: p.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: p.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: p.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.border),
                    ),
                    child: GameTypeIcon(
                      game: widget.game,
                      size: 24,
                      color: p.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.guideDialogTitle(widget.game.localizedTitle(l10n)),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          l10n.guideDialogSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: p.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: p.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_pageIndex + 1} / ${slides.length}',
                      style: ZetzyThemes.monoStyle(
                        fontSize: 12,
                        color: p.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Slideable PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: slides.length,
                  onPageChanged: (idx) => setState(() => _pageIndex = idx),
                  itemBuilder: (context, idx) {
                    final s = slides[idx];
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 176,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: p.surfaceElevated,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: p.border),
                            ),
                            child: Center(child: s.visualBuilder(p, l10n)),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: p.accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s.badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: p.accent,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.description,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: p.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (final b in s.bullets)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 15,
                                    color: p.accent,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      b,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Page indicator dots + prev/next
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _pageIndex > 0
                        ? () => _pageCtrl.previousPage(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                          )
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded, size: 18),
                    label: Text(l10n.guidePrev),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < slides.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _pageIndex ? 18 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _pageIndex ? p.accent : p.border,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _pageIndex < slides.length - 1
                        ? () => _pageCtrl.nextPage(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                          )
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    label: Text(l10n.guideNext),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Primary actions: Exit Guide OR Start Interactive Tutorial
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('guide_close_btn'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 17),
                      label: Text(
                        l10n.guideClose,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('guide_start_tutorial_btn'),
                      onPressed: widget.onStartTutorial,
                      icon: const Icon(Icons.school_rounded, size: 17),
                      label: Text(
                        l10n.guideStartTutorial,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Visual Slide Definitions for All 4 Games ───────────────────────────────

List<_GuideSlideData> _sudokuSlides(AppLocalizations l10n) => [
  _GuideSlideData(
    badge: l10n.guideSudokuS1Badge,
    title: l10n.guideSudokuS1Title,
    description: l10n.guideSudokuS1Desc,
    bullets: l10n.guideSudokuS1Bullets.split('\n'),
    visualBuilder: (p, l10n) => _SudokuBoxVisual(palette: p, l10n: l10n),
  ),
  _GuideSlideData(
    badge: l10n.guideSudokuS2Badge,
    title: l10n.guideSudokuS2Title,
    description: l10n.guideSudokuS2Desc,
    bullets: l10n.guideSudokuS2Bullets.split('\n'),
    visualBuilder: (p, _) => _SudokuKeypadVisual(palette: p),
  ),
  _GuideSlideData(
    badge: l10n.guideSudokuS3Badge,
    title: l10n.guideSudokuS3Title,
    description: l10n.guideSudokuS3Desc,
    bullets: l10n.guideSudokuS3Bullets.split('\n'),
    visualBuilder: (p, l10n) => _SudokuNotesVisual(palette: p, l10n: l10n),
  ),
  _GuideSlideData(
    badge: l10n.guideSudokuS4Badge,
    title: l10n.guideSudokuS4Title,
    description: l10n.guideSudokuS4Desc,
    bullets: l10n.guideSudokuS4Bullets.split('\n'),
    visualBuilder: (p, l10n) => _SudokuHudVisual(palette: p, l10n: l10n),
  ),
];

List<_GuideSlideData> _minesweeperSlides(AppLocalizations l10n) => [
  _GuideSlideData(
    badge: l10n.guideMineS1Badge,
    title: l10n.guideMineS1Title,
    description: l10n.guideMineS1Desc,
    bullets: l10n.guideMineS1Bullets.split('\n'),
    visualBuilder: (p, l10n) => _MineNumberVisual(palette: p, l10n: l10n),
  ),
  _GuideSlideData(
    badge: l10n.guideMineS2Badge,
    title: l10n.guideMineS2Title,
    description: l10n.guideMineS2Desc,
    bullets: l10n.guideMineS2Bullets.split('\n'),
    visualBuilder: (p, l10n) => _MineFlagVisual(palette: p, l10n: l10n),
  ),
  _GuideSlideData(
    badge: l10n.guideMineS3Badge,
    title: l10n.guideMineS3Title,
    description: l10n.guideMineS3Desc,
    bullets: l10n.guideMineS3Bullets.split('\n'),
    visualBuilder: (p, _) => _MineChordVisual(palette: p),
  ),
  _GuideSlideData(
    badge: l10n.guideMineS4Badge,
    title: l10n.guideMineS4Title,
    description: l10n.guideMineS4Desc,
    bullets: l10n.guideMineS4Bullets.split('\n'),
    visualBuilder: (p, l10n) => _MineShieldVisual(palette: p, l10n: l10n),
  ),
];

List<_GuideSlideData> _chessSlides(
  AppLocalizations l10n,
  ChessPieceSet pieceSet,
) => [
  _GuideSlideData(
    badge: l10n.guideChessS1Badge,
    title: l10n.guideChessS1Title,
    description: l10n.guideChessS1Desc,
    bullets: l10n.guideChessS1Bullets.split('\n'),
    visualBuilder: (p, _) =>
        _ChessPiecesVisual(palette: p, pieceSet: pieceSet),
  ),
  _GuideSlideData(
    badge: l10n.guideChessS2Badge,
    title: l10n.guideChessS2Title,
    description: l10n.guideChessS2Desc,
    bullets: l10n.guideChessS2Bullets.split('\n'),
    visualBuilder: (p, l10n) =>
        _ChessCheckVisual(palette: p, l10n: l10n, pieceSet: pieceSet),
  ),
  _GuideSlideData(
    badge: l10n.guideChessS3Badge,
    title: l10n.guideChessS3Title,
    description: l10n.guideChessS3Desc,
    bullets: l10n.guideChessS3Bullets.split('\n'),
    visualBuilder: (p, l10n) =>
        _ChessCastlingVisual(palette: p, l10n: l10n, pieceSet: pieceSet),
  ),
  _GuideSlideData(
    badge: l10n.guideChessS4Badge,
    title: l10n.guideChessS4Title,
    description: l10n.guideChessS4Desc,
    bullets: l10n.guideChessS4Bullets.split('\n'),
    visualBuilder: (p, l10n) =>
        _ChessSpecialPawnVisual(palette: p, l10n: l10n, pieceSet: pieceSet),
  ),
  _GuideSlideData(
    badge: l10n.guideChessS5Badge,
    title: l10n.guideChessS5Title,
    description: l10n.guideChessS5Desc,
    bullets: l10n.guideChessS5Bullets.split('\n'),
    visualBuilder: (p, _) => _ChessHudVisual(palette: p),
  ),
];

List<_GuideSlideData> _snakeSlides(AppLocalizations l10n) => [
  _GuideSlideData(
    badge: l10n.guideSnakeS1Badge,
    title: l10n.guideSnakeS1Title,
    description: l10n.guideSnakeS1Desc,
    bullets: l10n.guideSnakeS1Bullets.split('\n'),
    visualBuilder: (p, _) => _SnakeControlVisual(palette: p),
  ),
  _GuideSlideData(
    badge: l10n.guideSnakeS2Badge,
    title: l10n.guideSnakeS2Title,
    description: l10n.guideSnakeS2Desc,
    bullets: l10n.guideSnakeS2Bullets.split('\n'),
    visualBuilder: (p, l10n) => _SnakeItemsVisual(palette: p, l10n: l10n),
  ),
  _GuideSlideData(
    badge: l10n.guideSnakeS3Badge,
    title: l10n.guideSnakeS3Title,
    description: l10n.guideSnakeS3Desc,
    bullets: l10n.guideSnakeS3Bullets.split('\n'),
    visualBuilder: (p, l10n) => _SnakeWallVisual(palette: p, l10n: l10n),
  ),
  _GuideSlideData(
    badge: l10n.guideSnakeS4Badge,
    title: l10n.guideSnakeS4Title,
    description: l10n.guideSnakeS4Desc,
    bullets: l10n.guideSnakeS4Bullets.split('\n'),
    visualBuilder: (p, l10n) =>
        _SnakeStarvationVisual(palette: p, l10n: l10n),
  ),
];

// ── Compact Visual Illustration Widgets for Guide Slides ──────────────────

class _SudokuBoxVisual extends StatelessWidget {
  const _SudokuBoxVisual({required this.palette, required this.l10n});
  final ZetzyPalette palette;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    const nums = ['1', '2', '3', '4', '?', '6', '7', '8', '9'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 126,
          height: 126,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 9,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (_, i) {
              final isTarget = nums[i] == '?';
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isTarget
                      ? palette.accent.withValues(alpha: 0.25)
                      : palette.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isTarget ? palette.accent : palette.border,
                    width: isTarget ? 2 : 1,
                  ),
                ),
                child: Text(
                  isTarget ? '5' : nums[i],
                  style: ZetzyThemes.monoStyle(
                    fontSize: 16,
                    color: isTarget ? palette.accent : palette.textPrimary,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MiniBadge(
                palette: palette,
                icon: Icons.check_rounded,
                text: '1 2 3 4 [5] 6 7 8 9',
              ),
              const SizedBox(height: 8),
              Text(
                l10n.guideSudokuS1VisualCaption,
                style: TextStyle(fontSize: 12, color: palette.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SudokuKeypadVisual extends StatelessWidget {
  const _SudokuKeypadVisual({required this.palette});
  final ZetzyPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final d in ['7', ' ', '7'])
              Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: d == '7'
                      ? palette.accent.withValues(alpha: 0.22)
                      : palette.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.accent),
                ),
                child: Text(
                  d,
                  style: ZetzyThemes.monoStyle(
                    fontSize: 16,
                    color: palette.accent,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Icon(Icons.arrow_upward_rounded, size: 18, color: palette.accent),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: [
            for (var n = 1; n <= 9; n++)
              Container(
                width: 28,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: n == 7 ? palette.accent : palette.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  '$n',
                  style: ZetzyThemes.monoStyle(
                    fontSize: 13,
                    color: n == 7 ? Colors.black : palette.textPrimary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SudokuNotesVisual extends StatelessWidget {
  const _SudokuNotesVisual({required this.palette, required this.l10n});
  final ZetzyPalette palette;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 78,
          height: 78,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.accent, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1', style: TextStyle(fontSize: 11, color: palette.accent)),
                  const Text(' ', style: TextStyle(fontSize: 11)),
                  Text('3', style: TextStyle(fontSize: 11, color: palette.accent)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(' ', style: TextStyle(fontSize: 11)),
                  Text('5', style: TextStyle(fontSize: 11, color: palette.accent)),
                  const Text(' ', style: TextStyle(fontSize: 11)),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Icon(Icons.arrow_forward_rounded, color: palette.accent),
        const SizedBox(width: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: palette.accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.accent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_note_rounded, color: palette.accent),
              const SizedBox(width: 6),
              Text(
                l10n.guideSudokuS3VisualBadge,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: palette.accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SudokuHudVisual extends StatelessWidget {
  const _SudokuHudVisual({required this.palette, required this.l10n});
  final ZetzyPalette palette;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  Icons.favorite_rounded,
                  color: Colors.redAccent,
                  size: 24,
                ),
              ),
            const SizedBox(width: 16),
            _MiniBadge(
              palette: palette,
              icon: Icons.lightbulb_outline_rounded,
              text: '${l10n.sudokuHint} 3/3',
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: palette.accent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt_rounded, size: 18, color: Colors.black),
              const SizedBox(width: 6),
              Text(
                l10n.guideSudokuS4VisualBadge,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MineNumberVisual extends StatelessWidget {
  const _MineNumberVisual({required this.palette, required this.l10n});
  final ZetzyPalette palette;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 118,
          height: 118,
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _mineTile(palette, ''),
              _mineTile(palette, ''),
              _mineTile(palette, 'mine'),
              _mineTile(palette, ''),
              _mineTile(palette, '1', highlight: true),
              _mineTile(palette, ''),
              _mineTile(palette, ''),
              _mineTile(palette, ''),
              _mineTile(palette, ''),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            l10n.guideMineS1VisualCaption,
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _MineFlagVisual extends StatelessWidget {
  const _MineFlagVisual({required this.palette, required this.l10n});
  final ZetzyPalette palette;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _mineTile(palette, '1', size: 48),
        const SizedBox(width: 10),
        Icon(Icons.arrow_forward_rounded, color: palette.accent),
        const SizedBox(width: 10),
        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: palette.accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.accent, width: 2),
          ),
          child: Image.asset(AssetPaths.mineFlag),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            l10n.guideMineS2VisualCaption,
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _MineChordVisual extends StatelessWidget {
  const _MineChordVisual({required this.palette});
  final ZetzyPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _mineTile(palette, 'flag', size: 44),
        const SizedBox(width: 6),
        _mineTile(palette, '1', size: 48, highlight: true),
        const SizedBox(width: 6),
        Icon(Icons.bolt_rounded, color: palette.accent, size: 26),
        const SizedBox(width: 6),
        _mineTile(palette, 'safe', size: 44),
      ],
    );
  }
}

class _MineShieldVisual extends StatelessWidget {
  const _MineShieldVisual({required this.palette, required this.l10n});
  final ZetzyPalette palette;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(AssetPaths.mineShield, width: 48, height: 48),
        const SizedBox(width: 12),
        Icon(Icons.arrow_forward_rounded, color: palette.accent),
        const SizedBox(width: 12),
        Image.asset(AssetPaths.mineDefused, width: 48, height: 48),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            l10n.guideMineS4VisualCaption,
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
        ),
      ],
    );
  }
}

Widget _mineTile(
  ZetzyPalette p,
  String kind, {
  double size = 34,
  bool highlight = false,
}) {
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: highlight ? p.accent.withValues(alpha: 0.22) : p.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: highlight ? p.accent : p.border,
        width: highlight ? 2 : 1,
      ),
    ),
    child: switch (kind) {
      'mine' => Padding(
        padding: const EdgeInsets.all(5),
        child: Image.asset(AssetPaths.mineNormal),
      ),
      'flag' => Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(AssetPaths.mineFlag),
      ),
      'safe' => Icon(Icons.check_circle_rounded, size: 20, color: p.accent),
      _ => Text(
        kind,
        style: ZetzyThemes.monoStyle(fontSize: 15, color: p.accent),
      ),
    },
  );
}

class _ChessPiecesVisual extends StatelessWidget {
  const _ChessPiecesVisual({required this.palette, required this.pieceSet});
  final ZetzyPalette palette;
  final ChessPieceSet pieceSet;

  @override
  Widget build(BuildContext context) {
    const pieces = [
      ('K', 'King'),
      ('Q', 'Queen'),
      ('R', 'Rook'),
      ('B', 'Bishop'),
      ('N', 'Knight'),
      ('P', 'Pawn'),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final item in pieces)
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  pieceSet.pieceAsset('w', item.$1),
                  width: 30,
                  height: 30,
                ),
                const SizedBox(height: 3),
                Text(
                  item.$2,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChessCheckVisual extends StatelessWidget {
  const _ChessCheckVisual({
    required this.palette,
    required this.l10n,
    required this.pieceSet,
  });
  final ZetzyPalette palette;
  final AppLocalizations l10n;
  final ChessPieceSet pieceSet;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _chessCard(
          palette,
          badge: l10n.guideChessS2Checkmate,
          badgeColor: palette.accent,
        ),
        _chessCard(
          palette,
          badge: l10n.guideChessS2Stalemate,
          badgeColor: palette.warning,
        ),
      ],
    );
  }

  Widget _chessCard(
    ZetzyPalette p, {
    required String badge,
    required Color badgeColor,
  }) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: p.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: badgeColor, width: 1.5),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          pieceSet.pieceAsset('b', 'K'),
          width: 38,
          height: 38,
        ),
        const SizedBox(height: 6),
        Text(
          badge,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: badgeColor,
          ),
        ),
      ],
    ),
  );
}

class _ChessCastlingVisual extends StatelessWidget {
  const _ChessCastlingVisual({
    required this.palette,
    required this.l10n,
    required this.pieceSet,
  });
  final ZetzyPalette palette;
  final AppLocalizations l10n;
  final ChessPieceSet pieceSet;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _squarePiece(palette, pieceSet, 'wK', 'e1'),
            _squarePiece(palette, pieceSet, null, 'f1'),
            _squarePiece(palette, pieceSet, null, 'g1', highlight: true),
            _squarePiece(palette, pieceSet, 'wR', 'h1'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.guideChessS3VisualCaption,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: palette.accent,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ChessSpecialPawnVisual extends StatelessWidget {
  const _ChessSpecialPawnVisual({
    required this.palette,
    required this.l10n,
    required this.pieceSet,
  });
  final ZetzyPalette palette;
  final AppLocalizations l10n;
  final ChessPieceSet pieceSet;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                _squarePiece(palette, pieceSet, 'bP', 'd5'),
                _squarePiece(palette, pieceSet, 'wP', 'e5', highlight: true),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'En Passant (↗ d6)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.accent,
              ),
            ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                _squarePiece(palette, pieceSet, 'wP', 'a7'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_forward_rounded, color: palette.accent),
                ),
                _squarePiece(palette, pieceSet, 'wQ', 'a8', highlight: true),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.guideChessS4VisualPromo,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChessHudVisual extends StatelessWidget {
  const _ChessHudVisual({required this.palette});
  final ZetzyPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _MiniBadge(
          palette: palette,
          icon: Icons.touch_app_rounded,
          text: 'Confirm Move: e2 → e4',
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final ic in [
              Icons.first_page_rounded,
              Icons.chevron_left_rounded,
              Icons.chevron_right_rounded,
              Icons.last_page_rounded,
            ])
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.border),
                ),
                child: Icon(ic, size: 18, color: palette.accent),
              ),
          ],
        ),
      ],
    );
  }
}

Widget _squarePiece(
  ZetzyPalette p,
  ChessPieceSet pieceSet,
  String? piece,
  String coord, {
  bool highlight = false,
}) => Container(
  width: 44,
  height: 48,
  margin: const EdgeInsets.symmetric(horizontal: 2),
  decoration: BoxDecoration(
    color: highlight ? p.accent.withValues(alpha: 0.22) : p.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: highlight ? p.accent : p.border,
      width: highlight ? 2 : 1,
    ),
  ),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (piece != null)
        SvgPicture.asset(
          pieceSet.pieceAsset(piece[0], piece[1]),
          width: 24,
          height: 24,
        )
      else
        Icon(Icons.circle, size: 8, color: p.accent),
      Text(coord, style: TextStyle(fontSize: 9, color: p.textSecondary)),
    ],
  ),
);

class _SnakeControlVisual extends StatelessWidget {
  const _SnakeControlVisual({required this.palette});
  final ZetzyPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: i == 2 ? palette.accent : palette.accent.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        Icon(Icons.subdirectory_arrow_right_rounded, color: palette.accent),
        const SizedBox(width: 8),
        Image.asset(AssetPaths.snakeApple, width: 32, height: 32),
      ],
    );
  }
}

class _SnakeItemsVisual extends StatelessWidget {
  const _SnakeItemsVisual({required this.palette, required this.l10n});
  final ZetzyPalette palette;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final items = [
      (AssetPaths.snakeApple, '+10'),
      (AssetPaths.snakeGolden, '+30'),
      (AssetPaths.snakeScissors, l10n.guideSnakeS2Trim),
      (AssetPaths.snakePoison, l10n.guideSnakeS2Hazard),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final item in items)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border),
                ),
                child: Image.asset(item.$1, width: 32, height: 32),
              ),
              const SizedBox(height: 6),
              Text(
                item.$2,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _SnakeWallVisual extends StatelessWidget {
  const _SnakeWallVisual({required this.palette, required this.l10n});
  final ZetzyPalette palette;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(AssetPaths.snakeWall, width: 42, height: 42),
        const SizedBox(width: 8),
        Image.asset(AssetPaths.snakeWall, width: 42, height: 42),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            l10n.guideSnakeS3VisualCaption,
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _SnakeStarvationVisual extends StatelessWidget {
  const _SnakeStarvationVisual({required this.palette, required this.l10n});
  final ZetzyPalette palette;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AssetPaths.snakeApple, width: 24, height: 24),
            const SizedBox(width: 8),
            Text(
              l10n.guideSnakeS4VisualCaption,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: 0.65,
            minHeight: 12,
            backgroundColor: palette.surface,
            color: palette.warning,
          ),
        ),
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.palette,
    required this.icon,
    required this.text,
  });
  final ZetzyPalette palette;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: palette.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: palette.accent),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: palette.accent),
        const SizedBox(width: 6),
        Text(
          text,
          style: ZetzyThemes.monoStyle(fontSize: 11.5, color: palette.accent),
        ),
      ],
    ),
  );
}
