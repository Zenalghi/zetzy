import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zetzy/core/routing/app_router.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

class ZetzyApp extends ConsumerStatefulWidget {
  const ZetzyApp({super.key});

  @override
  ConsumerState<ZetzyApp> createState() => _ZetzyAppState();
}

class _ZetzyAppState extends ConsumerState<ZetzyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isForeground = state == AppLifecycleState.resumed;
    if (isForeground ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      ref.read(audioServiceProvider).handleAppLifecycleState(isForeground);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
