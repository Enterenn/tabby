import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage chiffré des tokens JWT (Keystore Android / Keychain iOS).
class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  // v11+: AES-GCM + RSA OAEP key wrapping par défaut — aucun paramètre requis.
  static const _storage = FlutterSecureStorage();

  String? _cachedAccess;
  String? _cachedRefresh;

  String? get accessToken => _cachedAccess;
  String? get refreshToken => _cachedRefresh;
  bool get hasTokens => _cachedAccess != null;

  /// Charge les tokens depuis le stockage sécurisé au démarrage.
  Future<void> load() async {
    _cachedAccess = await _storage.read(key: _accessKey);
    _cachedRefresh = await _storage.read(key: _refreshKey);
  }

  Future<void> save({required String access, required String refresh}) async {
    _cachedAccess = access;
    _cachedRefresh = refresh;
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> clear() async {
    _cachedAccess = null;
    _cachedRefresh = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

late TokenStorage tokenStorage;

Future<void> initTokenStorage() async {
  tokenStorage = TokenStorage();
  await tokenStorage.load();
}
