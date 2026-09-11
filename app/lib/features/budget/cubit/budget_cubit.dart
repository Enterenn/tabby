import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/models/budget.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/group.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class BudgetState extends Equatable {
  const BudgetState();
  @override
  List<Object?> get props => [];
}

class BudgetInitial extends BudgetState {
  const BudgetInitial();
}

class BudgetLoading extends BudgetState {
  const BudgetLoading();
}

class BudgetLoaded extends BudgetState {
  const BudgetLoaded({
    required this.budgets,
    required this.groups,
    required this.allCategories,
  });

  final List<Budget> budgets;
  final List<Group> groups;
  final List<Category> allCategories;

  @override
  List<Object?> get props => [budgets, groups, allCategories];
}

class BudgetError extends BudgetState {
  const BudgetError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class BudgetCubit extends Cubit<BudgetState> {
  BudgetCubit() : super(const BudgetInitial());

  Future<void> load() async {
    emit(const BudgetLoading());
    try {
      final results = await Future.wait([
        apiClient.dio.get('/budgets'),
        apiClient.dio.get('/groups'),
        apiClient.dio.get('/categories'),
      ]);

      final budgets = (results[0].data as List)
          .map((b) => Budget.fromJson(b as Map<String, dynamic>))
          .toList();

      final groups = (results[1].data as List)
          .map((g) => Group.fromJson(g as Map<String, dynamic>))
          .toList();

      final categories = (results[2].data as List)
          .map((c) => Category.fromJson(c as Map<String, dynamic>))
          .toList();

      emit(BudgetLoaded(
        budgets: budgets,
        groups: groups,
        allCategories: categories,
      ));
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  Future<bool> createBudget({
    required String groupId,
    required String categoryId,
    required double limitAmount,
  }) async {
    try {
      await apiClient.dio.post('/groups/$groupId/budgets', data: {
        'category_id': categoryId,
        'limit_amount': limitAmount,
      });
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateBudget({
    required String groupId,
    required String budgetId,
    required double limitAmount,
  }) async {
    try {
      await apiClient.dio
          .put('/groups/$groupId/budgets/$budgetId', data: {
        'limit_amount': limitAmount,
      });
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteBudget({
    required String groupId,
    required String budgetId,
  }) async {
    try {
      await apiClient.dio
          .delete('/groups/$groupId/budgets/$budgetId');
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Catégories disponibles pour créer un budget dans un groupe donné
  /// (exclut celles qui ont déjà un budget).
  List<Category> availableCategories({
    required String groupId,
    required List<Budget> budgets,
    required List<Category> allCategories,
  }) {
    final alreadyUsed = budgets
        .where((b) => b.groupId == groupId)
        .map((b) => b.category.id)
        .toSet();
    return allCategories
        .where((c) => !alreadyUsed.contains(c.id))
        .toList();
  }
}
