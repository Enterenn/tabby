import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/api/token_storage.dart';
import '../../../core/format/split_shares.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/expressive_shapes.dart';
import '../../../l10n/l10n.dart';
import '../../../features/home/cubit/home_cubit.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/expense.dart';
import '../../../shared/models/group.dart';
import '../../../shared/widgets/category_editor_sheet.dart';
import '../cubit/add_expense_cubit.dart';

part 'add_expense_widgets.dart';

/// Ouvre la feuille de création (ou d'édition) de dépense.
/// [groupId] renseigné → groupe prérempli et verrouillé.
/// [editing] renseigné → même feuille, déjà remplie.
Future<bool?> showAddExpenseSheet(
  BuildContext context, {
  String? groupId,
  bool forMe = false,
  Expense? editing,
}) {
  final lock = (groupId != null && groupId.isNotEmpty) || editing != null;
  final home = context.read<HomeCubit>();
  return showTabbySheet<bool>(
    context,
    isScrollControlled: true,
    builder: (_) => BlocProvider(
      create: (_) => AddExpenseCubit()
        ..load(groupId: groupId, lockGroup: lock),
      child: _AddExpenseSheet(
        onCreated: home.loadGroups,
        initialForMe: forMe,
        editing: editing,
        groupId: groupId,
      ),
    ),
  );
}

// ─── Sheet (stateful: owns all form state) ────────────────────────────────────

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet({
    required this.onCreated,
    this.initialForMe = false,
    this.editing,
    this.groupId,
  });

  final VoidCallback onCreated;
  final bool initialForMe;
  final Expense? editing;
  final String? groupId;

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
  ExpenseSplitMode _splitMode = ExpenseSplitMode.equal;
  bool _recurring = false;
  late bool _forMe = widget.initialForMe;

  final Map<String, TextEditingController> _splitCtrls = {};
  final Map<String, int> _shareCounts = {};
  final Set<String> _includedIds = {};
  String? _splitGroupId;

  AddExpenseReady? _lastReady;
  bool _didPrefillSplitAmounts = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing == null) return;
    _nameCtrl.text = editing.name;
    _amountCtrl.text = editing.amount.toStringAsFixed(2);
    _selectedCategory = editing.category;
    _selectedPayerId = editing.paidBy;
    _expenseDate = editing.expenseDate;
    _forMe = false;
    _recurring = false;
    _splitMode = _looksEqualSplit(editing)
        ? ExpenseSplitMode.equal
        : ExpenseSplitMode.amounts;
    _splitGroupId = widget.groupId;
    for (final split in editing.splits) {
      if (split.amount > 0.005) {
        _includedIds.add(split.userId);
        _shareCounts[split.userId] = 1;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    for (final c in _splitCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncSplitMembers(List<GroupMember> members, String groupId) {
    if (_splitGroupId != groupId) {
      _splitGroupId = groupId;
      _includedIds
        ..clear()
        ..addAll(members.map((m) => m.user.id));
    }
    for (final m in members) {
      _splitCtrls.putIfAbsent(m.user.id, () => TextEditingController());
      _shareCounts.putIfAbsent(
        m.user.id,
        () => _includedIds.contains(m.user.id) ? 1 : 0,
      );
    }
    final editing = widget.editing;
    if (editing != null && !_didPrefillSplitAmounts) {
      _didPrefillSplitAmounts = true;
      final splitByUser = {for (final s in editing.splits) s.userId: s.amount};
      for (final m in members) {
        final amount = splitByUser[m.user.id] ?? 0;
        _splitCtrls[m.user.id]?.text = amount.toStringAsFixed(2);
        if (amount > 0.005) {
          _includedIds.add(m.user.id);
          if ((_shareCounts[m.user.id] ?? 0) <= 0) _shareCounts[m.user.id] = 1;
        } else {
          _includedIds.remove(m.user.id);
          _shareCounts[m.user.id] = 0;
        }
      }
    }
  }

  void _fillEqualAmounts(List<GroupMember> members) {
    final amounts = _previewAmounts(members);
    for (final m in members) {
      final ctrl = _splitCtrls.putIfAbsent(
        m.user.id,
        () => TextEditingController(),
      );
      ctrl.text = (amounts[m.user.id] ?? 0).toStringAsFixed(2);
    }
  }

  void _setIncluded(String userId, bool included) {
    if (included) {
      _includedIds.add(userId);
      if ((_shareCounts[userId] ?? 0) <= 0) _shareCounts[userId] = 1;
    } else {
      _includedIds.remove(userId);
      _shareCounts[userId] = 0;
      _splitCtrls[userId]?.text = '0.00';
    }
  }

  void _selectAll(List<GroupMember> members, {required bool included}) {
    for (final m in members) {
      _setIncluded(m.user.id, included);
    }
    if (_splitMode == ExpenseSplitMode.amounts) {
      if (included) {
        _fillEqualAmounts(members);
      } else {
        for (final m in members) {
          _splitCtrls[m.user.id]?.text = '0.00';
        }
      }
    }
  }

  Map<String, double> _previewAmounts(List<GroupMember> members) {
    if (_splitMode == ExpenseSplitMode.amounts) {
      return {
        for (final m in members)
          m.user.id: double.tryParse(
                _splitCtrls[m.user.id]?.text.replaceAll(',', '.') ?? '',
              ) ??
              0,
      };
    }
    return amountsFromShares(
      total: _expenseAmount,
      userIds: members.map((m) => m.user.id).toList(),
      shares: {
        for (final m in members)
          m.user.id: _splitMode == ExpenseSplitMode.shares
              ? (_shareCounts[m.user.id] ?? 0)
              : (_includedIds.contains(m.user.id) ? 1 : 0),
      },
    );
  }

  int get _shareSum => _shareCounts.values.fold(0, (sum, n) => sum + n);

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

  String? _defaultPayerId(List<GroupMember> members) {
    final me = tokenStorage.userId;
    if (me != null && members.any((m) => m.user.id == me)) return me;
    return members.isNotEmpty ? members.first.user.id : null;
  }

  Future<void> _onGroupChanged(String? id) async {
    if (id == null) return;
    setState(() {
      _selectedCategory = null;
      _selectedPayerId = null;
      _splitMode = ExpenseSplitMode.equal;
      _splitGroupId = null;
    });
    await context.read<AddExpenseCubit>().selectGroup(id);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ready = _lastReady;
    if (!_forMe && ready?.group == null) {
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
    if (!_forMe &&
        !_recurring &&
        _includedIds.isEmpty) {
      showTabbySnack(context, context.l10n.splitNeedSomeone);
      return;
    }
    if (_splitMode == ExpenseSplitMode.amounts &&
        !_recurring &&
        !_splitsValid) {
      showTabbySnack(context, context.l10n.splitsMustMatch);
      return;
    }
    if (_splitMode == ExpenseSplitMode.shares &&
        !_recurring &&
        _shareSum <= 0) {
      showTabbySnack(context, context.l10n.splitsMustMatch);
      return;
    }

    final name = _nameCtrl.text.trim();
    final bool ok;
    if (_forMe) {
      ok = await context.read<AddExpenseCubit>().submitPersonal(
            name: name,
            amount: amount,
            categoryId: _selectedCategory!.id,
            expenseDate: _expenseDate,
            recurring: _recurring,
          );
    } else {
      final payerId = _selectedPayerId ??
          _defaultPayerId(ready!.group!.members);
      if (payerId == null) {
        showTabbySnack(context, context.l10n.chooseAGroup);
        return;
      }

      List<Map<String, dynamic>>? splits;
      if (!_recurring) {
        final amounts = _previewAmounts(ready!.group!.members);
        splits = amounts.entries
            .where((e) => e.value > 0)
            .map((e) => {'user_id': e.key, 'amount': e.value})
            .toList();
      }

      final editing = widget.editing;
      if (editing != null) {
        ok = await context.read<AddExpenseCubit>().update(
              groupId: ready!.group!.id,
              expenseId: editing.id,
              name: name,
              amount: amount,
              categoryId: _selectedCategory!.id,
              paidBy: payerId,
              expenseDate: _expenseDate,
              customSplits: splits,
            );
      } else {
        ok = await context.read<AddExpenseCubit>().submit(
              groupId: ready!.group!.id,
              name: name,
              amount: amount,
              categoryId: _selectedCategory!.id,
              paidBy: payerId,
              expenseDate: _expenseDate,
              customSplits: _recurring ? null : splits,
              recurring: _recurring,
            );
      }
    }

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
              _selectedPayerId = _defaultPayerId(ready.group!.members);
            }
            if (_selectedCategory != null) {
              for (final category in ready.categories) {
                if (category.id == _selectedCategory!.id) {
                  _selectedCategory = category;
                  break;
                }
              }
            }
            if (ready.group != null) {
              _syncSplitMembers(ready.group!.members, ready.group!.id);
            }

            return Form(
              key: _formKey,
              child: Column(
                children: [
                  ExpressiveSheetHeader(
                    title: _isEditing
                        ? context.l10n.editExpense
                        : context.l10n.newExpense,
                    subtitle: _isEditing
                        ? context.l10n.editExpenseSubtitle
                        : context.l10n.newExpenseSubtitle,
                    onClose: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        if (!ready.groupLocked &&
                            !widget.initialForMe &&
                            !_isEditing) ...[
                          ExpressiveButtonGroup<bool>(
                            value: _forMe,
                            onChanged: (v) => setState(() => _forMe = v),
                            segments: [
                              ExpressiveButtonGroupSegment(
                                value: false,
                                label: context.l10n.expenseShared,
                              ),
                              ExpressiveButtonGroupSegment(
                                value: true,
                                label: context.l10n.expenseForMe,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
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
                                      autofocus: !_isEditing,
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

                        if (ready.categories.isNotEmpty) ...[
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

                        if (!_forMe) ...[
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
                                  : ExpressiveDropdown<String>(
                                      selected: ready.group?.id,
                                      hintText: context.l10n.chooseGroup,
                                      leadingIcon: Icon(
                                        Symbols.group_rounded,
                                        size: 20,
                                        color: cs.onSurfaceVariant,
                                      ),
                                      entries: [
                                        for (final g in ready.groups)
                                          ExpressiveDropdownEntry(
                                            value: g.id,
                                            label: g.name,
                                          ),
                                      ],
                                      onSelected: _onGroupChanged,
                                    ),
                          ),

                          if (ready.group != null) ...[
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ExpressiveSheetSection(
                                    label: context.l10n.paidBy,
                                    child: _PayerDropdown(
                                      members: ready.group!.members,
                                      selectedId: _selectedPayerId,
                                      onChanged: (id) => setState(
                                        () => _selectedPayerId = id,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ExpressiveSheetSection(
                                    label: context.l10n.date,
                                    child: _DateField(
                                      date: _expenseDate,
                                      onTap: _pickDate,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 24),
                          AbsorbPointer(
                            absorbing: _recurring,
                            child: Opacity(
                              opacity: _recurring ? 0.45 : 1,
                              child: _SplitParticipants(
                                mode: _splitMode,
                                members: ready.group!.members,
                                includedIds: _includedIds,
                                amounts: _previewAmounts(ready.group!.members),
                                shares: _shareCounts,
                                splitCtrls: _splitCtrls,
                                total: _expenseAmount,
                                splitsTotal: _splitsTotal,
                                isValid: _splitsValid,
                                onToggle: (id) => setState(() {
                                  _setIncluded(
                                    id,
                                    !_includedIds.contains(id),
                                  );
                                }),
                                onSelectAll: () => setState(
                                  () => _selectAll(
                                    ready.group!.members,
                                    included: true,
                                  ),
                                ),
                                onSelectNone: () => setState(
                                  () => _selectAll(
                                    ready.group!.members,
                                    included: false,
                                  ),
                                ),
                                onModeChanged: (v) => setState(() {
                                  _splitMode = v;
                                  if (v == ExpenseSplitMode.amounts) {
                                    _fillEqualAmounts(ready.group!.members);
                                  }
                                }),
                                onShareChanged: (userId, value) {
                                  setState(() {
                                    _shareCounts[userId] = value;
                                    if (value <= 0) {
                                      _includedIds.remove(userId);
                                    } else {
                                      _includedIds.add(userId);
                                    }
                                  });
                                },
                                onAmountChanged: () => setState(() {}),
                              ),
                            ),
                          ),

                          if (!_isEditing) ...[
                            const SizedBox(height: 16),
                            _RecurringTile(
                              value: _recurring,
                              expenseDate: _expenseDate,
                              onChanged: (v) => setState(() {
                                _recurring = v;
                                if (v) {
                                  _splitMode = ExpenseSplitMode.equal;
                                  _includedIds.addAll(
                                    ready.group!.members.map((m) => m.user.id),
                                  );
                                }
                              }),
                            ),
                          ],
                          ],
                        ],
                        if (_forMe) ...[
                          const SizedBox(height: 24),
                          ExpressiveSheetSection(
                            label: context.l10n.date,
                            child: _DateField(
                              date: _expenseDate,
                              onTap: _pickDate,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _RecurringTile(
                            value: _recurring,
                            expenseDate: _expenseDate,
                            onChanged: (v) => setState(() => _recurring = v),
                          ),
                        ],

                        const SizedBox(height: 28),
                        ExpressiveSheetSubmit(
                          label: _recurring
                              ? context.l10n.scheduleRecurrence
                              : context.l10n.save,
                          loading: submitting,
                          onPressed: (!_forMe && ready.group == null)
                              ? null
                              : _submit,
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
    showCategoryEditorSheet(
      context: context,
      onSubmit: ({
        required name,
        required icon,
        required color,
      }) async {
        final cat = await context.read<AddExpenseCubit>().createCategory(
              name: name,
              icon: icon,
              color: color,
            );
        if (cat != null) setState(() => _selectedCategory = cat);
        return cat;
      },
    );
  }
}

bool _looksEqualSplit(Expense expense) {
  final active = [
    for (final split in expense.splits)
      if (split.amount > 0.005) split.amount,
  ];
  if (active.length <= 1) return true;
  var minAmount = active.first;
  var maxAmount = active.first;
  for (final amount in active) {
    if (amount < minAmount) minAmount = amount;
    if (amount > maxAmount) maxAmount = amount;
  }
  return maxAmount - minAmount <= 0.02;
}
