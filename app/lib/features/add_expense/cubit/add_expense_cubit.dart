import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/api/api_failure.dart';
import '../../../data/repositories.dart';
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
      final groups = await groupsRepository.list();
      final categories = await categoriesRepository.list();

      if (groups.isEmpty) {
        if (!isClosed) {
          emit(AddExpenseReady(
            groups: const [],
            categories: categories,
            groupLocked: lockGroup,
          ));
        }
        return;
      }

      final selectedId = groupId ?? (groups.length == 1 ? groups.first.id : null);
      if (selectedId == null) {
        if (!isClosed) {
          emit(AddExpenseReady(groups: groups, categories: categories));
        }
        return;
      }

      final group = await groupsRepository.get(selectedId);
      if (!isClosed) {
        emit(AddExpenseReady(
          groups: groups,
          group: group,
          categories: categories,
          groupLocked: lockGroup && groupId != null,
        ));
      }
    } catch (e) {
      if (!isClosed) emit(AddExpenseError(ApiFailure.from(e).message));
    }
  }

  Future<void> selectGroup(String groupId) async {
    final current = state;
    if (current is! AddExpenseReady || current.groupLocked) return;
    try {
      final group = await groupsRepository.get(groupId);
      if (!isClosed) {
        emit(current.copyWith(group: group));
      }
    } catch (e) {
      if (!isClosed) emit(AddExpenseError(ApiFailure.from(e).message));
    }
  }

  Future<Category?> createCategory({
    required String name,
    required String icon,
    required String color,
  }) async {
    final current = state;
    if (current is! AddExpenseReady) return null;
    try {
      final newCat = await categoriesRepository.create(
        name: name,
        icon: icon,
        color: color,
      );
      if (!isClosed) {
        emit(current.copyWith(categories: [...current.categories, newCat]));
      }
      return newCat;
    } catch (e) {
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
        await recurringRepository.create(
          groupId: groupId,
          name: name,
          amount: amount,
          categoryId: categoryId,
          paidBy: paidBy,
          dayOfPeriod: expenseDate.day,
        );
      } else {
        await expensesRepository.create(
          groupId: groupId,
          name: name,
          amount: amount,
          categoryId: categoryId,
          paidBy: paidBy,
          expenseDate: expenseDate,
          customSplits: customSplits,
        );
      }

      if (!isClosed) emit(const AddExpenseSuccess());
      return true;
    } catch (e) {
      if (!isClosed) emit(AddExpenseError(ApiFailure.from(e).message));
      return false;
    }
  }

  Future<bool> submitPersonal({
    required String name,
    required double amount,
    required String categoryId,
    required DateTime expenseDate,
  }) async {
    if (state is! AddExpenseReady) return false;
    emit(const AddExpenseSubmitting());
    try {
      await personalExpensesRepository.create(
        name: name,
        amount: amount,
        categoryId: categoryId,
        expenseDate: expenseDate,
      );
      if (!isClosed) emit(const AddExpenseSuccess());
      return true;
    } catch (e) {
      if (!isClosed) emit(AddExpenseError(ApiFailure.from(e).message));
      return false;
    }
  }
}
