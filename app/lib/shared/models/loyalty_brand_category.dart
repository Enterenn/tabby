import 'loyalty_brand.dart';
import 'loyalty_card.dart';

/// Rayon d'une enseigne — sert au filtre du portefeuille.
enum LoyaltyBrandCategory {
  groceries,
  pets,
  fashion,
  home,
  food,
  tech,
  sport,
  other;

  static LoyaltyBrandCategory ofBrandId(String? id) =>
      _byId[id] ?? LoyaltyBrandCategory.other;

  static LoyaltyBrandCategory ofCard(LoyaltyCard card) {
    final known =
        LoyaltyBrand.byId(card.brandId) ?? LoyaltyBrand.byName(card.brandName);
    return ofBrandId(known?.id);
  }

  /// Catégories présentes, dans l'ordre d'affichage.
  static List<LoyaltyBrandCategory> presentIn(Iterable<LoyaltyCard> cards) {
    final found = <LoyaltyBrandCategory>{};
    for (final card in cards) {
      found.add(ofCard(card));
    }
    return [
      for (final category in values)
        if (found.contains(category)) category,
    ];
  }

  /// Garde la position des cartes masquées, applique le nouvel ordre visible.
  static List<LoyaltyCard> mergeVisibleOrder(
    List<LoyaltyCard> all,
    List<LoyaltyCard> visibleOrdered,
  ) {
    final queue = List<LoyaltyCard>.from(visibleOrdered);
    final ids = visibleOrdered.map((c) => c.id).toSet();
    return [
      for (final card in all)
        if (ids.contains(card.id)) queue.removeAt(0) else card,
    ];
  }

  static const _byId = <String, LoyaltyBrandCategory>{
    'carrefour': groceries,
    'leclerc': groceries,
    'auchan': groceries,
    'monoprix': groceries,
    'lidl': groceries,
    'intermarche': groceries,
    'picard': groceries,
    'superu': groceries,
    'casino': groceries,
    'franprix': groceries,
    'cora': groceries,
    'aldi': groceries,
    'grandfrais': groceries,
    'naturalia': groceries,
    'biocoop': groceries,
    'animalis': pets,
    'maxizoo': pets,
    'jardiland': home,
    'truffaut': home,
    'botanic': home,
    'gammvert': home,
    'ikea': home,
    'leroymerlin': home,
    'castorama': home,
    'bricomarche': home,
    'but': home,
    'conforama': home,
    'nike': fashion,
    'hm': fashion,
    'zara': fashion,
    'kiabi': fashion,
    'ca': fashion,
    'jules': fashion,
    'promod': fashion,
    'etam': fashion,
    'sephora': fashion,
    'marionnaud': fashion,
    'nocibe': fashion,
    'yvesrocher': fashion,
    'loccitane': fashion,
    'printemps': fashion,
    'galerieslafayette': fashion,
    'veepee': fashion,
    'starbucks': food,
    'mcdo': food,
    'paul': food,
    'quick': food,
    'kfc': food,
    'burgerking': food,
    'dominos': food,
    'flunch': food,
    'fnac': tech,
    'apple': tech,
    'boulanger': tech,
    'darty': tech,
    'ldlc': tech,
    'cultura': tech,
    'micromania': tech,
    'decathlon': sport,
    'intersport': sport,
    'gosport': sport,
  };
}
