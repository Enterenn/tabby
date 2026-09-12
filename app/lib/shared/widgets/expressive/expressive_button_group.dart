import 'package:flutter/physics.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';

/// Segment d'un [ExpressiveButtonGroup].
class ExpressiveButtonGroupSegment<T> {
  const ExpressiveButtonGroupSegment({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

/// Groupe de boutons connectés M3 Expressive — sélection unique, une ligne.
///
/// La pilule active glisse avec le ressort *fast spatial* expressif.
///
/// Réf. [Button groups](https://m3.material.io/components/button-groups/overview)
class ExpressiveButtonGroup<T> extends StatefulWidget {
  const ExpressiveButtonGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.segments,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final List<ExpressiveButtonGroupSegment<T>> segments;

  @override
  State<ExpressiveButtonGroup<T>> createState() =>
      _ExpressiveButtonGroupState<T>();
}

class _ExpressiveButtonGroupState<T> extends State<ExpressiveButtonGroup<T>>
    with SingleTickerProviderStateMixin {
  static final SpringDescription _fastSpatial =
      SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 800,
    ratio: 0.6,
  );

  late final AnimationController _pill;
  double _width = 0;

  int get _selectedIndex {
    final index = widget.segments.indexWhere((s) => s.value == widget.value);
    return index < 0 ? 0 : index;
  }

  double _targetFor(int index, double width) {
    final count = widget.segments.length;
    if (count <= 0 || width <= 0) return 0;
    return index * (width / count);
  }

  @override
  void initState() {
    super.initState();
    _pill = AnimationController.unbounded(vsync: this);
  }

  @override
  void didUpdateWidget(covariant ExpressiveButtonGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.segments.length != widget.segments.length) {
      _animatePill();
    }
  }

  @override
  void dispose() {
    _pill.dispose();
    super.dispose();
  }

  void _animatePill() {
    if (_width <= 0) return;
    _pill.animateWith(
      SpringSimulation(
        _fastSpatial,
        _pill.value,
        _targetFor(_selectedIndex, _width),
        _pill.velocity,
      ),
    );
  }

  void _syncWidth(double width) {
    if ((width - _width).abs() < 0.5) return;
    final wasEmpty = _width <= 0;
    _width = width;
    if (wasEmpty) {
      _pill.value = _targetFor(_selectedIndex, width);
    } else {
      _animatePill();
    }
  }

  void _scheduleSyncWidth(double width) {
    if ((width - _width).abs() < 0.5) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncWidth(width);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;
    final count = widget.segments.length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: shapes.radiusFull,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _scheduleSyncWidth(constraints.maxWidth);
            final segmentWidth = count == 0 ? 0.0 : constraints.maxWidth / count;

            return AnimatedBuilder(
              animation: _pill,
              builder: (context, child) {
                return Stack(
                  children: [
                    if (count > 0 && segmentWidth > 0)
                      Positioned(
                        left: _pill.value,
                        top: 0,
                        bottom: 0,
                        width: segmentWidth,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: shapes.radiusFull,
                          ),
                        ),
                      ),
                    child!,
                  ],
                );
              },
              child: Row(
                children: [
                  for (final segment in widget.segments)
                    Expanded(
                      child: _ExpressiveButtonGroupItem(
                        label: segment.label,
                        selected: widget.value == segment.value,
                        onTap: () => widget.onChanged(segment.value),
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

class _ExpressiveButtonGroupItem extends StatelessWidget {
  const _ExpressiveButtonGroupItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: shapes.radiusFull,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            style: (tt.labelLarge ?? const TextStyle()).copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
