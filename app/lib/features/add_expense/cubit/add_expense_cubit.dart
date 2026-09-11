import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/group.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class AddExpenseState extends Equatable {
  const AddExpenseState();
  @override
  List<Object?> get props => [];
}

class AddExpenseInitial extends AddExpenseState {
  const AddExpenseInitial();
}

class AddExpenseLoading extends AddExpenseState {
  const AddExpenseLoading();
}

class AddExpenseReady extends AddExpenseState {
  const AddExpenseReady({
    required this.groups,
    required this.categories,
    this.group,
    this.groupLocked = false,
  });

  final List<Group> groups;
  final List<Category> categories;
  final Group? group;
  final bool groupLocked;

  AddExpenseReady copyWith({
    List<Group>? groups,
    List<Category>? categories,
    Group? group,
    bool? groupLocked,
    bool clearGroup = false,
  }) =>
      AddExpenseReady(
        groups: groups ?? this.groups,
        categories: categories ?? this.categories,
        group: clearGroup ? null : (group ?? this.group),
        groupLocked: groupLocked ?? this.groupLocked,
      );

  @override
  List<Object?> get props => [groups, categories, group, groupLocked];
}

class AddExpenseSubmitting extends AddExpenseState {
  const AddExpenseSubmitting();
}

class AddExpenseSuccess extends AddExpenseState {
  const AddExpenseSuccess();
}

class AddExpenseError extends AddExpenseState {
  const AddExpenseError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class AddExpenseCubit extends Cubit<AddExpenseState> {
  AddExpenseCubit() : super(const AddExpenseInitial());

  Future<void> load({String? groupId, bool lockGroup = false}) async {
    emit(const AddExpenseLoading());
    try {
      final groupsResp = await apiClient.dio.get('/groups');
      final groups = (groupsResp.data as List)
          .map((g) => Group.fromJson(g as Map<String, dynamic>))
          .toList();

      if (groups.isEmpty) {
        emit(AddExpenseReady(
          groups: const [],
          categories: const [],
          groupLocked: lockGroup,
        ));
        return;
      }

      final selectedId = groupId ?? (groups.length == 1 ? groups.first.id : null);
      if (selectedId == null) {
        emit(AddExpenseReady(groups: groups, categories: const []));
        return;
      }

      final data = await _fetchGroupData(selectedId);
      emit(AddExpenseReady(
        groups: groups,
        group: data.group,
        categories: data.categories,
        groupLocked: lockGroup && groupId != null,
      ));
    } catch (e) {
      emit(AddExpenseError(e.toString()));
    }
  }

  Future<void> selectGroup(String groupId) async {
    final current = state;
    if (current is! AddExpenseReady || current.groupLocked) return;
    try {
      final data = await _fetchGroupData(groupId);
      emit(current.copyWith(group: data.group, categories: data.categories));
    } catch (e) {
      emit(AddExpenseError(e.toString()));
    }
  }

  Future<({Group group, List<Category> categories})> _fetchGroupData(
      String groupId) async {
    final results = await Future.wait([
      apiClient.dio.get('/categories', queryParameters: {'group_id': groupId}),
      apiClient.dio.get('/groups/$groupId'),
    ]);
    final categories = (results[0].data as List)
        .map((c) => Category.fromJson(c as Map<String, dynamic>))
        .toList();
    final group = Group.fromJson(results[1].data as Map<String, dynamic>);
    return (group: group, categories: categories);
  }

  Future<Category?> createCategory({
    required String groupId,
    required String name,
    required String icon,
    required String color,
  }) async {
    final current = state;
    if (current is! AddExpenseReady) return null;
    try {
      final response = await apiClient.dio.post('/categories', data: {
        'group_id': groupId,
        'name': name,
        'icon': icon,
        'color': color,
      });
      final newCat = Category.fromJson(response.data as Map<String, dynamic>);
      emit(current.copyWith(categories: [...current.categories, newCat]));
      return newCat;
    } catch (_) {
      return null;
    }
  }

  Future<bool> submit({
    required String groupId,
    required String name,
    required double amount,
    required String categoryId,
    required String paidBy,
    required DateTime expenseDate,
    List<Map<String, dynamic>>? customSplits,
    bool recurring = false,
  }) async {
    final current = state;
    if (current is! AddExpenseReady) return false;
    emit(const AddExpenseSubmitting());

    try {
      if (recurring) {
        await apiClient.dio.post('/groups/$groupId/recurring-expenses', data: {
          'name': name,
          'amount': amount,
          'category_id': categoryId,
          'paid_by': paidBy,
          'day_of_period': expenseDate.day,
          'frequency': 'monthly',
        });
      } else {
        final dateStr =
            '${expenseDate.year.toString().padLeft(4, '0')}-'
            '${expenseDate.month.toString().padLeft(2, '0')}-'
            '${expenseDate.day.toString().padLeft(2, '0')}';

        final body = <String, dynamic>{
          'name': name,
          'amount': amount,
          'category_id': categoryId,
          'paid_by': paidBy,
          'expense_date': dateStr,
        };

        if (customSplits != null) {
          body['split_type'] = 'custom';
          body['splits'] = customSplits;
        } else {
          body['split_type'] = 'equal';
        }

        await apiClient.dio.post('/groups/$groupId/expenses', data: body);
      }

      emit(const AddExpenseSuccess());
      return true;
    } catch (_) {
      emit(current);
      return false;
    }
  }
}
