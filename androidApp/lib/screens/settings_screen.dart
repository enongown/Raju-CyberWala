import 'package:flutter/material.dart';

import '../data/prefs.dart';
import '../main.dart';
import '../theme/app_colors.dart';
import '../theme/transitions.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _prefs = AppPrefs.instance;
  late bool _offline = _prefs.offlineMode;

  Future<void> _switchTo(UserRole role) async {
    await _prefs.setRole(role);
    if (!mounted) return;
    Navigator.of(context)
        .pushAndRemoveUntil(fadeRoute(homeForRole(role)), (_) => false);
  }
//Not so important featuere is  herer
  Future<void> _showWelcome() async {
    await _prefs.clearRole();
    if (!mounted) return;
    Navigator.of(context)
        .pushAndRemoveUntil(fadeRoute(homeForRole(null)), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final role = _prefs.role ?? UserRole.traveller;
    final other = role == UserRole.traveller
        ? UserRole.host
        : UserRole.traveller;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SectionHeader('Your role'),
          ListTile(
            leading: Icon(
              role == UserRole.traveller
                  ? Icons.backpack_outlined
                  : Icons.storefront_outlined,
            ),
            title: Text(
              role == UserRole.traveller ? 'Traveller' : 'Host / Guide',
            ),
            subtitle: const Text('Current role'),
            trailing: const TonePill('Active', color: AppColors.green),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: Text(
              other == UserRole.host
                  ? 'Switch to Host / Guide'
                  : 'Switch to Traveller',
            ),
            subtitle: const Text('Your saved data stays on this device'),
            onTap: () => _switchTo(other),
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Show welcome screen again'),
            onTap: _showWelcome,
          ),
          const Divider(indent: 20, endIndent: 20),
          const SectionHeader('Offline'),
          SwitchListTile(
            secondary: const Icon(Icons.cloud_off_outlined),
            title: const Text('Offline mode'),
            subtitle: const Text(
              'Places, permits guide, phrases and travel times are stored on this device',
            ),
            value: _offline,
            onChanged: (v) {
              setState(() => _offline = v);
              _prefs.setOfflineMode(v);
            },
          ),
          const ListTile(
            leading: Icon(Icons.download_done_outlined),
            title: Text('Offline pack'),
            subtitle: Text('8 places · 4 hubs · 2 phrase books'),
          ),
          const Divider(indent: 20, endIndent: 20),
          const SectionHeader('About'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Explore Arunachal · MVP 0.1', style: t.bodyMedium),
                const SizedBox(height: 8),
                const InfoNote(
                  'Distances, times, prices and permit details are approximate '
                  'sample data. Always verify permits with official sources.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
