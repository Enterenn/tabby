/// Valeur d'un code fidélité (QR / code-barres / saisie).
///
/// Chez BK / McDo les espaces sont un habillage visuel. Le payload machine
/// (ce que la borne lit) est la [rawValue] du scan.
abstract final class LoyaltyCodeValue {
  static final _internalSpace = RegExp(r'\s');
  static final _allWhitespace = RegExp(r'\s+');

  /// Bordures uniquement — les espaces au milieu restent.
  static String preserve(String raw) => raw.trim();

  /// Payload encodé dans le code, pas le texte imprimé en dessous.
  static String fromScan({
    String? rawValue,
    String? displayValue,
  }) {
    final raw = preserve(rawValue ?? '');
    if (raw.isNotEmpty) return raw;
    return preserve(displayValue ?? '');
  }

  static bool _hasInternalSpace(String value) =>
      _internalSpace.hasMatch(value);

  static String compact(String value) =>
      preserve(value).replaceAll(_allWhitespace, '');

  static String _compact(String value) => compact(value);

  static final _alnum = RegExp(r'^[A-Z0-9]+$');

  /// Réinjecte le groupement enseigne si le scan a perdu les espaces.
  /// McDo `7CCVLHIA` → `7CCV LHIA` (4). BK `8DDC9YD9L` → `8DD C9Y D9L` (3).
  static String grouped(String raw, {int? groupSize}) {
    final preserved = preserve(raw);
    if (groupSize == null || groupSize < 2) return preserved;
    if (_hasInternalSpace(preserved)) return preserved;
    if (preserved.contains('://') || preserved.startsWith('{')) {
      return preserved;
    }
    final compact = _compact(preserved).toUpperCase();
    if (compact.length < groupSize * 2) return preserved;
    if (compact.length % groupSize != 0) return preserved;
    if (!_alnum.hasMatch(compact)) return preserved;
    final parts = <String>[];
    for (var i = 0; i < compact.length; i += groupSize) {
      parts.add(compact.substring(i, i + groupSize));
    }
    return parts.join(' ');
  }
}
