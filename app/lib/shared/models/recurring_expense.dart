import 'package:equatable/equatable.dart';
import 'category.dart';

class RecurringExpense extends Equatable {
  const RecurringExpense({
    required this.id,
    required this.groupId,
    required this.groupName,
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
        groupId: json['group_id'] as String,
        groupName: json['group_name'] as String,
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

  String get frequencyLabel {
    return switch (frequency) {
      'monthly' => 'Mensuelle',
      'yearly' => 'Annuelle',
      _ => frequency,
    };
  }

  String get dayLabel {
    return switch (dayOfPeriod) {
      1 => '1er du mois',
      _ => '${dayOfPeriod}e du mois',
    };
  }

  @override
  List<Object?> get props => [
        id, groupId, name, amount, active, dayOfPeriod, frequency,
      ];
}
