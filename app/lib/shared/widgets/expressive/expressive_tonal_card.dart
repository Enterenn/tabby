import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/expressive_shapes.dart';

/// Variantes tonales M3 Expressive — sémantiques pour soldes, neutres pour KPI.
enum ExpressiveTonalVariant {
  violet,
  coral,
  lime,
  neutral,
  success,
  danger,
}

/// Grand bloc coloré — hero surfaces, cartes mises en avant.
class ExpressiveTonalCard extends StatelessWidget {
  const ExpressiveTonalCard({
    super.key,
    required this.variant,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
    this.margin,
  });

  final ExpressiveTonalVariant variant;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  (Color bg, Color fg) _colors(BuildContext context) {
    final cs = context.tabbyColors;
    final s = context.tabbySemantic;
    return switch (variant) {
      ExpressiveTonalVariant.violet => (
          cs.secondaryContainer,
          cs.onSecondaryContainer,
        ),
      ExpressiveTonalVariant.coral => (
          cs.tertiaryContainer,
          cs.onTertiaryContainer,
        ),
      ExpressiveTonalVariant.lime => (
          cs.primaryContainer,
          cs.onPrimaryContainer,
        ),
      ExpressiveTonalVariant.neutral => (
          cs.surfaceContainerHighest,
          cs.onSurface,
        ),
      ExpressiveTonalVariant.success => (
          s.successContainer,
          s.onSuccessContainer,
        ),
      ExpressiveTonalVariant.danger => (
          s.dangerContainer,
          s.onDangerContainer,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final shapes = context.tabbyShapes;
    final (bg, _) = _colors(context);

    final card = Material(
      color: bg,
      elevation: 0,
      shape: shapes.cardShape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );

    if (margin != null) {
      return Padding(padding: margin!, child: card);
    }
    return card;
  }
}

/// Cadre festonné ponctuel pour icône / badge accent (usage unique par écran).
class ExpressiveAccentIcon extends StatelessWidget {
  const ExpressiveAccentIcon({
    super.key,
    required this.icon,
    this.size = 52,
    this.color,
    this.iconColor,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final bg = color ?? cs.primary;
    final fg = iconColor ?? cs.onPrimary;

    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: bg,
        elevation: 0,
        shape: const ScallopedBorder(lobes: 8, amplitude: 0.09),
        clipBehavior: Clip.antiAlias,
        child: Icon(icon, color: fg, size: size * 0.48, fill: 1),
      ),
    );
  }
}
