import 'package:flutter/material.dart';

/// Design tokens verified by UI/UX Pro Max for Rendez
class AppColors {
  AppColors._();

  // Primary Accent (Amber)
  static const Color primary = Color(0xFFD97706); // Amber 600
  static const Color primaryHover = Color(0xFFB45309); // Amber 700
  static const Color primaryLight = Color(0xFFFEF3C7); // Amber 100
  static const Color primarySubtle = Color(0xFFFFFBEB); // Amber 50

  static const Color primaryText = Color(
    0xFF92400E,
  ); // Amber 800 (high contrast text)

  // Trust / Verified Accent (Emerald)
  static const Color verified = Color(0xFF059669); // Emerald 600
  static const Color verifiedLight = Color(0xFFD1FAE5); // Emerald 100

  // Base Neutrals (High Contrast Charcoal & Grays)
  static const Color neutral900 = Color(0xFF111827); // Gray 900 (Main text)
  static const Color neutral800 = Color(0xFF1F2937); // Gray 800
  static const Color neutral700 = Color(0xFF374151); // Gray 700
  static const Color neutral600 = Color(0xFF4B5563); // Gray 600
  static const Color neutral500 = Color(
    0xFF4B5563,
  ); // Gray 600 (WCAG AA 4.6:1 contrast on white for small text)
  static const Color neutral400 = Color(
    0xFF6B7280,
  ); // Gray 500 (3.9:1 contrast for secondary icons & subtle hints)
  static const Color neutral300 = Color(0xFFD1D5DB); // Gray 300
  static const Color neutral200 = Color(0xFFE5E7EB); // Gray 200 (Borders)
  static const Color neutral100 = Color(0xFFF3F4F6); // Gray 100 (Fill / Input)
  static const Color neutral50 = Color(0xFFF9FAFB); // Gray 50 (Card surface)

  // Pure surface & Editorial paper (Light)
  static const Color surface = Colors.white;
  static const Color surfaceWarm = Color(0xFFFFFDF9); // Warm ivory surface
  static const Color scaffoldBackground = Color(
    0xFFFAF8F5,
  ); // Warm paper background
  static const Color paperBorder = Color(0xFFF0EBE1); // Warm subtle card edge

  // Dark Mode Semantic Tokens (Espresso Noir & Dark Velvet)
  static const Color darkScaffoldBackground = Color(0xFF121214);
  static const Color darkSurface = Color(0xFF1C1C20);
  static const Color darkSurfaceWarm = Color(0xFF22201E);
  static const Color darkPaperBorder = Color(0xFF2C2B30);

  static const Color darkNeutral900 = Color(
    0xFFF4F4F5,
  ); // Main text in dark mode
  static const Color darkNeutral800 = Color(0xFFE4E4E7);
  static const Color darkNeutral700 = Color(0xFFD4D4D8);
  static const Color darkNeutral600 = Color(0xFFA1A1AA); // WCAG AA subtitle
  static const Color darkNeutral500 = Color(0xFF71717A);
  static const Color darkNeutral400 = Color(0xFF52525B);
  static const Color darkNeutral300 = Color(0xFF3F3F46);
  static const Color darkNeutral200 = Color(0xFF27272A); // Borders in dark mode
  static const Color darkNeutral100 = Color(0xFF1E1E22); // Input / Pill fill

  // Editorial Pastel Tag Palette (Light)
  static const Color sagePastel = Color(0xFFE8F3EB);
  static const Color sagePastelText = Color(0xFF235A36);

  static const Color peachPastel = Color(0xFFFDF0E7);
  static const Color peachPastelText = Color(0xFF9E441B);

  static const Color lilacPastel = Color(0xFFF3ECF8);
  static const Color lilacPastelText = Color(0xFF6B3A82);

  static const Color butterPastel = Color(0xFFFEF8E4);
  static const Color butterPastelText = Color(0xFF8B6414);

  static const Color skyPastel = Color(0xFFEAF3FC);
  static const Color skyPastelText = Color(0xFF1E5686);

  static const Color terracottaPastel = Color(0xFFF9ECE8);
  static const Color terracottaPastelText = Color(0xFF96372A);

  // Editorial Pastel Tag Palette (Dark)
  static const Color darkSagePastel = Color(0xFF162B1D);
  static const Color darkSagePastelText = Color(0xFF86EFAC);

  static const Color darkPeachPastel = Color(0xFF331E16);
  static const Color darkPeachPastelText = Color(0xFFFDBA74);

  static const Color darkLilacPastel = Color(0xFF2C1938);
  static const Color darkLilacPastelText = Color(0xFFD8B4FE);

  static const Color darkButterPastel = Color(0xFF332710);
  static const Color darkButterPastelText = Color(0xFFFDE047);

  static const Color darkSkyPastel = Color(0xFF142638);
  static const Color darkSkyPastelText = Color(0xFF93C5FD);

  static const Color darkTerracottaPastel = Color(0xFF361814);
  static const Color darkTerracottaPastelText = Color(0xFFFCA5A5);

  // Status
  static const Color destructive = Color(0xFFDC2626); // Red 600
  static const Color destructiveLight = Color(0xFFFEE2E2); // Red 100
  static const Color warning = Color(0xFFF59E0B); // Amber 500

  /// Get harmonious editorial pastel colors for vibe tags
  static ({Color bg, Color text}) getEditorialPastel(
    String vibe, {
    bool isDark = false,
  }) {
    final lower = vibe.toLowerCase();
    if (lower.contains('hẹn hò') ||
        lower.contains('date') ||
        lower.contains('lãng mạn')) {
      return isDark
          ? (bg: darkPeachPastel, text: darkPeachPastelText)
          : (bg: peachPastel, text: peachPastelText);
    }
    if (lower.contains('deadline') ||
        lower.contains('yên tĩnh') ||
        lower.contains('học')) {
      return isDark
          ? (bg: darkSagePastel, text: darkSagePastelText)
          : (bg: sagePastel, text: sagePastelText);
    }
    if (lower.contains('24/7') ||
        lower.contains('đêm') ||
        lower.contains('chill')) {
      return isDark
          ? (bg: darkLilacPastel, text: darkLilacPastelText)
          : (bg: lilacPastel, text: lilacPastelText);
    }
    if (lower.contains('nhóm') ||
        lower.contains('tụ tập') ||
        lower.contains('boardgame')) {
      return isDark
          ? (bg: darkButterPastel, text: darkButterPastelText)
          : (bg: butterPastel, text: butterPastelText);
    }
    if (lower.contains('check-in') ||
        lower.contains('sống ảo') ||
        lower.contains('view')) {
      return isDark
          ? (bg: darkTerracottaPastel, text: darkTerracottaPastelText)
          : (bg: terracottaPastel, text: terracottaPastelText);
    }
    return isDark
        ? (bg: darkSkyPastel, text: darkSkyPastelText)
        : (bg: skyPastel, text: skyPastelText);
  }
}
