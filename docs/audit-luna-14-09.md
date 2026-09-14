# Audit technique, UX et Material 3 Expressive — Tabby

## 1. Problèmes Code/Backend

### Architecture et dette technique

| Priorité | Zone | Constat | Impact |
|---|---|---|---|
| P0 | `backend/app/api/v1/*.py` | Les endpoints contiennent directement validation, accès DB, calcul métier, notifications et mapping DTO | Tests difficiles, duplication, faible évolutivité |
| P0 | `backend/app/api/v1/groups.py` / `expenses.py` | Logique de calcul des soldes et splits répartie entre endpoints et `core/balance.py` | Risque d’incohérences lors des évolutions |
| P1 | `backend/app/api/v1/budgets.py`, `stats.py`, `personal_expenses.py` | Requêtes et règles métier similaires dupliquées entre dépenses personnelles et groupes | Corrections à maintenir à plusieurs endroits |
| P1 | Flutter `lib/data/*_repository.dart` | Repositories très minces, sans cache, pagination, mapping d’erreur métier ou invalidation centralisée | Multiplication des appels réseau et états transitoires |
| P1 | Flutter `features/*/cubit` | Orchestration inter-features manuelle (`HomeCubit` recharge après événements externes) | Couplage implicite, états facilement obsolètes |
| P2 | `docs/tabby-cahier-technique.md` | Documentation partiellement divergente du code actuel | Risque d’erreurs d’intégration |

### Backend : performances et requêtes

- **P0 — N+1 dans le scheduler** : `backend/app/scheduler.py`
  - Une requête d’existence + une requête membres par récurrence.
  - `selectinload(RecurringExpense.generated_expenses)` charge une relation complète inutilement.
  - Remplacer par traitement groupé, contrainte unique SQL sur `(recurring_source_id, expense_date)` et insertion idempotente avec `ON CONFLICT`.

- **P0 — Absence de pagination** : `backend/app/api/v1/expenses.py`
  - `GET /groups/{group_id}/expenses` retourne toutes les dépenses.
  - Ajouter `limit`, curseur/offset, filtres date/catégorie et index.

- **P1 — Calculs coûteux en Python** : `backend/app/api/v1/groups.py::_load_group_with_balance`
  - Toutes les dépenses et splits sont chargés pour calculer un solde.
  - Prévoir agrégation SQL ou cache de soldes si le volume augmente.

- **P1 — Validation DB dispersée** : `backend/app/api/v1/expenses.py`
  - Appartenances membres vérifiées par plusieurs requêtes.
  - Vérifier explicitement le rattachement autorisé des catégories.
  - Centraliser et renforcer la validation de somme des splits.

- **P1 — Index à vérifier/ajouter** :
  - `expense(group_id, expense_date)`.
  - `expense(recurring_source_id, expense_date)`.
  - `expense_split(expense_id)`.
  - `group_member(user_id)`.
  - `budget(user_id, category_id)`.
  - `group_invite(code, expires_at, used_at)`.

- **P1 — Concurrence du scheduler** : `backend/app/main.py`, `scheduler.py`
  - Chaque instance FastAPI démarre le scheduler.
  - Utiliser un worker séparé, un advisory lock PostgreSQL ou une contrainte unique robuste.

- **P1 — Notifications synchrones** : `backend/app/api/v1/expenses.py`
  - FCM est appelé dans le cycle HTTP.
  - Déporter vers une queue/background task avec retry et déduplication.

- **P2 — Transaction longue** : `backend/app/scheduler.py`
  - Toutes les récurrences sont traitées dans une transaction.
  - Utiliser des commits par lot ou par période.

### Sécurité et robustesse

- `backend/app/main.py`
  - Vérifier que `DEBUG` ne puisse pas être activé en production.
  - Réduire CORS à des méthodes et headers nécessaires en production.

- `backend/app/api/v1/auth.py`
  - Vérifier rotation, révocation et purge des refresh tokens expirés.
  - Ajouter audit des sessions/appareils et limitation globale par IP/utilisateur.

- `backend/app/api/v1/avatars.py`, `auth.py`
  - Contrôler taille maximale, MIME réel et dimensions d’image.
  - Ajouter quota et nettoyage des anciens fichiers.

- `app/lib/core/api/api_client.dart`
  - Le retry réutilise directement `RequestOptions` : vérifier les requêtes non rejouables avec body/stream.
  - Ajouter limite de retry et gestion hors-ligne explicite.
  - Le singleton `apiClient` complique les tests et l’isolation multi-environnement.

### Flutter : état, performance et mémoire

- `app/lib/features/home/screens/home_screen.dart`
  - Écoute manuelle de `GoRouter.routerDelegate` et chemin littéral `'/home'`.
  - Préférer invalidation explicite après mutation ou store partagé.

- `app/lib/features/home/cubit/home_cubit.dart`
  - `loadGroups()` ne déduplique pas les appels concurrents.
  - Ajouter mutex, annulation ou identifiant de requête.
  - Les changements personnels rechargent groupes et dépenses : limiter l’invalidation aux données affectées.

- `app/lib/core/router/app_router.dart`
  - Vérifier le `dispose()` de `_AuthListenable` et couvrir le cycle de vie par test.

- Contrôleurs Flutter
  - Auditer systématiquement `TextEditingController`, `ScrollController`, `AnimationController` et subscriptions.
  - Ajouter tests widget de navigation, auth et fermeture de sheets.

- Pas de cache local
  - Cohérent avec la documentation mais pénalisant au démarrage et sur réseau Tailscale.
  - Ajouter au minimum un cache mémoire court avec stale-while-revalidate.

### Validation observée

- `flutter analyze` : aucune erreur bloquante, **6 infos**.
  - 5 `use_null_aware_elements` dans `lib/data/personal_expenses_repository.dart`.
  - 1 API dépréciée `MaterialUiCompatibilityBridge` dans `lib/main.dart`.
- Trois dépendances ont des versions plus récentes incompatibles avec les contraintes actuelles.
- Tests présents côté Flutter et backend ; couverture API d’intégration et performance non vérifiée.

---

## 2. Friction UX & Design M3 Expressive

### Parcours utilisateur

| Parcours | Points fluides | Frictions majeures |
|---|---|---|
| Authentification | JWT refresh, biométrie prévue, écrans dédiés | Erreurs réseau/auth à rendre actionnables ; récupération de compte peu visible |
| Home | Solde global, groupes épinglables, pull-to-refresh, état vide travaillé | Dépendance réseau totale ; attente sans données précédentes ; rechargements implicites |
| Création dépense | Flow séparé, catégories, splits, montant dédié | Parcours long ; validation des splits tardive ; gestion clavier/scroll |
| Groupe | Invitation par code, membres, soldes | Règlement à rendre plus explicite : qui doit quoi, confirmation et retour d’état |
| Budget | Vues dédiées et couleurs sémantiques | Couleurs seules insuffisantes ; manque d’explication du calcul et du reste |
| Cartes fidélité | Scanner et affichage plein écran | Accès rapide à la carte prioritaire à renforcer ; erreurs caméra/scanner inline |

### M3 Expressive : recommandations

#### Surfaces et hiérarchie

- Utiliser une hiérarchie stable : `surface`, `surfaceContainerLow`, `surfaceContainer`, `primaryContainer`.
- Réduire les ombres au profit du contraste tonal et de `outlineVariant`.
- Réserver les formes organiques fortes aux hero cards, soldes et empty states.
- Garder les formulaires denses visuellement calmes.

#### Couleurs et accessibilité

- Contrôler le contraste de la primaire `#F2C230` avec `onPrimary`.
- Ne jamais représenter un état uniquement par vert/orange/rouge : ajouter icône, libellé et valeur.
- Vérifier les contrastes du texte secondaire, labels, soldes négatifs et dark mode.
- Centraliser les couleurs sémantiques dans `AppColors`/extensions.

#### Typographie

- Réserver les grandes graisses aux soldes, titres et totaux.
- Garder les métadonnées lisibles et suffisamment contrastées.
- Harmoniser les tailles entre `Hero`, `GroupCard`, `BudgetCard` et détail dépense.

#### Micro-interactions

- Feedback tactile léger sur pin/unpin, ajout, règlement et copie du code.
- `AnimatedSwitcher`/transitions pour loading → loaded et évolution du solde.
- Éviter les animations à chaque rebuild ; les déclencher à l’entrée ou lors d’un vrai changement.
- Ajouter skeletons plutôt qu’un loader global.
- Optimistic update pour pin, snackbar avec Undo pour suppression et confirmation inline après création.

#### Home

- Conserver le hero de solde global.
- Éviter la redondance entre bouton `New group` et bouton flottant.
- Ajouter état offline distinct de l’erreur serveur.
- Afficher la date de dernière synchronisation si un cache est introduit.
- Dans `GroupCard`, expliciter `Vous devez` / `On vous doit`.

#### Création de dépense

- Parcours progressif : montant, catégorie, payeur, participants, date.
- Préremplir date, dernier payeur, split égal et groupe courant.
- Afficher somme des splits et écart au montant en temps réel.
- Désactiver le CTA avec une raison explicite.
- Préserver le brouillon à la fermeture accidentelle du sheet.

#### Budget et statistiques

- Afficher dépensé, plafond, restant et projection de fin de mois.
- Styliser les graphiques avec espacement, légende persistante et labels accessibles.
- Conserver le filtre de période entre écrans.
- Séparer couleur de catégorie et couleur de statut budgétaire.

#### États système

- Uniformiser `Loading`, `Empty`, `Error`, `Offline`, `Unauthorized`.
- Proposer une action par erreur : réessayer, se reconnecter, vérifier le réseau ou revenir à Home.
- Ajouter les annonces semantics pour soldes et confirmations importantes.

---

## 3. Plan d'action priorisé

### P0 — Risques fonctionnels et scalabilité

1. Rendre les dépenses récurrentes idempotentes : contrainte unique SQL, insertion atomique, advisory lock ou worker unique.
2. Ajouter pagination, filtres et index aux dépenses.
3. Centraliser les validations de catégorie, membership, splits et permissions.
4. Décorréler FCM du cycle HTTP avec queue/background task, retry et déduplication.
5. Traiter les états réseau Flutter et dédupliquer les appels `HomeCubit`.

### P1 — Maintenabilité et performance

1. Extraire `GroupService`, `ExpenseService`, `BudgetService` et `RecurringExpenseService` côté backend.
2. Remplacer les calculs de solde complets par agrégations SQL ou cache invalidé.
3. Regrouper les requêtes du scheduler.
4. Introduire un store/cache Flutter mémoire avec invalidation après mutation.
5. Réduire les rechargements implicites de Home liés au routeur.
6. Auditer tous les `dispose()` et subscriptions ; ajouter des tests de cycle de vie.
7. Remplacer `MaterialUiCompatibilityBridge` dans `app/lib/main.dart`.
8. Corriger les cinq lint infos de `personal_expenses_repository.dart`.

### P2 — UX et design system

1. Uniformiser les tokens M3 : couleurs, surfaces, typographie, rayons et espacements.
2. Ajouter skeletons et transitions d’état.
3. Revoir la création de dépense avec validation des splits en temps réel.
4. Clarifier soldes et règlements avec textes directionnels.
5. Renforcer les états offline, empty et error.
6. Vérifier accessibilité, contrastes, semantics et cibles tactiles.

### P3 — Évolution produit

1. Ajouter cache persistant/offline partiel.
2. Ajouter synchronisation optimiste et résolution de conflits.
3. Ajouter observabilité : latence DB, erreurs API, durée scheduler et notifications FCM.
4. Ajouter tests d’intégration API avec PostgreSQL réel.
5. Ajouter tests de charge sur groupes nombreux, historique volumineux et génération concurrente.
