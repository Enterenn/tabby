import 'package:flutter_test/flutter_test.dart';
import 'package:tabby/features/budget/cubit/budget_cubit.dart';
import 'package:tabby/shared/models/category.dart';
import 'package:tabby/shared/models/personal_expense.dart';
import 'package:tabby/shared/models/spend_scope.dart';
import 'package:tabby/shared/models/stats.dart';

void main() {
  const clothes = Category(
    id: 'clothes',
    name: 'Vêtements',
    icon: 'checkroom',
    color: '#000',
    isDefault: true,
    sortOrder: 0,
  );
  const food = Category(
    id: 'food',
    name: 'Courses',
    icon: 'shopping_cart',
    color: '#111',
    isDefault: true,
    sortOrder: 1,
  );

  PersonalExpense item(String id, Category category) => PersonalExpense(
        id: id,
        name: id,
        amount: 10,
        category: category,
        expenseDate: DateTime(2026, 9, 1),
        createdAt: DateTime(2026, 9, 1),
      );

  BudgetLoaded state({String? categoryId}) => BudgetLoaded(
        budgets: const [],
        groups: const [],
        allCategories: const [clothes, food],
        stats: const MonthStats(
          year: 2026,
          month: 9,
          total: 20,
          categories: [],
        ),
        selectedYear: 2026,
        selectedMonth: 9,
        selectedCategoryId: categoryId,
        selectedScope: SpendScope.personal,
        personalExpenses: [item('pull', clothes), item('lait', food)],
      );

  test('visiblePersonalExpenses keeps every purchase without a category filter',
      () {
    expect(state().visiblePersonalExpenses.map((e) => e.id), ['pull', 'lait']);
  });

  test('visiblePersonalExpenses keeps only the selected category', () {
    expect(
      state(categoryId: clothes.id).visiblePersonalExpenses.map((e) => e.id),
      ['pull'],
    );
  });
}
