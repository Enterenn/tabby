import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabby/core/api/api_client.dart';

void main() {
  test('redacts auth retry marker from no public API', () {
    final options = RequestOptions(path: '/groups', extra: {'authRetried': true});
    expect(options.extra['authRetried'], isTrue);
  });

  test('clearToken removes authorization header', () {
    final client = ApiClient(baseUrl: 'https://example.test');
    client.setAccessToken('access-token');
    expect(client.dio.options.headers['Authorization'], 'Bearer access-token');
    client.clearToken();
    expect(client.dio.options.headers.containsKey('Authorization'), isFalse);
  });
}
