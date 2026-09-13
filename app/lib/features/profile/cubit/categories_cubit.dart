import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_failure.dart';
import '../../../data/repositories.dart';
import '../../../shared/models/category.dart';

sealed class CategoriesState extends Equatable {
  const CategoriesState();
  @override
  List<Object?> get props => [];
}

class CategoriesLoading extends CategoriesState {
  const CategoriesLoading();
}

class CategoriesLoaded extends CategoriesState {
  const CategoriesLoaded(this.custom);
  final List<Category> custom;
  @override
  List<Object?> get props => [custom];
}

class CategoriesError extends CategoriesState {
  const CategoriesError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit({
    CategoriesRepository? categories,
  })  : _categories = categories ?? categoriesRepository,
        super(const CategoriesLoading());

  final CategoriesRepository _categories;

  Future<void> load() async {
    emit(const CategoriesLoading());
    try {
      final all = await _categories.list();
      if (!isClosed) {
        emit(CategoriesLoaded(all.where((c) => !c.isDefault).toList()));
      }
    } catch (e) {
      if (!isClosed) emit(CategoriesError(ApiFailure.from(e).message));
    }
  }

  Future<String?> delete({required String categoryId}) async {
    final current = state;
    if (current is! CategoriesLoaded) return 'errorUnexpected';
    try {
      await _categories.delete(categoryId);
      if (!isClosed) {
        emit(CategoriesLoaded(
          [...current.custom]..removeWhere((c) => c.id == categoryId),
        ));
      }
      return null;
    } catch (e) {
      return ApiFailure.from(e).message;
    }
  }
}
