part of 'budget_screen.dart';
// ─── Full content (scrollable) ────────────────────────────────────────────────

class _BudgetContent extends StatelessWidget {
  const _BudgetContent({
    required this.state,
    required this.canCreate,
    required this.onCreateBudget,
  });

  final BudgetLoaded state;
  final bool canCreate;
  final VoidCallback onCreateBudget;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: ExpressiveHeroBanner(
            label: context.l10n.monthTotal,
            value: formatMoney(context, state.stats.total),
            subtitle: switch (state.selectedScope) {
              SpendScope.all => context.l10n.shareLegendAll,
              SpendScope.groups => context.l10n.shareLegendGroups,
              SpendScope.personal => context.l10n.shareLegendPersonal,
            },
            variant: ExpressiveTonalVariant.lime,
            accentIcon: Symbols.payments_rounded,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TabbyFilterChip(
                  label: context.l10n.scopeAll,
                  selected: state.selectedScope == SpendScope.all,
                  onSelected: () =>
                      context.read<BudgetCubit>().selectScope(SpendScope.all),
                ),
                TabbyFilterChip(
                  label: context.l10n.scopeGroups,
                  selected: state.selectedScope == SpendScope.groups,
                  onSelected: () =>
                      context.read<BudgetCubit>().selectScope(SpendScope.groups),
                ),
                TabbyFilterChip(
                  label: context.l10n.scopePersonal,
                  selected: state.selectedScope == SpendScope.personal,
                  onSelected: () => context
                      .read<BudgetCubit>()
                      .selectScope(SpendScope.personal),
                ),
              ],
            ),
          ),
        ),

        if (state.groups.length > 1 &&
            state.selectedScope == SpendScope.groups)
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

        if (state.selectedScope == SpendScope.personal)
          SliverToBoxAdapter(
            child: _PersonalExpensesSection(state: state),
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
                if (canCreate)
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final budget = state.budgets[i];
                  return _BudgetCard(
                    budget: budget,
                    selected: state.selectedCategoryId == budget.category.id,
                    canManage: true,
                  );
                },
                childCount: state.budgets.length,
              ),
            ),
          ),
        ] else
          SliverToBoxAdapter(
            child: _BudgetEmpty(
              onCreateBudget: canCreate ? onCreateBudget : null,
            ),
          ),
      ],
    );
  }
}

class _BudgetEmpty extends StatelessWidget {
  const _BudgetEmpty({this.onCreateBudget});

  final VoidCallback? onCreateBudget;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
          if (onCreateBudget != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCreateBudget,
              child: Text(context.l10n.newBudget),
            ),
          ],
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

  static const _all = '';

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BudgetCubit>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ExpressiveDropdown<String>(
        selected: selectedGroupId ?? _all,
        leadingIcon: Icon(
          Symbols.group_rounded,
          size: 20,
          color: context.tabbyColors.onSurfaceVariant,
        ),
        entries: [
          ExpressiveDropdownEntry(
            value: _all,
            label: context.l10n.allGroupsMenu,
          ),
          for (final g in groups)
            ExpressiveDropdownEntry(value: g.id, label: g.name),
        ],
        onSelected: (id) {
          if (id == null) return;
          cubit.selectGroup(id == _all ? null : id);
        },
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

// ─── Budget card ──────────────────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.selected,
    required this.canManage,
  });
  final Budget budget;
  final bool selected;
  final bool canManage;

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
                    context.categoryName(b.category),
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
            if (canManage)
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
      title: context.categoryName(budget.category),
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
      body: context.l10n.deleteBudgetBody(
        context.categoryName(budget.category),
      ),
      confirmLabel: context.l10n.delete,
      danger: true,
    );
    if (confirmed && context.mounted) {
      await context.read<BudgetCubit>().deleteBudget(budgetId: budget.id);
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
    final amount = TabbyAmountField.parse(_ctrl.text);
    if (amount == null || amount <= 0) return;
    setState(() => _loading = true);
    final ok = await context.read<BudgetCubit>().updateBudget(
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
              Text(context.categoryName(b.category), style: tt.titleMedium),
            ],
          ),
          const SizedBox(height: 20),
          Text(context.l10n.monthlyLimit, style: tt.labelLarge),
          const SizedBox(height: 6),
          TabbyAmountField(
            controller: _ctrl,
            autofocus: true,
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
  Category? _selectedCategory;
  final _amountCtrl = TextEditingController();
  bool _loading = false;

  List<Category> get _availableCategories {
    return context.read<BudgetCubit>().availableCategories(
          budgets: widget.state.budgets,
          allCategories: widget.state.allCategories,
        );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount =
        TabbyAmountField.parse(_amountCtrl.text);
    if (_selectedCategory == null || amount == null || amount <= 0) {
      return;
    }
    setState(() => _loading = true);
    final ok = await context.read<BudgetCubit>().createBudget(
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
                          Text(context.categoryName(c)),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (c) => setState(() => _selectedCategory = c),
          ),
          const SizedBox(height: 16),
          Text(context.l10n.monthlyLimit, style: tt.labelLarge),
          const SizedBox(height: 6),
          TabbyAmountField(controller: _amountCtrl),
        ],
      ),
    );
  }
}

// ─── Personal purchases (Pour moi) ────────────────────────────────────────────

class _PersonalExpensesSection extends StatelessWidget {
  const _PersonalExpensesSection({required this.state});

  final BudgetLoaded state;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = context.tabbyColors;
    final items = state.visiblePersonalExpenses;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.personalPurchases, style: tt.titleMedium),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.noPersonalPurchases,
                    style: tt.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.noPersonalPurchasesHint,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            )
          else
            ...items.map(
              (expense) => _PersonalExpenseTile(expense: expense, state: state),
            ),
        ],
      ),
    );
  }
}

class _PersonalExpenseTile extends StatelessWidget {
  const _PersonalExpenseTile({required this.expense, required this.state});

  final PersonalExpense expense;
  final BudgetLoaded state;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = context.tabbyColors;
    final catColor = expense.category.resolvedColor;
    final onCat = expense.category.onResolvedColor;

    return TabbyListCard(
      margin: const EdgeInsets.only(bottom: 8),
      onTap: () => _showActions(context),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          TabbyCategoryGlyph(
            icon: expense.category.flutterIcon,
            background: catColor,
            foreground: onCat,
            size: 40,
            iconSize: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.name,
                  style: tt.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '${context.categoryName(expense.category)} · ${_formatPersonalDate(context, expense.expenseDate)}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          ExpressiveFigure(
            value: formatMoney(context, expense.amount),
            size: ExpressiveFigureSize.small,
          ),
        ],
      ),
    );
  }

  void _showActions(BuildContext context) {
    showTabbyActionSheet(
      context,
      title: expense.name,
      actions: [
        TabbyActionSheetItem(
          label: context.l10n.editExpense,
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
        child: _EditPersonalDialog(
          expense: expense,
          categories: state.allCategories,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showTabbyConfirm(
      context,
      title: context.l10n.deletePersonalTitle,
      body: context.l10n.deletePersonalBody(expense.name),
      confirmLabel: context.l10n.delete,
      danger: true,
    );
    if (!confirmed || !context.mounted) return;
    final err = await context.read<BudgetCubit>().deletePersonal(expense.id);
    if (!context.mounted || err == null) return;
    showTabbySnack(context, context.l10nError(err));
  }
}

class _EditPersonalDialog extends StatefulWidget {
  const _EditPersonalDialog({
    required this.expense,
    required this.categories,
  });

  final PersonalExpense expense;
  final List<Category> categories;

  @override
  State<_EditPersonalDialog> createState() => _EditPersonalDialogState();
}

class _EditPersonalDialogState extends State<_EditPersonalDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late Category _category;
  late DateTime _date;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.expense.name);
    _amountCtrl = TextEditingController(
      text: widget.expense.amount.toStringAsFixed(2),
    );
    _category = widget.categories.firstWhere(
      (c) => c.id == widget.expense.category.id,
      orElse: () => widget.expense.category,
    );
    _date = widget.expense.expenseDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = TabbyAmountField.parse(_amountCtrl.text);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || amount == null || amount <= 0) return;
    setState(() => _loading = true);
    final ok = await context.read<BudgetCubit>().updatePersonal(
          expenseId: widget.expense.id,
          name: name,
          amount: amount,
          categoryId: _category.id,
          expenseDate: _date,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final dateLabel =
        '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}';

    return TabbyFormDialog(
      title: context.l10n.editExpense,
      submitLabel: context.l10n.save,
      cancelLabel: context.l10n.cancel,
      loading: _loading,
      scrollable: true,
      onSubmit: _save,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: context.l10n.name),
          ),
          const SizedBox(height: 12),
          TabbyAmountField(
            controller: _amountCtrl,
            label: context.l10n.amount,
          ),
          const SizedBox(height: 12),
          Text(context.l10n.category, style: tt.labelLarge),
          const SizedBox(height: 6),
          DropdownButtonFormField<Category>(
            value: _category,
            items: [
              if (!widget.categories.any((c) => c.id == _category.id))
                _category,
              ...widget.categories,
            ]
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        c.iconWidget(size: 18, color: c.resolvedColor),
                        const SizedBox(width: 8),
                        Text(context.categoryName(c)),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (c) {
              if (c != null) setState(() => _category = c);
            },
          ),
          const SizedBox(height: 12),
          Text(context.l10n.date, style: tt.labelLarge),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickDate,
            borderRadius: context.tabbyShapes.radiusMedium,
            child: InputDecorator(
              decoration: const InputDecoration(
                prefixIcon: Icon(Symbols.calendar_month_rounded, size: 18),
              ),
              child: Text(dateLabel, style: tt.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatPersonalDate(BuildContext context, DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final expenseDay = DateTime(date.year, date.month, date.day);
  final days = today.difference(expenseDay).inDays;

  if (days <= 0) return context.l10n.today;
  if (days == 1) return context.l10n.daysAgoOne;
  return context.l10n.daysAgo(days);
}
