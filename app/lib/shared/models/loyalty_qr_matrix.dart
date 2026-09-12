import 'package:qr/qr.dart';

/// QR style Kingdom / bornes : alphanumérique, version mini, ECC M, masque 0.
abstract final class LoyaltyQrMatrix {
  static final _retailCode = RegExp(r'^[0-9A-Z]+$');

  static bool usesRetailProfile(String data) {
    final compact = data.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    return compact.length <= 25 && _retailCode.hasMatch(compact);
  }

  static QrImage encode(String data) {
    final retail = usesRetailProfile(data);
    final payload = retail ? data.replaceAll(RegExp(r'\s+'), '').toUpperCase() : data;

    InputTooLongException? last;
    for (var version = 1; version <= 40; version++) {
      try {
        final code = QrCode(version, QrErrorCorrectLevel.M);
        if (retail) {
          code.addAlphaNumeric(payload);
          return QrImage.withMaskPattern(code, 0);
        }
        code.addData(payload);
        return QrImage(code);
      } on InputTooLongException catch (e) {
        last = e;
      }
    }
    throw last ?? StateError('Unable to encode QR');
  }
}
