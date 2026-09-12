import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/token_storage.dart';
import '../../../core/services/fcm_service.dart';
import '../../../shared/models/user.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  /// Appelé au démarrage — vérifie si un token existe déjà.
  Future<void> checkAuth() async {
    if (!tokenStorage.hasTokens) {
      emit(AuthUnauthenticated());
      return;
    }
    emit(AuthLoading());
    try {
      // Utilise le token stocké pour récupérer le profil
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
      if (detail != null) return detail.toString();
    }
    final status = e.response?.statusCode;
    if (status != null) return '$fallback (HTTP $status)';
    return '$fallback (${e.type.name}: ${e.message})';
  }

  Future<void> logout() async {
    await FcmService.instance.deleteToken();
    await tokenStorage.clear();
    apiClient.clearToken();
    emit(AuthUnauthenticated());
  }
}
