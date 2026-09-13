import 'package:equatable/equatable.dart';

import 'category.dart';

enum BudgetStatus { ok, warning, danger }

class Budget extends Equatable {
  const Budget({
    required this.id,
    this.groupId,
    required this.category,
    required this.limitAmount,
    required this.spentAmount,
    required this.percent,
    required this.status,
  });

  final String id;
  final String? groupId;
  final Category category;
  final double limitAmount;
  final double spentAmount;
  final double percent;
  final BudgetStatus status;

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: json['id'] as String,
        groupId: json['group_id'] as String?,
        category: Category.fromJson(json['category'] as Map<String, dynamic>),
        limitAmount: (json['limit_amount'] as num).toDouble(),
        spentAmount: (json['spent_amount'] as num).toDouble(),
        percent: (json['percent'] as num).toDouble(),
        status: switch (json['status'] as String) {
          'warning' => BudgetStatus.warning,
          'danger' => BudgetStatus.danger,
          _ => BudgetStatus.ok,
        },
      );

  double get remaining => limitAmount - spentAmount;

  @override
  List<Object?> get props => [id, spentAmount, percent, status];
}
