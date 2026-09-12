import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

/// Bouton d'action circulaire — FAB nav, actions prioritaires.
class ExpressiveActionButton extends StatelessWidget {
  const ExpressiveActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 52,
    this.color,
    this.iconColor,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color? color;
  final Color? iconColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;
    final bg = color ?? cs.primary;
    final fg = iconColor ?? cs.onPrimary;
    final border = shapes.circle();

    final button = Material(
      color: bg,
      elevation: 0,
      shape: border,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: border,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: fg, size: size * 0.52, fill: 1),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
