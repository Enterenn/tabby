import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/models/group.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  Future<void> loadGroups() async {
    emit(HomeLoading());
    try {
      final response = await apiClient.dio.get('/groups');
      final groups = (response.data as List)
          .map((g) => Group.fromJson(g as Map<String, dynamic>))
          .toList();
      emit(HomeLoaded(groups));
    } on DioException catch (e) {
      emit(HomeError(e.response?.data?['detail']?.toString() ?? 'Erreur réseau'));
    }
  }
}
