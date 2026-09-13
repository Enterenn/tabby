part of 'budget_screen.dart';
// ─── Personal purchases (Pour moi) ────────────────────────────────────────────

class _PersonalExpensesSection extends StatelessWidget {
  const _PersonalExpensesSection({required this.state});

  final BudgetLoaded state;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = context.tabbyColors;
    final items = state.visiblePersonalExpenses;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.personalPurchases, style: tt.titleMedium),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.noPersonalPurchases,
                    style: tt.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.noPersonalPurchasesHint,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            )
          else
            ...items.map(
              (expense) => _PersonalExpenseTile(expense: expense, state: state),
            ),
        ],
      ),
    );
  }
}

class _PersonalExpenseTile extends StatelessWidget {
  const _PersonalExpenseTile({required this.expense, required this.state});

  final PersonalExpense expense;
  final BudgetLoaded state;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final catColor = expense.category.resolvedColor;
    final onCat = expense.category.onResolvedColor;

    return TabbyListCard(
      margin: const EdgeInsets.only(bottom: 8),
      onTap: () => _showActions(context),
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: TabbyCategoryGlyph(
          icon: expense.category.flutterIcon,
          background: catColor,
          foreground: onCat,
          size: 40,
          iconSize: 20,
        ),
        title: Text(expense.name, style: tt.titleSmall),
        subtitle: Text(
          '${context.categoryName(expense.category)} · ${formatRelativeDate(context, expense.expenseDate)}',
        ),
        trailing: ExpressiveFigure(
          value: formatMoney(context, expense.amount),
          size: ExpressiveFigureSize.small,
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showTabbyActionSheet(
      context,
      title: expense.name,
      actions: [
        TabbyActionSheetItem(
          label: context.l10n.editExpense,
          icon: Symbols.edit_rounded,
          onTap: () => _showEditDialog(context),
        ),
        TabbyActionSheetItem(
          label: context.l10n.delete,
          icon: Symbols.delete_rounded,
          danger: true,
          onTap: () => _confirmDelete(context),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
    final cubit = context.read<BudgetCubit>();
    showTabbyFormDialog(
      context: context,
      builder: (_) => PersonalExpenseEditDialog(
        expense: expense,
        categories: state.allCategories,
        onSave: ({
          required name,
          required amount,
          required categoryId,
          required expenseDate,
        }) async {
          final errorLabel = context.l10n.errorUpdate;
          final ok = await cubit.updatePersonal(
            expenseId: expense.id,
            name: name,
            amount: amount,
            categoryId: categoryId,
            expenseDate: expenseDate,
          );
          return ok ? null : errorLabel;
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showTabbyConfirm(
      context,
      title: context.l10n.deletePersonalTitle,
      body: context.l10n.deletePersonalBody(expense.name),
      confirmLabel: context.l10n.delete,
      danger: true,
    );
    if (!confirmed || !context.mounted) return;
    final err = await context.read<BudgetCubit>().deletePersonal(expense.id);
    if (!context.mounted || err == null) return;
    showTabbySnack(context, context.l10nError(err));
  }
}
