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
    final waiting = err == null && entry.fromUserId == currentUserId;
    showTabbySnack(
      context,
      err != null
          ? context.l10nError(err)
          : waiting
              ? context.l10n.settlePending
              : context.l10n.settleSaved,
    );
  }
}

// ─── Member tile ─────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    super.key,
    required this.member,
    required this.balances,
    required this.ownerId,
  });
  final GroupMember member;
  final List<BalanceEntry> balances;
  final String? ownerId;

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
    final isAdmin = isGroupAdmin(userId: member.user.id, ownerId: ownerId);

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
                    if (isAdmin)
                      ExpressiveBadge(
                        label: context.l10n.admin,
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
                groupId: group.id,
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
                ownerId: group.ownerId,
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
    required this.groupId,
  });

  final Expense expense;
  final String currentUserId;
  final String? ownerId;
  final String groupId;

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

    final canManage = canManagePaidRecord(
      userId: currentUserId,
      ownerId: ownerId,
      paidBy: expense.paidBy,
    );

    final canConfirm = expense.canConfirm(currentUserId);

    return InkWell(
      onTap: () => context.push(
        '/groups/$groupId/expenses/${expense.id}',
        extra: context.read<GroupDetailCubit>(),
      ),
      onLongPress: canManage || canConfirm
          ? () => _showExpenseActions(context)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Opacity(
              opacity: expense.isPending ? 0.48 : 1,
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
                              context.expenseName(expense),
                              style: tt.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                            if (expense.isPending)
                              ExpressiveBadge(
                                label: context.l10n.repaymentPending,
                                color: cs.surfaceContainerHighest,
                                textColor: cs.onSurfaceVariant,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                labelStyle: tt.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  height: 1.1,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.l10n.paidByPerson(payerLabel),
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${expense.amount.toStringAsFixed(2)} €',
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      if (currentUserId.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.yourShareAmount(
                            expense.shareFor(currentUserId).toStringAsFixed(2),
                          ),
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (canConfirm) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () => _confirmRepayment(context),
                  child: Text(context.l10n.confirmRepayment),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRepayment(BuildContext context) async {
    final err = await context.read<GroupDetailCubit>().confirmExpense(expense.id);
    if (!context.mounted) return;
    showTabbySnack(
      context,
      err != null ? context.l10nError(err) : context.l10n.repaymentConfirmed,
    );
  }

  void _showExpenseActions(BuildContext context) {
    final cubit = context.read<GroupDetailCubit>();
    final title = context.expenseName(expense);

    showTabbyActionSheet(
      context,
      actions: [
        if (!expense.isPending)
          TabbyActionSheetItem(
            icon: Symbols.edit_rounded,
            label: context.l10n.editExpense,
            subtitle: title,
            onTap: () => _editGroupExpense(
              context,
              groupId: groupId,
              expense: expense,
            ),
          ),
        if (!expense.isPending) const TabbyActionSheetItem.divider(),
        TabbyActionSheetItem(
          icon: Symbols.delete_rounded,
          label: context.l10n.delete,
          subtitle: title,
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

}

// ─── Total card ───────────────────────────────────────────────────────────────

// Remplace l'ancienne mini card par un hero stat expressif
class _TotalHero extends StatelessWidget {
  const _TotalHero({required this.expenses, required this.currentUserId});
  final List<Expense> expenses;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final confirmed = expenses.where((e) => e.isConfirmed);
    final total = confirmed.fold<double>(0, (sum, e) => sum + e.amount);
    final myShare = currentUserId.isEmpty
        ? 0.0
        : confirmed.fold<double>(0, (sum, e) => sum + e.shareFor(currentUserId));

    final yourShare = formatMoney(context, myShare);
    final groupTotal = formatMoney(context, total);
    const gap = 16.0;

    return ExpressiveTonalCard(
      variant: ExpressiveTonalVariant.coral,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final figureStyle = _heroAmountStyle(context);
          final sideBySide = _measureText(context, yourShare, figureStyle) +
                  _measureText(context, groupTotal, figureStyle) +
                  gap <=
              constraints.maxWidth;
          if (sideBySide) {
            return Row(
              children: [
                Expanded(
                  child: _CostColumn(
                    label: context.l10n.yourShare,
                    value: yourShare,
                  ),
                ),
                const SizedBox(width: gap),
                Expanded(
                  child: _CostColumn(
                    label: context.l10n.totalExpenses,
                    value: groupTotal,
                    alignEnd: true,
                  ),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CostColumn(
                label: context.l10n.yourShare,
                value: yourShare,
              ),
              const SizedBox(height: 12),
              _CostColumn(
                label: context.l10n.totalExpenses,
                value: groupTotal,
              ),
            ],
          );
        },
      ),
    );
  }
}

TextStyle _heroAmountStyle(BuildContext context) {
  final base = context.tabbyType.figureMedium;
  return base.copyWith(
    fontSize: 28,
    height: 32 / 28,
  );
}

double _measureText(BuildContext context, String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    maxLines: 1,
  )..layout();
  return painter.width;
}

class _CostColumn extends StatelessWidget {
  const _CostColumn({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final align = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: tt.labelSmall?.copyWith(
            fontSize: 10,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: _heroAmountStyle(context),
            ),
          ),
        ),
      ],
    );
  }
}
