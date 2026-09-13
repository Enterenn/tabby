import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/personal_expense.dart';

typedef PersonalExpenseSave = Future<String?> Function({
  required String name,
  required double amount,
  required String categoryId,
  required DateTime expenseDate,
});

/// Dialog d’édition d’une dépense perso — partagé perso / budget.
class PersonalExpenseEditDialog extends StatefulWidget {
  const PersonalExpenseEditDialog({
    super.key,
    required this.expense,
    required this.categories,
    required this.onSave,
  });

  final PersonalExpense expense;
  final List<Category> categories;
  final PersonalExpenseSave onSave;

  @override
  State<PersonalExpenseEditDialog> createState() =>
      _PersonalExpenseEditDialogState();
}

class _PersonalExpenseEditDialogState extends State<PersonalExpenseEditDialog> {
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

  Future<void> _save() async {
    final amount = TabbyAmountField.parse(_amountCtrl.text);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || amount == null || amount <= 0) return;
    setState(() => _loading = true);
    final err = await widget.onSave(
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
    final space = context.tabbySpace;

    return TabbyFormDialog(
      title: context.l10n.editExpense,
      submitLabel: context.l10n.save,
      cancelLabel: context.l10n.cancel,
      loading: _loading,
      scrollable: true,
      onSubmit: _save,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: context.l10n.name),
          ),
          SizedBox(height: space.md),
          TabbyAmountField(
            controller: _amountCtrl,
            label: context.l10n.amount,
          ),
          SizedBox(height: space.md),
          TabbyCategoryDropdown(
            categories: widget.categories,
            selected: _category,
            label: context.l10n.category,
            onSelected: (c) {
              if (c != null) setState(() => _category = c);
            },
          ),
          SizedBox(height: space.md),
          TabbyDateField(
            value: _date,
            label: context.l10n.date,
            onChanged: (d) => setState(() => _date = d),
          ),
        ],
      ),
    );
  }
}
