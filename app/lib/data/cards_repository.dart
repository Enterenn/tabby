import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../shared/models/loyalty_card.dart';
import 'parse_list.dart';

class CardsRepository {
  CardsRepository({Dio? dio}) : _dio = dio ?? apiClient.dio;

  final Dio _dio;

  Future<List<LoyaltyCard>> list() async {
    final response = await _dio.get('/loyalty-cards');
    return parseJsonList(response.data, LoyaltyCard.fromJson);
  }

  Future<void> add({
    required String brandName,
    required String codeType,
    required String codeValue,
    String? color,
    String? brandId,
  }) {
    return _dio.post(
      '/loyalty-cards',
      data: {
        'brand_name': brandName,
        'code_type': codeType,
        'code_value': codeValue,
        'color': ?color,
        'brand_id': ?brandId,
      },
    );
  }

  Future<void> update({
    required String id,
    required String brandName,
    required String codeType,
    required String codeValue,
    String? color,
    String? brandId,
  }) {
    return _dio.patch(
      '/loyalty-cards/$id',
      data: {
        'brand_name': brandName,
        'code_type': codeType,
        'code_value': codeValue,
        'color': color,
        'brand_id': brandId,
      },
    );
  }

  Future<void> delete(String id) => _dio.delete('/loyalty-cards/$id');

  Future<void> reorder(List<LoyaltyCard> cards) {
    return _dio.put(
      '/loyalty-cards/reorder',
      data: cards
          .asMap()
          .entries
          .map((e) => {'id': e.value.id, 'sort_order': e.key})
          .toList(),
    );
  }
}

final cardsRepository = CardsRepository();
