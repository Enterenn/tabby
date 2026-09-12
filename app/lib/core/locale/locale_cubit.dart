import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistance de la langue (fr / en). Défaut : français.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(const Locale('fr')) {
    load();
  }

  static const _key = 'locale';
  static const _storage = FlutterSecureStorage();
  static const supported = [Locale('fr'), Locale('en')];

  Future<void> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == 'en' || raw == 'fr') emit(Locale(raw!));
  }

  Future<void> setLocale(Locale locale) async {
    emit(locale);
    await _storage.write(key: _key, value: locale.languageCode);
  }
}
