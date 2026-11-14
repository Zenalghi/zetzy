import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/services/audio_service.dart';
import 'package:zetzy/features/home/home_screen.dart';
import 'package:zetzy/features/leaderboard/leaderboard_screen.dart';
import 'package:zetzy/features/profile/profile_screen.dart';
import 'package:zetzy/features/statistics/statistics_screen.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;

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
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                        AssetPaths.appIcon,
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
                    index: _selectedIndex,
                    children: _pages,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _pages,
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
