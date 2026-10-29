import 'package:flutter/material.dart';

import '../../theme/transitions.dart';
import '../../widgets/common.dart';
import '../settings_screen.dart';
import 'explore_screen.dart';
import 'know_locals_screen.dart';
import 'permits_screen.dart';
import 'plan_screen.dart';
import 'stays_screen.dart';

/// Traveller tabs, in mockup order:
/// Explore · Permits · Stays / Guides · Know the Locals · Plan a Trip.
class TravellerShell extends StatefulWidget {
  const TravellerShell({
    super.key,
    this.initialTab = 0,
    this.previewIndian = false,
    this.previewEmergency = false,
  });

  final int initialTab;

  /// Only used by the web screenshot preview.
  final bool previewIndian;

  /// Only used by the web screenshot preview.
  final bool previewEmergency;

  @override
  State<TravellerShell> createState() => _TravellerShellState();
}

class _TravellerShellState extends State<TravellerShell> {
  late int _index = widget.initialTab;

  /// Trip selections survive tab switches.
  final _plan = PlanController();

  @override
  void dispose() {
    _plan.dispose();
    super.dispose();
  }

  Widget _page(int i) => switch (i) {
    0 => ExploreScreen(initialEmergency: widget.previewEmergency),
    1 => PermitsScreen(initialIndian: widget.previewIndian ? true : null),
    2 => const StaysScreen(),
    3 => const KnowLocalsScreen(),
    _ => PlanScreen(controller: _plan),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: const AppBarBrand(),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                Navigator.of(context).push(fadeRoute(const SettingsScreen())),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeSlideTransition(
          animation: animation,
          offset: const Offset(0, 0.015),
          child: child,
        ),
        child: KeyedSubtree(key: ValueKey(_index), child: _page(_index)),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEDEEF0))),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Explore',
              tooltip: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description),
              label: 'Permits',
              tooltip: 'Permits',
            ),
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Stays',
              tooltip: 'Stays / Guides',
            ),
            NavigationDestination(
              icon: Icon(Icons.diversity_3_outlined),
              selectedIcon: Icon(Icons.diversity_3),
              label: 'Locals',
              tooltip: 'Know the Locals',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Plan',
              tooltip: 'Plan a Trip',
            ),
          ],
        ),
      ),
    );
  }
}
