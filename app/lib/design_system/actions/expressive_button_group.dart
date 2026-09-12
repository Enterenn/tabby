import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

/// Segment d'un [ExpressiveButtonGroup].
class ExpressiveButtonGroupSegment<T> {
  const ExpressiveButtonGroupSegment({
    required this.value,
    required this.label,
    this.semanticLabel,
  });

  final T value;
  final String label;

  /// Label a11y long (« Apparence claire ») — le [label] reste court (« Clair »).
  final String? semanticLabel;
}

/// Rail creux + thumb unique qui glisse derrière le label choisi.
///
/// Track = `surfaceContainerHighest`, thumb = `surfaceContainerLowest`.
/// Anim 250 ms / [Curves.easeInOutCubic] — durée 0 si a11y reduce-motion.
class ExpressiveButtonGroup<T> extends StatelessWidget {
  const ExpressiveButtonGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.segments,
    this.enabled = true,
    this.fireOnReselect = false,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final List<ExpressiveButtonGroupSegment<T>> segments;
  final bool enabled;
  final bool fireOnReselect;

  static const _duration = Duration(milliseconds: 250);
  static const _inset = 4.0;
  static const _radius = 999.0;
  static const _minTap = 48.0;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final disableAnim = MediaQuery.disableAnimationsOf(context);
    final i = segments.indexWhere((s) => s.value == value);
    final index = i < 0 ? 0 : i;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_inset),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final count = segments.length;
            final w = count == 0 ? 0.0 : constraints.maxWidth / count;
            return Stack(
              children: [
                if (count > 0 && w > 0)
                  AnimatedPositioned(
                    duration: disableAnim ? Duration.zero : _duration,
                    curve: Curves.easeInOutCubic,
                    left: index * w,
                    width: w,
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(_radius),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    for (final segment in segments)
                      Expanded(
                        child: _Segment(
                          label: segment.label,
                          semanticLabel: segment.semanticLabel,
                          selected: segment.value == value,
                          enabled: enabled,
                          onTap: !enabled
                              ? null
                              : (!fireOnReselect && segment.value == value)
                              ? null
                              : () => onChanged(segment.value),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.semanticLabel,
  });

  final String label;
  final String? semanticLabel;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: semanticLabel ?? label,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(999),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: ExpressiveButtonGroup._minTap,
              ),
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TabbyTypographyTokens.flex(
                    fontSize: 14,
                    wght: selected ? 500 : 400,
                    rond: 0,
                    height: 1.4,
                    color: selected ? cs.onSurface : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
