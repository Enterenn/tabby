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
          child: TabbySectionHeader(
            title: context.l10n.monthBudgets,
            padding: EdgeInsets.fromLTRB(
              context.tabbySpace.lg,
              context.tabbySpace.xl,
              context.tabbySpace.sm,
              context.tabbySpace.sm,
            ),
            trailing: canCreate
                ? TextButton(
                    onPressed: onCreateBudget,
                    child: Text(context.l10n.newBudget),
                  )
                : null,
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

