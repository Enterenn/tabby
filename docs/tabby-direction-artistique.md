# Tabby — Direction artistique

Cette charte décrit l'identité actuellement implémentée. Les valeurs techniques
de référence vivent dans `app/lib/core/theme/` et dans le design system Flutter.

## Principes

- Une interface expressive, chaleureuse et moderne, sans gamification.
- Une hiérarchie forte pour les montants, soldes et actions principales.
- Des surfaces tonales et des formes généreuses plutôt que des ombres lourdes.
- Des écrans de saisie plus calmes que les cartes de synthèse.
- La couleur accompagne toujours un libellé, une valeur ou une icône.

## Palette POLA

| Rôle | Couleur | Valeur |
| --- | --- | --- |
| Primaire | Cobalt | `#0053E1` |
| Secondaire | Vermillon | `#FF4617` |
| Tertiaire | Citron | `#FEF335` |
| Succès | Vert | `#2EAA6B` |
| Avertissement | Orange | `#FF9800` |

Le `ColorScheme` clair et sombre est généré depuis le cobalt avec la variante
M3 `vibrant`, puis enrichi avec les accents vermillon et citron. Les widgets
doivent utiliser les rôles du thème (`colorScheme`, `tabbyColors`,
`tabbySemantic`) plutôt que recopier ces valeurs.

## Typographie

Tabby utilise **Google Sans Flex**, une police variable embarquée avec
l'application :

- `wght` structure la hiérarchie ;
- `ROND` donne davantage de personnalité aux titres et chiffres ;
- `GRAD` allège visuellement le thème sombre sans modifier la mise en page ;
- `opsz` adapte le dessin à la taille d'affichage.

Les styles éditoriaux et financiers sont centralisés dans
`TabbyTypographyTokens`. Le texte courant reste volontairement plus neutre.

## Formes, surfaces et mouvement

- Cartes, boutons, champs et modales utilisent `TabbyShapeTokens`.
- Les formes organiques fortes sont réservées aux hero cards et accents.
- Les niveaux `surfaceContainer*` créent la profondeur sans élévation excessive.
- Les transitions de navigation suivent les patterns Fade Through et Shared Axis.
- Les micro-interactions ne doivent accompagner que les changements significatifs.

## Iconographie

- Material Symbols Rounded pour la navigation et les actions.
- `TabbyCategoryGlyph` pour normaliser les catégories.
- Logos de marques dédiés dans le wallet de fidélité.
- Épaisseur, remplissage et taille des icônes varient selon l'état sélectionné.

## Composants emblématiques

- `ExpressiveHeroBanner` pour les synthèses financières ;
- `GroupCard` et `PersonalCard` sur l'accueil ;
- `ExpressiveTonalCard` pour les surfaces de mise en avant ;
- `TabbyAmountField`, `TabbyDateField` et les sélecteurs expressifs ;
- le wallet empilé et les cartes de fidélité plein écran ;
- les états `TabbyLoading`, `TabbyEmptyState`, `TabbyErrorState` et
  `TabbyOfflineState`.

## Thèmes et accessibilité

Les thèmes clair, sombre et système sont disponibles depuis le profil. Toute
évolution visuelle doit être vérifiée dans les deux luminosités, avec une grande
taille de texte et la réduction des animations activée.

Pour les règles d'implémentation, consulter
[`material3-reference.md`](./material3-reference.md).
