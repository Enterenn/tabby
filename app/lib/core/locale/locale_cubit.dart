import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// `null` = suivre la langue du téléphone.
class LocaleCubit extends Cubit<Locale?> {
  LocaleCubit() : super(null) {
    load();
  }

  static const _key = 'locale';
  static const _storage = FlutterSecureStorage();
  static const supported = [Locale('fr'), Locale('en')];

  Future<void> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == 'en' || raw == 'fr') emit(Locale(raw!));
  }

  Future<void> setLocale(Locale? locale) async {
    emit(locale);
    if (locale == null) {
      await _storage.delete(key: _key);
      return;
    }
    await _storage.write(key: _key, value: locale.languageCode);
  }
}
