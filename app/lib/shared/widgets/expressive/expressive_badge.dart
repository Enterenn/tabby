import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Badge pill M3 Expressive.
class ExpressiveBadge extends StatelessWidget {
  const ExpressiveBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.labelStyle,
    this.iconSize = 16,
  });

  final String label;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final EdgeInsets padding;
  final TextStyle? labelStyle;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;
    final bg = color ?? cs.primaryContainer;
    final fg = textColor ?? cs.onPrimaryContainer;

    return Material(
      color: bg,
      elevation: 0,
      shape: shapes.pill(),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: iconSize, color: fg, fill: 1),
              SizedBox(width: iconSize >= 16 ? 6 : 4),
            ],
            Text(
              label,
              style: labelStyle ??
                  Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge de solde (+/-) avec couleur sémantique.
class ExpressiveBalanceBadge extends StatelessWidget {
  const ExpressiveBalanceBadge({
    super.key,
    required this.amount,
    this.showSign = true,
  });

  final double amount;
  final bool showSign;

  @override
  Widget build(BuildContext context) {
    final semantic = context.tabbySemantic;
    final isNeutral = amount.abs() < 0.01;
    final isPositive = amount > 0.01;

    if (isNeutral) {
      final cs = context.tabbyColors;
      return ExpressiveBadge(
        label: '0,00 €',
        color: cs.surfaceContainerHighest,
        textColor: cs.onSurfaceVariant,
      );
    }

    final sign = isPositive ? '+' : '-';
    final label = showSign
        ? '$sign ${amount.abs().toStringAsFixed(2)} €'
        : '${amount.abs().toStringAsFixed(2)} €';

    return ExpressiveBadge(
      label: label,
      color: isPositive ? semantic.successContainer : semantic.dangerContainer,
      textColor:
          isPositive ? semantic.onSuccessContainer : semantic.onDangerContainer,
    );
  }
}
