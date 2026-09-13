import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/format/date.dart';
import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../design_system/design_system.dart';
import '../../../features/add_expense/screens/add_expense_screen.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/models/personal_expense.dart';
import '../cubit/personal_detail_cubit.dart';

Future<void> _editPersonalExpense(
  BuildContext context, {
  required PersonalExpense expense,
}) async {
  final updated = await showAddExpenseSheet(
    context,
    forMe: true,
    editingPersonal: expense,
  );
  if (updated == true && context.mounted) {
    context.read<PersonalDetailCubit>().load();
  }
}

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
          PersonalDetailLoaded(:final expenses) =>
            _LoadedBody(expenses: expenses),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.expenses});

  final List<PersonalExpense> expenses;

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
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: cs.onTertiaryContainer),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.yourShare.toUpperCase(),
                          style: tt.labelSmall?.copyWith(
                            fontSize: 10,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w700,
                            color: cs.onTertiaryContainer,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatMoney(context, total),
                          style: context.tabbyType.figureMedium.copyWith(
                            fontSize: 28,
                            height: 32 / 28,
                            color: cs.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: TabbySectionHeader(
                  title: expenses.isEmpty
                      ? context.l10n.expenses
                      : context.l10n.expensesCount(expenses.length),
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
                    itemBuilder: (ctx, i) => _ExpenseTile(expense: expenses[i]),
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
                  final created =
                      await showAddExpenseSheet(context, forMe: true);
                  if (created == true && context.mounted) {
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
  const _ExpenseTile({required this.expense});

  final PersonalExpense expense;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
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
          onTap: () => _editPersonalExpense(context, expense: expense),
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
    final err =
        await context.read<PersonalDetailCubit>().deleteExpense(expense.id);
    if (!context.mounted || err == null) return;
    showTabbySnack(context, context.l10nError(err));
  }
}
