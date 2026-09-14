import 'package:flutter_test/flutter_test.dart';
import 'package:tabby/features/add_expense/cubit/add_expense_cubit.dart';

void main() {
  String? validate({
    String groupId = 'group',
    String name = 'Lunch',
    double amount = 20,
    String categoryId = 'category',
    String paidBy = 'payer',
    List<Map<String, dynamic>>? splits,
  }) {
    return validateExpenseSubmission(
      groupId: groupId,
      name: name,
      amount: amount,
      categoryId: categoryId,
      paidBy: paidBy,
      customSplits: splits,
    );
  }

  test('rejects required fields and invalid amounts before submission', () {
    expect(validate(groupId: ''), 'expenseGroupRequired');
    expect(validate(name: '  '), 'expenseNameRequired');
    expect(validate(amount: 0), 'expenseAmountInvalid');
    expect(validate(amount: double.nan), 'expenseAmountInvalid');
    expect(validate(categoryId: ''), 'expenseCategoryRequired');
    expect(validate(paidBy: ''), 'expensePayerRequired');
  });

  test('rejects empty, duplicate and mismatched custom splits', () {
    expect(validate(splits: []), 'expenseSplitsRequired');
    expect(
      validate(
        splits: [
          {'user_id': 'member', 'amount': 10},
          {'user_id': 'member', 'amount': 10},
        ],
      ),
      'expenseSplitsDuplicate',
    );
    expect(
      validate(
        splits: [
          {'user_id': 'first', 'amount': 10},
          {'user_id': 'second', 'amount': 5},
        ],
      ),
      'expenseSplitsMismatch',
    );
  });

  test('accepts a complete expense with balanced custom splits', () {
    expect(
      validate(
        splits: [
          {'user_id': 'first', 'amount': 10},
          {'user_id': 'second', 'amount': 10},
        ],
      ),
      isNull,
    );
  });
}
