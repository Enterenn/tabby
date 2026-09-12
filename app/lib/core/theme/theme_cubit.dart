import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistance du mode thème (système / clair / sombre).
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system) {
    load();
  }

  static const _key = 'theme_mode';
  static const _storage = FlutterSecureStorage();

  Future<void> load() async {
    final raw = await _storage.read(key: _key);
    final mode = _decode(raw);
    if (mode != null) emit(mode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    await _storage.write(key: _key, value: _encode(mode));
  }

  static String _encode(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      };

  static ThemeMode? _decode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => null,
      };
}
