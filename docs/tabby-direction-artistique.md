# Tabby — Direction artistique / Design system

## 1. Principes

- Fun et moderne, **sans gamification** — la personnalité vient de la forme (couleurs, formes organiques, lettrage) et non de mécaniques ludiques (pas de badges, points, streaks).
- Palette chaude, cohérente du splash screen jusqu'aux écrans de contenu.
- Formes arrondies et organiques plutôt que géométriques/techniques, en écho aux rubans ondulés du splash.

## 2. Palette de couleurs (proposition — à valider visuellement)

| Rôle | Couleur | Hex indicatif |
|---|---|---|
| Primaire (marque) | Jaune moutarde | `#F2C230` |
| Fond clair | Crème / blanc cassé | `#FFF8E7` |
| Surface (cartes) | Blanc | `#FFFFFF` |
| Texte principal | Anthracite chaud | `#2E2A22` |
| Succès / "on te doit" | Vert sauge | `#4C9A6A` |
| Alerte / "tu dois" / budget dépassé | Corail/rouge chaud | `#E4573D` |
| Avertissement / proche du seuil | Orange | `#F0932B` |
| Accent secondaire (CTA) | Corail | `#F17C58` |

Les teintes exactes sont à ajuster une fois testées sur écran (contraste, accessibilité) — elles servent de point de départ cohérent avec le jaune du splash déjà validé.

## 3. Typographie

- **Titres et montants** : police display arrondie avec du caractère, proche de l'esprit du logotype (ex. Baloo 2, Fredoka, ou Quicksand en bold) — réservée aux gros chiffres et titres d'écran pour ne pas fatiguer sur les écrans denses.
- **Texte courant** (listes de dépenses, formulaires, labels) : police neutre très lisible (ex. Inter, Manrope) — priorité à la lisibilité sur les écrans à forte densité d'information (Home, Budget).
- Hiérarchie suggérée : montant d'une dépense en gras large, nom en poids medium, métadonnées (date, payeur) en gris clair plus petit.

## 4. Formes et motifs

- **Rubans ondulés** du splash réutilisables en motif discret : header de certains écrans, fond léger d'une carte mise en avant — jamais sur les écrans de saisie dense (Add, formulaires) pour garder la lisibilité.
- **Coins arrondis généreux** sur toutes les cartes et boutons (cohérent avec le logotype et les pastilles "+ Add group" / "+ Add expense" déjà vues sur le mock Home).
- **Stack d'avatars superposés** : pattern réutilisé pour les groupes (Home) et pourrait aussi inspirer l'affichage empilé des cartes de fidélité (Cards).

## 5. Iconographie

- Icônes de catégories en style **doodle/illustré arrondi** (façon sticker) plutôt que filaire type Material par défaut — renforce le côté fun sans mécanique de jeu.
- Catégories par défaut à couvrir au minimum : Loyer, Courses, Restaurant, Transport, Loisirs, Factures/Abonnements, Santé, Autre — plus les catégories custom créées par l'utilisateur (ex. "Chien").
- Chaque catégorie a une couleur assignée automatiquement à la création (palette dédiée de 8-10 teintes vives et différenciées, distincte de la palette principale de l'app pour rester lisible dans le camembert).

## 6. Composants clés à designer en priorité

1. **GroupCard** (Home) — déjà esquissée sur le mock : avatar stack, nom, solde coloré, bouton d'action.
2. **CategoryPill** (sélecteur horizontal dans Add) — icône doodle + label, état sélectionné/non sélectionné.
3. **BudgetBar** — barre de progression arrondie avec les 3 états de couleur (vert/orange/rouge).
4. **PieChart custom** — pas de rendu "chart library" brut par défaut : à styliser pour rester dans l'esprit organique (segments avec léger espacement, coins légèrement arrondis si la lib le permet).
5. **LoyaltyCardStack** (Cards) — effet d'empilement, ombres douces.

## 7. Dark mode

Prévu comme paramètre dans Profile — à décliner une fois la palette claire validée (fond anthracite chaud plutôt que noir pur, pour rester dans la famille de teintes chaudes de l'app plutôt que basculer vers un dark mode froid générique).
