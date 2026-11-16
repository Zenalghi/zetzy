import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/routing/app_router.dart';
import 'package:zetzy/core/services/audio_service.dart';
import 'package:zetzy/features/home/home_screen.dart';
import 'package:zetzy/features/leaderboard/leaderboard_screen.dart';
import 'package:zetzy/features/profile/profile_screen.dart';
import 'package:zetzy/features/statistics/statistics_screen.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _selectedIndex = widget.initialTab.clamp(0, 3);
  late final Set<int> _activatedTabs = {_selectedIndex};
  final _pagesKey = GlobalKey();

  static const _pages = [
    HomeScreen(),
    LeaderboardScreen(),
    StatisticsScreen(),
    ProfileScreen(),
  ];

  void _onSelectTab(int index) {
    if (index == _selectedIndex) return;
    ref.read(audioServiceProvider).playSfx(ZetzySfx.uiClick);
    ref.read(hapticServiceProvider).selection();
    setState(() {
      _selectedIndex = index;
      _activatedTabs.add(index);
    });
    if (kIsWeb) {
      SystemNavigator.routeInformationUpdated(
        uri: Uri.parse(AppRouter.routeForTab(index)),
      );
    }
  }

  List<Widget> _buildLazyPages() => [
    for (var i = 0; i < _pages.length; i++)
      _activatedTabs.contains(i) ? _pages[i] : const SizedBox.shrink(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final themeIconPath = AssetPaths.themeAppIcon(
      settings.themeMode,
      abyssalAlterEgo: settings.abyssalCyanAlterEgo,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth > 640;

        if (useRail) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onSelectTab,
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        themeIconPath,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.sports_esports_outlined),
                      selectedIcon: const Icon(Icons.sports_esports_rounded),
                      label: Text(l10n.navHome),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.leaderboard_outlined),
                      selectedIcon: const Icon(Icons.leaderboard_rounded),
                      label: Text(l10n.navLeaderboard),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.insights_outlined),
                      selectedIcon: const Icon(Icons.insights_rounded),
                      label: Text(l10n.navStatistics),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.person_outline_rounded),
                      selectedIcon: const Icon(Icons.person_rounded),
                      label: Text(l10n.navProfile),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: IndexedStack(
                    key: _pagesKey,
                    index: _selectedIndex,
                    children: _buildLazyPages(),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(
            key: _pagesKey,
            index: _selectedIndex,
            children: _buildLazyPages(),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onSelectTab,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.sports_esports_outlined),
                selectedIcon: const Icon(Icons.sports_esports_rounded),
                label: l10n.navHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.leaderboard_outlined),
                selectedIcon: const Icon(Icons.leaderboard_rounded),
                label: l10n.navLeaderboard,
              ),
              NavigationDestination(
                icon: const Icon(Icons.insights_outlined),
                selectedIcon: const Icon(Icons.insights_rounded),
                label: l10n.navStatistics,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: const Icon(Icons.person_rounded),
                label: l10n.navProfile,
              ),
            ],
          ),
        );
      },
    );
  }
}
