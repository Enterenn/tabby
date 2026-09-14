import 'package:flutter_test/flutter_test.dart';
import 'package:tabby/data/categories_repository.dart';
import 'package:tabby/data/expenses_repository.dart';
import 'package:tabby/data/groups_repository.dart';
import 'package:tabby/features/add_expense/cubit/add_expense_cubit.dart';
import 'package:tabby/shared/models/category.dart';
import 'package:tabby/shared/models/expense.dart';
import 'package:tabby/shared/models/group.dart';
import 'package:tabby/shared/models/user.dart';

const _category = Category(
  id: 'food',
  name: 'Food',
  icon: 'restaurant',
  color: '#000000',
  isDefault: true,
  sortOrder: 0,
);

final _group = Group(
  id: 'group',
  name: 'Trip',
  createdAt: DateTime(2026),
  members: [
    GroupMember(
      user: const User(id: 'payer', name: 'Payer', email: 'p@example.com'),
      joinedAt: DateTime(2026),
    ),
  ],
  balance: 0,
);

class _GroupsRepository extends GroupsRepository {
  @override
  Future<List<Group>> list() async => [_group];

  @override
  Future<Group> get(String groupId) async => _group;
}

class _CategoriesRepository extends CategoriesRepository {
  @override
  Future<List<Category>> list({String? groupId}) async => const [_category];
}

class _FailingExpensesRepository extends ExpensesRepository {
  int attempts = 0;

  @override
  Future<Expense> create({
    required String groupId,
    required String name,
    required double amount,
    required String categoryId,
    required String paidBy,
    required DateTime expenseDate,
    List<Map<String, dynamic>>? customSplits,
  }) async {
    attempts++;
    throw Exception('offline');
  }
}

void main() {
  test(
    'restores ready state after a failed submission so it can retry',
    () async {
      final expenses = _FailingExpensesRepository();
      final cubit = AddExpenseCubit(
        groups: _GroupsRepository(),
        categories: _CategoriesRepository(),
        expenses: expenses,
      );
      addTearDown(cubit.close);

      await cubit.load(groupId: _group.id);
      expect(cubit.state, isA<AddExpenseReady>());

      Future<bool> submit() => cubit.submit(
        groupId: _group.id,
        name: 'Lunch',
        amount: 20,
        categoryId: _category.id,
        paidBy: 'payer',
        expenseDate: DateTime(2026),
        customSplits: const [
          {'user_id': 'payer', 'amount': 20},
        ],
      );

      expect(await submit(), isFalse);
      expect(cubit.state, isA<AddExpenseReady>());
      expect(await submit(), isFalse);
      expect(expenses.attempts, 2);
    },
  );
}
