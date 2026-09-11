import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Seeds M3 ───────────────────────────────────────────────────────────────
  /// Primaire : jaune or chaud.
  static const Color primary   = Color(0xFFFFDB5A);
  /// Secondaire : indigo-violet froid.
  static const Color secondary = Color(0xFF6C5CE7);
  /// Tertiaire : teal-menthe froid.
  static const Color tertiary  = Color(0xFF00B4A2);

  // ── Containers secondary (light / dark) ───────────────────────────────────
  static const Color secondaryContainerLight    = Color(0xFFE4E0FF);
  static const Color onSecondaryContainerLight  = Color(0xFF1A006E);
  static const Color secondaryDark              = Color(0xFFB0A8FF);
  static const Color onSecondaryDark            = Color(0xFF1A006E);
  static const Color secondaryContainerDark     = Color(0xFF3B2D8A);
  static const Color onSecondaryContainerDark   = Color(0xFFE4E0FF);

  // ── Containers tertiary (light / dark) ────────────────────────────────────
  static const Color tertiaryContainerLight    = Color(0xFFC0F4EE);
  static const Color onTertiaryContainerLight  = Color(0xFF00201C);
  static const Color tertiaryDark              = Color(0xFF82E8DE);
  static const Color onTertiaryDark            = Color(0xFF00201C);
  static const Color tertiaryContainerDark     = Color(0xFF005048);
  static const Color onTertiaryContainerDark   = Color(0xFFC0F4EE);

  // ── Sémantique métier ──────────────────────────────────────────────────────
  static const Color success = Color(0xFF4C9A6A);
  static const Color danger  = Color(0xFFE4573D);
  static const Color warning = Color(0xFFF0932B);

  // ── Palette catégories ─────────────────────────────────────────────────────
  static const List<Color> categoryPalette = [
    Color(0xFFFF6B35),
    Color(0xFF4C9A6A),
    Color(0xFF6C5CE7),
    Color(0xFF00B4A2),
    Color(0xFFFF4B8B),
    Color(0xFF4A90D9),
    Color(0xFFE74C3C),
    Color(0xFF7F8C8D),
    Color(0xFFE67E22),
    Color(0xFF1ABC9C),
  ];

  // ── Avatar palette ─────────────────────────────────────────────────────────
  static const List<Color> avatarPalette = [
    Color(0xFFFF6B35),
    Color(0xFF6C5CE7),
    Color(0xFF00B4A2),
    Color(0xFFFF4B8B),
    Color(0xFF4A90D9),
  ];
}
