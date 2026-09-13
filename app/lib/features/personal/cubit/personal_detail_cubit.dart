import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_failure.dart';
import '../../../data/repositories.dart';
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
  const PersonalDetailLoaded({required this.expenses});

  final List<PersonalExpense> expenses;

  double get total => expenses.fold(0, (sum, e) => sum + e.amount);

  @override
  List<Object?> get props => [expenses];
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
  })  : _personal = personal ?? personalExpensesRepository,
        super(const PersonalDetailLoading()) {
    _sub = _personal.changes.listen((_) {
      if (!isClosed) load();
    });
  }

  final PersonalExpensesRepository _personal;
  StreamSubscription<void>? _sub;

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }

  Future<void> load() async {
    final keep = state is PersonalDetailLoaded;
    if (!keep) emit(const PersonalDetailLoading());
    try {
      final expenses = List<PersonalExpense>.from(await _personal.list())
        ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
      if (!isClosed) emit(PersonalDetailLoaded(expenses: expenses));
    } catch (e) {
      if (!isClosed) emit(PersonalDetailError(ApiFailure.from(e).message));
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
