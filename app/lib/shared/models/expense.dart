import 'package:equatable/equatable.dart';
import 'category.dart';

class ExpenseSplit extends Equatable {
  const ExpenseSplit({required this.userId, required this.amount});

  final String userId;
  final double amount;

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) => ExpenseSplit(
        userId: json['user_id'] as String,
        amount: (json['amount'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [userId, amount];
}

class Expense extends Equatable {
  const Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.paidBy,
    required this.paidByName,
    required this.expenseDate,
    required this.createdAt,
    required this.splits,
  });

  final String id;
  final String name;
  final double amount;
  final Category category;
  final String paidBy;
  final String paidByName;
  final DateTime expenseDate;
  final DateTime createdAt;
  final List<ExpenseSplit> splits;

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: Category.fromJson(json['category'] as Map<String, dynamic>),
        paidBy: json['paid_by'] as String,
        paidByName: json['paid_by_name'] as String,
        expenseDate: DateTime.parse(json['expense_date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        splits: (json['splits'] as List)
            .map((s) => ExpenseSplit.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  double shareFor(String userId) {
    for (final split in splits) {
      if (split.userId == userId) return split.amount;
    }
    return 0;
  }

  @override
  List<Object?> get props =>
      [id, name, amount, category, paidBy, expenseDate, createdAt];
}
