# Tabby — Guide Material 3 Expressive

Ce document résume les conventions UI actuellement utilisées par l'application.
Le code de référence se trouve dans `app/lib/core/theme/` et
`app/lib/design_system/`.

## Fondations

`AppTheme` active Material 3 et construit les thèmes clair et sombre à partir
d'un `ColorScheme.fromSeed` vibrant. Les extensions de thème exposent :

- `context.tabbyColors` pour les rôles M3 ;
- `context.tabbySemantic` pour les états métier ;
- `context.tabbyShapes` pour les formes ;
- `context.tabbyType` pour la typographie expressive ;
- `context.tabbySpace` pour l'espacement.

Les composants fonctionnels doivent dépendre de ces tokens, pas de couleurs ou
rayons recopiés localement.

## Couleurs

La triade de marque est définie dans `app_colors.dart` :

```dart
AppColors.seed        // cobalt, primary
AppColors.vermillion  // secondary
AppColors.lemon       // tertiary et surfaces tonales
```

Règles d'usage :

| Rôle | Usage |
| --- | --- |
| `primary` | Action principale, sélection forte |
| `primaryContainer` | Indicateur, surface sélectionnée |
| `secondary` | Accent vermillon ponctuel |
| `tertiaryContainer` | Surface citron de mise en avant |
| `surface` | Fond principal |
| `surfaceContainerLow` | Cartes et bottom sheets calmes |
| `surfaceContainer` | Navigation et regroupements |
| `surfaceContainerHighest` | Champs et surfaces denses |
| `onSurfaceVariant` | Texte et icônes secondaires |
| `outlineVariant` | Séparateurs et bordures discrètes |
| `error` / `errorContainer` | Erreurs et actions destructives |

Ne pas transmettre une information uniquement par la couleur : ajouter un
libellé, une valeur ou une icône.

## Typographie

Google Sans Flex est embarquée comme police variable. Utiliser en priorité le
`TextTheme` M3 ou les styles de `TabbyTypographyTokens`.

- Figures financières : `figureHero`, `figureMedium`.
- Titres éditoriaux : `displayEditorial`.
- Contenu courant : `body*` et `label*` du `TextTheme`.
- Les axes `ROND` et `GRAD` sont configurés par les tokens ; ne pas les
  redéfinir écran par écran.

## Formes et espacement

`TabbyShapeTokens` fournit les rayons, formes de cartes, boutons et modales.
`TabbySpaceTokens` fournit l'échelle d'espacement.

Principes :

- réserver les formes les plus expressives aux hero cards et accents ;
- conserver les formulaires visuellement calmes ;
- préférer les surfaces tonales aux ombres ;
- garder une cible tactile d'au moins 48 dp ;
- utiliser les tokens avant d'introduire une nouvelle valeur.

## Composants

Le barrel `app/lib/design_system/design_system.dart` expose les primitives
partagées :

- actions : boutons, FAB menu, button groups, overflow menu ;
- données : hero, figures et badges ;
- feedback : loading, empty, error, offline et snackbars ;
- saisie : montant, date, mot de passe, catégories et dropdowns ;
- overlays : sheets, confirmations, dialogs et action sheets ;
- surfaces : cartes tonales et cartes de liste ;
- identité : avatar, logo, code d'invitation et glyphes de catégorie.

Avant de créer un widget ad hoc dans une feature, vérifier qu'un composant
équivalent n'existe pas déjà dans ce barrel.

## Mouvement

Tabby utilise :

- Fade Through entre les destinations principales ;
- Shared Axis pour les écrans de détail ;
- animations d'entrée discrètes sur les synthèses et listes ;
- animations de pression sur certaines actions expressives.

Toute animation doit :

1. communiquer un changement d'état ou de hiérarchie ;
2. rester courte et interrompable ;
3. respecter `MediaQuery.disableAnimationsOf(context)` ;
4. éviter de redémarrer lors d'un rebuild sans changement métier.

## États système

Utiliser les composants dédiés :

```dart
TabbyLoading()
TabbyEmptyState(...)
TabbyErrorState(...)
TabbyOfflineState(...)
showTabbySnack(...)
```

Chaque erreur doit proposer une action pertinente : réessayer, revenir,
se reconnecter ou vérifier le réseau.

## Accessibilité

Avant validation d'un nouvel écran :

- tester TalkBack et l'ordre de lecture ;
- ajouter des labels aux contrôles custom et icônes seules ;
- vérifier une taille de texte à 200 % ;
- contrôler les contrastes clair et sombre ;
- ne pas masquer une action uniquement derrière un long press ;
- respecter la réduction des animations.

## Checklist de revue

- [ ] Aucun token visuel métier n'est redéfini dans la feature.
- [ ] Les thèmes clair et sombre sont lisibles.
- [ ] Les états loading, empty, error et offline sont traités.
- [ ] Les actions destructives sont explicites et protégées.
- [ ] Les contrôles custom ont une sémantique accessible.
- [ ] Les animations ont un rôle fonctionnel et respectent reduce motion.
- [ ] Les textes sont localisés en français et en anglais.
