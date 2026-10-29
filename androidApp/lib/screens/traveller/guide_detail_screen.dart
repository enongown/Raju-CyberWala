import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/trip_calculator.dart';
import '../../theme/app_colors.dart';
import '../../widgets/call_request_bar.dart';
import '../../widgets/common.dart';
import '../../widgets/fade_in.dart';
import '../../widgets/gender_rating.dart';
import '../../widgets/photo_placeholder.dart';
import '../../widgets/rating_ring.dart';
import '../../widgets/visuals.dart';

/// Large initials shown on a guide's placeholder portrait.
class GuideInitials extends StatelessWidget {
  const GuideInitials({super.key, required this.guide, this.fontSize = 44});
  final Guide guide;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = PhotoPlaceholder.colorsFor(guide.palette);
    return Align(
      alignment: const Alignment(0, -0.15),
      child: Container(
        width: fontSize * 2,
        height: fontSize * 2,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Text(
          guide.initials,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: fontSize * 0.8,
            fontWeight: FontWeight.w500,
            color: c[3],
          ),
        ),
      ),
    );
  }
}

/// "Guide Selected": bio, portrait, key traits, score rings, past trips and
/// a sticky Call / Request bar.
class GuideDetailScreen extends StatelessWidget {
  const GuideDetailScreen({super.key, required this.guide});

  final Guide guide;

  static const _ringColors = [
    AppColors.blue,
    AppColors.green,
    Color(0xFFE8710A),
    Color(0xFFD01884),
  ];

  @override
  Widget build(BuildContext context) {
    final g = guide;
    final t = Theme.of(context).textTheme;
    var i = 0;
    return Scaffold(
      appBar: detailAppBar(context, '${g.name} (${g.tribe})'),
      bottomNavigationBar: CallRequestBar(
        summary: formatRupees(g.pricePerDay),
        summaryCaption: 'per day',
        onCall: () => callNumber(context, g.phone),
        onRequest: () => showRequestSentSheet(
          context,
          to: g.name,
          details: [
            'Guide: ${g.name} (${g.tribe})',
            g.specialty,
            '${formatRupees(g.pricePerDay)} per day · dates to be agreed',
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          FadeIn(
            index: i++,
            child: Text(
              '${g.years} years guiding · ${g.languages.join(', ')} · ${g.location}',
              style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
          FadeIn(
            index: i++,
            child: Row(
              children: [
                StarRow(g.rating),
                const SizedBox(width: 6),
                Text(
                  '${g.rating.toStringAsFixed(1)} · ${g.reviews} reviews',
                  style: t.labelLarge,
                ),
                const Spacer(),
                VerifiedPill(verified: g.verified),
              ],
            ),
          ),
          if (g.ratings.isWomenRecommended) ...[
            const SizedBox(height: 8),
            FadeIn(
              index: i++,
              child: const Align(
                alignment: Alignment.centerLeft,
                child: WomenRecommendedChip(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FadeIn(
            index: i++,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TonePill(g.specialty, color: AppColors.blue),
                      const SizedBox(height: 10),
                      Text(g.bio, style: t.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 124,
                  height: 156,
                  child: Hero(
                    tag: 'photo-${g.id}',
                    child: PhotoPlaceholder(
                      palette: g.palette,
                      radius: 18,
                      child: GuideInitials(guide: g, fontSize: 26),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FadeIn(
            index: i++,
            child: Text('Key Traits & Expertise', style: t.titleMedium),
          ),
          for (final tr in g.traits)
            FadeIn(
              index: i++,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 7, color: AppColors.blue),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${tr.title}. ',
                              style: t.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: tr.body,
                              style: t.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          FadeIn(
            index: i++,
            child: Text('Ratings', style: t.titleMedium),
          ),
          const SizedBox(height: 12),
          FadeIn(
            index: i++,
            child: OutlineCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Who rated ${g.name.split(' ').first}',
                    style: t.titleSmall,
                  ),
                  const SizedBox(height: 10),
                  GenderRatingSummary(ratings: g.ratings),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FadeIn(
            index: i++,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final (n, s) in g.scores.indexed)
                  RatingRing(
                    label: s.label,
                    score: s.score,
                    color: _ringColors[n % _ringColors.length],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FadeIn(
            index: i++,
            child: Text('Past trips', style: t.titleMedium),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 138,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: g.pastTrips.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, n) => FadeIn(
                index: n,
                child: _PastTripCard(
                  trip: g.pastTrips[n],
                  palette: g.palette + n + 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const InfoNote(
            'Sample guide profile. Verified guides have confirmed phone and '
            'ID with a local volunteer.',
          ),
        ],
      ),
    );
  }
}

class _PastTripCard extends StatelessWidget {
  const _PastTripCard({required this.trip, required this.palette});
  final PastTrip trip;
  final int palette;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 92,
            width: 150,
            child: PhotoPlaceholder(
              palette: palette,
              radius: 14,
              icon: pastTripIcon(trip.kind),
              iconSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            trip.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.labelLarge,
          ),
          Text(
            trip.area,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
