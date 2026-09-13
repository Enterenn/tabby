import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../shared/models/personal_expense.dart';
import 'api_date.dart';
import 'parse_list.dart';

class PersonalExpensesRepository {
  PersonalExpensesRepository({Dio? dio}) : _dio = dio ?? apiClient.dio;

  final Dio _dio;

  Future<List<PersonalExpense>> list() async {
    final response = await _dio.get('/personal-expenses');
    return parseJsonList(response.data, PersonalExpense.fromJson);
  }

  Future<PersonalExpense> create({
    required String name,
    required double amount,
    required String categoryId,
    required DateTime expenseDate,
  }) async {
    final response = await _dio.post(
      '/personal-expenses',
      data: {
        'name': name,
        'amount': amount,
        'category_id': categoryId,
        'expense_date': formatApiDate(expenseDate),
      },
    );
    return PersonalExpense.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(String expenseId) =>
      _dio.delete('/personal-expenses/$expenseId');
}

final personalExpensesRepository = PersonalExpensesRepository();
