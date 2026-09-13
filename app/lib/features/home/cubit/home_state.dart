part of 'home_cubit.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  HomeLoaded(this.groups, {this.personalExpenses = const []});
  final List<Group> groups;
  final List<PersonalExpense> personalExpenses;

  double get personalMonthTotal {
    final now = DateTime.now();
    return personalExpenses
        .where(
          (e) =>
              e.expenseDate.year == now.year && e.expenseDate.month == now.month,
        )
        .fold<double>(0, (sum, e) => sum + e.amount);
  }
}

class HomeError extends HomeState {
  HomeError(this.message);
  final String message;
}
