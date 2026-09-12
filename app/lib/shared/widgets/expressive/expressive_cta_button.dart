import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import 'expressive_press_scale.dart';

enum ExpressiveCtaVariant { filled, tonal }

/// Bouton CTA pill M3 Expressive — label centré, icône optionnelle.
class ExpressiveCtaButton extends StatelessWidget {
  const ExpressiveCtaButton({
    super.key,
    this.icon,
    required this.label,
    this.onPressed,
    this.variant = ExpressiveCtaVariant.filled,
    this.expanded = false,
  });

  final IconData? icon;
  final String label;
  final VoidCallback? onPressed;
  final ExpressiveCtaVariant variant;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;
    final tt = Theme.of(context).textTheme;

    final (bg, fg) = switch (variant) {
      ExpressiveCtaVariant.filled => (cs.primary, cs.onPrimary),
      ExpressiveCtaVariant.tonal => (
          cs.primaryContainer,
          cs.onPrimaryContainer,
        ),
    };

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: fg, fill: 1),
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

    final enabled = onPressed != null;
    final button = ExpressivePressScale(
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: bg,
          elevation: 0,
          shape: shapes.buttonShape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            customBorder: shapes.buttonShape,
            child: SizedBox(
              height: 52,
              width: expanded ? double.infinity : null,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: expanded ? 16 : 28),
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
