import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zetzy/app.dart';
import 'package:zetzy/core/services/audio_service.dart';
import 'package:zetzy/data/local/local_storage_service.dart';
import 'package:zetzy/data/local/settings_repository.dart';
import 'package:zetzy/data/remote/supabase_service.dart';
import 'package:zetzy/providers/app_providers.dart';

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
  });
}
