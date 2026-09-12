import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/biometric_service.dart';
import '../../../core/auth/biometric_settings.dart';

class BiometricState {
  const BiometricState({
    this.available = false,
    this.enabled = false,
  });

  final bool available;
  final bool enabled;

  BiometricState copyWith({bool? available, bool? enabled}) {
    return BiometricState(
      available: available ?? this.available,
      enabled: enabled ?? this.enabled,
    );
  }
}

class BiometricCubit extends Cubit<BiometricState> {
  BiometricCubit()
      : super(BiometricState(enabled: biometricSettings.enabled)) {
    refreshAvailability();
  }

  Future<void> refreshAvailability() async {
    final available = await biometricService.isAvailable();
    emit(state.copyWith(available: available));
  }

  Future<bool> authenticate(String reason) {
    return biometricService.authenticate(reason);
  }

  Future<bool> enable(String reason) async {
    final ok = await authenticate(reason);
    if (!ok) return false;
    await biometricSettings.setEnabled(true);
    emit(state.copyWith(enabled: true));
    return true;
  }

  Future<void> disable() async {
    await biometricSettings.setEnabled(false);
    emit(state.copyWith(enabled: false));
  }

  Future<void> declineOffer() => biometricSettings.markPrompted();
}
