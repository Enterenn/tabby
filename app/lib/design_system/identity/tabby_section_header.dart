import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

/// Titre de section liste — padding et graisse unifiés.
class TabbySectionHeader extends StatelessWidget {
  const TabbySectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding,
    this.emphasized = false,
  });

  /// Gouttière titre au-dessus d’une liste (groupe, perso, détail).
  static EdgeInsets listPadding(TabbySpaceTokens space) =>
      EdgeInsets.fromLTRB(space.xl, space.xxl, space.xl, space.sm);

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final space = context.tabbySpace;
    final tt = Theme.of(context).textTheme;
    final titleWidget = Text(
      title,
      style: tt.titleLarge?.copyWith(
        fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
      ),
    );

    return Padding(
      padding: padding ?? listPadding(space),
      child: trailing == null
          ? Align(alignment: Alignment.centerLeft, child: titleWidget)
          : Row(
              children: [
                Expanded(child: titleWidget),
                trailing!,
              ],
            ),
    );
  }
}
