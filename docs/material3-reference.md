# Material 3 — Référence pour Tabby
_Mis à jour : septembre 2026 — Flutter 3.44.6_

## Contexte Flutter 2026

### Flutter 3.47 (août 2026) — À noter mais pas encore utilisé
- `material_ui` et `cupertino_ui` sont désormais des packages standalone sur pub.dev
- Migration : `dart fix --apply --code=migrate_design_widgets`
- Deprecation des imports `package:flutter/material.dart` prévue en nov. 2026
- **Pour Tabby (Flutter 3.44.6)** : on reste sur `package:flutter/material.dart`, migration future

### Material 3 Expressive (Google I/O 2026)
- 14 nouveaux composants : ButtonGroup, FABMenu, SplitButton, Toolbar, etc.
- Nouveau système de motion : **springs physiques** (spatial + effects) remplace duration+easing
- Flutter : **non disponible nativement** (Android Compose only pour l'instant)
- Package tiers : `material_3_expressive` disponible sur pub.dev si on veut les composants M3E
- **Pour Tabby** : on n'adopte pas M3E pour l'instant, on reste sur M3 standard

---

## Système de couleurs M3 en place (Tabby)

### Seed color
```dart
AppColors.primary = Color(0xFFFFDB5A)  // Jaune pastel (logo Tabby)
```

### Génération automatique via ColorScheme.fromSeed
```dart
ColorScheme.fromSeed(
  seedColor: AppColors.primary,
  brightness: Brightness.light | Brightness.dark,
)
// → génère ~30 rôles de couleurs harmonieux en HCT
```

### Rôles principaux à utiliser (NE PAS hardcoder de couleurs)
| Rôle | Usage |
|------|-------|
| `cs.primary` | Accent principal, boutons filled |
| `cs.onPrimary` | Texte/icône sur fond primary |
| `cs.primaryContainer` | Surfaces mises en valeur (indicator nav) |
| `cs.surface` | Fond de base |
| `cs.surfaceContainerLow` | Fond Scaffold, AppBar |
| `cs.surfaceContainer` | NavigationBar |
| `cs.surfaceContainerHigh` | Cards, surfaces surélevées |
| `cs.surfaceContainerHighest` | Inputs, chips, tags |
| `cs.onSurface` | Texte principal |
| `cs.onSurfaceVariant` | Texte secondaire, icônes inactives |
| `cs.outline` | Bordures actives |
| `cs.outlineVariant` | Dividers, bordures légères |
| `cs.inverseSurface` | SnackBar fond |
| `cs.onInverseSurface` | Texte sur SnackBar |
| `cs.error` | Erreurs |
| `cs.errorContainer` | Fond d'erreur doux |

### Couleurs sémantiques métier (AppColors)
```dart
AppColors.success = Color(0xFF4C9A6A)  // "On te doit" — crédit
AppColors.danger  = Color(0xFFE4573D)  // "Tu dois" / budget dépassé
AppColors.warning = Color(0xFFF0932B)  // Budget proche du seuil
```

### Dark mode
- **Aucune couleur hardcodée** → les rôles `cs.*` s'adaptent automatiquement
- `scaffoldBackgroundColor: cs.surfaceContainerLow` — NE PAS utiliser `Colors.black`
- Elevation en dark mode = tonal color tint (automatique avec surfaceContainerX)
- GRAD négatif (-25) en dark : réduit le poids visuel de la typo variable

---

## Typographie (Google Sans Flex)

Police variable avec 4 axes exploités :
- `wght` : poids (400–800)
- `ROND` : arrondi des lettres (0–100) — expressivité
- `GRAD` : grade, poids sans layout shift (−25 en dark, 0 en light)
- `opsz` : taille optique clampée entre 20 et 48

### Stratégie ROND par rôle
| Niveau | ROND | Effet |
|--------|------|-------|
| Display | 80–100 | Maximum expressif |
| Headline | 50–70 | Assertif et lisible |
| Title | 10–30 | Neutre avec caractère |
| Body/Label | 0 | Géométrique strict, lisibilité max |

---

## Composants M3 à utiliser (conformité)

### Navigation
```dart
NavigationBar         // Barre du bas ✅ (déjà en place)
AppBar / SliverAppBar // En-tête ✅
```

### Boutons (ordre de priorité M3)
1. `FilledButton` — action principale (CTA)
2. `FilledButton.tonal` — action secondaire importante
3. `OutlinedButton` — action neutre/annulation
4. `TextButton` — action tertiaire, liens
5. `IconButton` — action icône seule
6. `FloatingActionButton` — action principale flottante

### Surfaces et cards
```dart
Card(elevation: 0, color: cs.surfaceContainerHighest)  // Filled card M3
// Pas d'ombre en light, tonal elevation en dark
```

### Inputs
```dart
TextField(decoration: InputDecoration(filled: true))
// border: OutlineInputBorder avec BorderSide.none
// focusedBorder: avec cs.primary + width: 2
```

### Feedback
```dart
SnackBar(behavior: SnackBarBehavior.floating)  // Toujours floating en M3
showDialog(...)                                 // AlertDialog arrondi (28px)
showModalBottomSheet(...)                      // BottomSheet avec handle
```

### Chips (filtres, tags)
```dart
FilterChip(label: ..., selected: ..., onSelected: ...)
InputChip(...)
```

---

## Motion / Transitions

### Recommandations M3 pour Flutter 3.44

#### Transitions de page
```dart
// Dans MaterialApp :
theme: ThemeData(
  pageTransitionsTheme: PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),
)
```

#### Transitions de contenu (internes)
```dart
// Remplacement conditionnel de widget
AnimatedSwitcher(
  duration: Duration(milliseconds: 300),
  transitionBuilder: (child, animation) =>
      FadeTransition(opacity: animation, child: child),
)

// Taille animée
AnimatedSize(duration: Duration(milliseconds: 250), curve: Curves.easeInOut)

// Container animé
AnimatedContainer(duration: Duration(milliseconds: 200))
```

#### Curves M3 recommandées
| Situation | Curve |
|-----------|-------|
| Entrée d'éléments | `Curves.easeOut` |
| Sortie d'éléments | `Curves.easeIn` |
| Mouvements entre deux états | `Curves.easeInOut` |
| Accentuation (bounce léger) | `Curves.easeOutBack` |
| Déformations de conteneur | `Curves.fastOutSlowIn` |

#### Durées M3
| Type | Durée |
|------|-------|
| Micro (icon flip, toggle) | 100ms |
| Courte (fade, badge) | 200ms |
| Moyenne (card expand, dialog) | 300ms |
| Longue (page transition) | 400ms |

---

## Spacing & Layout

### Grille de 4dp
```
4   — espace minimal (icon/text gap)
8   — padding interne compact
12  — gap standard entre éléments
16  — padding latéral des pages
20  — gap entre sections
24  — padding card
32  — grande séparation
```

### Border radius M3
| Surface | Radius |
|---------|--------|
| Petits éléments (chips, badges) | 8px |
| Inputs, boutons | 14–16px |
| Cards | 20px |
| Dialogs, bottom sheets | 28px |
| Surfaces pleine page | 0 ou very large (28+) |

---

## Pattern offline / erreur réseau (pour Lot 8)

### Architecture
```
DioInterceptor → détecte les erreurs réseau
↓
ConnectivityBanner (widget permanent si offline)
↓
ScaffoldMessenger.SnackBar (erreur ponctuelle)
↓
Retry button (inline sur les écrans qui ont échoué)
```

### Comportement
- **Perte de connexion** : `ConnectivityBanner` rouge en haut, message "Pas de connexion"
- **Erreur serveur (5xx)** : SnackBar flottant avec message + bouton "Réessayer"
- **Erreur client (4xx)** : SnackBar flottant avec message explicite
- **Timeout (>10s)** : SnackBar "Connexion lente, réessayez"
- **Timeout Dio configuré** : `connectTimeout: 10s, receiveTimeout: 15s`

---

## Checkliste Dark Mode

- [ ] `ThemeMode.system` dans MaterialApp
- [ ] Zéro couleur hardcodée dans les widgets (uniquement `cs.*` ou `AppColors.*`)
- [ ] `scaffoldBackgroundColor` = `cs.surfaceContainerLow` (pas noir)
- [ ] GRAD axis = -25 en dark (déjà en place dans AppTheme)
- [ ] Tester : `SystemChrome.setSystemUIOverlayStyle` adapté au mode
- [ ] Vérifier les icônes de catégorie (couleurs hardcodées dans categoryPalette)

---

## Patterns Flutter spécifiques

### Accéder au thème
```dart
final cs = Theme.of(context).colorScheme;
final tt = Theme.of(context).textTheme;
```

### Responsive safe area
```dart
Padding(padding: MediaQuery.viewPaddingOf(context))
// vs MediaQuery.paddingOf(context) — toujours utiliser viewPaddingOf pour les fonds
```

### Éviter les rebuilds
```dart
// Préférer context.watch vs BlocBuilder quand toute la subtree rebuild est ok
// BlocBuilder avec buildWhen: pour les rebuilds ciblés
```
