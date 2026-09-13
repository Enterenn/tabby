/// How a shared expense is divided among members.
enum ExpenseSplitMode { equal, shares, amounts }

/// Turns integer shares into euro amounts that sum exactly to [total].
///
/// The last person in [userIds] who has a share receives leftover cents.
/// A share of 0 means that person pays nothing.
Map<String, double> amountsFromShares({
  required double total,
  required List<String> userIds,
  required Map<String, int> shares,
}) {
  final cents = (total * 100).round();
  final shareSum = userIds.fold<int>(
    0,
    (sum, id) => sum + (shares[id] ?? 0).clamp(0, 99),
  );
  if (cents <= 0 || shareSum <= 0) {
    return {for (final id in userIds) id: 0};
  }

  final out = <String, double>{};
  var allocated = 0;
  final withShares = userIds.where((id) => (shares[id] ?? 0) > 0).toList();
  for (var i = 0; i < withShares.length; i++) {
    final id = withShares[i];
    final part = (shares[id] ?? 0).clamp(0, 99);
    final int shareCents;
    if (i == withShares.length - 1) {
      shareCents = cents - allocated;
    } else {
      shareCents = (cents * part) ~/ shareSum;
      allocated += shareCents;
    }
    out[id] = shareCents / 100;
  }
  for (final id in userIds) {
    out.putIfAbsent(id, () => 0);
  }
  return out;
}
