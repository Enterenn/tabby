import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

/// FAB / action ronde — [IconButton.filled] aux tokens Tabby.
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

    return IconButton.filled(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, fill: 1),
      style: IconButton.styleFrom(
        backgroundColor: color ?? cs.primary,
        foregroundColor: iconColor ?? cs.onPrimary,
        minimumSize: Size(size, size),
        maximumSize: Size(size, size),
        iconSize: size * 0.52,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
