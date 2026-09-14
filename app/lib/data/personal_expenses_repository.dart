// The analyzer's null-aware map-element lint targets a newer Dart syntax than
// the SDK currently used by this project.
// ignore_for_file: use_null_aware_elements

import 'dart:async';

import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../shared/models/personal_expense.dart';
import 'api_date.dart';
import 'parse_list.dart';

class PersonalExpensesRepository {
  PersonalExpensesRepository({Dio? dio}) : _dio = dio ?? apiClient.dio;

  final Dio _dio;
  final _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<List<PersonalExpense>> list({int? year, int? month}) async {
    final response = await _dio.get(
      '/personal-expenses',
      queryParameters: {
        if (year != null) 'year': year,
        if (month != null) 'month': month,
      },
    );
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
    _notify();
    return PersonalExpense.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PersonalExpense> update({
    required String expenseId,
    String? name,
    double? amount,
    String? categoryId,
    DateTime? expenseDate,
  }) async {
    final response = await _dio.patch(
      '/personal-expenses/$expenseId',
      data: {
        if (name != null) 'name': name,
        if (amount != null) 'amount': amount,
        if (categoryId != null) 'category_id': categoryId,
        if (expenseDate != null) 'expense_date': formatApiDate(expenseDate),
      },
    );
    _notify();
    return PersonalExpense.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(String expenseId) async {
    await _dio.delete('/personal-expenses/$expenseId');
    _notify();
  }
}

final personalExpensesRepository = PersonalExpensesRepository();
