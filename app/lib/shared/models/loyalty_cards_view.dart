import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Affichage du portefeuille — pile, grille 2 colonnes, ou liste compacte.
enum LoyaltyCardsView {
  wallet,
  grid,
  compact;

  static LoyaltyCardsView parse(String? raw) => switch (raw) {
        'grid' => LoyaltyCardsView.grid,
        'compact' => LoyaltyCardsView.compact,
        _ => LoyaltyCardsView.wallet,
      };
}

abstract final class LoyaltyCardsViewStore {
  static const _key = 'loyalty_cards_view';
  static const _storage = FlutterSecureStorage();

  static Future<LoyaltyCardsView> load() async {
    return LoyaltyCardsView.parse(await _storage.read(key: _key));
  }

  static Future<void> save(LoyaltyCardsView view) {
    return _storage.write(key: _key, value: view.name);
  }
}
