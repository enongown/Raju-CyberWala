import 'package:flutter/material.dart';

/// Google-style palette. Blue is the only "loud" colour; the others are
/// used sparingly as small dots, chips and status indicators.
abstract final class AppColors {
  static const blue = Color(0xFF1A73E8);
  static const red = Color(0xFFEA4335);
  static const yellow = Color(0xFFFBBC05);
  static const green = Color(0xFF34A853);

  static const white = Color(0xFFFFFFFF);
  static const text = Color(0xFF202124);
  static const textSecondary = Color(0xFF5F6368);
  static const textTertiary = Color(0xFF80868B);
  static const border = Color(0xFFE3E5E8);
  static const borderStrong = Color(0xFFDADCE0);
  static const surfaceSoft = Color(0xFFF8F9FA);
  static const searchFill = Color(0xFFF1F3F4);
  static const blueTint = Color(0xFFE8F0FE);
  static const greenTint = Color(0xFFE6F4EA);
  static const redTint = Color(0xFFFCE8E6);
  static const yellowTint = Color(0xFFFEF7E0);

  /// Rating split by rater gender (women / men), from the reference design.
  static const women = Color(0xFFFF6FAE);
  static const men = Color(0xFF00A3FF);
  static const womenTint = Color(0xFFFFEAF3);
  static const womenDeep = Color(0xFFC2185B);

  static const accents = [blue, red, yellow, green];
}
