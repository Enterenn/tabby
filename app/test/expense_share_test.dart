import 'package:flutter_test/flutter_test.dart';
import 'package:tabby/shared/models/category.dart';
import 'package:tabby/shared/models/expense.dart';

void main() {
  const category = Category(
    id: 'cat',
    name: 'Restau',
    icon: 'restaurant',
    color: '#000',
    isDefault: true,
    sortOrder: 0,
  );

  Expense expense({required List<ExpenseSplit> splits}) => Expense(
        id: 'e1',
        name: 'Resto',
        amount: 80,
        category: category,
        paidBy: 'a',
        paidByName: 'Alex',
        expenseDate: DateTime(2026, 9, 1),
        createdAt: DateTime(2026, 9, 1),
        splits: splits,
      );

  test('shareFor returns the user split, not the ticket', () {
    final e = expense(
      splits: const [
        ExpenseSplit(userId: 'me', amount: 40),
        ExpenseSplit(userId: 'them', amount: 40),
      ],
    );
    expect(e.shareFor('me'), 40);
    expect(e.shareFor('them'), 40);
    expect(e.amount, 80);
  });

  test('shareFor is zero when the user is not in the split', () {
    final e = expense(
      splits: const [ExpenseSplit(userId: 'them', amount: 80)],
    );
    expect(e.shareFor('me'), 0);
  });
}
