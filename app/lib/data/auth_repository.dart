import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../shared/models/user.dart';

class TokenPair {
  const TokenPair({required this.access, required this.refresh});

  final String access;
  final String refresh;
}

class AuthRepository {
  AuthRepository({Dio? dio}) : _dio = dio ?? apiClient.dio;

  final Dio _dio;

  Future<User> me() async {
    final response = await _dio.get('/auth/me');
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  Future<TokenPair> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    return TokenPair(
      access: data['access_token'] as String,
      refresh: data['refresh_token'] as String,
    );
  }

  Future<void> logout(String refreshToken) {
    return _dio.post('/auth/logout', data: {'refresh_token': refreshToken});
  }

  Future<User> updateProfile({
    required String name,
    required String email,
  }) async {
    final response = await _dio.patch('/auth/me', data: {
      'name': name,
      'email': email,
    });
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _dio.post('/auth/change-password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  Future<User> uploadAvatar(String filePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post(
      '/auth/me/avatar',
      data: form,
      options: Options(
        contentType: Headers.multipartFormDataContentType,
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    return User.fromJson(response.data as Map<String, dynamic>);
  }
}

final authRepository = AuthRepository();
