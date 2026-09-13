import 'package:equatable/equatable.dart';
import 'category.dart';

class RecurringExpense extends Equatable {
  const RecurringExpense({
    required this.id,
    required this.groupId,
    required this.groupName,
    this.isPersonal = false,
    required this.name,
    required this.amount,
    required this.category,
    required this.paidBy,
    required this.paidByName,
    required this.frequency,
    required this.dayOfPeriod,
    required this.active,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String groupName;
  final bool isPersonal;
  final String name;
  final double amount;
  final Category category;
  final String paidBy;
  final String paidByName;
  final String frequency; // 'monthly'
  final int dayOfPeriod;
  final bool active;
  final DateTime createdAt;

  factory RecurringExpense.fromJson(Map<String, dynamic> json) =>
      RecurringExpense(
        id: json['id'] as String,
        groupId: json['group_id'] as String? ?? '',
        groupName: json['group_name'] as String? ?? '',
        isPersonal: json['is_personal'] as bool? ?? false,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: Category.fromJson(json['category'] as Map<String, dynamic>),
        paidBy: json['paid_by'] as String,
        paidByName: json['paid_by_name'] as String,
        frequency: json['frequency'] as String,
        dayOfPeriod: json['day_of_period'] as int,
        active: json['active'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  String frequencyLabel(String monthly, String yearly) {
    return switch (frequency) {
      'monthly' => monthly,
      'yearly' => yearly,
      _ => frequency,
    };
  }

  String dayLabel(String firstOfMonth, String Function(int day) nthOfMonth) {
    return switch (dayOfPeriod) {
      1 => firstOfMonth,
      _ => nthOfMonth(dayOfPeriod),
    };
  }

  @override
  List<Object?> get props => [
        id, groupId, name, amount, active, dayOfPeriod, frequency, isPersonal,
      ];
}
