import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'loyalty_brand.dart';

/// Préfixes code-barres appris localement (scan + choix manuel enseigne).
abstract final class LoyaltyPrefixStore {
  static const _key = 'loyalty_brand_prefixes';
  static const _storage = FlutterSecureStorage();

  static Map<String, List<String>> _cache = {};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    final raw = await _storage.read(key: _key);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _cache = map.map(
          (k, v) => MapEntry(k, (v as List).cast<String>()),
        );
      } catch (_) {
        _cache = {};
      }
    }
    _loaded = true;
  }

  static Future<void> _persist() async {
    await _storage.write(key: _key, value: jsonEncode(_cache));
  }

  /// Enregistre le préfixe du code scanné pour une enseigne choisie.
  static Future<void> learn(String rawBarcode, String brandId) async {
    await load();
    final digits = rawBarcode.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6) return;

    final candidates = <String>{
      if (digits.length >= 13) digits.substring(0, 7),
      if (digits.length >= 12) digits.substring(0, 6),
      if (digits.length >= 10) digits.substring(0, 8),
      if (digits.length >= 9) digits.substring(0, 9),
    };

    final list = _cache.putIfAbsent(brandId, () => []);
    var changed = false;
    for (final p in candidates) {
      if (!list.contains(p)) {
        list.add(p);
        changed = true;
      }
    }
    if (changed) await _persist();
  }

  /// Cherche une enseigne via préfixes appris ou catalogue.
  static LoyaltyBrand? matchBarcode(String rawValue) {
    final digits = rawValue.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    String? bestBrandId;
    var bestLen = 0;

    void consider(String brandId, List<String> prefixes) {
      for (final p in prefixes) {
        if (digits.startsWith(p) && p.length > bestLen) {
          bestLen = p.length;
          bestBrandId = brandId;
        }
      }
    }

    for (final entry in _cache.entries) {
      consider(entry.key, entry.value);
    }
    for (final brand in LoyaltyBrand.catalog) {
      consider(brand.id, brand.codePrefixes);
    }

    return bestBrandId != null ? LoyaltyBrand.byId(bestBrandId) : null;
  }
}
