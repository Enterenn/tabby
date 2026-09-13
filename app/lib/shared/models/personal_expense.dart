import 'package:equatable/equatable.dart';

import 'category.dart';

class PersonalExpense extends Equatable {
  const PersonalExpense({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.expenseDate,
    required this.createdAt,
  });

  final String id;
  final String name;
  final double amount;
  final Category category;
  final DateTime expenseDate;
  final DateTime createdAt;

  factory PersonalExpense.fromJson(Map<String, dynamic> json) =>
      PersonalExpense(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: Category.fromJson(json['category'] as Map<String, dynamic>),
        expenseDate: DateTime.parse(json['expense_date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, name, amount, expenseDate];
}
