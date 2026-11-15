import 'package:bishop/bishop.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/core/utils/time_formatter.dart';
import 'package:zetzy/core/widgets/anti_cheat_pause_overlay.dart';
import 'package:zetzy/core/widgets/game_lifecycle_guard.dart';
import 'package:zetzy/core/widgets/game_timer_badge.dart';
import 'package:zetzy/core/widgets/tactile_card.dart';
import 'package:zetzy/core/widgets/win_result_dialog.dart';
import 'package:zetzy/data/models/auto_save_slot.dart';
import 'package:zetzy/features/games/chess/chess_ai.dart';
import 'package:zetzy/features/games/chess/chess_controller.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

class ChessScreen extends ConsumerStatefulWidget {
  const ChessScreen({
    super.key,
    required this.difficulty,
    this.isPractice = false,
    this.resumeSlot,
  });

  final DifficultyLevel difficulty;
  final bool isPractice;
  final AutoSaveSlot? resumeSlot;

  @override
  ConsumerState<ChessScreen> createState() => _ChessScreenState();
}

class _ChessScreenState extends ConsumerState<ChessScreen> {
  late final ChessController _controller;
  late final AutoSaveSlotsNotifier _autoSaveSlots;
  bool _inLobby = true;

  ChessPlayMode _selectedMode = ChessPlayMode.vsAi;
  ChessColorPref _selectedColor = ChessColorPref.white;
  ChessTimeControl _selectedTime = ChessTimeControl.blitz5;
  final TextEditingController _roomCodeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _autoSaveSlots = ref.read(autoSaveSlotsProvider.notifier);
    final settings = ref.read(settingsProvider);
    _controller = ChessController(
      audio: ref.read(audioServiceProvider),
      haptics: ref.read(hapticServiceProvider),
      supabase: ref.read(supabaseServiceProvider),
      autoQueen: settings.chessAutoQueen,
      onFinished: _handleGameFinished,
      onAutoSave: (slot) => _autoSaveSlots.saveSlot(slot),
    );

    if (widget.resumeSlot != null) {
      _inLobby = false;
      _controller.restoreFromSlot(widget.resumeSlot!);
    }
  }

  void _startMatch({String? joinRoomCode}) {
    setState(() => _inLobby = false);
    _controller.startNew(
      difficulty: widget.difficulty,
      isPractice: widget.isPractice,
      mode: _selectedMode,
      colorPref: joinRoomCode != null ? ChessColorPref.black : _selectedColor,
      timeControl: _selectedTime,
      roomCode: joinRoomCode,
      isHost: joinRoomCode == null,
    );
  }

  Future<void> _handleGameFinished(ChessUiState finalState) async {
    await ref.read(autoSaveSlotsProvider.notifier).clearSlot(GameType.chess);

    final playerWon =
        !finalState.isDraw && finalState.winnerColour == finalState.playerColor;
    var score = playerWon ? 100 : (finalState.isDraw ? 50 : 0);

    if (!finalState.isPractice &&
        finalState.mode != ChessPlayMode.passAndPlay) {
      final currentElo = ref.read(authProvider).chessElo;
      final opponentElo = finalState.mode == ChessPlayMode.vsAi
          ? ChessAiEngine.aiRatingForLevel(finalState.difficulty.level)
          : currentElo;
      final outcome = finalState.isDraw ? 0.5 : (playerWon ? 1.0 : 0.0);
      final newElo = ChessAiEngine.calculateNewElo(
        currentElo: currentElo,
        opponentElo: opponentElo,
        score: outcome,
      );
      score = newElo - currentElo;
      await ref.read(authProvider.notifier).updateChessElo(newElo);
    }

    final isNewRecord = await ref
        .read(scoreSyncControllerProvider)
        .recordGameResult(
          gameType: GameType.chess,
          difficulty: finalState.difficulty.level,
          isWon: playerWon,
          score: score,
          durationMs: finalState.elapsedMs,
          isPractice:
              finalState.isPractice ||
              finalState.mode == ChessPlayMode.passAndPlay,
          metadata: {
            'mode': finalState.mode.name,
            'pgn': _controller.game.pgn(),
            'moves': finalState.moveSans.length,
          },
        );

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.read(settingsProvider);
    final canRewind =
        finalState.isPractice &&
        !playerWon &&
        !finalState.isDraw &&
        settings.practiceRewindOnLoss &&
        finalState.canPracticeUndo;
    await showGameResultDialog(
      context: context,
      gameType: GameType.chess,
      difficulty: finalState.difficulty,
      isWon: playerWon,
      isDraw: finalState.isDraw,
      durationMs: finalState.elapsedMs,
      score: score,
      isNewRecord: isNewRecord,
      isPractice:
          finalState.isPractice || finalState.mode == ChessPlayMode.passAndPlay,
      extraMetrics: [
        (label: l10n.chessMoves, value: '${finalState.moveSans.length}'),
      ],
      rewindSteps: settings.practiceRewindSteps,
      onRewindContinue: canRewind
          ? () => _controller.practiceRewind(settings.practiceRewindSteps)
          : null,
      onPlayAgain: () => setState(() => _inLobby = true),
      onExit: () => Navigator.of(context).pop(),
    );
  }

  @override
  void dispose() {
    if (!_inLobby &&
        !_controller.state.isGameOver &&
        _controller.state.mode != ChessPlayMode.online) {
      _autoSaveSlots.saveSlot(_controller.exportSlot());
    }
    _roomCodeCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    _controller.setAutoQueen(settings.chessAutoQueen);

    if (_inLobby) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '${l10n.gameChess} • ${widget.difficulty.localizedLabel(l10n)}',
          ),
        ),
        body: _buildPreMatchLobby(p, l10n),
      );
    }

    return GameLifecycleGuard(
      onAutoPause: () => _controller.pause(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${l10n.gameChess} • ${widget.difficulty.localizedLabel(l10n)}',
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
                  if (_controller.state.mode != ChessPlayMode.online)
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
                    final isWide = constraints.maxWidth > 780;
                    if (isWide) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: _buildBoard(
                                  s,
                                  p,
                                  settings.chessPieceSet,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            SizedBox(
                              width: 310,
                              child: _buildSidebar(
                                s,
                                p,
                                l10n,
                                settings.chessPieceSet,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Column(
                          children: [
                            if (s.onlineRoomCode != null) ...[
                              _buildOnlineRoomBanner(s: s, p: p, l10n: l10n),
                              const SizedBox(height: 6),
                            ],
                            _buildPlayerBar(
                              isTop: true,
                              s: s,
                              p: p,
                              l10n: l10n,
                              pieceSet: settings.chessPieceSet,
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Center(
                                child: _buildBoard(
                                  s,
                                  p,
                                  settings.chessPieceSet,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildPlayerBar(
                              isTop: false,
                              s: s,
                              p: p,
                              l10n: l10n,
                              pieceSet: settings.chessPieceSet,
                            ),
                            const SizedBox(height: 8),
                            _buildControlsRow(s, p, l10n),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (s.pendingPromotionMoves != null)
                  _buildPromotionOverlay(
                    s.pendingPromotionMoves!,
                    s.turn,
                    settings.chessPieceSet,
                    p,
                    l10n,
                  ),
                AntiCheatPauseOverlay(
                  isPaused: s.isPaused && !s.isGameOver,
                  onResume: () => _controller.resume(),
                  onRestart: () => setState(() => _inLobby = true),
                  onQuit: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPreMatchLobby(ZetzyPalette p, AppLocalizations l10n) {
    final supa = ref.watch(supabaseServiceProvider);
    final user = ref.watch(authProvider);
    final canOnline = supa.isAvailable && !user.isGuest;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TactileCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Mode',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<ChessPlayMode>(
                    selected: {_selectedMode},
                    onSelectionChanged: (set) =>
                        setState(() => _selectedMode = set.first),
                    segments: [
                      ButtonSegment(
                        value: ChessPlayMode.vsAi,
                        label: Text(l10n.chessModeVsAi),
                        icon: const Icon(Icons.memory_rounded, size: 18),
                      ),
                      ButtonSegment(
                        value: ChessPlayMode.passAndPlay,
                        label: Text(l10n.chessModePassPlay),
                        icon: const Icon(
                          Icons.people_outline_rounded,
                          size: 18,
                        ),
                      ),
                      ButtonSegment(
                        value: ChessPlayMode.online,
                        label: Text(l10n.chessModeOnline),
                        icon: const Icon(Icons.wifi_rounded, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_selectedMode != ChessPlayMode.passAndPlay) ...[
                    Text(
                      l10n.chessPlayAs,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<ChessColorPref>(
                      selected: {_selectedColor},
                      onSelectionChanged: (set) =>
                          setState(() => _selectedColor = set.first),
                      segments: [
                        ButtonSegment(
                          value: ChessColorPref.white,
                          label: Text(l10n.chessWhite),
                        ),
                        ButtonSegment(
                          value: ChessColorPref.black,
                          label: Text(l10n.chessBlack),
                        ),
                        ButtonSegment(
                          value: ChessColorPref.random,
                          label: Text(l10n.chessRandom),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                  Text(
                    l10n.chessTimeControl,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tc in ChessTimeControl.values)
                        ChoiceChip(
                          selected: _selectedTime == tc,
                          onSelected: (_) => setState(() => _selectedTime = tc),
                          label: Text(switch (tc) {
                            ChessTimeControl.untimed => l10n.chessUntimed,
                            ChessTimeControl.bullet1 => l10n.chessBullet,
                            ChessTimeControl.blitz3 => l10n.chessBlitz3,
                            ChessTimeControl.blitz5 => l10n.chessBlitz5,
                            ChessTimeControl.rapid10 => l10n.chessRapid,
                          }),
                        ),
                    ],
                  ),
                  if (_selectedMode == ChessPlayMode.online) ...[
                    const SizedBox(height: 18),
                    if (!canOnline)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: p.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: p.warning),
                        ),
                        child: Text(
                          l10n.chessOnlineRequiresAuth,
                          style: TextStyle(color: p.warning, fontSize: 12),
                        ),
                      )
                    else ...[
                      TextField(
                        controller: _roomCodeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: l10n.chessRoomCode,
                          hintText: 'ABC123',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                final code = _roomCodeCtrl.text.trim();
                                if (code.isNotEmpty) {
                                  _startMatch(joinRoomCode: code);
                                }
                              },
                              child: Text(l10n.chessJoinRoom),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _startMatch(),
                              child: Text(l10n.chessCreateRoom),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ] else ...[
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _startMatch(),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(l10n.play),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildModeInfoCard(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineRoomBanner({
    required ChessUiState s,
    required ZetzyPalette p,
    required AppLocalizations l10n,
  }) {
    final code = s.onlineRoomCode!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(Icons.public_rounded, size: 18, color: p.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${l10n.chessRoomCode}: $code',
                  style: TextStyle(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (s.onlineWaiting)
                  Text(
                    l10n.chessWaitingOpponent,
                    style: TextStyle(color: p.warning, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.chessRoomCodeCopied(code))),
              );
            },
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            icon: const Icon(Icons.copy_rounded, size: 15),
            label: Text(l10n.chessCopyCode),
          ),
        ],
      ),
    );
  }

  String _timeControlLabel(ChessTimeControl tc, bool isIndo) {
    return switch (tc) {
      ChessTimeControl.untimed => isIndo ? 'Tanpa Waktu' : 'Untimed',
      ChessTimeControl.bullet1 => 'Bullet 1m',
      ChessTimeControl.blitz3 => 'Blitz 3m',
      ChessTimeControl.blitz5 => 'Blitz 5m',
      ChessTimeControl.rapid10 => 'Rapid 10m',
    };
  }

  Widget _buildModeInfoCard(AppLocalizations l10n) {
    final p = context.palette;
    final (icon, summary, accent) = switch (_selectedMode) {
      ChessPlayMode.vsAi => (
        Icons.smart_toy_rounded,
        widget.isPractice
            ? l10n.chessInfoSummaryPractice
            : l10n.chessInfoSummaryVsAi,
        widget.isPractice ? p.warning : p.accent,
      ),
      ChessPlayMode.passAndPlay => (
        Icons.people_alt_rounded,
        l10n.chessInfoSummaryPassPlay,
        p.textSecondary,
      ),
      ChessPlayMode.online => (
        Icons.public_rounded,
        widget.isPractice
            ? l10n.chessInfoSummaryPractice
            : l10n.chessInfoSummaryOnline,
        widget.isPractice ? p.warning : p.success,
      ),
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: TactileCard(
        key: const ValueKey('chess_mode_info_card'),
        onTap: () => _showModeInfoDialog(l10n),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        backgroundColor: p.surfaceElevated,
        borderColor: accent.withValues(alpha: 0.35),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    summary,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.chessTapForDetails,
                    style: TextStyle(color: p.textSecondary, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.info_outline_rounded, size: 18, color: accent),
          ],
        ),
      ),
    );
  }

  void _showModeInfoDialog(AppLocalizations l10n) {
    final p = context.palette;
    final isIndo = Localizations.localeOf(context).languageCode == 'id';
    final timeLabel = _timeControlLabel(_selectedTime, isIndo);
    final aiRating = ChessAiEngine.aiRatingForLevel(widget.difficulty.level);

    final (icon, modeTitle, detailText, accent) = switch (_selectedMode) {
      ChessPlayMode.vsAi => (
        Icons.smart_toy_rounded,
        l10n.chessInfoSummaryVsAi,
        l10n.chessInfoDetailVsAi(
          widget.difficulty.level.toString(),
          aiRating.toString(),
          widget.difficulty.xpReward.toString(),
        ),
        p.accent,
      ),
      ChessPlayMode.passAndPlay => (
        Icons.people_alt_rounded,
        l10n.chessInfoSummaryPassPlay,
        l10n.chessInfoDetailPassPlay,
        p.textSecondary,
      ),
      ChessPlayMode.online => (
        Icons.public_rounded,
        l10n.chessInfoSummaryOnline,
        l10n.chessInfoDetailOnline,
        p.success,
      ),
    };

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: p.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: p.border),
          ),
          title: Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.chessModeGuideTitle,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    modeTitle,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  detailText,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.timer_outlined, size: 17, color: p.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.chessTimeControlRule(timeLabel),
                          style: TextStyle(
                            color: p.textSecondary,
                            fontSize: 12.2,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isPractice &&
                    _selectedMode != ChessPlayMode.passAndPlay) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: p.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: p.warning.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.school_outlined, size: 17, color: p.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.chessPracticeDisabledNote,
                            style: TextStyle(
                              color: p.textPrimary,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBoard(ChessUiState s, ZetzyPalette p, ChessPieceSet pieceSet) {
    final game = _controller.game;

    return AspectRatio(
      aspectRatio: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 520),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.border, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var visualRow = 0; visualRow < 8; visualRow++)
                Expanded(
                  child: Row(
                    children: [
                      for (var visualCol = 0; visualCol < 8; visualCol++)
                        _buildSquare(
                          s: s,
                          p: p,
                          pieceSet: pieceSet,
                          game: game,
                          rank: s.flipped ? visualRow : 7 - visualRow,
                          file: s.flipped ? 7 - visualCol : visualCol,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquare({
    required ChessUiState s,
    required ZetzyPalette p,
    required ChessPieceSet pieceSet,
    required Game game,
    required int rank,
    required int file,
  }) {
    final sqIdx = game.size.square(file, rank);
    final sq = game.board[sqIdx];
    final isLight = (rank + file) % 2 != 0;
    final isSelected = s.selectedSquare == sqIdx;
    final isLastMove = s.lastFrom == sqIdx || s.lastTo == sqIdx;
    final isTarget = s.legalTargets.contains(sqIdx);

    final isKingInCheck =
        s.inCheck &&
        sq.isNotEmpty &&
        sq.colour == s.turn &&
        game.variant.pieces[sq.type].symbol.toUpperCase() == 'K';

    Color bg = isLight ? p.boardLight : p.boardDark;
    if (isKingInCheck) {
      bg = p.danger.withValues(alpha: 0.72);
    } else if (isSelected) {
      bg = p.accent.withValues(alpha: 0.55);
    } else if (isLastMove) {
      bg = Color.alphaBlend(p.boardHighlight, bg);
    }

    String? pieceAsset;
    if (sq.isNotEmpty) {
      final colorPrefix = sq.colour == Bishop.white ? 'w' : 'b';
      final pieceCode = game.variant.pieces[sq.type].symbol.toUpperCase();
      pieceAsset = pieceSet.pieceAsset(colorPrefix, pieceCode);
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => _controller.onSquareTap(sqIdx),
        child: Container(
          color: bg,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (pieceAsset != null)
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: SvgPicture.asset(pieceAsset),
                ),
              if (isTarget)
                Container(
                  width: sq.isNotEmpty ? 42 : 14,
                  height: sq.isNotEmpty ? 42 : 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sq.isNotEmpty
                        ? Colors.transparent
                        : p.accent.withValues(alpha: 0.65),
                    border: sq.isNotEmpty
                        ? Border.all(
                            color: p.accent.withValues(alpha: 0.8),
                            width: 3,
                          )
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerBar({
    required bool isTop,
    required ChessUiState s,
    required ZetzyPalette p,
    required AppLocalizations l10n,
    required ChessPieceSet pieceSet,
  }) {
    final colour = isTop
        ? (s.flipped ? Bishop.white : Bishop.black)
        : (s.flipped ? Bishop.black : Bishop.white);
    final isWhite = colour == Bishop.white;
    final isTurn = s.turn == colour;
    final timeMs = isWhite ? s.whiteTimeMs : s.blackTimeMs;
    final captured = isWhite ? s.capturedByWhite : s.capturedByBlack;
    final adv = isWhite ? s.materialAdvantage : -s.materialAdvantage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isTurn ? p.accent : p.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: isWhite ? Colors.white : Colors.black,
          ),
          const SizedBox(width: 8),
          Text(
            isWhite ? l10n.chessWhite : l10n.chessBlack,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final code in captured)
                    SvgPicture.asset(
                      pieceSet.pieceAsset(isWhite ? 'b' : 'w', code),
                      width: 18,
                      height: 18,
                    ),
                  if (adv > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        '+$adv',
                        style: ZetzyThemes.monoStyle(
                          fontSize: 12,
                          color: p.accent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (s.timeControl != ChessTimeControl.untimed)
            Text(
              TimeFormatter.formatClock(timeMs),
              style: ZetzyThemes.monoStyle(
                fontSize: 15,
                color: isTurn ? p.accent : p.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlsRow(
    ChessUiState s,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (s.isPractice && s.mode != ChessPlayMode.online)
          OutlinedButton.icon(
            onPressed: s.canPracticeUndo ? _controller.practiceUndo : null,
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: Text(l10n.practiceUndo),
          )
        else if (s.mode == ChessPlayMode.vsAi)
          Tooltip(
            message: s.difficulty.level >= 5
                ? l10n.chessUndoLocked
                : l10n.chessUndo,
            child: OutlinedButton.icon(
              onPressed: s.canUndo ? _controller.undoVsAi : null,
              icon: Icon(
                s.difficulty.level >= 5
                    ? Icons.lock_outline
                    : Icons.undo_rounded,
                size: 18,
              ),
              label: Text(l10n.chessUndo),
            ),
          ),
        OutlinedButton.icon(
          onPressed: _controller.flipBoard,
          icon: const Icon(Icons.swap_vert_rounded, size: 18),
          label: Text(l10n.chessFlipBoard),
        ),
        OutlinedButton.icon(
          onPressed: _controller.resign,
          icon: Icon(Icons.flag_outlined, size: 18, color: p.danger),
          label: Text(l10n.chessResign, style: TextStyle(color: p.danger)),
        ),
      ],
    );
  }

  Widget _buildSidebar(
    ChessUiState s,
    ZetzyPalette p,
    AppLocalizations l10n,
    ChessPieceSet pieceSet,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPlayerBar(
            isTop: true,
            s: s,
            p: p,
            l10n: l10n,
            pieceSet: pieceSet,
          ),
          const SizedBox(height: 8),
          if (s.onlineRoomCode != null)
            ListTile(
              dense: true,
              title: Text('${l10n.chessRoomCode}: ${s.onlineRoomCode}'),
              subtitle: Text(
                s.onlineWaiting ? l10n.chessWaitingOpponent : 'Connected',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: s.onlineRoomCode!));
                },
              ),
            ),
          if (s.isAiThinking)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.chessAiThinking, style: TextStyle(color: p.accent)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              l10n.chessMoves,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: p.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                itemCount: (s.moveSans.length + 1) ~/ 2,
                itemBuilder: (context, idx) {
                  final whiteMove = s.moveSans[idx * 2];
                  final blackMove = idx * 2 + 1 < s.moveSans.length
                      ? s.moveSans[idx * 2 + 1]
                      : '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${idx + 1}. $whiteMove  $blackMove',
                      style: ZetzyThemes.monoStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: p.textPrimary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildPlayerBar(
            isTop: false,
            s: s,
            p: p,
            l10n: l10n,
            pieceSet: pieceSet,
          ),
          const SizedBox(height: 10),
          _buildControlsRow(s, p, l10n),
        ],
      ),
    );
  }

  Widget _buildPromotionOverlay(
    List<Move> promoMoves,
    int turn,
    ChessPieceSet pieceSet,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) {
    final prefix = turn == Bishop.white ? 'w' : 'b';
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.chessPromotion,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final move in promoMoves)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: InkWell(
                        onTap: () => _controller.completePromotion(move),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: p.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SvgPicture.asset(
                            pieceSet.pieceAsset(
                              prefix,
                              _controller
                                  .game
                                  .variant
                                  .pieces[move.promoPiece!]
                                  .symbol
                                  .toUpperCase(),
                            ),
                            width: 42,
                            height: 42,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _controller.cancelPromotion,
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
