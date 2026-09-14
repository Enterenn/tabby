import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/api/token_storage.dart';
import '../../../core/format/money.dart';
import '../../../core/format/split_shares.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/expressive_shapes.dart';
import '../../../l10n/l10n.dart';
import '../../../features/home/cubit/home_cubit.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/expense.dart';
import '../../../shared/models/group.dart';
import '../../../shared/models/personal_expense.dart';
import '../../../shared/widgets/category_editor_sheet.dart';
import '../cubit/add_expense_cubit.dart';
import '../cubit/draft_store.dart';

part 'add_expense_sheet.dart';
part 'add_expense_splits.dart';
part 'add_expense_category_rail.dart';
part 'add_expense_meta.dart';

/// Ouvre la feuille de création (ou d'édition) de dépense.
/// [groupId] renseigné → groupe prérempli et verrouillé.
/// [editing] / [editingPersonal] → même feuille, déjà remplie.
Future<bool?> showAddExpenseSheet(
  BuildContext context, {
  String? groupId,
  bool forMe = false,
  Expense? editing,
  PersonalExpense? editingPersonal,
}) {
  assert(
    editing == null || editingPersonal == null,
    'Pass either a group or personal expense to edit, not both.',
  );
  final lock = (groupId != null && groupId.isNotEmpty) ||
      editing != null ||
      editingPersonal != null;
  final home = context.read<HomeCubit>();
  return showTabbySheet<bool>(
    context,
    isScrollControlled: true,
    builder: (_) => BlocProvider(
      create: (_) => AddExpenseCubit()
        ..load(groupId: groupId, lockGroup: lock),
      child: _AddExpenseSheet(
        onCreated: home.loadGroups,
        initialForMe: forMe || editingPersonal != null,
        editing: editing,
        editingPersonal: editingPersonal,
        groupId: groupId,
      ),
    ),
  );
}
