import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Circular score badge (out of 5) that fills in when first shown.
class RatingRing extends StatelessWidget {
  const RatingRing({
    super.key,
    required this.label,
    required this.score,
    required this.color,
    this.size = 58,
  });

  final String label;
  final double score;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: score / 5),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => SizedBox(
            width: size,
            height: size,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: v,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                  color: color,
                  backgroundColor: Color.alphaBlend(
                    color.withValues(alpha: 0.14),
                    Colors.white,
                  ),
                ),
                Center(
                  child: Text(
                    (v * 5).toStringAsFixed(1),
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: t.labelSmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Five small stars with partial fill, e.g. 4.8 -> 4 full + 1 mostly full.
class StarRow extends StatelessWidget {
  const StarRow(this.rating, {super.key, this.size = 18});
  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            rating >= i + 0.75
                ? Icons.star_rounded
                : rating >= i + 0.25
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded,
            size: size,
            color: AppColors.yellow,
          ),
      ],
    );
  }
}
