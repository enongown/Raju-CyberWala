import 'package:flutter/material.dart';

import '../../theme/transitions.dart';
import '../../widgets/common.dart';
import '../settings_screen.dart';
import 'host_bookings_screen.dart';
import 'host_home_screen.dart';
import 'host_promote_screen.dart';

class HostShell extends StatefulWidget {
  const HostShell({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<HostShell> createState() => _HostShellState();
}

class _HostShellState extends State<HostShell> {
  late int _index = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final page = switch (_index) {
      0 => const HostHomeScreen(),
      1 => const HostPromoteScreen(),
      _ => const HostBookingsScreen(),
    };
    return Scaffold(
      appBar: AppBar(
        title: const AppBarBrand(label: 'Host'),
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
        transitionBuilder: (child, animation) => FadeSlideTransition(
          animation: animation,
          offset: const Offset(0, 0.015),
          child: child,
        ),
        child: KeyedSubtree(key: ValueKey(_index), child: page),
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
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign),
              label: 'Promote',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note),
              label: 'Bookings',
            ),
          ],
        ),
      ),
    );
  }
}
