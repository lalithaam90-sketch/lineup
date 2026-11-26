import 'package:flutter/material.dart';

class AppColors {
  // Brand Deep Emerald & Dark Teal Gradients
  static const Color primaryDark = Color(0xFF04201B);
  static const Color primaryMid = Color(0xFF083C33);
  static const Color primary = Color(0xFF0B4C41);
  static const Color primaryLight = Color(0xFF116959);

  // Mint & Cyan Accents
  static const Color accentMint = Color(0xFF10B981);
  static const Color accentCyan = Color(0xFF14B8A6);
  static const Color accentTeal = Color(0xFF2DD4BF);
  static const Color accentLightMint = Color(0xFFE6F4EA);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF7F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFE8EEF3);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGreen = Color(0xFF059669);

  // Channel Specific Colors
  static const Color whatsappGreen = Color(0xFF25D366);
  static const Color whatsappDark = Color(0xFF075E54);
  static const Color whatsappSurface = Color(0xFF0E2E28);

  // Instagram Gradients
  static const List<Color> instagramGradient = [
    Color(0xFF833AB4),
    Color(0xFFC13584),
    Color(0xFFE1306C),
    Color(0xFFFD1D1D),
    Color(0xFFF77737),
    Color(0xFFFCB045),
  ];

  // Brand Header Gradient
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF031E19),
      Color(0xFF083830),
      Color(0xFF0C4D42),
    ],
  );

  // Splash Screen Gradient
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF021713),
      Color(0xFF062D26),
      Color(0xFF0B463B),
    ],
  );

  // Instagram Banner Gradient
  static const LinearGradient igBannerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6B21A8),
      Color(0xFFA855F7),
      Color(0xFFEC4899),
      Color(0xFFF97316),
    ],
  );

  // Trend Badges
  static const Color trendUp = Color(0xFF10B981);
  static const Color trendUpBg = Color(0xFFEBFDF5);
}
