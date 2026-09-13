import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/l10n.dart';

class PersonalCard extends StatelessWidget {
  const PersonalCard({super.key, required this.monthTotal});

  final double monthTotal;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final space = context.tabbySpace;
    final tt = Theme.of(context).textTheme;

    return TabbyListCard(
      color: cs.surfaceContainerLow,
      margin: EdgeInsets.only(bottom: space.sm),
      onTap: () => context.push('/personal'),
      padding: EdgeInsets.fromLTRB(space.xl, space.lg, space.lg, space.lg),
      child: Row(
        children: [
          Icon(
            Symbols.person_rounded,
            color: cs.onSurfaceVariant,
          ),
          SizedBox(width: space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.myExpenses,
                  style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: space.xs / 2),
                Text(
                  context.l10n.thisMonth,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: space.md),
          ExpressiveFigure(
            value: formatMoney(context, monthTotal),
            size: ExpressiveFigureSize.small,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}
