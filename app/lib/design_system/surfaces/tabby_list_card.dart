import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

/// Carte de liste — `surfaceContainerLow` + `cardShape`, tap optionnel.
class TabbyListCard extends StatelessWidget {
  const TabbyListCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final padded =
        padding == null ? child : Padding(padding: padding!, child: child);

    final card = Material(
      color: color ?? context.tabbyColors.surfaceContainerLow,
      elevation: 0,
      shape: context.tabbyShapes.cardShape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? padded : InkWell(onTap: onTap, child: padded),
    );

    if (margin == null) return card;
    return Padding(padding: margin!, child: card);
  }
}
