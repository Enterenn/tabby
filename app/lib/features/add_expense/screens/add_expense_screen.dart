import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../shared/models/category.dart';
import '../../../shared/models/group.dart';
import '../cubit/add_expense_cubit.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key, this.groupId});

  final String? groupId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddExpenseCubit()..load(groupId ?? ''),
      child: _AddExpenseView(groupId: groupId),
    );
  }
}

class _AddExpenseView extends StatefulWidget {
  const _AddExpenseView({required this.groupId});

  final String? groupId;

  @override
  State<_AddExpenseView> createState() => _AddExpenseViewState();
}

class _AddExpenseViewState extends State<_AddExpenseView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  Category? _selectedCategory;
  String? _selectedPayerId;
  DateTime _expenseDate = DateTime.now();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _expenseDate = picked);
  }

  Future<void> _submit(AddExpenseReady state) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis une catégorie')),
      );
      return;
    }

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montant invalide')),
      );
      return;
    }

    final ok = await context.read<AddExpenseCubit>().submit(
          groupId: widget.groupId!,
          name: _nameCtrl.text.trim(),
          amount: amount,
          categoryId: _selectedCategory!.id,
          paidBy: _selectedPayerId ?? state.group.members.first.user.id,
          expenseDate: _expenseDate,
        );

    if (ok && mounted) {
      context.pop(true); // true = dépense ajoutée, le parent peut rafraîchir
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocConsumer<AddExpenseCubit, AddExpenseState>(
      listener: (context, state) {
        if (state is AddExpenseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Nouvelle dépense'),
            leading: IconButton(
              icon: const Icon(Symbols.close_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: _buildBody(context, cs, tt, state),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    AddExpenseState state,
  ) {
    if (state is AddExpenseInitial || state is AddExpenseLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is AddExpenseError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () =>
                  context.read<AddExpenseCubit>().load(widget.groupId ?? ''),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (state is AddExpenseReady) {
      _lastReady = (state.categories, state.group);
      return _buildForm(context, cs, tt,
          categories: state.categories, group: state.group, isSubmitting: false);
    }
    if (state is AddExpenseSubmitting && _lastReady != null) {
      final (cats, grp) = _lastReady!;
      return _buildForm(context, cs, tt,
          categories: cats, group: grp, isSubmitting: true);
    }
    return const SizedBox();
  }

  (List<Category>, Group)? _lastReady;

  Widget _buildForm(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt, {
    required List<Category> categories,
    required Group group,
    required bool isSubmitting,
  }) {
    _lastReady = (categories, group);

    // Initialiser le payeur courant par défaut si pas encore défini
    if (_selectedPayerId == null && group.members.isNotEmpty) {
      // L'utilisateur courant est le 1er membre (tri par joined_at)
      // En pratique on prend le premier membre disponible
      _selectedPayerId = group.members.first.user.id;
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          // ── Montant ────────────────────────────────────────────────────────
          const SizedBox(height: 24),
          Center(
            child: IntrinsicWidth(
              child: TextFormField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: tt.displayMedium?.copyWith(color: cs.onSurface),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                decoration: InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  hintText: '0,00',
                  hintStyle:
                      tt.displayMedium?.copyWith(color: cs.outlineVariant),
                  suffixText: '€',
                  suffixStyle: tt.headlineLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) {
                    return 'Nombre invalide';
                  }
                  return null;
                },
                autofocus: true,
              ),
            ),
          ),

          // ── Nom ────────────────────────────────────────────────────────────
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Description'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requis' : null,
          ),

          // ── Catégorie ──────────────────────────────────────────────────────
          const SizedBox(height: 24),
          Text('Catégorie', style: tt.titleSmall),
          const SizedBox(height: 10),
          _CategoryGrid(
            categories: categories,
            selected: _selectedCategory,
            onSelect: (c) => setState(() => _selectedCategory = c),
          ),

          // ── Payeur + Date ──────────────────────────────────────────────────
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payé par', style: tt.titleSmall),
                    const SizedBox(height: 8),
                    _PayerDropdown(
                      members: group.members,
                      selectedId: _selectedPayerId,
                      onChanged: (id) =>
                          setState(() => _selectedPayerId = id),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date', style: tt.titleSmall),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Symbols.calendar_month_rounded,
                                size: 18, color: cs.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Text(
                              '${_expenseDate.day.toString().padLeft(2, '0')}/${_expenseDate.month.toString().padLeft(2, '0')}',
                              style: tt.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Submit ─────────────────────────────────────────────────────────
          const SizedBox(height: 32),
          FilledButton(
            onPressed: isSubmitting
                ? null
                : () => _submit(
                      AddExpenseReady(categories: categories, group: group),
                    ),
            child: isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

// ─── CategoryGrid ─────────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<Category> categories;
  final Category? selected;
  final ValueChanged<Category> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((c) {
        final isSelected = selected?.id == c.id;
        return GestureDetector(
          onTap: () => onSelect(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? c.flutterColor.withValues(alpha: 0.18)
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? c.flutterColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  c.flutterIcon,
                  size: 18,
                  color: isSelected ? c.flutterColor : cs.onSurfaceVariant,
                  fill: isSelected ? 1 : 0,
                ),
                const SizedBox(width: 6),
                Text(
                  c.name,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color:
                            isSelected ? c.flutterColor : cs.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── PayerDropdown ────────────────────────────────────────────────────────────

class _PayerDropdown extends StatelessWidget {
  const _PayerDropdown({
    required this.members,
    required this.selectedId,
    required this.onChanged,
  });

  final List<GroupMember> members;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      isExpanded: true,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: members
          .map(
            (m) => DropdownMenuItem(
              value: m.user.id,
              child: Text(m.user.name),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
