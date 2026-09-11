import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/group.dart';
import '../cubit/add_expense_cubit.dart';

// ─── Screen entry point ───────────────────────────────────────────────────────

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key, this.groupId});

  final String? groupId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddExpenseCubit()..load(groupId ?? ''),
      child: _AddExpenseView(groupId: groupId ?? ''),
    );
  }
}

// ─── Main view (stateful: owns all form state) ────────────────────────────────

class _AddExpenseView extends StatefulWidget {
  const _AddExpenseView({required this.groupId});

  final String groupId;

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
  bool _customSplit = false;
  bool _recurring = false;

  // memberId → TextEditingController pour la répartition personnalisée
  final Map<String, TextEditingController> _splitCtrls = {};

  AddExpenseReady? _lastReady;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    for (final c in _splitCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Initialise les contrôleurs de split avec répartition égale
  void _initSplitCtrls(List<GroupMember> members) {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    final n = members.length;
    final perPerson = n > 0 ? (amount / n) : 0.0;

    for (final m in members) {
      if (!_splitCtrls.containsKey(m.user.id)) {
        _splitCtrls[m.user.id] = TextEditingController();
      }
      _splitCtrls[m.user.id]!.text =
          perPerson.toStringAsFixed(2);
    }
  }

  // Somme des montants saisis dans la répartition custom
  double get _splitsTotal => _splitCtrls.values.fold(0.0, (acc, ctrl) {
        return acc + (double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0.0);
      });

  double get _expenseAmount =>
      double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0.0;

  bool get _splitsValid =>
      (_expenseAmount - _splitsTotal).abs() < 0.02;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _expenseDate = picked);
  }

  Future<void> _submit() async {
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
    if (_customSplit && !_recurring && !_splitsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('La somme des parts doit égaler le montant total')),
      );
      return;
    }

    final ready = _lastReady!;
    final payerId =
        _selectedPayerId ?? ready.group.members.first.user.id;

    List<Map<String, dynamic>>? splits;
    if (_customSplit) {
      splits = _splitCtrls.entries.map((e) {
        return {
          'user_id': e.key,
          'amount':
              double.tryParse(e.value.text.replaceAll(',', '.')) ?? 0.0,
        };
      }).toList();
    }

    final ok = await context.read<AddExpenseCubit>().submit(
          groupId: widget.groupId,
          name: _nameCtrl.text.trim(),
          amount: amount,
          categoryId: _selectedCategory!.id,
          paidBy: payerId,
          expenseDate: _expenseDate,
          customSplits: _recurring ? null : splits,
          recurring: _recurring,
        );

    if (ok && mounted) context.pop(true);
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
        if (state is AddExpenseInitial || state is AddExpenseLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is AddExpenseError) {
          return Scaffold(
            appBar: AppBar(leading: IconButton(
              icon: const Icon(Symbols.close_rounded),
              onPressed: () => context.pop(),
            )),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () =>
                        context.read<AddExpenseCubit>().load(widget.groupId),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        final AddExpenseReady ready;
        final bool submitting;
        if (state is AddExpenseReady) {
          ready = state;
          _lastReady = state;
          submitting = false;
        } else {
          ready = _lastReady!;
          submitting = true;
        }

        if (_selectedPayerId == null && ready.group.members.isNotEmpty) {
          _selectedPayerId = ready.group.members.first.user.id;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Nouvelle dépense'),
            leading: IconButton(
              icon: const Icon(Symbols.close_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              children: [

                // ── Montant ────────────────────────────────────────────────
                const SizedBox(height: 24),
                Center(
                  child: IntrinsicWidth(
                    child: TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: tt.displayMedium?.copyWith(color: cs.onSurface),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                      ],
                      onChanged: (_) {
                        if (_customSplit) setState(() {});
                      },
                      decoration: InputDecoration(
                        filled: false,
                        border: InputBorder.none,
                        hintText: '0,00',
                        hintStyle: tt.displayMedium
                            ?.copyWith(color: cs.outlineVariant),
                        suffixText: '€',
                        suffixStyle: tt.headlineLarge
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        if (double.tryParse(v.replaceAll(',', '.')) == null) {
                          return 'Invalide';
                        }
                        return null;
                      },
                      autofocus: true,
                    ),
                  ),
                ),

                // ── Description ────────────────────────────────────────────
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requis' : null,
                ),

                // ── Catégorie ──────────────────────────────────────────────
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text('Catégorie', style: tt.titleSmall),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showCreateCategorySheet(
                          context, ready, cs, tt),
                      icon: const Icon(Symbols.add_rounded, size: 16),
                      label: const Text('Nouvelle'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _CategoryGrid(
                  categories: ready.categories,
                  selected: _selectedCategory,
                  onSelect: (c) => setState(() => _selectedCategory = c),
                ),

                // ── Payeur + Date ──────────────────────────────────────────
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
                            members: ready.group.members,
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
                                      size: 18,
                                      color: cs.onSurfaceVariant),
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

                // ── Répartition ────────────────────────────────────────────
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text('Répartition', style: tt.titleSmall),
                    const Spacer(),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Égale')),
                        ButtonSegment(value: true, label: Text('Perso')),
                      ],
                      selected: {_customSplit},
                      onSelectionChanged: _recurring
                          ? null
                          : (set) {
                              setState(() {
                                _customSplit = set.first;
                                if (_customSplit) {
                                  _initSplitCtrls(ready.group.members);
                                }
                              });
                            },
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                if (_customSplit) ...[
                  const SizedBox(height: 12),
                  _CustomSplitSection(
                    members: ready.group.members,
                    splitCtrls: _splitCtrls,
                    total: _expenseAmount,
                    splitsTotal: _splitsTotal,
                    isValid: _splitsValid,
                    onChanged: () => setState(() {}),
                  ),
                ],

                // ── Récurrence ────────────────────────────────────────────
                const SizedBox(height: 8),
                _RecurringTile(
                  value: _recurring,
                  expenseDate: _expenseDate,
                  onChanged: (v) => setState(() {
                    _recurring = v;
                    if (v) _customSplit = false; // incompatible avec custom split
                  }),
                ),

                // ── Submit ─────────────────────────────────────────────────
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: submitting ? null : _submit,
                  child: submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_recurring ? 'Programmer la récurrence' : 'Enregistrer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateCategorySheet(
    BuildContext context,
    AddExpenseReady ready,
    ColorScheme cs,
    TextTheme tt,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<AddExpenseCubit>(),
        child: _CreateCategorySheet(
          groupId: widget.groupId,
          onCreated: (cat) => setState(() => _selectedCategory = cat),
        ),
      ),
    );
  }
}

// ─── Custom split section ─────────────────────────────────────────────────────

class _CustomSplitSection extends StatelessWidget {
  const _CustomSplitSection({
    required this.members,
    required this.splitCtrls,
    required this.total,
    required this.splitsTotal,
    required this.isValid,
    required this.onChanged,
  });

  final List<GroupMember> members;
  final Map<String, TextEditingController> splitCtrls;
  final double total;
  final double splitsTotal;
  final bool isValid;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final diff = (total - splitsTotal).abs();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...members.map((m) {
              final ctrl = splitCtrls[m.user.id]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                        m.user.name[0].toUpperCase(),
                        style: tt.labelMedium?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(m.user.name, style: tt.bodyMedium),
                    ),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        controller: ctrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textAlign: TextAlign.right,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                        ],
                        onChanged: (_) => onChanged(),
                        decoration: InputDecoration(
                          suffixText: '€',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: cs.primary, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total réparti', style: tt.bodySmall),
                Row(
                  children: [
                    if (!isValid)
                      Text(
                        diff < 0.01
                            ? '≈ ok'
                            : '${diff > 0 ? '-' : '+'}${diff.toStringAsFixed(2)} €',
                        style: tt.bodySmall?.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      '${splitsTotal.toStringAsFixed(2)} / ${total.toStringAsFixed(2)} €',
                      style: tt.bodyMedium?.copyWith(
                        color: isValid ? AppColors.success : AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
                        color: isSelected ? c.flutterColor : cs.onSurfaceVariant,
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
          .map((m) => DropdownMenuItem(value: m.user.id, child: Text(m.user.name)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ─── Recurring tile ───────────────────────────────────────────────────────────

class _RecurringTile extends StatelessWidget {
  const _RecurringTile({
    required this.value,
    required this.expenseDate,
    required this.onChanged,
  });

  final bool value;
  final DateTime expenseDate;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: value
            ? cs.primaryContainer.withValues(alpha: 0.5)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        secondary: Icon(
          Symbols.repeat_rounded,
          color: value ? cs.primary : cs.onSurfaceVariant,
          fill: value ? 1 : 0,
        ),
        title: const Text('Répéter chaque mois'),
        subtitle: value
            ? Text(
                'Le ${expenseDate.day} de chaque mois',
                style: tt.bodySmall?.copyWith(color: cs.primary),
              )
            : null,
      ),
    );
  }
}

// ─── Create Category bottom sheet ─────────────────────────────────────────────

class _CreateCategorySheet extends StatefulWidget {
  const _CreateCategorySheet({
    required this.groupId,
    required this.onCreated,
  });

  final String groupId;
  final ValueChanged<Category> onCreated;

  @override
  State<_CreateCategorySheet> createState() => _CreateCategorySheetState();
}

class _CreateCategorySheetState extends State<_CreateCategorySheet> {
  final _nameCtrl = TextEditingController();
  String _selectedIcon = 'category';
  Color _selectedColor = AppColors.categoryPalette[0];
  bool _loading = false;

  static const _icons = [
    'pets', 'school', 'flight', 'hotel', 'fitness_center', 'phone',
    'shopping_bag', 'local_gas_station', 'home', 'shopping_cart',
    'restaurant', 'directions_car', 'sports_esports', 'subscriptions',
    'local_hospital', 'category',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _colorToHex(Color c) =>
      '#${c.r.round().toRadixString(16).padLeft(2, '0')}'
      '${c.g.round().toRadixString(16).padLeft(2, '0')}'
      '${c.b.round().toRadixString(16).padLeft(2, '0')}';

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    final cat = await context.read<AddExpenseCubit>().createCategory(
          groupId: widget.groupId,
          name: name,
          icon: _selectedIcon,
          color: _colorToHex(_selectedColor),
        );
    if (mounted) {
      setState(() => _loading = false);
      if (cat != null) {
        widget.onCreated(cat);
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la création')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text('Nouvelle catégorie', style: tt.headlineSmall),
          const SizedBox(height: 20),

          // Prévisualisation + nom
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _selectedColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _selectedColor, width: 2),
                ),
                child: Icon(
                  Category(
                    id: '', name: '', icon: _selectedIcon,
                    color: '', isDefault: false, sortOrder: 0,
                  ).flutterIcon,
                  color: _selectedColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  autofocus: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Icône
          Text('Icône', style: tt.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _icons.map((icon) {
              final isSelected = icon == _selectedIcon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _selectedColor.withValues(alpha: 0.15)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _selectedColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Category(
                      id: '', name: '', icon: icon,
                      color: '', isDefault: false, sortOrder: 0,
                    ).flutterIcon,
                    size: 22,
                    color: isSelected ? _selectedColor : cs.onSurfaceVariant,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Couleur
          Text('Couleur', style: tt.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: AppColors.categoryPalette.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? cs.onSurface : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Symbols.check_rounded,
                          color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Créer la catégorie'),
          ),
        ],
      ),
    );
  }
}
