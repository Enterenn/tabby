class AddExpenseDraft {
  const AddExpenseDraft({
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.payerId,
    required this.expenseDate,
  });

  final String name;
  final String amount;
  final String? categoryId;
  final String? payerId;
  final DateTime expenseDate;
}

class AddExpenseDraftStore {
  AddExpenseDraft? _draft;

  AddExpenseDraft? take() {
    final draft = _draft;
    _draft = null;
    return draft;
  }

  void save(AddExpenseDraft draft) => _draft = draft;
  void clear() => _draft = null;
}

final addExpenseDraftStore = AddExpenseDraftStore();
