import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/budget.dart';
import '../../../shared/widgets/expressive/expressive.dart';
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
          appBar: AppBar(title: const Text('Budget')),
          body: switch (state) {
            BudgetInitial() || BudgetLoading() =>
              const Center(child: CircularProgressIndicator()),
            BudgetError(:final message) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () => context.read<BudgetCubit>().load(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
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
    showDialog(
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
    final now = DateTime.now();
    final isCurrentMonth = state.selectedYear == now.year &&
        state.selectedMonth == now.month;

    return CustomScrollView(
      slivers: [
        if (state.stats.total > 0)
          SliverToBoxAdapter(
            child: ExpressiveHeroBanner(
              label: 'Total du mois',
              value: state.stats.total.toStringAsFixed(2),
              suffix: ' €',
              subtitle: state.stats.monthLabel,
              variant: ExpressiveTonalVariant.coral,
              accentIcon: Symbols.payments_rounded,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            ),
          ),

        // ── Navigation mois ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _MonthNav(
            year: state.selectedYear,
            month: state.selectedMonth,
            monthLabel: state.stats.monthLabel,
            isCurrentMonth: isCurrentMonth,
          ),
        ),

        // ── Filtre groupe ──────────────────────────────────────────────────
        if (state.groups.length > 1)
          SliverToBoxAdapter(
            child: _GroupFilter(
              groups: state.groups,
              selectedGroupId: state.selectedGroupId,
            ),
          ),

        // ── Section statistiques ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: _StatsSection(stats: state.stats),
        ),

        // ── Section budgets ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Budgets du mois',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        if (state.budgets.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _BudgetCard(budget: state.budgets[i]),
                childCount: state.budgets.length,
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Aucun budget ce mois — fixe un plafond par catégorie.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.tabbyColors.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Center(
              child: ExpressiveCtaButton(
                label: 'Nouveau budget',
                onPressed: onCreateBudget,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Month navigation ─────────────────────────────────────────────────────────

class _MonthNav extends StatelessWidget {
  const _MonthNav({
    required this.year,
    required this.month,
    required this.monthLabel,
    required this.isCurrentMonth,
  });

  final int year, month;
  final String monthLabel;
  final bool isCurrentMonth;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Symbols.chevron_left_rounded),
            onPressed: () => context.read<BudgetCubit>().prevMonth(),
          ),
          const SizedBox(width: 4),
          Column(
            children: [
              Text(
                monthLabel,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '$year',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              Symbols.chevron_right_rounded,
              color: isCurrentMonth ? cs.outlineVariant : null,
            ),
            onPressed:
                isCurrentMonth ? null : () => context.read<BudgetCubit>().nextMonth(),
          ),
        ],
      ),
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
            child: _GroupFilterChip(
              label: 'Tous',
              selected: selectedGroupId == null,
              onTap: () => cubit.selectGroup(null),
            ),
          ),
          ...groups.map(
            (g) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _GroupFilterChip(
                label: g.name,
                selected: selectedGroupId == g.id,
                onTap: () => cubit.selectGroup(g.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupFilterChip extends StatelessWidget {
  const _GroupFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
      elevation: 0,
      shape: shapes.pill(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: shapes.radiusFull,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(
                  Symbols.check_rounded,
                  size: 16,
                  color: cs.onPrimaryContainer,
                  fill: 1,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: tt.labelLarge?.copyWith(
                  color: selected
                      ? cs.onPrimaryContainer
                      : cs.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stats section (donut chart + legend cards) ───────────────────────────────

class _StatsSection extends StatefulWidget {
  const _StatsSection({required this.stats});
  final MonthStats stats;

  @override
  State<_StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<_StatsSection> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final semantic = context.tabbySemantic;
    final tt = Theme.of(context).textTheme;
    final shapes = context.tabbyShapes;
    final stats = widget.stats;

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
              'Aucune dépense ce mois',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ExpressiveDonutChart(
            sections: stats.categories,
            total: stats.total,
            selectedIndex: _touchedIndex,
            onSelectedIndexChanged: (i) => setState(() => _touchedIndex = i),
          ),

          const SizedBox(height: 16),

          // ── Légende ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Toutes les dépenses', style: tt.bodySmall),
                Text(
                  'Total ${stats.total.toStringAsFixed(2)} €',
                  style: tt.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          ...stats.categories.asMap().entries.map((entry) {
            final i = entry.key;
            final cat = entry.value;
            final catColor = semantic.chartColorFor(cat.category);
            final isSelected = _touchedIndex == i;

            return GestureDetector(
              onTap: () =>
                  setState(() => _touchedIndex = isSelected ? null : i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? catColor
                      : cs.surfaceContainerLow,
                  borderRadius: shapes.radiusLarge,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Material(
                          color: isSelected
                              ? semantic.onFor(catColor, cs)
                              : catColor,
                          shape: shapes.circle(),
                          clipBehavior: Clip.antiAlias,
                          child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: cat.category.iconWidget(
                              size: 18,
                              color: isSelected
                                  ? catColor
                                  : semantic.onFor(catColor, cs),
                              fill: 1,
                            ),
                          ),
                        ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.category.name,
                                style: tt.titleSmall?.copyWith(
                                  color: isSelected
                                      ? semantic.onFor(catColor, cs)
                                      : null,
                                ),
                              ),
                              Text(
                                '${cat.percent.toStringAsFixed(1)}% du total',
                                style: tt.bodySmall?.copyWith(
                                  color: isSelected
                                      ? semantic.onFor(catColor, cs)
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ExpressiveFigure(
                          value: cat.amount.toStringAsFixed(2),
                          suffix: ' €',
                          size: ExpressiveFigureSize.small,
                          color: isSelected
                              ? semantic.onFor(catColor, cs)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Mini barre de progression colorée
                    ClipRRect(
                      borderRadius: shapes.radiusExtraSmall,
                      child: LinearProgressIndicator(
                        value: cat.percent / 100,
                        minHeight: 5,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isSelected
                              ? semantic.onFor(catColor, cs)
                              : catColor,
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
  const _BudgetCard({required this.budget});
  final Budget budget;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;
    final semantic = context.tabbySemantic;
    final shapes = context.tabbyShapes;
    final b = budget;
    final catColor = semantic.chartColorFor(b.category);
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
            Material(
              color: isDanger ? semantic.danger : catColor,
              shape: shapes.circle(),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: b.category.iconWidget(
                    size: 22,
                    color: isDanger
                        ? semantic.onDanger
                        : semantic.onFor(catColor, cs),
                  ),
                ),
              ),
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
                    'Budget ${b.limitAmount.toStringAsFixed(0)} €/mois',
                    style: tt.bodySmall?.copyWith(color: mutedColor),
                  ),
                ],
              ),
            ),
            ExpressiveBadge(
              label: b.status == BudgetStatus.danger
                  ? 'Dépassé'
                  : b.status == BudgetStatus.warning
                      ? 'Attention'
                      : 'OK',
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
              '${b.spentAmount.toStringAsFixed(2)} € dépensés',
              style: tt.bodySmall?.copyWith(
                color: isDanger ? semantic.onDangerContainer : null,
              ),
            ),
            Text(
              b.remaining >= 0
                  ? '${b.remaining.toStringAsFixed(2)} € restants'
                  : '${b.remaining.abs().toStringAsFixed(2)} € de dépassement',
              style: tt.bodySmall?.copyWith(
                color: isDanger ? semantic.onDangerContainer : mutedColor,
                fontWeight: isDanger ? FontWeight.w700 : null,
              ),
            ),
          ],
        ),
      ],
    );

    if (isDanger) {
      return GestureDetector(
        onLongPress: () => _showActions(context),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ExpressiveTonalCard(
            variant: ExpressiveTonalVariant.danger,
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: shapes.radiusExtraLarge,
        onLongPress: () => _showActions(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: context.tabbyShapes.modalTopShape,
      builder: (ctx) => BlocProvider.value(
        value: context.read<BudgetCubit>(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 32, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: context.tabbyShapes.radiusExtraSmall,
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    budget.category.iconWidget(
                      size: 20,
                      color: context.tabbySemantic.chartColorFor(budget.category),
                    ),
                    const SizedBox(width: 10),
                    Text(budget.category.name, style: tt.titleMedium),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Symbols.edit_rounded),
                title: const Text('Modifier le plafond'),
                shape: context.tabbyShapes.fieldShape,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showEditDialog(context);
                },
              ),
              ListTile(
                leading: Icon(Symbols.delete_rounded, color: cs.error),
                title: Text('Supprimer', style: TextStyle(color: cs.error)),
                shape: context.tabbyShapes.fieldShape,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDelete(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<BudgetCubit>(),
        child: _EditBudgetDialog(budget: budget),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce budget ?'),
        content: Text(
            'Le budget "${budget.category.name}" sera supprimé.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
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
    final catColor = context.tabbySemantic.chartColorFor(b.category);

    return AlertDialog(
      title: const Text('Modifier le budget'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: catColor,
                  borderRadius: context.tabbyShapes.radiusMedium,
                ),
                child: Center(
                  child: b.category.iconWidget(
                    size: 20,
                    color: context.tabbySemantic.onFor(
                      catColor,
                      Theme.of(context).colorScheme,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(b.category.name, style: tt.titleMedium),
            ],
          ),
          const SizedBox(height: 20),
          Text('Plafond mensuel', style: tt.labelLarge),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  height: 16, width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Enregistrer'),
        ),
      ],
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
    final semantic = context.tabbySemantic;

    return AlertDialog(
      title: const Text('Nouveau budget'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.state.groups.length > 1) ...[
              Text('Groupe', style: tt.labelLarge),
              const SizedBox(height: 6),
              DropdownButtonFormField<Group>(
                initialValue: _selectedGroup,
                hint: const Text('Choisir un groupe'),
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
            Text('Catégorie', style: tt.labelLarge),
            const SizedBox(height: 6),
            DropdownButtonFormField<Category>(
              initialValue: _selectedCategory,
              hint: const Text('Choisir une catégorie'),
              items: _availableCategories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            c.iconWidget(
                              size: 18,
                              color: semantic.chartColorFor(c),
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
            Text('Plafond mensuel', style: tt.labelLarge),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  height: 16, width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Créer'),
        ),
      ],
    );
  }
}
