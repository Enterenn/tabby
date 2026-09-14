import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/categories_repository.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/group.dart';
import '../../../shared/models/recurring_expense.dart';
import '../cubit/recurring_cubit.dart';

Future<void> showEditRecurringSheet({
  required BuildContext context,
  required RecurringExpense item,
  List<GroupMember> members = const [],
}) {
  final cubit = context.read<RecurringCubit>();
  return showTabbySheet<void>(
    context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _EditRecurringSheet(item: item, members: members),
    ),
  );
}

class _EditRecurringSheet extends StatefulWidget {
  const _EditRecurringSheet({
    required this.item,
    required this.members,
  });

  final RecurringExpense item;
  final List<GroupMember> members;

  @override
  State<_EditRecurringSheet> createState() => _EditRecurringSheetState();
}

class _EditRecurringSheetState extends State<_EditRecurringSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late Category _category;
  late int _dayOfPeriod;
  late String _paidBy;
  List<Category> _categories = const [];
  bool _loading = false;

  RecurringExpense get _item => widget.item;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: _item.name);
    _amountCtrl = TextEditingController(text: _item.amount.toStringAsFixed(2));
    _category = _item.category;
    _dayOfPeriod = _item.dayOfPeriod.clamp(1, 28);
    _paidBy = _item.paidBy;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await categoriesRepository.list(
        groupId: _item.isPersonal ? null : _item.groupId,
      );
      if (!mounted) return;
      setState(() {
        _categories = categories;
        for (final category in categories) {
          if (category.id == _category.id) {
            _category = category;
            break;
          }
        }
      });
    } catch (_) {
      // Keep the current category if the list cannot be loaded.
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = TabbyAmountField.parse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    setState(() => _loading = true);
    final err = await context.read<RecurringCubit>().update(
          _item,
          name: _nameCtrl.text.trim(),
          amount: amount,
          categoryId: _category.id,
          dayOfPeriod: _dayOfPeriod,
          paidBy: _item.isPersonal ? null : _paidBy,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      showTabbySnack(context, context.l10nError(err));
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final showPayer = !_item.isPersonal && widget.members.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExpressiveSheetHeader(
                title: context.l10n.editRecurring,
                subtitle: context.l10n.editRecurringSubtitle,
                onClose: () => Navigator.of(context).pop(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: context.l10n.name),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? context.l10n.requiredField
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TabbyAmountField(
                      controller: _amountCtrl,
                      label: context.l10n.amount,
                      validator: (value) {
                        final amount = TabbyAmountField.parse(value ?? '');
                        if (amount == null || amount <= 0) {
                          return context.l10n.requiredField;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ExpressiveSheetSection(
                      label: context.l10n.category,
                      child: TabbyCategoryDropdown(
                        key: ValueKey('${_categories.length}-${_category.id}'),
                        categories: _categories,
                        selected: _category,
                        hint: context.l10n.chooseCategory,
                        onSelected: (category) {
                          if (category == null) return;
                          setState(() => _category = category);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    ExpressiveSheetSection(
                      label: context.l10n.recurringDayOfMonth,
                      child: ExpressiveDropdown<int>(
                        selected: _dayOfPeriod,
                        leadingIcon: Icon(
                          Symbols.calendar_month_rounded,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                        entries: [
                          for (var day = 1; day <= 28; day++)
                            ExpressiveDropdownEntry(
                              value: day,
                              label: day == 1
                                  ? context.l10n.recurringFirstOfMonth
                                  : context.l10n.recurringNthOfMonth(day),
                            ),
                        ],
                        onSelected: (day) {
                          if (day == null) return;
                          setState(() => _dayOfPeriod = day);
                        },
                      ),
                    ),
                    if (showPayer) ...[
                      const SizedBox(height: 20),
                      ExpressiveSheetSection(
                        label: context.l10n.paidBy,
                        child: ExpressiveDropdown<String>(
                          selected: _paidBy,
                          leadingIcon: Icon(
                            Symbols.person_rounded,
                            size: 20,
                            color: cs.onSurfaceVariant,
                          ),
                          entries: [
                            if (widget.members.every(
                              (member) => member.user.id != _paidBy,
                            ))
                              ExpressiveDropdownEntry(
                                value: _paidBy,
                                label: _item.paidByName,
                              ),
                            for (final member in widget.members)
                              ExpressiveDropdownEntry(
                                value: member.user.id,
                                label: member.user.name,
                              ),
                          ],
                          onSelected: (id) {
                            if (id == null) return;
                            setState(() => _paidBy = id);
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    ExpressiveSheetSubmit(
                      label: context.l10n.save,
                      loading: _loading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
