import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zetzy/app.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/routing/app_router.dart';
import 'package:zetzy/core/widgets/difficulty_badge.dart';
import 'package:zetzy/core/widgets/game_type_icon.dart';
import 'package:zetzy/core/services/audio_service.dart';
import 'package:zetzy/core/services/avatar_picker_service.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/core/widgets/platform_badge.dart';
import 'package:zetzy/core/widgets/user_avatar.dart';
import 'package:zetzy/core/widgets/win_result_dialog.dart';
import 'package:zetzy/data/local/local_storage_service.dart';
import 'package:zetzy/data/local/settings_repository.dart';
import 'package:zetzy/data/models/auto_save_slot.dart';
import 'package:zetzy/data/models/feedback_entry.dart';
import 'package:zetzy/data/models/game_record.dart';
import 'package:zetzy/data/models/stats_summary.dart';
import 'package:zetzy/data/models/user_profile.dart';
import 'package:zetzy/data/remote/supabase_service.dart';
import 'package:zetzy/features/games/chess/chess_screen.dart';
import 'package:zetzy/features/games/minesweeper/minesweeper_screen.dart';
import 'package:zetzy/features/games/sudoku/sudoku_screen.dart';
import 'package:zetzy/features/home/home_screen.dart';
import 'package:zetzy/features/leaderboard/leaderboard_screen.dart';
import 'package:zetzy/features/shell/main_shell.dart';
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

  @override
  Future<void> signOut() async {}
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

    // Switching to Find Match shows dynamic ELO matchmaking guide
    await tester.tap(find.text('Find Match'));
    await tester.pumpAndSettle();
    expect(
      find.text('Ranked Random 1v1 • Dynamic ELO Matchmaking'),
      findsOneWidget,
    );

    await tester.tap(infoCard);
    await tester.pumpAndSettle();
    expect(find.textContaining('Expanding ELO Window'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Switching to Online Room shows unrated friend-room anti-cheat guide
    await tester.tap(find.text('Online Room'));
    await tester.pumpAndSettle();
    expect(find.text('Friend Room 1v1 • Unrated (Anti-Cheat)'), findsOneWidget);

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
          home: const MainShell(),
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

  testWidgets('ProfileScreen collapses account actions into Configure Account dialog', (
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
        child: MaterialApp(
          theme: ZetzyThemes.buildTheme(ZetzyThemeMode.oledMidnight),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MainShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Create Account'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'cfg_user');
    await tester.enterText(fields.at(1), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
    await tester.pumpAndSettle();

    // Only single Configure Account button is shown inline; the 3 actions are inside its dialog.
    expect(find.text('Configure Account'), findsOneWidget);
    expect(find.text('Change Username'), findsNothing);
    expect(find.text('Change Password'), findsNothing);
    expect(find.text('Sign Out'), findsNothing);

    await tester.tap(find.text('Configure Account'));
    await tester.pumpAndSettle();

    expect(find.text('Change Username'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);

    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('Home and Leaderboard use themed bP SVG icon for Chess', (
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
        child: MaterialApp(
          theme: ZetzyThemes.buildTheme(ZetzyThemeMode.draculaNeon),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MainShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Home dashboard uses bP SVG tinted with active theme's accentSecondary
    final homePawnSvg = tester.widget<SvgPicture>(
      find.descendant(
        of: find.byType(HomeScreen),
        matching: find.byType(SvgPicture),
      ),
    );
    expect(
      (homePawnSvg.bytesLoader as SvgAssetLoader).assetName,
      equals(AssetPaths.chessPawn),
    );
    expect(
      homePawnSvg.colorFilter,
      equals(
        ColorFilter.mode(
          ZetzyThemes.paletteFor(ZetzyThemeMode.draculaNeon).accentSecondary,
          BlendMode.srcIn,
        ),
      ),
    );
    expect(find.byIcon(Icons.castle_rounded), findsNothing);

    // Leaderboard tab renders themed bP SVG in both Chess ELO segment and Chess chip
    await tester.tap(find.text('Leaderboard'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(LeaderboardScreen),
        matching: find.byWidgetPredicate(
          (w) => w is GameTypeIcon && w.game == GameType.chess,
        ),
      ),
      findsNWidgets(2),
    );
    expect(find.byIcon(Icons.castle_rounded), findsNothing);
  });

  testWidgets('WinResultDialog shows Rewind N & Continue on Practice loss and triggers callback', (
    WidgetTester tester,
  ) async {
    var rewound = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ZetzyThemes.buildTheme(ZetzyThemeMode.oledMidnight),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  showGameResultDialog(
                    context: context,
                    gameType: GameType.minesweeper,
                    difficulty: DifficultyLevel.pro,
                    isWon: false,
                    isPractice: true,
                    durationMs: 19000,
                    score: 0,
                    rewindSteps: 3,
                    onRewindContinue: () => rewound = true,
                    onPlayAgain: () {},
                    onExit: () {},
                  );
                },
                child: const Text('Open Result'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Result'));
    await tester.pumpAndSettle();

    final rewindBtn = find.text('Rewind 3 & Continue');
    expect(rewindBtn, findsOneWidget);
    await tester.tap(rewindBtn);
    await tester.pumpAndSettle();
    expect(rewound, isTrue);
  });

  testWidgets('ProfileScreen configures Practice Rewind on Loss toggle and step selector locally', (
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
        child: MaterialApp(
          theme: ZetzyThemes.buildTheme(ZetzyThemeMode.oledMidnight),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MainShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('3 Steps'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('3 Steps'));
    await tester.pumpAndSettle();
    expect(find.text('Practice Rewind on Loss'), findsOneWidget);
    expect(find.text('1 Step'), findsOneWidget);
    expect(find.text('2 Steps'), findsOneWidget);
    expect(find.text('3 Steps'), findsOneWidget);

    await tester.tap(find.text('3 Steps'));
    await tester.pumpAndSettle();
    expect(settingsRepo.load().practiceRewindSteps, equals(3));

    await tester.scrollUntilVisible(
      find.text('Practice Rewind on Loss'),
      -100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('Practice Rewind on Loss'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Practice Rewind on Loss'));
    await tester.pumpAndSettle();
    expect(settingsRepo.load().practiceRewindOnLoss, isFalse);
    expect(find.text('Rewind Steps on Loss'), findsNothing);
  });

  testWidgets('SudokuScreen and MinesweeperScreen expose Practice Undo controls when isPractice is true', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService.forTesting(prefs: prefs);
    final settingsRepo = SettingsRepository(prefs);
    final supa = SupabaseService();
    final audio = AudioService();

    Widget wrap(Widget home) => ProviderScope(
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
        home: home,
      ),
    );

    await tester.pumpWidget(
      wrap(
        const MinesweeperScreen(
          difficulty: DifficultyLevel.easy,
          isPractice: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.undo_rounded), findsWidgets);

    await tester.pumpWidget(
      wrap(
        const SudokuScreen(
          difficulty: DifficultyLevel.easy,
          isPractice: true,
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('Undo Notes'), findsNothing);
  });

  testWidgets('ProfileScreen displays pubspec app version quietly at bottom while Home omits it', (
    WidgetTester tester,
  ) async {
    PackageInfo.setMockInitialValues(
      appName: 'Zetzy',
      packageName: 'com.example.zetzy',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );

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

    // Home must not display the app version footer.
    expect(find.text('Zetzy v1.0.0'), findsNothing);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Zetzy v1.0.0'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Zetzy v1.0.0'), findsOneWidget);
  });

  testWidgets('WinResultDialog shows View Board button and enters post-game review without exiting', (
    WidgetTester tester,
  ) async {
    var reviewed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ZetzyThemes.buildTheme(ZetzyThemeMode.oledMidnight),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  showGameResultDialog(
                    context: context,
                    gameType: GameType.minesweeper,
                    difficulty: DifficultyLevel.normal,
                    isWon: false,
                    durationMs: 12000,
                    score: 0,
                    onReviewBoard: () => reviewed = true,
                    onPlayAgain: () {},
                    onExit: () {},
                  );
                },
                child: const Text('Open Result'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Result'));
    await tester.pumpAndSettle();

    final viewBoardBtn = find.widgetWithText(OutlinedButton, 'View Board');
    expect(viewBoardBtn, findsOneWidget);

    await tester.tap(viewBoardBtn);
    await tester.pumpAndSettle();

    expect(reviewed, isTrue);
    expect(find.widgetWithText(OutlinedButton, 'View Board'), findsNothing);
    expect(find.text('Open Result'), findsOneWidget);
  });

  testWidgets('ChessScreen enters post-game review scrubber and re-opens result dialog via View Result', (
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
        child: MaterialApp(
          theme: ZetzyThemes.buildTheme(ZetzyThemeMode.oledMidnight),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ChessScreen(
            difficulty: DifficultyLevel.pro,
            isPractice: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Pass & Play + Untimed in lobby so there is no countdown timer.
    await tester.tap(find.text('Pass & Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Untimed'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Play'));
    await tester.pumpAndSettle();

    // Resign immediately -> WinResultDialog opens with View Board.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Resign'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'View Board'));
    await tester.pumpAndSettle();

    // Post-game review bar replaces active controls and allows re-opening Result.
    expect(find.text('Ply 0/0'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'View Result'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'View Result'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, 'View Board'), findsOneWidget);
  });

  testWidgets('ProfileScreen groups game settings into per-game cards and updates Auto-Finish threshold', (
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
        child: MaterialApp(
          theme: ZetzyThemes.buildTheme(ZetzyThemeMode.oledMidnight),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MainShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Verify per-game cards & new toggles
    Future<void> scrollTo(Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        220,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
    }

    await scrollTo(find.text('Background Music (BGM)'));
    expect(find.text('Background Music (BGM)'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget);
    expect(find.text('Auto'), findsOneWidget);
    expect(find.text('Manual'), findsOneWidget);
    await tester.tap(find.text('Manual'));
    await tester.pumpAndSettle();
    expect(settingsRepo.load().bgmMode, equals(BgmMode.manual));
    await scrollTo(find.text('Track 3'));
    await tester.tap(find.text('Track 3'));
    await tester.pumpAndSettle();
    expect(settingsRepo.load().bgmTrack, equals('3.mp3'));
    await scrollTo(find.text('Off'));
    await tester.tap(find.text('Off'));
    await tester.pumpAndSettle();
    expect(settingsRepo.load().bgmMode, equals(BgmMode.off));

    await scrollTo(find.text('Vibration Strength'));
    expect(find.text('Vibration Strength'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Strong'), findsOneWidget);
    await tester.tap(find.text('Strong'));
    await tester.pumpAndSettle();
    expect(settingsRepo.load().hapticIntensity, equals(HapticIntensity.strong));

    await scrollTo(find.text('Auto-Finish Endgame'));
    expect(find.text('Auto-Finish Endgame'), findsOneWidget);
    expect(find.text('5 Cells'), findsOneWidget);
    expect(find.text('7 Cells'), findsOneWidget);
    await tester.tap(find.text('7 Cells'));
    await tester.pumpAndSettle();
    expect(settingsRepo.load().sudokuAutoFinishThreshold, equals(7));

    await scrollTo(find.text('Show Board Coordinates'));
    expect(find.text('Show Legal Move Hints'), findsOneWidget);
    expect(find.text('Show Board Coordinates'), findsOneWidget);

    await scrollTo(find.text('Tap Number to Chord'));
    expect(find.text('Tap Number to Chord'), findsOneWidget);

    await scrollTo(find.text('Show Arena Grid Lines'));
    expect(find.text('Show Arena Grid Lines'), findsOneWidget);

    await scrollTo(find.text('Practice Mode'));
    expect(find.text('Practice Mode'), findsOneWidget);
  });

  testWidgets('SudokuScreen opens mid-game Quick Settings safely and shows Auto-Finish with bolt icon', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService.forTesting(prefs: prefs);
    final settingsRepo = SettingsRepository(prefs);
    final supa = SupabaseService();
    final audio = AudioService();

    const solution = <int>[
      5, 3, 4, 6, 7, 8, 9, 1, 2,
      6, 7, 2, 1, 9, 5, 3, 4, 8,
      1, 9, 8, 3, 4, 2, 5, 6, 7,
      8, 5, 9, 7, 6, 1, 4, 2, 3,
      4, 2, 6, 8, 5, 3, 7, 9, 1,
      7, 1, 3, 9, 2, 4, 8, 5, 6,
      9, 6, 1, 5, 3, 7, 2, 8, 4,
      2, 8, 7, 4, 1, 9, 6, 3, 5,
      3, 4, 5, 2, 8, 6, 1, 7, 9,
    ];
    final board = List<int>.from(solution);
    for (final i in const [0, 1, 10, 20, 30]) {
      board[i] = 0;
    }

    final slot = AutoSaveSlot(
      gameType: GameType.sudoku,
      difficulty: DifficultyLevel.pro.level,
      elapsedMs: 15000,
      updatedAt: DateTime(2026, 11, 15),
      stateJson: {
        'isPractice': false,
        'givens': board,
        'values': List<int>.from(board),
        'solution': solution,
        'notes': List.generate(81, (_) => const <int>[]),
        'errorCells': const <int>[],
        'livesLeft': 3,
        'mistakes': 0,
        'hintsLeft': 3,
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('admin-scope'),
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
          home: SudokuScreen(
            difficulty: DifficultyLevel.pro,
            resumeSlot: slot,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Resumed slot starts paused -> resume to play.
    await tester.tap(find.text('Resume'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Auto-Finish (5) with left thunder icon is visible.
    expect(find.text('Auto-Finish (5)'), findsOneWidget);
    expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);

    // Open mid-game Quick Settings from AppBar gear icon.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Quick Settings • Sudoku'), findsOneWidget);
    expect(find.text('Auto-Finish Endgame'), findsOneWidget);
    expect(find.text('Highlight Matching Digits'), findsOneWidget);

    // Non-live / unrelated controls must not be exposed mid-game.
    expect(find.text('Practice Mode'), findsNothing);
    expect(find.text('Tap Number to Chord'), findsNothing);
    expect(find.text('Show Arena Grid Lines'), findsNothing);
    expect(find.text('Reset All Statistics'), findsNothing);

    // Toggle Highlight Matching Digits inside sheet and close.
    await tester.tap(find.text('Highlight Matching Digits'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(settingsRepo.load().sudokuHighlightSameDigits, isFalse);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Quick Settings • Sudoku'), findsNothing);

    // Trigger Auto-Finish with 5 empty cells remaining -> stops timer, shows dialog.
    // Note: ConfettiWidget on WinResultDialog keeps an active physics ticker while mounted,
    // so pump explicit durations instead of pumpAndSettle().
    await tester.tap(find.text('Auto-Finish (5)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();

    expect(find.text('View Board'), findsOneWidget);
    expect(find.text('Play Again'), findsWidgets);
  });

  testWidgets('SudokuScreen renders Streak/Accuracy HUD and Smart Notes gated to Beginner/Practice', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService.forTesting(prefs: prefs);
    final settingsRepo = SettingsRepository(prefs);
    final supa = SupabaseService();
    final audio = AudioService();

    const solution = <int>[
      5, 3, 4, 6, 7, 8, 9, 1, 2,
      6, 7, 2, 1, 9, 5, 3, 4, 8,
      1, 9, 8, 3, 4, 2, 5, 6, 7,
      8, 5, 9, 7, 6, 1, 4, 2, 3,
      4, 2, 6, 8, 5, 3, 7, 9, 1,
      7, 1, 3, 9, 2, 4, 8, 5, 6,
      9, 6, 1, 5, 3, 7, 2, 8, 4,
      2, 8, 7, 4, 1, 9, 6, 3, 5,
      3, 4, 5, 2, 8, 6, 1, 7, 9,
    ];
    final board = List<int>.from(solution)
      ..[0] = 0
      ..[1] = 0;

    final easySlot = AutoSaveSlot(
      gameType: GameType.sudoku,
      difficulty: DifficultyLevel.easy.level,
      elapsedMs: 5000,
      updatedAt: DateTime(2026, 11, 15),
      stateJson: {
        'isPractice': false,
        'givens': board,
        'values': List<int>.from(board),
        'solution': solution,
        'notes': List.generate(81, (_) => const <int>[]),
        'errorCells': const <int>[],
        'livesLeft': 3,
        'mistakes': 0,
        'hintsLeft': 3,
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('admin-scope'),
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
          home: SudokuScreen(
            difficulty: DifficultyLevel.easy,
            resumeSlot: easySlot,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resume'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Streak 0'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Smart Notes'), findsOneWidget);

    await tester.tap(find.text('Smart Notes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Candidate note digits '5' and '3' appear cleanly after fillSmartCandidates
    expect(find.text('5'), findsWidgets);

    // Quick Settings exposes Streak stats & enabled Smart Candidate Notes
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Mistake-Free Streak & Accuracy'), findsOneWidget);
    expect(find.text('Smart Candidate Notes'), findsOneWidget);
  });

  testWidgets('MinesweeperScreen toggles 1-Tap Swap without overflow on narrow screens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
          home: const MinesweeperScreen(difficulty: DifficultyLevel.easy),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1-Tap: Dig'), findsOneWidget);
    await tester.tap(find.text('1-Tap: Dig'));
    await tester.pumpAndSettle();

    expect(find.text('1-Tap: Flag'), findsOneWidget);
    expect(settingsRepo.load().minesweeperSwapTapFlag, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ChessScreen AppBar exposes Flip toggle and Touch Move Confirmation bar works', (
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
        child: MaterialApp(
          theme: ZetzyThemes.buildTheme(ZetzyThemeMode.oledMidnight),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ChessScreen(
            difficulty: DifficultyLevel.normal,
            isPractice: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pass & Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Untimed'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Play'));
    await tester.pumpAndSettle();

    // AppBar has accessible 1-tap Flip button
    expect(find.byIcon(Icons.swap_vert_rounded), findsWidgets);

    // Enable Always Move Confirmation via Quick Settings
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Always'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Tap e2 (visualCol 4, visualRow 6) -> e4 (visualCol 4, visualRow 4)
    final boardRect = tester.getRect(find.byType(AspectRatio).first);
    Offset squareCenter(int visualCol, int visualRow) => Offset(
      boardRect.left + (visualCol + 0.5) * (boardRect.width / 8),
      boardRect.top + (visualRow + 0.5) * (boardRect.height / 8),
    );

    await tester.tapAt(squareCenter(4, 6));
    await tester.pump();
    await tester.tapAt(squareCenter(4, 4));
    await tester.pumpAndSettle();

    expect(find.text('Confirm e4?'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Confirm e4?'), findsNothing);
    expect(find.text('e4'), findsOneWidget);
  });

  testWidgets('ProfileScreen Rank Badges showcase enlarges crest modal with 4-game status and DifficultySelector previews tier', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService.forTesting(prefs: prefs);
    await localStorage.saveLocalRecord(
      GameRecord(
        id: 'won-pro-1',
        userId: 'guest',
        username: 'guest',
        gameType: GameType.sudoku,
        difficulty: DifficultyLevel.pro.level,
        isWon: true,
        score: 420,
        durationMs: 25000,
        platform: 'android',
        playedAt: DateTime(2026, 11, 16),
      ),
    );
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

    // Verify DifficultySelector shows live Selected Tier crest preview
    await tester.tap(find.text('Sudoku'));
    await tester.pumpAndSettle();
    expect(find.text('Selected Tier'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is DifficultyBadgeImage && w.size == 56,
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('5. PRO'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('5. PRO'));
    await tester.pumpAndSettle();
    expect(find.text('+175 XP'), findsWidgets);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Navigate to Profile -> verifies Account highest badge & 7-tier Rank Badges showcase
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Rank Badges'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Rank Badges'), findsOneWidget);
    expect(find.text('1/7 Conquered'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('PRO'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('PRO'));
    await tester.pumpAndSettle();
    expect(find.text('1/4 ✓'), findsOneWidget);

    // Tap PRO crest to open crisp 160px Zoom Inspect Modal + 4 per-game chips
    await tester.tap(find.text('PRO'));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (w) => w is DifficultyBadgeImage && w.size == 160,
      ),
      findsOneWidget,
    );
    expect(find.text('5. PRO'), findsOneWidget);
    expect(find.text('1× Won'), findsOneWidget);
    expect(find.text('Sudoku'), findsOneWidget);
    expect(find.text('Chess'), findsOneWidget);
    expect(find.text('Minesweeper'), findsOneWidget);
    expect(find.text('Snake'), findsOneWidget);

    // Carousel next arrow previews 6. Nightmare
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(find.text('6. Nightmare'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
  });

  testWidgets('WinResultDialog spotlights large crisp difficulty badge on victory', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ZetzyThemes.buildTheme(ZetzyThemeMode.oledMidnight),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  showGameResultDialog(
                    context: context,
                    gameType: GameType.minesweeper,
                    difficulty: DifficultyLevel.god,
                    isWon: true,
                    durationMs: 31200,
                    score: 180,
                    onPlayAgain: () {},
                    onExit: () {},
                  );
                },
                child: const Text('Show Win'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Win'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is DifficultyBadgeImage &&
            w.difficulty == DifficultyLevel.god &&
            w.size == 92,
      ),
      findsOneWidget,
    );
    expect(find.text('Victory!'), findsOneWidget);
  });

  testWidgets('ZetzyApp unlocks deferred Web BGM on first pointer interaction', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService.forTesting(prefs: prefs);
    final settingsRepo = SettingsRepository(prefs);
    final supa = SupabaseService();
    final playedTracks = <String>[];
    final audio = AudioService(
      waitForUserGestureBeforeBgm: true,
      onPlayBgm: (assetPath, {required bool loop}) async {
        playedTracks.add(assetPath);
      },
    )..setAvailableAssetsForTest({
        'assets/audio/mp3/bgm/5.mp3',
      });

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

    // Renders home immediately while still waiting for first user gesture
    expect(find.text('Zetzy'), findsOneWidget);
    expect(audio.isAwaitingUserGesture, isTrue);
    expect(playedTracks, isEmpty);

    // Tapping anywhere in the app unlocks audio playback cleanly
    await tester.tap(find.text('Zetzy'));
    await tester.pumpAndSettle();

    expect(audio.isAwaitingUserGesture, isFalse);
    expect(audio.isBgmPlaying, isTrue);
    expect(playedTracks, equals(['audio/mp3/bgm/5.mp3']));
  });

  testWidgets('ProfileScreen exposes 6 themes (Abyssal Cyan & Warm Parchment) and expanded equal-width segmented controls', (
    WidgetTester tester,
  ) async {
    expect(ZetzyThemeMode.values.length, equals(6));
    final cyanNormal = ZetzyThemes.paletteFor(ZetzyThemeMode.abyssalCyan);
    expect(cyanNormal.background, equals(const Color(0xFF060A0B)));
    expect(cyanNormal.surfaceElevated, equals(const Color(0xFF00393D)));
    expect(cyanNormal.accent, equals(const Color(0xFF1ECAD6)));

    final cyanAlter = ZetzyThemes.paletteFor(
      ZetzyThemeMode.abyssalCyan,
      abyssalAlterEgo: true,
    );
    expect(cyanAlter.background, equals(const Color(0xFF001C1C)));
    expect(cyanAlter.textPrimary, equals(const Color(0xFFD9EEEE)));
    expect(cyanAlter.accent, equals(const Color(0xFF80C5C5)));
    expect(cyanAlter.snakeBody, equals(const Color(0xFF008B8B)));

    final parchmentPalette = ZetzyThemes.paletteFor(
      ZetzyThemeMode.warmParchment,
    );
    expect(parchmentPalette.brightness, equals(Brightness.light));
    expect(parchmentPalette.background, equals(const Color(0xFFF4EFE6)));

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

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    Future<void> scrollTo(Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
    }

    // Verify all 6 theme buttons work + Abyssal Cyan Easter Egg flip (Normal <-> Alter Ego)
    await scrollTo(find.text('Abyssal Cyan'));
    expect(find.text('Warm Parchment'), findsOneWidget);
    // 1st tap: enters Normal Abyssal Cyan (black + #00393D)
    await tester.tap(find.text('Abyssal Cyan'));
    await tester.pumpAndSettle();
    expect(settingsRepo.load().themeMode, equals(ZetzyThemeMode.abyssalCyan));
    expect(settingsRepo.load().abyssalCyanAlterEgo, isFalse);
    expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);

    // 2nd tap while active: flips into Alter Ego Easter Egg
    await tester.tap(find.text('Abyssal Cyan'));
    await tester.pumpAndSettle();
    expect(settingsRepo.load().themeMode, equals(ZetzyThemeMode.abyssalCyan));
    expect(settingsRepo.load().abyssalCyanAlterEgo, isTrue);
    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);

    // 3rd tap: flips cleanly back to Normal
    await tester.tap(find.text('Abyssal Cyan'));
    await tester.pumpAndSettle();
    expect(settingsRepo.load().abyssalCyanAlterEgo, isFalse);

    // Flip to Alter Ego again, then switching away to another theme resets alter flag
    await tester.tap(find.text('Abyssal Cyan'));
    await tester.pumpAndSettle();
    expect(settingsRepo.load().abyssalCyanAlterEgo, isTrue);

    await tester.tap(find.text('Warm Parchment'));
    await tester.pumpAndSettle();
    expect(settingsRepo.load().themeMode, equals(ZetzyThemeMode.warmParchment));
    expect(settingsRepo.load().abyssalCyanAlterEgo, isFalse);

    // Verify the 5 requested segmented controls span edge-to-edge equally
    await scrollTo(find.byType(SegmentedButton<BgmMode>));
    final bgmFinder = find.byType(SegmentedButton<BgmMode>);
    final bgmBtn = tester.widget<SegmentedButton<BgmMode>>(bgmFinder);
    expect(bgmBtn.expandedInsets, equals(EdgeInsets.zero));
    final expectedWidth = tester.getSize(bgmFinder).width;

    await scrollTo(find.byType(SegmentedButton<HapticIntensity>));
    final hapticFinder = find.byType(SegmentedButton<HapticIntensity>);
    expect(
      tester.widget<SegmentedButton<HapticIntensity>>(hapticFinder).expandedInsets,
      equals(EdgeInsets.zero),
    );
    expect(tester.getSize(hapticFinder).width, closeTo(expectedWidth, 0.5));

    await scrollTo(find.byType(SegmentedButton<ChessPieceSet>));
    final piecesFinder = find.byType(SegmentedButton<ChessPieceSet>);
    expect(
      tester.widget<SegmentedButton<ChessPieceSet>>(piecesFinder).expandedInsets,
      equals(EdgeInsets.zero),
    );
    expect(tester.getSize(piecesFinder).width, closeTo(expectedWidth, 0.5));
    await tester.tap(find.text('Tatiana'));
    await tester.pumpAndSettle();
    expect(settingsRepo.load().chessPieceSet, equals(ChessPieceSet.tatiana));

    await scrollTo(find.byType(SegmentedButton<ChessMoveConfirmMode>));
    final confirmFinder = find.byType(SegmentedButton<ChessMoveConfirmMode>);
    expect(
      tester
          .widget<SegmentedButton<ChessMoveConfirmMode>>(confirmFinder)
          .expandedInsets,
      equals(EdgeInsets.zero),
    );
    expect(tester.getSize(confirmFinder).width, closeTo(expectedWidth, 0.5));

    await scrollTo(find.text('Rewind Steps on Loss'));
    final rewindFinder = find.byWidgetPredicate(
      (w) => w is SegmentedButton<int> && w.segments.length == 3,
    );
    await scrollTo(rewindFinder);
    expect(
      tester.widget<SegmentedButton<int>>(rewindFinder).expandedInsets,
      equals(EdgeInsets.zero),
    );
    expect(tester.getSize(rewindFinder).width, closeTo(expectedWidth, 0.5));
  });

  testWidgets('ProfileScreen arranges 6 theme buttons in 2x3 expanded grid, customizes Auto favorite BGM, places Sudoku cells threshold inline, and gates Danger Zone inside 1 dialog', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    Future<void> scrollTo(Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
    }

    // 1. Verify Theme Skin is 2 columns x 3 rows expanded evenly left-to-right
    await scrollTo(find.text('Abyssal Cyan'));
    await scrollTo(find.text('OLED Midnight'));
    final oledRect = tester.getRect(find.text('OLED Midnight'));
    final woodRect = tester.getRect(find.text('Classic Wood & Slate'));
    final frostRect = tester.getRect(find.text('Nordic Frost'));
    final draculaRect = tester.getRect(find.text('Dracula Neon'));
    final cyanRect = tester.getRect(find.text('Abyssal Cyan'));
    final parchmentRect = tester.getRect(find.text('Warm Parchment'));
    expect(oledRect.center.dy, closeTo(woodRect.center.dy, 2.0));
    expect(frostRect.center.dy, closeTo(draculaRect.center.dy, 2.0));
    expect(cyanRect.center.dy, closeTo(parchmentRect.center.dy, 2.0));
    expect(frostRect.top, greaterThan(oledRect.bottom));
    expect(cyanRect.top, greaterThan(frostRect.bottom));

    // 2. Verify Auto BGM shows customizable Favorite Track picker (default Track 5)
    await scrollTo(find.text('Background Music (BGM)'));
    expect(find.textContaining('★ Track 5'), findsOneWidget);
    expect(find.text('Favorite Track (3× Priority in Auto)'), findsOneWidget);
    await scrollTo(find.text('Track 2'));
    await tester.tap(find.text('Track 2'));
    await tester.pumpAndSettle();
    expect(settingsRepo.load().favoriteBgmTrack, equals('2.mp3'));
    expect(find.textContaining('★ Track 2'), findsOneWidget);

    // 3. Verify Remaining Empty Cells sits inline beside [5 Cells | 7 Cells]
    await scrollTo(find.text('Remaining Empty Cells'));
    final cellsLabelRect = tester.getRect(find.text('Remaining Empty Cells'));
    final cellsBtnRect = tester.getRect(find.text('5 Cells'));
    expect(cellsLabelRect.center.dy, closeTo(cellsBtnRect.center.dy, 4.0));
    expect(cellsBtnRect.left, greaterThan(cellsLabelRect.right));

    // 4. Verify Cloud & Sync shows 1 Account & Data Management button opening dialog
    await scrollTo(find.text('Account & Data Management'));
    expect(find.text('Reset All Statistics'), findsNothing);
    expect(find.text('Delete Account Permanently'), findsNothing);

    await tester.tap(find.text('Account & Data Management'));
    await tester.pumpAndSettle();
    expect(find.text('Reset All Statistics'), findsOneWidget);
    // Guest user sees Reset All Statistics inside the dialog; Close dismisses cleanly
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Reset All Statistics'), findsNothing);
  });

  testWidgets('FeedbackScreen enforces 5-pending limit, 6h edit lock, delete anytime, Admin 20-item Load More, and 1x reply', (
    WidgetTester tester,
  ) async {
    PackageInfo.setMockInitialValues(
      appName: 'Zetzy',
      packageName: 'com.zetzy.app',
      version: '0.0.9',
      buildNumber: '1',
      buildSignature: '',
    );

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService.forTesting(prefs: prefs);
    final settingsRepo = SettingsRepository(prefs);
    final supa = _FakeFeedbackSupabaseService();
    final audio = AudioService();

    // 1. Player flow: navigate from Profile -> Feedback page, edit <6h, blocked >6h, cap 5, delete
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
    await tester.tap(find.text('Feedback'));
    await tester.pumpAndSettle();

    expect(
      find.text('Feedback can only be seen by you and admins.'),
      findsOneWidget,
    );
    expect(find.text('Pending: 5/5'), findsOneWidget);
    expect(
      find.text(
        'Max 5 pending feedback items reached. Wait for admin review or delete an older one.',
      ),
      findsOneWidget,
    );
    expect(find.text('v0.0.9'), findsWidgets);

    // Edit recent item (<6h)
    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Edited feedback text',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Edited feedback text'), findsOneWidget);

    final listScrollable = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;

    // Scroll down to verify older (>6h) item locks Edit button
    await tester.scrollUntilVisible(
      find.text('Edit locked (>6h)'),
      200,
      scrollable: listScrollable,
    );
    expect(find.text('Edit locked (>6h)'), findsWidgets);

    // Delete 1 item frees pending slot to 4/5 and unlocks submit
    await tester.ensureVisible(find.text('Delete').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Pending: 4/5'),
      -200,
      scrollable: listScrollable,
    );
    expect(find.text('Pending: 4/5'), findsOneWidget);

    // 2. Admin flow: ADMIN badge on Profile, Inbox loads 20 + Load More (20), 1x approve + reply
    supa.currentUser = UserProfile(
      id: 'admin-1',
      username: 'mod_admin',
      role: UserRole.admin,
      isGuest: false,
      accountData: {
        'stats': StatsSummary.fromRecords([
          GameRecord(
            id: 'r1',
            userId: 'admin-1',
            username: 'mod_admin',
            gameType: GameType.sudoku,
            difficulty: 5,
            isWon: true,
            score: 400,
            durationMs: 22000,
            platform: 'web',
            playedAt: DateTime(2026, 11, 16),
          ),
        ]).toJson(),
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('admin-scope'),
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

    // Verify synced stats restored onto Statistics tab even with empty local storage
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('175 XP'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('ADMIN'), findsOneWidget);

    await tester.tap(find.text('Feedback'));
    await tester.pumpAndSettle();
    expect(find.text('Feedback Inbox'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Load More (20)'),
      300,
      scrollable: listScrollable,
    );
    await tester.ensureVisible(find.text('Load More (20)'));
    await tester.tap(find.text('Load More (20)'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Inbox item 22'),
      200,
      scrollable: listScrollable,
    );
    expect(find.text('Inbox item 22'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Inbox item 0'),
      -300,
      scrollable: listScrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Fixed in next release!',
    );
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Fixed in next release!'), findsOneWidget);
    expect(find.text('Approved'), findsWidgets);
  });

  testWidgets(
    'ProfileScreen centers BGM tracks 1-9 and expands Snake touch control',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService.forTesting(prefs: prefs);
      final settingsRepo = SettingsRepository(prefs);
      final audio = AudioService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(localStorage),
            settingsRepoProvider.overrideWithValue(settingsRepo),
            supabaseServiceProvider.overrideWithValue(SupabaseService()),
            audioServiceProvider.overrideWithValue(audio),
          ],
          child: const ZetzyApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      final bgmWrap = tester
          .widgetList<Wrap>(find.byType(Wrap))
          .firstWhere((w) => w.alignment == WrapAlignment.center);
      expect(bgmWrap.alignment, WrapAlignment.center);
      expect(find.text('Track 9'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byType(SegmentedButton<SnakeControlMode>),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      final snakeSeg = tester.widget<SegmentedButton<SnakeControlMode>>(
        find.byType(SegmentedButton<SnakeControlMode>),
      );
      expect(snakeSeg.expandedInsets, EdgeInsets.zero);
    },
  );
}

class _FakeFeedbackSupabaseService extends _FakeAvailableSupabaseService {
  _FakeFeedbackSupabaseService() {
    final now = DateTime.now().toUtc();
    myItems = [
      FeedbackEntry(
        id: 'my-recent',
        userId: 'p-1',
        username: 'player_one',
        message: 'Recent editable item',
        appVersion: '0.0.9',
        createdAt: now.subtract(const Duration(minutes: 20)),
        updatedAt: now.subtract(const Duration(minutes: 20)),
      ),
      for (var i = 1; i <= 4; i++)
        FeedbackEntry(
          id: 'my-old-$i',
          userId: 'p-1',
          username: 'player_one',
          message: 'Older item $i',
          appVersion: '0.0.9',
          createdAt: now.subtract(const Duration(hours: 8)),
          updatedAt: now.subtract(const Duration(hours: 8)),
        ),
    ];
    inboxItems = [
      for (var i = 0; i < 24; i++)
        FeedbackEntry(
          id: 'adm-$i',
          userId: 'u-$i',
          username: 'user_$i',
          message: 'Inbox item $i',
          appVersion: '0.0.9',
          createdAt: now.subtract(Duration(minutes: i + 1)),
          updatedAt: now.subtract(Duration(minutes: i + 1)),
        ),
    ];
  }

  UserProfile currentUser = const UserProfile(
    id: 'p-1',
    username: 'player_one',
    isGuest: false,
  );
  late List<FeedbackEntry> myItems;
  late List<FeedbackEntry> inboxItems;

  @override
  Future<UserProfile?> fetchCurrentProfile() async => currentUser;

  @override
  Future<Map<String, dynamic>?> updateAccountData({
    Map<String, dynamic>? settingsJson,
    StatsSummary? statsSummary,
    Map<String, dynamic>? baseAccountData,
  }) async {
    final next = Map<String, dynamic>.from(baseAccountData ?? currentUser.accountData);
    if (settingsJson != null) next['settings'] = settingsJson;
    if (statsSummary != null) next['stats'] = statsSummary.toJson();
    currentUser = currentUser.copyWith(accountData: next);
    return next;
  }

  @override
  Future<List<FeedbackEntry>> fetchMyFeedbacks() async => List.of(myItems);

  @override
  Future<List<FeedbackEntry>> fetchAllFeedbacks({
    int limit = 20,
    int offset = 0,
  }) async {
    if (offset >= inboxItems.length) return const [];
    return inboxItems.skip(offset).take(limit).toList();
  }

  @override
  Future<FeedbackEntry> updateFeedbackMessage({
    required String feedbackId,
    required String message,
  }) async {
    final idx = myItems.indexWhere((e) => e.id == feedbackId);
    final updated = myItems[idx].copyWith(message: message);
    myItems[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteFeedback(String feedbackId) async {
    myItems.removeWhere((e) => e.id == feedbackId);
    inboxItems.removeWhere((e) => e.id == feedbackId);
  }

  @override
  Future<FeedbackEntry> reviewFeedback({
    required String feedbackId,
    required FeedbackStatus decision,
    String? adminReply,
  }) async {
    final idx = inboxItems.indexWhere((e) => e.id == feedbackId);
    final updated = inboxItems[idx].copyWith(
      status: decision,
      adminReply: (adminReply ?? '').isEmpty ? null : adminReply,
      reviewedBy: currentUser.id,
      reviewedAt: DateTime.now().toUtc(),
    );
    inboxItems[idx] = updated;
    return updated;
  }
}

class _FakeLeaderboardSupabaseService extends _FakeAvailableSupabaseService {
  @override
  Future<List<GameRecord>> fetchGlobalLeaderboard({
    required GameType gameType,
    required int difficulty,
    int limit = 20,
    int offset = 0,
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
