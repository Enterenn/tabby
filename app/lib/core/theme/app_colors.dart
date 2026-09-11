import 'package:flutter/material.dart';

/// Seed HCT + tokens métier (success / warning).
///
/// Tous les rôles M3 (primary, secondary, tertiary, surfaces) viennent de
/// [ColorScheme.fromSeed] — ne pas ajouter d'accents UI ici.
abstract final class AppColors {
  /// Or Tabby — unique seed du [ColorScheme] Expressive.
  static const Color seed = Color(0xFFC9A227);

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
