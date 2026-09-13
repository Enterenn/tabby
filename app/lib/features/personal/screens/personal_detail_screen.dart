import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../design_system/design_system.dart';
import '../../../features/add_expense/screens/add_expense_screen.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/personal_expense.dart';
import '../cubit/personal_detail_cubit.dart';

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
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.expenseCount(expenses.length),
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onTertiaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (expenses.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: TabbyEmptyState(
                      icon: Symbols.receipt_long_rounded,
                      title: context.l10n.noPersonalPurchasesYet,
                      body: context.l10n.noPersonalPurchasesHint,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
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
    final cs = context.tabbyColors;
    final catColor = expense.category.resolvedColor;
    final onCat = expense.category.onResolvedColor;

    return TabbyListCard(
      margin: EdgeInsets.zero,
      onTap: () => _showActions(context),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
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
                Text(expense.name, style: tt.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${expense.category.name} · ${_formatDate(context, expense.expenseDate)}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          ExpressiveFigure(
            value: formatMoney(context, expense.amount),
            size: ExpressiveFigureSize.small,
          ),
        ],
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
    showTabbyFormDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<PersonalDetailCubit>(),
        child: _EditDialog(expense: expense, categories: categories),
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

class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.expense, required this.categories});

  final PersonalExpense expense;
  final List<Category> categories;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late Category _category;
  late DateTime _date;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.expense.name);
    _amountCtrl = TextEditingController(
      text: widget.expense.amount.toStringAsFixed(2),
    );
    _category = widget.categories.firstWhere(
      (c) => c.id == widget.expense.category.id,
      orElse: () => widget.expense.category,
    );
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

  Future<void> _save() async {
    final amount = TabbyAmountField.parse(_amountCtrl.text);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || amount == null || amount <= 0) return;
    setState(() => _loading = true);
    final err = await context.read<PersonalDetailCubit>().updateExpense(
          expenseId: widget.expense.id,
          name: name,
          amount: amount,
          categoryId: _category.id,
          expenseDate: _date,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err == null) {
      Navigator.of(context).pop();
      return;
    }
    showTabbySnack(context, context.l10nError(err));
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final dateLabel =
        '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}';

    return TabbyFormDialog(
      title: context.l10n.editExpense,
      submitLabel: context.l10n.save,
      cancelLabel: context.l10n.cancel,
      loading: _loading,
      scrollable: true,
      onSubmit: _save,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: context.l10n.name),
          ),
          const SizedBox(height: 12),
          TabbyAmountField(
            controller: _amountCtrl,
            label: context.l10n.amount,
          ),
          const SizedBox(height: 12),
          Text(context.l10n.category, style: tt.labelLarge),
          const SizedBox(height: 6),
          DropdownButtonFormField<Category>(
            initialValue: _category,
            items: [
              if (!widget.categories.any((c) => c.id == _category.id))
                _category,
              ...widget.categories,
            ]
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        c.iconWidget(size: 18, color: c.resolvedColor),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (c) {
              if (c != null) setState(() => _category = c);
            },
          ),
          const SizedBox(height: 12),
          Text(context.l10n.date, style: tt.labelLarge),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickDate,
            borderRadius: context.tabbyShapes.radiusMedium,
            child: InputDecorator(
              decoration: const InputDecoration(
                prefixIcon: Icon(Symbols.calendar_month_rounded, size: 18),
              ),
              child: Text(dateLabel, style: tt.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(BuildContext context, DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final expenseDay = DateTime(date.year, date.month, date.day);
  final days = today.difference(expenseDay).inDays;

  if (days <= 0) return context.l10n.today;
  if (days == 1) return context.l10n.daysAgoOne;
  return context.l10n.daysAgo(days);
}
