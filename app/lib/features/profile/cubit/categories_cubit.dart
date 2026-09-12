import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_failure.dart';
import '../../../data/repositories.dart';
import '../../../shared/models/category.dart';

class CategoriesLoadedData extends Equatable {
  const CategoriesLoadedData({
    required this.customByGroup,
    required this.groupNames,
  });

  final Map<String, List<Category>> customByGroup;
  final Map<String, String> groupNames;

  @override
  List<Object?> get props => [customByGroup, groupNames];
}

sealed class CategoriesState extends Equatable {
  const CategoriesState();
  @override
  List<Object?> get props => [];
}

class CategoriesLoading extends CategoriesState {
  const CategoriesLoading();
}

class CategoriesLoaded extends CategoriesState {
  const CategoriesLoaded(this.data);
  final CategoriesLoadedData data;
  @override
  List<Object?> get props => [data];
}

class CategoriesError extends CategoriesState {
  const CategoriesError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit({
    GroupsRepository? groups,
    CategoriesRepository? categories,
  })  : _groups = groups ?? groupsRepository,
        _categories = categories ?? categoriesRepository,
        super(const CategoriesLoading());

  final GroupsRepository _groups;
  final CategoriesRepository _categories;

  Future<void> load() async {
    emit(const CategoriesLoading());
    try {
      final groups = await _groups.list();
      final customByGroup = <String, List<Category>>{};
      final groupNames = <String, String>{};
      for (final group in groups) {
        groupNames[group.id] = group.name;
        final all = await _categories.list(groupId: group.id);
        customByGroup[group.id] = all.where((c) => !c.isDefault).toList();
      }
      if (!isClosed) {
        emit(CategoriesLoaded(CategoriesLoadedData(
          customByGroup: customByGroup,
          groupNames: groupNames,
        )));
      }
    } catch (e) {
      if (!isClosed) emit(CategoriesError(ApiFailure.from(e).message));
    }
  }

  Future<String?> delete({
    required String groupId,
    required String categoryId,
  }) async {
    final current = state;
    if (current is! CategoriesLoaded) return 'errorUnexpected';
    try {
      await _categories.delete(categoryId);
      final next = Map<String, List<Category>>.from(current.data.customByGroup);
      next[groupId] =
          [...?next[groupId]]..removeWhere((c) => c.id == categoryId);
      if (!isClosed) {
        emit(CategoriesLoaded(CategoriesLoadedData(
          customByGroup: next,
          groupNames: current.data.groupNames,
        )));
      }
      return null;
    } catch (e) {
      return ApiFailure.from(e).message;
    }
  }
}
