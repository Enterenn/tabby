import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import 'expressive_press_scale.dart';

enum ExpressiveCtaVariant { filled, tonal, danger, outlined }

/// Bouton CTA pill M3 Expressive — label centré, icône optionnelle.
class ExpressiveCtaButton extends StatelessWidget {
  const ExpressiveCtaButton({
    super.key,
    this.icon,
    required this.label,
    this.onPressed,
    this.variant = ExpressiveCtaVariant.filled,
    this.expanded = false,
    this.compact = false,
    this.loading = false,
  });

  final IconData? icon;
  final String label;
  final VoidCallback? onPressed;
  final ExpressiveCtaVariant variant;
  final bool expanded;
  final bool compact;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;
    final tt = Theme.of(context).textTheme;

    final (Color bg, Color fg, BorderSide? side) = switch (variant) {
      ExpressiveCtaVariant.filled => (cs.primary, cs.onPrimary, null),
      ExpressiveCtaVariant.tonal => (
          cs.primaryContainer,
          cs.onPrimaryContainer,
          null,
        ),
      ExpressiveCtaVariant.danger => (cs.error, cs.onError, null),
      ExpressiveCtaVariant.outlined => (
          cs.surface,
          cs.primary,
          BorderSide(color: cs.outline, width: 1.5),
        ),
    };

    final enabled = onPressed != null && !loading;
    final height = compact ? 40.0 : 52.0;
    final spinnerSize = compact ? 16.0 : 20.0;

    final Widget content;
    if (loading) {
      content = SizedBox(
        height: spinnerSize,
        width: spinnerSize,
        child: CircularProgressIndicator(strokeWidth: 2, color: fg),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 18 : 20, color: fg, fill: 1),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: tt.labelLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    final shape = side == null
        ? shapes.buttonShape
        : RoundedRectangleBorder(
            borderRadius: shapes.radiusFull,
            side: side,
          );

    final button = ExpressivePressScale(
      enabled: enabled,
      child: Opacity(
        opacity: enabled || loading ? 1 : 0.45,
        child: Material(
          color: bg,
          elevation: 0,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            customBorder: shape,
            child: SizedBox(
              height: height,
              width: expanded ? double.infinity : null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: expanded || compact ? 16 : 28,
                ),
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );

    if (expanded) return button;
    return IntrinsicWidth(child: button);
  }
}
