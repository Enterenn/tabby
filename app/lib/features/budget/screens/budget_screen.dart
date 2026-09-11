import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/budget.dart';
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
          floatingActionButton: state is BudgetLoaded
              ? FloatingActionButton.extended(
                  onPressed: () => _showCreateDialog(context, state),
                  icon: const Icon(Symbols.add_rounded, fill: 1),
                  label: const Text('Nouveau budget'),
                )
              : null,
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
            BudgetLoaded() => _BudgetContent(state: state),
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
  const _BudgetContent({required this.state});
  final BudgetLoaded state;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = state.selectedYear == now.year &&
        state.selectedMonth == now.month;

    return CustomScrollView(
      slivers: [
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
        if (state.budgets.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Budgets du mois',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _BudgetCard(budget: state.budgets[i]),
                childCount: state.budgets.length,
              ),
            ),
          ),
        ] else
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Chip "Tous"
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Tous'),
              selected: selectedGroupId == null,
              onSelected: (_) =>
                  context.read<BudgetCubit>().selectGroup(null),
            ),
          ),
          ...groups.map((g) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(g.name),
                  selected: selectedGroupId == g.id,
                  onSelected: (_) =>
                      context.read<BudgetCubit>().selectGroup(g.id),
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Stats section (pie chart + legend) ──────────────────────────────────────

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final stats = widget.stats;

    if (stats.total == 0) {
      return Container(
        height: 180,
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

    final sections = stats.categories.asMap().entries.map((entry) {
      final i = entry.key;
      final cat = entry.value;
      final isTouched = _touchedIndex == i;
      return PieChartSectionData(
        value: cat.percent,
        color: cat.category.flutterColor,
        radius: isTouched ? 72 : 60,
        showTitle: false,
        borderSide: isTouched
            ? BorderSide(color: cs.surface, width: 3)
            : const BorderSide(color: Colors.transparent),
      );
    }).toList();

    final touched =
        _touchedIndex != null && _touchedIndex! < stats.categories.length
            ? stats.categories[_touchedIndex!]
            : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Camembert + total central
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 56,
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          setState(() => _touchedIndex = null);
                          return;
                        }
                        setState(() => _touchedIndex =
                            response.touchedSection!.touchedSectionIndex);
                      },
                    ),
                  ),
                ),
                // Label central
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      touched != null
                          ? '${touched.percent.toStringAsFixed(1)}%'
                          : '${stats.total.toStringAsFixed(0)} €',
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: touched?.category.flutterColor,
                      ),
                    ),
                    Text(
                      touched?.category.name ?? 'Total',
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Légende ordonnée par %
          ...stats.categories.asMap().entries.map((entry) {
            final i = entry.key;
            final cat = entry.value;
            final isSelected = _touchedIndex == i;
            return GestureDetector(
              onTap: () => setState(
                  () => _touchedIndex = isSelected ? null : i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cat.category.flutterColor.withValues(alpha: 0.1)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? cat.category.flutterColor
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: cat.category.flutterColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(cat.category.flutterIcon,
                        size: 16, color: cat.category.flutterColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(cat.category.name,
                          style: tt.bodyMedium),
                    ),
                    Text(
                      '${cat.amount.toStringAsFixed(2)} €',
                      style: tt.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${cat.percent.toStringAsFixed(1)}%',
                        textAlign: TextAlign.right,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final b = budget;
    final clampedPercent = (b.percent / 100).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onLongPress: () => _showActions(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: b.category.flutterColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(b.category.flutterIcon,
                        color: b.category.flutterColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.category.name, style: tt.titleMedium),
                        Text(
                          'Budget ${b.limitAmount.toStringAsFixed(0)} €/mois',
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: b.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      b.status == BudgetStatus.danger
                          ? 'Dépassé'
                          : b.status == BudgetStatus.warning
                              ? 'Attention'
                              : 'OK',
                      style: tt.labelSmall?.copyWith(
                        color: b.statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: clampedPercent,
                  minHeight: 8,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(b.statusColor),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${b.spentAmount.toStringAsFixed(2)} € dépensés',
                      style: tt.bodySmall),
                  Text(
                    b.remaining >= 0
                        ? '${b.remaining.toStringAsFixed(2)} € restants'
                        : '${b.remaining.abs().toStringAsFixed(2)} € de dépassement',
                    style: tt.bodySmall?.copyWith(
                      color: b.status == BudgetStatus.danger
                          ? AppColors.danger
                          : cs.onSurfaceVariant,
                      fontWeight: b.status == BudgetStatus.danger
                          ? FontWeight.w700
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Icon(budget.category.flutterIcon,
                        color: budget.category.flutterColor, size: 20),
                    const SizedBox(width: 10),
                    Text(budget.category.name, style: tt.titleMedium),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Symbols.edit_rounded),
                title: const Text('Modifier le plafond'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showEditDialog(context);
                },
              ),
              ListTile(
                leading: Icon(Symbols.delete_rounded, color: cs.error),
                title: Text('Supprimer',
                    style: TextStyle(color: cs.error)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
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
                  color: b.category.flutterColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(b.category.flutterIcon,
                    color: b.category.flutterColor, size: 20),
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
                            Icon(c.flutterIcon,
                                color: c.flutterColor, size: 18),
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
