import 'package:flutter/material.dart';

/// Palette seed + tokens M3 Expressive (contraste tonal fort, accents saturés).
///
/// Réf. : https://m3.material.io/styles/color/overview
abstract final class AppColors {
  // ── Seeds M3 Expressive ────────────────────────────────────────────────────
  /// Jaune néon — action prioritaire.
  static const Color primary = Color(0xFFFFDB5A);
  static const Color onPrimaryLight = Color(0xFF2E2A22);
  static const Color primaryContainerLight = Color(0xFFFFE566);
  static const Color onPrimaryContainerLight = Color(0xFF3D3200);

  static const Color primaryDark = Color(0xFFFFE566);
  static const Color onPrimaryDark = Color(0xFF2E2A22);
  static const Color primaryContainerDark = Color(0xFF6B5A00);
  static const Color onPrimaryContainerDark = Color(0xFFFFE566);

  /// Violet vif — secondaire expressif.
  static const Color secondary = Color(0xFF7C4DFF);
  static const Color secondaryContainerLight = Color(0xFFE8DEFF);
  static const Color onSecondaryContainerLight = Color(0xFF21005D);
  static const Color secondaryDark = Color(0xFFB99AFF);
  static const Color onSecondaryDark = Color(0xFF21005D);
  static const Color secondaryContainerDark = Color(0xFF4A148C);
  static const Color onSecondaryContainerDark = Color(0xFFE8DEFF);

  /// Teal-menthe — tertiaire.
  static const Color tertiary = Color(0xFF00C9B7);
  static const Color tertiaryContainerLight = Color(0xFFB2FFF5);
  static const Color onTertiaryContainerLight = Color(0xFF00201C);
  static const Color tertiaryDark = Color(0xFF5CF2E3);
  static const Color onTertiaryDark = Color(0xFF00201C);
  static const Color tertiaryContainerDark = Color(0xFF005048);
  static const Color onTertiaryContainerDark = Color(0xFFB2FFF5);

  // ── Accents Expressive saturés ─────────────────────────────────────────────
  static const Color expressiveViolet = Color(0xFF7C4DFF);
  static const Color expressiveLime = Color(0xFFB8FF3C);
  static const Color expressivePink = Color(0xFFFF4B8B);
  static const Color expressiveYellow = Color(0xFFFFDB5A);

  static const Color expressiveVioletContainerLight = Color(0xFFE8DEFF);
  static const Color expressiveLimeContainerLight = Color(0xFFE8FFB2);
  static const Color expressivePinkContainerLight = Color(0xFFFFD9E8);
  static const Color expressiveYellowContainerLight = Color(0xFFFFF0A3);

  static const Color expressiveVioletDark = Color(0xFFB99AFF);
  static const Color expressiveLimeDark = Color(0xFFD4FF6B);
  static const Color expressivePinkDark = Color(0xFFFF8AB8);
  static const Color expressiveYellowDark = Color(0xFFFFE566);

  static const Color expressiveVioletContainerDark = Color(0xFF4A148C);
  static const Color expressiveLimeContainerDark = Color(0xFF3D5A00);
  static const Color expressivePinkContainerDark = Color(0xFF8B0040);
  static const Color expressiveYellowContainerDark = Color(0xFF6B5A00);

  // ── Sémantique métier ──────────────────────────────────────────────────────
  static const Color success = Color(0xFF2EAA6B);
  static const Color onSuccessLight = Color(0xFFFFFFFF);
  static const Color successContainerLight = Color(0xFFB8FFD9);
  static const Color onSuccessContainerLight = Color(0xFF002114);

  static const Color successDark = Color(0xFF6BFFB0);
  static const Color onSuccessDark = Color(0xFF002114);
  static const Color successContainerDark = Color(0xFF005233);
  static const Color onSuccessContainerDark = Color(0xFFB8FFD9);

  static const Color danger = Color(0xFFFF5252);
  static const Color onDangerLight = Color(0xFFFFFFFF);
  static const Color dangerContainerLight = Color(0xFFFFDAD6);
  static const Color onDangerContainerLight = Color(0xFF410002);

  static const Color dangerDark = Color(0xFFFF8A80);
  static const Color onDangerDark = Color(0xFF410002);
  static const Color dangerContainerDark = Color(0xFF93000A);
  static const Color onDangerContainerDark = Color(0xFFFFDAD6);

  static const Color warning = Color(0xFFFF9800);
  static const Color onWarningLight = Color(0xFF2E2A22);
  static const Color warningContainerLight = Color(0xFFFFE0B2);
  static const Color onWarningContainerLight = Color(0xFF3D2800);

  static const Color warningDark = Color(0xFFFFB74D);
  static const Color onWarningDark = Color(0xFF3D2800);
  static const Color warningContainerDark = Color(0xFF6B4400);
  static const Color onWarningContainerDark = Color(0xFFFFE0B2);

  // ── Palette catégories (saturée — création / édition) ──────────────────────
  static const List<Color> categoryPalette = [
    Color(0xFFFF6B35),
    Color(0xFF2EAA6B),
    Color(0xFF7C4DFF),
    Color(0xFF00C9B7),
    Color(0xFFFF4B8B),
    Color(0xFF4A90D9),
    Color(0xFFFF5252),
    Color(0xFF78909C),
    Color(0xFFFF9800),
    Color(0xFFB8FF3C),
  ];

  /// Tons harmonisés M3 Expressive — graphiques budget / donut (pas les hex DB).
  static const List<Color> chartPaletteLight = [
    secondary,
    tertiary,
    expressivePink,
    success,
    Color(0xFF6750A4),
    Color(0xFF006874),
    Color(0xFF984061),
    Color(0xFF7D5260),
  ];

  static const List<Color> chartPaletteDark = [
    secondaryDark,
    tertiaryDark,
    expressivePinkDark,
    successDark,
    Color(0xFFCCC2DC),
    Color(0xFF4FD8EB),
    Color(0xFFFFB1C8),
    Color(0xFFEFB8C8),
  ];

  // ── Surfaces Dark Expressive (plum profond) ────────────────────────────────
  static const Color surfaceDark = Color(0xFF120E1A);
  static const Color onSurfaceDark = Color(0xFFE8E0F0);
  static const Color surfaceContainerLowestDark = Color(0xFF0A0710);
  static const Color surfaceContainerLowDark = Color(0xFF161022);
  static const Color surfaceContainerDark = Color(0xFF1F1630);
  static const Color surfaceContainerHighDark = Color(0xFF2A2040);
  static const Color surfaceContainerHighestDark = Color(0xFF352A4D);

  // ── Avatar palette ─────────────────────────────────────────────────────────
  static const List<Color> avatarPalette = [
    Color(0xFFFF6B35),
    Color(0xFF7C4DFF),
    Color(0xFF00C9B7),
    Color(0xFFFF4B8B),
    Color(0xFF4A90D9),
  ];
}
