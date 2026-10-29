import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/app_colors.dart';
import 'common.dart';
import 'gender_rating.dart';
import 'photo_placeholder.dart';

/// Large listing card used for stays and guides: big rounded photo with a
/// favourite button, then title, details, price, rating and the
/// women / men split of raters.
class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.id,
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.price,
    required this.priceSuffix,
    required this.ratings,
    required this.onTap,
    this.icon,
    this.photoOverlay,
    this.badge,
  });

  /// Used for the Hero tag and favourites.
  final String id;
  final int palette;
  final IconData? icon;
  final Widget? photoOverlay;
  final Widget? badge;
  final String title;
  final String subtitle;
  final String details;
  final String price;
  final String priceSuffix;
  final RatingBreakdown ratings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'photo-$id',
                    child: PhotoPlaceholder(
                      palette: palette,
                      icon: icon,
                      child: photoOverlay,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: FavouriteButton(id: id),
                  ),
                  if (badge != null)
                    Positioned(top: 14, left: 14, child: badge!),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: RatingLabel(ratings.average, count: ratings.count),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
              child: Text(details, style: t.bodySmall),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: GenderRatingCompact(ratings: ratings, showStar: false),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SizeTransition(
                    sizeFactor: a,
                    axis: Axis.horizontal,
                    alignment: AlignmentDirectional.centerStart,
                    child: child,
                  ),
                ),
                child: Text.rich(
                  key: ValueKey('$price$priceSuffix'),
                  TextSpan(
                    children: [
                      TextSpan(
                        text: price,
                        style: t.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: ' $priceSuffix',
                        style: t.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
