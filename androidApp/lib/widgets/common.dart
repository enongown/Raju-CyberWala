import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// White card with a 1px light-grey border and no shadow.
class OutlineCard extends StatelessWidget {
  const OutlineCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.white,
    this.borderColor = AppColors.border,
    this.radius = 16,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor),
    );
    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: t.bodySmall),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// A large, quiet page heading used at the top of each tab.
class PageHeading extends StatelessWidget {
  const PageHeading(this.title, {super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.headlineSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: t.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Small coloured dot followed by a label.
class DotLabel extends StatelessWidget {
  const DotLabel(this.text, {super.key, required this.color, this.style});

  final String text;
  final Color color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style:
                style ??
                Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// A tiny tinted pill, e.g. "Verified", "Best time", "Pending".
class TonePill extends StatelessWidget {
  const TonePill(this.text, {super.key, required this.color, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bg = Color.alphaBlend(color.withValues(alpha: 0.10), Colors.white);
    final fg = Color.lerp(color, Colors.black, 0.25)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class RatingLabel extends StatelessWidget {
  const RatingLabel(this.rating, {super.key, this.count});

  final double rating;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 16, color: AppColors.yellow),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: t.labelMedium?.copyWith(color: AppColors.text),
        ),
        if (count != null)
          Text(
            ' ($count)',
            style: t.labelMedium?.copyWith(color: AppColors.textTertiary),
          ),
      ],
    );
  }
}

class VerifiedPill extends StatelessWidget {
  const VerifiedPill({super.key, required this.verified});
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return verified
        ? const TonePill(
            'Verified',
            color: AppColors.blue,
            icon: Icons.verified_outlined,
          )
        : const TonePill(
            'Verification pending',
            color: AppColors.yellow,
            icon: Icons.schedule_outlined,
          );
  }
}

/// Grey info line used for "approximate" disclaimers.
class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key, this.icon = Icons.info_outline});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

/// Round icon container with a soft tint, used as a leading visual.
class TintIcon extends StatelessWidget {
  const TintIcon(
    this.icon, {
    super.key,
    this.color = AppColors.blue,
    this.size = 40,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.10), Colors.white),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

/// The four Google colour dots, used as a tiny brand mark.
class BrandDots extends StatelessWidget {
  const BrandDots({super.key, this.size = 8});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in AppColors.accents)
          Container(
            width: size,
            height: size,
            margin: EdgeInsets.only(right: size * 0.6),
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
      ],
    );
  }
}

void showSoonSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Quiet app-bar mark: four colour dots + app name (+ optional role pill).
class AppBarBrand extends StatelessWidget {
  const AppBarBrand({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandDots(size: 6),
        const SizedBox(width: 6),
        Text(
          'Explore Arunachal',
          style: t.titleMedium?.copyWith(
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 8),
          TonePill(label!, color: AppColors.blue),
        ],
      ],
    );
  }
}

/// App bar for detail pages: back button, a small "Explore Arunachal"
/// caption and the page [title] (e.g. the host or guide name).
AppBar detailAppBar(
  BuildContext context,
  String title, {
  List<Widget>? actions,
}) {
  final t = Theme.of(context).textTheme;
  return AppBar(
    toolbarHeight: 64,
    // Line the title up with the page padding when there is no back button.
    titleSpacing: Navigator.of(context).canPop() ? 0 : 20,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Explore Arunachal',
          style: t.labelMedium?.copyWith(color: AppColors.textTertiary),
        ),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    ),
    actions: actions,
  );
}
