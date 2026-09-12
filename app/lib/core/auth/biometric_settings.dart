import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Préférence biométrie (Keystore / Keychain). Indépendante des JWT.
class BiometricSettings {
  static const _enabledKey = 'biometric_enabled';
  static const _promptedKey = 'biometric_prompted';
  static const _storage = FlutterSecureStorage();

  bool enabled = false;
  bool prompted = false;

  Future<void> load() async {
    enabled = await _storage.read(key: _enabledKey) == '1';
    prompted = await _storage.read(key: _promptedKey) == '1';
  }

  Future<void> setEnabled(bool value) async {
    enabled = value;
    prompted = true;
    await _storage.write(key: _enabledKey, value: value ? '1' : '0');
    await _storage.write(key: _promptedKey, value: '1');
  }

  Future<void> markPrompted() async {
    prompted = true;
    await _storage.write(key: _promptedKey, value: '1');
  }
}

late BiometricSettings biometricSettings;

Future<void> initBiometricSettings() async {
  biometricSettings = BiometricSettings();
  await biometricSettings.load();
}
