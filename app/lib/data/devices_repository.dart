import 'package:dio/dio.dart';

import '../core/api/api_client.dart';

class DevicesRepository {
  DevicesRepository({Dio? dio}) : _dio = dio ?? apiClient.dio;

  final Dio _dio;

  Future<void> registerToken(String token) {
    return _dio.post('/devices/token', data: {
      'token': token,
      'platform': 'android',
    });
  }

  Future<void> deleteToken(String token) {
    return _dio.delete('/devices/token', data: {'token': token});
  }
}

final devicesRepository = DevicesRepository();
