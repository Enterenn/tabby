import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_failure.dart';
import '../../../data/repositories.dart';
import '../../../shared/models/group.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({GroupsRepository? groups})
      : _groups = groups ?? groupsRepository,
        super(HomeInitial());

  final GroupsRepository _groups;

  void reset() {
    if (!isClosed) emit(HomeInitial());
  }

  Future<void> loadGroups() async {
    emit(HomeLoading());
    try {
      final groups = await _groups.list()..sort(_compareGroups);
      if (!isClosed) emit(HomeLoaded(groups));
    } catch (e) {
      if (!isClosed) emit(HomeError(ApiFailure.from(e).message));
    }
  }

  static int _compareGroups(Group a, Group b) {
    if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
    return b.createdAt.compareTo(a.createdAt);
  }
}
