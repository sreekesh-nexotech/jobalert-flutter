import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography tokens lifted from the Frappe UI scale used in
/// `colors_and_type.css`. We use Inter (loaded at runtime via google_fonts)
/// to match the prototype's `InterVar` font.
class AppText {
  AppText._();

  static TextStyle _base(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink900,
    double height = 1.15,
    double letterSpacing = 0.01 * 14,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ── UI scale (line-height 1.15) ──
  static TextStyle h1 = _base(24, weight: FontWeight.w600);
  static TextStyle h2 = _base(20, weight: FontWeight.w600);
  static TextStyle h3 = _base(18, weight: FontWeight.w600);
  static TextStyle h4 = _base(16, weight: FontWeight.w500);

  /// Auth screen titles ("Welcome back 👋", etc.).
  static TextStyle screenTitle = _base(
    22,
    weight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.025 * 22,
  );

  /// Auth subtitles.
  static TextStyle screenSubtitle = _base(
    13,
    color: AppColors.ink600,
    height: 1.5,
  );

  /// Form input label.
  static TextStyle formLabel = _base(
    12,
    weight: FontWeight.w600,
    color: AppColors.ink700,
  );

  static TextStyle body = _base(
    14,
    color: AppColors.ink800,
    height: 1.5,
    letterSpacing: 0.02 * 14,
  );

  static TextStyle caption = _base(
    12,
    color: AppColors.ink600,
    letterSpacing: 0.02 * 12,
  );

  static TextStyle captionMuted = _base(11, color: AppColors.ink400);

  // ── Main app sizes ──
  static TextStyle pageTitle = _base(
    19,
    weight: FontWeight.w600,
    letterSpacing: -0.03 * 19,
  );

  static TextStyle sectionTitle = _base(
    15,
    weight: FontWeight.w600,
    letterSpacing: -0.02 * 15,
  );

  static TextStyle cardTitle = _base(
    14,
    weight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.02 * 14,
  );

  static TextStyle button = _base(15, weight: FontWeight.w600, color: Colors.white);
}
