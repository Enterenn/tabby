import 'package:flutter_test/flutter_test.dart';
import 'package:tabby/shared/models/loyalty_code_value.dart';

void main() {
  group('LoyaltyCodeValue.preserve', () {
    test('keeps internal spaces from Burger King and McDo codes', () {
      expect(LoyaltyCodeValue.preserve('8DD C9Y D9L'), '8DD C9Y D9L');
      expect(LoyaltyCodeValue.preserve('7CCV LHIA'), '7CCV LHIA');
    });

    test('trims only leading and trailing whitespace', () {
      expect(LoyaltyCodeValue.preserve('  8DD C9Y D9L  '), '8DD C9Y D9L');
      expect(LoyaltyCodeValue.preserve('\n7CCV LHIA\t'), '7CCV LHIA');
    });

    test('does not invent spaces in a compact payload', () {
      expect(LoyaltyCodeValue.preserve('8DDC9YD9L'), '8DDC9YD9L');
    });
  });

  group('LoyaltyCodeValue.fromScan', () {
    test('prefers the scan string that still has grouping spaces', () {
      expect(
        LoyaltyCodeValue.fromScan(
          rawValue: '8DDC9YD9L',
          displayValue: '8DD C9Y D9L',
        ),
        '8DD C9Y D9L',
      );
      expect(
        LoyaltyCodeValue.fromScan(
          rawValue: '7CCV LHIA',
          displayValue: '7CCVLHIA',
        ),
        '7CCV LHIA',
      );
    });

    test('keeps rawValue when payloads differ (URL vs printed code)', () {
      expect(
        LoyaltyCodeValue.fromScan(
          rawValue: 'https://burgerking.fr/card/8DDC9YD9L',
          displayValue: '8DD C9Y D9L',
        ),
        'https://burgerking.fr/card/8DDC9YD9L',
      );
    });

    test('falls back to displayValue when rawValue is empty', () {
      expect(
        LoyaltyCodeValue.fromScan(
          rawValue: null,
          displayValue: '8DD C9Y D9L',
        ),
        '8DD C9Y D9L',
      );
    });
  });
}
