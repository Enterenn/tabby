import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/expressive_shapes.dart';
import '../../../l10n/l10n.dart';
import '../../../features/home/cubit/home_cubit.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/group.dart';
import '../cubit/add_expense_cubit.dart';

part 'add_expense_widgets.dart';

/// Ouvre la feuille de création de dépense.
/// [groupId] renseigné → groupe prérempli et verrouillé.
Future<bool?> showAddExpenseSheet(
  BuildContext context, {
  String? groupId,
}) {
  final lock = groupId != null && groupId.isNotEmpty;
  final home = context.read<HomeCubit>();
  return showTabbySheet<bool>(
    context,
    isScrollControlled: true,
    builder: (_) => BlocProvider(
      create: (_) => AddExpenseCubit()
        ..load(groupId: groupId, lockGroup: lock),
      child: _AddExpenseSheet(onCreated: home.loadGroups),
    ),
  );
}

// ─── Sheet (stateful: owns all form state) ────────────────────────────────────

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet({required this.onCreated});

  final VoidCallback onCreated;

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
      showTabbySnack(context, context.l10n.chooseAGroup);
      return;
    }
    if (_selectedCategory == null) {
      showTabbySnack(context, context.l10n.chooseACategory);
      return;
    }
    final amount = TabbyAmountField.parse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      showTabbySnack(context, context.l10n.invalidAmount);
      return;
    }
    if (_customSplit && !_recurring && !_splitsValid) {
      showTabbySnack(context, context.l10n.splitsMustMatch);
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

    final name = _nameCtrl.text.trim();

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
      widget.onCreated();
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
              showTabbySnack(context, context.l10nError(state.message));
            }
          },
          builder: (context, state) {
            if (state is AddExpenseInitial || state is AddExpenseLoading) {
              return const TabbyLoading();
            }
            if (state is AddExpenseError && _lastReady == null) {
              return TabbyErrorState(
                message: context.l10nError(state.message),
                retryLabel: context.l10n.retry,
                onRetry: () => context.read<AddExpenseCubit>().load(),
              );
            }

            final AddExpenseReady ready;
            final bool submitting;
            if (state is AddExpenseReady) {
              ready = state;
              _lastReady = state;
              submitting = false;
            } else if (state is AddExpenseSubmitting) {
              ready = _lastReady!;
              submitting = true;
            } else {
              ready = _lastReady!;
              submitting = false;
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
                          padding: const EdgeInsets.symmetric(
                            vertical: 28,
                            horizontal: 24,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 96),
                                  child: IntrinsicWidth(
                                    child: TextFormField(
                                      controller: _amountCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      textAlign: TextAlign.end,
                                      autofocus: true,
                                      cursorColor: cs.onTertiaryContainer,
                                      style: type.figureHero.copyWith(
                                        color: cs.onTertiaryContainer,
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[\d,.]'),
                                        ),
                                      ],
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        filled: false,
                                        isCollapsed: true,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        focusedErrorBorder: InputBorder.none,
                                        hintText: '0,00',
                                        hintStyle: type.figureHero.copyWith(
                                          color: cs.onTertiaryContainer
                                              .withValues(alpha: 0.34),
                                        ),
                                        errorStyle: const TextStyle(
                                          fontSize: 0,
                                          height: 0,
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return context.l10n.required;
                                        }
                                        if (double.tryParse(
                                              v.replaceAll(',', '.'),
                                            ) ==
                                            null) {
                                          return context.l10n.invalid;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                Text(
                                  ' €',
                                  style: type.figureMedium.copyWith(
                                    color: cs.onTertiaryContainer.withValues(
                                      alpha:
                                          _amountCtrl.text.isEmpty ? 0.34 : 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        ExpressiveSheetSection(
                          label: context.l10n.name,
                          child: TextFormField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: context.l10n.expenseNameHint,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return context.l10n.requiredField;
                              }
                              return null;
                            },
                          ),
                        ),

                        if (ready.group != null) ...[
                          const SizedBox(height: 24),
                          ExpressiveSheetSection(
                            label: context.l10n.category,
                            child: _CategoryRail(
                              categories: ready.categories,
                              selected: _selectedCategory,
                              onSelect: (c) =>
                                  setState(() => _selectedCategory = c),
                              onCreate: () =>
                                  _showCreateCategorySheet(context, ready),
                            ),
                          ),
                        ],

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
