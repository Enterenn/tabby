import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

/// Forme festonnée légère — accent ponctuel uniquement (1 par écran max).
///
/// [amplitude] 0 = cercle. Au-dessus, les lobes apparaissent.
abstract final class ExpressiveAccentShape {
  static Path path(
    Size size, {
    int lobes = 8,
    double amplitude = 0.09,
    double rotation = 0,
  }) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final half = math.min(size.width, size.height) / 2;
    final baseR = half / (1 + amplitude.abs());
    final path = Path();
    const steps = 96;
    for (var i = 0; i <= steps; i++) {
      final angle = (i / steps) * 2 * math.pi + rotation;
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
    this.rotation = 0,
    super.side = BorderSide.none,
  });

  final int lobes;
  final double amplitude;
  final double rotation;

  @override
  ScallopedBorder copyWith({
    BorderSide? side,
    int? lobes,
    double? amplitude,
    double? rotation,
  }) {
    return ScallopedBorder(
      side: side ?? this.side,
      lobes: lobes ?? this.lobes,
      amplitude: amplitude ?? this.amplitude,
      rotation: rotation ?? this.rotation,
    );
  }

  @override
  ShapeBorder scale(double t) => ScallopedBorder(
        side: side.scale(t),
        lobes: lobes,
        amplitude: amplitude,
        rotation: rotation,
      );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is ScallopedBorder) {
      return ScallopedBorder.lerp(a, this, t);
    }
    if (a is CircleBorder) {
      return ScallopedBorder.lerp(
        ScallopedBorder(side: a.side, lobes: lobes, amplitude: 0),
        this,
        t,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is ScallopedBorder) {
      return ScallopedBorder.lerp(this, b, t);
    }
    if (b is CircleBorder) {
      return ScallopedBorder.lerp(
        this,
        ScallopedBorder(side: b.side, lobes: lobes, amplitude: 0),
        t,
      );
    }
    return super.lerpTo(b, t);
  }

  static ScallopedBorder lerp(ScallopedBorder a, ScallopedBorder b, double t) {
    return ScallopedBorder(
      side: BorderSide.lerp(a.side, b.side, t),
      lobes: t < 0.5 ? a.lobes : b.lobes,
      amplitude: lerpDouble(a.amplitude, b.amplitude, t)!,
      rotation: lerpDouble(a.rotation, b.rotation, t)!,
    );
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return ExpressiveAccentShape.path(
      rect.size,
      lobes: lobes,
      amplitude: amplitude,
      rotation: rotation,
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

class ExpressiveAccentClipper extends CustomClipper<Path> {
  ExpressiveAccentClipper({
    this.lobes = 8,
    this.amplitude = 0,
    this.rotation = 0,
  });

  final int lobes;
  final double amplitude;
  final double rotation;

  @override
  Path getClip(Size size) => ExpressiveAccentShape.path(
        size,
        lobes: lobes,
        amplitude: amplitude,
        rotation: rotation,
      );

  @override
  bool shouldReclip(covariant ExpressiveAccentClipper old) =>
      old.lobes != lobes ||
      old.amplitude != amplitude ||
      old.rotation != rotation;
}
