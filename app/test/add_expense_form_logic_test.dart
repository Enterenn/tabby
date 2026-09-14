import 'package:flutter_test/flutter_test.dart';
import 'package:tabby/features/add_expense/add_expense_form_logic.dart';
import 'package:tabby/shared/models/category.dart';
import 'package:tabby/shared/models/expense.dart';
import 'package:tabby/shared/models/group.dart';
import 'package:tabby/shared/models/user.dart';

void main() {
  const oldCategory = Category(
    id: 'food',
    name: 'Old',
    icon: 'restaurant',
    color: '#000000',
    isDefault: true,
    sortOrder: 0,
  );
  const refreshedCategory = Category(
    id: 'food',
    name: 'Refreshed',
    icon: 'restaurant',
    color: '#FFFFFF',
    isDefault: true,
    sortOrder: 0,
  );
  final members = [
    GroupMember(
      user: const User(id: 'first', name: 'First', email: 'first@example.com'),
      joinedAt: DateTime(2026),
    ),
    GroupMember(
      user: const User(id: 'me', name: 'Me', email: 'me@example.com'),
      joinedAt: DateTime(2026),
    ),
  ];

  test('reconciles selected and draft categories with loaded instances', () {
    expect(
      resolveExpenseCategory(
        selected: oldCategory,
        draftCategoryId: null,
        available: const [refreshedCategory],
      ),
      same(refreshedCategory),
    );
    expect(
      resolveExpenseCategory(
        selected: null,
        draftCategoryId: 'food',
        available: const [refreshedCategory],
      ),
      same(refreshedCategory),
    );
  });

  test(
    'keeps a valid payer then falls back to current user or first member',
    () {
      expect(
        resolveExpensePayer(
          selectedId: 'first',
          members: members,
          currentUserId: 'me',
        ),
        'first',
      );
      expect(
        resolveExpensePayer(
          selectedId: 'missing',
          members: members,
          currentUserId: 'me',
        ),
        'me',
      );
      expect(
        resolveExpensePayer(
          selectedId: null,
          members: members,
          currentUserId: null,
        ),
        'first',
      );
    },
  );

  test('detects equal and custom split shapes for expense editing', () {
    Expense expense(List<ExpenseSplit> splits) => Expense(
      id: 'expense',
      name: 'Lunch',
      amount: 20,
      category: oldCategory,
      paidBy: 'me',
      paidByName: 'Me',
      expenseDate: DateTime(2026),
      createdAt: DateTime(2026),
      splits: splits,
    );

    expect(
      looksLikeEqualSplit(
        expense(const [
          ExpenseSplit(userId: 'first', amount: 10),
          ExpenseSplit(userId: 'me', amount: 10),
        ]),
      ),
      isTrue,
    );
    expect(
      looksLikeEqualSplit(
        expense(const [
          ExpenseSplit(userId: 'first', amount: 15),
          ExpenseSplit(userId: 'me', amount: 5),
        ]),
      ),
      isFalse,
    );
  });
}
