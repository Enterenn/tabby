# Tabby — Contrat API réel

> Source de vérité pour le lot 0. Ce document décrit les routes actuellement enregistrées par `backend/app/main.py`, leurs paramètres et leurs schémas principaux. Toute modification d’API doit mettre à jour ce fichier et les tests concernés.

## Conventions

- Authentification : `Authorization: Bearer <access_token>` sauf indication contraire.
- Format : JSON, sauf upload avatar en `multipart/form-data`.
- Dates : `YYYY-MM-DD` pour les dates métier ; timestamps ISO 8601 pour les dates de création/expiration.
- Les réponses `204 No Content` ne contiennent pas de payload.
- Les erreurs utilisent le format FastAPI standard : `{ "detail": ... }`.

## Health

| Méthode | Route | Auth | Réponse |
|---|---|---|---|
| `GET` | `/health` | Non | Production : `{status}` ; debug : status, app, version, database |

## Authentification

| Méthode | Route | Entrée | Réponse |
|---|---|---|---|
| `POST` | `/auth/register` | `name`, `email`, `password` | `201 UserResponse` |
| `POST` | `/auth/login` | `email`, `password` | `TokenResponse` |
| `POST` | `/auth/refresh` | `refresh_token` | `TokenResponse` |
| `POST` | `/auth/logout` | `refresh_token` | `204` |
| `GET` | `/auth/me` | — | `UserResponse` |
| `PATCH` | `/auth/me` | `name?`, `email?` | `UserResponse` |
| `POST` | `/auth/change-password` | `current_password`, `new_password` | `204` |
| `POST` | `/auth/me/avatar` | multipart `file` | `UserResponse` |

## Groupes

| Méthode | Route | Entrée | Réponse |
|---|---|---|---|
| `GET` | `/groups` | — | `list[GroupResponse]` |
| `POST` | `/groups` | `name` | `201 GroupResponse` |
| `GET` | `/groups/{group_id}` | — | `GroupResponse` |
| `PATCH` | `/groups/{group_id}` | `name` | `GroupResponse` |
| `DELETE` | `/groups/{group_id}` | — | `204` |
| `PATCH` | `/groups/{group_id}/pin` | `is_pinned` | `GroupResponse` |
| `POST` | `/groups/{group_id}/invite` | — | `InviteResponse` |
| `POST` | `/groups/join` | `code` | `201 GroupResponse` |
| `POST` | `/groups/{group_id}/leave` | — | `204` |
| `DELETE` | `/groups/{group_id}/members/{user_id}` | — | `204` |
| `GET` | `/groups/{group_id}/balances` | — | `list[BalanceEntry]` |
| `POST` | `/groups/{group_id}/settle` | `from_user_id`, `to_user_id`, `amount` | réponse de règlement actuelle |

## Catégories

| Méthode | Route | Entrée | Réponse |
|---|---|---|---|
| `GET` | `/categories` | `group_id?` actuellement ignoré | `list[CategoryResponse]` |
| `POST` | `/categories` | `name`, `icon`, `color` | `201 CategoryResponse` |
| `PATCH` | `/categories/{category_id}` | `name?`, `icon?`, `color?` | `CategoryResponse` |
| `DELETE` | `/categories/{category_id}` | — | `204` |

## Dépenses de groupe

| Méthode | Route | Entrée | Réponse |
|---|---|---|---|
| `GET` | `/groups/{group_id}/expenses` | `from_date?`, `to_date?`, `category_id?`, `status?`, `limit?` (1-500, défaut illimité), `offset=0` | `list[ExpenseResponse]` (rétrocompatible sans limit) |
| `POST` | `/groups/{group_id}/expenses` | `name`, `amount`, `category_id`, `paid_by`, `expense_date`, split | `201 ExpenseResponse` |
| `PATCH` | `/groups/{group_id}/expenses/{expense_id}` | champs de dépense optionnels | `ExpenseResponse` |
| `POST` | `/groups/{group_id}/expenses/{expense_id}/confirm` | — | `ExpenseResponse` |
| `DELETE` | `/groups/{group_id}/expenses/{expense_id}` | — | `204` |

## Récurrences

| Méthode | Route | Entrée | Réponse |
|---|---|---|---|
| `GET` | `/groups/{group_id}/recurring-expenses` | — | `list[RecurringExpenseResponse]` |
| `POST` | `/groups/{group_id}/recurring-expenses` | `name`, `amount`, `category_id`, `paid_by`, `frequency`, `day_of_period` | `201 RecurringExpenseResponse` |
| `PATCH` | `/groups/{group_id}/recurring-expenses/{rec_id}/toggle` | — | `RecurringExpenseResponse` |
| `DELETE` | `/groups/{group_id}/recurring-expenses/{rec_id}` | — | `204` |
| `GET` | `/recurring-expenses` | — | récurrences groupe + personnelles |
| `POST` | `/recurring-expenses` | récurrence personnelle | `201 RecurringExpenseResponse` |
| `PATCH` | `/recurring-expenses/{rec_id}/toggle` | — | `RecurringExpenseResponse` |
| `DELETE` | `/recurring-expenses/{rec_id}` | — | `204` |

## Budgets

| Méthode | Route | Entrée | Réponse |
|---|---|---|---|
| `GET` | `/budgets` | `year?`, `month?` | `list[BudgetResponse]` |
| `POST` | `/budgets` | `category_id`, `limit_amount` | `201 BudgetResponse` |
| `PUT` | `/budgets/{budget_id}` | `limit_amount` | `BudgetResponse` |
| `DELETE` | `/budgets/{budget_id}` | — | `204` |
| `GET` | `/groups/{group_id}/budgets` | `year?`, `month?` | route de compatibilité, budgets personnels |

## Dépenses personnelles

| Méthode | Route | Entrée | Réponse |
|---|---|---|---|
| `GET` | `/personal-expenses` | `year?`, `month?` | `list[PersonalExpenseResponse]` |
| `POST` | `/personal-expenses` | `name`, `amount`, `category_id`, `expense_date` | `201 PersonalExpenseResponse` |
| `PATCH` | `/personal-expenses/{expense_id}` | champs optionnels | `PersonalExpenseResponse` |
| `DELETE` | `/personal-expenses/{expense_id}` | — | `204` |

## Statistiques

| Méthode | Route | Entrée | Réponse |
|---|---|---|---|
| `GET` | `/stats` | `year?`, `month?`, `group_id?`, `scope=all|groups|personal` | `{year, month, total, categories[]}` |

## Cartes de fidélité

| Méthode | Route | Entrée | Réponse |
|---|---|---|---|
| `GET` | `/loyalty-cards` | — | `list[LoyaltyCardResponse]` |
| `POST` | `/loyalty-cards` | `brand_name`, `brand_id?`, `code_type`, `code_value`, `color?` | `201 LoyaltyCardResponse` |
| `PATCH` | `/loyalty-cards/{card_id}` | champs optionnels | `LoyaltyCardResponse` |
| `DELETE` | `/loyalty-cards/{card_id}` | — | `204` |
| `PUT` | `/loyalty-cards/reorder` | `[{id, sort_order}]` | `204` |

## Écarts à traiter dans les lots suivants

- `GET /groups/{group_id}/expenses` n’a pas encore de pagination ni filtres.
- La documentation technique historique décrit des routes et payloads parfois différents des routes réellement enregistrées.
- `GET /categories?group_id=` conserve le paramètre pour compatibilité mais l’ignore actuellement.
- `/groups/{group_id}/budgets` est une route de compatibilité et retourne des budgets personnels.
- Le format exact de la réponse de règlement doit être formalisé dans un schéma dédié.
