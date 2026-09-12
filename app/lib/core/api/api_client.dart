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

/// Base URL du backend (HTTPS public via NPM / Cloudflare).
/// Override LAN : `flutter run --dart-define=API_BASE_URL=http://192.168.1.31:8000`
const String _defaultBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://tabby.landrodie.fr',
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
  Future<String>? _refreshing;

  static bool _skipRefresh(RequestOptions options) {
    final path = options.path;
    return path.endsWith('/auth/refresh') ||
        path.endsWith('/auth/login') ||
        path.endsWith('/auth/register') ||
        path.endsWith('/auth/logout');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_skipRefresh(options)) {
      final token = tokenStorage.accessToken;
      if (token != null && !options.headers.containsKey('Authorization')) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 || _skipRefresh(err.requestOptions)) {
      handler.next(err);
      return;
    }

    final refresh = tokenStorage.refreshToken;
    if (refresh == null) {
      handler.next(err);
      return;
    }

    _refreshing ??= _refreshAccessToken(refresh).whenComplete(() {
      _refreshing = null;
    });
    try {
      final newAccess = await _refreshing!;
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccess';
      handler.resolve(await _dio.fetch(retryOptions));
    } on DioException catch (refreshErr) {
      if (refreshErr.response?.statusCode == 401) {
        await tokenStorage.clear();
        handler.next(err);
      } else {
        handler.next(refreshErr);
      }
    } catch (_) {
      handler.next(err);
    }
  }

  Future<String> _refreshAccessToken(String refresh) async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refresh_token': refresh},
      options: Options(headers: {}),
    );
    final newAccess = response.data['access_token'] as String;
    final newRefresh = response.data['refresh_token'] as String;
    await tokenStorage.save(access: newAccess, refresh: newRefresh);
    apiClient.setAccessToken(newAccess);
    return newAccess;
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
