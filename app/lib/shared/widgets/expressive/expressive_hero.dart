import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'expressive_figure.dart';
import 'expressive_tonal_card.dart';

/// Bandeau hero réutilisable — label + chiffre + sous-titre.
class ExpressiveHeroBanner extends StatelessWidget {
  const ExpressiveHeroBanner({
    super.key,
    required this.label,
    required this.value,
    this.suffix = '',
    this.subtitle,
    this.variant = ExpressiveTonalVariant.violet,
    this.accentIcon,
    this.figureSize = ExpressiveFigureSize.hero,
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 16),
  });

  final String label;
  final String value;
  final String suffix;
  final String? subtitle;
  final ExpressiveTonalVariant variant;
  final IconData? accentIcon;
  final ExpressiveFigureSize figureSize;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;
    final (_, fg) = switch (variant) {
      ExpressiveTonalVariant.violet => (
          cs.secondaryContainer,
          cs.onSecondaryContainer,
        ),
      ExpressiveTonalVariant.coral => (
          context.tabbySemantic.expressivePinkContainer,
          cs.onSecondaryContainer,
        ),
      ExpressiveTonalVariant.lime => (
          context.tabbySemantic.expressiveLimeContainer,
          cs.onTertiaryContainer,
        ),
      ExpressiveTonalVariant.neutral => (
          cs.surfaceContainerHighest,
          cs.onSurface,
        ),
    };

    return ExpressiveTonalCard(
      variant: variant,
      margin: margin,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: tt.labelMedium?.copyWith(
                    color: fg.withValues(alpha: 0.85),
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ExpressiveFigure(
                    value: value,
                    suffix: suffix,
                    size: figureSize,
                    color: fg,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: tt.bodyMedium?.copyWith(
                      color: fg.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (accentIcon != null) ...[
            const SizedBox(width: 12),
            ExpressiveAccentIcon(
              icon: accentIcon!,
              color: cs.primary,
              iconColor: cs.onPrimary,
            ),
          ],
        ],
      ),
    );
  }
}
