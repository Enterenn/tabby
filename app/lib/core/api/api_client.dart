import 'package:dio/dio.dart';

/// Configuration du base URL — pointe sur l'IP Tailscale du LXC backend.
/// Modifie [baseUrl] selon ton adresse Tailscale (ex. http://100.x.x.x:8000).
const String _defaultBaseUrl = '192.168.1.31:8000';

class ApiClient {
  ApiClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? _defaultBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  late final Dio _dio;

  Dio get dio => _dio;

  /// Injecte le JWT access token dans les requêtes
  void setAccessToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // TODO (Lot 1): intercepter le 401 → refresh token → retry
    super.onError(err, handler);
  }
}

/// Singleton global — remplace l'URL en fonction de l'environnement
final apiClient = ApiClient();
