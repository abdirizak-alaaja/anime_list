import 'package:flutter/material.dart';

import '../../features/favorites/screens/favorites_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/library/screens/my_list_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../shared/widgets/offline_banner.dart';
import '../constants/app_constants.dart';
import '../di/app_scope.dart';

/// A top-level tab of the app.
class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

final List<ShellDestination> _destinations = [
  ShellDestination(
    label: 'Discover',
    icon: Icons.explore_outlined,
    selectedIcon: Icons.explore,
    builder: (_) => const HomeScreen(),
  ),
  ShellDestination(
    label: 'Search',
    icon: Icons.search_outlined,
    selectedIcon: Icons.search,
    builder: (_) => const SearchScreen(),
  ),
  ShellDestination(
    label: 'My List',
    icon: Icons.video_library_outlined,
    selectedIcon: Icons.video_library,
    builder: (_) => const MyListScreen(),
  ),
  ShellDestination(
    label: 'Favorites',
    icon: Icons.favorite_outline,
    selectedIcon: Icons.favorite,
    builder: (_) => const FavoritesScreen(),
  ),
];

/// Root layout: bottom navigation on phones, a navigation rail on wide
/// screens.
///
/// Tabs are built lazily on first visit and then kept alive, so switching
/// tabs preserves scroll position and search state without refetching.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final Set<int> _visited = {0};

  void _select(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _visited.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stack = IndexedStack(
      index: _index,
      children: [
        for (var i = 0; i < _destinations.length; i++)
          _visited.contains(i)
              ? Builder(builder: _destinations[i].builder)
              : const SizedBox.shrink(),
      ],
    );

    final body = Column(
      children: [
        Expanded(child: stack),
        OfflineBanner(health: AppScope.of(context).apiHealth),
      ],
    );

    final isWide =
        MediaQuery.sizeOf(context).width >= AppConstants.wideLayoutBreakpoint;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
