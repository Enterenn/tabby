part of 'add_expense_screen.dart';

// ─── Sheet (stateful: owns all form state) ────────────────────────────────────

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet({
    required this.onCreated,
    this.initialForMe = false,
    this.editing,
    this.editingPersonal,
    this.groupId,
  });

  final VoidCallback onCreated;
  final bool initialForMe;
  final Expense? editing;
  final PersonalExpense? editingPersonal;
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
  bool _submitted = false;
  String? _draftCategoryId;

  bool get _isEditing =>
      widget.editing != null || widget.editingPersonal != null;

  @override
  void initState() {
    super.initState();
    final draft = _isEditing ? null : addExpenseDraftStore.take();
    if (draft != null) {
      _nameCtrl.text = draft.name;
      _amountCtrl.text = draft.amount;
      _selectedPayerId = draft.payerId;
      _expenseDate = draft.expenseDate;
      _draftCategoryId = draft.categoryId;
    }
    final personal = widget.editingPersonal;
    if (personal != null) {
      _nameCtrl.text = personal.name;
      _amountCtrl.text = personal.amount.toStringAsFixed(2);
      _selectedCategory = personal.category;
      _expenseDate = personal.expenseDate;
      _forMe = true;
      _recurring = false;
      return;
    }
    final editing = widget.editing;
    if (editing == null) return;
    _nameCtrl.text = editing.name;
    _amountCtrl.text = editing.amount.toStringAsFixed(2);
    _selectedCategory = editing.category;
    _selectedPayerId = editing.paidBy;
    _expenseDate = editing.expenseDate;
    _forMe = false;
    _recurring = false;
    _splitMode = looksLikeEqualSplit(editing)
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

  void _saveDraft() {
    if (_submitted ||
        _isEditing ||
        (_nameCtrl.text.trim().isEmpty && _amountCtrl.text.trim().isEmpty)) {
      return;
    }
    addExpenseDraftStore.save(
      AddExpenseDraft(
        name: _nameCtrl.text,
        amount: _amountCtrl.text,
        categoryId: _selectedCategory?.id,
        payerId: _selectedPayerId,
        expenseDate: _expenseDate,
      ),
    );
  }

  @override
  void dispose() {
    _saveDraft();
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

  void _synchronizeReadyState(AddExpenseReady ready) {
    _lastReady = ready;

    final group = ready.group;
    if (group != null) {
      _selectedPayerId = resolveExpensePayer(
        selectedId: _selectedPayerId,
        members: group.members,
        currentUserId: tokenStorage.userId,
      );
      _syncSplitMembers(group.members, group.id);
    }

    final category = resolveExpenseCategory(
      selected: _selectedCategory,
      draftCategoryId: _draftCategoryId,
      available: ready.categories,
    );
    if (category != null) {
      _selectedCategory = category;
      if (_draftCategoryId == category.id) _draftCategoryId = null;
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
          m.user.id:
              double.tryParse(
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

  void _hideKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
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
    if (!_forMe && !_recurring && _includedIds.isEmpty) {
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
    final cubit = context.read<AddExpenseCubit>();
    final bool ok;
    final editingPersonal = widget.editingPersonal;
    if (editingPersonal != null) {
      ok = await cubit.updatePersonal(
        expenseId: editingPersonal.id,
        name: name,
        amount: amount,
        categoryId: _selectedCategory!.id,
        expenseDate: _expenseDate,
      );
    } else if (_forMe) {
      ok = await cubit.submitPersonal(
        name: name,
        amount: amount,
        categoryId: _selectedCategory!.id,
        expenseDate: _expenseDate,
        recurring: _recurring,
      );
    } else {
      final payerId = resolveExpensePayer(
        selectedId: _selectedPayerId,
        members: ready!.group!.members,
        currentUserId: tokenStorage.userId,
      );
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
        ok = await cubit.update(
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
        ok = await cubit.submit(
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
      _submitted = true;
      addExpenseDraftStore.clear();
      widget.onCreated();
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.92,
        child: BlocConsumer<AddExpenseCubit, AddExpenseState>(
          listener: (context, state) {
            if (state is AddExpenseReady) {
              _synchronizeReadyState(state);
            }
            if (state is AddExpenseError && _lastReady != null) {
              showTabbySnack(context, context.l10nError(state.message));
            }
          },
          builder: (context, state) {
            if (state is AddExpenseInitial || state is AddExpenseLoading) {
              return const TabbyLoading();
            }
            if (state is AddExpenseError && _lastReady == null) {
              void retry() => context.read<AddExpenseCubit>().load();
              return state.message == 'errorNetwork'
                  ? TabbyOfflineState(
                      message: context.l10n.offlineRetry,
                      retryLabel: context.l10n.retry,
                      onRetry: retry,
                    )
                  : TabbyErrorState(
                      message: context.l10nError(state.message),
                      retryLabel: context.l10n.retry,
                      onRetry: retry,
                    );
            }

            final AddExpenseReady ready;
            final bool submitting;
            if (state is AddExpenseReady) {
              ready = state;
              submitting = false;
            } else if (state is AddExpenseSubmitting) {
              ready = _lastReady!;
              submitting = true;
            } else {
              ready = _lastReady!;
              submitting = false;
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
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        if (!ready.groupLocked &&
                            !widget.initialForMe &&
                            !_isEditing) ...[
                          _ExpenseKindSelector(
                            forMe: _forMe,
                            onChanged: (value) =>
                                setState(() => _forMe = value),
                          ),
                          const SizedBox(height: 24),
                        ],
                        _ExpenseAmountCard(controller: _amountCtrl),

                        const SizedBox(height: 24),
                        ExpressiveSheetSection(
                          label: context.l10n.name,
                          child: TextFormField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.next,
                            onTapOutside: (_) => _hideKeyboard(),
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
                          _ExpenseGroupField(
                            ready: ready,
                            onSelected: _onGroupChanged,
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
                                      onChanged: (id) =>
                                          setState(() => _selectedPayerId = id),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ExpressiveSheetSection(
                                    label: context.l10n.date,
                                    child: TabbyDateField.sheet(
                                      value: _expenseDate,
                                      onChanged: (d) =>
                                          setState(() => _expenseDate = d),
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
                                child: AnimatedBuilder(
                                  animation: Listenable.merge([
                                    _amountCtrl,
                                    ..._splitCtrls.values,
                                  ]),
                                  builder: (context, _) => _SplitParticipants(
                                    mode: _splitMode,
                                    members: ready.group!.members,
                                    includedIds: _includedIds,
                                    amounts: _previewAmounts(
                                      ready.group!.members,
                                    ),
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
                                    onModeChanged: (value) => setState(() {
                                      _splitMode = value;
                                      if (value == ExpenseSplitMode.amounts) {
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
                                  ),
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
                                      ready.group!.members.map(
                                        (m) => m.user.id,
                                      ),
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
                            child: TabbyDateField.sheet(
                              value: _expenseDate,
                              onChanged: (d) =>
                                  setState(() => _expenseDate = d),
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

  void _showCreateCategorySheet(BuildContext context, AddExpenseReady ready) {
    showCategoryEditorSheet(
      context: context,
      onSubmit: ({required name, required icon, required color}) async {
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
