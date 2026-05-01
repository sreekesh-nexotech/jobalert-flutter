import 'package:flutter/material.dart';

/// Frappe UI color tokens, ported from `colors_and_type.css`.
///
/// The design uses a light-mode palette with a warm accent (`brand`) on a
/// near-white surface — the auth screens lean on `ink900` for primary CTAs
/// while the main shell switches to a warm orange accent.
class AppColors {
  AppColors._();

  // ── Brand / accent ──
  /// Warm orange accent used by the main app (banner CTAs, points card,
  /// active nav indicator, "View all" links).
  static const Color brand = Color(0xFFC8783A);
  static const Color brandLight = Color(0xFFD4956A);

  /// Auth-flow primary uses Frappe `--blue-500` for links + focus rings.
  static const Color blue500 = Color(0xFF0289F7);
  static const Color blue700 = Color(0xFF0070CC);

  /// Soft sage used for "saved" surfaces and success accents in the main app.
  static const Color sage = Color(0xFF5A7A52);
  static const Color sageBg = Color(0xFFEDF2EC);

  /// Banner peach background.
  static const Color peachBg = Color(0xFFFFF5EB);

  /// Quick-card warm beige.
  static const Color beigeBg = Color(0xFFF0EDE6);

  // ── Ink (text) ──
  static const Color ink900 = Color(0xFF171717);
  static const Color ink800 = Color(0xFF383838);
  static const Color ink700 = Color(0xFF525252);
  static const Color ink600 = Color(0xFF7C7C7C);
  static const Color ink500 = Color(0xFF999999);
  static const Color ink400 = Color(0xFFC7C7C7);
  static const Color ink300 = Color(0xFFE2E2E2);
  static const Color ink200 = Color(0xFFEDEDED);
  static const Color ink100 = Color(0xFFF3F3F3);
  static const Color ink50 = Color(0xFFF8F8F8);

  // ── Surfaces ──
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFFAFAFA);
  static const Color surfaceDeep = Color(0xFFE8EAED);
  static const Color outline = Color(0xFFEDEDED);
  static const Color outlineStrong = Color(0xFFE2E2E2);

  // ── Status ──
  static const Color success = Color(0xFF30A66D);
  static const Color successBg = Color(0xFFDFFCE8);
  static const Color warning = Color(0xFFE79913);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFE03636);
  static const Color dangerBg = Color(0xFFFFE7E7);
  static const Color info = Color(0xFF2563EB);
  static const Color infoBg = Color(0xFFDBEAFE);

  // ── Card label backgrounds (rgba in the design) ──
  static const Color labelTrendingBg = Color(0xEAFEF3C7);
  static const Color labelTrendingFg = Color(0xFFD97706);
  static const Color labelNewBg = Color(0xEAD1FAE5);
  static const Color labelNewFg = Color(0xFF059669);
  static const Color labelFeaturedBg = Color(0xEADBEAFE);
  static const Color labelFeaturedFg = Color(0xFF2563EB);
  static const Color labelVerifiedBg = Color(0xE0111111);
  static const Color labelVerifiedFg = Color(0xFFFFFFFF);
  static const Color labelExpiredBg = Color(0xEAF3F3F3);
  static const Color labelExpiredFg = Color(0xFF999999);
}
