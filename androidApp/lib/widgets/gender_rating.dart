import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/app_colors.dart';

/// Explains the women / men split wherever it is shown.
const genderRatingInfo =
    'Share of ratings by women and men. A high share from women can be a '
    'good sign for solo women travellers.';

/// Full rating summary: a big star with the average inside, two animated
/// bars (pink = women, blue = men) that grow from 0 on first show, the
/// review count and an info line.
class GenderRatingSummary extends StatelessWidget {
  const GenderRatingSummary({
    super.key,
    required this.ratings,
    this.showInfo = true,
  });

  final RatingBreakdown ratings;
  final bool showInfo;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = ratings;
    return Semantics(
      container: true,
      label: r.semanticsLabel,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              RatingStar(average: r.average, count: r.count),
              const SizedBox(width: 16),
              Expanded(
                child: r.hasGenderData
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ShareBar(
                            share: r.womenShare,
                            label: '${r.womenPercent}% women',
                            color: AppColors.women,
                          ),
                          const SizedBox(height: 8),
                          _ShareBar(
                            share: r.menShare,
                            label: '${r.menPercent}% men',
                            color: AppColors.men,
                          ),
                        ],
                      )
                    : Text(
                        r.count == 0
                            ? 'No ratings yet'
                            : 'Raters have not shared their gender yet',
                        style: t.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                r.count == 0
                    ? 'No reviews yet'
                    : '${r.count} review${r.count == 1 ? '' : 's'}'
                          '${r.hasGenderData ? ' · ${r.statedCount} shared gender' : ''}',
                style: t.labelMedium?.copyWith(color: AppColors.textSecondary),
              ),
              if (r.isWomenRecommended) const WomenRecommendedChip(),
            ],
          ),
          if (showInfo) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.info_outline,
                    size: 15,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    genderRatingInfo,
                    style: t.bodySmall?.copyWith(color: AppColors.textTertiary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Big yellow star with the average rating written inside it.
class RatingStar extends StatelessWidget {
  const RatingStar({
    super.key,
    required this.average,
    this.count = 1,
    this.size = 84,
  });

  final double average;
  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.star_rounded, size: size, color: AppColors.yellow),
          Align(
            alignment: const Alignment(0, 0.16),
            child: Text(
              count == 0 ? '–' : average.toStringAsFixed(1),
              style: TextStyle(
                fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
                fontSize: size * 0.25,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One rounded bar on a soft track; the label sits right-aligned inside the
/// filled part, or just after it when the bar is too short to hold it.
class _ShareBar extends StatelessWidget {
  const _ShareBar({
    required this.share,
    required this.label,
    required this.color,
  });

  final double share;
  final String label;
  final Color color;

  static const _height = 30.0;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge
        ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.text);
    return LayoutBuilder(
      builder: (context, c) {
        final labelWidth = (TextPainter(
          text: TextSpan(text: label, style: style),
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout()).width;
        final fullWidth = c.maxWidth;
        final inside = share * fullWidth >= labelWidth + 24;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: share.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) {
            final w = v * fullWidth;
            return SizedBox(
              height: _height,
              width: fullWidth,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.searchFill,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: w,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: inside ? null : (w + 8).clamp(0, fullWidth),
                    right: inside ? (fullWidth - w) + 12 : null,
                    child: Center(
                      child: Opacity(
                        opacity: (v / (share == 0 ? 1 : share)).clamp(0, 1),
                        child: Text(label, maxLines: 1, style: style),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Compact rating for list cards: star + average (+ count), then a thin
/// pink/blue split bar and "68% women".
class GenderRatingCompact extends StatelessWidget {
  const GenderRatingCompact({
    super.key,
    required this.ratings,
    this.showStar = true,
    this.showCount = true,
    this.showBadge = true,
    this.barWidth = 56,
  });

  final RatingBreakdown ratings;
  final bool showStar;
  final bool showCount;
  final bool showBadge;
  final double barWidth;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = ratings;
    return Tooltip(
      message: genderRatingInfo,
      child: Semantics(
        container: true,
        label: r.semanticsLabel,
        excludeSemantics: true,
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (showStar)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: AppColors.yellow,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    r.count == 0 ? 'New' : r.average.toStringAsFixed(1),
                    style: t.labelMedium?.copyWith(color: AppColors.text),
                  ),
                  if (showCount && r.count > 0)
                    Text(
                      ' (${r.count})',
                      style: t.labelMedium?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            if (r.hasGenderData)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GenderSplitBar(share: r.womenShare, width: barWidth),
                  const SizedBox(width: 6),
                  Text(
                    '${r.womenPercent}% women',
                    style: t.labelMedium?.copyWith(
                      color: AppColors.womenDeep,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            if (showBadge && r.isWomenRecommended)
              const WomenRecommendedChip(dense: true),
          ],
        ),
      ),
    );
  }
}

/// Thin rounded bar split pink (women) / blue (men); grows on first show.
class GenderSplitBar extends StatelessWidget {
  const GenderSplitBar({
    super.key,
    required this.share,
    this.width = 56,
    this.height = 6,
  });

  /// Women's share, 0.0–1.0.
  final double share;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: width,
        height: height,
        child: ColoredBox(
          color: AppColors.men,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: share.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: width * v,
                height: height,
                color: AppColors.women,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft pink "Women recommended" chip, shown when
/// [RatingBreakdown.isWomenRecommended] is true.
class WomenRecommendedChip extends StatelessWidget {
  const WomenRecommendedChip({super.key, this.dense = false});
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Tooltip(
      message:
          'At least ${(RatingBreakdown.womenRecommendedShare * 100).round()}% '
          'of raters are women and the average is '
          '${RatingBreakdown.womenRecommendedMinAverage.toStringAsFixed(1)}+',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10,
          vertical: dense ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: AppColors.womenTint,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_outlined,
              size: dense ? 13 : 15,
              color: AppColors.womenDeep,
            ),
            const SizedBox(width: 4),
            Text(
              'Women recommended',
              style: (dense ? t.labelSmall : t.labelMedium)?.copyWith(
                color: AppColors.womenDeep,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
