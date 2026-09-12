import 'package:material_ui/material_ui.dart';

/// Marque connue — couleurs et monogramme (logo asset optionnel plus tard).
class LoyaltyBrand {
  const LoyaltyBrand({
    required this.id,
    required this.name,
    required this.primary,
    this.secondary,
    required this.monogram,
    this.logoAsset,
    this.onPrimary = Colors.white,
    this.codePrefixes = const [],
    this.qrHints = const [],
  });

  final String id;
  final String name;
  final Color primary;
  final Color? secondary;
  final String monogram;
  final String? logoAsset;
  final Color onPrimary;
  /// Préfixes numériques EAN/code-barres — enrichissable au fil des scans.
  final List<String> codePrefixes;
  /// Indices dans une URL ou un QR texte (domaine, slug…).
  final List<String> qrHints;

  LinearGradient get gradient {
    final hasDistinctSecondary =
        secondary != null && secondary != primary;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primary,
        hasDistinctSecondary
            ? secondary!
            : Color.lerp(primary, Colors.white, 0.16)!,
      ],
    );
  }

  /// Catalogue Tabby — ajouter un logo : `assets/brands/{id}.svg` + `logoAsset`.
  static const List<LoyaltyBrand> catalog = [
    LoyaltyBrand(
      id: 'carrefour',
      name: 'Carrefour',
      primary: Color(0xFF004E9A),
      secondary: Color(0xFFED1C24),
      monogram: 'C',
      qrHints: ['carrefour.fr', 'carrefour.com', 'carrefour'],
      codePrefixes: ['275090', '275091'],
      // logoAsset: 'assets/brands/carrefour.svg',
    ),
    LoyaltyBrand(
      id: 'leclerc',
      name: 'E.Leclerc',
      primary: Color(0xFF0054A6),
      secondary: Color(0xFF003D7A),
      monogram: 'E',
      qrHints: ['e.leclerc', 'leclerc'],
      codePrefixes: ['275092'],
    ),
    LoyaltyBrand(
      id: 'auchan',
      name: 'Auchan',
      primary: Color(0xFFE30613),
      secondary: Color(0xFFB0040F),
      monogram: 'A',
      qrHints: ['auchan.fr', 'auchan'],
    ),
    LoyaltyBrand(
      id: 'monoprix',
      name: 'Monoprix',
      primary: Color(0xFFE2001A),
      secondary: Color(0xFF1A1A1A),
      monogram: 'M',
      qrHints: ['monoprix.fr', 'monoprix'],
    ),
    LoyaltyBrand(
      id: 'lidl',
      name: 'Lidl',
      primary: Color(0xFF0050AA),
      secondary: Color(0xFFFDD900),
      monogram: 'L',
      onPrimary: Colors.white,
      qrHints: ['lidl.fr', 'lidl.com', 'lidl'],
    ),
    LoyaltyBrand(
      id: 'decathlon',
      name: 'Decathlon',
      primary: Color(0xFF0082C3),
      secondary: Color(0xFF006699),
      monogram: 'D',
      qrHints: ['decathlon.fr', 'decathlon.com', 'decathlon'],
    ),
    LoyaltyBrand(
      id: 'fnac',
      name: 'Fnac',
      primary: Color(0xFFEBB300),
      secondary: Color(0xFF1A1A1A),
      monogram: 'F',
      onPrimary: Color(0xFF1A1A1A),
      qrHints: ['fnac.com', 'fnac'],
    ),
    LoyaltyBrand(
      id: 'sephora',
      name: 'Sephora',
      primary: Color(0xFF000000),
      secondary: Color(0xFF333333),
      monogram: 'S',
      qrHints: ['sephora.fr', 'sephora.com', 'sephora'],
    ),
    LoyaltyBrand(
      id: 'starbucks',
      name: 'Starbucks',
      primary: Color(0xFF00704A),
      secondary: Color(0xFF1E3932),
      monogram: '★',
      qrHints: ['starbucks.fr', 'starbucks.com', 'starbucks'],
    ),
    LoyaltyBrand(
      id: 'mcdo',
      name: 'McDonald\'s',
      primary: Color(0xFFDA291C),
      secondary: Color(0xFFFFBC0D),
      monogram: 'M',
      qrHints: ['mcdonalds.fr', 'mcdonalds.com', 'mcdo'],
    ),
    LoyaltyBrand(
      id: 'ikea',
      name: 'IKEA',
      primary: Color(0xFF0058A3),
      secondary: Color(0xFFFFDB00),
      monogram: 'IK',
      onPrimary: Colors.white,
      qrHints: ['ikea.fr', 'ikea.com', 'ikea'],
    ),
    LoyaltyBrand(
      id: 'amazon',
      name: 'Amazon',
      primary: Color(0xFF232F3E),
      secondary: Color(0xFFFF9900),
      monogram: 'a',
      qrHints: ['amazon.fr', 'amazon.com', 'amazon'],
    ),
    LoyaltyBrand(
      id: 'apple',
      name: 'Apple',
      primary: Color(0xFF1D1D1F),
      secondary: Color(0xFF424245),
      monogram: '',
      qrHints: ['apple.com', 'wallet.apple'],
    ),
    LoyaltyBrand(
      id: 'nike',
      name: 'Nike',
      primary: Color(0xFF111111),
      secondary: Color(0xFF333333),
      monogram: '✓',
      qrHints: ['nike.com', 'nike.fr', 'nike'],
    ),
    LoyaltyBrand(
      id: 'hm',
      name: 'H&M',
      primary: Color(0xFFE50010),
      secondary: Color(0xFF1A1A1A),
      monogram: 'H',
      qrHints: ['hm.com', 'h&m', 'hm.fr'],
    ),
    LoyaltyBrand(
      id: 'zara',
      name: 'Zara',
      primary: Color(0xFF000000),
      secondary: Color(0xFF2A2A2A),
      monogram: 'Z',
      qrHints: ['zara.com', 'zara.fr', 'zara'],
    ),
    LoyaltyBrand(
      id: 'intermarche',
      name: 'Intermarché',
      primary: Color(0xFFED1C24),
      secondary: Color(0xFF0054A4),
      monogram: 'I',
      qrHints: ['intermarche.com', 'intermarche'],
    ),
    LoyaltyBrand(
      id: 'picard',
      name: 'Picard',
      primary: Color(0xFF003DA5),
      secondary: Color(0xFF002878),
      monogram: 'P',
      qrHints: ['picard.fr', 'picard'],
      codePrefixes: ['2900334', '2900335', '2900336'],
    ),
    // ── Animalerie ───────────────────────────────────────────────────────────
    LoyaltyBrand(
      id: 'animalis',
      name: 'Animalis',
      primary: Color(0xFFE30613),
      secondary: Color(0xFFB0040F),
      monogram: 'A',
      qrHints: ['animalis.fr', 'animalis'],
    ),
    LoyaltyBrand(
      id: 'maxizoo',
      name: 'Maxi Zoo',
      primary: Color(0xFF015E27),
      secondary: Color(0xFF015E27),
      monogram: 'MZ',
      qrHints: ['maxizoo.fr', 'maxi-zoo', 'maxizoo'],
    ),
    LoyaltyBrand(
      id: 'jardiland',
      name: 'Jardiland',
      primary: Color(0xFF00843D),
      secondary: Color(0xFF006830),
      monogram: 'J',
      qrHints: ['jardiland.fr', 'jardiland'],
    ),
    LoyaltyBrand(
      id: 'truffaut',
      name: 'Truffaut',
      primary: Color(0xFF009640),
      secondary: Color(0xFF007030),
      monogram: 'T',
      qrHints: ['truffaut.com', 'truffaut'],
    ),
    LoyaltyBrand(
      id: 'botanic',
      name: 'Botanic',
      primary: Color(0xFF6BA539),
      secondary: Color(0xFF4E8528),
      monogram: 'B',
      qrHints: ['botanic.fr', 'botanic'],
    ),
    LoyaltyBrand(
      id: 'gammvert',
      name: 'Gamm Vert',
      primary: Color(0xFF008542),
      secondary: Color(0xFF006B35),
      monogram: 'GV',
      qrHints: ['gammvert.fr', 'gammvert'],
    ),
    // ── Grande distribution ────────────────────────────────────────────────────
    LoyaltyBrand(
      id: 'superu',
      name: 'Super U',
      primary: Color(0xFFE2001A),
      secondary: Color(0xFF0054A4),
      monogram: 'U',
      qrHints: ['superu.com', 'systeme-u', 'coursesu.com', 'super u'],
    ),
    LoyaltyBrand(
      id: 'casino',
      name: 'Casino',
      primary: Color(0xFFE2007A),
      secondary: Color(0xFF9E0056),
      monogram: 'C',
      qrHints: ['casino.fr', 'casino-shopping', 'casino'],
    ),
    LoyaltyBrand(
      id: 'franprix',
      name: 'Franprix',
      primary: Color(0xFFE30613),
      secondary: Color(0xFF1A1A1A),
      monogram: 'F',
      qrHints: ['franprix.fr', 'franprix'],
    ),
    LoyaltyBrand(
      id: 'cora',
      name: 'Cora',
      primary: Color(0xFF0054A4),
      secondary: Color(0xFFE2001A),
      monogram: 'C',
      qrHints: ['cora.fr', 'cora'],
    ),
    LoyaltyBrand(
      id: 'aldi',
      name: 'Aldi',
      primary: Color(0xFF0050AA),
      secondary: Color(0xFFFF7800),
      monogram: 'A',
      qrHints: ['aldi.fr', 'aldi.com', 'aldi'],
    ),
    LoyaltyBrand(
      id: 'grandfrais',
      name: 'Grand Frais',
      primary: Color(0xFFE85D04),
      secondary: Color(0xFF52B788),
      monogram: 'GF',
      qrHints: ['grandfrais.com', 'grandfrais', 'grand frais'],
    ),
    LoyaltyBrand(
      id: 'naturalia',
      name: 'Naturalia',
      primary: Color(0xFFBF2616),
      secondary: Color(0xFFBF2616),
      monogram: 'N',
      qrHints: ['naturalia.fr', 'naturalia'],
    ),
    LoyaltyBrand(
      id: 'biocoop',
      name: 'Biocoop',
      primary: Color(0xFF8AB928),
      secondary: Color(0xFF6A9020),
      monogram: 'B',
      qrHints: ['biocoop.fr', 'biocoop'],
    ),
    // ── Bricolage & maison ───────────────────────────────────────────────────
    LoyaltyBrand(
      id: 'leroymerlin',
      name: 'Leroy Merlin',
      primary: Color(0xFF78BE20),
      secondary: Color(0xFF5A9418),
      monogram: 'LM',
      qrHints: ['leroymerlin.fr', 'leroymerlin.com', 'leroy merlin'],
    ),
    LoyaltyBrand(
      id: 'castorama',
      name: 'Castorama',
      primary: Color(0xFF0078D4),
      secondary: Color(0xFFE30613),
      monogram: 'C',
      qrHints: ['castorama.fr', 'castorama'],
    ),
    LoyaltyBrand(
      id: 'bricomarche',
      name: 'Bricomarché',
      primary: Color(0xFF009640),
      secondary: Color(0xFF007030),
      monogram: 'B',
      qrHints: ['bricomarche.com', 'bricomarche', 'bricomarché'],
    ),
    LoyaltyBrand(
      id: 'but',
      name: 'But',
      primary: Color(0xFFE2001A),
      secondary: Color(0xFF1A1A1A),
      monogram: 'B',
      qrHints: ['but.fr', 'but'],
    ),
    LoyaltyBrand(
      id: 'conforama',
      name: 'Conforama',
      primary: Color(0xFFE2001A),
      secondary: Color(0xFF0054A4),
      monogram: 'C',
      qrHints: ['conforama.fr', 'conforama'],
    ),
    // ── Mode & beauté ──────────────────────────────────────────────────────
    LoyaltyBrand(
      id: 'kiabi',
      name: 'Kiabi',
      primary: Color(0xFF0066CC),
      secondary: Color(0xFF004499),
      monogram: 'K',
      qrHints: ['kiabi.com', 'kiabi.fr', 'kiabi'],
    ),
    LoyaltyBrand(
      id: 'ca',
      name: 'C&A',
      primary: Color(0xFF003DA5),
      secondary: Color(0xFF1A1A1A),
      monogram: 'C',
      qrHints: ['c-and-a.com', 'canda.com', 'c&a'],
    ),
    LoyaltyBrand(
      id: 'jules',
      name: 'Jules',
      primary: Color(0xFF1A2744),
      secondary: Color(0xFF2E3F66),
      monogram: 'J',
      qrHints: ['jules.com', 'jules.fr', 'jules'],
    ),
    LoyaltyBrand(
      id: 'promod',
      name: 'Promod',
      primary: Color(0xFFE2001A),
      secondary: Color(0xFF1A1A1A),
      monogram: 'P',
      qrHints: ['promod.fr', 'promod.com', 'promod'],
    ),
    LoyaltyBrand(
      id: 'etam',
      name: 'Etam',
      primary: Color(0xFF1A1A1A),
      secondary: Color(0xFF333333),
      monogram: 'E',
      qrHints: ['etam.com', 'etam.fr', 'etam'],
    ),
    LoyaltyBrand(
      id: 'marionnaud',
      name: 'Marionnaud',
      primary: Color(0xFFE2007A),
      secondary: Color(0xFF9E0056),
      monogram: 'M',
      qrHints: ['marionnaud.fr', 'marionnaud'],
    ),
    LoyaltyBrand(
      id: 'nocibe',
      name: 'Nocibé',
      primary: Color(0xFFD4145A),
      secondary: Color(0xFF9E0F42),
      monogram: 'N',
      qrHints: ['nocibe.fr', 'nocibe'],
    ),
    LoyaltyBrand(
      id: 'yvesrocher',
      name: 'Yves Rocher',
      primary: Color(0xFF006241),
      secondary: Color(0xFF004830),
      monogram: 'YR',
      qrHints: ['yves-rocher.fr', 'yvesrocher', 'yves rocher'],
    ),
    LoyaltyBrand(
      id: 'loccitane',
      name: "L'Occitane",
      primary: Color(0xFFF5C518),
      secondary: Color(0xFF1A1A1A),
      monogram: 'O',
      onPrimary: Color(0xFF1A1A1A),
      qrHints: ['loccitane.com', 'loccitane.fr', 'occitane'],
    ),
    LoyaltyBrand(
      id: 'printemps',
      name: 'Printemps',
      primary: Color(0xFF1A1A1A),
      secondary: Color(0xFF444444),
      monogram: 'P',
      qrHints: ['printemps.com', 'printemps.fr', 'printemps'],
    ),
    LoyaltyBrand(
      id: 'galerieslafayette',
      name: 'Galeries Lafayette',
      primary: Color(0xFF1A1A1A),
      secondary: Color(0xFF8B6914),
      monogram: 'GL',
      qrHints: ['galerieslafayette.com', 'galeries lafayette'],
    ),
    // ── High-tech & culture ──────────────────────────────────────────────────
    LoyaltyBrand(
      id: 'boulanger',
      name: 'Boulanger',
      primary: Color(0xFFFF6600),
      secondary: Color(0xFFCC5200),
      monogram: 'B',
      qrHints: ['boulanger.com', 'boulanger.fr', 'boulanger'],
    ),
    LoyaltyBrand(
      id: 'darty',
      name: 'Darty',
      primary: Color(0xFFE60012),
      secondary: Color(0xFF1A1A1A),
      monogram: 'D',
      qrHints: ['darty.com', 'darty.fr', 'darty'],
    ),
    LoyaltyBrand(
      id: 'ldlc',
      name: 'LDLC',
      primary: Color(0xFFE2001A),
      secondary: Color(0xFF1A1A1A),
      monogram: 'L',
      qrHints: ['ldlc.com', 'ldlc'],
    ),
    LoyaltyBrand(
      id: 'cultura',
      name: 'Cultura',
      primary: Color(0xFF7B2D8E),
      secondary: Color(0xFF5A1F68),
      monogram: 'C',
      qrHints: ['cultura.com', 'cultura.fr', 'cultura'],
    ),
    LoyaltyBrand(
      id: 'micromania',
      name: 'Micromania',
      primary: Color(0xFFFFCC00),
      secondary: Color(0xFF1A1A1A),
      monogram: 'M',
      onPrimary: Color(0xFF1A1A1A),
      qrHints: ['micromania.fr', 'micromania-zing', 'micromania'],
    ),
    LoyaltyBrand(
      id: 'cdiscount',
      name: 'Cdiscount',
      primary: Color(0xFF4A2D8C),
      secondary: Color(0xFFFF6600),
      monogram: 'C',
      qrHints: ['cdiscount.com', 'cdiscount'],
    ),
    // ── Sport ────────────────────────────────────────────────────────────────
    LoyaltyBrand(
      id: 'intersport',
      name: 'Intersport',
      primary: Color(0xFFED1C24),
      secondary: Color(0xFF1A1A1A),
      monogram: 'I',
      qrHints: ['intersport.fr', 'intersport.com', 'intersport'],
    ),
    LoyaltyBrand(
      id: 'gosport',
      name: 'Go Sport',
      primary: Color(0xFF1A1A1A),
      secondary: Color(0xFFED1C24),
      monogram: 'GS',
      qrHints: ['go-sport.com', 'gosport', 'go sport'],
    ),
    // ── Auto ─────────────────────────────────────────────────────────────────
    LoyaltyBrand(
      id: 'norauto',
      name: 'Norauto',
      primary: Color(0xFF004F9E),
      secondary: Color(0xFF003670),
      monogram: 'N',
      qrHints: ['norauto.fr', 'norauto.com', 'norauto'],
    ),
    LoyaltyBrand(
      id: 'feuvert',
      name: 'Feu Vert',
      primary: Color(0xFF009640),
      secondary: Color(0xFF007030),
      monogram: 'FV',
      qrHints: ['feuvert.fr', 'feuvert', 'feu vert'],
    ),
    LoyaltyBrand(
      id: 'total',
      name: 'TotalEnergies',
      primary: Color(0xFFE2001A),
      secondary: Color(0xFF0054A4),
      monogram: 'T',
      qrHints: ['totalenergies.fr', 'total.fr', 'totalenergies'],
    ),
    // ── Restauration ─────────────────────────────────────────────────────────
    LoyaltyBrand(
      id: 'paul',
      name: 'Paul',
      primary: Color(0xFF1A1A1A),
      secondary: Color(0xFFC4A035),
      monogram: 'P',
      qrHints: ['paul.fr', 'paul-boulangerie', 'paul'],
    ),
    LoyaltyBrand(
      id: 'quick',
      name: 'Quick',
      primary: Color(0xFFE2001A),
      secondary: Color(0xFFFFCC00),
      monogram: 'Q',
      qrHints: ['quick.fr', 'quick.com', 'quick'],
    ),
    LoyaltyBrand(
      id: 'kfc',
      name: 'KFC',
      primary: Color(0xFFE4002B),
      secondary: Color(0xFF1A1A1A),
      monogram: 'K',
      qrHints: ['kfc.fr', 'kfc.com', 'kfc'],
    ),
    LoyaltyBrand(
      id: 'burgerking',
      name: 'Burger King',
      primary: Color(0xFFEC7000),
      secondary: Color(0xFF502314),
      monogram: 'BK',
      qrHints: ['burgerking.fr', 'burgerking.com', 'burger king'],
    ),
    LoyaltyBrand(
      id: 'dominos',
      name: "Domino's",
      primary: Color(0xFF006491),
      secondary: Color(0xFFE31837),
      monogram: 'D',
      qrHints: ['dominos.fr', 'dominos.com', 'dominos'],
    ),
    LoyaltyBrand(
      id: 'flunch',
      name: 'Flunch',
      primary: Color(0xFFE2001A),
      secondary: Color(0xFFFFCC00),
      monogram: 'F',
      qrHints: ['flunch.fr', 'flunch-traveller', 'flunch'],
    ),
    // ── E-commerce ───────────────────────────────────────────────────────────
    LoyaltyBrand(
      id: 'veepee',
      name: 'Veepee',
      primary: Color(0xFFEC008C),
      secondary: Color(0xFF9E0056),
      monogram: 'V',
      qrHints: ['veepee.fr', 'vente-privee.com', 'veepee', 'vente privée'],
    ),
    LoyaltyBrand(
      id: 'rakuten',
      name: 'Rakuten',
      primary: Color(0xFFBF0000),
      secondary: Color(0xFF1A1A1A),
      monogram: 'R',
      qrHints: ['rakuten.fr', 'rakuten.com', 'rakuten', 'price Minister'],
    ),
  ];

  static LoyaltyBrand? byId(String? id) {
    if (id == null || id.isEmpty || id == 'custom') return null;
    for (final b in catalog) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Retrouve une marque par nom (cartes ajoutées avant brand_id).
  static LoyaltyBrand? byName(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final n = name.trim().toLowerCase();
    for (final b in catalog) {
      if (b.name.toLowerCase() == n || b.id == n) return b;
    }
    // Correspondance partielle (ex. « maxi zoo » → Maxi Zoo).
    if (n.length >= 3) {
      for (final b in catalog) {
        final bn = b.name.toLowerCase();
        if (bn.contains(n) || n.contains(bn)) return b;
        for (final hint in b.qrHints) {
          final h = hint.toLowerCase();
          if (h.length >= 3 && n.contains(h)) return b;
        }
      }
    }
    return null;
  }

  static LoyaltyBrand custom({
    required String name,
    required Color color,
  }) =>
      LoyaltyBrand(
        id: 'custom',
        name: name,
        primary: color,
        monogram: name.isNotEmpty ? name[0].toUpperCase() : '?',
      );
}
