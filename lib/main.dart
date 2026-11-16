import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zetzy/app.dart';
import 'package:zetzy/core/services/audio_service.dart';
import 'package:zetzy/data/local/local_storage_service.dart';
import 'package:zetzy/data/local/settings_repository.dart';
import 'package:zetzy/data/remote/supabase_service.dart';
import 'package:zetzy/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final localStorage = await LocalStorageService.create();
  final settingsRepo = SettingsRepository(prefs);
  final initialSettings = settingsRepo.load();

  final supabaseService = SupabaseService();
  await supabaseService.initialize();

  final audioService = AudioService();
  await audioService.init(
    sfxEnabled: initialSettings.sfxEnabled,
    bgmMode: initialSettings.bgmMode,
    manualBgmTrack: initialSettings.bgmTrack,
    favoriteBgmTrack: initialSettings.favoriteBgmTrack,
  );

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(localStorage),
        settingsRepoProvider.overrideWithValue(settingsRepo),
        supabaseServiceProvider.overrideWithValue(supabaseService),
        audioServiceProvider.overrideWithValue(audioService),
      ],
      child: const ZetzyApp(),
    ),
  );
}
