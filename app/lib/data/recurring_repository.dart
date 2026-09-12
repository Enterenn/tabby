import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../shared/models/recurring_expense.dart';
import 'parse_list.dart';

class RecurringRepository {
  RecurringRepository({Dio? dio}) : _dio = dio ?? apiClient.dio;

  final Dio _dio;

  Future<List<RecurringExpense>> list() async {
    final response = await _dio.get('/recurring-expenses');
    return parseJsonList(response.data, RecurringExpense.fromJson);
  }

  Future<void> create({
    required String groupId,
    required String name,
    required double amount,
    required String categoryId,
    required String paidBy,
    required int dayOfPeriod,
  }) {
    return _dio.post('/groups/$groupId/recurring-expenses', data: {
      'name': name,
      'amount': amount,
      'category_id': categoryId,
      'paid_by': paidBy,
      'day_of_period': dayOfPeriod,
      'frequency': 'monthly',
    });
  }

  Future<RecurringExpense> toggle({
    required String groupId,
    required String id,
  }) async {
    final response =
        await _dio.patch('/groups/$groupId/recurring-expenses/$id/toggle');
    return RecurringExpense.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete({required String groupId, required String id}) {
    return _dio.delete('/groups/$groupId/recurring-expenses/$id');
  }
}

final recurringRepository = RecurringRepository();
