import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zetzy/core/routing/app_router.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

class ZetzyApp extends ConsumerWidget {
  const ZetzyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    // Keep offline score sync listener alive across app lifetime
    ref.watch(scoreSyncControllerProvider);

    return MaterialApp(
      title: 'Zetzy',
      debugShowCheckedModeBanner: false,
      theme: ZetzyThemes.buildTheme(settings.themeMode),
      locale: Locale(settings.localeCode),
      supportedLocales: const [Locale('en'), Locale('id')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppRouter.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
