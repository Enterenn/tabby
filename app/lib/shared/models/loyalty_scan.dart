import 'dart:convert';

import 'loyalty_brand.dart';
import 'loyalty_code_value.dart';
import 'loyalty_prefix_store.dart';

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
  static LoyaltyBrand? identify(
    LoyaltyScanPayload scan, {
    Iterable<String> knownBrandIds = const [],
  }) {
    final value = scan.value.trim();
    if (value.isEmpty) return null;

    if (scan.isQrCode) {
      final fromQr = _fromQrContent(value);
      if (fromQr != null) return fromQr;
    }

    final fromPrefix = LoyaltyPrefixStore.match(value);
    if (fromPrefix != null) return fromPrefix;

    return _pickShape(scan, knownBrandIds);
  }

  /// Enseignes plausibles pour le picker (forme du code + wallet).
  static List<LoyaltyBrand> suggestions(
    LoyaltyScanPayload scan, {
    Iterable<String> knownBrandIds = const [],
  }) {
    final matches = _shapeMatches(scan);
    if (matches.isEmpty) return const [];
    final known = knownBrandIds.toSet();
    matches.sort((a, b) {
      final ak = known.contains(a.id) ? 0 : 1;
      final bk = known.contains(b.id) ? 0 : 1;
      return ak.compareTo(bk);
    });
    return matches;
  }

  static LoyaltyBrand? _fromQrContent(String value) {
    final lower = value.toLowerCase();

    if (value.startsWith('{')) {
      try {
        final map = jsonDecode(value) as Map<String, dynamic>;
        for (final key in [
          'brand',
          'merchant',
          'store',
          'retailer',
          'enseigne',
        ]) {
          final raw = map[key];
          if (raw is String) {
            final brand = LoyaltyBrand.byName(raw);
            if (brand != null) return brand;
          }
        }
      } catch (_) {}
    }

    for (final brand in LoyaltyBrand.catalog) {
      for (final hint in brand.qrHints) {
        if (lower.contains(hint.toLowerCase())) return brand;
      }
    }

    return null;
  }

  static LoyaltyBrand? _pickShape(
    LoyaltyScanPayload scan,
    Iterable<String> knownBrandIds,
  ) {
    final matches = _shapeMatches(scan);
    if (matches.isEmpty) return null;
    if (matches.length == 1) return matches.first;
    final known = knownBrandIds.toSet();
    for (final brand in matches) {
      if (known.contains(brand.id)) return brand;
    }
    return null;
  }

  static List<LoyaltyBrand> _shapeMatches(LoyaltyScanPayload scan) {
    final compact = LoyaltyCodeValue.compact(scan.value).toUpperCase();
    if (compact.isEmpty) return const [];
    final matches = <LoyaltyBrand>[];
    for (final brand in LoyaltyBrand.catalog) {
      final pattern = brand.codePattern;
      if (pattern == null) continue;
      if (brand.codeKind == LoyaltyCodeKind.qrcode && !scan.isQrCode) {
        continue;
      }
      if (brand.codeKind == LoyaltyCodeKind.barcode && scan.isQrCode) {
        continue;
      }
      if (RegExp(pattern).hasMatch(compact)) matches.add(brand);
    }
    return matches;
  }
}
