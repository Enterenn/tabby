# Tabby — Roadmap de développement

Découpage en lots pour attaquer le développement avec Cursor/Composer de façon incrémentale, sans suivre une méthode formelle type BMAD, mais en gardant un ordre logique de dépendances.

## Lot 0 — Fondations
- Setup repo GitHub, clone local, ouverture Cursor.
- Setup backend (choix Python/FastAPI ou Node/Express), connexion PostgreSQL, migrations initiales.
- Setup projet Flutter (structure de dossiers, thème de base avec la palette provisoire).
- Déploiement du backend en LXC sur le home server, accessible via Tailscale — valider la connexion app ↔ serveur avec un endpoint `/health` avant d'aller plus loin.

## Lot 1 — Auth & groupes
- Endpoints `auth/register`, `auth/login`, `auth/refresh`.
- Modèles `User`, `Group`, `group_member`, `group_invite`.
- Écrans : inscription/connexion, création de groupe, invitation par code, écran Profile (liste des groupes).
- Objectif de fin de lot : toi et ta copine pouvez créer vos comptes et former le groupe "Couple".

## Lot 2 — Catégories & dépenses de base
- Modèles `Category`, `Expense`, `ExpenseSplit`.
- Catégories par défaut pré-remplies en base (seed).
- Écran Add complet (montant, nom, catégorie, payeur, répartition égale).
- Écran Home avec la GroupCard et le solde calculé.
- Objectif de fin de lot : ajouter une dépense simple et voir le solde se mettre à jour sur Home.

## Lot 3 — Répartition personnalisée & catégories custom
- Section répartition personnalisée dans Add (montants/% par membre).
- Création de catégorie à la volée depuis Add + gestion complète des catégories dans Profile.
- Objectif de fin de lot : créer la catégorie "Chien" et répartir une dépense de façon non égale.

## Lot 4 — Dépenses récurrentes
- Modèle `RecurringExpense` + job planifié de génération mensuelle.
- Toggle "Répéter chaque mois" dans Add.
- Écran de gestion des récurrences actives (probable ajout dans Profile ou dans le détail de groupe).
- Objectif de fin de lot : le loyer se recrée automatiquement chaque mois sans ressaisie.

## Lot 5 — Budgets
- Modèle `Budget`, calcul du statut vert/orange/rouge à la volée.
- Affichage des barres de budget dans l'écran Budget.
- Flow de création/édition d'un budget par catégorie.
- Objectif de fin de lot : définir un budget "150€/mois" pour une catégorie et voir l'indicateur changer de couleur en le dépassant.

## Lot 6 — Statistiques
- Endpoint d'agrégation `stats` (par groupe + vue consolidée).
- Camembert + liste ordonnée par % dans l'écran Budget.
- Navigation mois/année, toggle groupe actif / tous les groupes.
- Objectif de fin de lot : écran Budget complet et fonctionnel.

## Lot 7 — Cartes de fidélité
- Modèle `LoyaltyCard`.
- Écran Cards : liste, scan code-barres/QR, affichage plein écran, réorganisation.
- Objectif de fin de lot : ajouter une vraie carte de fidélité et la scanner en caisse depuis l'app.

## Lot 8 — Finitions
- Écran de détail de groupe (historique complet, membres, réglages) — à spécifier plus précisément le moment venu.
- Dark mode.
- Polish visuel complet selon le document Direction artistique (motifs ondulés, icônes doodle, animations douces).
- Gestion d'erreurs réseau soignée (l'app étant 100% online, les retours en cas de perte de connexion doivent être clairs).

## Points à trancher au fil de l'eau
Voir la section "Points ouverts" du Cahier des charges — certains choix (portée par défaut des stats, mécanisme d'invitation exact, visibilité de la répartition personnalisée) sont volontairement laissés ouverts pour être validés à l'usage réel plutôt que figés avant d'avoir testé l'app.
