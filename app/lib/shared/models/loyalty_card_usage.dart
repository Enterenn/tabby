import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'loyalty_card.dart';

/// Ouvertures plein écran — sert à déduire les cartes fréquentes.
abstract final class LoyaltyCardUsageStore {
  static const _key = 'loyalty_card_opens';
  static const _window = Duration(days: 42);
  static const _retain = Duration(days: 90);
  static const _minDays = 3;
  static const _maxCards = 3;
  static const _keepPerCard = 40;
  static const _storage = FlutterSecureStorage();

  static final Map<String, List<DateTime>> _cache = {};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    final raw = await _storage.read(key: _key);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _cache
          ..clear()
          ..addAll(
            map.map(
              (id, value) => MapEntry(
                id,
                [
                  for (final item in value as List)
                    DateTime.parse(item as String).toUtc(),
                ],
              ),
            ),
          );
      } catch (_) {
        _cache.clear();
      }
    }
    _loaded = true;
  }

  static Future<void> recordOpen(String cardId) async {
    await load();
    final opens = List<DateTime>.from(_cache[cardId] ?? const []);
    opens.add(DateTime.now().toUtc());
    _cache[cardId] = _prune(opens);
    await _persist();
  }

  static Future<void> forget(String cardId) async {
    await load();
    if (_cache.remove(cardId) == null) return;
    await _persist();
  }

  static Future<void> forgetMissing(Iterable<String> keepIds) async {
    await load();
    final keep = keepIds.toSet();
    final stale = _cache.keys.where((id) => !keep.contains(id)).toList();
    if (stale.isEmpty) return;
    for (final id in stale) {
      _cache.remove(id);
    }
    await _persist();
  }

  /// Jours distincts sur [_window], écart clair avec le reste du wallet.
  static List<LoyaltyCard> frequentOf(List<LoyaltyCard> cards) {
    if (cards.length < 2) return const [];
    final now = DateTime.now();
    final counts = <String, int>{
      for (final card in cards) card.id: _distinctDays(card.id, now),
    };
    final qualified = [
      for (final card in cards)
        if (counts[card.id]! >= _minDays) card,
    ];
    if (qualified.isEmpty) return const [];

    var high = 0;
    var low = counts[qualified.first.id]!;
    for (final card in qualified) {
      final days = counts[card.id]!;
      if (days > high) high = days;
      if (days < low) low = days;
    }
    final halfWallet = (cards.length / 2).ceil();
    if (qualified.length >= halfWallet && high - low <= 1) {
      return const [];
    }
    if (qualified.length <= _maxCards) return qualified;

    final ranked = [...qualified]
      ..sort((a, b) => counts[b.id]!.compareTo(counts[a.id]!));
    final fourth = counts[ranked[_maxCards].id]!;
    final above = [
      for (final card in qualified)
        if (counts[card.id]! > fourth) card,
    ];
    if (above.isEmpty || above.length > _maxCards) return const [];
    return above;
  }

  static int _distinctDays(String cardId, DateTime now) {
    final seen = <int>{};
    for (final open in _cache[cardId] ?? const <DateTime>[]) {
      if (now.difference(open) > _window) continue;
      final local = open.toLocal();
      seen.add(local.year * 10000 + local.month * 100 + local.day);
    }
    return seen.length;
  }

  static List<DateTime> _prune(List<DateTime> opens) {
    final now = DateTime.now().toUtc();
    final kept = [
      for (final open in opens)
        if (now.difference(open) <= _retain) open,
    ];
    if (kept.length > _keepPerCard) {
      return kept.sublist(kept.length - _keepPerCard);
    }
    return kept;
  }

  static Future<void> _persist() {
    return _storage.write(
      key: _key,
      value: jsonEncode(
        _cache.map(
          (id, opens) => MapEntry(
            id,
            [for (final open in opens) open.toIso8601String()],
          ),
        ),
      ),
    );
  }
}
