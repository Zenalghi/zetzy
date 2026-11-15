import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zetzy/app.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/routing/app_router.dart';
import 'package:zetzy/core/services/audio_service.dart';
import 'package:zetzy/core/services/avatar_picker_service.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/core/widgets/platform_badge.dart';
import 'package:zetzy/core/widgets/user_avatar.dart';
import 'package:zetzy/core/widgets/win_result_dialog.dart';
import 'package:zetzy/data/local/local_storage_service.dart';
import 'package:zetzy/data/local/settings_repository.dart';
import 'package:zetzy/data/models/game_record.dart';
import 'package:zetzy/data/models/user_profile.dart';
import 'package:zetzy/data/remote/supabase_service.dart';
import 'package:zetzy/features/games/chess/chess_screen.dart';
import 'package:zetzy/features/games/minesweeper/minesweeper_screen.dart';
import 'package:zetzy/features/games/sudoku/sudoku_screen.dart';
import 'package:zetzy/features/leaderboard/leaderboard_screen.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

class _FakeAvailableSupabaseService extends SupabaseService {
  bool shouldFailNextRegister = false;

  @override
  bool get isAvailable => true;

  @override
  Future<UserProfile?> fetchCurrentProfile() async => null;

  @override
  Future<UserProfile> register({
    required String username,
    required String password,
    String? recoveryPhrase,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (shouldFailNextRegister) {
      throw const AuthException('Username already taken');
    }
    return UserProfile(id: 'u-1', username: username, isGuest: false);
  }

  Uint8List? lastUploadedBytes;

  @override
  Future<String> uploadAvatar(Uint8List rawBytes) async {
    lastUploadedBytes = rawBytes;
    return 'https://example.supabase.co/storage/v1/object/public/avatars/u-1/avatar.png';
  }
}

class _FakeAvatarPickerService extends AvatarPickerService {
  _FakeAvatarPickerService(this.fakeBytes);

  final Uint8List? fakeBytes;
  bool mobileCamera = false;
  AvatarPickSource? lastSource;

  @override
  bool get supportsCameraChoice => mobileCamera;

  @override
  Future<Uint8List?> pickImageBytes({
    AvatarPickSource source = AvatarPickSource.gallery,
  }) async {
    lastSource = source;
    return fakeBytes;
  }

  @override
  Future<Uint8List?> retrieveLostAndroidBytes() async => null;
}

void main() {
  testWidgets('ZetzyApp renders 4 games and navigates across all 4 tabs', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService.forTesting(prefs: prefs);
    final settingsRepo = SettingsRepository(prefs);
    final supa = SupabaseService();
    final audio = AudioService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepoProvider.overrideWithValue(settingsRepo),
          supabaseServiceProvider.overrideWithValue(supa),
          audioServiceProvider.overrideWithValue(audio),
        ],
        child: const ZetzyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Zetzy'), findsOneWidget);
    expect(find.text('Sudoku'), findsOneWidget);
    expect(find.text('Chess'), findsOneWidget);
    expect(find.text('Minesweeper'), findsOneWidget);
    expect(find.text('Snake'), findsOneWidget);

    // Tap Difficulty Selector on Sudoku
    await tester.tap(find.text('Sudoku'));
    await tester.pumpAndSettle();
    expect(find.text('1. Chill'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('7. Are U a God?'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('7. Are U a God?'), findsOneWidget);
    expect(find.text('Practice Mode'), findsOneWidget);

    // Close selector
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Navigate to Profile/Settings & switch language to Indonesian
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Theme Skin'), findsOneWidget);

    await tester.tap(find.text('Indonesia'));
    await tester.pumpAndSettle();
    expect(find.text('Skin Tema'), findsOneWidget);
    expect(find.text('View Supabase SQL Schema'), findsNothing);
    expect(find.text('Lihat Skema SQL Supabase'), findsNothing);
  });

  testWidgets('ProfileScreen enables Sign In and Create Account when cloud is available', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService.forTesting(prefs: prefs);
    final settingsRepo = SettingsRepository(prefs);
    final supa = _FakeAvailableSupabaseService();
    final audio = AudioService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepoProvider.overrideWithValue(settingsRepo),
          supabaseServiceProvider.overrideWithValue(supa),
          audioServiceProvider.overrideWithValue(audio),
        ],
        child: const ZetzyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('View Supabase SQL Schema'), findsNothing);

    final signInBtn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Sign In'),
    );
    final registerBtn = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Create Account'),
    );
    expect(signInBtn.onPressed, isNotNull);
    expect(registerBtn.onPressed, isNotNull);

    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
    expect(find.text('* Required'), findsOneWidget);
    expect(find.text('Username *'), findsOneWidget);
    expect(find.text('Password *'), findsOneWidget);
    expect(find.text('Recovery Code / Passphrase (Optional)'), findsOneWidget);

    // Enter valid credentials and test error + success flow cleanly
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'zetzy_player');
    await tester.enterText(fields.at(1), 'secret123');

    supa.shouldFailNextRegister = true;
    await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
    await tester.pumpAndSettle();
    expect(find.text('Username already taken'), findsOneWidget);

    supa.shouldFailNextRegister = false;
    await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
    await tester.pumpAndSettle();
    expect(find.text('@zetzy_player'), findsOneWidget);
  });

  testWidgets('SudokuScreen renders uniform 9x9 cells, fills empty cell, and disposes safely', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService.forTesting(prefs: prefs);
    final settingsRepo = SettingsRepository(prefs);
    final supa = SupabaseService();
    final audio = AudioService();

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
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SudokuScreen(
                          difficulty: DifficultyLevel.easy,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Sudoku'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Sudoku'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    // Every empty cell (SizedBox.expand inside cell GestureDetector) must have full non-zero height.
    final emptyCells = find.byWidgetPredicate(
      (w) => w is SizedBox && w.width == double.infinity && w.height == double.infinity,
    );
    expect(emptyCells, findsWidgets);
    final firstEmptySize = tester.getSize(emptyCells.first);
    expect(firstEmptySize.width, greaterThan(40));
    expect(firstEmptySize.height, greaterThan(40));

    // Tap empty cell then tap digit '1' from digit pad
    final emptyCellTapTarget = find
        .ancestor(of: emptyCells.first, matching: find.byType(GestureDetector))
        .first;
    await tester.tap(emptyCellTapTarget);
    await tester.pump();
    await tester.tap(find.text('1').last);
    await tester.pump();

    // Pop SudokuScreen back to verify dispose() does not throw ref-after-unmount error
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Open Sudoku'), findsOneWidget);
  });

  testWidgets('MinesweeperScreen renders without RenderFlex overflow on wide and narrow screens', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService.forTesting(prefs: prefs);
    final settingsRepo = SettingsRepository(prefs);
    final supa = SupabaseService();
    final audio = AudioService();

    Widget buildApp() => ProviderScope(
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
        home: const MinesweeperScreen(difficulty: DifficultyLevel.chill),
      ),
    );

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Defuse Shield Ready'), findsOneWidget);
    expect(find.text('Mark (?)'), findsOneWidget);

    // Narrow mobile layout (< 760px)
    tester.view.physicalSize = const Size(360, 740);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('ProfileScreen handles guest hint and cross-platform avatar upload', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService.forTesting(prefs: prefs);
    final settingsRepo = SettingsRepository(prefs);
    final supa = _FakeAvailableSupabaseService();
    final audio = AudioService();

    final sampleImg = img.Image(width: 64, height: 64);
    img.fill(sampleImg, color: img.ColorRgb8(90, 140, 220));
    final sampleBytes = Uint8List.fromList(img.encodePng(sampleImg));
    final fakePicker = _FakeAvatarPickerService(sampleBytes);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepoProvider.overrideWithValue(settingsRepo),
          supabaseServiceProvider.overrideWithValue(supa),
          audioServiceProvider.overrideWithValue(audio),
          avatarPickerServiceProvider.overrideWithValue(fakePicker),
        ],
        child: const ZetzyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Tapping avatar as guest shows clear guidance instead of doing nothing.
    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();
    expect(
      find.text('Sign in or create an account to upload a profile photo.'),
      findsOneWidget,
    );

    // Register account, then upload avatar cleanly via picker service.
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'avatar_user');
    await tester.enterText(fields.at(1), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Upload Avatar'));
    await tester.pumpAndSettle();
    expect(fakePicker.lastSource, equals(AvatarPickSource.gallery));
    expect(supa.lastUploadedBytes, equals(sampleBytes));
    expect(find.text('Profile photo updated!'), findsOneWidget);

    // Verify mobile camera/gallery bottom sheet flow as well.
    fakePicker.mobileCamera = true;
    await tester.tap(find.byTooltip('Upload Avatar'));
    await tester.pumpAndSettle();
    expect(find.text('Choose from Gallery / Photos'), findsOneWidget);
    expect(find.text('Take Photo with Camera'), findsOneWidget);
    await tester.tap(find.text('Take Photo with Camera'));
    await tester.pumpAndSettle();
    expect(fakePicker.lastSource, equals(AvatarPickSource.camera));
  });

  testWidgets('AppRouter supports deep-linked tab and deferred game routes', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService.forTesting(prefs: prefs);
    final settingsRepo = SettingsRepository(prefs);
    final supa = SupabaseService();
    final audio = AudioService();

    final navKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepoProvider.overrideWithValue(settingsRepo),
          supabaseServiceProvider.overrideWithValue(supa),
          audioServiceProvider.overrideWithValue(audio),
        ],
        child: MaterialApp(
          navigatorKey: navKey,
          theme: ZetzyThemes.buildTheme(ZetzyThemeMode.oledMidnight),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          initialRoute: AppRouter.leaderboard,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Global Top 100'), findsOneWidget);

    navKey.currentState!.pushNamed('${AppRouter.minesweeper}?level=2&practice=1');
    await tester.pumpAndSettle();
    expect(find.textContaining('Minesweeper • Easy'), findsOneWidget);
  });

  testWidgets('ChessScreen pre-match lobby shows dynamic mode info card below TactileCard', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService.forTesting(prefs: prefs);
    final settingsRepo = SettingsRepository(prefs);
    final supa = SupabaseService();
    final audio = AudioService();

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
          home: const ChessScreen(difficulty: DifficultyLevel.normal),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final infoCard = find.byKey(const ValueKey('chess_mode_info_card'));
    expect(infoCard, findsOneWidget);
    expect(find.text('Ranked • ELO vs AI & Leaderboard'), findsOneWidget);

    // Ensure the info card is positioned below the main setup TactileCard
    final infoRect = tester.getRect(infoCard);
    final modeSegmentRect = tester.getRect(find.text('Vs AI'));
    expect(infoRect.top, greaterThan(modeSegmentRect.bottom));

    // Switching to Pass & Play updates the summary dynamically
    await tester.tap(find.text('Pass & Play'));
    await tester.pumpAndSettle();
    expect(find.text('Local 2-Player • Unrated (No ELO/Score)'), findsOneWidget);

    await tester.tap(infoCard);
    await tester.pumpAndSettle();
    expect(find.text('Match Rules & Scoring'), findsOneWidget);
    expect(find.textContaining('Blitz 5m'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Switching to Online Room shows room ELO guide
    await tester.tap(find.text('Online Room'));
    await tester.pumpAndSettle();
    expect(find.text('Online 1v1 • Rated ELO via Room Code'), findsOneWidget);

    await tester.tap(infoCard);
    await tester.pumpAndSettle();
    expect(find.textContaining('Supabase Realtime'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Starting Pass & Play enters active board cleanly without overflow
    await tester.tap(find.text('Pass & Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chess • Normal'), findsOneWidget);
  });

  testWidgets('WinResultDialog shows Back to Menu clearly on compact Nordic Frost screens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 560);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var exited = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ZetzyThemes.buildTheme(ZetzyThemeMode.nordicFrost),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  showGameResultDialog(
                    context: context,
                    gameType: GameType.sudoku,
                    difficulty: DifficultyLevel.pro,
                    isWon: false,
                    durationMs: 42000,
                    score: 0,
                    extraMetrics: const [
                      (label: 'Lives', value: '0/3'),
                      (label: 'Mistakes', value: '3'),
                    ],
                    onPlayAgain: () {},
                    onExit: () => exited = true,
                  );
                },
                child: const Text('Show Result'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Result'));
    await tester.pumpAndSettle();

    final backButton = find.widgetWithText(OutlinedButton, 'Back to Menu');
    expect(backButton, findsOneWidget);
    final rect = tester.getRect(backButton);
    expect(rect.bottom, lessThanOrEqualTo(560));

    await tester.tap(backButton);
    await tester.pumpAndSettle();
    expect(exited, isTrue);
  });

  testWidgets('Home dashboard and Leaderboard Global/My Best render UserAvatar and inline PlatformBadge', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService.forTesting(prefs: prefs);
    final settingsRepo = SettingsRepository(prefs);
    final supa = _FakeLeaderboardSupabaseService();
    final audio = AudioService();

    await localStorage.saveLocalRecord(
      GameRecord(
        id: 'loc-1',
        userId: 'guest',
        username: 'guest',
        gameType: GameType.sudoku,
        difficulty: 3,
        isWon: true,
        score: 100,
        durationMs: 25000,
        platform: 'windows',
        playedAt: DateTime(2026, 11, 15),
      ),
    );

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
          home: const ZetzyApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Dashboard Play displays UserAvatar in the header profile pill
    expect(find.byType(UserAvatar), findsOneWidget);

    // Navigate to Leaderboard tab -> Global Top 100
    await tester.tap(find.text('Leaderboard'));
    await tester.pumpAndSettle();

    expect(find.text('@global_pro'), findsOneWidget);
    final globalAvatarRect = tester.getRect(
      find.descendant(
        of: find.byType(LeaderboardScreen),
        matching: find.byType(UserAvatar),
      ).first,
    );
    final globalNameRect = tester.getRect(find.text('@global_pro'));
    final globalBadgeRect = tester.getRect(
      find.descendant(
        of: find.byType(LeaderboardScreen),
        matching: find.byType(PlatformBadge),
      ).first,
    );
    // Profile photo on the left, platform badge moved next to username on the right
    expect(globalAvatarRect.right, lessThan(globalNameRect.left));
    expect(globalBadgeRect.left, greaterThan(globalNameRect.right));

    // Switch to My Best tab and verify same avatar + inline platform badge layout
    await tester.tap(find.text('My Best'));
    await tester.pumpAndSettle();
    expect(find.text('@guest'), findsOneWidget);
    final myAvatarRect = tester.getRect(
      find.descendant(
        of: find.byType(LeaderboardScreen),
        matching: find.byType(UserAvatar),
      ).first,
    );
    final myNameRect = tester.getRect(find.text('@guest'));
    final myBadgeRect = tester.getRect(
      find.descendant(
        of: find.byType(LeaderboardScreen),
        matching: find.byType(PlatformBadge),
      ).first,
    );
    expect(myAvatarRect.right, lessThan(myNameRect.left));
    expect(myBadgeRect.left, greaterThan(myNameRect.right));
  });
}

class _FakeLeaderboardSupabaseService extends _FakeAvailableSupabaseService {
  @override
  Future<List<GameRecord>> fetchGlobalLeaderboard({
    required GameType gameType,
    required int difficulty,
  }) async {
    return [
      GameRecord(
        id: 'glb-1',
        userId: 'u-global',
        username: 'global_pro',
        gameType: gameType,
        difficulty: difficulty,
        isWon: true,
        score: 250,
        durationMs: 18000,
        platform: 'android',
        playedAt: DateTime(2026, 11, 15),
      ),
    ];
  }
}
