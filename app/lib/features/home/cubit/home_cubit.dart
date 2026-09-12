import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/models/group.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  static HomeCubit? _active;

  HomeCubit() : super(HomeInitial()) {
    _active = this;
  }

  static void refreshIfActive() => _active?.loadGroups();

  @override
  Future<void> close() {
    if (_active == this) _active = null;
    return super.close();
  }

  Future<void> loadGroups() async {
    emit(HomeLoading());
    try {
      final response = await apiClient.dio.get('/groups');
      final groups = (response.data as List)
          .map((g) => Group.fromJson(g as Map<String, dynamic>))
          .toList()
        ..sort(_compareGroups);
      emit(HomeLoaded(groups));
    } on DioException catch (e) {
      emit(HomeError(e.response?.data?['detail']?.toString() ?? 'errorNetwork'));
    }
  }

  static int _compareGroups(Group a, Group b) {
    if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
    return b.createdAt.compareTo(a.createdAt);
  }
}
