import 'package:dio/dio.dart';

import 'token_storage.dart';

/// Base URL du backend — IP locale (même réseau) ou IP Tailscale (hors réseau).
const String _defaultBaseUrl = 'http://192.168.1.31:8000';

class ApiClient {
  ApiClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? _defaultBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_dio),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        // ignore: avoid_print
        logPrint: (o) => print('[Dio] $o'),
      ),
    ]);
  }

  late final Dio _dio;

  Dio get dio => _dio;

  void setAccessToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;
  bool _isRefreshing = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenStorage.accessToken;
    if (token != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      final refresh = tokenStorage.refreshToken;
      if (refresh == null) {
        handler.next(err);
        return;
      }
      _isRefreshing = true;
      try {
        final response = await _dio.post(
          '/auth/refresh',
          data: {'refresh_token': refresh},
          options: Options(headers: {}), // pas de token sur ce call
        );
        final newAccess = response.data['access_token'] as String;
        final newRefresh = response.data['refresh_token'] as String;
        await tokenStorage.save(access: newAccess, refresh: newRefresh);
        apiClient.setAccessToken(newAccess);

        // Rejouer la requête initiale avec le nouveau token
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccess';
        final retryResponse = await _dio.fetch(retryOptions);
        handler.resolve(retryResponse);
      } catch (_) {
        await tokenStorage.clear();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }
}

/// Singleton global
final apiClient = ApiClient();
