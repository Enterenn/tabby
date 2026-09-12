import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/token_storage.dart';
import '../../../core/auth/biometric_settings.dart';
import '../../../core/services/fcm_service.dart';
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
      final response = await apiClient.dio.get('/auth/me');
      final user = User.fromJson(response.data as Map<String, dynamic>);
      if (tokenStorage.userId == null) {
        await tokenStorage.save(
          access: tokenStorage.accessToken!,
          refresh: tokenStorage.refreshToken!,
          userId: user.id,
        );
      }
      emit(AuthAuthenticated(user));
      FcmService.instance.init();
    } catch (_) {
      await tokenStorage.clear();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      await apiClient.dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      await login(email: email, password: password);
    } on DioException catch (e) {
      emit(AuthError(_extractDetail(e, 'errorRegister')));
    } catch (e) {
      emit(AuthError('errorUnexpected'));
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(AuthLoading());
    try {
      final response = await apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      final access = data['access_token'] as String;
      final refresh = data['refresh_token'] as String;
      await tokenStorage.save(access: access, refresh: refresh);
      apiClient.setAccessToken(access);

      final profileResponse = await apiClient.dio.get('/auth/me');
      final user = User.fromJson(profileResponse.data as Map<String, dynamic>);
      await tokenStorage.save(access: access, refresh: refresh, userId: user.id);
      _offerBiometrics = !biometricSettings.enabled && !biometricSettings.prompted;
      emit(AuthAuthenticated(user));
      FcmService.instance.init();
    } on DioException catch (e) {
      emit(AuthError(_extractDetail(e, 'errorInvalidCredentials')));
    } catch (e) {
      emit(AuthError('errorUnexpected'));
    }
  }

  /// Extrait `detail` depuis la réponse d'erreur FastAPI,
  /// quelle que soit la forme de `response.data` (Map, String, null).
  static String _extractDetail(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      final extracted = _unwrapDetail(detail);
      if (extracted != null) return extracted;
    }
    final status = e.response?.statusCode;
    if (status != null) return '$fallback (HTTP $status)';
    return '$fallback (${e.type.name}: ${e.message})';
  }

  static String? _unwrapDetail(dynamic detail) {
    if (detail is List && detail.isNotEmpty) {
      return _unwrapDetail(detail.first);
    }
    if (detail is Map) {
      final msg = detail['msg']?.toString();
      if (msg == null || msg.isEmpty) return null;
      const prefix = 'Value error, ';
      return msg.startsWith(prefix) ? msg.substring(prefix.length) : msg;
    }
    if (detail == null) return null;
    return detail.toString();
  }

  Future<void> logout() async {
    await FcmService.instance.deleteToken();
    await tokenStorage.clear();
    apiClient.clearToken();
    emit(AuthUnauthenticated());
  }

  Future<String?> updateProfile({
    required String name,
    required String email,
  }) async {
    final prev = state;
    if (prev is! AuthAuthenticated) return 'errorUnexpected';
    try {
      final response = await apiClient.dio.patch('/auth/me', data: {
        'name': name,
        'email': email,
      });
      emit(AuthAuthenticated(User.fromJson(response.data as Map<String, dynamic>)));
      return null;
    } on DioException catch (e) {
      return _extractDetail(e, 'errorUpdate');
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
      await apiClient.dio.post('/auth/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      return null;
    } on DioException catch (e) {
      return _extractDetail(e, 'errorUpdate');
    } catch (_) {
      return 'errorUnexpected';
    }
  }

  Future<String?> uploadAvatar(String filePath) async {
    final prev = state;
    if (prev is! AuthAuthenticated) return 'errorUnexpected';
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await apiClient.dio.post(
        '/auth/me/avatar',
        data: form,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      emit(AuthAuthenticated(User.fromJson(response.data as Map<String, dynamic>)));
      return null;
    } on DioException catch (e) {
      return _extractDetail(e, 'avatarUploadFailed');
    } catch (_) {
      return 'avatarUploadFailed';
    }
  }
}
