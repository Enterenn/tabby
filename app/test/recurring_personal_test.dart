import 'package:flutter_test/flutter_test.dart';
import 'package:tabby/shared/models/recurring_expense.dart';

void main() {
  final category = {
    'id': 'cat',
    'name': 'Abonnements',
    'icon': 'live_tv',
    'color': '#000',
    'is_default': true,
    'sort_order': 0,
  };

  test('fromJson marks a personal recurring without a group', () {
    final item = RecurringExpense.fromJson({
      'id': 'r1',
      'group_id': null,
      'group_name': null,
      'is_personal': true,
      'name': 'Netflix',
      'amount': 13.49,
      'category': category,
      'paid_by': 'me',
      'paid_by_name': 'Baptiste',
      'frequency': 'monthly',
      'day_of_period': 5,
      'active': true,
      'created_at': '2026-09-13T12:00:00Z',
    });
    expect(item.isPersonal, isTrue);
    expect(item.groupId, isEmpty);
    expect(item.name, 'Netflix');
  });

  test('fromJson keeps a group recurring as shared', () {
    final item = RecurringExpense.fromJson({
      'id': 'r2',
      'group_id': 'g1',
      'group_name': 'Couple',
      'is_personal': false,
      'name': 'Loyer',
      'amount': 800,
      'category': category,
      'paid_by': 'me',
      'paid_by_name': 'Baptiste',
      'frequency': 'monthly',
      'day_of_period': 1,
      'active': true,
      'created_at': '2026-09-13T12:00:00Z',
    });
    expect(item.isPersonal, isFalse);
    expect(item.groupName, 'Couple');
  });
}
