part of 'home_cubit.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  HomeLoaded(this.groups);
  final List<Group> groups;
}

class HomeError extends HomeState {
  HomeError(this.message);
  final String message;
}
