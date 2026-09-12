import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../shared/models/group.dart';
import 'parse_list.dart';

class GroupsRepository {
  GroupsRepository({Dio? dio}) : _dio = dio ?? apiClient.dio;

  final Dio _dio;

  Future<List<Group>> list() async {
    final response = await _dio.get('/groups');
    return parseJsonList(response.data, Group.fromJson);
  }

  Future<Group> get(String groupId) async {
    final response = await _dio.get('/groups/$groupId');
    return Group.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Group> create(String name) async {
    final response = await _dio.post('/groups', data: {'name': name});
    return Group.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Group> updateName(String groupId, String name) async {
    final response = await _dio.patch('/groups/$groupId', data: {'name': name});
    return Group.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Group> setPinned(String groupId, {required bool isPinned}) async {
    final response = await _dio.patch(
      '/groups/$groupId/pin',
      data: {'is_pinned': isPinned},
    );
    return Group.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> leave(String groupId) => _dio.post('/groups/$groupId/leave');

  Future<void> delete(String groupId) => _dio.delete('/groups/$groupId');

  Future<Group> join(String code) async {
    final response = await _dio.post('/groups/join', data: {'code': code});
    return Group.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> createInvite(String groupId) async {
    final response = await _dio.post('/groups/$groupId/invite');
    return response.data['code'] as String;
  }

  Future<List<BalanceEntry>> balances(String groupId) async {
    final response = await _dio.get('/groups/$groupId/balances');
    return parseJsonList(response.data, BalanceEntry.fromJson);
  }

  Future<void> settle({
    required String groupId,
    required String fromUserId,
    required String toUserId,
    required double amount,
  }) {
    return _dio.post('/groups/$groupId/settle', data: {
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'amount': amount,
    });
  }
}

final groupsRepository = GroupsRepository();
