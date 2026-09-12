import 'package:flutter/services.dart';

import 'loyalty_brand.dart';

class LoyaltyLogoAsset {
  const LoyaltyLogoAsset({required this.path, required this.isSvg});

  final String path;
  final bool isSvg;
}

/// Logos déposés dans `assets/brands/` — SVG, PNG, JPG, WebP
/// (y compris un WebP mal nommé en `.svg`).
abstract final class LoyaltyBrandLogos {
  static const _folder = 'assets/brands/';
  static const _exts = {'svg', 'png', 'jpg', 'jpeg', 'webp'};

  static final Map<String, LoyaltyLogoAsset> _byStem = {};

  static Future<void> load() async {
    _byStem.clear();
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    for (final key in manifest.listAssets()) {
      if (!key.startsWith(_folder)) continue;
      final file = key.split('/').last;
      final dot = file.lastIndexOf('.');
      if (dot <= 0) continue;
      final stem = file.substring(0, dot);
      final ext = file.substring(dot + 1).toLowerCase();
      if (!_exts.contains(ext)) continue;
      final bytes = await rootBundle.load(key);
      _byStem[LoyaltyBrand.normalizeSearch(stem)] = LoyaltyLogoAsset(
        path: key,
        isSvg: _looksLikeSvg(bytes),
      );
    }
  }

  static LoyaltyLogoAsset? assetFor(LoyaltyBrand brand) {
    if (brand.logoAsset != null) {
      return LoyaltyLogoAsset(
        path: brand.logoAsset!,
        isSvg: brand.logoAsset!.toLowerCase().endsWith('.svg'),
      );
    }
    final fromId = _lookup(brand.id);
    if (fromId != null) return fromId;
    for (final alias in brand.aliases) {
      final hit = _lookup(alias);
      if (hit != null) return hit;
    }
    return _lookup(brand.name);
  }

  static LoyaltyLogoAsset? _lookup(String raw) =>
      _byStem[LoyaltyBrand.normalizeSearch(raw)];

  static bool _looksLikeSvg(ByteData data) {
    final n = data.lengthInBytes;
    if (n < 4) return false;
    final b0 = data.getUint8(0);
    final b1 = data.getUint8(1);
    if (b0 == 0x52 && b1 == 0x49) return false; // RIFF / WebP
    if (b0 == 0x89 && b1 == 0x50) return false; // PNG
    if (b0 == 0xFF && b1 == 0xD8) return false; // JPEG
    for (var i = 0; i < n && i < 64; i++) {
      final b = data.getUint8(i);
      if (b == 0x20 || b == 0x0A || b == 0x0D || b == 0x09) continue;
      return b == 0x3C; // '<'
    }
    return false;
  }
}
