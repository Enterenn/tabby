part of 'group_detail_screen.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({
    super.key,
    required this.groupId,
    required this.expenseId,
    this.cubit,
  });

  final String groupId;
  final String expenseId;
  final GroupDetailCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final view = _ExpenseDetailView(expenseId: expenseId);
    final existing = cubit;
    if (existing != null) {
      return BlocProvider<GroupDetailCubit>.value(
        value: existing,
        child: view,
      );
    }
    return BlocProvider(
      create: (ctx) => GroupDetailCubit(groupId, ctx.read<HomeCubit>())..load(),
      child: view,
    );
  }
}

class _ExpenseDetailView extends StatelessWidget {
  const _ExpenseDetailView({required this.expenseId});

  final String expenseId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroupDetailCubit, GroupDetailState>(
      listener: (context, state) {
        if (state is GroupDetailLoaded &&
            !state.expenses.any((e) => e.id == expenseId)) {
          context.pop();
        }
      },
      builder: (context, state) {
        return switch (state) {
          GroupDetailLoading() || GroupDetailInitial() => const Scaffold(
              body: TabbyLoading(),
            ),
          GroupDetailError(:final message) => Scaffold(
              appBar: AppBar(),
              body: TabbyErrorState(
                message: context.l10nError(message),
                retryLabel: context.l10n.retry,
                onRetry: () => context.read<GroupDetailCubit>().load(),
              ),
            ),
          GroupDetailLoaded(:final group, :final expenses) => _loadedBody(
              context,
              group: group,
              expenses: expenses,
            ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _loadedBody(
    BuildContext context, {
    required Group group,
    required List<Expense> expenses,
  }) {
    Expense? expense;
    for (final item in expenses) {
      if (item.id == expenseId) {
        expense = item;
        break;
      }
    }
    if (expense == null) {
      return const Scaffold(body: TabbyLoading());
    }
    return _ExpenseDetailBody(group: group, expense: expense);
  }
}

class _ExpenseDetailBody extends StatelessWidget {
  const _ExpenseDetailBody({required this.group, required this.expense});

  final Group group;
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final me = tokenStorage.userId ?? '';
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final semantic = context.tabbySemantic;
    final catColor = semantic.chartColorFor(expense.category);
    final onCat = semantic.onFor(catColor, cs);

    final canManage = canManagePaidRecord(
      userId: me,
      ownerId: group.ownerId,
      paidBy: expense.paidBy,
    );
    final canConfirm = expense.canConfirm(me);
    final payer = _personFor(
      context,
      group: group,
      userId: expense.paidBy,
      fallbackName: expense.paidByName,
      currentUserId: me,
    );

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Symbols.more_vert_rounded),
              tooltip: context.l10n.editExpense,
              onPressed: () => _showActions(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                TabbyCategoryGlyph(
                  icon: expense.category.flutterIcon,
                  background: catColor,
                  foreground: onCat,
                  size: 64,
                  iconSize: 32,
                ),
                const SizedBox(height: 16),
                Text(
                  context.expenseName(expense),
                  textAlign: TextAlign.center,
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ExpressiveBadge(
                      label: context.categoryName(expense.category),
                      color: catColor,
                      textColor: onCat,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      labelStyle: tt.labelSmall?.copyWith(
                        color: onCat,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    if (expense.isPending)
                      ExpressiveBadge(
                        label: context.l10n.repaymentPending,
                        color: cs.surfaceContainerHighest,
                        textColor: cs.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        labelStyle: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _GroupedSection(
            title: context.l10n.paidBy,
            itemCount: 1,
            itemBuilder: (_) => _ExpensePersonTile(
              name: payer.name,
              avatarLabel: payer.avatarLabel,
              avatarUrl: payer.avatarUrl,
              amount: expense.amount,
              subtitle: _formatExpenseDate(context, expense.expenseDate),
            ),
          ),
          _GroupedSection(
            title: context.l10n.participants,
            itemCount: expense.splits.length,
            itemBuilder: (i) {
              final split = expense.splits[i];
              final person = _personFor(
                context,
                group: group,
                userId: split.userId,
                fallbackName: split.userId == expense.paidBy
                    ? expense.paidByName
                    : null,
                currentUserId: me,
              );
              return _ExpensePersonTile(
                name: person.name,
                avatarLabel: person.avatarLabel,
                avatarUrl: person.avatarUrl,
                amount: split.amount,
              );
            },
          ),
          if (canConfirm)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: FilledButton.tonal(
                onPressed: () => _confirmRepayment(context),
                child: Text(context.l10n.confirmRepayment),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmRepayment(BuildContext context) async {
    final err =
        await context.read<GroupDetailCubit>().confirmExpense(expense.id);
    if (!context.mounted) return;
    showTabbySnack(
      context,
      err != null ? context.l10nError(err) : context.l10n.repaymentConfirmed,
    );
  }

  void _showActions(BuildContext context) {
    final cubit = context.read<GroupDetailCubit>();
    final state = cubit.state;
    if (state is! GroupDetailLoaded) return;
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
              groupId: group.id,
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

class _ExpensePersonTile extends StatelessWidget {
  const _ExpensePersonTile({
    required this.name,
    required this.avatarLabel,
    required this.amount,
    this.avatarUrl,
    this.subtitle,
  });

  final String name;
  final String avatarLabel;
  final String? avatarUrl;
  final double amount;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          ExpressiveAvatar(
            label: avatarLabel,
            size: 40,
            imageUrl: resolveMediaUrl(avatarUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: tt.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(context, amount),
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ResolvedPerson {
  const _ResolvedPerson({
    required this.name,
    required this.avatarLabel,
    this.avatarUrl,
  });
  final String name;
  final String avatarLabel;
  final String? avatarUrl;
}

_ResolvedPerson _personFor(
  BuildContext context, {
  required Group group,
  required String userId,
  required String currentUserId,
  String? fallbackName,
}) {
  GroupMember? member;
  for (final item in group.members) {
    if (item.user.id == userId) {
      member = item;
      break;
    }
  }
  final realName = member?.user.name ?? fallbackName ?? userId;
  return _ResolvedPerson(
    name: userId == currentUserId ? context.l10n.you : realName,
    avatarLabel: realName,
    avatarUrl: member?.user.avatarUrl,
  );
}

String _formatExpenseDate(BuildContext context, DateTime date) {
  return DateFormat(
    'd MMM yyyy',
    Localizations.localeOf(context).toString(),
  ).format(date);
}
