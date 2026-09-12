import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'loyalty_brand.dart';
import 'loyalty_code_value.dart';

/// Préfixes appris localement (scan + choix manuel enseigne).
abstract final class LoyaltyPrefixStore {
  static const _key = 'loyalty_brand_prefixes';
  static const _storage = FlutterSecureStorage();
  static final _alnum = RegExp(r'^[A-Z0-9]+$');
  static final _digitsOnly = RegExp(r'^\d+$');

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

  static List<String> get learnedBrandIds => _cache.keys.toList();

  static Future<void> _persist() async {
    await _storage.write(key: _key, value: jsonEncode(_cache));
  }

  /// Enregistre un préfixe (EAN ou alphanumérique, QR comme code-barres).
  static Future<void> learn(String rawCode, String brandId) async {
    await load();
    final compact = LoyaltyCodeValue.compact(rawCode).toUpperCase();
    final digits = compact.replaceAll(RegExp(r'\D'), '');
    final candidates = <String>{};

    if (digits.length >= 6) {
      if (digits.length >= 13) candidates.add(digits.substring(0, 7));
      if (digits.length >= 12) candidates.add(digits.substring(0, 6));
      if (digits.length >= 10) candidates.add(digits.substring(0, 8));
      if (digits.length >= 9) candidates.add(digits.substring(0, 6));
    }
    if (_alnum.hasMatch(compact) && compact.length >= 6) {
      candidates.add(compact.substring(0, 4));
      if (compact.length >= 8) candidates.add(compact.substring(0, 5));
    }
    if (candidates.isEmpty) return;

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

  /// Préfixes appris, puis catalogue EAN.
  static LoyaltyBrand? match(String rawValue) {
    final compact = LoyaltyCodeValue.compact(rawValue).toUpperCase();
    final digits = compact.replaceAll(RegExp(r'\D'), '');

    String? bestBrandId;
    var bestLen = 0;

    void consider(String brandId, String prefix, String haystack) {
      if (prefix.isEmpty || haystack.length < prefix.length) return;
      if (haystack.startsWith(prefix) && prefix.length > bestLen) {
        bestLen = prefix.length;
        bestBrandId = brandId;
      }
    }

    for (final entry in _cache.entries) {
      for (final prefix in entry.value) {
        if (_digitsOnly.hasMatch(prefix)) {
          consider(entry.key, prefix, digits);
        } else {
          consider(entry.key, prefix.toUpperCase(), compact);
        }
      }
    }
    for (final brand in LoyaltyBrand.catalog) {
      for (final prefix in brand.codePrefixes) {
        consider(brand.id, prefix, digits);
      }
    }

    return bestBrandId != null ? LoyaltyBrand.byId(bestBrandId) : null;
  }

  /// Conservé pour les appels existants.
  static LoyaltyBrand? matchBarcode(String rawValue) => match(rawValue);
}
