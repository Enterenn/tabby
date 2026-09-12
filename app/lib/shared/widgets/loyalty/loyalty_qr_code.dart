import 'package:material_ui/material_ui.dart';
import 'package:qr/qr.dart';

import '../../models/loyalty_qr_matrix.dart';

/// QR fidélité — même profil que Kingdom (alphanum + ECC M + masque 0).
class LoyaltyQrCode extends StatelessWidget {
  const LoyaltyQrCode({
    super.key,
    required this.data,
    this.size = 220,
    this.color = Colors.black,
  });

  final String data;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final image = LoyaltyQrMatrix.encode(data);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _LoyaltyQrPainter(image, color)),
    );
  }
}

class _LoyaltyQrPainter extends CustomPainter {
  const _LoyaltyQrPainter(this.image, this.color);

  final QrImage image;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final n = image.moduleCount;
    const quiet = 4;
    final total = n + quiet * 2;
    final cell = size.shortestSide / total;
    final origin = Offset(
      (size.width - cell * total) / 2,
      (size.height - cell * total) / 2,
    );
    final paint = Paint()..color = color;
    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        if (!image.isDark(row, col)) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            origin.dx + (col + quiet) * cell,
            origin.dy + (row + quiet) * cell,
            cell,
            cell,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LoyaltyQrPainter old) =>
      old.image != image || old.color != color;
}
