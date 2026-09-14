import 'package:flutter_test/flutter_test.dart';
import 'package:tabby/features/add_expense/cubit/add_expense_cubit.dart';

void main() {
  test('rejects invalid expense before network submission', () async {
    final cubit = AddExpenseCubit();
    addTearDown(cubit.close);

    await cubit.submit(
      groupId: 'group',
      name: 'Lunch',
      amount: 20,
      categoryId: 'category',
      paidBy: 'payer',
      expenseDate: DateTime(2026, 9, 14),
      customSplits: [
        {'user_id': 'member', 'amount': 10},
      ],
    );

    expect(cubit.state, isA<AddExpenseInitial>());
  });
}
