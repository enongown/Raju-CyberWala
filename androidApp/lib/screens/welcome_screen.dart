import 'package:flutter/material.dart';

import '../data/prefs.dart';
import '../main.dart';
import '../theme/app_colors.dart';
import '../theme/transitions.dart';
import '../widgets/common.dart';
import '../widgets/fade_in.dart';

/// First-launch screen: a plain white page split in two by a thin divider,
/// "Host" on the left and "Traveller" on the right. Tapping a half
/// highlights it, saves the role and continues.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.initialSelection});

  /// Pre-selected role (only used by the web screenshot preview).
  final UserRole? initialSelection;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late UserRole? _selected = widget.initialSelection;
  bool _busy = false;

  Future<void> _choose(UserRole role) async {
    if (_busy) return;
    setState(() {
      _selected = role;
      _busy = true;
    });
    // Let the selection animation play before moving on.
    await Future<void>.delayed(const Duration(milliseconds: 420));
    await AppPrefs.instance.setRole(role);
    if (!mounted) return;
    Navigator.of(context)
        .pushAndRemoveUntil(fadeRoute(homeForRole(role)), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            FadeIn(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandDots(size: 7),
                  const SizedBox(width: 4),
                  Text(
                    'Explore Arunachal',
                    style: t.titleSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: FadeIn(
                      index: 1,
                      child: _Half(
                        label: 'Host',
                        caption: 'List a stay, guiding\nor crafts',
                        selected: _selected == UserRole.host,
                        dimmed: _selected == UserRole.traveller,
                        onTap: () => _choose(UserRole.host),
                      ),
                    ),
                  ),
                  FadeIn(
                    index: 2,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Container(
                        width: 1,
                        height: 220 * v,
                        color: AppColors.borderStrong,
                      ),
                    ),
                  ),
                  Expanded(
                    child: FadeIn(
                      index: 3,
                      child: _Half(
                        label: 'Traveller',
                        caption: 'Plan trips, permits,\nstays and guides',
                        selected: _selected == UserRole.traveller,
                        dimmed: _selected == UserRole.host,
                        onTap: () => _choose(UserRole.traveller),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            FadeIn(
              index: 4,
              child: Text(
                'Tap to begin · switch anytime in Settings',
                style: t.bodySmall?.copyWith(color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Half extends StatelessWidget {
  const _Half({
    required this.label,
    required this.caption,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final String label;
  final String caption;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const curve = Curves.easeOutCubic;
    const d = Duration(milliseconds: 320);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.blueTint,
        highlightColor: AppColors.blueTint.withValues(alpha: 0.5),
        child: SizedBox.expand(
          child: AnimatedOpacity(
            duration: d,
            curve: curve,
            opacity: dimmed ? 0.35 : 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  duration: d,
                  curve: curve,
                  scale: selected ? 1.08 : 1,
                  child: AnimatedDefaultTextStyle(
                    duration: d,
                    curve: curve,
                    style: (t.headlineMedium ?? const TextStyle()).copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.3,
                      color: selected ? AppColors.blue : AppColors.text,
                    ),
                    child: Text(label),
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedContainer(
                  duration: d,
                  curve: curve,
                  width: selected ? 28 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  caption,
                  textAlign: TextAlign.center,
                  style: t.bodySmall?.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
