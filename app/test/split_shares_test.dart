import 'package:flutter_test/flutter_test.dart';
import 'package:tabby/core/format/split_shares.dart';

void main() {
  test('two shares and one share split 80€ like 53.33 and 26.67', () {
    final out = amountsFromShares(
      total: 80,
      userIds: const ['a', 'b'],
      shares: const {'a': 2, 'b': 1},
    );
    expect(out['a'], 53.33);
    expect(out['b'], 26.67);
    expect(
      ((out['a']! + out['b']!) * 100).round(),
      8000,
    );
  });

  test('equal shares match an equal split of two', () {
    final out = amountsFromShares(
      total: 80,
      userIds: const ['a', 'b'],
      shares: const {'a': 1, 'b': 1},
    );
    expect(out['a'], 40);
    expect(out['b'], 40);
  });

  test('zero shares leave that person at 0', () {
    final out = amountsFromShares(
      total: 30,
      userIds: const ['a', 'b'],
      shares: const {'a': 1, 'b': 0},
    );
    expect(out['a'], 30);
    expect(out['b'], 0);
  });
}
