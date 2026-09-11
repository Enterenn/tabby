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
  });

  final String label;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;
    final bg = color ?? cs.secondaryContainer;
    final fg = textColor ?? cs.onSecondaryContainer;

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
              Icon(icon, size: 16, color: fg, fill: 1),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
      return ExpressiveBadge(
        label: 'Réglé ✓',
        color: semantic.successContainer,
        textColor: semantic.onSuccessContainer,
        icon: Icons.check_rounded,
      );
    }

    final color = semantic.balanceColor(amount);
    final sign = isPositive ? '+' : '-';
    final label = showSign
        ? '$sign ${amount.abs().toStringAsFixed(2)} €'
        : '${amount.abs().toStringAsFixed(2)} €';

    return ExpressiveBadge(
      label: label,
      color: color.withValues(alpha: 0.18),
      textColor: color,
    );
  }
}
