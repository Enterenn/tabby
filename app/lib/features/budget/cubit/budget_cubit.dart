import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_failure.dart';
import '../../../data/repositories.dart';
import '../../../shared/models/budget.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/group.dart';
import '../../../shared/models/spend_scope.dart';
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
    this.selectedScope = SpendScope.all,
  });

  final List<Budget> budgets;
  final List<Group> groups;
  final List<Category> allCategories;
  final MonthStats stats;
  final int selectedYear;
  final int selectedMonth;
  final String? selectedGroupId; // null = tous les groupes
  final String? selectedCategoryId;
  final SpendScope selectedScope;

  BudgetLoaded copyWith({
    List<Budget>? budgets,
    List<Group>? groups,
    List<Category>? allCategories,
    MonthStats? stats,
    int? selectedYear,
    int? selectedMonth,
    String? selectedGroupId,
    String? selectedCategoryId,
    SpendScope? selectedScope,
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
    selectedScope: selectedScope ?? this.selectedScope,
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
    selectedScope,
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
      final results = await Future.wait([
        budgetsRepository.list(
          year: targetYear,
          month: targetMonth,
          groupId: targetGroup,
        ),
        groupsRepository.list(),
        categoriesRepository.list(),
        budgetsRepository.stats(
          year: targetYear,
          month: targetMonth,
          groupId: targetGroup,
          scope: prev?.selectedScope ?? SpendScope.all,
        ),
      ]);

      final budgets = results[0] as List<Budget>;
      final groups = results[1] as List<Group>;
      final categories = results[2] as List<Category>;
      final stats = results[3] as MonthStats;

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
            selectedScope: prev?.selectedScope ?? SpendScope.all,
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

  Future<void> selectScope(SpendScope scope) async {
    if (state is! BudgetLoaded) return;
    final s = state as BudgetLoaded;
    if (s.selectedScope == scope) return;
    emit(s.copyWith(selectedScope: scope));
    try {
      final stats = await budgetsRepository.stats(
        year: s.selectedYear,
        month: s.selectedMonth,
        groupId: s.selectedGroupId,
        scope: scope,
      );
      if (!isClosed && state is BudgetLoaded) {
        emit((state as BudgetLoaded).copyWith(stats: stats));
      }
    } catch (e) {
      if (!isClosed) emit(BudgetError(ApiFailure.from(e).message));
    }
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
    required String categoryId,
    required double limitAmount,
  }) async {
    try {
      await budgetsRepository.create(
        categoryId: categoryId,
        limitAmount: limitAmount,
      );
      final s = state is BudgetLoaded ? state as BudgetLoaded : null;
      await load(
        year: s?.selectedYear,
        month: s?.selectedMonth,
        groupId: s?.selectedGroupId,
      );
      return true;
    } catch (e) {
      if (!isClosed) emit(BudgetError(ApiFailure.from(e).message));
      return false;
    }
  }

  Future<bool> updateBudget({
    required String budgetId,
    required double limitAmount,
  }) async {
    try {
      await budgetsRepository.update(
        budgetId: budgetId,
        limitAmount: limitAmount,
      );
      final s = state is BudgetLoaded ? state as BudgetLoaded : null;
      await load(
        year: s?.selectedYear,
        month: s?.selectedMonth,
        groupId: s?.selectedGroupId,
      );
      return true;
    } catch (e) {
      if (!isClosed) emit(BudgetError(ApiFailure.from(e).message));
      return false;
    }
  }

  Future<bool> deleteBudget({
    required String budgetId,
  }) async {
    try {
      await budgetsRepository.delete(budgetId: budgetId);
      final s = state is BudgetLoaded ? state as BudgetLoaded : null;
      await load(
        year: s?.selectedYear,
        month: s?.selectedMonth,
        groupId: s?.selectedGroupId,
      );
      return true;
    } catch (e) {
      if (!isClosed) emit(BudgetError(ApiFailure.from(e).message));
      return false;
    }
  }

  List<Category> availableCategories({
    required List<Budget> budgets,
    required List<Category> allCategories,
  }) {
    final alreadyUsed = budgets.map((b) => b.category.id).toSet();
    return allCategories.where((c) => !alreadyUsed.contains(c.id)).toList();
  }
}
