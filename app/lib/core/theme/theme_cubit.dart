import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme_preference.dart';

export 'theme_preference.dart';

/// Persist d'abord, emit ensuite — si le write échoue, l'UI ne ment pas.
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({
    required this.prefs,
    AppThemePreference initial = kDefaultThemePreference,
  }) : super(ThemeState(preference: initial));

  final ThemePrefs prefs;

  Future<void>? _inFlight;

  Future<bool> setThemePreference(AppThemePreference preference) async {
    if (state.preference == preference) return false;
    final waitFor = _inFlight;
    var success = false;
    late final Future<void> op;
    op = () async {
      if (waitFor != null) await waitFor;
      if (isClosed || state.preference == preference) return;
      try {
        await prefs.setThemeMode(preference);
      } catch (_) {
        return;
      }
      if (isClosed || state.preference == preference) return;
      emit(ThemeState(preference: preference));
      success = true;
    }();
    _inFlight = op;
    try {
      await op;
      return success;
    } finally {
      if (_inFlight == op) _inFlight = null;
    }
  }
}
