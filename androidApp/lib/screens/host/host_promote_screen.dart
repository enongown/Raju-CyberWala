import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/fade_in.dart';

class HostPromoteScreen extends StatefulWidget {
  const HostPromoteScreen({super.key});

  @override
  State<HostPromoteScreen> createState() => _HostPromoteScreenState();
}

class _HostPromoteScreenState extends State<HostPromoteScreen> {
  final _visible = <String, bool>{'stay': true, 'guide': false, 'crafts': true};

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const FadeIn(
          child: PageHeading(
            'Promote',
            subtitle: 'Choose what travellers can see and book.',
          ),
        ),
        const SizedBox(height: 12),
        FadeIn(
          index: 1,
          child: _ListingCard(
            icon: Icons.cottage_outlined,
            color: AppColors.blue,
            title: 'Homestay',
            detail: '2 rooms · ₹1,800 / night',
            hint: 'Fair range nearby: ₹1,500 – ₹2,500',
            visible: _visible['stay']!,
            onChanged: (v) => setState(() => _visible['stay'] = v),
          ),
        ),
        FadeIn(
          index: 2,
          child: _ListingCard(
            icon: Icons.hiking_outlined,
            color: AppColors.green,
            title: 'Guiding',
            detail: 'Monastery walk · ₹2,000 / day',
            hint: 'Draft — add a photo to publish',
            visible: _visible['guide']!,
            onChanged: (v) => setState(() => _visible['guide'] = v),
          ),
        ),
        FadeIn(
          index: 3,
          child: _ListingCard(
            icon: Icons.shopping_bag_outlined,
            color: AppColors.red,
            title: 'Crafts',
            detail: 'Handmade paper · 3 products',
            hint: 'Rated 4.8 by 74 buyers',
            visible: _visible['crafts']!,
            onChanged: (v) => setState(() => _visible['crafts'] = v),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: OutlinedButton.icon(
            onPressed: () =>
                showSoonSnack(context, 'Adding products is coming soon'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add a product or service'),
          ),
        ),
        const SectionHeader('Tips'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DotLabel(
                'Clear photos get 3× more enquiries',
                color: AppColors.blue,
                style: t.bodyMedium,
              ),
              const SizedBox(height: 10),
              DotLabel(
                'Keep prices in the fair range to build trust',
                color: AppColors.green,
                style: t.bodyMedium,
              ),
              const SizedBox(height: 10),
              DotLabel(
                'Reply within a day — even by SMS',
                color: AppColors.yellow,
                style: t.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.hint,
    required this.visible,
    required this.onChanged,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String hint;
  final bool visible;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: OutlineCard(
        child: Row(
          children: [
            TintIcon(icon, color: color, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleMedium),
                  const SizedBox(height: 2),
                  Text(detail, style: t.bodyMedium),
                  const SizedBox(height: 2),
                  Text(hint, style: t.bodySmall),
                ],
              ),
            ),
            Column(
              children: [
                Switch(value: visible, onChanged: onChanged),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    visible ? 'Visible' : 'Hidden',
                    key: ValueKey(visible),
                    style: t.labelSmall?.copyWith(
                      color: visible ? AppColors.green : AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
