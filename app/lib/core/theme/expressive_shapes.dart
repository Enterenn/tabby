import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Forme festonnée légère — accent ponctuel uniquement (1 par écran max).
abstract final class ExpressiveAccentShape {
  static Path path(Size size, {int lobes = 8, double amplitude = 0.09}) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final baseR = math.min(size.width, size.height) / 2;
    final path = Path();
    const steps = 360;
    for (var i = 0; i <= steps; i++) {
      final angle = (i / steps) * 2 * math.pi;
      final r = baseR * (1 + amplitude * math.cos(lobes * angle));
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
}

class ScallopedBorder extends OutlinedBorder {
  const ScallopedBorder({
    this.lobes = 8,
    this.amplitude = 0.09,
    super.side = BorderSide.none,
  });

  final int lobes;
  final double amplitude;

  @override
  ScallopedBorder copyWith({BorderSide? side, int? lobes, double? amplitude}) {
    return ScallopedBorder(
      side: side ?? this.side,
      lobes: lobes ?? this.lobes,
      amplitude: amplitude ?? this.amplitude,
    );
  }

  @override
  ShapeBorder scale(double t) => ScallopedBorder(
        side: side.scale(t),
        lobes: lobes,
        amplitude: amplitude,
      );

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return ExpressiveAccentShape.path(
      rect.size,
      lobes: lobes,
      amplitude: amplitude,
    ).shift(rect.topLeft);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(
      getOuterPath(rect, textDirection: textDirection),
      side.toPaint(),
    );
  }
}
