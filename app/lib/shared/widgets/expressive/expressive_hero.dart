import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import 'expressive_badge.dart';
import 'expressive_figure.dart';
import 'expressive_tonal_card.dart';

/// Bandeau hero réutilisable — label + chiffre + sous-titre.
///
/// Passer [amount] pour un solde (+/−, couleur vert/rouge, fond sémantique).
class ExpressiveHeroBanner extends StatelessWidget {
  const ExpressiveHeroBanner({
    super.key,
    required this.label,
    this.value,
    this.amount,
    this.suffix = '',
    this.subtitle,
    this.variant = ExpressiveTonalVariant.neutral,
    this.accentIcon,
    this.figureSize = ExpressiveFigureSize.hero,
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 16),
  }) : assert(value != null || amount != null);

  final String label;
  final String? value;
  final double? amount;
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
    final semantic = context.tabbySemantic;

    final bool isBalance = amount != null;
    final double bal = amount ?? 0;
    final isNeutral = isBalance && bal.abs() < 0.01;
    final isPositive = isBalance && bal > 0.01;

    final effectiveVariant = isBalance
        ? (isNeutral
            ? ExpressiveTonalVariant.neutral
            : isPositive
                ? ExpressiveTonalVariant.success
                : ExpressiveTonalVariant.danger)
        : variant;

    final (_, fg) = _variantColors(context, effectiveVariant);

    final String displayValue =
        isBalance ? bal.abs().toStringAsFixed(2) : value!;
    final String? prefix = isBalance && !isNeutral ? (isPositive ? '+' : '−') : null;
    final Color figureColor =
        isBalance ? semantic.balanceColor(bal) : fg;

    return ExpressiveTonalCard(
      variant: effectiveVariant,
      margin: margin,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label.toUpperCase(),
                        style: tt.labelMedium?.copyWith(
                          color: fg.withValues(alpha: 0.85),
                          letterSpacing: 2.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isBalance)
                      ExpressiveBadge(
                        label: isNeutral
                            ? 'Réglé ✓'
                            : isPositive
                                ? 'On te doit'
                                : 'Tu dois',
                        color: figureColor.withValues(alpha: 0.2),
                        textColor: figureColor,
                        icon: isNeutral
                            ? Icons.check_rounded
                            : isPositive
                                ? Symbols.south_west_rounded
                                : Symbols.north_east_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ExpressiveFigure(
                    value: displayValue,
                    prefix: prefix,
                    suffix: suffix,
                    size: figureSize,
                    color: figureColor,
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
              color: isBalance && !isNeutral
                  ? figureColor.withValues(alpha: 0.22)
                  : cs.primary,
              iconColor: isBalance && !isNeutral ? figureColor : cs.onPrimary,
            ),
          ],
        ],
      ),
    );
  }

  (Color, Color) _variantColors(
    BuildContext context,
    ExpressiveTonalVariant v,
  ) {
    final cs = context.tabbyColors;
    final s = context.tabbySemantic;
    return switch (v) {
      ExpressiveTonalVariant.violet => (
          cs.secondaryContainer,
          cs.onSecondaryContainer,
        ),
      ExpressiveTonalVariant.coral => (
          s.expressivePinkContainer,
          cs.onSecondaryContainer,
        ),
      ExpressiveTonalVariant.lime => (
          s.expressiveLimeContainer,
          cs.onTertiaryContainer,
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
}
