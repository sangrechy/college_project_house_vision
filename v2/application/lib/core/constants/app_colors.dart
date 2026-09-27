import 'package:flutter/material.dart';

/// Architectural Dark Studio color system for House Vision.
abstract final class AppColors {
  // Brand Primary & Cyber Accents
  static const Color primary = Color(0xFF06B6D4); // Electric Cyan
  static const Color primaryDark = Color(0xFF0891B2);
  static const Color primaryLight = Color(0xFF22D3EE);
  static const Color secondary = Color(0xFF3B82F6); // Technical Blue
  static const Color accentOrange = Color(0xFFF59E0B); // Safety Amber

  // Architectural Dark Backgrounds & Surfaces
  static const Color scaffoldBackground = Color(0xFF0B0F19); // Deep Carbon
  static const Color surface = Color(0xFF111827); // Dark Slate Surface
  static const Color surfaceElevated = Color(0xFF1F2937); // Elevated Card Surface
  static const Color surfaceVariant = Color(0xFF1A2234); // Interactive Surface
  static const Color glassBackground = Color(0xCC111827); // Frosted Glass

  // Status & Telemetry
  static const Color success = Color(0xFF10B981); // Laser Emerald
  static const Color successBackground = Color(0x2210B981);
  static const Color warning = Color(0xFFF59E0B); // Safety Amber
  static const Color warningBackground = Color(0x22F59E0B);
  static const Color error = Color(0xFFEF4444); // Crimson Alert
  static const Color errorBackground = Color(0x22EF4444);
  static const Color info = Color(0xFF38BDF8); // Sky Telemetry
  static const Color infoBackground = Color(0x2238BDF8);

  // High-Contrast Typography & Separators
  static const Color textPrimary = Color(0xFFF8FAFC); // Clean Polar White
  static const Color textSecondary = Color(0xFF94A3B8); // Architectural Gray
  static const Color textMuted = Color(0xFF64748B); // Dim Label Gray
  static const Color border = Color(0xFF1E293B); // Dark Grid Border
  static const Color borderHighlight = Color(0xFF334155); // Highlighted Border
  static const Color divider = Color(0xFF1E293B);

  // Architectural Material Customizer Palette
  static const List<Color> customizerPalette = [
    Color(0xFF64748B), // Polished Concrete
    Color(0xFF1E293B), // Matte Dark Steel
    Color(0xFFD97706), // Warm Scandinavian Timber
    Color(0xFF991B1B), // Terracotta Brick
    Color(0xFF06B6D4), // Electric Cyan Glass
    Color(0xFF10B981), // Green Living Wall
    Color(0xFFE2E8F0), // Architectural Off-White
    Color(0xFF78350F), // Natural Cedar Wood
  ];
}
