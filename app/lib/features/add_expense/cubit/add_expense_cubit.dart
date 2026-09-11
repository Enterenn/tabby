import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/api/api_client.dart';
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
    required this.categories,
    required this.group,
  });

  final List<Category> categories;
  final Group group;

  @override
  List<Object?> get props => [categories, group];
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

  Future<void> load(String groupId) async {
    emit(const AddExpenseLoading());
    try {
      final results = await Future.wait([
        apiClient.dio.get('/categories', queryParameters: {'group_id': groupId}),
        apiClient.dio.get('/groups/$groupId'),
      ]);

      final categories = (results[0].data as List)
          .map((c) => Category.fromJson(c as Map<String, dynamic>))
          .toList();

      final group = Group.fromJson(results[1].data as Map<String, dynamic>);

      emit(AddExpenseReady(categories: categories, group: group));
    } catch (e) {
      emit(AddExpenseError(e.toString()));
    }
  }

  Future<bool> submit({
    required String groupId,
    required String name,
    required double amount,
    required String categoryId,
    required String paidBy,
    required DateTime expenseDate,
  }) async {
    if (state is! AddExpenseReady) return false;
    emit(const AddExpenseSubmitting());
    try {
      await apiClient.dio.post('/groups/$groupId/expenses', data: {
        'name': name,
        'amount': amount,
        'category_id': categoryId,
        'paid_by': paidBy,
        'expense_date':
            '${expenseDate.year.toString().padLeft(4, '0')}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}',
      });
      emit(const AddExpenseSuccess());
      return true;
    } catch (e) {
      final ready = state;
      // Restaurer l'état Ready pour permettre de corriger sans recharger
      emit(ready is AddExpenseReady ? ready : const AddExpenseError('Erreur lors de la création'));
      return false;
    }
  }
}
