import 'dart:convert';

import 'loyalty_brand.dart';

/// Résultat d'un scan — valeur brute + type déduit.
class LoyaltyScanPayload {
  const LoyaltyScanPayload({
    required this.value,
    required this.isQrCode,
  });

  final String value;
  final bool isQrCode;
}

/// Identification automatique d'une enseigne depuis un code scanné.
abstract final class LoyaltyBrandDetector {
  /// Retourne la marque reconnue, ou null si inconnu.
  static LoyaltyBrand? identify(LoyaltyScanPayload scan) {
    final value = scan.value.trim();
    if (value.isEmpty) return null;

    if (scan.isQrCode) {
      final fromQr = _fromQrContent(value);
      if (fromQr != null) return fromQr;
    }

    final fromPrefix = _fromBarcodePrefix(value);
    if (fromPrefix != null) return fromPrefix;

    return null;
  }

  static LoyaltyBrand? _fromQrContent(String value) {
    final lower = value.toLowerCase();

    // JSON embarqué (apps wallet / fidélité).
    if (value.startsWith('{')) {
      try {
        final map = jsonDecode(value) as Map<String, dynamic>;
        for (final key in ['brand', 'merchant', 'store', 'retailer', 'enseigne']) {
          final raw = map[key];
          if (raw is String) {
            final brand = LoyaltyBrand.byName(raw);
            if (brand != null) return brand;
          }
        }
      } catch (_) {}
    }

    // URL ou texte contenant un indice marque.
    for (final brand in LoyaltyBrand.catalog) {
      for (final hint in brand.qrHints) {
        if (lower.contains(hint.toLowerCase())) return brand;
      }
    }

    return null;
  }

  static LoyaltyBrand? _fromBarcodePrefix(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    for (final brand in LoyaltyBrand.catalog) {
      for (final prefix in brand.codePrefixes) {
        if (digits.startsWith(prefix)) return brand;
      }
    }

    return null;
  }
}
