import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../shared/models/expense.dart';
import 'api_date.dart';
import 'parse_list.dart';

class ExpensesRepository {
  ExpensesRepository({Dio? dio}) : _dio = dio ?? apiClient.dio;

  final Dio _dio;

  Future<List<Expense>> list(String groupId) async {
    final response = await _dio.get('/groups/$groupId/expenses');
    return parseJsonList(response.data, Expense.fromJson);
  }

  Future<Expense> create({
    required String groupId,
    required String name,
    required double amount,
    required String categoryId,
    required String paidBy,
    required DateTime expenseDate,
    List<Map<String, dynamic>>? customSplits,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'amount': amount,
      'category_id': categoryId,
      'paid_by': paidBy,
      'expense_date': formatApiDate(expenseDate),
      'split_type': customSplits != null ? 'custom' : 'equal',
      'splits': ?customSplits,
    };
    final response = await _dio.post('/groups/$groupId/expenses', data: body);
    return Expense.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Expense> update({
    required String groupId,
    required String expenseId,
    String? name,
    double? amount,
    String? categoryId,
    String? paidBy,
    DateTime? expenseDate,
  }) async {
    final data = <String, dynamic>{
      'name': ?name,
      'amount': ?amount,
      'category_id': ?categoryId,
      'paid_by': ?paidBy,
      if (expenseDate != null) 'expense_date': formatApiDate(expenseDate),
    };
    final response = await _dio.patch(
      '/groups/$groupId/expenses/$expenseId',
      data: data,
    );
    return Expense.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete({required String groupId, required String expenseId}) {
    return _dio.delete('/groups/$groupId/expenses/$expenseId');
  }
}

final expensesRepository = ExpensesRepository();
