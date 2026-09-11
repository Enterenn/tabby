import 'package:flutter/material.dart';

/// Seed de secours + tokens métier (success / warning).
///
/// En priorité, le [ColorScheme] vient de Dynamic Color (système).
/// [seed] n'est utilisée que si la plateforme n'en fournit pas.
abstract final class AppColors {
  /// Seed de secours (logo Tabby) — utilisée seulement si le système
  /// n'expose pas de Dynamic Color (Android 12+, accent Windows/macOS…).
  static const Color seed = Color(0xFFFFDB5A);

  static const Color success = Color(0xFF2EAA6B);
  static const Color onSuccessLight = Color(0xFFFFFFFF);
  static const Color successContainerLight = Color(0xFFB8FFD9);
  static const Color onSuccessContainerLight = Color(0xFF002114);

  static const Color successDark = Color(0xFF6BFFB0);
  static const Color onSuccessDark = Color(0xFF002114);
  static const Color successContainerDark = Color(0xFF005233);
  static const Color onSuccessContainerDark = Color(0xFFB8FFD9);

  static const Color warning = Color(0xFFFF9800);
  static const Color onWarningLight = Color(0xFF2E2A22);
  static const Color warningContainerLight = Color(0xFFFFE0B2);
  static const Color onWarningContainerLight = Color(0xFF3D2800);

  static const Color warningDark = Color(0xFFFFB74D);
  static const Color onWarningDark = Color(0xFF3D2800);
  static const Color warningContainerDark = Color(0xFF6B4400);
  static const Color onWarningContainerDark = Color(0xFFFFE0B2);
}
