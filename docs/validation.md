# Tabby — Validation locale

## Flutter

Depuis `app/` :

```bash
flutter pub get
flutter analyze
flutter test
```

## Backend

Depuis `backend/` :

```bash
python -m pip install -r requirements-dev.txt
python -m pytest
```

Pour tester avec PostgreSQL et les migrations :

```bash
alembic upgrade head
python -m pytest
```

## Contrat API

Le contrat actuellement implémenté est documenté dans [`api-contract-audit.md`](./api-contract-audit.md).

Toute modification d’une route doit être accompagnée de :

1. la mise à jour du schéma ou du router concerné ;
2. un test backend adapté ;
3. la mise à jour du contrat API ;
4. la vérification des repositories Flutter appelants.

## Contrôle avant merge

- `flutter analyze` sans issue.
- `flutter test` vert.
- `python -m pytest` vert.
- Migrations Alembic applicables sur une base vierge et une base existante.
- Aucun secret dans les logs ou fichiers suivis.
- Aucun changement non documenté du contrat API.
