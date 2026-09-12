import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/token_storage.dart';
import '../../../core/auth/biometric_settings.dart';
import '../../../core/services/fcm_service.dart';
import '../../../data/repositories.dart';
import '../../../shared/models/user.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  bool _offerBiometrics = false;

  bool consumeBiometricOffer() {
    final offer = _offerBiometrics;
    _offerBiometrics = false;
    return offer;
  }

  /// Appelé au démarrage — JWT + éventuellement le verrou biométrique.
  Future<void> checkAuth() async {
    if (!tokenStorage.hasTokens) {
      emit(AuthUnauthenticated());
      return;
    }
    if (biometricSettings.enabled) {
      emit(AuthBiometricRequired());
      return;
    }
    await resumeSession();
  }

  /// Après empreinte / Face ID réussi, ou auto-login sans biométrie.
  Future<void> resumeSession() async {
    if (!tokenStorage.hasTokens) {
      emit(AuthUnauthenticated());
      return;
    }
    emit(AuthLoading());
    try {
      final user = await authRepository.me();
      if (tokenStorage.userId == null) {
        await tokenStorage.save(
          access: tokenStorage.accessToken!,
          refresh: tokenStorage.refreshToken!,
          userId: user.id,
        );
      }
      if (isClosed) return;
      emit(AuthAuthenticated(user));
      FcmService.instance.init();
    } on DioException catch (e) {
      final fail = ApiFailure.fromDio(e, fallback: 'errorNetwork');
      if (fail.isUnauthorized) {
        await tokenStorage.clear();
        if (!isClosed) emit(AuthUnauthenticated());
        return;
      }
      if (!isClosed) emit(AuthError(fail.message));
    } catch (_) {
      if (!isClosed) emit(AuthError('errorUnexpected'));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      await authRepository.register(
        name: name,
        email: email,
        password: password,
      );
      await login(email: email, password: password);
    } on DioException catch (e) {
      if (!isClosed) {
        emit(AuthError(ApiFailure.fromDio(e, fallback: 'errorRegister').message));
      }
    } catch (e) {
      if (!isClosed) emit(AuthError('errorUnexpected'));
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(AuthLoading());
    try {
      final tokens = await authRepository.login(
        email: email,
        password: password,
      );
      await tokenStorage.save(access: tokens.access, refresh: tokens.refresh);
      apiClient.setAccessToken(tokens.access);

      final user = await authRepository.me();
      await tokenStorage.save(
        access: tokens.access,
        refresh: tokens.refresh,
        userId: user.id,
      );
      _offerBiometrics = !biometricSettings.enabled && !biometricSettings.prompted;
      if (isClosed) return;
      emit(AuthAuthenticated(user));
      FcmService.instance.init();
    } on DioException catch (e) {
      if (!isClosed) {
        emit(AuthError(
          ApiFailure.fromDio(e, fallback: 'errorInvalidCredentials').message,
        ));
      }
    } catch (e) {
      if (!isClosed) emit(AuthError('errorUnexpected'));
    }
  }

  Future<void> logout() async {
    final refresh = tokenStorage.refreshToken;
    try {
      if (refresh != null) {
        await authRepository.logout(refresh);
      }
    } catch (_) {
      // On continue le logout local même si le réseau est down.
    }
    await FcmService.instance.deleteToken();
    await tokenStorage.clear();
    apiClient.clearToken();
    if (!isClosed) emit(AuthUnauthenticated());
  }

  Future<String?> updateProfile({
    required String name,
    required String email,
  }) async {
    final prev = state;
    if (prev is! AuthAuthenticated) return 'errorUnexpected';
    try {
      final user = await authRepository.updateProfile(name: name, email: email);
      if (!isClosed) emit(AuthAuthenticated(user));
      return null;
    } on DioException catch (e) {
      return ApiFailure.fromDio(e, fallback: 'errorUpdate').message;
    } catch (_) {
      return 'errorUnexpected';
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state is! AuthAuthenticated) return 'errorUnexpected';
    try {
      await authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return null;
    } on DioException catch (e) {
      return ApiFailure.fromDio(e, fallback: 'errorUpdate').message;
    } catch (_) {
      return 'errorUnexpected';
    }
  }

  Future<String?> uploadAvatar(String filePath) async {
    final prev = state;
    if (prev is! AuthAuthenticated) return 'errorUnexpected';
    try {
      final user = await authRepository.uploadAvatar(filePath);
      if (!isClosed) emit(AuthAuthenticated(user));
      return null;
    } on DioException catch (e) {
      return ApiFailure.fromDio(e, fallback: 'avatarUploadFailed').message;
    } catch (_) {
      return 'avatarUploadFailed';
    }
  }
}
