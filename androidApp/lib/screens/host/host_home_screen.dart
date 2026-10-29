import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/transitions.dart';
import '../../widgets/common.dart';
import '../../widgets/fade_in.dart';
import '../../widgets/gender_rating.dart';
import 'host_register_screen.dart';
import 'sms_listing_screen.dart';

/// Host overview: verification status, ways to get listed, quick stats.
class HostHomeScreen extends StatelessWidget {
  const HostHomeScreen({super.key});

  static const _steps = <(String, String, _StepState)>[
    ('Registered', 'Basic details received', _StepState.done),
    ('Phone verified', 'OTP / SMS bot confirmed', _StepState.done),
    (
      'ID & place check',
      'Local volunteer visit · in review',
      _StepState.active,
    ),
    ('Verified badge', 'Shown to travellers', _StepState.todo),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    var i = 0;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        FadeIn(
          index: i++,
          child: const PageHeading(
            'Namaste, host',
            subtitle: 'Welcome travellers, earn locally, keep it simple.',
          ),
        ),
        FadeIn(index: i++, child: const SectionHeader('Verification status')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FadeIn(
            index: i++,
            child: OutlineCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('2 of 4 steps done', style: t.titleSmall),
                      ),
                      const TonePill('In review', color: AppColors.yellow),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 0.5),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) =>
                          LinearProgressIndicator(value: v, minHeight: 4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final s in _steps) _StepRow(step: s),
                ],
              ),
            ),
          ),
        ),
        FadeIn(
          index: i++,
          child: const SectionHeader(
            'Get listed',
            subtitle: 'Use the app, or just send an SMS',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: FadeIn(
                  index: i++,
                  child: _ActionCard(
                    icon: Icons.app_registration,
                    color: AppColors.blue,
                    title: 'Register in app',
                    subtitle: 'Stay, guiding or crafts',
                    onTap: () =>
                        Navigator.of(context)
                            .push(fadeRoute(const HostRegisterScreen())),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FadeIn(
                  index: i++,
                  child: _ActionCard(
                    icon: Icons.sms_outlined,
                    color: AppColors.green,
                    title: 'List via SMS',
                    subtitle: 'No smartphone needed',
                    onTap: () =>
                        Navigator.of(context)
                            .push(fadeRoute(const SmsListingScreen())),
                  ),
                ),
              ),
            ],
          ),
        ),
        FadeIn(index: i++, child: const SectionHeader('This month')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FadeIn(
            index: i++,
            child: OutlineCard(
              child: Row(
                children: [
                  _Metric(value: '214', label: 'Profile views'),
                  _Metric(value: '9', label: 'Enquiries'),
                  _Metric(
                    value: MockData.hostOwnRatings.average.toStringAsFixed(1),
                    label: 'Rating',
                    star: true,
                  ),
                ],
              ),
            ),
          ),
        ),
        FadeIn(
          index: i++,
          child: const SectionHeader(
            'Who rated you',
            subtitle: 'Travellers see this split on your listing',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FadeIn(
            index: i++,
            child: const OutlineCard(
              child: GenderRatingSummary(ratings: MockData.hostOwnRatings),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: InfoNote(
            'Demo data. Nothing is sent or published from this screen.',
          ),
        ),
      ],
    );
  }
}

enum _StepState { done, active, todo }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});
  final (String, String, _StepState) step;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final (title, sub, state) = step;
    final (icon, color) = switch (state) {
      _StepState.done => (Icons.check_circle, AppColors.green),
      _StepState.active => (Icons.timelapse, AppColors.yellow),
      _StepState.todo => (Icons.radio_button_unchecked, AppColors.borderStrong),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.bodyMedium?.copyWith(
                    color: state == _StepState.todo
                        ? AppColors.textTertiary
                        : AppColors.text,
                  ),
                ),
                Text(sub, style: t.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return OutlineCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TintIcon(icon, color: color),
          const SizedBox(height: 14),
          Text(title, style: t.titleSmall),
          const SizedBox(height: 2),
          Text(subtitle, style: t.bodySmall),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, this.star = false});
  final String value;
  final String label;
  final bool star;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(value, style: t.headlineSmall),
              if (star) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.yellow,
                  size: 20,
                ),
              ],
            ],
          ),
          Text(label, style: t.bodySmall),
        ],
      ),
    );
  }
}
