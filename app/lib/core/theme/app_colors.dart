import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Couleurs de seed M3 ─────────────────────────────────────────────────────
  /// Primaire : jaune or — seed du thème M3.
  static const Color primary   = Color(0xFFFFDB5A);
  /// Secondaire : corail-orange chaud.
  static const Color secondary = Color(0xFFFF6B35);
  /// Tertiaire : rose-magenta chaud.
  static const Color tertiary  = Color(0xFFFF4B8B);

  // ── Containers explicites (light / dark) ────────────────────────────────────
  // Secondary
  static const Color secondaryContainerLight = Color(0xFFFFDBCE);
  static const Color onSecondaryContainerLight = Color(0xFF4A1000);
  static const Color secondaryDark            = Color(0xFFFFB59A);
  static const Color onSecondaryDark          = Color(0xFF5C1700);
  static const Color secondaryContainerDark   = Color(0xFF8B3510);
  static const Color onSecondaryContainerDark = Color(0xFFFFDBCE);

  // Tertiary
  static const Color tertiaryContainerLight = Color(0xFFFFD7E9);
  static const Color onTertiaryContainerLight = Color(0xFF4A001C);
  static const Color tertiaryDark            = Color(0xFFFFB0CC);
  static const Color onTertiaryDark          = Color(0xFF5C0028);
  static const Color tertiaryContainerDark   = Color(0xFF8B0040);
  static const Color onTertiaryContainerDark = Color(0xFFFFD7E9);

  // ── Sémantique métier ───────────────────────────────────────────────────────
  static const Color success = Color(0xFF4C9A6A);
  static const Color danger  = Color(0xFFE4573D);
  static const Color warning = Color(0xFFF0932B);

  // ── Palette catégories ─────────────────────────────────────────────────────
  static const List<Color> categoryPalette = [
    Color(0xFFFF6B35), // coral-orange
    Color(0xFF4C9A6A), // emerald
    Color(0xFFFF4B8B), // rose
    Color(0xFF4A90D9), // sky blue
    Color(0xFF9B59B6), // violet
    Color(0xFF16A085), // teal
    Color(0xFFE74C3C), // red
    Color(0xFF7F8C8D), // slate
    Color(0xFFE67E22), // amber
    Color(0xFF1ABC9C), // mint
  ];

  // ── Avatar palette — warm & vivid ──────────────────────────────────────────
  static const List<Color> avatarPalette = [
    Color(0xFFFF6B35),
    Color(0xFFFF4B8B),
    Color(0xFF9B59B6),
    Color(0xFF4A90D9),
    Color(0xFF16A085),
  ];
}
