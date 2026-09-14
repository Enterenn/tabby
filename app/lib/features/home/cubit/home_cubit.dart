import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_failure.dart';
import '../../../data/repositories.dart';
import '../../../shared/models/group.dart';
import '../../../shared/models/personal_expense.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    GroupsRepository? groups,
    PersonalExpensesRepository? personal,
  })  : _groups = groups ?? groupsRepository,
        _personal = personal ?? personalExpensesRepository,
        super(HomeInitial()) {
    _personalSub = _personal.changes.listen((_) {
      if (!isClosed && state is HomeLoaded) loadGroups(silent: true, force: true);
    });
  }

  final GroupsRepository _groups;
  final PersonalExpensesRepository _personal;
  StreamSubscription<void>? _personalSub;
  Future<void>? _loading;

  void reset() {
    if (!isClosed) emit(HomeInitial());
  }

  @override
  Future<void> close() {
    _personalSub?.cancel();
    return super.close();
  }

  Future<void> loadGroups({bool silent = false, bool force = false}) {
    final current = _loading;
    if (current != null) return current;

    if (!silent && !isClosed) emit(HomeLoading());
    final request = _loadGroups(silent: silent, force: force);
    _loading = request;
    return request.whenComplete(() => _loading = null);
  }

  Future<void> _loadGroups({required bool silent, required bool force}) async {
    try {
      final groupsFuture = force ? _groups.refresh() : _groups.list();
      final personalFuture = () async {
        try {
          return await _personal.list();
        } catch (_) {
          return const <PersonalExpense>[];
        }
      }();
      final groups = await groupsFuture..sort(_compareGroups);
      final personal = await personalFuture;
      if (!isClosed) emit(HomeLoaded(groups, personalExpenses: personal));
    } catch (e) {
      if (!isClosed && state is! HomeLoaded) {
        emit(HomeError(ApiFailure.from(e).message));
      }
    }
  }

  static int _compareGroups(Group a, Group b) {
    if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
    return b.createdAt.compareTo(a.createdAt);
  }
}
