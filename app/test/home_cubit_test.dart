import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabby/data/groups_repository.dart';
import 'package:tabby/features/home/cubit/home_cubit.dart';
import 'package:tabby/shared/models/group.dart';

class _FakeGroupsRepository extends GroupsRepository {
  _FakeGroupsRepository(this.items) : super(dio: Dio());

  final List<Group> items;

  @override
  Future<List<Group>> list() async => items;
}

class _FailingGroupsRepository extends GroupsRepository {
  _FailingGroupsRepository() : super(dio: Dio());

  @override
  Future<List<Group>> list() {
    throw DioException(
      requestOptions: RequestOptions(path: '/groups'),
      type: DioExceptionType.connectionError,
    );
  }
}

Group _group(String id, {bool pinned = false, DateTime? createdAt}) {
  return Group(
    id: id,
    name: id,
    createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
    members: const [],
    balance: 0,
    isPinned: pinned,
  );
}

void main() {
  test('pins first then sorts by newest', () async {
    final older = _group('a', createdAt: DateTime.utc(2026, 1, 1));
    final newer = _group('b', createdAt: DateTime.utc(2026, 2, 1));
    final pinned = _group(
      'c',
      pinned: true,
      createdAt: DateTime.utc(2025, 1, 1),
    );
    final cubit = HomeCubit(
      groups: _FakeGroupsRepository([older, newer, pinned]),
    );

    await cubit.loadGroups();
    final state = cubit.state;
    expect(state, isA<HomeLoaded>());
    expect(
      (state as HomeLoaded).groups.map((g) => g.id).toList(),
      ['c', 'b', 'a'],
    );
    await cubit.close();
  });

  test('maps a network failure', () async {
    final cubit = HomeCubit(groups: _FailingGroupsRepository());
    await cubit.loadGroups();
    expect(cubit.state, isA<HomeError>());
    expect((cubit.state as HomeError).message, 'errorNetwork');
    await cubit.close();
  });

  test('reset returns to initial', () async {
    final cubit = HomeCubit(groups: _FakeGroupsRepository([_group('a')]));
    await cubit.loadGroups();
    cubit.reset();
    expect(cubit.state, isA<HomeInitial>());
    await cubit.close();
  });
}
