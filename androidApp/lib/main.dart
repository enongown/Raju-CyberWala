import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/firebase_service.dart';
import 'data/mock_data.dart';
import 'data/prefs.dart';
import 'firebase_options.dart';
import 'screens/host/host_shell.dart';
import 'screens/traveller/guide_detail_screen.dart';
import 'screens/traveller/stay_detail_screen.dart';
import 'screens/traveller/traveller_shell.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebase();
  // Google Sans is bundled in assets/google_fonts so the app works offline.
  GoogleFonts.config.allowRuntimeFetching = false;
  final prefs = await AppPrefs.load();
  runApp(ExploreArunachalApp(prefs: prefs, preview: PreviewTarget.fromUrl()));
}

/// Connects Firebase before the first frame. Any failure (offline first
/// launch, bad config, unsupported platform) is logged and swallowed so the
/// app always opens and keeps running on bundled mock data.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Cache Firestore data on device so the app keeps working offline.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    AppFirebaseService.markReady();
    debugPrint('Firebase initialised (project explore-arunachal).');
  } catch (e, st) {
    debugPrint('Firebase init failed, continuing offline with mock data: $e');
    debugPrint('$st');
  }
}

class ExploreArunachalApp extends StatelessWidget {
  const ExploreArunachalApp({super.key, required this.prefs, this.preview});

  final AppPrefs prefs;
  final PreviewTarget? preview;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Explore Arunachal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: preview?.build() ?? homeForRole(prefs.role),
    );
  }
}

/// The screen a given role lands on. `null` shows the first-launch welcome.
Widget homeForRole(UserRole? role) => switch (role) {
  null => const WelcomeScreen(),
  UserRole.traveller => const TravellerShell(),
  UserRole.host => const HostShell(),
};

/// Web-only preview hook used to capture design screenshots, e.g.
/// `/?preview=permits`. It never touches saved preferences and is ignored on
/// Android.
class PreviewTarget {
  const PreviewTarget(this.name);
  final String name;

  static PreviewTarget? fromUrl() {
    if (!kIsWeb) return null;
    final name = Uri.base.queryParameters['preview'];
    return name == null ? null : PreviewTarget(name);
  }

  Widget build() => switch (name) {
    'welcome' => const WelcomeScreen(),
    'welcome_selected' => const WelcomeScreen(
      initialSelection: UserRole.traveller,
    ),
    'explore' => const TravellerShell(initialTab: 0),
    'explore_emergency' => const TravellerShell(
      initialTab: 0,
      previewEmergency: true,
    ),
    'permits' => const TravellerShell(initialTab: 1, previewIndian: true),
    'stays' => const TravellerShell(initialTab: 2),
    'stay_detail' => StayDetailScreen(stay: MockData.stays.first),
    'guide_detail' => GuideDetailScreen(guide: MockData.guides.first),
    'know_locals' => const TravellerShell(initialTab: 3),
    'plan' => const TravellerShell(initialTab: 4),
    'host' => const HostShell(initialTab: 0),
    'host_promote' => const HostShell(initialTab: 1),
    'host_bookings' => const HostShell(initialTab: 2),
    _ => const WelcomeScreen(),
  };
}
