import 'package:flutter_test/flutter_test.dart';
import 'package:tabby/shared/models/loyalty_barcode.dart';
import 'package:tabby/shared/models/loyalty_card.dart';
import 'package:tabby/shared/models/loyalty_code_value.dart';
import 'package:tabby/shared/models/loyalty_qr_matrix.dart';
import 'package:tabby/shared/models/loyalty_scan.dart';

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
    test('keeps the machine payload, not the printed grouping', () {
      expect(
        LoyaltyCodeValue.fromScan(
          rawValue: '8DDC9YD9L',
          displayValue: '8DD C9Y D9L',
        ),
        '8DDC9YD9L',
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

  group('LoyaltyCodeValue.grouped', () {
    test('reinserts McDo 4+4 and BK 3+3+3 groups', () {
      expect(LoyaltyCodeValue.grouped('7CCVLHIA', groupSize: 4), '7CCV LHIA');
      expect(LoyaltyCodeValue.grouped('8DDC9YD9L', groupSize: 3), '8DD C9Y D9L');
    });

    test('keeps an already grouped code', () {
      expect(LoyaltyCodeValue.grouped('7CCV LHIA', groupSize: 4), '7CCV LHIA');
    });

    test('does not group URLs or odd lengths', () {
      expect(
        LoyaltyCodeValue.grouped('https://x/7CCVLHIA', groupSize: 4),
        'https://x/7CCVLHIA',
      );
      expect(LoyaltyCodeValue.grouped('7CCVLHI', groupSize: 4), '7CCVLHI');
    });
  });

  test('LoyaltyCard shows grouped text but encodes the compact payload', () {
    const mcdo = LoyaltyCard(
      id: '1',
      brandName: "McDonald's",
      codeType: 'barcode',
      codeValue: '7CCVLHIA',
      color: null,
      sortOrder: 0,
      brandId: 'mcdo',
    );
    expect(mcdo.renderedCode, '7CCV LHIA');
    expect(mcdo.encodedCode, '7CCVLHIA');

    const bk = LoyaltyCard(
      id: '2',
      brandName: 'Burger King',
      codeType: 'qrcode',
      codeValue: '8DD C9Y D9L',
      color: null,
      sortOrder: 0,
      brandId: 'burgerking',
    );
    expect(bk.renderedCode, '8DD C9Y D9L');
    expect(bk.encodedCode, '8DDC9YD9L');
  });

  test('BK QR matches Kingdom (alphanumeric, ECC M, mask 0)', () {
    const expected =
        '111111100011101111111100000101100001000001101110100101101011101'
        '101110100110101011101101110101100101011101100000100110101000001'
        '111111101010101111111000000000001100000000101010100011000010010'
        '111101010010001100000101101111000100010111101010000010001101101'
        '000100101000101010011000000001001010111100111111100001011000000'
        '100000100101110110010101110101101011010011101110100100001000110'
        '101110101110100001101100000100100001110111111111101010101011101';
    final image = LoyaltyQrMatrix.encode('8DDC9YD9L');
    expect(image.moduleCount, 21);
    expect(image.maskPattern, 0);
    final bits = StringBuffer();
    for (var row = 0; row < 21; row++) {
      for (var col = 0; col < 21; col++) {
        bits.write(image.isDark(row, col) ? '1' : '0');
      }
    }
    expect(bits.toString(), expected);
  });

  group('LoyaltyBarcode', () {
    test('uses EAN-13 for a valid supermarket card', () {
      expect(LoyaltyBarcode.kind('5901234123457'), LoyaltyBarcodeKind.ean13);
      expect(
        LoyaltyBarcode.machineValue('590 1234 123457'),
        '5901234123457',
      );
    });

    test('keeps McDo as Code 128', () {
      expect(LoyaltyBarcode.kind('7CCVLHIA'), LoyaltyBarcodeKind.code128);
      expect(LoyaltyBarcode.machineValue('7CCV LHIA'), '7CCV LHIA');
    });

    test('falls back to Code 128 when the EAN checksum is wrong', () {
      expect(LoyaltyBarcode.kind('5901234123450'), LoyaltyBarcodeKind.code128);
    });

    test('leaves a URL QR payload untouched', () {
      const url = 'https://carrefour.fr/card/abc';
      expect(LoyaltyQrMatrix.usesRetailProfile(url), isFalse);
    });
  });

  group('LoyaltyBrandDetector', () {
    test('recognizes a Kingdom QR without a URL', () {
      expect(
        LoyaltyBrandDetector.identify(
          const LoyaltyScanPayload(value: '8DDC9YD9L', isQrCode: true),
        )?.id,
        'burgerking',
      );
    });

    test('recognizes a McDo barcode without a prefix', () {
      expect(
        LoyaltyBrandDetector.identify(
          const LoyaltyScanPayload(value: '7CCVLHIA', isQrCode: false),
        )?.id,
        'mcdo',
      );
    });

    test('recognizes Carrefour from its EAN prefix', () {
      expect(
        LoyaltyBrandDetector.identify(
          const LoyaltyScanPayload(value: '2750901234567', isQrCode: false),
        )?.id,
        'carrefour',
      );
    });

    test('recognizes McDo from a loyalty URL', () {
      expect(
        LoyaltyBrandDetector.identify(
          const LoyaltyScanPayload(
            value: 'https://www.mcdonalds.fr/fid/abc',
            isQrCode: true,
          ),
        )?.id,
        'mcdo',
      );
    });
  });
}
