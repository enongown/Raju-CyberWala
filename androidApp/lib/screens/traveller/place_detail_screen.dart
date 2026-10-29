import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../data/trip_calculator.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/fade_in.dart';
import '../../widgets/gender_rating.dart';

class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({super.key, required this.place});

  final Place place;

  Future<void> _openMaps(BuildContext context) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lng}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      showSoonSnack(context, 'Could not open maps');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final month = DateTime.now().month;
    final hosts = MockData.hosts.where((h) => h.placeId == place.id).toList();
    var i = 0;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          FadeIn(
            index: i++,
            child: PageHeading(
              place.name,
              subtitle: '${place.district} · ${place.altitudeM} m',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: FadeIn(
              index: i++,
              child: Text(
                place.description,
                style: t.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: FadeIn(
              index: i++,
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openMaps(context),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Open in Maps'),
                  ),
                ],
              ),
            ),
          ),
          FadeIn(
            index: i++,
            child: const SectionHeader(
              'Seasons',
              subtitle: 'Green = best · red = risky',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FadeIn(
              index: i++,
              child: _MonthStrip(place: place, now: month),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DotLabel(place.seasonNote, color: AppColors.green),
                const SizedBox(height: 6),
                DotLabel(place.riskNote, color: AppColors.red),
              ],
            ),
          ),
          FadeIn(
            index: i++,
            child: const SectionHeader(
              'How to reach',
              subtitle: 'Approximate road distance and time',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlineCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.howToReach, style: t.bodyMedium),
                  const SizedBox(height: 12),
                  const Divider(),
                  for (final h in MockData.hubs)
                    Builder(
                      builder: (context) {
                        final leg = TripCalculator.hubToPlace(h, place);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                h.kind.startsWith('Airport')
                                    ? Icons.flight_outlined
                                    : Icons.train_outlined,
                                size: 18,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(h.name, style: t.bodyMedium),
                                    Text(h.kind, style: t.bodySmall),
                                  ],
                                ),
                              ),
                              Text(
                                '${leg.estimated ? '≈' : '~'}${leg.km} km · ${formatHours(leg.hours)}',
                                style: t.bodySmall,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 4),
                  const InfoNote(
                    '≈ estimated from map distance. All times approximate.',
                  ),
                ],
              ),
            ),
          ),
          if (hosts.isNotEmpty) ...[
            const SectionHeader('Local hosts & guides'),
            for (final h in hosts)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: OutlineCard(
                  child: Row(
                    children: [
                      TintIcon(
                        h.type == HostType.homestay
                            ? Icons.cottage_outlined
                            : Icons.hiking_outlined,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(h.name, style: t.titleSmall),
                            Text(
                              '${h.type.label} · ${h.price}',
                              style: t.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            GenderRatingCompact(
                              ratings: h.ratings,
                              showStar: false,
                              barWidth: 44,
                            ),
                          ],
                        ),
                      ),
                      RatingLabel(h.rating),
                    ],
                  ),
                ),
              ),
          ],
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: InfoNote(
              'Indian visitors need an ILP; foreign nationals need a PAP. '
              'See the Permits tab.',
              icon: Icons.badge_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthStrip extends StatelessWidget {
  const _MonthStrip({required this.place, required this.now});
  final Place place;
  final int now;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        for (var m = 1; m <= 12; m++)
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: switch (place.statusFor(m)) {
                      SeasonStatus.best => AppColors.greenTint,
                      SeasonStatus.risky => AppColors.redTint,
                      SeasonStatus.okay => AppColors.surfaceSoft,
                    },
                    border: m == now
                        ? Border.all(color: AppColors.blue, width: 1.5)
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  monthShort[m - 1][0],
                  style: t.labelSmall?.copyWith(
                    color: m == now ? AppColors.blue : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
