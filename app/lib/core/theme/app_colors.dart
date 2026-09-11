import 'package:flutter/material.dart';

/// Couleurs de marque et couleurs sémantiques qui ne font pas partie
/// du système M3 (succès, avertissement, catégories).
/// Pour les couleurs de l'interface (surface, fond, texte, etc.), utiliser
/// `Theme.of(context).colorScheme` qui est géré par le thème M3.
abstract final class AppColors {
  /// Couleur primaire de marque — seed du thème M3.
  static const Color primary = Color(0xFFF2C230);

  /// Sémantique métier (non couverte par M3)
  static const Color success = Color(0xFF4C9A6A); // "on te doit"
  static const Color danger = Color(0xFFE4573D);  // "tu dois" / dépassement budget
  static const Color warning = Color(0xFFF0932B); // proche du seuil budget

  /// Palette de couleurs pour les catégories (camembert / icônes)
  /// Distincte de la palette principale pour rester lisible.
  static const List<Color> categoryPalette = [
    Color(0xFFE67E22),
    Color(0xFF27AE60),
    Color(0xFFE74C3C),
    Color(0xFF2980B9),
    Color(0xFF8E44AD),
    Color(0xFF16A085),
    Color(0xFFC0392B),
    Color(0xFF7F8C8D),
    Color(0xFFD35400),
    Color(0xFF1ABC9C),
  ];
}
