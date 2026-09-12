import 'package:dio/dio.dart';

/// Erreur API normalisée — 401 / 403 / 409 / 422 / offline.
class ApiFailure {
  const ApiFailure({
    required this.code,
    this.statusCode,
    this.detail,
  });

  /// Clé l10n de repli (`errorNetwork`, `errorUnauthorized`, …).
  final String code;
  final int? statusCode;
  final String? detail;

  String get message =>
      (detail != null && detail!.isNotEmpty) ? detail! : code;

  bool get isUnauthorized => statusCode == 401;

  static ApiFailure from(Object error, {String fallback = 'errorNetwork'}) {
    if (error is DioException) {
      return fromDio(error, fallback: fallback);
    }
    return const ApiFailure(code: 'errorUnexpected');
  }

  static ApiFailure fromDio(DioException e, {String fallback = 'errorNetwork'}) {
    final status = e.response?.statusCode;
    final detail = unwrapDetail(e.response?.data);

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.unknown && status == null) {
      return ApiFailure(code: 'errorNetwork', statusCode: status, detail: detail);
    }

    return switch (status) {
      401 => ApiFailure(
          code: 'errorUnauthorized',
          statusCode: 401,
          detail: detail,
        ),
      403 => ApiFailure(
          code: 'errorForbidden',
          statusCode: 403,
          detail: detail,
        ),
      409 => ApiFailure(
          code: 'errorConflict',
          statusCode: 409,
          detail: detail,
        ),
      422 => ApiFailure(
          code: 'errorValidation',
          statusCode: 422,
          detail: detail,
        ),
      _ => ApiFailure(
          code: fallback,
          statusCode: status,
          detail: detail,
        ),
    };
  }

  static String? unwrapDetail(dynamic data) {
    if (data is Map) {
      return _unwrap(data['detail']);
    }
    return null;
  }

  static String? _unwrap(dynamic detail) {
    if (detail is List && detail.isNotEmpty) {
      return _unwrap(detail.first);
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
}
