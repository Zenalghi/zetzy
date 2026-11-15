import 'package:bishop/bishop.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/services/audio_service.dart';
import 'package:zetzy/core/services/haptic_service.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/data/local/local_storage_service.dart';
import 'package:zetzy/data/local/settings_repository.dart';
import 'package:zetzy/data/models/auto_save_slot.dart';
import 'package:zetzy/data/models/user_profile.dart';
import 'package:zetzy/data/remote/supabase_service.dart';
import 'package:zetzy/features/games/chess/chess_controller.dart';
import 'package:zetzy/features/games/chess/chess_matchmaking.dart';
import 'package:zetzy/features/games/chess/chess_screen.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

class _FakeMatchmakingSupabaseService extends SupabaseService {
  int cancelCalls = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<UserProfile?> fetchCurrentProfile() async => const UserProfile(
    id: 'u-mm-1',
    username: 'zen',
    chessElo: 1200,
    isGuest: false,
  );

  @override
  Future<MatchAssignment?> matchmakeChess({
    required String timeControlName,
    int? searchRadius,
    int waitSeconds = 0,
  }) async => null;

  @override
  Future<void> cancelChessMatchmaking() async {
    cancelCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChessMatchmakingEngine expanding ELO window', () {
    test('expands radius across timed stages and clamps to 400..3500', () {
      final t0 = ChessMatchmakingEngine.windowFor(myElo: 1000, waitSeconds: 0);
      expect(t0.stage, 1);
      expect(t0.totalStages, 6);
      expect(t0.isUnbounded, isFalse);
      expect(t0.radius, 50);
      expect(t0.minElo, 950);
      expect(t0.maxElo, 1050);

      final t8 = ChessMatchmakingEngine.windowFor(myElo: 450, waitSeconds: 8);
      expect(t8.stage, 2);
      expect(t8.radius, 120);
      expect(t8.minElo, 400);
      expect(t8.maxElo, 570);

      final t16 = ChessMatchmakingEngine.windowFor(myElo: 3400, waitSeconds: 16);
      expect(t16.stage, 3);
      expect(t16.radius, 250);
      expect(t16.minElo, 3150);
      expect(t16.maxElo, 3500);

      final t25 = ChessMatchmakingEngine.windowFor(myElo: 1500, waitSeconds: 25);
      expect(t25.stage, 4);
      expect(t25.radius, 500);

      final t35 = ChessMatchmakingEngine.windowFor(myElo: 1500, waitSeconds: 35);
      expect(t35.stage, 5);
      expect(t35.radius, 1000);

      final t45 = ChessMatchmakingEngine.windowFor(myElo: 1500, waitSeconds: 45);
      expect(t45.stage, 6);
      expect(t45.isUnbounded, isTrue);
      expect(t45.radius, isNull);
      expect(t45.minElo, 400);
      expect(t45.maxElo, 3500);
    });

    test('blocks self-match and different time controls', () {
      const me = MatchSearchTicket(
        userId: 'u1',
        username: 'zen',
        chessElo: 1000,
        timeControlName: 'blitz5',
        waitSeconds: 50,
      );

      final picked = ChessMatchmakingEngine.selectBestOpponent(
        me: me,
        candidates: const [
          MatchCandidate(
            userId: 'u1',
            username: 'zen',
            chessElo: 1000,
            timeControlName: 'blitz5',
            waitSeconds: 50,
          ),
          MatchCandidate(
            userId: 'u2',
            username: 'rapid_player',
            chessElo: 1005,
            timeControlName: 'rapid10',
            waitSeconds: 50,
          ),
        ],
      );

      expect(picked, isNull);
    });

    test('picks nearest ELO among compatible waiting opponents', () {
      const me = MatchSearchTicket(
        userId: 'u1',
        username: 'zen',
        chessElo: 1200,
        timeControlName: 'blitz5',
        waitSeconds: 18,
      );

      final picked = ChessMatchmakingEngine.selectBestOpponent(
        me: me,
        candidates: const [
          MatchCandidate(
            userId: 'u-far',
            username: 'far',
            chessElo: 1410,
            timeControlName: 'blitz5',
            waitSeconds: 20,
          ),
          MatchCandidate(
            userId: 'u-near',
            username: 'near',
            chessElo: 1235,
            timeControlName: 'blitz5',
            waitSeconds: 18,
          ),
        ],
      );

      expect(picked?.userId, 'u-near');
    });

    test('rejects huge ELO gap early, then forces nearest match after 45s', () {
      const earlyMe = MatchSearchTicket(
        userId: 'u1',
        username: 'novice',
        chessElo: 600,
        timeControlName: 'blitz3',
        waitSeconds: 0,
      );
      const grandmaster = MatchCandidate(
        userId: 'u2',
        username: 'gm',
        chessElo: 2450,
        timeControlName: 'blitz3',
        waitSeconds: 4,
      );

      expect(
        ChessMatchmakingEngine.selectBestOpponent(
          me: earlyMe,
          candidates: const [grandmaster],
        ),
        isNull,
      );

      const desperateMe = MatchSearchTicket(
        userId: 'u1',
        username: 'novice',
        chessElo: 600,
        timeControlName: 'blitz3',
        waitSeconds: 46,
      );
      const waitingGm = MatchCandidate(
        userId: 'u2',
        username: 'gm',
        chessElo: 2450,
        timeControlName: 'blitz3',
        waitSeconds: 16,
      );

      final forced = ChessMatchmakingEngine.selectBestOpponent(
        me: desperateMe,
        candidates: const [waitingGm],
      );
      expect(forced?.userId, 'u2');
    });
  });

  group('ChessController anti-cheat & fair-play rules', () {
    test('aborts online Find Match & Friend Room resigns before 4 half-moves', () {
      ChessUiState? ended;
      final controller = ChessController(
        audio: AudioService(),
        haptics: HapticService()..enabled = false,
        supabase: SupabaseService(),
        autoQueen: true,
        onFinished: (s) => ended = s,
        onAutoSave: (_) {},
      );

      controller.startNew(
        difficulty: DifficultyLevel.pro,
        isPractice: false,
        mode: ChessPlayMode.findMatch,
        colorPref: ChessColorPref.white,
        timeControl: ChessTimeControl.blitz5,
        roomCode: 'MM0001',
        isHost: true,
      );

      expect(controller.state.canPracticeUndo, isFalse);
      controller.resign();
      expect(ended, isNotNull);
      expect(ended!.isAbortedUnrated, isTrue);
      expect(ended!.winnerColour, isNull);
      expect(ended!.isDraw, isFalse);

      // Private friend room is unrated & cannot rank or unlock
      expect(ChessPlayMode.online.isOnlineMultiplayer, isTrue);
      expect(ChessPlayMode.online.isRankedMode, isFalse);
      expect(ChessPlayMode.findMatch.isRankedMode, isTrue);

      controller.dispose();
    });

    test('counts Find Match resign at >= 4 half-moves as normal rated loss', () {
      ChessUiState? ended;
      final controller = ChessController(
        audio: AudioService(),
        haptics: HapticService()..enabled = false,
        supabase: SupabaseService(),
        autoQueen: true,
        onFinished: (s) => ended = s,
        onAutoSave: (_) {},
      );

      final fourPlySlot = AutoSaveSlot(
        gameType: GameType.chess,
        difficulty: DifficultyLevel.pro.level,
        elapsedMs: 12000,
        updatedAt: DateTime(2026, 11, 15),
        stateJson: const {
          'isPractice': false,
          'mode': 'findMatch',
          'timeControl': 'blitz5',
          'playerColor': Bishop.white,
          'pgn': '1. e4 e5 2. Nf3 Nc6',
          'whiteTimeMs': 290000,
          'blackTimeMs': 290000,
          'moveSans': ['e4', 'e5', 'Nf3', 'Nc6'],
        },
      );

      controller.restoreFromSlot(fourPlySlot);
      controller.resume();
      controller.resign();

      expect(ended, isNotNull);
      expect(ended!.isAbortedUnrated, isFalse);
      expect(ended!.winnerColour, Bishop.black);
      controller.dispose();
    });
  });

  testWidgets(
    'ChessScreen Find Match expands live ELO search window and cancels cleanly on 360px phone',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService.forTesting(prefs: prefs);
      final settingsRepo = SettingsRepository(prefs);
      final supa = _FakeMatchmakingSupabaseService();
      final audio = AudioService();

      await tester.binding.setSurfaceSize(const Size(360, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(localStorage),
            settingsRepoProvider.overrideWithValue(settingsRepo),
            supabaseServiceProvider.overrideWithValue(supa),
            audioServiceProvider.overrideWithValue(audio),
          ],
          child: MaterialApp(
            theme: ZetzyThemes.buildTheme(ZetzyThemeMode.oledMidnight),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ChessScreen(difficulty: DifficultyLevel.pro),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Untimed first, then pick Find Match -> auto-switches to Blitz 5m
      await tester.tap(find.text('Untimed'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('chess_mode_findMatch')));
      await tester.pumpAndSettle();

      final untimedChip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('Untimed'),
          matching: find.byType(ChoiceChip),
        ),
      );
      expect(untimedChip.onSelected, isNull);
      expect(find.text('Your ELO: 1200'), findsOneWidget);

      // Start Find Match -> initial stage (±50 around 1200 -> 1150 – 1250)
      final startFindBtn = find.widgetWithText(FilledButton, 'Find Match');
      await tester.ensureVisible(startFindBtn);
      await tester.pumpAndSettle();
      await tester.tap(startFindBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final searchCard = find.byKey(const ValueKey('chess_finding_match_card'));
      await tester.ensureVisible(searchCard);
      await tester.pump();
      expect(searchCard, findsOneWidget);
      expect(find.text('Searching ELO: 1150 – 1250 (±50)'), findsOneWidget);

      // Wait 9s -> expands to Stage 2 (±120 -> 1080 – 1320)
      await tester.pump(const Duration(seconds: 9));
      expect(find.text('Searching ELO: 1080 – 1320 (±120)'), findsOneWidget);

      // Wait 37s more (total 46s) -> unbounded nearest available (400 – 3500)
      await tester.pump(const Duration(seconds: 37));
      expect(
        find.text('Searching ELO: 400 – 3500 (Nearest Available)'),
        findsOneWidget,
      );

      // Cancel search cleanly without leaving open timers
      final cancelBtn = find.widgetWithText(OutlinedButton, 'Cancel');
      await tester.ensureVisible(cancelBtn);
      await tester.pump();
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();
      expect(supa.cancelCalls, greaterThanOrEqualTo(1));
      expect(find.byKey(const ValueKey('chess_finding_match_card')), findsNothing);
    },
  );
}
