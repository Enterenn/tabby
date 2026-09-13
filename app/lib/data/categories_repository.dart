import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../shared/models/category.dart';
import 'parse_list.dart';

class CategoriesRepository {
  CategoriesRepository({Dio? dio}) : _dio = dio ?? apiClient.dio;

  final Dio _dio;

  Future<List<Category>> list({String? groupId}) async {
    final response = await _dio.get(
      '/categories',
      queryParameters: {'group_id': ?groupId},
    );
    return parseJsonList(response.data, Category.fromJson);
  }

  Future<Category> create({
    String? groupId,
    required String name,
    required String icon,
    required String color,
  }) async {
    final response = await _dio.post('/categories', data: {
      'group_id': ?groupId,
      'name': name,
      'icon': icon,
      'color': color,
    });
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(String categoryId) =>
      _dio.delete('/categories/$categoryId');
}

final categoriesRepository = CategoriesRepository();
