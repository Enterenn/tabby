import 'package:equatable/equatable.dart';
import 'category.dart';

class CategoryStat extends Equatable {
  const CategoryStat({
    required this.category,
    required this.amount,
    required this.percent,
  });

  final Category category;
  final double amount;
  final double percent;

  factory CategoryStat.fromJson(Map<String, dynamic> json) => CategoryStat(
        category:
            Category.fromJson(json['category'] as Map<String, dynamic>),
        amount: (json['amount'] as num).toDouble(),
        percent: (json['percent'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [category.id, amount, percent];
}

class MonthStats extends Equatable {
  const MonthStats({
    required this.year,
    required this.month,
    required this.total,
    required this.categories,
  });

  final int year;
  final int month;
  final double total;
  final List<CategoryStat> categories;

  factory MonthStats.fromJson(Map<String, dynamic> json) => MonthStats(
        year: json['year'] as int,
        month: json['month'] as int,
        total: (json['total'] as num).toDouble(),
        categories: (json['categories'] as List)
            .map((c) => CategoryStat.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  static const _months = [
    '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  String get monthLabel => _months[month];

  @override
  List<Object?> get props => [year, month, total, categories];
}
