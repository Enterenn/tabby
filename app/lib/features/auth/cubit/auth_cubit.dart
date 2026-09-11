import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/token_storage.dart';
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
      emit(AuthAuthenticated(user));
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
      // Inscription puis connexion automatique
      await apiClient.dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      await login(email: email, password: password);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Erreur lors de l\'inscription';
      emit(AuthError(msg.toString()));
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

      // Récupérer le profil
      final profileResponse = await apiClient.dio.get('/auth/me');
      final user = User.fromJson(profileResponse.data as Map<String, dynamic>);
      emit(AuthAuthenticated(user));
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Email ou mot de passe incorrect';
      emit(AuthError(msg.toString()));
    }
  }

  Future<void> logout() async {
    await tokenStorage.clear();
    apiClient.clearToken();
    emit(AuthUnauthenticated());
  }
}
