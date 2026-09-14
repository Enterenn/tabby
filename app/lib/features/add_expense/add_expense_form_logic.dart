import '../../shared/models/category.dart';
import '../../shared/models/expense.dart';
import '../../shared/models/group.dart';

Category? resolveExpenseCategory({
  required Category? selected,
  required String? draftCategoryId,
  required List<Category> available,
}) {
  final targetId = selected?.id ?? draftCategoryId;
  if (targetId == null) return selected;
  for (final category in available) {
    if (category.id == targetId) return category;
  }
  return selected;
}

String? resolveExpensePayer({
  required String? selectedId,
  required List<GroupMember> members,
  required String? currentUserId,
}) {
  if (selectedId != null && members.any((m) => m.user.id == selectedId)) {
    return selectedId;
  }
  if (currentUserId != null && members.any((m) => m.user.id == currentUserId)) {
    return currentUserId;
  }
  return members.isNotEmpty ? members.first.user.id : null;
}

bool looksLikeEqualSplit(Expense expense) {
  final active = [
    for (final split in expense.splits)
      if (split.amount > 0.005) split.amount,
  ];
  if (active.length <= 1) return true;

  var minAmount = active.first;
  var maxAmount = active.first;
  for (final amount in active) {
    if (amount < minAmount) minAmount = amount;
    if (amount > maxAmount) maxAmount = amount;
  }
  return maxAmount - minAmount <= 0.02;
}
