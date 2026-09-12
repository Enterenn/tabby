import 'dart:convert';

import 'loyalty_brand.dart';
import 'loyalty_code_value.dart';
import 'loyalty_prefix_store.dart';

/// Résultat d'un scan — valeur brute + type déduit.
class LoyaltyScanPayload {
  const LoyaltyScanPayload({
    required this.value,
    required this.isQrCode,
    this.visibleText = '',
  });

  final String value;
  final bool isQrCode;

  /// Texte lu autour du code (QR, OCR d'une capture Wallet…).
  final String visibleText;
}

/// Identification automatique d'une enseigne depuis un code scanné.
abstract final class LoyaltyBrandDetector {
  static LoyaltyBrand? identify(
    LoyaltyScanPayload scan, {
    Iterable<String> knownBrandIds = const [],
  }) {
    final value = scan.value.trim();
    if (value.isEmpty) return null;

    final fromPrefix = LoyaltyPrefixStore.match(value);
    if (fromPrefix != null) return fromPrefix;

    final fromText = _fromVisibleText(_haystack(scan));
    if (fromText != null) return fromText;

    return _pickShape(scan, knownBrandIds);
  }

  /// Enseignes plausibles pour le picker (préfixe, texte, forme, wallet).
  static List<LoyaltyBrand> suggestions(
    LoyaltyScanPayload scan, {
    Iterable<String> knownBrandIds = const [],
  }) {
    final matches = <LoyaltyBrand>[];
    final seen = <String>{};

    void add(LoyaltyBrand? brand) {
      if (brand == null || seen.contains(brand.id)) return;
      seen.add(brand.id);
      matches.add(brand);
    }

    add(LoyaltyPrefixStore.match(scan.value));
    add(_fromVisibleText(_haystack(scan)));
    for (final brand in _shapeMatches(scan)) {
      add(brand);
    }
    if (matches.isEmpty) return const [];

    final known = knownBrandIds.toSet();
    matches.sort((a, b) {
      final ak = known.contains(a.id) ? 0 : 1;
      final bk = known.contains(b.id) ? 0 : 1;
      return ak.compareTo(bk);
    });
    return matches;
  }

  static String _haystack(LoyaltyScanPayload scan) {
    final extra = scan.visibleText.trim();
    if (extra.isEmpty) return scan.value;
    return '${scan.value}\n$extra';
  }

  static LoyaltyBrand? _fromVisibleText(String value) {
    if (value.trim().isEmpty) return null;

    if (value.trimLeft().startsWith('{')) {
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

    final lower = value.toLowerCase();
    final compact = LoyaltyBrand.normalizeSearch(value);
    LoyaltyBrand? best;
    var bestScore = 0;
    var tied = false;

    for (final brand in LoyaltyBrand.catalog) {
      var score = 0;
      final name = LoyaltyBrand.normalizeSearch(brand.name);
      if (name.length >= 4 && compact.contains(name)) {
        score = name.length;
      }
      for (final hint in brand.qrHints) {
        final raw = hint.toLowerCase();
        final token = LoyaltyBrand.normalizeSearch(hint);
        if (token.length < 4) continue;
        if (lower.contains(raw) || compact.contains(token)) {
          if (token.length > score) score = token.length;
        }
      }
      for (final alias in brand.aliases) {
        final token = LoyaltyBrand.normalizeSearch(alias);
        if (token.length < 4) continue;
        if (compact.contains(token) && token.length > score) {
          score = token.length;
        }
      }
      if (score < 4) continue;
      if (score > bestScore) {
        bestScore = score;
        best = brand;
        tied = false;
      } else if (score == bestScore && best?.id != brand.id) {
        tied = true;
      }
    }

    if (tied) return null;
    return best;
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
