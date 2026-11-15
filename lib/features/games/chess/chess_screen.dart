import 'dart:async';

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
import 'package:zetzy/core/widgets/in_game_settings_sheet.dart';
import 'package:zetzy/core/widgets/tactile_card.dart';
import 'package:zetzy/core/widgets/win_result_dialog.dart';
import 'package:zetzy/data/models/auto_save_slot.dart';
import 'package:zetzy/features/games/chess/chess_ai.dart';
import 'package:zetzy/features/games/chess/chess_controller.dart';
import 'package:zetzy/features/games/chess/chess_matchmaking.dart';
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
  late final ChessMatchmakingSession _matchmaking;
  bool _inLobby = true;

  ChessPlayMode _selectedMode = ChessPlayMode.vsAi;
  ChessColorPref _selectedColor = ChessColorPref.white;
  ChessTimeControl _selectedTime = ChessTimeControl.blitz5;
  final TextEditingController _roomCodeCtrl = TextEditingController();
  ({
    ChessUiState state,
    int score,
    bool effectiveWon,
    bool aborted,
    bool isUnratedForDialog,
    bool isNewRecord,
  })?
  _finishedSummary;

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
    _matchmaking = ChessMatchmakingSession(
      supabase: ref.read(supabaseServiceProvider),
      onMatched: _onMatchFound,
    );

    if (widget.resumeSlot != null) {
      _inLobby = false;
      _controller.restoreFromSlot(widget.resumeSlot!);
    }
  }

  void _onMatchFound(MatchAssignment assignment) {
    if (!mounted) return;
    setState(() => _selectedMode = ChessPlayMode.findMatch);
    _startMatch(assignment: assignment);
    final l10n = AppLocalizations.of(context);
    if (l10n != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.chessMatchFoundBanner(
              assignment.opponentUsername,
              assignment.opponentElo,
            ),
          ),
        ),
      );
    }
  }

  void _selectMode(ChessPlayMode mode) {
    if (_matchmaking.state.isSearching && mode != ChessPlayMode.findMatch) {
      unawaited(_matchmaking.cancelSearch());
    }
    setState(() {
      _selectedMode = mode;
      if (mode == ChessPlayMode.findMatch &&
          _selectedTime == ChessTimeControl.untimed) {
        _selectedTime = ChessTimeControl.blitz5;
      }
    });
  }

  void _startMatch({String? joinRoomCode, MatchAssignment? assignment}) {
    if (_matchmaking.state.isSearching) {
      unawaited(_matchmaking.cancelSearch());
    }
    final user = ref.read(authProvider);
    final effectiveMode = assignment != null
        ? ChessPlayMode.findMatch
        : _selectedMode;
    final effectiveTime =
        effectiveMode == ChessPlayMode.findMatch &&
            _selectedTime == ChessTimeControl.untimed
        ? ChessTimeControl.blitz5
        : _selectedTime;
    final colorPref = assignment != null
        ? (assignment.assignedColor == Bishop.black
              ? ChessColorPref.black
              : ChessColorPref.white)
        : (joinRoomCode != null ? ChessColorPref.black : _selectedColor);

    setState(() {
      _finishedSummary = null;
      _inLobby = false;
    });
    _controller.startNew(
      difficulty: widget.difficulty,
      isPractice: widget.isPractice,
      mode: effectiveMode,
      colorPref: colorPref,
      timeControl: effectiveTime,
      roomCode: assignment?.roomCode ?? joinRoomCode,
      isHost: assignment == null
          ? joinRoomCode == null
          : assignment.assignedColor == Bishop.white,
      matchId: assignment?.matchId,
      localUserId: user.isGuest ? null : user.id,
      localUsername: user.isGuest ? null : user.username,
      localAvatarUrl: user.avatarUrl,
      localChessElo: user.chessElo,
      opponentUserId: assignment?.opponentUserId,
      opponentUsername: assignment?.opponentUsername,
      opponentAvatarUrl: assignment?.opponentAvatarUrl,
      opponentElo: assignment?.opponentElo,
    );
  }

  Future<void> _handleGameFinished(ChessUiState finalState) async {
    await ref.read(autoSaveSlotsProvider.notifier).clearSlot(GameType.chess);

    var aborted = finalState.isAbortedUnrated;
    final playerWon =
        !aborted &&
        !finalState.isDraw &&
        finalState.winnerColour == finalState.playerColor;
    // Anti-cheat: Private Online Friend Rooms and Pass & Play are strictly unrated
    // to prevent mutual forfeit/win-trading ELO boosting or PRO+ Leaderboard spoofing.
    final isCasualMode =
        finalState.isPractice ||
        finalState.mode == ChessPlayMode.passAndPlay ||
        finalState.mode == ChessPlayMode.online;
    var score = 0;

    if (!aborted && !isCasualMode && finalState.mode.isRankedMode) {
      final currentElo = ref.read(authProvider).chessElo;
      if (finalState.mode == ChessPlayMode.findMatch &&
          finalState.onlineMatchId != null) {
        final serverResult = await ref
            .read(supabaseServiceProvider)
            .finishRankedChessMatch(
              matchId: finalState.onlineMatchId!,
              winnerColour: finalState.isDraw ? null : finalState.winnerColour,
              isDraw: finalState.isDraw,
              moveCount: finalState.moveSans.length,
              pgn: _controller.livePgn,
            );
        if (serverResult != null) {
          if (serverResult.status == 'aborted') {
            aborted = true;
            score = 0;
          } else {
            score = serverResult.eloDelta;
            await ref
                .read(authProvider.notifier)
                .updateChessElo(serverResult.newElo);
          }
        } else {
          final opponentElo = finalState.opponentElo ?? currentElo;
          final outcome = finalState.isDraw ? 0.5 : (playerWon ? 1.0 : 0.0);
          final newElo = ChessAiEngine.calculateNewElo(
            currentElo: currentElo,
            opponentElo: opponentElo,
            score: outcome,
          );
          score = newElo - currentElo;
          await ref.read(authProvider.notifier).updateChessElo(newElo);
        }
      } else {
        final opponentElo = finalState.mode == ChessPlayMode.vsAi
            ? ChessAiEngine.aiRatingForLevel(finalState.difficulty.level)
            : (finalState.opponentElo ?? currentElo);
        final outcome = finalState.isDraw ? 0.5 : (playerWon ? 1.0 : 0.0);
        final newElo = ChessAiEngine.calculateNewElo(
          currentElo: currentElo,
          opponentElo: opponentElo,
          score: outcome,
        );
        score = newElo - currentElo;
        await ref.read(authProvider.notifier).updateChessElo(newElo);
      }
    }

    final isUnratedForDialog = aborted || isCasualMode;
    final effectiveWon = !aborted && playerWon;
    final isVsAiRanked = !aborted && !isCasualMode && finalState.mode == ChessPlayMode.vsAi;

    final isNewRecord = await ref
        .read(scoreSyncControllerProvider)
        .recordGameResult(
          gameType: GameType.chess,
          difficulty: finalState.difficulty.level,
          isWon: effectiveWon,
          score: score,
          durationMs: finalState.elapsedMs,
          isPractice: isUnratedForDialog,
          allowUnlock: isVsAiRanked,
          syncRemote: isVsAiRanked,
          metadata: {
            'mode': finalState.mode.name,
            'timeControl': finalState.timeControl.name,
            if (finalState.opponentElo != null)
              'opponentElo': finalState.opponentElo,
            if (finalState.opponentUsername != null)
              'opponentUsername': finalState.opponentUsername,
            'pgn': _controller.livePgn,
            'moves': finalState.moveSans.length,
            if (aborted) 'aborted': true,
          },
        );

    final summary = (
      state: finalState,
      score: score,
      effectiveWon: effectiveWon,
      aborted: aborted,
      isUnratedForDialog: isUnratedForDialog,
      isNewRecord: isNewRecord,
    );
    _finishedSummary = summary;

    if (!mounted) return;
    await _showResultDialog(summary);
  }

  Future<void> _showResultDialog(
    ({
      ChessUiState state,
      int score,
      bool effectiveWon,
      bool aborted,
      bool isUnratedForDialog,
      bool isNewRecord,
    })
    summary,
  ) async {
    final finalState = summary.state;
    final aborted = summary.aborted;
    final effectiveWon = summary.effectiveWon;
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.read(settingsProvider);
    final canRewind =
        finalState.isPractice &&
        !finalState.mode.isOnlineMultiplayer &&
        !effectiveWon &&
        !finalState.isDraw &&
        !aborted &&
        settings.practiceRewindOnLoss &&
        finalState.canPracticeUndo;

    final subtitleOverride = switch (finalState.mode) {
      ChessPlayMode.findMatch =>
        '${l10n.chessModeFindMatch}'
            '${finalState.opponentUsername != null ? ' • vs @${finalState.opponentUsername}' : ''}',
      ChessPlayMode.online => '${l10n.chessModeOnline} (Unrated)',
      _ => null,
    };
    final noteText = aborted
        ? l10n.chessAbortedTooShortNote
        : (finalState.mode == ChessPlayMode.online
              ? l10n.chessOnlineUnratedNote
              : null);

    await showGameResultDialog(
      context: context,
      gameType: GameType.chess,
      difficulty: finalState.difficulty,
      isWon: effectiveWon,
      isDraw: aborted || finalState.isDraw,
      durationMs: finalState.elapsedMs,
      score: summary.score,
      isNewRecord: summary.isNewRecord,
      isPractice: summary.isUnratedForDialog,
      titleOverride: aborted ? l10n.chessAbortedTooShortTitle : null,
      subtitleOverride: subtitleOverride,
      noteText: noteText,
      extraMetrics: [
        (label: l10n.chessMoves, value: '${finalState.moveSans.length}'),
        if (finalState.mode == ChessPlayMode.findMatch &&
            finalState.opponentElo != null)
          (
            label: '${l10n.chessOpponentLabel} ELO',
            value: '${finalState.opponentElo}',
          ),
      ],
      rewindSteps: settings.practiceRewindSteps,
      onRewindContinue: canRewind
          ? () {
              _finishedSummary = null;
              _controller.practiceRewind(settings.practiceRewindSteps);
            }
          : null,
      onReviewBoard: () {},
      onPlayAgain: () => setState(() => _inLobby = true),
      onExit: () => Navigator.of(context).pop(),
    );
  }

  @override
  void dispose() {
    if (!_inLobby &&
        !_controller.state.isGameOver &&
        !_controller.state.mode.isOnlineMultiplayer) {
      _autoSaveSlots.saveSlot(_controller.exportSlot());
    }
    _matchmaking.dispose();
    _roomCodeCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openInGameSettings() async {
    final canAutoPause =
        !_inLobby &&
        !_controller.state.mode.isOnlineMultiplayer &&
        !_controller.state.isPaused &&
        !_controller.state.isGameOver;
    if (canAutoPause) {
      _controller.pause(save: false);
    }
    await showInGameSettingsSheet(
      context: context,
      gameType: GameType.chess,
    );
    if (!mounted) return;
    if (canAutoPause) {
      _controller.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    _controller.setAutoQueen(settings.chessAutoQueen);
    _controller.setMoveConfirmMode(settings.chessMoveConfirmMode);
    _controller.setAutoFlipPassPlay(settings.chessAutoFlipPassPlay);

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
                mainAxisSize: MainAxisSize.min,
                children: [
                  GameTimerBadge(
                    elapsedMs: _controller.state.elapsedMs,
                    isPaused: _controller.state.isPaused,
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 34,
                      minHeight: 34,
                    ),
                    tooltip: l10n.chessFlipBoard,
                    onPressed: _controller.flipBoard,
                    icon: const Icon(Icons.swap_vert_rounded, size: 20),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 34,
                      minHeight: 34,
                    ),
                    tooltip: l10n.settingsInGameTitle,
                    onPressed: _openInGameSettings,
                    icon: const Icon(Icons.settings_outlined, size: 20),
                  ),
                  if (!_controller.state.mode.isOnlineMultiplayer)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
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
                                  showLegalMoves: settings.chessShowLegalMoves,
                                  showCoordinates:
                                      settings.chessShowCoordinates,
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
                                  showLegalMoves: settings.chessShowLegalMoves,
                                  showCoordinates:
                                      settings.chessShowCoordinates,
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
                            if (s.hasPendingConfirm && !s.isGameOver) ...[
                              _buildMoveConfirmBar(s, p, l10n),
                              const SizedBox(height: 8),
                            ],
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
    final isFindMatch = _selectedMode == ChessPlayMode.findMatch;

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
                  _buildModeSelector(p, l10n),
                  const SizedBox(height: 18),
                  if (_selectedMode == ChessPlayMode.vsAi ||
                      _selectedMode == ChessPlayMode.online) ...[
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
                  ] else if (isFindMatch) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: p.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shuffle_rounded, size: 16, color: p.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.chessAutoColorFair,
                              style: TextStyle(
                                color: p.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                          onSelected:
                              isFindMatch && tc == ChessTimeControl.untimed
                              ? null
                              : (_) => setState(() => _selectedTime = tc),
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
                  if (isFindMatch) ...[
                    const SizedBox(height: 6),
                    Text(
                      l10n.chessMatchTimedOnlyNote,
                      style: TextStyle(color: p.textSecondary, fontSize: 11.5),
                    ),
                    const SizedBox(height: 18),
                    _buildFindMatchPanel(p, l10n, canOnline),
                  ] else if (_selectedMode == ChessPlayMode.online) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: p.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 16,
                            color: p.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.chessOnlineUnratedNote,
                              style: TextStyle(
                                color: p.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
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

  Widget _buildModeSelector(ZetzyPalette p, AppLocalizations l10n) {
    final options = [
      (ChessPlayMode.vsAi, l10n.chessModeVsAi, Icons.memory_rounded),
      (
        ChessPlayMode.passAndPlay,
        l10n.chessModePassPlay,
        Icons.people_outline_rounded,
      ),
      (ChessPlayMode.findMatch, l10n.chessModeFindMatch, Icons.radar_rounded),
      (ChessPlayMode.online, l10n.chessModeOnline, Icons.wifi_rounded),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (mode, label, icon) in options)
              SizedBox(
                width: itemWidth,
                child: Material(
                  color: _selectedMode == mode
                      ? p.accent.withValues(alpha: 0.14)
                      : p.surfaceElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _selectedMode == mode ? p.accent : p.border,
                      width: _selectedMode == mode ? 1.4 : 1,
                    ),
                  ),
                  child: InkWell(
                    key: ValueKey('chess_mode_${mode.name}'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _selectMode(mode),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 11,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 17,
                            color: _selectedMode == mode
                                ? p.accent
                                : p.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _selectedMode == mode
                                    ? p.accent
                                    : p.textPrimary,
                                fontWeight: _selectedMode == mode
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFindMatchPanel(
    ZetzyPalette p,
    AppLocalizations l10n,
    bool canOnline,
  ) {
    final user = ref.watch(authProvider);
    if (!canOnline) {
      return Container(
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
      );
    }

    return ListenableBuilder(
      listenable: _matchmaking,
      builder: (context, _) {
        final mm = _matchmaking.state;
        if (!mm.isSearching) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.chessYourElo(user.chessElo),
                    style: ZetzyThemes.monoStyle(
                      fontSize: 12.5,
                      color: p.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _timeControlLabel(_selectedTime, false),
                    style: TextStyle(color: p.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              if (mm.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  mm.errorMessage!,
                  style: TextStyle(color: p.danger, fontSize: 12),
                ),
              ],
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () {
                  unawaited(
                    _matchmaking.startSearch(
                      profile: user,
                      timeControlName: _selectedTime.name,
                    ),
                  );
                },
                icon: const Icon(Icons.radar_rounded),
                label: Text(l10n.chessFindMatchStart),
              ),
            ],
          );
        }

        final w = mm.window;
        final rangeText = w.isUnbounded
            ? l10n.chessSearchingNearestElo(w.minElo, w.maxElo)
            : l10n.chessSearchingEloRange(w.minElo, w.maxElo, w.radius!);

        return Container(
          key: const ValueKey('chess_finding_match_card'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.accent.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: p.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.chessFindingMatchTitle,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  Text(
                    l10n.chessFindMatchStage(w.stage, w.totalStages, mm.waitSeconds),
                    style: ZetzyThemes.monoStyle(
                      fontSize: 11.5,
                      color: p.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                rangeText,
                key: const ValueKey('chess_elo_search_range'),
                style: ZetzyThemes.monoStyle(
                  fontSize: 12.5,
                  color: p.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: w.stage / w.totalStages,
                  minHeight: 5,
                  backgroundColor: p.surfaceElevated,
                  color: p.accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.chessExpandingRangeHint,
                style: TextStyle(color: p.textSecondary, fontSize: 11.5),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => unawaited(_matchmaking.cancelSearch()),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: Text(l10n.cancel),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOnlineRoomBanner({
    required ChessUiState s,
    required ZetzyPalette p,
    required AppLocalizations l10n,
  }) {
    final isFindMatch = s.mode == ChessPlayMode.findMatch;
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
          Icon(
            isFindMatch ? Icons.radar_rounded : Icons.public_rounded,
            size: 18,
            color: p.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isFindMatch
                      ? (s.opponentUsername != null
                            ? l10n.chessMatchFoundBanner(
                                s.opponentUsername!,
                                s.opponentElo ?? 1000,
                              )
                            : l10n.chessModeFindMatch)
                      : '${l10n.chessRoomCode}: $code (Unrated)',
                  style: TextStyle(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
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
          if (!isFindMatch) ...[
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
      ChessPlayMode.findMatch => (
        Icons.radar_rounded,
        widget.isPractice
            ? l10n.chessInfoSummaryPractice
            : l10n.chessInfoSummaryFindMatch,
        widget.isPractice ? p.warning : p.success,
      ),
      ChessPlayMode.online => (
        Icons.public_rounded,
        l10n.chessInfoSummaryOnline,
        p.textSecondary,
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
      ChessPlayMode.findMatch => (
        Icons.radar_rounded,
        l10n.chessInfoSummaryFindMatch,
        l10n.chessInfoDetailFindMatch,
        p.success,
      ),
      ChessPlayMode.online => (
        Icons.public_rounded,
        l10n.chessInfoSummaryOnline,
        l10n.chessInfoDetailOnline,
        p.textSecondary,
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
                if (widget.isPractice && _selectedMode.isRankedMode) ...[
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

  Widget _buildBoard(
    ChessUiState s,
    ZetzyPalette p,
    ChessPieceSet pieceSet, {
    required bool showLegalMoves,
    required bool showCoordinates,
  }) {
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
                          showRankLabel: showCoordinates && visualCol == 0,
                          showFileLabel: showCoordinates && visualRow == 7,
                          showLegalMoves: showLegalMoves,
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
    required bool showRankLabel,
    required bool showFileLabel,
    required bool showLegalMoves,
  }) {
    final sqIdx = game.size.square(file, rank);
    final sq = game.board[sqIdx];
    final isLight = (rank + file) % 2 != 0;
    final isSelected = s.selectedSquare == sqIdx;
    final isLastMove = s.lastFrom == sqIdx || s.lastTo == sqIdx;
    final isTarget = s.legalTargets.contains(sqIdx);
    final isPendingFrom = s.pendingConfirmFrom == sqIdx;
    final isPendingTo = s.pendingConfirmTo == sqIdx;

    final isKingInCheck =
        s.inCheck &&
        sq.isNotEmpty &&
        sq.colour == s.turn &&
        game.variant.pieces[sq.type].symbol.toUpperCase() == 'K';

    Color bg = isLight ? p.boardLight : p.boardDark;
    if (isKingInCheck) {
      bg = p.danger.withValues(alpha: 0.72);
    } else if (isPendingTo) {
      bg = Color.alphaBlend(p.accent.withValues(alpha: 0.48), bg);
    } else if (isPendingFrom) {
      bg = Color.alphaBlend(p.accent.withValues(alpha: 0.30), bg);
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
    final coordColor = (isLight ? p.boardDark : p.boardLight).withValues(
      alpha: 0.85,
    );

    return Expanded(
      child: GestureDetector(
        onTap: () => _controller.onSquareTap(sqIdx),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: isPendingTo
                ? Border.all(color: p.accent, width: 2.5)
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (showRankLabel)
                Positioned(
                  left: 3,
                  top: 1.5,
                  child: IgnorePointer(
                    child: Text(
                      '${rank + 1}',
                      style: ZetzyThemes.monoStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: coordColor,
                      ).copyWith(height: 1.0),
                    ),
                  ),
                ),
              if (showFileLabel)
                Positioned(
                  right: 3,
                  bottom: 1.5,
                  child: IgnorePointer(
                    child: Text(
                      String.fromCharCode('a'.codeUnitAt(0) + file),
                      style: ZetzyThemes.monoStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: coordColor,
                      ).copyWith(height: 1.0),
                    ),
                  ),
                ),
              if (pieceAsset != null)
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: SvgPicture.asset(pieceAsset),
                ),
              if (showLegalMoves && isTarget)
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

    final auth = ref.watch(authProvider);
    final isLocalPlayer = colour == s.playerColor;
    var label = isWhite ? l10n.chessWhite : l10n.chessBlack;
    if (s.mode.isOnlineMultiplayer) {
      if (isLocalPlayer) {
        if (!auth.isGuest) {
          label = '@${auth.username} (${auth.chessElo})';
        }
      } else if (s.opponentUsername != null) {
        final oppElo = s.opponentElo != null ? ' (${s.opponentElo})' : '';
        label = '@${s.opponentUsername}$oppElo';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isTurn ? p.accent : p.border),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isWhite ? Colors.white : Colors.black,
              border: Border.all(color: p.border, width: 1.2),
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 165),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
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

  Widget _buildMoveConfirmBar(
    ChessUiState s,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) {
    final prompt = l10n.chessConfirmMovePrompt(s.pendingConfirmSan ?? '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.accent.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app_rounded, size: 18, color: p.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              prompt,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: p.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton.outlined(
            visualDensity: VisualDensity.compact,
            tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
            onPressed: _controller.cancelPendingMove,
            icon: Icon(Icons.close_rounded, size: 18, color: p.danger),
          ),
          const SizedBox(width: 6),
          IconButton.filled(
            visualDensity: VisualDensity.compact,
            tooltip: prompt,
            onPressed: _controller.confirmPendingMove,
            icon: const Icon(Icons.check_rounded, size: 18),
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
    if (s.isGameOver) {
      return _buildReviewControls(s, p, l10n);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.spaceEvenly,
      children: [
        if (s.isPractice && !s.mode.isOnlineMultiplayer)
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

  Widget _buildReviewControls(
    ChessUiState s,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) {
    final summary = _finishedSummary;
    final totalPlies = s.moveSans.length;
    final currentPly = s.effectiveReviewPly;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: s.canReviewBack ? _controller.reviewFirst : null,
                icon: const Icon(Icons.first_page_rounded, size: 19),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: s.canReviewBack ? _controller.reviewPrev : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 19),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    l10n.chessMoveStep(currentPly, totalPlies),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: ZetzyThemes.monoStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: s.canReviewForward ? _controller.reviewNext : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 19),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: s.canReviewForward ? _controller.reviewLast : null,
                icon: const Icon(Icons.last_page_rounded, size: 19),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 32),
                padding: EdgeInsets.zero,
                tooltip: l10n.chessFlipBoard,
                onPressed: _controller.flipBoard,
                icon: const Icon(Icons.swap_vert_rounded, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (summary != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => _showResultDialog(summary),
                    icon: const Icon(Icons.assessment_outlined, size: 16),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(l10n.viewResult, maxLines: 1),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () => setState(() => _inLobby = true),
                  icon: const Icon(Icons.replay_rounded, size: 16),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(l10n.playAgain, maxLines: 1),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
          if (s.onlineRoomCode != null) ...[
            _buildOnlineRoomBanner(s: s, p: p, l10n: l10n),
            const SizedBox(height: 8),
          ],
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
                  final whitePly = idx * 2 + 1;
                  final blackPly = idx * 2 + 2;
                  final whiteMove = s.moveSans[idx * 2];
                  final hasBlack = idx * 2 + 1 < s.moveSans.length;
                  final blackMove = hasBlack ? s.moveSans[idx * 2 + 1] : '';

                  Widget buildMoveChip(String san, int ply) {
                    final active = s.isGameOver && s.effectiveReviewPly == ply;
                    final chip = Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? p.accent.withValues(alpha: 0.22)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        san,
                        style: ZetzyThemes.monoStyle(
                          fontSize: 13,
                          fontWeight:
                              active ? FontWeight.w800 : FontWeight.w500,
                          color: active ? p.accent : p.textPrimary,
                        ),
                      ),
                    );
                    if (!s.isGameOver) return chip;
                    return InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => _controller.jumpToReviewPly(ply),
                      child: chip,
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            '${idx + 1}.',
                            style: ZetzyThemes.monoStyle(
                              fontSize: 12,
                              color: p.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(child: buildMoveChip(whiteMove, whitePly)),
                        if (hasBlack)
                          Expanded(child: buildMoveChip(blackMove, blackPly))
                        else
                          const Spacer(),
                      ],
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
          if (s.hasPendingConfirm && !s.isGameOver) ...[
            _buildMoveConfirmBar(s, p, l10n),
            const SizedBox(height: 8),
          ],
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
