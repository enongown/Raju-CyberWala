import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'transitions.dart';

/// Pure white, minimal Material 3 theme with Google Sans typography.
abstract final class AppTheme {
  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.blue,
          onPrimary: Colors.white,
          primaryContainer: AppColors.blueTint,
          onPrimaryContainer: const Color(0xFF0B57D0),
          secondary: AppColors.textSecondary,
          error: AppColors.red,
          surface: AppColors.white,
          onSurface: AppColors.text,
          onSurfaceVariant: AppColors.textSecondary,
          surfaceContainerLowest: AppColors.white,
          surfaceContainerLow: AppColors.white,
          surfaceContainer: AppColors.white,
          surfaceContainerHigh: AppColors.surfaceSoft,
          surfaceContainerHighest: AppColors.searchFill,
          outline: AppColors.borderStrong,
          outlineVariant: AppColors.border,
          surfaceTint: Colors.transparent,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.white,
      splashFactory: InkSparkle.splashFactory,
    );

    final textTheme = _googleSans(base.textTheme)
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text);

    final border = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.border),
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w400,
          letterSpacing: -0.2,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w400,
          letterSpacing: -0.1,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.4),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          height: 1.35,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.linux: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w400,
          color: AppColors.text,
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: border,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: AppColors.blueTint,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF0B57D0)
                : AppColors.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF0B57D0)
                : AppColors.textSecondary,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.blueTint,
        side: const BorderSide(color: AppColors.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: textTheme.labelLarge?.copyWith(color: AppColors.text),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: const Color(0xFF0B57D0),
        ),
        checkmarkColor: const Color(0xFF0B57D0),
        showCheckmark: true,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.searchFill,
          minimumSize: const Size(64, 52),
          shape: const StadiumBorder(),
          elevation: 0,
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blue,
          side: const BorderSide(color: AppColors.borderStrong),
          minimumSize: const Size(64, 44),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.borderStrong),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.blueTint
                : AppColors.white,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const Color(0xFF0B57D0)
                : AppColors.text,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        contentPadding: EdgeInsets.symmetric(horizontal: 20),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : AppColors.borderStrong,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.blue,
        linearTrackColor: AppColors.searchFill,
      ),
    );
  }

  /// Maps every style of [t] to Google Sans via the google_fonts package
  /// (font files are bundled in assets/google_fonts for offline use).
  static TextTheme _googleSans(TextTheme t) {
    TextStyle? g(TextStyle? s) =>
        s == null ? null : GoogleFonts.googleSans(textStyle: s);
    return t.copyWith(
      displayLarge: g(t.displayLarge),
      displayMedium: g(t.displayMedium),
      displaySmall: g(t.displaySmall),
      headlineLarge: g(t.headlineLarge),
      headlineMedium: g(t.headlineMedium),
      headlineSmall: g(t.headlineSmall),
      titleLarge: g(t.titleLarge),
      titleMedium: g(t.titleMedium),
      titleSmall: g(t.titleSmall),
      bodyLarge: g(t.bodyLarge),
      bodyMedium: g(t.bodyMedium),
      bodySmall: g(t.bodySmall),
      labelLarge: g(t.labelLarge),
      labelMedium: g(t.labelMedium),
      labelSmall: g(t.labelSmall),
    );
  }
}
