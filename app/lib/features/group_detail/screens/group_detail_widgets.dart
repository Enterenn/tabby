part of 'group_detail_screen.dart';
// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}

// ─── Balance tile ─────────────────────────────────────────────────────────────

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({required this.entry, required this.currentUserId});
  final BalanceEntry entry;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isMine =
        entry.fromUserId == currentUserId || entry.toUserId == currentUserId;

    return TabbyListCard(
      color: isMine ? cs.primaryContainer : cs.surfaceContainerLow,
      padding: const EdgeInsets.all(16),
      child: Row(
          children: [
            ExpressiveAvatar(label: entry.fromUserName, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                      children: [
                        TextSpan(
                          text: entry.fromUserName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: context.l10n.owesTo),
                        TextSpan(
                          text: entry.toUserName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ExpressiveFigure(
                    value: entry.amount.toStringAsFixed(2),
                    suffix: ' €',
                    size: ExpressiveFigureSize.small,
                    color: cs.primary,
                  ),
                ],
              ),
            ),
            if (isMine)
              FilledButton.tonal(
                onPressed: () => _confirmSettle(context),
                child: Text(context.l10n.settle),
              ),
          ],
        ),
    );
  }

  Future<void> _confirmSettle(BuildContext context) async {
    final ok = await showTabbyConfirm(
      context,
      title: context.l10n.confirmSettle,
      body: context.l10n.settleBody(
        entry.fromUserName,
        entry.amount.toStringAsFixed(2),
        entry.toUserName,
      ),
      cancelLabel: context.l10n.cancel,
      confirmLabel: context.l10n.confirm,
    );
    if (!ok || !context.mounted) return;
    final err = await context.read<GroupDetailCubit>().settle(
          fromUserId: entry.fromUserId,
          toUserId: entry.toUserId,
          amount: entry.amount,
        );
    if (!context.mounted) return;
    showTabbySnack(
      context,
      err != null ? context.l10nError(err) : context.l10n.settleSaved,
    );
  }
}

// ─── Member tile ─────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    super.key,
    required this.member,
    required this.balances,
    required this.currentUserId,
  });
  final GroupMember member;
  final List<BalanceEntry> balances;
  final String currentUserId;

  double get _memberBalance {
    double b = 0;
    for (final e in balances) {
      if (e.toUserId == member.user.id) b += e.amount;
      if (e.fromUserId == member.user.id) b -= e.amount;
    }
    return b;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final balance = _memberBalance;
    final isMe = member.user.id == currentUserId;

    final semantic = context.tabbySemantic;
    Color balColor;
    String balLabel;
    if (balance > 0.01) {
      balColor = semantic.success;
      balLabel = '+${balance.toStringAsFixed(2)} €';
    } else if (balance < -0.01) {
      balColor = semantic.danger;
      balLabel = '${balance.toStringAsFixed(2)} €';
    } else {
      balColor = cs.onSurfaceVariant;
      balLabel = context.l10n.settled;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ExpressiveAvatar(
            label: member.user.name,
            size: 40,
            imageUrl: resolveMediaUrl(member.user.avatarUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      member.user.name,
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    if (isMe)
                      ExpressiveBadge(
                        label: context.l10n.me,
                        color: cs.primaryContainer,
                        textColor: cs.onPrimaryContainer,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        labelStyle: tt.labelSmall?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.joinedOn(
                    DateFormat(
                      'd MMM yyyy',
                      Localizations.localeOf(context).toString(),
                    ).format(member.joinedAt),
                  ),
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            balLabel,
            style: tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: balColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Group sheet (dépenses + membres) ─────────────────────────────────────────

class _GroupDetailSheet extends StatelessWidget {
  const _GroupDetailSheet({
    required this.group,
    required this.expenses,
    required this.balances,
    required this.currentUserId,
  });

  final Group group;
  final List<Expense> expenses;
  final List<BalanceEntry> balances;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: cs.surfaceContainerLowest,
        elevation: 0,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(shapes.cornerExtraLarge),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GroupedSection(
              title: expenses.isEmpty
                  ? context.l10n.expenses
                  : context.l10n.expensesCount(expenses.length),
              emptyMessage: expenses.isEmpty
                  ? context.l10n.noExpensesInGroup
                  : null,
              itemCount: expenses.length,
              itemBuilder: (i) => _ExpenseTile(
                key: ValueKey(expenses[i].id),
                expense: expenses[i],
                currentUserId: currentUserId,
                ownerId: group.ownerId,
              ),
            ),
            _GroupedSection(
              title: context.l10n.membersCount(group.members.length),
              topPadding: 8,
              itemCount: group.members.length,
              itemBuilder: (i) => _MemberTile(
                key: ValueKey(group.members[i].user.id),
                member: group.members[i],
                balances: balances,
                currentUserId: currentUserId,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _GroupedSection extends StatelessWidget {
  const _GroupedSection({
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    this.emptyMessage,
    this.topPadding = 0,
  });

  final String title;
  final int itemCount;
  final Widget Function(int index) itemBuilder;
  final String? emptyMessage;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
            child: Text(
              title,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (emptyMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                emptyMessage!,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            )
          else if (itemCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Material(
                color: cs.surfaceContainerLow,
                borderRadius: shapes.radiusLarge,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < itemCount; i++) ...[
                      itemBuilder(i),
                      if (i < itemCount - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: cs.surfaceContainerLowest,
                        ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Expense row ──────────────────────────────────────────────────────────────

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    super.key,
    required this.expense,
    required this.currentUserId,
    required this.ownerId,
  });

  final Expense expense;
  final String currentUserId;
  final String? ownerId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final semantic = context.tabbySemantic;
    final catColor = semantic.chartColorFor(expense.category);
    final onCat = semantic.onFor(catColor, cs);

    final payerLabel = expense.paidBy == currentUserId
        ? context.l10n.you
        : expense.paidByName;
    final metaLine =
        '$payerLabel - ${_formatRelativeDate(context, expense.expenseDate)}';

    final canManage = canManagePaidRecord(
      userId: currentUserId,
      ownerId: ownerId,
      paidBy: expense.paidBy,
    );

    return InkWell(
      onLongPress: canManage ? () => _showExpenseActions(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TabbyCategoryGlyph(
              icon: expense.category.flutterIcon,
              background: catColor,
              foreground: onCat,
              size: 40,
              iconSize: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        expense.name,
                        style: tt.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      ExpressiveBadge(
                        label: expense.category.name,
                        color: catColor,
                        textColor: onCat,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        labelStyle: tt.labelSmall?.copyWith(
                          color: onCat,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    metaLine,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${expense.amount.toStringAsFixed(2)} €',
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseActions(BuildContext context) {
    final cubit = context.read<GroupDetailCubit>();
    final state = cubit.state as GroupDetailLoaded;

    showTabbyActionSheet(
      context,
      actions: [
        TabbyActionSheetItem(
          icon: Symbols.edit_rounded,
          label: context.l10n.editExpense,
          subtitle: expense.name,
          onTap: () => _showEditDialog(context, state, cubit),
        ),
        const TabbyActionSheetItem.divider(),
        TabbyActionSheetItem(
          icon: Symbols.delete_rounded,
          label: context.l10n.delete,
          subtitle: expense.name,
          danger: true,
          onTap: () async {
            final err = await cubit.deleteExpense(expense.id);
            if (!context.mounted) return;
            if (err != null) {
              showTabbySnack(context, context.l10nError(err));
            }
          },
        ),
      ],
    );
  }

  void _showEditDialog(
    BuildContext context,
    GroupDetailLoaded state,
    GroupDetailCubit cubit,
  ) {
    showTabbyDialog(
      context: context,
      builder: (ctx) => _EditExpenseDialog(
        expense: expense,
        members: state.group.members,
        cubit: cubit,
      ),
    );
  }
}

// ─── Total card ───────────────────────────────────────────────────────────────

// Remplace l'ancienne mini card par un hero stat expressif
class _TotalHero extends StatelessWidget {
  const _TotalHero({required this.expenses});
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final count = expenses.length;

    return ExpressiveHeroBanner(
      label: context.l10n.totalExpenses,
      value: total.toStringAsFixed(2),
      suffix: ' €',
      subtitle: context.l10n.expenseCount(count),
      variant: ExpressiveTonalVariant.coral,
      accentIcon: Symbols.receipt_long_rounded,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    );
  }
}

// ─── Edit expense dialog ──────────────────────────────────────────────────────

class _EditExpenseDialog extends StatefulWidget {
  const _EditExpenseDialog({
    required this.expense,
    required this.members,
    required this.cubit,
  });
  final Expense expense;
  final List<GroupMember> members;
  final GroupDetailCubit cubit;

  @override
  State<_EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends State<_EditExpenseDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late String _paidBy;
  late DateTime _date;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.expense.name);
    _amountCtrl = TextEditingController(
      text: widget.expense.amount.toStringAsFixed(2),
    );
    _paidBy = widget.expense.paidBy;
    _date = widget.expense.expenseDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final dateLabel =
        '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}';

    return TabbyFormDialog(
      title: context.l10n.editExpense,
      submitLabel: context.l10n.save,
      cancelLabel: context.l10n.cancel,
      loading: _loading,
      onSubmit: _submit,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: context.l10n.name),
            ),
            const SizedBox(height: 12),
            TabbyAmountField(
              controller: _amountCtrl,
              label: context.l10n.amount,
            ),
            const SizedBox(height: 12),
            Text(context.l10n.paidBy, style: tt.labelMedium),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _paidBy,
              decoration: const InputDecoration(),
              items: widget.members
                  .map(
                    (m) => DropdownMenuItem(
                      value: m.user.id,
                      child: Text(m.user.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _paidBy = v ?? _paidBy),
            ),
            const SizedBox(height: 12),
            Text(context.l10n.date, style: tt.labelMedium),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              borderRadius: context.tabbyShapes.radiusMedium,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: context.tabbyShapes.radiusMedium,
                ),
                child: Row(
                  children: [
                    Icon(
                      Symbols.calendar_month_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(dateLabel, style: tt.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final amount = TabbyAmountField.parse(_amountCtrl.text);
    if (name.isEmpty || amount == null || amount <= 0) return;

    setState(() => _loading = true);
    final err = await widget.cubit.updateExpense(
      expenseId: widget.expense.id,
      name: name,
      amount: amount,
      paidBy: _paidBy,
      expenseDate: _date,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      showTabbySnack(context, context.l10nError(err));
    } else {
      Navigator.pop(context);
    }
  }
}

String _formatRelativeDate(BuildContext context, DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final expenseDay = DateTime(date.year, date.month, date.day);
  final days = today.difference(expenseDay).inDays;

  if (days <= 0) return context.l10n.today;
  if (days == 1) return context.l10n.daysAgoOne;
  return context.l10n.daysAgo(days);
}
