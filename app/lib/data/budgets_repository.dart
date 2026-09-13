import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../shared/models/budget.dart';
import '../shared/models/spend_scope.dart';
import '../shared/models/stats.dart';
import 'parse_list.dart';

class BudgetsRepository {
  BudgetsRepository({Dio? dio}) : _dio = dio ?? apiClient.dio;

  final Dio _dio;

  Map<String, dynamic> _period({
    required int year,
    required int month,
    String? groupId,
    SpendScope scope = SpendScope.all,
  }) =>
      {
        'year': year,
        'month': month,
        'group_id': ?groupId,
        'scope': scope.apiValue,
      };

  Future<List<Budget>> list({
    required int year,
    required int month,
    String? groupId,
  }) async {
    final response = await _dio.get(
      '/budgets',
      queryParameters: _period(year: year, month: month, groupId: groupId),
    );
    return parseJsonList(response.data, Budget.fromJson);
  }

  Future<MonthStats> stats({
    required int year,
    required int month,
    String? groupId,
    SpendScope scope = SpendScope.all,
  }) async {
    final response = await _dio.get(
      '/stats',
      queryParameters: _period(
        year: year,
        month: month,
        groupId: groupId,
        scope: scope,
      ),
    );
    return MonthStats.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> create({
    required String categoryId,
    required double limitAmount,
  }) {
    return _dio.post(
      '/budgets',
      data: {'category_id': categoryId, 'limit_amount': limitAmount},
    );
  }

  Future<void> update({
    required String budgetId,
    required double limitAmount,
  }) {
    return _dio.put(
      '/budgets/$budgetId',
      data: {'limit_amount': limitAmount},
    );
  }

  Future<void> delete({required String budgetId}) {
    return _dio.delete('/budgets/$budgetId');
  }
}

final budgetsRepository = BudgetsRepository();
