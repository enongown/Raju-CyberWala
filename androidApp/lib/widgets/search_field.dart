import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Rounded grey search pill used at the top of Explore, Stays and Know the
/// Locals. Shows a clear button while typing and an optional [trailing]
/// action (e.g. camera search).
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.trailing,
    this.focusNode,
    this.onSubmitted,
    this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final Widget? trailing;
  final FocusNode? focusNode;

  /// Enter / search key on the keyboard.
  final ValueChanged<String>? onSubmitted;

  /// Called after the clear (x) button empties the field.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide.none,
    );
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          hintMaxLines: 1,
          // Long hints (Know the Locals) step down a size so they fit.
          hintStyle: hint.length > 32
              ? const TextStyle(fontSize: 14, color: AppColors.textSecondary)
              : null,
          filled: true,
          fillColor: AppColors.searchFill,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value.text.isNotEmpty)
                IconButton(
                  key: const ValueKey('search-clear'),
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                    onClear?.call();
                  },
                ),
              ?trailing,
              const SizedBox(width: 4),
            ],
          ),
          border: pill,
          enabledBorder: pill,
          focusedBorder: pill.copyWith(
            borderSide: const BorderSide(color: AppColors.blue),
          ),
        ),
      ),
    );
  }
}
