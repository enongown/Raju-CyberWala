import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/fade_in.dart';

/// Explains how hosts with a basic phone can list by SMS.
class SmsListingScreen extends StatelessWidget {
  const SmsListingScreen({super.key});

  static const _steps = [
    ('Send an SMS', 'Type STAY, GUIDE or CRAFT, your name and village.'),
    (
      'Answer a few questions',
      'Our assistant bot replies by SMS — price, rooms, languages.',
    ),
    (
      'Verification call',
      'A local volunteer calls or visits to confirm you are real.',
    ),
    (
      'You are listed',
      'Travellers see a "SMS / call host" badge and contact you by SMS.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('List via SMS')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const PageHeading(
            'No app needed',
            subtitle: 'Any phone that can send SMS works. Free to list.',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: OutlineCard(
              color: AppColors.surfaceSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Example message', style: t.bodySmall),
                  const SizedBox(height: 8),
                  Text(
                    'STAY Pema Tawang 1800',
                    style: t.titleLarge?.copyWith(
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Send to: number coming soon', style: t.bodySmall),
                ],
              ),
            ),
          ),
          const SectionHeader('How it works'),
          for (final (n, s) in _steps.indexed)
            FadeIn(
              index: n,
              child: ListTile(
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.blueTint,
                  child: Text(
                    '${n + 1}',
                    style: t.labelMedium?.copyWith(color: AppColors.blue),
                  ),
                ),
                title: Text(s.$1),
                subtitle: Text(s.$2),
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: InfoNote(
              'The SMS number and AI verification bot are not live yet in '
              'this version.',
            ),
          ),
        ],
      ),
    );
  }
}
