import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

/// Pastille circulaire d'une catégorie — fond + icône, tokens du caller.
class TabbyCategoryGlyph extends StatelessWidget {
  const TabbyCategoryGlyph({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
    this.size = 40,
    this.iconSize,
    this.fill = 0,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;
  final double? iconSize;
  final double fill;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      elevation: 0,
      shape: context.tabbyShapes.circle(),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          icon,
          size: iconSize ?? size * 0.5,
          color: foreground,
          fill: fill,
        ),
      ),
    );
  }
}
