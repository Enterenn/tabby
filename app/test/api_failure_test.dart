import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabby/core/api/api_failure.dart';

DioException _dio({
  int? status,
  dynamic data,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  return DioException(
    requestOptions: RequestOptions(path: '/test'),
    type: type,
    response: status == null
        ? null
        : Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: status,
            data: data,
          ),
  );
}

void main() {
  test('unwraps FastAPI string detail', () {
    final fail = ApiFailure.fromDio(
      _dio(status: 409, data: {'detail': 'Already a member'}),
    );
    expect(fail.code, 'errorConflict');
    expect(fail.message, 'Already a member');
  });

  test('maps 401 without detail', () {
    final fail = ApiFailure.fromDio(_dio(status: 401));
    expect(fail.isUnauthorized, isTrue);
    expect(fail.message, 'errorUnauthorized');
  });

  test('maps connection errors to network', () {
    final fail = ApiFailure.fromDio(
      _dio(type: DioExceptionType.connectionError),
    );
    expect(fail.code, 'errorNetwork');
  });

  test('unwraps validation list detail', () {
    final fail = ApiFailure.fromDio(
      _dio(status: 422, data: {
        'detail': [
          {'msg': 'Value error, Name must be 2-50 characters'},
        ],
      }),
    );
    expect(fail.code, 'errorValidation');
    expect(fail.message, 'Name must be 2-50 characters');
  });
}
