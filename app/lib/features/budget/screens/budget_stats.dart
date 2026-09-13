part of 'budget_screen.dart';
// ─── Stats section (donut chart + legend cards) ───────────────────────────────

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.stats,
    required this.selectedCategoryId,
  });

  final MonthStats stats;
  final String? selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;
    final shapes = context.tabbyShapes;
    final cubit = context.read<BudgetCubit>();

    if (stats.total == 0) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.bar_chart_rounded,
                size: 48, color: cs.outlineVariant),
            const SizedBox(height: 8),
            Text(
              context.l10n.noSpendThisMonth,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final selectedIndex = selectedCategoryId == null
        ? null
        : stats.categories.indexWhere(
            (c) => c.category.id == selectedCategoryId,
          );
    final resolvedIndex =
        selectedIndex == null || selectedIndex < 0 ? null : selectedIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ExpressiveDonutChart(
            sections: stats.categories,
            total: stats.total,
            selectedIndex: resolvedIndex,
            onSelectedIndexChanged: (i) {
              if (i == null) {
                cubit.selectCategory(null);
                return;
              }
              cubit.selectCategory(stats.categories[i].category.id);
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(context.l10n.allExpenses, style: tt.bodySmall),
          ),
          const SizedBox(height: 8),
          ...stats.categories.asMap().entries.map((entry) {
            final cat = entry.value;
            final catColor = cat.category.resolvedColor;
            final onCat = cat.category.onResolvedColor;
            final isSelected = selectedCategoryId == cat.category.id;

            return GestureDetector(
              onTap: () => cubit.selectCategory(cat.category.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: BoxDecoration(
                  color: isSelected ? catColor : cs.surfaceContainerLow,
                  borderRadius: shapes.radiusLarge,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TabbyCategoryGlyph(
                          icon: cat.category.flutterIcon,
                          background: isSelected ? onCat : catColor,
                          foreground: isSelected ? catColor : onCat,
                          size: 36,
                          iconSize: 18,
                          fill: 1,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.categoryName(cat.category),
                                style: tt.titleSmall?.copyWith(
                                  color: isSelected ? onCat : null,
                                ),
                              ),
                              Text(
                                context.l10n.percentOfTotal(
                                  cat.percent.toStringAsFixed(1),
                                ),
                                style: tt.bodySmall?.copyWith(
                                  color: isSelected
                                      ? onCat
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ExpressiveFigure(
                          value: formatMoney(context, cat.amount),
                          size: ExpressiveFigureSize.small,
                          color: isSelected ? onCat : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: shapes.radiusExtraSmall,
                      child: LinearProgressIndicator(
                        value: cat.percent / 100,
                        minHeight: 5,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isSelected ? onCat : catColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
