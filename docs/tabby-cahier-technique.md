# Tabby — Cahier technique

## 1. Architecture générale

```
[Flutter app - Android]  <---HTTPS/JSON--->  [API backend - LXC Proxmox]  <--->  [PostgreSQL - LXC/CT séparé]
        |                                              |
   Tailscale (réseau privé)                    Job planifié (dépenses récurrentes)
```

- **Client mobile** : Flutter/Dart, Android uniquement pour l'instant. Aucun stockage local — client HTTP pur, aucun cache/`sqflite`.
- **Backend** : API REST hébergée en conteneur LXC dédié sur le home server (Proxmox), cohérent avec l'architecture LXC-first déjà en place pour les autres services (Jellyfin, *arr stack, etc.).
- **Base de données** : PostgreSQL, dans son propre conteneur ou colocalisée avec l'API selon les ressources disponibles sur le home server. Choisi plutôt que SQLite pour gérer proprement la concurrence multi-device (toi + ta copine écrivant potentiellement en même temps).
- **Réseau** : accès exclusivement via **Tailscale** dans un premier temps — pas d'exposition publique via Nginx Proxy Manager tant que l'usage reste privé à quelques personnes. Chaque téléphone doit avoir le client Tailscale installé et connecté au même tailnet que le serveur.
- **Job planifié** : un scheduler côté serveur (cron système du LXC, ou scheduler intégré à l'API selon le framework) génère chaque mois les dépenses issues des `RecurringExpense`.

## 2. Stack technique recommandée

| Composant | Choix recommandé | Alternative |
|---|---|---|
| Frontend mobile | Flutter/Dart | — |
| State management | flutter_bloc (Cubit) | Riverpod |
| Backend API | FastAPI (Python) | Node.js/Express |
| Base de données | PostgreSQL | — |
| ORM | SQLAlchemy (si FastAPI) | Prisma (si Node) |
| Auth | JWT (access + refresh token) | — |
| Scheduler récurrences | APScheduler (Python) ou cron système | node-cron (si Node) |
| Hébergement | LXC Proxmox, réseau Tailscale | — |

Le choix Python/FastAPI vs Node/Express dépend surtout de ta familiarité — les deux tournent très bien en LXC avec peu de ressources. Recommandation : privilégier celui que tu maîtrises déjà pour itérer plus vite avec Composer.

## 3. Modèle de données

### 3.1 Schéma (DDL simplifié PostgreSQL)

```sql
CREATE TABLE "user" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE "group" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE group_member (
    group_id UUID REFERENCES "group"(id) ON DELETE CASCADE,
    user_id UUID REFERENCES "user"(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (group_id, user_id)
);

CREATE TABLE category (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES "group"(id) ON DELETE CASCADE, -- NULL si catégorie globale par défaut
    name TEXT NOT NULL,
    icon TEXT NOT NULL,          -- clé d'icône (ex. "dog", "rent")
    color TEXT NOT NULL,         -- hex
    is_default BOOLEAN DEFAULT false,
    sort_order INT DEFAULT 0
);

CREATE TABLE expense (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES "group"(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES category(id),
    paid_by UUID NOT NULL REFERENCES "user"(id),
    name TEXT NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    expense_date DATE NOT NULL,
    recurring_source_id UUID REFERENCES recurring_expense(id), -- NULL si dépense ponctuelle
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE expense_split (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expense_id UUID NOT NULL REFERENCES expense(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES "user"(id),
    amount NUMERIC(10,2) NOT NULL -- part de cet utilisateur dans la dépense
);

CREATE TABLE recurring_expense (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES "group"(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES category(id),
    paid_by UUID NOT NULL REFERENCES "user"(id),
    name TEXT NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    frequency TEXT NOT NULL CHECK (frequency IN ('monthly', 'yearly')),
    day_of_period INT NOT NULL, -- jour du mois de génération
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE budget (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES "group"(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES category(id),
    limit_amount NUMERIC(10,2) NOT NULL,
    period TEXT NOT NULL DEFAULT 'monthly' CHECK (period IN ('monthly')),
    UNIQUE (group_id, category_id)
);

CREATE TABLE loyalty_card (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    brand_name TEXT NOT NULL,
    code_type TEXT NOT NULL CHECK (code_type IN ('barcode', 'qrcode')),
    code_value TEXT NOT NULL,
    color TEXT,
    sort_order INT DEFAULT 0
);

CREATE TABLE group_invite (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES "group"(id) ON DELETE CASCADE,
    code TEXT UNIQUE NOT NULL, -- code à 6 chiffres ou token de lien
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ
);
```

### 3.2 Notes de modélisation

- `expense_split` permet une répartition arbitraire (pas forcément égale) — la somme des `amount` de tous les splits d'une dépense doit égaler `expense.amount` (contrainte applicative, à vérifier côté API avant insertion).
- Le statut vert/orange/rouge d'un `budget` **n'est jamais stocké** : calculé à la volée en comparant la somme des dépenses du mois pour `(group_id, category_id)` au `limit_amount`.
- `category.group_id` nullable permet de distinguer catégories globales par défaut (loyer, courses...) des catégories créées dans un groupe spécifique (ex. "Chien" créée dans le groupe "Couple").
- `group_invite` répond au point ouvert du cahier des charges (mécanisme d'invitation) — proposition : code à 6 chiffres à durée de vie limitée (ex. 24h), simple à saisir manuellement entre deux téléphones sans dépendance à un service d'email.

## 4. Endpoints API (proposition v1)

### Auth
```
POST   /auth/register          { name, email, password }
POST   /auth/login             { email, password } -> { access_token, refresh_token }
POST   /auth/refresh           { refresh_token }
```

### Groupes
```
GET    /groups                          # groupes de l'utilisateur courant, avec solde calculé
POST   /groups                          { name }
GET    /groups/{id}                     # détail + membres
PATCH  /groups/{id}                     { name }
DELETE /groups/{id}
POST   /groups/{id}/invite              -> { code, expires_at }
POST   /groups/join                     { code }
DELETE /groups/{id}/members/{user_id}
```

### Catégories
```
GET    /categories?group_id=            # globales + celles du groupe
POST   /categories                      { group_id, name, icon, color }
PATCH  /categories/{id}
DELETE /categories/{id}
```

### Dépenses
```
GET    /groups/{id}/expenses?from=&to=&category_id=
POST   /groups/{id}/expenses            { name, amount, category_id, paid_by, date, splits[] }
GET    /expenses/{id}
PATCH  /expenses/{id}
DELETE /expenses/{id}
```

### Dépenses récurrentes
```
GET    /groups/{id}/recurring-expenses
POST   /groups/{id}/recurring-expenses  { name, amount, category_id, paid_by, frequency, day_of_period }
PATCH  /recurring-expenses/{id}
DELETE /recurring-expenses/{id}
```

### Budgets
```
GET    /groups/{id}/budgets             # avec statut vert/orange/rouge calculé
POST   /groups/{id}/budgets             { category_id, limit_amount }
PATCH  /budgets/{id}
DELETE /budgets/{id}
```

### Statistiques
```
GET    /groups/{id}/stats?period=month&date=2026-09   # par groupe
GET    /stats?period=month&date=2026-09               # tous groupes confondus (vue consolidée)
# Réponse : [{ category_id, category_name, color, total_amount, percentage }], triée décroissant
```

### Cartes de fidélité
```
GET    /loyalty-cards
POST   /loyalty-cards                   { brand_name, code_type, code_value, color }
PATCH  /loyalty-cards/{id}
DELETE /loyalty-cards/{id}
PATCH  /loyalty-cards/reorder           { ordered_ids: [] }
```

## 5. Structure de dossiers Flutter (proposition)

```
lib/
  main.dart
  core/
    api/              # client HTTP, intercepteurs auth, gestion erreurs
    theme/            # couleurs, typographie, composants partagés (design system)
    router/           # navigation (go_router recommandé)
  features/
    auth/
      cubit/
      screens/
    home/
      cubit/
      screens/        # HomeScreen (liste des groupes)
      widgets/        # GroupCard
    group_detail/
      cubit/
      screens/
    budget/
      cubit/
      screens/
      widgets/        # PieChart, CategoryBudgetBar
    add_expense/
      cubit/
      screens/
      widgets/        # CategoryPicker, SplitEditor
    cards/
      cubit/
      screens/
      widgets/        # ScannerView, CardFullscreen
    profile/
      cubit/
      screens/
  shared/
    models/           # Group, Expense, Category, Budget, LoyaltyCard (DTOs)
    widgets/           # boutons, avatars, inputs réutilisables
```

Un `Cubit` par feature reflète l'état retourné par l'API en mémoire (pas de persistance), conformément au choix "aucun stockage local".

## 6. Sécurité et auth

- JWT access token (courte durée, ex. 15-30 min) + refresh token (longue durée) — évite de renvoyer le mot de passe à chaque appel.
- Mots de passe hashés (bcrypt/argon2) côté serveur.
- Toutes les routes de groupes/dépenses vérifient que l'utilisateur courant est bien membre du `group_id` concerné avant de répondre (contrôle d'accès systématique côté API, jamais confié au client).
- Pas d'auth sociale prévue à ce stade (cohérent avec l'usage privé/self-hosted).

## 7. Déploiement

1. Créer un conteneur LXC dédié sur le Proxmox pour l'API (+ un second pour PostgreSQL si tu préfères séparer, ou même conteneur si ressources limitées).
2. Configurer le service Tailscale sur ce conteneur pour qu'il rejoigne le tailnet existant.
3. Déployer l'API (Docker recommandé pour simplifier les mises à jour, ou service systemd direct si tu préfères rester léger comme le reste de ton homelab).
4. L'app Flutter pointe sur l'IP Tailscale du conteneur (à configurer en variable d'environnement/constante, pour pouvoir changer facilement si l'IP évolue).
5. Migration DB versionnée dès le départ (Alembic si FastAPI/SQLAlchemy) pour pouvoir faire évoluer le schéma proprement au fil du développement avec Composer.
