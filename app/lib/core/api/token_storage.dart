import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage chiffré des tokens JWT (Keystore Android / Keychain iOS).
class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userIdKey = 'user_id';

  // v11+: AES-GCM + RSA OAEP key wrapping par défaut — aucun paramètre requis.
  static const _storage = FlutterSecureStorage();

  String? _cachedAccess;
  String? _cachedRefresh;
  String? _cachedUserId;

  String? get accessToken => _cachedAccess;
  String? get refreshToken => _cachedRefresh;
  String? get userId => _cachedUserId;
  bool get hasTokens => _cachedAccess != null;

  /// Charge les tokens depuis le stockage sécurisé au démarrage.
  Future<void> load() async {
    _cachedAccess = await _storage.read(key: _accessKey);
    _cachedRefresh = await _storage.read(key: _refreshKey);
    _cachedUserId = await _storage.read(key: _userIdKey);
  }

  Future<void> save({
    required String access,
    required String refresh,
    String? userId,
  }) async {
    _cachedAccess = access;
    _cachedRefresh = refresh;
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
    if (userId != null) {
      _cachedUserId = userId;
      await _storage.write(key: _userIdKey, value: userId);
    }
  }

  Future<void> clear() async {
    _cachedAccess = null;
    _cachedRefresh = null;
    _cachedUserId = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userIdKey);
  }
}

late TokenStorage tokenStorage;

Future<void> initTokenStorage() async {
  tokenStorage = TokenStorage();
  await tokenStorage.load();
}
