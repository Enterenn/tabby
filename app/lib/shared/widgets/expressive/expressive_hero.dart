import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
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

    final content = isBalance
        ? _BalanceHeroContent(
            label: label,
            displayValue: displayValue,
            prefix: prefix,
            suffix: suffix,
            subtitle: subtitle,
            figureSize: figureSize,
            figureColor: figureColor,
            fg: fg,
            tt: tt,
            isNeutral: isNeutral,
            isPositive: isPositive,
            accentIcon: accentIcon,
            accentBg: isBalance && !isNeutral
                ? (isPositive
                    ? semantic.successContainer
                    : semantic.dangerContainer)
                : cs.primary,
            accentFg: isBalance && !isNeutral
                ? (isPositive
                    ? semantic.onSuccessContainer
                    : semantic.onDangerContainer)
                : cs.onPrimary,
          )
        : _ValueHeroContent(
            label: label,
            value: value!,
            suffix: suffix,
            subtitle: subtitle,
            figureSize: figureSize,
            fg: fg,
            tt: tt,
            accentIcon: accentIcon,
            accentBg: cs.primary,
            accentFg: cs.onPrimary,
          );

    return ExpressiveTonalCard(
      variant: effectiveVariant,
      margin: margin,
      child: content,
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
          cs.primaryContainer,
          cs.onPrimaryContainer,
        ),
      ExpressiveTonalVariant.coral => (
          cs.secondaryContainer,
          cs.onSecondaryContainer,
        ),
      ExpressiveTonalVariant.lime => (
          cs.tertiaryContainer,
          cs.onTertiaryContainer,
        ),
      ExpressiveTonalVariant.neutral => (
          cs.surfaceContainerLow,
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

class _BalanceHeroContent extends StatelessWidget {
  const _BalanceHeroContent({
    required this.label,
    required this.displayValue,
    required this.prefix,
    required this.suffix,
    required this.subtitle,
    required this.figureSize,
    required this.figureColor,
    required this.fg,
    required this.tt,
    required this.isNeutral,
    required this.isPositive,
    required this.accentIcon,
    required this.accentBg,
    required this.accentFg,
  });

  final String label;
  final String displayValue;
  final String? prefix;
  final String suffix;
  final String? subtitle;
  final ExpressiveFigureSize figureSize;
  final Color figureColor;
  final Color fg;
  final TextTheme tt;
  final bool isNeutral;
  final bool isPositive;
  final IconData? accentIcon;
  final Color accentBg;
  final Color accentFg;

  @override
  Widget build(BuildContext context) {
    final type = context.tabbyType;
    final figureStyle = switch (figureSize) {
      ExpressiveFigureSize.hero => type.figureHero,
      ExpressiveFigureSize.large => type.figureLarge,
      ExpressiveFigureSize.medium => type.figureMedium,
      ExpressiveFigureSize.small => type.figureSmall,
    };
    final prefixStyle = figureStyle.copyWith(
      fontSize: (figureStyle.fontSize ?? 16) * 0.72,
      color: figureColor,
    );
    final suffixStyle = figureStyle.copyWith(
      fontSize: (figureStyle.fontSize ?? 16) * 0.5,
      color: figureColor,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(right: accentIcon != null ? 56 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: tt.labelMedium?.copyWith(
                  color: fg,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ExpressiveBadge(
                label: isNeutral
                    ? context.l10n.settledBadge
                    : isPositive
                        ? context.l10n.owedToYou
                        : context.l10n.youOwe,
                color: isNeutral
                    ? context.tabbyColors.surfaceContainerHighest
                    : isPositive
                        ? context.tabbySemantic.successContainer
                        : context.tabbySemantic.dangerContainer,
                textColor: isNeutral
                    ? context.tabbyColors.onSurfaceVariant
                    : isPositive
                        ? context.tabbySemantic.onSuccessContainer
                        : context.tabbySemantic.onDangerContainer,
                icon: isNeutral
                    ? Icons.check_rounded
                    : isPositive
                        ? Symbols.south_west_rounded
                        : Symbols.north_east_rounded,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (prefix != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Text(prefix!, style: prefixStyle),
                      ),
                    Text(displayValue, style: figureStyle.copyWith(color: figureColor)),
                    if (suffix.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(suffix, style: suffixStyle),
                      ),
                  ],
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 10),
                Text(
                  subtitle!,
                  style: tt.bodyMedium?.copyWith(
                    color: fg,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (accentIcon != null)
          Positioned(
            top: 0,
            right: 0,
            child: ExpressiveAccentIcon(
              icon: accentIcon!,
              size: 48,
              color: accentBg,
              iconColor: accentFg,
            ),
          ),
      ],
    );
  }
}

class _ValueHeroContent extends StatelessWidget {
  const _ValueHeroContent({
    required this.label,
    required this.value,
    required this.suffix,
    required this.subtitle,
    required this.figureSize,
    required this.fg,
    required this.tt,
    required this.accentIcon,
    required this.accentBg,
    required this.accentFg,
  });

  final String label;
  final String value;
  final String suffix;
  final String? subtitle;
  final ExpressiveFigureSize figureSize;
  final Color fg;
  final TextTheme tt;
  final IconData? accentIcon;
  final Color accentBg;
  final Color accentFg;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(right: accentIcon != null ? 56 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: tt.labelMedium?.copyWith(
                  color: fg,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
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
                const SizedBox(height: 10),
                Text(
                  subtitle!,
                  style: tt.bodyMedium?.copyWith(
                    color: fg,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (accentIcon != null)
          Positioned(
            top: 0,
            right: 0,
            child: ExpressiveAccentIcon(
              icon: accentIcon!,
              size: 48,
              color: accentBg,
              iconColor: accentFg,
            ),
          ),
      ],
    );
  }
}
