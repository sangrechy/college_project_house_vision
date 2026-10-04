import 'package:flutter/material.dart';

/// Neumorphism Soft UI Color System for House Vision.
/// Extracted from reference UI: soft slate off-white surfaces,
/// dual light/dark bevel shadows, deep slate typography, and vibrant coral orange accents.
abstract final class AppColors {
  // Brand Primary & Accents (Vibrant Coral Orange from reference chart/switches)
  static const Color primary = Color(0xFFED8943); // Warm Coral Orange
  static const Color primaryDark = Color(0xFFD6732D);
  static const Color primaryLight = Color(0xFFF8A86C);
  static const Color secondary = Color(0xFF2E384D); // Deep Slate Navy
  static const Color accentOrange = Color(0xFFED8943); // Safety / Metric Coral

  // Neumorphic Soft UI Backgrounds & Surfaces
  static const Color scaffoldBackground = Color(0xFFE8EEF5); // Soft Slate Canvas
  static const Color surface = Color(0xFFEDF1F7); // Extruded Neumorphic Card
  static const Color surfaceElevated = Color(0xFFF3F6FA); // High Convex Pill
  static const Color surfaceVariant = Color(0xFFE0E7F0); // Recessed / Inset Well
  static const Color glassBackground = Color(0xEEEDF1F7); // Frosted Soft UI

  // Status & Telemetry
  static const Color success = Color(0xFF10B981); // Emerald Metric
  static const Color successBackground = Color(0x2210B981);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningBackground = Color(0x22F59E0B);
  static const Color error = Color(0xFFEF4444); // Crimson Toggle Indicator
  static const Color errorBackground = Color(0x22EF4444);
  static const Color info = Color(0xFF3B82F6); // Technical Blue
  static const Color infoBackground = Color(0x223B82F6);

  // High-Contrast Typography & Separators
  static const Color textPrimary = Color(0xFF1E293B); // Deep Navy Slate
  static const Color textSecondary = Color(0xFF64748B); // Architectural Slate Gray
  static const Color textMuted = Color(0xFF94A3B8); // Soft Label Gray
  static const Color border = Color(0xFFD8E1EC); // Soft Bevel Edge
  static const Color borderHighlight = Color(0xFFCBD5E1); // Highlighted Border
  static const Color divider = Color(0xFFE2E8F0);

  // Neumorphic Shadow System (Dual Light & Dark Bevel)
  static const BoxShadow shadowLight = BoxShadow(
    color: Colors.white,
    offset: Offset(-4, -4),
    blurRadius: 10,
    spreadRadius: 1,
  );

  static final BoxShadow shadowDark = BoxShadow(
    color: const Color(0xFFA6B4C8).withValues(alpha: 0.52),
    offset: const Offset(4, 4),
    blurRadius: 10,
    spreadRadius: 1,
  );

  static final List<BoxShadow> neumorphicShadow = [
    shadowLight,
    shadowDark,
  ];

  static final List<BoxShadow> neumorphicPillShadow = [
    const BoxShadow(
      color: Colors.white,
      offset: Offset(-2, -2),
      blurRadius: 6,
    ),
    BoxShadow(
      color: const Color(0xFFA6B4C8).withValues(alpha: 0.45),
      offset: const Offset(2, 2),
      blurRadius: 6,
    ),
  ];

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
