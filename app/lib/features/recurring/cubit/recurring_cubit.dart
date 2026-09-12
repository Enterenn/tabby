import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_failure.dart';
import '../../../data/repositories.dart';
import '../../../shared/models/recurring_expense.dart';

sealed class RecurringState extends Equatable {
  const RecurringState();
  @override
  List<Object?> get props => [];
}

class RecurringLoading extends RecurringState {
  const RecurringLoading();
}

class RecurringLoaded extends RecurringState {
  const RecurringLoaded(this.items);
  final List<RecurringExpense> items;
  @override
  List<Object?> get props => [items];
}

class RecurringError extends RecurringState {
  const RecurringError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class RecurringCubit extends Cubit<RecurringState> {
  RecurringCubit({RecurringRepository? recurring})
      : _recurring = recurring ?? recurringRepository,
        super(const RecurringLoading());

  final RecurringRepository _recurring;

  Future<void> load() async {
    emit(const RecurringLoading());
    try {
      final items = await _recurring.list();
      if (!isClosed) emit(RecurringLoaded(items));
    } catch (e) {
      if (!isClosed) emit(RecurringError(ApiFailure.from(e).message));
    }
  }

  Future<String?> toggle(RecurringExpense item) async {
    final current = state;
    if (current is! RecurringLoaded) return 'errorUnexpected';
    try {
      final updated =
          await _recurring.toggle(groupId: item.groupId, id: item.id);
      if (!isClosed) {
        emit(RecurringLoaded([
          for (final existing in current.items)
            if (existing.id == item.id) updated else existing,
        ]));
      }
      return null;
    } catch (e) {
      return ApiFailure.from(e).message;
    }
  }

  Future<String?> delete(RecurringExpense item) async {
    final current = state;
    if (current is! RecurringLoaded) return 'errorUnexpected';
    try {
      await _recurring.delete(groupId: item.groupId, id: item.id);
      if (!isClosed) {
        emit(RecurringLoaded(
          current.items.where((e) => e.id != item.id).toList(),
        ));
      }
      return null;
    } catch (e) {
      return ApiFailure.from(e).message;
    }
  }
}
