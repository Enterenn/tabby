import 'package:flutter/material.dart';

/// Triade POLA + tokens métier (success / warning).
///
/// Primary = cobalt ([seed]). Secondary = vermillon. Tertiary = citron.
abstract final class AppColors {
  /// POLA Cobalt — seed du [ColorScheme] (primary).
  static const Color seed = Color(0xFF0053E1);

  /// POLA citron — [ColorScheme.tertiary].
  static const Color lemon = Color(0xFFFEF335);
  static const Color onLemon = Color(0xFF1D1D1D);
  static const Color lemonInk = Color(0xFF8F8500);
  static const Color lemonContainerDark = Color(0xFF3D3800);
  static const Color onLemonContainerDark = Color(0xFFFEF335);

  /// POLA vermillon — [ColorScheme.secondary].
  static const Color vermillion = Color(0xFFFF4617);
  static const Color onVermillion = Color(0xFFFFFFFF);
  static const Color vermillionContainerLight = Color(0xFFFFDAD4);
  static const Color onVermillionContainerLight = Color(0xFF3B0900);
  static const Color vermillionContainerDark = Color(0xFF6B1600);
  static const Color onVermillionContainerDark = Color(0xFFFFDAD4);

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
