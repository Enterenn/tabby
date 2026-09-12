import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../shared/models/budget.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/group.dart';
import '../../../shared/models/stats.dart';

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
    required this.stats,
    required this.selectedYear,
    required this.selectedMonth,
    this.selectedGroupId,
    this.selectedCategoryId,
  });

  final List<Budget> budgets;
  final List<Group> groups;
  final List<Category> allCategories;
  final MonthStats stats;
  final int selectedYear;
  final int selectedMonth;
  final String? selectedGroupId; // null = tous les groupes
  final String? selectedCategoryId;

  BudgetLoaded copyWith({
    List<Budget>? budgets,
    List<Group>? groups,
    List<Category>? allCategories,
    MonthStats? stats,
    int? selectedYear,
    int? selectedMonth,
    String? selectedGroupId,
    String? selectedCategoryId,
    bool clearGroup = false,
    bool clearCategory = false,
  }) => BudgetLoaded(
    budgets: budgets ?? this.budgets,
    groups: groups ?? this.groups,
    allCategories: allCategories ?? this.allCategories,
    stats: stats ?? this.stats,
    selectedYear: selectedYear ?? this.selectedYear,
    selectedMonth: selectedMonth ?? this.selectedMonth,
    selectedGroupId: clearGroup
        ? null
        : (selectedGroupId ?? this.selectedGroupId),
    selectedCategoryId: clearCategory
        ? null
        : (selectedCategoryId ?? this.selectedCategoryId),
  );

  int? get selectedCategoryIndex {
    if (selectedCategoryId == null) return null;
    final index = stats.categories.indexWhere(
      (c) => c.category.id == selectedCategoryId,
    );
    return index < 0 ? null : index;
  }

  @override
  List<Object?> get props => [
    budgets,
    groups,
    allCategories,
    stats,
    selectedYear,
    selectedMonth,
    selectedGroupId,
    selectedCategoryId,
  ];
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

  Future<void> load({
    int? year,
    int? month,
    String? groupId,
    bool clearGroup = false,
  }) async {
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;

    // Conserver les sélections si déjà chargé
    final prev = state is BudgetLoaded ? state as BudgetLoaded : null;
    final targetYear = year ?? prev?.selectedYear ?? y;
    final targetMonth = month ?? prev?.selectedMonth ?? m;
    // clearGroup=true → null explicite, sinon on garde l'ancienne sélection
    final targetGroup = clearGroup ? null : (groupId ?? prev?.selectedGroupId);

    if (prev == null) emit(const BudgetLoading());
    try {
      final queryParams = <String, dynamic>{
        'year': targetYear,
        'month': targetMonth,
        'group_id': ?targetGroup,
      };

      final results = await Future.wait([
        apiClient.dio.get('/budgets', queryParameters: queryParams),
        apiClient.dio.get('/groups'),
        apiClient.dio.get('/categories'),
        apiClient.dio.get('/stats', queryParameters: queryParams),
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
      final stats = MonthStats.fromJson(
        results[3].data as Map<String, dynamic>,
      );

      if (!isClosed) {
        emit(
          BudgetLoaded(
            budgets: budgets,
            groups: groups,
            allCategories: categories,
            stats: stats,
            selectedYear: targetYear,
            selectedMonth: targetMonth,
            selectedGroupId: targetGroup,
            selectedCategoryId: prev?.selectedCategoryId,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) emit(BudgetError(ApiFailure.from(e).message));
    }
  }

  void prevMonth() {
    if (state is! BudgetLoaded) return;
    final s = state as BudgetLoaded;
    final dt = DateTime(s.selectedYear, s.selectedMonth - 1);
    load(year: dt.year, month: dt.month, groupId: s.selectedGroupId);
  }

  void nextMonth() {
    if (state is! BudgetLoaded) return;
    final s = state as BudgetLoaded;
    final now = DateTime.now();
    if (s.selectedYear >= now.year && s.selectedMonth >= now.month) return;
    final dt = DateTime(s.selectedYear, s.selectedMonth + 1);
    load(year: dt.year, month: dt.month, groupId: s.selectedGroupId);
  }

  void selectGroup(String? groupId) {
    if (state is! BudgetLoaded) return;
    final s = state as BudgetLoaded;
    load(
      year: s.selectedYear,
      month: s.selectedMonth,
      groupId: groupId,
      clearGroup: groupId == null,
    );
  }

  void selectCategory(String? categoryId) {
    if (state is! BudgetLoaded) return;
    final s = state as BudgetLoaded;
    if (categoryId == null || s.selectedCategoryId == categoryId) {
      emit(s.copyWith(clearCategory: true));
      return;
    }
    emit(s.copyWith(selectedCategoryId: categoryId));
  }

  Future<bool> createBudget({
    required String groupId,
    required String categoryId,
    required double limitAmount,
  }) async {
    try {
      await apiClient.dio.post(
        '/groups/$groupId/budgets',
        data: {'category_id': categoryId, 'limit_amount': limitAmount},
      );
      final s = state is BudgetLoaded ? state as BudgetLoaded : null;
      await load(
        year: s?.selectedYear,
        month: s?.selectedMonth,
        groupId: s?.selectedGroupId,
      );
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
      await apiClient.dio.put(
        '/groups/$groupId/budgets/$budgetId',
        data: {'limit_amount': limitAmount},
      );
      final s = state is BudgetLoaded ? state as BudgetLoaded : null;
      await load(
        year: s?.selectedYear,
        month: s?.selectedMonth,
        groupId: s?.selectedGroupId,
      );
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
      await apiClient.dio.delete('/groups/$groupId/budgets/$budgetId');
      final s = state is BudgetLoaded ? state as BudgetLoaded : null;
      await load(
        year: s?.selectedYear,
        month: s?.selectedMonth,
        groupId: s?.selectedGroupId,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  List<Category> availableCategories({
    required String groupId,
    required List<Budget> budgets,
    required List<Category> allCategories,
  }) {
    final alreadyUsed = budgets
        .where((b) => b.groupId == groupId)
        .map((b) => b.category.id)
        .toSet();
    return allCategories.where((c) => !alreadyUsed.contains(c.id)).toList();
  }
}
