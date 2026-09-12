import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/group_detail/cubit/group_detail_cubit.dart';
import '../../../l10n/l10n.dart';
import '../../../features/home/cubit/home_cubit.dart';
import '../../../shared/widgets/expressive/expressive.dart';
import '../../../shared/widgets/tabby_sheet.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/group.dart';
import '../cubit/add_expense_cubit.dart';

/// Ouvre la feuille de création de dépense.
/// [groupId] renseigné → groupe prérempli et verrouillé.
Future<bool?> showAddExpenseSheet(
  BuildContext context, {
  String? groupId,
}) {
  final lock = groupId != null && groupId.isNotEmpty;
  return showTabbySheet<bool>(
    context,
    isScrollControlled: true,
    builder: (_) => BlocProvider(
      create: (_) => AddExpenseCubit()
        ..load(groupId: groupId, lockGroup: lock),
      child: const _AddExpenseSheet(),
    ),
  );
}

// ─── Sheet (stateful: owns all form state) ────────────────────────────────────

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet();

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  Category? _selectedCategory;
  String? _selectedPayerId;
  DateTime _expenseDate = DateTime.now();
  bool _customSplit = false;
  bool _recurring = false;

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

  void _initSplitCtrls(List<GroupMember> members) {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    final n = members.length;
    final perPerson = n > 0 ? (amount / n) : 0.0;

    for (final m in members) {
      if (!_splitCtrls.containsKey(m.user.id)) {
        _splitCtrls[m.user.id] = TextEditingController();
      }
      _splitCtrls[m.user.id]!.text = perPerson.toStringAsFixed(2);
    }
  }

  double get _splitsTotal => _splitCtrls.values.fold(0.0, (acc, ctrl) {
        return acc + (double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0.0);
      });

  double get _expenseAmount =>
      double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0.0;

  bool get _splitsValid => (_expenseAmount - _splitsTotal).abs() < 0.02;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _expenseDate = picked);
  }

  Future<void> _onGroupChanged(String? id) async {
    if (id == null) return;
    setState(() {
      _selectedCategory = null;
      _selectedPayerId = null;
      _customSplit = false;
    });
    await context.read<AddExpenseCubit>().selectGroup(id);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ready = _lastReady;
    if (ready?.group == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.chooseAGroup)),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.chooseACategory)),
      );
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.invalidAmount)),
      );
      return;
    }
    if (_customSplit && !_recurring && !_splitsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.splitsMustMatch)),
      );
      return;
    }

    final payerId =
        _selectedPayerId ?? ready!.group!.members.first.user.id;

    List<Map<String, dynamic>>? splits;
    if (_customSplit) {
      splits = _splitCtrls.entries.map((e) {
        return {
          'user_id': e.key,
          'amount': double.tryParse(e.value.text.replaceAll(',', '.')) ?? 0.0,
        };
      }).toList();
    }

    final name = _nameCtrl.text.trim().isEmpty
        ? _selectedCategory!.name
        : _nameCtrl.text.trim();

    final ok = await context.read<AddExpenseCubit>().submit(
          groupId: ready!.group!.id,
          name: name,
          amount: amount,
          categoryId: _selectedCategory!.id,
          paidBy: payerId,
          expenseDate: _expenseDate,
          customSplits: _recurring ? null : splits,
          recurring: _recurring,
        );

    if (ok && mounted) {
      HomeCubit.refreshIfActive();
      GroupDetailCubit.refreshIfActive();
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;
    final type = context.tabbyType;
    final shapes = context.tabbyShapes;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.92,
        child: BlocConsumer<AddExpenseCubit, AddExpenseState>(
          listener: (context, state) {
            if (state is AddExpenseError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10nError(state.message))),
              );
            }
          },
          builder: (context, state) {
            if (state is AddExpenseInitial || state is AddExpenseLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AddExpenseError && _lastReady == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(context.l10nError(state.message), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: () =>
                            context.read<AddExpenseCubit>().load(),
                        child: Text(context.l10n.retry),
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

            if (_selectedPayerId == null &&
                ready.group != null &&
                ready.group!.members.isNotEmpty) {
              _selectedPayerId = ready.group!.members.first.user.id;
            }

            return Form(
              key: _formKey,
              child: Column(
                children: [
                  ExpressiveSheetHeader(
                    title: context.l10n.newExpense,
                    subtitle: context.l10n.newExpenseSubtitle,
                    onClose: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        ExpressiveTonalCard(
                          variant: ExpressiveTonalVariant.lime,
                          margin: EdgeInsets.zero,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: IntrinsicWidth(
                              child: TextFormField(
                                controller: _amountCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                textAlign: TextAlign.center,
                                style: type.figureHero.copyWith(
                                  color: cs.onTertiaryContainer,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d,.]')),
                                ],
                                onChanged: (_) {
                                  if (_customSplit) setState(() {});
                                },
                                decoration: InputDecoration(
                                  filled: false,
                                  border: InputBorder.none,
                                  hintText: '0,00',
                                  hintStyle: type.figureLarge.copyWith(
                                    color: cs.outline,
                                  ),
                                  suffixText: '€',
                                  suffixStyle: type.figureMedium.copyWith(
                                    color: cs.onTertiaryContainer,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return context.l10n.required;
                                  }
                                  if (double.tryParse(
                                          v.replaceAll(',', '.')) ==
                                      null) {
                                    return context.l10n.invalid;
                                  }
                                  return null;
                                },
                                autofocus: true,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        ExpressiveSheetSection(
                          label: context.l10n.group,
                          child: ready.groups.isEmpty
                              ? Text(
                                  context.l10n.createGroupFirst,
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                )
                              : ready.groupLocked && ready.group != null
                                  ? InputDecorator(
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(
                                          Symbols.lock_rounded,
                                          size: 18,
                                        ),
                                      ),
                                      child: Text(
                                        ready.group!.name,
                                        style: tt.bodyLarge,
                                      ),
                                    )
                                  : DropdownButtonFormField<String>(
                                      key: ValueKey(ready.group?.id),
                                      initialValue: ready.group?.id,
                                      isExpanded: true,
                                      hint: Text(context.l10n.chooseGroup),
                                      items: ready.groups
                                          .map((g) => DropdownMenuItem(
                                                value: g.id,
                                                child: Text(g.name),
                                              ))
                                          .toList(),
                                      onChanged: _onGroupChanged,
                                    ),
                        ),

                        if (ready.group != null) ...[
                          const SizedBox(height: 24),
                          ExpressiveSheetSection(
                            label: context.l10n.category,
                            trailing: TextButton.icon(
                              onPressed: () =>
                                  _showCreateCategorySheet(context, ready),
                              icon: const Icon(Symbols.add_rounded, size: 16),
                              label: Text(context.l10n.newFeminine),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            child: _CategoryGrid(
                              categories: ready.categories,
                              selected: _selectedCategory,
                              onSelect: (c) =>
                                  setState(() => _selectedCategory = c),
                            ),
                          ),

                          const SizedBox(height: 24),
                          ExpressiveSheetSection(
                            label: context.l10n.description,
                            child: TextFormField(
                              controller: _nameCtrl,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                hintText: context.l10n.optional,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          ExpressiveSheetSection(
                            label: context.l10n.paidBy,
                            child: _PayerDropdown(
                              members: ready.group!.members,
                              selectedId: _selectedPayerId,
                              onChanged: (id) =>
                                  setState(() => _selectedPayerId = id),
                            ),
                          ),

                          const SizedBox(height: 24),
                          ExpressiveSheetSection(
                            label: context.l10n.date,
                            child: InkWell(
                              onTap: _pickDate,
                              borderRadius: shapes.radiusLarge,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(
                                    Symbols.calendar_month_rounded,
                                    size: 18,
                                  ),
                                ),
                                child: Text(
                                  '${_expenseDate.day.toString().padLeft(2, '0')}/${_expenseDate.month.toString().padLeft(2, '0')}/${_expenseDate.year}',
                                  style: tt.bodyMedium,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          ExpressiveSheetSection(
                            label: context.l10n.split,
                            child: AbsorbPointer(
                              absorbing: _recurring,
                              child: Opacity(
                                opacity: _recurring ? 0.45 : 1,
                                child: ExpressiveButtonGroup<bool>(
                                  value: _customSplit,
                                  onChanged: (v) {
                                    setState(() {
                                      _customSplit = v;
                                      if (_customSplit) {
                                        _initSplitCtrls(ready.group!.members);
                                      }
                                    });
                                  },
                                  segments: [
                                    ExpressiveButtonGroupSegment(
                                      value: false,
                                      label: context.l10n.splitEqual,
                                    ),
                                    ExpressiveButtonGroupSegment(
                                      value: true,
                                      label: context.l10n.splitCustom,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_customSplit) ...[
                            const SizedBox(height: 12),
                            _CustomSplitSection(
                              members: ready.group!.members,
                              splitCtrls: _splitCtrls,
                              total: _expenseAmount,
                              splitsTotal: _splitsTotal,
                              isValid: _splitsValid,
                              onChanged: () => setState(() {}),
                            ),
                          ],

                          // 8. Récurrence
                          const SizedBox(height: 16),
                          _RecurringTile(
                            value: _recurring,
                            expenseDate: _expenseDate,
                            onChanged: (v) => setState(() {
                              _recurring = v;
                              if (v) _customSplit = false;
                            }),
                          ),
                        ],

                        const SizedBox(height: 28),
                        ExpressiveSheetSubmit(
                          label: _recurring
                              ? context.l10n.scheduleRecurrence
                              : context.l10n.save,
                          loading: submitting,
                          onPressed: ready.group == null ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showCreateCategorySheet(
    BuildContext context,
    AddExpenseReady ready,
  ) {
    final groupId = ready.group?.id;
    if (groupId == null) return;
    showTabbySheet(
      context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<AddExpenseCubit>(),
        child: _CreateCategorySheet(
          groupId: groupId,
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

    return ExpressiveTonalCard(
      variant: ExpressiveTonalVariant.neutral,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...members.map((m) {
              final ctrl = splitCtrls[m.user.id]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    ExpressiveAvatar(
                      label: m.user.name,
                      size: 32,
                      color: cs.primaryContainer,
                      textColor: cs.onPrimaryContainer,
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
                            borderRadius: context.tabbyShapes.radiusMedium,
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: context.tabbyShapes.radiusMedium,
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: context.tabbyShapes.radiusMedium,
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
              Text(context.l10n.splitTotal, style: tt.bodySmall),
              Row(
                children: [
                  if (!isValid)
                    Text(
                      diff < 0.01
                          ? '≈ ok'
                          : '${diff > 0 ? '-' : '+'}${diff.toStringAsFixed(2)} €',
                      style: tt.bodySmall?.copyWith(
                        color: context.tabbySemantic.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '${splitsTotal.toStringAsFixed(2)} / ${total.toStringAsFixed(2)} €',
                    style: tt.bodyMedium?.copyWith(
                      color: isValid
                          ? context.tabbySemantic.success
                          : context.tabbySemantic.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
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
    final cs = context.tabbyColors;
    final semantic = context.tabbySemantic;
    final shapes = context.tabbyShapes;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((c) {
        final isSelected = selected?.id == c.id;
        final catColor = semantic.chartColorFor(c);
        final onCat = semantic.onFor(catColor, cs);
        return GestureDetector(
          onTap: () => onSelect(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? catColor : cs.surfaceContainerLow,
              borderRadius: shapes.radiusLarge,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                c.iconWidget(
                  size: 18,
                  color: isSelected ? onCat : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  c.name,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isSelected ? onCat : cs.onSurfaceVariant,
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
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;
    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      isExpanded: true,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: shapes.radiusLarge,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: shapes.radiusLarge,
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
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;
    final shapes = context.tabbyShapes;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: value ? cs.primaryContainer : cs.surfaceContainerLow,
        borderRadius: shapes.radiusLarge,
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: shapes.radiusLarge),
        secondary: Icon(
          Symbols.repeat_rounded,
          color: value ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          fill: value ? 1 : 0,
        ),
        title: Text(context.l10n.repeatMonthly),
        subtitle: value
            ? Text(
                context.l10n.repeatOnDay(expenseDate.day),
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
  late Color _selectedColor;
  bool _loading = false;
  bool _colorInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_colorInitialized) {
      _selectedColor = context.tabbySemantic.categoryPalette.first;
      _colorInitialized = true;
    }
  }

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
          SnackBar(content: Text(context.l10n.errorCreate)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final semantic = context.tabbySemantic;
    final shapes = context.tabbyShapes;
    final palette = semantic.categoryPalette;
    final onSelected = semantic.onFor(_selectedColor, cs);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExpressiveSheetHeader(
            title: context.l10n.newCategory,
            subtitle: context.l10n.newCategorySubtitle,
            onClose: () => Navigator.of(context).pop(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  borderRadius: shapes.radiusLarge,
                ),
                child: Center(
                  child: Icon(
                    CategoryIcons.resolve(_selectedIcon),
                    size: 26,
                    color: onSelected,
                    fill: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: context.l10n.name),
                  autofocus: true,
                ),
              ),
            ],
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ExpressiveSheetSection(
              label: context.l10n.icon,
              child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: CategoryIcons.all.map((entry) {
              final id = entry.$1;
              final icon = entry.$2;
              final isSelected = id == _selectedIcon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _selectedColor
                        : cs.surfaceContainerLow,
                    borderRadius: shapes.radiusMedium,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isSelected ? onSelected : cs.onSurfaceVariant,
                    fill: isSelected ? 1 : 0,
                  ),
                ),
              );
            }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ExpressiveSheetSection(
              label: context.l10n.color,
              child: Wrap(
                spacing: 10,
                children: palette.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Material(
                      color: color,
                      shape: shapes.circle(),
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: isSelected
                            ? Icon(Symbols.check_rounded,
                                color: semantic.onFor(color, cs), size: 18)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: ExpressiveSheetSubmit(
              label: context.l10n.createCategory,
              loading: _loading,
              onPressed: _submit,
            ),
          ),
        ],
        ),
      ),
    );
  }
}
