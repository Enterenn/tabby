Sprint Tabby — Plan de correction

## Lot 0 — Cadrage et sécurité de livraison

**Objectif :** établir une base fiable avant les changements fonctionnels.

### Tâches

- Figer le contrat API réel depuis les routes et schémas actuels.
- Comparer le code avec :
  - `docs/tabby-cahier-technique.md`
  - `docs/tabby-cahier-des-charges.md`
  - `docs/tabby-roadmap.md`
- Ajouter une matrice des endpoints :
  - authentification ;
  - groupes ;
  - dépenses ;
  - budgets ;
  - statistiques ;
  - récurrences ;
  - cartes fidélité.
- Ajouter tests d'intégration API avec PostgreSQL.
- Vérifier les migrations Alembic et les contraintes existantes.
- Corriger les lint Flutter existants.
- Remplacer `MaterialUiCompatibilityBridge`.
- Ajouter une commande de validation globale documentée.

### Critères de sortie

- `flutter analyze` sans issue.
- Tests backend verts.
- Contrat API documenté et aligné avec l'implémentation.
- Aucun changement fonctionnel non testé.

---

## Lot 1 — Intégrité des données et concurrence backend

**Priorité : P0**

**Objectif :** empêcher les doublons, incohérences de splits et générations concurrentes.

### Tâches

- Ajouter une contrainte d'unicité sur les dépenses récurrentes générées :
  - idéalement `(recurring_source_id, expense_date)`.
- Ajouter les migrations Alembic correspondantes.
- Rendre la génération récurrente idempotente avec insertion atomique.
- Ajouter un verrou PostgreSQL ou déplacer le scheduler dans un worker dédié.
- Centraliser les validations :
  - catégorie autorisée ;
  - membre du groupe ;
  - payeur membre ;
  - participants membres ;
  - somme exacte des splits ;
  - montant positif.
- Vérifier les contraintes de suppression et d'intégrité FK.
- Ajouter tests de concurrence et de relance du scheduler.

### Fichiers ciblés

- `backend/app/scheduler.py`
- `backend/app/api/v1/expenses.py`
- `backend/app/core/deps.py`
- `backend/app/models/models.py`
- `backend/alembic/versions/*`
- `backend/tests/test_scheduler.py`
- `backend/tests/test_schemas.py`

### Critères de sortie

- Deux exécutions simultanées ne créent qu'une dépense récurrente.
- Aucun split invalide ne peut être persisté.
- Les catégories d'un autre utilisateur/groupe sont refusées.
- Tests de concurrence verts.

---

## Lot 2 — Performance DB et endpoints bornés

**Priorité : P0/P1**

**Objectif :** éviter les réponses non bornées et réduire les requêtes inutiles.

### Tâches

- Ajouter pagination aux dépenses :
  - `limit`;
  - curseur ou offset ;
  - date min/max ;
  - catégorie ;
  - statut.
- Ajouter pagination aux autres historiques volumineux si nécessaire.
- Ajouter les index PostgreSQL :
  - `expense(group_id, expense_date)`;
  - `expense(recurring_source_id, expense_date)`;
  - `expense_split(expense_id)`;
  - `group_member(user_id)`;
  - `group_invite(code, expires_at, used_at)`.
- Supprimer le `selectinload` inutile des dépenses générées dans le scheduler.
- Regrouper les requêtes d'existence des récurrences.
- Remplacer les calculs de soldes complets par agrégation SQL lorsque possible.
- Mesurer les requêtes lentes avec logs SQL en environnement de test.
- Ajouter tests de pagination et de filtrage.

### Fichiers ciblés

- `backend/app/api/v1/expenses.py`
- `backend/app/api/v1/groups.py`
- `backend/app/api/v1/stats.py`
- `backend/app/scheduler.py`
- `backend/app/core/database.py`
- `backend/alembic/versions/*`

### Critères de sortie

- Aucun endpoint d'historique ne retourne une collection illimitée.
- Les requêtes principales utilisent les index attendus.
- Le nombre de requêtes par endpoint critique est mesuré.
- Les réponses API restent compatibles avec l'application Flutter.

---

## Lot 3 — Découpage métier backend

**Priorité : P1**

**Objectif :** réduire la logique métier dans les endpoints et limiter les doublons.

### Tâches

Créer des services dédiés :

- `backend/app/services/group_service.py`
- `backend/app/services/expense_service.py`
- `backend/app/services/budget_service.py`
- `backend/app/services/recurring_service.py`
- `backend/app/services/notification_service.py`

Extraire :

- calcul de solde ;
- validation d'appartenance ;
- création/mise à jour de dépense ;
- construction des réponses ;
- génération récurrente ;
- notification de groupe ;
- règles de budget.

### Règles

- Les routers orchestrent uniquement :
  - parsing ;
  - dépendances ;
  - appel service ;
  - réponse HTTP.
- Les services ne dépendent pas de FastAPI.
- Les erreurs métier utilisent des exceptions dédiées.
- Les services sont testables avec une session DB isolée.

### Critères de sortie

- Endpoints réduits et lisibles.
- Validation métier non dupliquée.
- Tests unitaires des services.
- Aucune régression sur les permissions.

---

## Lot 4 — Notifications et traitements asynchrones

**Priorité : P1**

**Objectif :** éviter que FCM dégrade la latence ou la fiabilité des mutations.

### Tâches

- Déporter les notifications hors du cycle principal HTTP.
- Définir une abstraction `NotificationService`.
- Ajouter :
  - retry limité ;
  - logs structurés ;
  - timeout ;
  - suppression des tokens invalides ;
  - déduplication.
- Décider entre :
  - `BackgroundTasks` FastAPI pour une première version ;
  - worker/queue pour une version robuste.
- Ne jamais faire échouer la création d'une dépense à cause de FCM.
- Ajouter tests avec FCM simulé.

### Fichiers ciblés

- `backend/app/core/fcm.py`
- `backend/app/api/v1/expenses.py`
- `backend/app/api/v1/groups.py`
- `backend/app/services/notification_service.py`

### Critères de sortie

- Latence de création indépendante de la disponibilité FCM.
- Les erreurs FCM sont observables mais non bloquantes.
- Les tokens invalides sont nettoyés.

---

## Lot 5 — Cache et synchronisation Flutter

**Priorité : P1**

**Objectif :** rendre l'application plus fluide avec réseau lent ou indisponible.

### Tâches

- Ajouter un store mémoire centralisé pour :
  - groupes ;
  - détail groupe ;
  - dépenses ;
  - budgets.
- Implémenter :
  - cache court ;
  - stale-while-revalidate ;
  - invalidation après mutation ;
  - état de synchronisation.
- Dédupliquer les appels simultanés dans `HomeCubit`.
- Éviter le rechargement complet après chaque dépense personnelle.
- Remplacer le rechargement dépendant de `GoRouter.routerDelegate`.
- Ajouter états :
  - `loading` ;
  - `refreshing` ;
  - `offline` ;
  - `error` ;
  - `stale`.
- Conserver la possibilité de désactiver le cache via configuration de test.

### Fichiers ciblés

- `app/lib/features/home/cubit/home_cubit.dart`
- `app/lib/features/group_detail/cubit/group_detail_cubit.dart`
- `app/lib/data/repositories.dart`
- `app/lib/data/groups_repository.dart`
- `app/lib/core/api/api_client.dart`
- `app/lib/core/router/app_router.dart`

### Critères de sortie

- Le contenu précédent reste visible pendant un refresh.
- Les appels identiques simultanés sont fusionnés.
- Une mutation invalide uniquement les ressources nécessaires.
- Le mode offline est clairement distingué d'une erreur serveur.

---

## Lot 6 — Robustesse API Flutter et cycle de vie

**Priorité : P1**

**Objectif :** fiabiliser auth, retry, subscriptions et contrôleurs.

### Tâches

- Sécuriser le retry Dio :
  - nombre maximum de tentatives ;
  - gestion des body non rejouables ;
  - prévention des boucles ;
  - annulation si logout.
- Ajouter une abstraction d'erreurs typées :
  - réseau ;
  - timeout ;
  - authentification ;
  - validation ;
  - serveur.
- Auditer tous les :
  - `StreamSubscription` ;
  - `AnimationController` ;
  - `ScrollController` ;
  - `TextEditingController`.
- Vérifier tous les `dispose()`.
- Ajouter tests de cycle de vie et logout pendant requête.
- Ajouter tests de navigation après expiration du token.

### Fichiers ciblés

- `app/lib/core/api/api_client.dart`
- `app/lib/core/api/api_failure.dart`
- `app/lib/core/router/app_router.dart`
- `app/lib/core/services/fcm_service.dart`
- `app/lib/features/*`

### Critères de sortie

- Aucun leak détecté dans les parcours principaux.
- Une expiration de token ne crée pas de boucle de refresh.
- Les erreurs sont affichées avec une action adaptée.

---

## Lot 7 — États UX et parcours critiques

**Priorité : P1/P2**

**Objectif :** rendre l'expérience robuste, compréhensible et cohérente.

### Tâches

- Uniformiser les composants :
  - `Loading` ;
  - `Empty` ;
  - `Error` ;
  - `Offline` ;
  - `Unauthorized`.
- Ajouter une action à chaque erreur :
  - réessayer ;
  - se reconnecter ;
  - vérifier le réseau ;
  - revenir à Home.
- Revoir le parcours création de dépense :
  - montant ;
  - catégorie ;
  - payeur ;
  - participants ;
  - date.
- Valider les splits en temps réel.
- Préremplir date, payeur, groupe et split égal.
- Préserver les brouillons des formulaires.
- Clarifier les règlements :
  - débiteur ;
  - créancier ;
  - montant ;
  - confirmation ;
  - état final.
- Ajouter état offline sur Home et détail groupe.

### Fichiers ciblés

- `app/lib/design_system/feedback/*`
- `app/lib/features/add_expense/*`
- `app/lib/features/home/*`
- `app/lib/features/group_detail/*`
- `app/lib/design_system/overlays/*`

### Critères de sortie

- Tous les états réseau ont un rendu dédié.
- Les erreurs de split sont visibles avant soumission.
- Un utilisateur comprend immédiatement son solde et ses actions.
- Les formulaires ne perdent pas leur contenu accidentellement.

---

## Lot 8 — Design System Material 3 Expressive

**Priorité : P2**

**Objectif :** consolider la direction visuelle sans introduire de divergence entre écrans.

### Tâches

- Centraliser les tokens :
  - couleurs ;
  - surfaces ;
  - typographie ;
  - formes ;
  - espacements ;
  - élévations.
- Vérifier les contrastes clair/sombre.
- Remplacer les couleurs directes dans les features par les extensions de thème.
- Définir les états sémantiques :
  - positif ;
  - négatif ;
  - warning ;
  - neutre ;
  - offline.
- Uniformiser :
  - `GroupCard` ;
  - `BudgetCard` ;
  - `HeroBanner` ;
  - chips ;
  - boutons ;
  - sheets ;
  - champs.
- Réduire les ombres et utiliser davantage les surfaces tonales.
- Vérifier la cohérence de `GoogleSansFlex`.
- Ajouter animations d'entrée et de transition uniquement aux changements significatifs.
- Ajouter feedback tactile sur les actions clés.
- Ajouter semantics et labels accessibles.

### Fichiers ciblés

- `app/lib/core/theme/*`
- `app/lib/design_system/*`
- `app/lib/features/*/widgets/*`
- `app/lib/features/*/screens/*`

### Critères de sortie

- Aucun écran critique ne définit sa palette localement.
- Contraste vérifié en clair et sombre.
- Les états ne reposent pas uniquement sur la couleur.
- Les composants réutilisables couvrent les parcours principaux.

---

## Lot 9 — Sécurité, fichiers et exploitation

**Priorité : P1/P2**

**Objectif :** durcir l'exploitation self-hosted.

### Tâches

- Vérifier configuration production :
  - `DEBUG=false` ;
  - CORS explicite ;
  - secrets obligatoires ;
  - HTTPS ;
  - headers.
- Renforcer les uploads avatar :
  - taille ;
  - MIME réel ;
  - dimensions ;
  - quota ;
  - nettoyage.
- Ajouter purge des refresh tokens expirés.
- Ajouter logs structurés sans secrets.
- Ajouter health checks :
  - API ;
  - DB ;
  - scheduler.
- Ajouter métriques :
  - latence DB ;
  - erreurs HTTP ;
  - temps scheduler ;
  - notifications.
- Documenter sauvegarde/restauration PostgreSQL.
- Documenter rollback de migration.

### Critères de sortie

- Configuration de production vérifiable automatiquement.
- Aucun token ou mot de passe dans les logs.
- Les uploads invalides sont rejetés.
- La restauration d'une base est testée.

---

## Lot 10 — Tests de charge, accessibilité et release

**Priorité : P2/P3**

**Objectif :** valider le système complet avant stabilisation.

### Tâches

- Tests backend avec PostgreSQL réel.
- Tests de charge :
  - groupes nombreux ;
  - historique volumineux ;
  - génération concurrente ;
  - appels simultanés.
- Tests Flutter :
  - Home offline ;
  - refresh ;
  - logout pendant appel ;
  - formulaire dépense ;
  - splits invalides ;
  - navigation.
- Tests accessibilité :
  - contraste ;
  - tailles de texte ;
  - lecteur d'écran ;
  - cibles tactiles.
- Profilage Flutter :
  - frame rendering ;
  - rebuilds ;
  - mémoire ;
  - animations.
- Ajouter checklist de release Android.
- Mettre à jour README et documentation technique.

### Critères de sortie

- Suite backend et Flutter verte.
- Aucun problème critique de performance ou mémoire.
- Parcours critiques testés hors-ligne et réseau dégradé.
- Release reproductible et documentée.

---

# Ordre recommandé du sprint

| Ordre | Lot | Résultat attendu |
|---:|---|---|
| 1 | Lot 0 | Base de mesure et contrats alignés |
| 2 | Lot 1 | Données cohérentes et scheduler sûr |
| 3 | Lot 2 | API bornée et performante |
| 4 | Lot 3 | Backend maintenable |
| 5 | Lot 4 | Notifications non bloquantes |
| 6 | Lot 5 | App fluide avec cache et invalidation |
| 7 | Lot 6 | Auth/retry/lifecycle robustes |
| 8 | Lot 7 | Parcours UX fiables |
| 9 | Lot 8 | Design system M3 cohérent |
| 10 | Lot 9 | Sécurité et exploitation durcies |
| 11 | Lot 10 | Validation finale et release |

# Découpage en sprints courts

## Sprint A — Fondation technique

- Lot 0
- Lot 1
- Début Lot 2

## Sprint B — Performance backend

- Fin Lot 2
- Lot 3
- Lot 4

## Sprint C — Robustesse Flutter

- Lot 5
- Lot 6

## Sprint D — UX et Material 3

- Lot 7
- Lot 8

## Sprint E — Production et validation

- Lot 9
- Lot 10

# Definition of Done globale

- Tests automatisés verts.
- `flutter analyze` sans issue.
- Migrations appliquées sur une base de test.
- Aucun endpoint critique non borné.
- Aucune génération récurrente dupliquée.
- Erreurs réseau et offline traitées explicitement.
- Aucun leak de controller/subscription identifié.
- Contrastes et états accessibles vérifiés.
- Documentation et procédure de release mises à jour.
