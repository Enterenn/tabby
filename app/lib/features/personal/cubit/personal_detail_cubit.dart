import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_failure.dart';
import '../../../data/repositories.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/personal_expense.dart';

abstract class PersonalDetailState extends Equatable {
  const PersonalDetailState();
  @override
  List<Object?> get props => [];
}

class PersonalDetailLoading extends PersonalDetailState {
  const PersonalDetailLoading();
}

class PersonalDetailLoaded extends PersonalDetailState {
  const PersonalDetailLoaded({
    required this.expenses,
    required this.categories,
  });

  final List<PersonalExpense> expenses;
  final List<Category> categories;

  double get total => expenses.fold(0, (sum, e) => sum + e.amount);

  @override
  List<Object?> get props => [expenses, categories];
}

class PersonalDetailError extends PersonalDetailState {
  const PersonalDetailError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class PersonalDetailCubit extends Cubit<PersonalDetailState> {
  PersonalDetailCubit({
    PersonalExpensesRepository? personal,
    CategoriesRepository? categories,
  })  : _personal = personal ?? personalExpensesRepository,
        _categories = categories ?? categoriesRepository,
        super(const PersonalDetailLoading()) {
    _sub = _personal.changes.listen((_) {
      if (!isClosed) load();
    });
  }

  final PersonalExpensesRepository _personal;
  final CategoriesRepository _categories;
  StreamSubscription<void>? _sub;

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }

  Future<void> load() async {
    final keep = state is PersonalDetailLoaded
        ? state as PersonalDetailLoaded
        : null;
    if (keep == null) emit(const PersonalDetailLoading());
    try {
      final results = await Future.wait([
        _personal.list(),
        _categories.list(),
      ]);
      final expenses = List<PersonalExpense>.from(
        results[0] as List<PersonalExpense>,
      )..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
      if (!isClosed) {
        emit(
          PersonalDetailLoaded(
            expenses: expenses,
            categories: results[1] as List<Category>,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) emit(PersonalDetailError(ApiFailure.from(e).message));
    }
  }

  Future<String?> updateExpense({
    required String expenseId,
    required String name,
    required double amount,
    required String categoryId,
    required DateTime expenseDate,
  }) async {
    try {
      await _personal.update(
        expenseId: expenseId,
        name: name,
        amount: amount,
        categoryId: categoryId,
        expenseDate: expenseDate,
      );
      return null;
    } catch (e) {
      return ApiFailure.from(e).message;
    }
  }

  Future<String?> deleteExpense(String expenseId) async {
    try {
      await _personal.delete(expenseId);
      return null;
    } catch (e) {
      return ApiFailure.from(e).message;
    }
  }
}
