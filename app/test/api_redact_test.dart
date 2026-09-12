import 'package:flutter_test/flutter_test.dart';
import 'package:tabby/core/api/api_client.dart';

void main() {
  test('redacts JSON login tokens', () {
    const line =
        '{"access_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.aaa.bbb","refresh_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.ccc.ddd"}';
    final redacted = redactLogLine(line);
    expect(redacted.contains('eyJ'), isFalse);
    expect(redacted, contains('access_token: "***"'));
    expect(redacted, contains('refresh_token: "***"'));
  });

  test('redacts FCM device token field', () {
    const line =
        '{token: fiFx_8WISC64Rh2y0zkOd5:APA91bExZZpgEcrhxwVbXfCODwz8cL6UfwtnMnQoov6MXwtEdlI110va, platform: android}';
    final redacted = redactLogLine(line);
    expect(redacted, contains('token: "***"'));
    expect(redacted.contains('APA91'), isFalse);
  });
}
