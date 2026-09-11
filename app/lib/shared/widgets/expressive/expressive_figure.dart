import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum ExpressiveFigureSize { hero, large, medium, small }

/// Affichage typographique condensé pour montants et KPI (M3 Expressive).
class ExpressiveFigure extends StatelessWidget {
  const ExpressiveFigure({
    super.key,
    required this.value,
    this.prefix,
    this.suffix = '',
    this.size = ExpressiveFigureSize.large,
    this.color,
  });

  final String value;
  final String? prefix;
  final String suffix;
  final ExpressiveFigureSize size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final type = context.tabbyType;
    final style = switch (size) {
      ExpressiveFigureSize.hero => type.figureHero,
      ExpressiveFigureSize.large => type.figureLarge,
      ExpressiveFigureSize.medium => type.figureMedium,
      ExpressiveFigureSize.small => type.figureSmall,
    };

    return Text.rich(
      TextSpan(
        children: [
          if (prefix != null)
            TextSpan(text: prefix, style: style.copyWith(fontSize: (style.fontSize ?? 16) * 0.65)),
          TextSpan(text: value),
          if (suffix.isNotEmpty)
            TextSpan(
              text: suffix,
              style: style.copyWith(fontSize: (style.fontSize ?? 16) * 0.55),
            ),
        ],
        style: style.copyWith(color: color),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Affichage horloge / compteur (64sp condensé).
class ExpressiveClockDisplay extends StatelessWidget {
  const ExpressiveClockDisplay({
    super.key,
    required this.text,
    this.color,
  });

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.tabbyType.clockDisplay.copyWith(color: color),
      maxLines: 1,
    );
  }
}
