import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum ExpressiveCtaVariant { filled, tonal }

/// Bouton CTA pill M3 Expressive — icône + label, pleine largeur.
class ExpressiveCtaButton extends StatelessWidget {
  const ExpressiveCtaButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.variant = ExpressiveCtaVariant.filled,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final ExpressiveCtaVariant variant;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;
    final tt = Theme.of(context).textTheme;

    final (bg, fg) = switch (variant) {
      ExpressiveCtaVariant.filled => (cs.primary, cs.onPrimary),
      ExpressiveCtaVariant.tonal => (
          cs.secondaryContainer,
          cs.onSecondaryContainer,
        ),
    };

    return Material(
      color: bg,
      elevation: 0,
      shape: shapes.buttonShape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: shapes.buttonShape,
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: fg, fill: 1),
              const SizedBox(width: 8),
              Text(
                label,
                style: tt.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
