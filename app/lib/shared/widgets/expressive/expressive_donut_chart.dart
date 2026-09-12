import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../models/stats.dart';
import 'expressive_figure.dart';
import 'expressive_tonal_card.dart';

/// Donut chart M3 Expressive — segments espacés, aplats, icônes.
class ExpressiveDonutChart extends StatelessWidget {
  const ExpressiveDonutChart({
    super.key,
    required this.sections,
    required this.total,
    this.height = 300,
    this.selectedIndex,
    this.onSelectedIndexChanged,
  });

  final List<CategoryStat> sections;
  final double total;
  final double height;
  final int? selectedIndex;
  final ValueChanged<int?>? onSelectedIndexChanged;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;
    final segmentColors = [
      for (final s in sections) s.category.resolvedColor,
    ];
    final touched = (selectedIndex != null && selectedIndex! < sections.length)
        ? sections[selectedIndex!]
        : null;
    final touchedColor =
        selectedIndex != null && selectedIndex! < segmentColors.length
        ? segmentColors[selectedIndex!]
        : null;

    return ExpressiveTonalCard(
      variant: ExpressiveTonalVariant.neutral,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, height);
            final iconSlots = _ExpressiveDonutGeometry.iconSlots(
              size,
              sections,
              segmentColors,
              selectedIndex,
            );
            final labelSlots = _ExpressiveDonutGeometry.percentLabelSlots(
              size,
              sections,
              segmentColors,
            );

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final hit = _ExpressiveDonutGeometry.hitTest(
                  details.localPosition,
                  size,
                  sections,
                );
                onSelectedIndexChanged?.call(hit == selectedIndex ? null : hit);
              },
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  CustomPaint(
                    size: size,
                    painter: _ExpressiveDonutPainter(
                      sections: sections,
                      segmentColors: segmentColors,
                      selectedIndex: selectedIndex,
                      trackColor: cs.surfaceContainerHighest,
                    ),
                  ),
                  ...iconSlots.map(
                    (slot) => Positioned(
                      left: slot.offset.dx - 16,
                      top: slot.offset.dy - 16,
                      width: 32,
                      height: 32,
                      child: IgnorePointer(
                        child: AnimatedScale(
                          scale: slot.selected ? 1.12 : 1,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: cs.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: slot.stat.category.iconWidget(
                                size: 17,
                                color: slot.color,
                                fill: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ...labelSlots.map(
                    (slot) => Positioned(
                      left: slot.offset.dx - 22,
                      top: slot.offset.dy - 10,
                      width: 44,
                      child: IgnorePointer(
                        child: Text(
                          '${slot.stat.percent.toStringAsFixed(0)}%',
                          textAlign: TextAlign.center,
                          style: tt.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: slot.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    label: context.l10n.totalAmount(total.toStringAsFixed(2)),
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (touched == null)
                        Icon(
                          Symbols.payments_rounded,
                          size: 28,
                          color: cs.onSurfaceVariant,
                        )
                      else
                        ExpressiveFigure(
                          value: touched.percent.toStringAsFixed(1),
                          suffix: '%',
                          size: ExpressiveFigureSize.medium,
                          color: touchedColor,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        touched?.category.name ?? context.l10n.totalExpenses,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DonutIconSlot {
  const _DonutIconSlot({
    required this.offset,
    required this.stat,
    required this.color,
    required this.selected,
  });

  final Offset offset;
  final CategoryStat stat;
  final Color color;
  final bool selected;
}

class _DonutLabelSlot {
  const _DonutLabelSlot({
    required this.offset,
    required this.stat,
    required this.color,
  });

  final Offset offset;
  final CategoryStat stat;
  final Color color;
}

abstract final class _ExpressiveDonutGeometry {
  static const strokeWidth = 40.0;
  static const gapDeg = 11.0;
  static const selectedBoost = 7.0;
  static const minArcForIcon = 36.0;

  static Offset _center(Size size) => Offset(size.width / 2, size.height / 2);

  static double _baseRadius(Size size) =>
      size.shortestSide / 2 - strokeWidth / 2 - selectedBoost - 6;

  static double get _gapRad => gapDeg * math.pi / 180;

  static double _availableRad(int count) => 2 * math.pi - _gapRad * 2 * count;

  static _SegmentLayout _layout(Size size, List<CategoryStat> sections) {
    final center = _center(size);
    final baseRadius = _baseRadius(size);
    final available = _availableRad(sections.length);
    var start = -math.pi / 2;
    final segments = <_SegmentArc>[];

    for (var i = 0; i < sections.length; i++) {
      final sweep = (sections[i].percent / 100) * available;
      segments.add(
        _SegmentArc(
          index: i,
          startAngle: start + _gapRad,
          sweepAngle: sweep,
          radius: baseRadius,
        ),
      );
      start += sweep + _gapRad * 2;
    }

    return _SegmentLayout(center: center, segments: segments);
  }

  static int? hitTest(Offset local, Size size, List<CategoryStat> sections) {
    if (sections.isEmpty) return null;

    final layout = _layout(size, sections);
    final dx = local.dx - layout.center.dx;
    final dy = local.dy - layout.center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final inner = _baseRadius(size) - strokeWidth / 2 - 4;
    final outer = _baseRadius(size) + strokeWidth / 2 + 8;
    if (dist < inner || dist > outer) return null;

    // Même convention que Canvas.drawArc : 0 = 3 h, sens horaire.
    final angle = math.atan2(dy, dx);

    for (final seg in layout.segments) {
      if (_angleInArc(angle, seg.startAngle, seg.sweepAngle)) {
        return seg.index;
      }
    }
    return null;
  }

  static List<_DonutIconSlot> iconSlots(
    Size size,
    List<CategoryStat> sections,
    List<Color> segmentColors,
    int? selectedIndex,
  ) {
    final layout = _layout(size, sections);
    final slots = <_DonutIconSlot>[];

    for (final seg in layout.segments) {
      final selected = selectedIndex == seg.index;
      final radius = seg.radius + (selected ? selectedBoost / 2 : 0);
      final mid = seg.startAngle + seg.sweepAngle / 2;
      if (radius * seg.sweepAngle < minArcForIcon) continue;

      slots.add(
        _DonutIconSlot(
          offset: Offset(
            layout.center.dx + radius * math.cos(mid),
            layout.center.dy + radius * math.sin(mid),
          ),
          stat: sections[seg.index],
          color: segmentColors[seg.index],
          selected: selected,
        ),
      );
    }
    return slots;
  }

  static bool _angleInArc(double angle, double start, double sweep) {
    double norm(double a) {
      a %= 2 * math.pi;
      if (a < 0) a += 2 * math.pi;
      return a;
    }

    final a = norm(angle);
    final s = norm(start);
    final e = norm(start + sweep);
    // Intervalle semi-ouvert pour ne pas chevaucher les gaps.
    if (s <= e) return a >= s && a < e;
    return a >= s || a < e;
  }

  static List<_DonutLabelSlot> percentLabelSlots(
    Size size,
    List<CategoryStat> sections,
    List<Color> segmentColors,
  ) {
    if (sections.length > 6) return const [];

    final layout = _layout(size, sections);
    final slots = <_DonutLabelSlot>[];
    final labelRadius = _baseRadius(size) + strokeWidth / 2 + 22;

    for (final seg in layout.segments) {
      if (sections[seg.index].percent < 4) continue;
      final mid = seg.startAngle + seg.sweepAngle / 2;
      slots.add(
        _DonutLabelSlot(
          offset: Offset(
            layout.center.dx + labelRadius * math.cos(mid),
            layout.center.dy + labelRadius * math.sin(mid),
          ),
          stat: sections[seg.index],
          color: segmentColors[seg.index],
        ),
      );
    }
    return slots;
  }
}

class _SegmentArc {
  const _SegmentArc({
    required this.index,
    required this.startAngle,
    required this.sweepAngle,
    required this.radius,
  });

  final int index;
  final double startAngle;
  final double sweepAngle;
  final double radius;
}

class _SegmentLayout {
  const _SegmentLayout({required this.center, required this.segments});

  final Offset center;
  final List<_SegmentArc> segments;
}

class _ExpressiveDonutPainter extends CustomPainter {
  const _ExpressiveDonutPainter({
    required this.sections,
    required this.segmentColors,
    required this.selectedIndex,
    required this.trackColor,
  });

  final List<CategoryStat> sections;
  final List<Color> segmentColors;
  final int? selectedIndex;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _ExpressiveDonutGeometry._layout(size, sections);
    final rect = Rect.fromCircle(
      center: layout.center,
      radius: _ExpressiveDonutGeometry._baseRadius(size),
    );

    // Piste de fond — anneau continu discret
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _ExpressiveDonutGeometry.strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    for (final seg in layout.segments) {
      final selected = selectedIndex == seg.index;
      final sw =
          _ExpressiveDonutGeometry.strokeWidth +
          (selected ? _ExpressiveDonutGeometry.selectedBoost : 0);
      final radius =
          seg.radius +
          (selected ? _ExpressiveDonutGeometry.selectedBoost / 2 : 0);
      final arcRect = Rect.fromCircle(center: layout.center, radius: radius);

      canvas.drawArc(
        arcRect,
        seg.startAngle,
        seg.sweepAngle,
        false,
        Paint()
          ..color = segmentColors[seg.index]
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ExpressiveDonutPainter old) =>
      old.selectedIndex != selectedIndex ||
      old.sections != sections ||
      old.segmentColors != segmentColors;
}
