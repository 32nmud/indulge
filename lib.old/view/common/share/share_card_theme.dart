import 'package:flutter/material.dart';

/// Shared palette and style constants for all share/export card widgets.
///
/// Using a single source of truth keeps every card — event share, overview
/// export, activity export, etc. — visually consistent without duplicating
/// colour values across files.
abstract final class ShareCardTheme {
  // ── Background ────────────────────────────────────────────────────────────

  static const Color bgTop = Color(0xFF1A1040);
  static const Color bgBottom = Color(0xFF0D0D1A);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgTop, bgBottom],
  );

  // ── Surfaces ──────────────────────────────────────────────────────────────

  /// Primary card / section surface.
  static const Color surface = Color(0xFF252040);

  /// Slightly elevated surface (e.g. subcategory headers, inner cards).
  static const Color surfaceHigh = Color(0xFF2E2850);

  /// Deepest recessed surface (e.g. nested subcategory containers).
  static const Color surfaceDeep = Color(0xFF1E1B38);

  // ── Accent ────────────────────────────────────────────────────────────────

  static const Color accent = Color(0xFF7C6FCD);
  static const Color accentDim = Color(0xFF5A4FA8);

  // ── Text ─────────────────────────────────────────────────────────────────

  static const Color textPrimary = Color(0xFFF0EEFF);
  static const Color textSecondary = Color(0xFFADA8CC);
  static const Color textMuted = Color(0xFF6B6490);

  // ── Borders / dividers ────────────────────────────────────────────────────

  static const Color divider = Color(0xFF3A3460);
  static const Color border = Color(0xFF3A3460);

  // ── Semantic colours ──────────────────────────────────────────────────────

  static const Color riskHigh = Color(0xFFEF5350);
  static const Color riskModerate = Color(0xFFFFB74D);
  static const Color riskLow = Color(0xFF66BB6A);
  static const Color riskVeryHigh = Color(0xFFB71C1C);

  static const Color solo = Color(0xFF42A5F5);
  static const Color couple = Color(0xFFAB47BC);
  static const Color group = Color(0xFFFFA726);

  // ── Dimensions ────────────────────────────────────────────────────────────

  /// Fixed logical width for all export cards. Capture at pixelRatio 3.0
  /// to produce a 1080 px wide image.
  static const double cardWidth = 360.0;

  /// Wide landscape card for the analysis export. At 1920 logical px the card
  /// renders like a dashboard infographic; capture at pixelRatio 2.0 to
  /// produce a crisp 3840 × N px image suitable for widescreen sharing.
  static const double analysisCardWidth = 1920.0;

  static const double cardRadius = 20.0;
  static const double sectionRadius = 10.0;
  static const double pillRadius = 20.0;

  static const EdgeInsets cardPadding = EdgeInsets.fromLTRB(20, 16, 20, 0);
  static const EdgeInsets sectionPadding = EdgeInsets.all(12);

  // ── Text styles ───────────────────────────────────────────────────────────

  static const TextStyle headingStyle = TextStyle(
    color: textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle subheadingStyle = TextStyle(
    color: textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );

  static const TextStyle bodyStyle = TextStyle(
    color: textPrimary,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle labelStyle = TextStyle(
    color: textSecondary,
    fontSize: 11,
  );

  static const TextStyle watermarkStyle = TextStyle(
    color: Color(0x4DADA8CC),
    fontSize: 9,
    letterSpacing: 0.4,
  );

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the semantic colour for a risk level string produced by
  /// [SexualHealthAnalysisData.riskLevel].
  static Color riskColor(String level) {
    switch (level) {
      case 'Low':
        return riskLow;
      case 'Moderate':
        return riskModerate;
      case 'High':
        return riskHigh;
      case 'Very High':
        return riskVeryHigh;
      default:
        return textSecondary;
    }
  }
}
