import 'loyalty_code_value.dart';

enum LoyaltyBarcodeKind { ean13, ean8, upcA, code128 }

/// Choisit le symbologie 1D d'après le payload scanné.
///
/// Super / Picard = EAN-13. Petit pack = EAN-8. Reste (McDo, mixtes) = Code 128.
abstract final class LoyaltyBarcode {
  static final _digitsOnly = RegExp(r'^\d+$');

  static String machineValue(String raw) {
    final preserved = LoyaltyCodeValue.preserve(raw);
    final compact = LoyaltyCodeValue.compact(preserved);
    if (_digitsOnly.hasMatch(compact) && kind(compact) != LoyaltyBarcodeKind.code128) {
      return compact;
    }
    return preserved;
  }

  static LoyaltyBarcodeKind kind(String payload) {
    if (!_digitsOnly.hasMatch(payload)) return LoyaltyBarcodeKind.code128;
    return switch (payload.length) {
      13 when _validCheck(payload) => LoyaltyBarcodeKind.ean13,
      8 when _validCheck(payload) => LoyaltyBarcodeKind.ean8,
      12 when _validCheck(payload) => LoyaltyBarcodeKind.upcA,
      _ => LoyaltyBarcodeKind.code128,
    };
  }

  static bool _validCheck(String data) {
    final expected = _modulo10(data.substring(0, data.length - 1));
    return expected != null && expected == data[data.length - 1];
  }

  /// Même règle que le package `barcode` (EAN / UPC).
  static String? _modulo10(String body) {
    var sum = 0;
    var weight = body.length;
    for (final unit in body.codeUnits) {
      final n = unit - 0x30;
      if (n < 0 || n > 9) return null;
      sum += weight.isEven ? n : n * 3;
      weight--;
    }
    final mod = sum % 10;
    return mod == 0 ? '0' : '${10 - mod}';
  }
}
