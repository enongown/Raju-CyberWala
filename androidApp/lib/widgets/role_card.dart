import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Large selectable card for the first-launch role choice. Selection animates
/// scale, border colour/width, background tint and a check mark.
class RoleCard extends StatelessWidget {
  const RoleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedScale(
        scale: selected ? 1.02 : 1.0,
        duration: _duration,
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: _duration,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.blueTint.withValues(alpha: 0.55)
                : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.blue : AppColors.borderStrong,
              width: selected ? 2 : 1,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: _duration,
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.blue
                            : AppColors.surfaceSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: t.titleLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: t.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: _duration,
                      transitionBuilder: (child, a) =>
                          ScaleTransition(scale: a, child: child),
                      child: selected
                          ? const Icon(
                              Icons.check_circle,
                              key: ValueKey('on'),
                              color: AppColors.blue,
                            )
                          : const Icon(
                              Icons.radio_button_unchecked,
                              key: ValueKey('off'),
                              color: AppColors.borderStrong,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
