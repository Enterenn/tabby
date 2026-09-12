# Tabby

Application mobile de partage de dépenses (type Tricount) avec analyses visuelles, hébergée en self-hosted sur home server.

- **Client** : Flutter/Dart — Android uniquement
- **Backend** : FastAPI (Python) + PostgreSQL
- **Réseau** : Tailscale (pas d'exposition publique)

Les spécifications complètes sont dans [`docs/`](./docs/).

---

## Structure du repo

```
tabby/
├── docs/          # Cahier des charges, cahier technique, direction artistique, roadmap
├── backend/       # API REST FastAPI + configuration Docker
└── app/           # Application Flutter Android
```

---

## Lancer le backend

### Prérequis
- Docker & Docker Compose

### Démarrage rapide (développement local)

```bash
cd backend

# Copier et adapter la config
cp .env.example .env

# Démarrer la base de données et l'API
docker compose up -d

# Appliquer les migrations (première fois ou après une mise à jour du schéma)
docker compose exec api alembic upgrade head

# Vérifier que tout fonctionne
curl http://localhost:8000/health
```

La réponse attendue :
```json
{"status": "ok", "app": "Tabby", "version": "0.1.0", "database": "connected"}
```

La documentation Swagger est accessible sur `http://localhost:8000/docs` **uniquement si `DEBUG=true`** dans le `.env`.

### Déploiement sur home server (LXC Proxmox)

1. Créer un conteneur LXC sur Proxmox, installer Docker.
2. Cloner le repo sur le LXC et aller dans `backend/`.
3. Configurer le `.env` : `SECRET_KEY` et `POSTGRES_PASSWORD` obligatoires.
   `python -c "import secrets; print(secrets.token_urlsafe(48)); print(secrets.token_urlsafe(24))"`
4. `docker compose up -d` puis `docker compose exec api alembic upgrade head`.
5. LAN : `http://<ip-lan>:8000`. Hors maison : Proxy Host NPM vers ce port 8000
   (comme Jellyfin), puis `https://tabby.<ton-domaine>`.
   Ne jamais ouvrir le port 8000 sur la box. Détail : `docs/tabby-tutoriel-deploiement.md` partie 11.

---

## Lancer l'app Flutter

### Prérequis
- Flutter 3.x (Android SDK configuré)
- Un émulateur Android ou un téléphone physique

### Démarrage

```bash
cd app

# Récupérer les dépendances
flutter pub get

# Adapter l'URL du serveur si besoin
# flutter run --dart-define=API_BASE_URL=https://<domaine>

# Lancer sur un appareil connecté
flutter run
```

La pastille en haut à droite de l'écran Home indique l'état de la connexion serveur :
- 🟡 Orange : vérification en cours
- 🟢 Vert : serveur accessible
- 🔴 Rouge : serveur inaccessible (tap pour réessayer)

---

## Développement

Voir [`docs/tabby-roadmap.md`](./docs/tabby-roadmap.md) pour le découpage en lots.

Le développement suit les lots de la roadmap — chaque lot est validé avant d'attaquer le suivant.
