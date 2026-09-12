import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:material_ui/material_ui.dart';

/// Choix utilisateur — `system` n'est pas un thème, c'est « suis l'OS ».
enum AppThemePreference { system, light, dark }

const kDefaultThemePreference = AppThemePreference.system;

AppThemePreference parseThemePreference(String? raw) => switch (raw) {
  'light' => AppThemePreference.light,
  'dark' => AppThemePreference.dark,
  _ => kDefaultThemePreference,
};

String themePreferenceToStorage(AppThemePreference preference) =>
    switch (preference) {
      AppThemePreference.light => 'light',
      AppThemePreference.dark => 'dark',
      AppThemePreference.system => 'system',
    };

class ThemeState {
  const ThemeState({this.preference = kDefaultThemePreference});

  final AppThemePreference preference;

  ThemeMode get materialThemeMode => switch (preference) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  @override
  bool operator ==(Object other) =>
      other is ThemeState && other.preference == preference;

  @override
  int get hashCode => preference.hashCode;
}

/// Persist KV (`system` | `light` | `dark`) — même clé que l'ancien cubit.
class ThemePrefs {
  const ThemePrefs({this._storage = const FlutterSecureStorage()});

  static const key = 'theme_mode';

  final FlutterSecureStorage _storage;

  Future<AppThemePreference> getThemeMode() async {
    final raw = await _storage.read(key: key);
    return parseThemePreference(raw);
  }

  Future<void> setThemeMode(AppThemePreference preference) {
    return _storage.write(
      key: key,
      value: themePreferenceToStorage(preference),
    );
  }
}
