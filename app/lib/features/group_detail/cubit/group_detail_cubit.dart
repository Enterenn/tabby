import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_failure.dart';
import '../../../data/repositories.dart';
import '../../../shared/models/expense.dart';
import '../../../shared/models/group.dart';
import '../../home/cubit/home_cubit.dart';

sealed class GroupDetailState extends Equatable {
  const GroupDetailState();
  @override
  List<Object?> get props => [];
}

class GroupDetailInitial extends GroupDetailState {}

class GroupDetailLoading extends GroupDetailState {}

class GroupDetailLoaded extends GroupDetailState {
  const GroupDetailLoaded({
    required this.group,
    required this.balances,
    required this.expenses,
  });

  final Group group;
  final List<BalanceEntry> balances;
  final List<Expense> expenses;

  @override
  List<Object?> get props => [group, balances, expenses];

  GroupDetailLoaded copyWith({
    Group? group,
    List<BalanceEntry>? balances,
    List<Expense>? expenses,
  }) =>
      GroupDetailLoaded(
        group: group ?? this.group,
        balances: balances ?? this.balances,
        expenses: expenses ?? this.expenses,
      );
}

class GroupDetailError extends GroupDetailState {
  const GroupDetailError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class GroupDetailLeft extends GroupDetailState {}

class GroupDetailCubit extends Cubit<GroupDetailState> {
  GroupDetailCubit(
    this._groupId,
    this._home, {
    GroupsRepository? groups,
    ExpensesRepository? expenses,
  })  : _groups = groups ?? groupsRepository,
        _expenses = expenses ?? expensesRepository,
        super(GroupDetailInitial());

  final String _groupId;
  final HomeCubit _home;
  final GroupsRepository _groups;
  final ExpensesRepository _expenses;

  Future<void> load() async {
    emit(GroupDetailLoading());
    try {
      final results = await Future.wait([
        _groups.get(_groupId),
        _groups.balances(_groupId),
        _expenses.list(_groupId),
      ]);
      if (!isClosed) {
        emit(GroupDetailLoaded(
          group: results[0] as Group,
          balances: results[1] as List<BalanceEntry>,
          expenses: results[2] as List<Expense>,
        ));
      }
    } catch (e) {
      if (!isClosed) emit(GroupDetailError(ApiFailure.from(e).message));
    }
  }

  Future<String?> updateName(String name) async {
    final prev = state;
    if (prev is! GroupDetailLoaded) return null;
    try {
      final updated = await _groups.updateName(_groupId, name);
      if (!isClosed) emit(prev.copyWith(group: updated));
      return null;
    } catch (e) {
      return ApiFailure.from(e).message;
    }
  }

  Future<String?> generateInviteCode() async {
    try {
      return await _groups.createInvite(_groupId);
    } catch (e) {
      return null;
    }
  }

  Future<String?> settle({
    required String fromUserId,
    required String toUserId,
    required double amount,
  }) async {
    try {
      await _groups.settle(
        groupId: _groupId,
        fromUserId: fromUserId,
        toUserId: toUserId,
        amount: amount,
      );
      await load();
      return null;
    } catch (e) {
      return ApiFailure.from(e).message;
    }
  }

  Future<String?> updateExpense({
    required String expenseId,
    String? name,
    double? amount,
    String? categoryId,
    String? paidBy,
    DateTime? expenseDate,
  }) async {
    final prev = state;
    if (prev is! GroupDetailLoaded) return null;
    try {
      final updated = await _expenses.update(
        groupId: _groupId,
        expenseId: expenseId,
        name: name,
        amount: amount,
        categoryId: categoryId,
        paidBy: paidBy,
        expenseDate: expenseDate,
      );
      final expenses =
          prev.expenses.map((e) => e.id == expenseId ? updated : e).toList();
      final balances = await _groups.balances(_groupId);
      if (!isClosed) emit(prev.copyWith(expenses: expenses, balances: balances));
      return null;
    } catch (e) {
      return ApiFailure.from(e).message;
    }
  }

  Future<String?> deleteExpense(String expenseId) async {
    final prev = state;
    if (prev is! GroupDetailLoaded) return null;
    try {
      await _expenses.delete(groupId: _groupId, expenseId: expenseId);
      if (!isClosed) {
        emit(prev.copyWith(
          expenses: prev.expenses.where((e) => e.id != expenseId).toList(),
        ));
      }
      final balances = await _groups.balances(_groupId);
      final current = state;
      if (!isClosed && current is GroupDetailLoaded) {
        emit(current.copyWith(balances: balances));
      }
      return null;
    } catch (e) {
      return ApiFailure.from(e).message;
    }
  }

  Future<String?> setPinned(bool isPinned) async {
    final prev = state;
    if (prev is! GroupDetailLoaded) return null;
    emit(prev.copyWith(group: prev.group.copyWith(isPinned: isPinned)));
    try {
      final updated = await _groups.setPinned(_groupId, isPinned: isPinned);
      final current = state;
      if (!isClosed && current is GroupDetailLoaded) {
        emit(current.copyWith(group: updated));
      }
      await _home.loadGroups();
      return null;
    } catch (e) {
      if (!isClosed) emit(prev);
      return ApiFailure.from(e).message;
    }
  }

  Future<String?> leaveGroup() async {
    try {
      await _groups.leave(_groupId);
      if (!isClosed) emit(GroupDetailLeft());
      return null;
    } catch (e) {
      return ApiFailure.from(e).message;
    }
  }

  Future<String?> deleteGroup() async {
    try {
      await _groups.delete(_groupId);
      if (!isClosed) emit(GroupDetailLeft());
      return null;
    } catch (e) {
      return ApiFailure.from(e).message;
    }
  }
}
