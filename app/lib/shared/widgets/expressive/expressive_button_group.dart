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
/// La pilule active glisse vers le segment choisi ([AnimatedAlign]).
///
/// Réf. [Button groups](https://m3.material.io/components/button-groups/overview)
class ExpressiveButtonGroup<T> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;
    final selectedIndex = segments.indexWhere((s) => s.value == value);
    final count = segments.length;

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
        child: Stack(
          children: [
            if (count > 0 && selectedIndex >= 0)
              Positioned.fill(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment(
                    count == 1 ? 0 : -1 + (2 * selectedIndex / (count - 1)),
                    0,
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 1 / count,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: shapes.radiusFull,
                      ),
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                for (final segment in segments)
                  Expanded(
                    child: _ExpressiveButtonGroupItem(
                      label: segment.label,
                      selected: value == segment.value,
                      onTap: () => onChanged(segment.value),
                    ),
                  ),
              ],
            ),
          ],
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
