import 'package:flutter/material.dart';

/// Cadence's palette. Kept as a small, named set rather than scattering hex
/// values through the widget tree — see AppTheme for how these become a
/// full Material 3 ColorScheme.
class AppColors {
  AppColors._();

  // "Ember" — a warm amber-gold signature accent. Distinct from the generic
  // Material purple seed and from the obvious Spotify-green move.
  static const Color ember = Color(0xFFF2A93B);

  static const Color accentEmber = Color(0xFFF2A93B);
  static const Color accentCoral = Color(0xFFFF6B5B);
  static const Color accentEmerald = Color(0xFF3ECF8E);
  static const Color accentAzure = Color(0xFF4C9AFF);
  static const Color accentViolet = Color(0xFF9B7BFF);
  static const Color accentRose = Color(0xFFFF6FA6);
  static const Color accentTeal = Color(0xFF2DD4BF);
  static const Color accentCrimson = Color(0xFFEF5350);

  static const List<NamedColor> accentOptions = [
    NamedColor('Ember', accentEmber),
    NamedColor('Coral', accentCoral),
    NamedColor('Emerald', accentEmerald),
    NamedColor('Azure', accentAzure),
    NamedColor('Violet', accentViolet),
    NamedColor('Rose', accentRose),
    NamedColor('Teal', accentTeal),
    NamedColor('Crimson', accentCrimson),
  ];

  static const Color lightBackground = Color(0xFFFBFAF8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0EEE9);

  static const Color darkBackground = Color(0xFF121214);
  static const Color darkSurface = Color(0xFF1A1A1D);
  static const Color darkSurfaceVariant = Color(0xFF232326);
  static const Color darkSurfaceRaised = Color(0xFF2A2A2E);

  static const Color amoledBackground = Color(0xFF000000);
  static const Color amoledSurface = Color(0xFF0A0A0A);
  static const Color amoledSurfaceVariant = Color(0xFF151515);
  static const Color amoledSurfaceRaised = Color(0xFF1C1C1C);

  static const Color success = Color(0xFF3ECF8E);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFF2A93B);

  static const List<Color> fallbackArtGradient = [
    Color(0xFF2A2A2E),
    Color(0xFF121214),
  ];
}

class NamedColor {
  final String label;
  final Color color;
  const NamedColor(this.label, this.color);
}
