import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/format/date.dart';
import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../design_system/design_system.dart';
import '../../../features/add_expense/screens/add_expense_screen.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/personal_expense.dart';
import '../cubit/personal_detail_cubit.dart';
import '../widgets/personal_expense_edit_dialog.dart';

class PersonalDetailScreen extends StatelessWidget {
  const PersonalDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PersonalDetailCubit()..load(),
      child: const _PersonalDetailView(),
    );
  }
}

class _PersonalDetailView extends StatelessWidget {
  const _PersonalDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PersonalDetailCubit, PersonalDetailState>(
      listener: (context, state) {
        if (state is PersonalDetailError) {
          showTabbySnack(
            context,
            context.l10nError(state.message),
            actionLabel: context.l10n.retry,
            onAction: () => context.read<PersonalDetailCubit>().load(),
          );
        }
      },
      builder: (context, state) {
        return switch (state) {
          PersonalDetailLoading() => const Scaffold(body: TabbyLoading()),
          PersonalDetailError(:final message) => Scaffold(
              appBar: AppBar(title: Text(context.l10n.myExpenses)),
              body: TabbyErrorState(
                message: context.l10nError(message),
                retryLabel: context.l10n.retry,
                onRetry: () => context.read<PersonalDetailCubit>().load(),
              ),
            ),
          PersonalDetailLoaded(:final expenses, :final categories) =>
            _LoadedBody(expenses: expenses, categories: categories),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.expenses, required this.categories});

  final List<PersonalExpense> expenses;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final tt = Theme.of(context).textTheme;
    final cs = context.tabbyColors;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(context.l10n.myExpenses),
              ),
              SliverToBoxAdapter(
                child: ExpressiveTonalCard(
                  variant: ExpressiveTonalVariant.lime,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.yourShare,
                        style: tt.labelLarge?.copyWith(
                          color: cs.onTertiaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      ExpressiveFigure(
                        value: formatMoney(context, total),
                        size: ExpressiveFigureSize.medium,
                        color: cs.onTertiaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                  child: Text(
                    expenses.isEmpty
                        ? context.l10n.expenses
                        : context.l10n.expensesCount(expenses.length),
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (expenses.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: TabbyEmptyState(
                      icon: Symbols.receipt_long_rounded,
                      title: context.l10n.noPersonalPurchasesYet,
                      body: context.l10n.noPersonalPurchasesHint,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  sliver: SliverList.separated(
                    itemCount: expenses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) => _ExpenseTile(
                      expense: expenses[i],
                      categories: categories,
                    ),
                  ),
                ),
            ],
          ),
          ExpressiveScreenFabMenu(
            actions: [
              ExpressiveFabMenuAction(
                icon: Symbols.receipt_long_rounded,
                label: context.l10n.addExpense,
                onSelected: () async {
                  await showAddExpenseSheet(context, forMe: true);
                  if (context.mounted) {
                    context.read<PersonalDetailCubit>().load();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, required this.categories});

  final PersonalExpense expense;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final catColor = expense.category.resolvedColor;
    final onCat = expense.category.onResolvedColor;

    return TabbyListCard(
      margin: EdgeInsets.zero,
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
    final cubit = context.read<PersonalDetailCubit>();
    showTabbyFormDialog(
      context: context,
      builder: (_) => PersonalExpenseEditDialog(
        expense: expense,
        categories: categories,
        onSave: ({
          required name,
          required amount,
          required categoryId,
          required expenseDate,
        }) {
          return cubit.updateExpense(
            expenseId: expense.id,
            name: name,
            amount: amount,
            categoryId: categoryId,
            expenseDate: expenseDate,
          );
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
    final err =
        await context.read<PersonalDetailCubit>().deleteExpense(expense.id);
    if (!context.mounted || err == null) return;
    showTabbySnack(context, context.l10nError(err));
  }
}
