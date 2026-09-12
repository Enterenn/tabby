/// Valeur d'un code fidélité (QR / code-barres / saisie).
///
/// Burger King, McDonald's et d'autres enseignes encodent des espaces
/// internes (`8DD C9Y D9L`). Les supprimer rend le code illisible en caisse.
abstract final class LoyaltyCodeValue {
  static final _internalSpace = RegExp(r'\s');
  static final _allWhitespace = RegExp(r'\s+');

  /// Bordures uniquement — les espaces au milieu restent.
  static String preserve(String raw) => raw.trim();

  /// Choisit la chaîne scannée qui garde le groupement d'origine.
  ///
  /// ML Kit expose parfois [rawValue] sans espaces et [displayValue] avec
  /// (ou l'inverse). Si les deux se réduisent au même payload, on garde
  /// celle qui contient encore les espaces.
  static String fromScan({
    String? rawValue,
    String? displayValue,
  }) {
    final raw = preserve(rawValue ?? '');
    final display = preserve(displayValue ?? '');
    if (raw.isEmpty) return display;
    if (display.isEmpty || raw == display) return raw;

    if (_compact(raw) != _compact(display)) {
      return raw;
    }
    if (_hasInternalSpace(raw) != _hasInternalSpace(display)) {
      return _hasInternalSpace(raw) ? raw : display;
    }
    return raw.length >= display.length ? raw : display;
  }

  static bool _hasInternalSpace(String value) =>
      _internalSpace.hasMatch(value);

  static String _compact(String value) =>
      value.replaceAll(_allWhitespace, '');
}
