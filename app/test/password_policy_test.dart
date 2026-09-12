import 'package:flutter_test/flutter_test.dart';
import 'package:tabby/core/auth/password_policy.dart';

void main() {
  test('rejects short or incomplete passwords', () {
    expect(isPasswordValid('Abcdef1'), isFalse);
    expect(isPasswordValid('abcdefgh'), isFalse);
    expect(isPasswordValid('Abcdefgh'), isFalse);
    expect(isPasswordValid('abcdef1!'), isFalse);
  });

  test('accepts policy-compliant passwords', () {
    expect(isPasswordValid('Abcdef1!'), isTrue);
  });
}
