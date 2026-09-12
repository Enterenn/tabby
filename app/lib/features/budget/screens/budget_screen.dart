import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/models/budget.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/widgets/expressive/expressive_donut_chart.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/group.dart';
import '../../../shared/models/stats.dart';
import '../cubit/budget_cubit.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BudgetCubit()..load(),
      child: const _BudgetView(),
    );
  }
}

// ─── Main view ────────────────────────────────────────────────────────────────

class _BudgetView extends StatelessWidget {
  const _BudgetView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetCubit, BudgetState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: state is BudgetLoaded
                ? _MonthNav(
                    year: state.selectedYear,
                    monthLabel: state.stats.monthLabel(
                      Localizations.localeOf(context).toString(),
                    ),
                    isCurrentMonth: state.selectedYear == DateTime.now().year &&
                        state.selectedMonth == DateTime.now().month,
                  )
                : Text(context.l10n.budget),
          ),
          body: switch (state) {
            BudgetInitial() || BudgetLoading() => const TabbyLoading(),
            BudgetError(:final message) => TabbyErrorState(
                message: context.l10nError(message),
                retryLabel: context.l10n.retry,
                onRetry: () => context.read<BudgetCubit>().load(),
              ),
            BudgetLoaded() => _BudgetContent(
                state: state,
                onCreateBudget: () => _showCreateDialog(context, state),
              ),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context, BudgetLoaded state) {
    showTabbyFormDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<BudgetCubit>(),
        child: _BudgetDialog(state: state),
      ),
    );
  }
}

// ─── Full content (scrollable) ────────────────────────────────────────────────

class _BudgetContent extends StatelessWidget {
  const _BudgetContent({
    required this.state,
    required this.onCreateBudget,
  });

  final BudgetLoaded state;
  final VoidCallback onCreateBudget;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ExpressiveHeroBanner(
            label: context.l10n.monthTotal,
            value: formatMoney(context, state.stats.total),
            variant: ExpressiveTonalVariant.lime,
            accentIcon: Symbols.payments_rounded,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          ),
        ),

        if (state.groups.length > 1)
          SliverToBoxAdapter(
            child: _GroupFilter(
              groups: state.groups,
              selectedGroupId: state.selectedGroupId,
            ),
          ),

        SliverToBoxAdapter(
          child: _StatsSection(
            stats: state.stats,
            selectedCategoryId: state.selectedCategoryId,
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.monthBudgets,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: onCreateBudget,
                  child: Text(context.l10n.newBudget),
                ),
              ],
            ),
          ),
        ),
        if (state.budgets.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                context.l10n.budgetThresholdHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.tabbyColors.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final budget = state.budgets[i];
                  return _BudgetCard(
                    budget: budget,
                    selected: state.selectedCategoryId == budget.category.id,
                  );
                },
                childCount: state.budgets.length,
              ),
            ),
          ),
        ] else
          SliverToBoxAdapter(
            child: _BudgetEmpty(onCreateBudget: onCreateBudget),
          ),
      ],
    );
  }
}

class _BudgetEmpty extends StatelessWidget {
  const _BudgetEmpty({required this.onCreateBudget});

  final VoidCallback onCreateBudget;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      child: Column(
        children: [
          Icon(Symbols.savings_rounded, size: 48, color: cs.outlineVariant),
          const SizedBox(height: 12),
          Text(context.l10n.noBudgetTitle, style: tt.titleMedium),
          const SizedBox(height: 6),
          Text(
            context.l10n.noBudgetBody,
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onCreateBudget,
            child: Text(context.l10n.newBudget),
          ),
        ],
      ),
    );
  }
}

// ─── Month navigation ─────────────────────────────────────────────────────────

class _MonthNav extends StatelessWidget {
  const _MonthNav({
    required this.year,
    required this.monthLabel,
    required this.isCurrentMonth,
  });

  final int year;
  final String monthLabel;
  final bool isCurrentMonth;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Symbols.chevron_left_rounded),
          onPressed: () => context.read<BudgetCubit>().prevMonth(),
        ),
        Flexible(
          child: Text(
            '$monthLabel $year',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          icon: Icon(
            Symbols.chevron_right_rounded,
            color: isCurrentMonth ? cs.outlineVariant : null,
          ),
          onPressed:
              isCurrentMonth ? null : () => context.read<BudgetCubit>().nextMonth(),
        ),
      ],
    );
  }
}

// ─── Group filter chips ───────────────────────────────────────────────────────

class _GroupFilter extends StatelessWidget {
  const _GroupFilter({required this.groups, required this.selectedGroupId});

  final List<Group> groups;
  final String? selectedGroupId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BudgetCubit>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TabbyFilterChip(
              label: context.l10n.allGroups,
              selected: selectedGroupId == null,
              onSelected: () => cubit.selectGroup(null),
            ),
          ),
          ...groups.map(
            (g) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TabbyFilterChip(
                label: g.name,
                selected: selectedGroupId == g.id,
                onSelected: () => cubit.selectGroup(g.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
                                cat.category.name,
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

// ─── Budget card ──────────────────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget, required this.selected});
  final Budget budget;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;
    final semantic = context.tabbySemantic;
    final shapes = context.tabbyShapes;
    final b = budget;
    final catColor = b.category.resolvedColor;
    final onCat = b.category.onResolvedColor;
    final statusColor = b.statusColor(semantic);
    final clampedPercent = (b.percent / 100).clamp(0.0, 1.0);
    final isDanger = b.status == BudgetStatus.danger;
    final mutedColor =
        isDanger ? semantic.onDangerContainer : cs.onSurfaceVariant;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TabbyCategoryGlyph(
              icon: b.category.flutterIcon,
              background: isDanger ? semantic.danger : catColor,
              foreground: isDanger ? semantic.onDanger : onCat,
              size: 40,
              iconSize: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.category.name,
                    style: tt.titleMedium?.copyWith(
                      color: isDanger ? semantic.onDangerContainer : null,
                    ),
                  ),
                  Text(
                    context.l10n.budgetPerMonth(
                      formatMoney(context, b.limitAmount, decimalDigits: 0),
                    ),
                    style: tt.bodySmall?.copyWith(color: mutedColor),
                  ),
                ],
              ),
            ),
            ExpressiveBadge(
              label: b.status == BudgetStatus.danger
                  ? context.l10n.overBudget
                  : b.status == BudgetStatus.warning
                      ? context.l10n.warning
                      : context.l10n.ok,
              color: isDanger
                  ? semantic.danger
                  : b.status == BudgetStatus.warning
                      ? semantic.warningContainer
                      : semantic.successContainer,
              textColor: isDanger
                  ? semantic.onDanger
                  : b.status == BudgetStatus.warning
                      ? semantic.onWarningContainer
                      : semantic.onSuccessContainer,
            ),
            IconButton(
              tooltip: context.l10n.budgetActions,
              icon: const Icon(Symbols.more_vert_rounded),
              onPressed: () => _showActions(context),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: shapes.radiusExtraSmall,
          child: LinearProgressIndicator(
            value: clampedPercent,
            minHeight: 8,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDanger ? semantic.danger : statusColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.spentAmount(formatMoney(context, b.spentAmount)),
              style: tt.bodySmall?.copyWith(
                color: isDanger ? semantic.onDangerContainer : null,
              ),
            ),
            Text(
              b.remaining >= 0
                  ? context.l10n.remainingAmount(
                      formatMoney(context, b.remaining),
                    )
                  : context.l10n.overspendAmount(
                      formatMoney(context, b.remaining.abs()),
                    ),
              style: tt.bodySmall?.copyWith(
                color: isDanger ? semantic.onDangerContainer : mutedColor,
                fontWeight: isDanger ? FontWeight.w700 : null,
              ),
            ),
          ],
        ),
      ],
    );

    void onConsult() =>
        context.read<BudgetCubit>().selectCategory(b.category.id);

    if (isDanger) {
      return ExpressiveTonalCard(
        variant: ExpressiveTonalVariant.danger,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
        onTap: onConsult,
        child: content,
      );
    }

    return TabbyListCard(
      margin: const EdgeInsets.only(bottom: 10),
      color: selected ? catColor.withValues(alpha: 0.12) : null,
      onTap: onConsult,
      padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
      child: content,
    );
  }

  void _showActions(BuildContext context) {
    showTabbyActionSheet(
      context,
      title: budget.category.name,
      actions: [
        TabbyActionSheetItem(
          label: context.l10n.editLimit,
          icon: Symbols.edit_rounded,
          onTap: () => _showEditDialog(context),
        ),
        TabbyActionSheetItem(
          label: context.l10n.delete,
          icon: Symbols.delete_rounded,
          danger: true,
          onTap: () => _confirmDelete(context),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
    showTabbyFormDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<BudgetCubit>(),
        child: _EditBudgetDialog(budget: budget),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showTabbyConfirm(
      context,
      title: context.l10n.deleteBudgetTitle,
      body: context.l10n.deleteBudgetBody(budget.category.name),
      confirmLabel: context.l10n.delete,
      danger: true,
    );
    if (confirmed && context.mounted) {
      context.read<BudgetCubit>().deleteBudget(
            groupId: budget.groupId,
            budgetId: budget.id,
          );
    }
  }
}

// ─── Edit budget dialog ───────────────────────────────────────────────────────

class _EditBudgetDialog extends StatefulWidget {
  const _EditBudgetDialog({required this.budget});
  final Budget budget;

  @override
  State<_EditBudgetDialog> createState() => _EditBudgetDialogState();
}

class _EditBudgetDialogState extends State<_EditBudgetDialog> {
  late final TextEditingController _ctrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.budget.limitAmount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_ctrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;
    setState(() => _loading = true);
    final ok = await context.read<BudgetCubit>().updateBudget(
          groupId: widget.budget.groupId,
          budgetId: widget.budget.id,
          limitAmount: amount,
        );
    if (mounted) {
      setState(() => _loading = false);
      if (ok) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final b = widget.budget;
    final catColor = b.category.resolvedColor;

    return TabbyFormDialog(
      title: context.l10n.editBudget,
      submitLabel: context.l10n.save,
      cancelLabel: context.l10n.cancel,
      loading: _loading,
      onSubmit: _save,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TabbyCategoryGlyph(
                icon: b.category.flutterIcon,
                background: catColor,
                foreground: b.category.onResolvedColor,
                size: 36,
                iconSize: 20,
              ),
              const SizedBox(width: 10),
              Text(b.category.name, style: tt.titleMedium),
            ],
          ),
          const SizedBox(height: 20),
          Text(context.l10n.monthlyLimit, style: tt.labelLarge),
          const SizedBox(height: 6),
          TextField(
            controller: _ctrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
            ],
            autofocus: true,
            decoration: const InputDecoration(suffixText: '€'),
          ),
        ],
      ),
    );
  }
}

// ─── Create budget dialog ─────────────────────────────────────────────────────

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({required this.state});
  final BudgetLoaded state;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  Group? _selectedGroup;
  Category? _selectedCategory;
  final _amountCtrl = TextEditingController();
  bool _loading = false;

  List<Category> get _availableCategories {
    if (_selectedGroup == null) return [];
    return context.read<BudgetCubit>().availableCategories(
          groupId: _selectedGroup!.id,
          budgets: widget.state.budgets,
          allCategories: widget.state.allCategories,
        );
  }

  @override
  void initState() {
    super.initState();
    if (widget.state.groups.length == 1) {
      _selectedGroup = widget.state.groups.first;
    } else if (widget.state.selectedGroupId != null) {
      for (final group in widget.state.groups) {
        if (group.id == widget.state.selectedGroupId) {
          _selectedGroup = group;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (_selectedGroup == null ||
        _selectedCategory == null ||
        amount == null ||
        amount <= 0) {
      return;
    }
    setState(() => _loading = true);
    final ok = await context.read<BudgetCubit>().createBudget(
          groupId: _selectedGroup!.id,
          categoryId: _selectedCategory!.id,
          limitAmount: amount,
        );
    if (mounted) {
      setState(() => _loading = false);
      if (ok) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return TabbyFormDialog(
      title: context.l10n.newBudget,
      submitLabel: context.l10n.create,
      cancelLabel: context.l10n.cancel,
      loading: _loading,
      scrollable: true,
      onSubmit: _submit,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.state.groups.length > 1) ...[
            Text(context.l10n.group, style: tt.labelLarge),
            const SizedBox(height: 6),
            DropdownButtonFormField<Group>(
              initialValue: _selectedGroup,
              hint: Text(context.l10n.chooseGroup),
              items: widget.state.groups
                  .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(g.name),
                      ))
                  .toList(),
              onChanged: (g) => setState(() {
                _selectedGroup = g;
                _selectedCategory = null;
              }),
            ),
            const SizedBox(height: 16),
          ],
          Text(context.l10n.category, style: tt.labelLarge),
          const SizedBox(height: 6),
          DropdownButtonFormField<Category>(
            initialValue: _selectedCategory,
            hint: Text(context.l10n.chooseCategory),
            items: _availableCategories
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          c.iconWidget(
                            size: 18,
                            color: c.resolvedColor,
                          ),
                          const SizedBox(width: 8),
                          Text(c.name),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: _selectedGroup == null
                ? null
                : (c) => setState(() => _selectedCategory = c),
          ),
          const SizedBox(height: 16),
          Text(context.l10n.monthlyLimit, style: tt.labelLarge),
          const SizedBox(height: 6),
          TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
            ],
            decoration: const InputDecoration(suffixText: '€'),
          ),
        ],
      ),
    );
  }
}
