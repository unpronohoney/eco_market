import 'package:flutter/material.dart';

/// Application color palette for EcoMarket
/// Uses green tones for eco-friendly branding
class AppColors {
  AppColors._();

  // Primary Colors - Green (Eco-friendly theme)
  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color primaryGreenLight = Color(0xFFDCFCE7);
  static const Color primaryGreenDark = Color(0xFF16A34A);

  // Discount & Accent
  static const Color discountRed = Color(0xFFEF4444);
  static const Color accentOrange = Color(0xFFF97316);

  // Neutrals
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color divider = Color(0xFFE2E8F0);

  // Map Marker
  static const Color markerGreen = Color(0xFF22C55E);
  static const Color markerShadow = Color(0x4022C55E);

  // Gradients
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, primaryGreenDark],
  );
}
