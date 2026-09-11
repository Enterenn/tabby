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

  AddExpenseReady copyWith({
    List<Category>? categories,
    Group? group,
  }) =>
      AddExpenseReady(
        categories: categories ?? this.categories,
        group: group ?? this.group,
      );

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
    if (groupId.isEmpty) {
      emit(const AddExpenseError('Aucun groupe sélectionné'));
      return;
    }
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

  /// Ajoute une catégorie custom et rafraîchit la liste.
  Future<Category?> createCategory({
    required String groupId,
    required String name,
    required String icon,
    required String color,
  }) async {
    final current = state;
    if (current is! AddExpenseReady) return null;
    try {
      final response = await apiClient.dio.post('/categories', data: {
        'group_id': groupId,
        'name': name,
        'icon': icon,
        'color': color,
      });
      final newCat = Category.fromJson(response.data as Map<String, dynamic>);
      emit(current.copyWith(categories: [...current.categories, newCat]));
      return newCat;
    } catch (_) {
      return null;
    }
  }

  Future<bool> submit({
    required String groupId,
    required String name,
    required double amount,
    required String categoryId,
    required String paidBy,
    required DateTime expenseDate,
    // null = répartition égale, non-null = personnalisée
    List<Map<String, dynamic>>? customSplits,
  }) async {
    final current = state;
    if (current is! AddExpenseReady) return false;
    emit(const AddExpenseSubmitting());

    final dateStr =
        '${expenseDate.year.toString().padLeft(4, '0')}-'
        '${expenseDate.month.toString().padLeft(2, '0')}-'
        '${expenseDate.day.toString().padLeft(2, '0')}';

    final body = <String, dynamic>{
      'name': name,
      'amount': amount,
      'category_id': categoryId,
      'paid_by': paidBy,
      'expense_date': dateStr,
    };

    if (customSplits != null) {
      body['split_type'] = 'custom';
      body['splits'] = customSplits;
    } else {
      body['split_type'] = 'equal';
    }

    try {
      await apiClient.dio.post('/groups/$groupId/expenses', data: body);
      emit(const AddExpenseSuccess());
      return true;
    } catch (_) {
      emit(current); // restaure Ready pour corriger sans recharger
      return false;
    }
  }
}
