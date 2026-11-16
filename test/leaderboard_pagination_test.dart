import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/services/audio_service.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/data/local/local_storage_service.dart';
import 'package:zetzy/data/local/settings_repository.dart';
import 'package:zetzy/data/models/game_record.dart';
import 'package:zetzy/data/models/user_profile.dart';
import 'package:zetzy/data/remote/supabase_service.dart';
import 'package:zetzy/features/leaderboard/leaderboard_screen.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

class _FakePaginatedSupabaseService extends SupabaseService {
  final List<({int limit, int offset})> globalCalls = [];
  final List<({int limit, int offset})> myBestCalls = [];
  final List<({int limit, int offset})> eloCalls = [];
  bool simulateNewTopRecordInserted = false;
  UserProfile? signedInProfile;

  @override
  bool get isAvailable => true;

  @override
  Future<UserProfile?> fetchCurrentProfile() async => signedInProfile;

  @override
  Future<List<GameRecord>> fetchMyBestRecords({
    required String userId,
    required GameType gameType,
    required int difficulty,
    int limit = 20,
    int offset = 0,
  }) async {
    myBestCalls.add((limit: limit, offset: offset));
    if (offset > 0) return [];
    return [
      GameRecord(
        id: 'cloud-my-1',
        userId: userId,
        username: signedInProfile?.username ?? 'cloud_user',
        gameType: gameType,
        difficulty: difficulty,
        isWon: true,
        score: 1850,
        durationMs: 14200,
        platform: 'web',
        playedAt: DateTime(2026, 11, 16),
      ),
    ];
  }

  List<GameRecord> _dataset() {
    final base = List.generate(35, (i) {
      return GameRecord(
        id: 'rec-${i + 1}',
        userId: 'u-${i + 1}',
        username: 'player_${i + 1}',
        gameType: GameType.sudoku,
        difficulty: DifficultyLevel.normal.level,
        isWon: true,
        score: 1000 - i,
        durationMs: 10000 + i * 100,
        platform: 'windows',
        playedAt: DateTime(2026, 11, 15),
      );
    });
    if (simulateNewTopRecordInserted) {
      return [
        GameRecord(
          id: 'rec-new-top',
          userId: 'u-top',
          username: 'new_champion',
          gameType: GameType.sudoku,
          difficulty: DifficultyLevel.normal.level,
          isWon: true,
          score: 2000,
          durationMs: 9000,
          platform: 'android',
          playedAt: DateTime(2026, 11, 15, 14),
        ),
        ...base,
      ];
    }
    return base;
  }

  @override
  Future<List<GameRecord>> fetchGlobalLeaderboard({
    required GameType gameType,
    required int difficulty,
    int limit = 20,
    int offset = 0,
  }) async {
    globalCalls.add((limit: limit, offset: offset));
    final all = _dataset();
    if (offset >= all.length) return [];
    final end = (offset + limit).clamp(0, all.length);
    return all.sublist(offset, end);
  }

  @override
  Future<List<UserProfile>> fetchChessEloLeaderboard({
    int limit = 20,
    int offset = 0,
  }) async {
    eloCalls.add((limit: limit, offset: offset));
    final all = List.generate(
      26,
      (i) => UserProfile(
        id: 'elo-u-${i + 1}',
        username: 'chess_master_${i + 1}',
        chessElo: 1800 - i * 10,
        isGuest: false,
      ),
    );
    if (offset >= all.length) return [];
    final end = (offset + limit).clamp(0, all.length);
    return all.sublist(offset, end);
  }
}

void main() {
  testWidgets(
    'Leaderboard loads 20 initially, loads 10 more cleanly with dedup, and refreshes newest top 20',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService.forTesting(prefs: prefs);
      final settingsRepo = SettingsRepository(prefs);
      final supa = _FakePaginatedSupabaseService();
      final audio = AudioService();

      // Seed 24 local records to verify My Best pagination too
      for (var i = 0; i < 24; i++) {
        await localStorage.saveLocalRecord(
          GameRecord(
            id: 'local-$i',
            userId: 'guest',
            username: 'guest',
            gameType: GameType.sudoku,
            difficulty: DifficultyLevel.normal.level,
            isWon: true,
            score: 500 - i,
            durationMs: 12000 + i * 50,
            platform: 'windows',
            playedAt: DateTime(2026, 11, 15, 10, i),
          ),
        );
      }

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
            home: const Scaffold(body: LeaderboardScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial pull on Global tab is exactly 20 (offset 0, limit 20)
      expect(supa.globalCalls, [(limit: 20, offset: 0)]);
      expect(find.text('@player_1'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('leaderboard_load_more_btn')),
        240,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('@player_20'), findsOneWidget);
      expect(find.text('@player_21'), findsNothing);
      expect(find.text('Load 10 more'), findsOneWidget);

      // 2. Simulate new record inserted at #1 on server while user loads next 10 -> no duplicates
      supa.simulateNewTopRecordInserted = true;
      await tester.tap(find.byKey(const ValueKey('leaderboard_load_more_btn')));
      await tester.pumpAndSettle();

      expect(supa.globalCalls.last, (limit: 10, offset: 20));
      // @player_20 appeared in page 1 AND shifts to offset 20 on server -> must remain unique (only 1 widget!)
      expect(find.text('@player_20'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('leaderboard_load_more_btn')),
        240,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('@player_29'), findsOneWidget);
      expect(find.text('@player_30'), findsNothing);

      // 3. Load remaining items until exhausted -> Load more disappears
      await tester.tap(find.byKey(const ValueKey('leaderboard_load_more_btn')));
      await tester.pumpAndSettle();
      expect(supa.globalCalls.last, (limit: 10, offset: 30));
      expect(find.byKey(const ValueKey('leaderboard_load_more_btn')), findsNothing);
      await tester.scrollUntilVisible(
        find.text('@player_35'),
        240,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('@player_35'), findsOneWidget);

      // 4. Refresh reloads fresh top 20 and scrolls back to #1 (@new_champion)
      await tester.tap(find.byKey(const ValueKey('leaderboard_refresh_btn')));
      await tester.pumpAndSettle();
      expect(supa.globalCalls.last, (limit: 20, offset: 0));
      expect(find.text('@new_champion'), findsOneWidget);

      // 5. Switch to Chess ELO -> initial 20, then Load 10 more reveals 26th
      await tester.tap(find.text('Chess ELO'));
      await tester.pumpAndSettle();
      expect(supa.eloCalls, [(limit: 20, offset: 0)]);
      expect(find.text('@chess_master_1'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('leaderboard_load_more_btn')),
        240,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const ValueKey('leaderboard_load_more_btn')));
      await tester.pumpAndSettle();
      expect(supa.eloCalls.last, (limit: 10, offset: 20));
      await tester.scrollUntilVisible(
        find.text('@chess_master_26'),
        240,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('@chess_master_26'), findsOneWidget);

      // 6. Switch to My Best -> initial 20 local, Load 10 more reveals remaining 4 (#24)
      await tester.tap(find.text('My Best'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('leaderboard_load_more_btn')),
        240,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('#20'), findsOneWidget);
      expect(find.text('#24'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('leaderboard_load_more_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('leaderboard_load_more_btn')), findsNothing);
      await tester.scrollUntilVisible(
        find.text('#24'),
        240,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('#24'), findsOneWidget);
    },
  );

  testWidgets(
    'My Best syncs cloud records for signed-in users even with empty local storage',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService.forTesting(prefs: prefs);
      final settingsRepo = SettingsRepository(prefs);
      final supa = _FakePaginatedSupabaseService()
        ..signedInProfile = const UserProfile(
          id: 'u-cloud',
          username: 'cloud_user',
          isGuest: false,
        );
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
            home: const Scaffold(body: LeaderboardScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Best'));
      await tester.pumpAndSettle();

      expect(supa.myBestCalls, isNotEmpty);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('@cloud_user'), findsOneWidget);
      expect(find.textContaining('00:14'), findsOneWidget);
    },
  );
}
