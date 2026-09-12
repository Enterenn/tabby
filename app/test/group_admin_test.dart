import 'package:flutter_test/flutter_test.dart';
import 'package:tabby/core/auth/group_admin.dart';

void main() {
  test('creator is the group admin', () {
    expect(isGroupAdmin(userId: 'admin', ownerId: 'admin'), isTrue);
    expect(isGroupAdmin(userId: 'member', ownerId: 'admin'), isFalse);
    expect(isGroupAdmin(userId: null, ownerId: 'admin'), isFalse);
  });

  test('payer or admin can manage a paid record', () {
    expect(
      canManagePaidRecord(userId: 'payer', ownerId: 'admin', paidBy: 'payer'),
      isTrue,
    );
    expect(
      canManagePaidRecord(userId: 'admin', ownerId: 'admin', paidBy: 'payer'),
      isTrue,
    );
    expect(
      canManagePaidRecord(userId: 'other', ownerId: 'admin', paidBy: 'payer'),
      isFalse,
    );
  });
}
