/// Group creator (`ownerId`) is the admin of that group.
bool isGroupAdmin({required String? userId, required String? ownerId}) {
  return userId != null && ownerId != null && userId == ownerId;
}

/// Admin or the person who paid can edit/delete an expense or recurring item.
bool canManagePaidRecord({
  required String? userId,
  required String? ownerId,
  required String paidBy,
}) {
  return isGroupAdmin(userId: userId, ownerId: ownerId) || userId == paidBy;
}
