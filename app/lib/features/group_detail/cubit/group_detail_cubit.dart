import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../shared/models/expense.dart';
import '../../../shared/models/group.dart';
import '../../home/cubit/home_cubit.dart';

// ─── States ──────────────────────────────────────────────────────────────────

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

// ─── Cubit ───────────────────────────────────────────────────────────────────

class GroupDetailCubit extends Cubit<GroupDetailState> {
  static GroupDetailCubit? _active;

  GroupDetailCubit(this._groupId) : super(GroupDetailInitial()) {
    _active = this;
  }

  static void refreshIfActive() => _active?.load();

  @override
  Future<void> close() {
    if (_active == this) _active = null;
    return super.close();
  }

  final String _groupId;
  final _dio = apiClient.dio;

  Future<void> load() async {
    emit(GroupDetailLoading());
    try {
      final results = await Future.wait([
        _dio.get('/groups/$_groupId'),
        _dio.get('/groups/$_groupId/balances'),
        _dio.get('/groups/$_groupId/expenses'),
      ]);

      final group = Group.fromJson(results[0].data as Map<String, dynamic>);
      final balances = (results[1].data as List)
          .map((e) => BalanceEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      final expenses = (results[2].data as List)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!isClosed) {
        emit(GroupDetailLoaded(group: group, balances: balances, expenses: expenses));
      }
    } catch (e) {
      if (!isClosed) emit(GroupDetailError(ApiFailure.from(e).message));
    }
  }

  Future<String?> updateName(String name) async {
    final prev = state;
    if (prev is! GroupDetailLoaded) return null;
    try {
      final res = await _dio.patch('/groups/$_groupId', data: {'name': name});
      final updated = Group.fromJson(res.data as Map<String, dynamic>);
      if (!isClosed) emit(prev.copyWith(group: updated));
      return null;
    } catch (e) {
      return ApiFailure.from(e).message;
    }
  }

  Future<String?> generateInviteCode() async {
    try {
      final res = await _dio.post('/groups/$_groupId/invite');
      return res.data['code'] as String;
    } catch (_) {
      return null;
    }
  }

  Future<String?> settle({
    required String fromUserId,
    required String toUserId,
    required double amount,
  }) async {
    try {
      await _dio.post('/groups/$_groupId/settle', data: {
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'amount': amount,
      });
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
    final prev = state as GroupDetailLoaded?;
    if (prev == null) return null;
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (amount != null) data['amount'] = amount;
      if (categoryId != null) data['category_id'] = categoryId;
      if (paidBy != null) data['paid_by'] = paidBy;
      if (expenseDate != null) {
        data['expense_date'] =
            '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}';
      }

      final res = await _dio.patch(
        '/groups/$_groupId/expenses/$expenseId',
        data: data,
      );
      final updated = Expense.fromJson(res.data as Map<String, dynamic>);
      final expenses = prev.expenses.map((e) => e.id == expenseId ? updated : e).toList();
      // Recalcule les balances
      final balRes = await _dio.get('/groups/$_groupId/balances');
      final balances = (balRes.data as List)
          .map((e) => BalanceEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!isClosed) emit(prev.copyWith(expenses: expenses, balances: balances));
      return null;
    } catch (e) {
      return ApiFailure.from(e).message;
    }
  }

  Future<String?> deleteExpense(String expenseId) async {
    final prev = state as GroupDetailLoaded?;
    if (prev == null) return null;
    try {
      await _dio.delete('/groups/$_groupId/expenses/$expenseId');
      if (!isClosed) {
        emit(prev.copyWith(
          expenses: prev.expenses.where((e) => e.id != expenseId).toList(),
        ));
      }
      final balRes = await _dio.get('/groups/$_groupId/balances');
      final balances = (balRes.data as List)
          .map((e) => BalanceEntry.fromJson(e as Map<String, dynamic>))
          .toList();
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
    final prev = state as GroupDetailLoaded?;
    if (prev == null) return null;
    emit(prev.copyWith(group: prev.group.copyWith(isPinned: isPinned)));
    try {
      final res = await _dio.patch(
        '/groups/$_groupId/pin',
        data: {'is_pinned': isPinned},
      );
      final updated = Group.fromJson(res.data as Map<String, dynamic>);
      final current = state;
      if (!isClosed && current is GroupDetailLoaded) {
        emit(current.copyWith(group: updated));
      }
      HomeCubit.refreshIfActive();
      return null;
    } catch (e) {
      if (!isClosed) emit(prev);
      return ApiFailure.from(e).message;
    }
  }

  Future<String?> leaveGroup() async {
    try {
      await _dio.post('/groups/$_groupId/leave');
      if (!isClosed) emit(GroupDetailLeft());
      return null;
    } catch (e) {
      return ApiFailure.from(e).message;
    }
  }

  Future<String?> deleteGroup() async {
    try {
      await _dio.delete('/groups/$_groupId');
      if (!isClosed) emit(GroupDetailLeft());
      return null;
    } catch (e) {
      return ApiFailure.from(e).message;
    }
  }
}
