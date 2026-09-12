import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'token_storage.dart';

const _sensitiveLogKeys = {
  'password',
  'current_password',
  'new_password',
  'access_token',
  'refresh_token',
};

String _redactLogLine(String line) {
  var out = line.replaceAllMapped(
    RegExp(r'(authorization)\s*[:=]\s*.+$', caseSensitive: false, multiLine: true),
    (match) => '${match[1]}: "***"',
  );
  for (final key in _sensitiveLogKeys) {
    out = out.replaceAllMapped(
      RegExp(
        '($key)\\s*[:=]\\s*("[^"]*"|[^,\\s}\\]]+)',
        caseSensitive: false,
      ),
      (match) => '${match[1]}: "***"',
    );
  }
  return out;
}

/// Base URL du backend.
/// Prod : `flutter run --dart-define=API_BASE_URL=https://<host>:8000`
/// Debug local : fallback HTTP LAN (cleartext autorisé uniquement en debug).
const String _defaultBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.1.31:8000',
);

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

    _dio.interceptors.add(_AuthInterceptor(_dio));
    if (!kReleaseMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          logPrint: (o) {
            // ignore: avoid_print
            print('[Dio] ${_redactLogLine(o.toString())}');
          },
        ),
      );
    }
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
      } on DioException catch (refreshErr) {
        if (refreshErr.response?.statusCode == 401) {
          await tokenStorage.clear();
        }
        handler.next(refreshErr.response?.statusCode == 401 ? err : refreshErr);
      } catch (_) {
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

/// Résout un chemin média (`/uploads/...`) contre la base URL de l'API.
String? resolveMediaUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final base = apiClient.dio.options.baseUrl.replaceAll(RegExp(r'/$'), '');
  final relative = path.startsWith('/') ? path : '/$path';
  return '$base$relative';
}
