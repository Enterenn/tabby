import 'package:barcode_widget/barcode_widget.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/loyalty_barcode.dart';
import '../../models/loyalty_card.dart';
import 'loyalty_qr_code.dart';

/// QR ou code-barres prêt à présenter en caisse.
class LoyaltyMachineCode extends StatelessWidget {
  const LoyaltyMachineCode({
    super.key,
    required this.card,
    this.barcodeHeight = 100,
    this.qrSize = 220,
  });

  final LoyaltyCard card;
  final double barcodeHeight;
  final double qrSize;

  @override
  Widget build(BuildContext context) {
    final data = card.encodedCode;
    if (!card.isBarcode) {
      return LoyaltyQrCode(data: data, size: qrSize);
    }

    final barcode = switch (LoyaltyBarcode.kind(data)) {
      LoyaltyBarcodeKind.ean13 => Barcode.ean13(),
      LoyaltyBarcodeKind.ean8 => Barcode.ean8(),
      LoyaltyBarcodeKind.upcA => Barcode.upcA(),
      LoyaltyBarcodeKind.code128 => Barcode.code128(),
    };
    return BarcodeWidget(
      barcode: barcode,
      data: data,
      width: double.infinity,
      height: barcodeHeight,
      drawText: false,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      errorBuilder: (context, _) => BarcodeWidget(
        barcode: Barcode.code128(),
        data: data,
        width: double.infinity,
        height: barcodeHeight,
        drawText: false,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }
}
