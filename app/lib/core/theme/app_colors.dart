import 'package:flutter/material.dart';

/// Tabby design system — couleurs tirées de la direction artistique
abstract final class AppColors {
  // Palette principale
  static const Color primary = Color(0xFFF2C230); // Jaune moutarde
  static const Color background = Color(0xFFFFF8E7); // Crème / blanc cassé
  static const Color surface = Color(0xFFFFFFFF); // Blanc (cartes)
  static const Color textPrimary = Color(0xFF2E2A22); // Anthracite chaud

  // Sémantique
  static const Color success = Color(0xFF4C9A6A); // Vert sauge — "on te doit"
  static const Color danger = Color(0xFFE4573D); // Corail/rouge — "tu dois" / budget dépassé
  static const Color warning = Color(0xFFF0932B); // Orange — proche du seuil
  static const Color accent = Color(0xFFF17C58); // Corail — CTA secondaire

  // Gris fonctionnels
  static const Color textSecondary = Color(0xFF8D8880);
  static const Color divider = Color(0xFFEDE8DC);
  static const Color disabled = Color(0xFFCBC6BA);

  // Palette catégories (camembert) — distincte de la palette principale
  static const List<Color> categoryPalette = [
    Color(0xFFE67E22), // orange
    Color(0xFF27AE60), // vert
    Color(0xFFE74C3C), // rouge
    Color(0xFF2980B9), // bleu
    Color(0xFF8E44AD), // violet
    Color(0xFF16A085), // teal
    Color(0xFFC0392B), // rouge foncé
    Color(0xFF7F8C8D), // gris
    Color(0xFFD35400), // orange foncé
    Color(0xFF1ABC9C), // turquoise
  ];
}
