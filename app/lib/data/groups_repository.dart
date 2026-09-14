import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/cache/memory_cache.dart';
import '../shared/models/group.dart';
import 'parse_list.dart';

class GroupsRepository {
  GroupsRepository({Dio? dio}) : _dio = dio ?? apiClient.dio;

  final Dio _dio;
  final _listCache = MemoryCache<List<Group>>();
  final _groupCache = <String, MemoryCache<Group>>{};

  Future<List<Group>> list() => _listCache.getOrLoad(() async {
        final response = await _dio.get('/groups');
        return parseJsonList(response.data, Group.fromJson);
      });

  Future<List<Group>> refresh() => _listCache.getOrLoad(() async {
        final response = await _dio.get('/groups');
        return parseJsonList(response.data, Group.fromJson);
      }, force: true);

  Future<Group> get(String groupId) {
    final cache = _groupCache.putIfAbsent(groupId, MemoryCache<Group>.new);
    return cache.getOrLoad(() async {
      final response = await _dio.get('/groups/$groupId');
      return Group.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<Group> refreshGroup(String groupId) {
    final cache = _groupCache.putIfAbsent(groupId, MemoryCache<Group>.new);
    return cache.getOrLoad(() async {
      final response = await _dio.get('/groups/$groupId');
      return Group.fromJson(response.data as Map<String, dynamic>);
    }, force: true);
  }

  void invalidate({String? groupId}) {
    if (groupId == null) {
      _listCache.invalidate();
      for (final cache in _groupCache.values) {
        cache.invalidate();
      }
      return;
    }
    _listCache.invalidate();
    _groupCache[groupId]?.invalidate();
  }

  Future<Group> create(String name) async {
    final response = await _dio.post('/groups', data: {'name': name});
    final group = Group.fromJson(response.data as Map<String, dynamic>);
    invalidate();
    return group;
  }

  Future<Group> updateName(String groupId, String name) async {
    final response = await _dio.patch('/groups/$groupId', data: {'name': name});
    final group = Group.fromJson(response.data as Map<String, dynamic>);
    invalidate(groupId: groupId);
    _groupCache.putIfAbsent(groupId, MemoryCache<Group>.new).set(group);
    return group;
  }

  Future<Group> setPinned(String groupId, {required bool isPinned}) async {
    final response = await _dio.patch(
      '/groups/$groupId/pin',
      data: {'is_pinned': isPinned},
    );
    final group = Group.fromJson(response.data as Map<String, dynamic>);
    invalidate(groupId: groupId);
    return group;
  }

  Future<void> leave(String groupId) async {
    await _dio.post('/groups/$groupId/leave');
    invalidate(groupId: groupId);
  }

  Future<void> delete(String groupId) async {
    await _dio.delete('/groups/$groupId');
    invalidate(groupId: groupId);
  }

  Future<Group> join(String code) async {
    final response = await _dio.post('/groups/join', data: {'code': code});
    final group = Group.fromJson(response.data as Map<String, dynamic>);
    invalidate();
    return group;
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
  }) async {
    await _dio.post('/groups/$groupId/settle', data: {
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'amount': amount,
    });
    invalidate(groupId: groupId);
  }
}

final groupsRepository = GroupsRepository();
