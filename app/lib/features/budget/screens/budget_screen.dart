import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/budget.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/group.dart';
import '../cubit/budget_cubit.dart';

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

class _BudgetView extends StatelessWidget {
  const _BudgetView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocBuilder<BudgetCubit, BudgetState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Budgets'),
            actions: [
              if (state is BudgetLoaded)
                IconButton(
                  icon: const Icon(Symbols.refresh_rounded),
                  onPressed: () => context.read<BudgetCubit>().load(),
                ),
            ],
          ),
          floatingActionButton: state is BudgetLoaded
              ? FloatingActionButton.extended(
                  onPressed: () =>
                      _showCreateDialog(context, state),
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
                      onPressed: () =>
                          context.read<BudgetCubit>().load(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            BudgetLoaded(:final budgets, :final groups) => budgets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Symbols.savings_rounded,
                            size: 56, color: cs.outlineVariant),
                        const SizedBox(height: 16),
                        Text('Aucun budget défini',
                            style: tt.headlineSmall),
                        const SizedBox(height: 8),
                        Text(
                          'Appuie sur + pour créer ton premier budget',
                          style: tt.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : _BudgetList(budgets: budgets, groups: groups),
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

// ─── Budget list ──────────────────────────────────────────────────────────────

class _BudgetList extends StatelessWidget {
  const _BudgetList({required this.budgets, required this.groups});

  final List<Budget> budgets;
  final List<Group> groups;

  @override
  Widget build(BuildContext context) {
    // Grouper par group_id
    final Map<String, List<Budget>> byGroup = {};
    for (final b in budgets) {
      byGroup.putIfAbsent(b.groupId, () => []).add(b);
    }

    final groupMap = {for (final g in groups) g.id: g};

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: byGroup.entries.map((entry) {
        final group = groupMap[entry.key];
        final groupBudgets = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (byGroup.length > 1) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  group?.name ?? entry.key,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
            ...groupBudgets.map(
              (b) => _BudgetCard(budget: b),
            ),
          ],
        );
      }).toList(),
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
        onTap: () => _showEditSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête : icône catégorie + nom + actions
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
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
                  // Status pill
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

              // Barre de progression
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: clampedPercent,
                  minHeight: 8,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(b.statusColor),
                ),
              ),

              const SizedBox(height: 8),

              // Montants
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${b.spentAmount.toStringAsFixed(2)} € dépensés',
                    style: tt.bodySmall,
                  ),
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

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<BudgetCubit>(),
        child: _EditBudgetSheet(budget: budget),
      ),
    );
  }
}

// ─── Edit budget bottom sheet ─────────────────────────────────────────────────

class _EditBudgetSheet extends StatefulWidget {
  const _EditBudgetSheet({required this.budget});
  final Budget budget;

  @override
  State<_EditBudgetSheet> createState() => _EditBudgetSheetState();
}

class _EditBudgetSheetState extends State<_EditBudgetSheet> {
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce budget ?'),
        content: Text(
            'Le budget "${widget.budget.category.name}" sera supprimé.'),
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
    if (confirmed != true || !mounted) return;

    final ok = await context.read<BudgetCubit>().deleteBudget(
          groupId: widget.budget.groupId,
          budgetId: widget.budget.id,
        );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final b = widget.budget;

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: b.category.flutterColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(b.category.flutterIcon,
                    color: b.category.flutterColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(b.category.name, style: tt.headlineSmall),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
            ],
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Plafond mensuel',
              suffixText: '€',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton.icon(
                onPressed: _loading ? null : _delete,
                icon: Icon(Symbols.delete_rounded, size: 18, color: cs.error),
                label: Text('Supprimer',
                    style: TextStyle(color: cs.error)),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Enregistrer'),
              ),
            ],
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
    if (_selectedGroup == null || _selectedCategory == null ||
        amount == null || amount <= 0) {
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
            // Sélecteur de groupe (si plusieurs)
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

            // Sélecteur de catégorie
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

            // Montant
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
