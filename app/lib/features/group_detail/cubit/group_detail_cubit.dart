import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/models/expense.dart';
import '../../../shared/models/group.dart';

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
  GroupDetailCubit(this._groupId) : super(GroupDetailInitial());

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

      emit(GroupDetailLoaded(group: group, balances: balances, expenses: expenses));
    } catch (e) {
      emit(GroupDetailError(e.toString()));
    }
  }

  Future<void> updateName(String name) async {
    final prev = state as GroupDetailLoaded?;
    if (prev == null) return;
    try {
      final res = await _dio.patch('/groups/$_groupId', data: {'name': name});
      final updated = Group.fromJson(res.data as Map<String, dynamic>);
      emit(prev.copyWith(group: updated));
    } catch (e) {
      emit(GroupDetailError(_errorMessage(e)));
    }
  }

  Future<String?> generateInviteCode() async {
    try {
      final res = await _dio.post('/groups/$_groupId/invite');
      return res.data['code'] as String;
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
      await _dio.post('/groups/$_groupId/settle', data: {
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'amount': amount,
      });
      await load();
      return null;
    } catch (e) {
      return _errorMessage(e);
    }
  }

  Future<String?> updateExpense({
    required String expenseId,
    String? name,
    double? amount,
    String? categoryId,
    String? paidBy,
  }) async {
    final prev = state as GroupDetailLoaded?;
    if (prev == null) return null;
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (amount != null) data['amount'] = amount;
      if (categoryId != null) data['category_id'] = categoryId;
      if (paidBy != null) data['paid_by'] = paidBy;

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
      emit(prev.copyWith(expenses: expenses, balances: balances));
      return null;
    } catch (e) {
      return _errorMessage(e);
    }
  }

  Future<String?> deleteExpense(String expenseId) async {
    final prev = state as GroupDetailLoaded?;
    if (prev == null) return null;
    try {
      await _dio.delete('/groups/$_groupId/expenses/$expenseId');
      emit(prev.copyWith(
        expenses: prev.expenses.where((e) => e.id != expenseId).toList(),
      ));
      // Recharge les balances après suppression
      final balRes = await _dio.get('/groups/$_groupId/balances');
      final balances = (balRes.data as List)
          .map((e) => BalanceEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      emit((state as GroupDetailLoaded).copyWith(balances: balances));
      return null;
    } catch (e) {
      return _errorMessage(e);
    }
  }

  Future<String?> leaveGroup() async {
    try {
      await _dio.post('/groups/$_groupId/leave');
      emit(GroupDetailLeft());
      return null;
    } catch (e) {
      return _errorMessage(e);
    }
  }

  Future<String?> deleteGroup() async {
    try {
      await _dio.delete('/groups/$_groupId');
      emit(GroupDetailLeft());
      return null;
    } catch (e) {
      return _errorMessage(e);
    }
  }

  String _errorMessage(Object e) {
    if (e is Exception) {
      final msg = e.toString();
      // Extrait le message du detail FastAPI si présent
      final match = RegExp(r'"detail":"([^"]+)"').firstMatch(msg);
      if (match != null) return match.group(1)!;
      return msg;
    }
    return e.toString();
  }
}
