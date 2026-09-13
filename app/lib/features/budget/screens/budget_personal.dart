part of 'budget_screen.dart';
// ─── Personal purchases (Pour moi) ────────────────────────────────────────────

class _PersonalExpensesSection extends StatelessWidget {
  const _PersonalExpensesSection({required this.state});

  final BudgetLoaded state;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = context.tabbyColors;
    final space = context.tabbySpace;
    final items = state.visiblePersonalExpenses;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabbySectionHeader(
            title: context.l10n.personalPurchases,
            padding: EdgeInsets.fromLTRB(4, space.md, 4, space.sm),
          ),
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
              (expense) => _PersonalExpenseTile(expense: expense),
            ),
        ],
      ),
    );
  }
}

class _PersonalExpenseTile extends StatelessWidget {
  const _PersonalExpenseTile({required this.expense});

  final PersonalExpense expense;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
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
        title: Text(
          expense.name,
          style: tt.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        subtitle: Text(
          '${context.categoryName(expense.category)} · ${formatRelativeDate(context, expense.expenseDate)}',
        ),
        trailing: Text(
          formatMoney(context, expense.amount),
          style: tt.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
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
          onTap: () => showAddExpenseSheet(
            context,
            forMe: true,
            editingPersonal: expense,
          ),
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
