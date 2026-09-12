# Tutoriel — Déployer le backend Tabby sur ton home server

Ce tuto part de zéro : création du conteneur, installation de Docker, récupération du code, lancement du backend, et connexion de l'app Flutter. Chaque commande est expliquée en une phrase — pas besoin de connaissances backend, juste de copier-coller dans l'ordre.

Convention : tout ce qui est dans un bloc `comme ceci` est une commande à taper telle quelle (en remplaçant les valeurs entre `< >` par les tiennes).

---

## Partie 1 — Créer le conteneur (LXC)

Dans l'interface Proxmox, clique sur **Create CT** et renseigne :

| Champ | Valeur |
|---|---|
| Node | ton node Proxmox habituel |
| CT ID | le prochain libre (vérifie qu'il n'entre pas en conflit avec tes CT existants) |
| Hostname | `tabby-backend` |
| Unprivileged container | coché |
| Template | Debian 13 (Trixie) — `pveam update` avant si tu ne le vois pas dans la liste |
| Disk | 16 GB |
| CPU cores | 2 |
| Memory | 2048 MB |
| Swap | 512 MB |
| Network | Bridge `vmbr0`, IPv4 en DHCP |

**Avant de démarrer le conteneur**, active deux options nécessaires pour faire tourner Docker à l'intérieur d'un LXC :

1. Dans Proxmox, clique sur ton conteneur → **Options** → **Features** → coche `nesting` et `keyctl` → OK.
2. Démarre le conteneur (bouton Start).

---

## Partie 2 — Installer les outils de base

Ouvre la **console** du conteneur (clic sur le CT → Console), ou depuis le host : `pct enter <ID>`.

```bash
apt update && apt upgrade -y
apt install -y curl git nano
```
*Ça met le système à jour et installe 3 outils dont on aura besoin : `curl` (télécharger des scripts), `git` (récupérer le code), `nano` (éditer des fichiers texte).*

---

## Partie 3 — Installer Docker

```bash
curl -fsSL https://get.docker.com | sh
```
*Ça installe Docker et Docker Compose en une seule commande (script officiel).*

Vérifie que ça fonctionne :
```bash
docker run hello-world
```
*Tu dois voir un message "Hello from Docker!". Si tu as une erreur, arrête-toi ici et montre-la moi avant de continuer.*

```bash
docker compose version
```
*Doit t'afficher un numéro de version (ex. `Docker Compose version v2.x.x`). Si oui, tout est prêt.*

---

## Partie 4 — Récupérer ton code depuis GitHub

```bash
git clone <URL_DE_TON_REPO>
```
*Remplace `<URL_DE_TON_REPO>` par l'URL de ton repo GitHub (ex. `https://github.com/tonpseudo/tabby.git`). Ça télécharge tout ton code dans un nouveau dossier.*

```bash
cd tabby/backend
```
*Adapte `tabby` si ton dossier a un autre nom — tape `ls` après le `git clone` pour voir le nom exact du dossier créé.*

---

## Partie 5 — Préparer le fichier de configuration

```bash
cp .env.example .env
```
*Ça duplique le fichier d'exemple. Ensuite il faut remplir `SECRET_KEY` et `POSTGRES_PASSWORD` — sans ça l'API refuse de démarrer.*

```bash
python3 -c "import secrets; print(secrets.token_urlsafe(48)); print(secrets.token_urlsafe(24))"
```
*La première ligne est `SECRET_KEY`, la seconde `POSTGRES_PASSWORD`.*

```bash
nano .env
```
*Colle les deux valeurs. Sauvegarde avec `Ctrl+O` puis Entrée, quitte avec `Ctrl+X`.*

**Base déjà existante** (volume Docker créé avec l'ancien mot de passe `tabby`) : Postgres n'applique `POSTGRES_PASSWORD` qu'à la première création. Change le mot de passe dans le volume, puis mets la même valeur dans `.env` :

```bash
docker compose exec db psql -U tabby -d tabby -c "ALTER USER tabby WITH PASSWORD '<POSTGRES_PASSWORD>'"
docker compose up -d
```

---

## Partie 6 — Lancer l'API et la base de données

```bash
docker compose up -d
```
*Le `-d` veut dire "en arrière-plan". Ça télécharge les images (Python + PostgreSQL) et démarre les deux services. Première fois : compte 1-2 minutes.*

Vérifie que tout tourne :
```bash
docker compose ps
```
*Tu dois voir deux lignes, `api` et `db`, toutes les deux avec un statut `running` ou `healthy`. Si l'une affiche `Restarting` ou `Exited`, tape `docker compose logs` et montre-moi le résultat.*

---

## Partie 7 — Créer les tables dans la base de données

```bash
docker compose exec api alembic upgrade head
```
*Cette commande crée toutes les tables (utilisateurs, groupes, dépenses...) et ajoute les 8 catégories par défaut (Loyer, Courses, etc.). Tu dois voir des lignes défiler sans message d'erreur en rouge à la fin.*

**Après chaque `git pull`** qui modifie le backend, relance la même commande pour appliquer les nouvelles migrations (ex. colonne `brand_id` sur les cartes fidélité). Le conteneur API applique aussi les migrations au démarrage, mais un `docker compose up -d --build` après pull reste la bonne habitude.

Test rapide que l'API répond bien :
```bash
curl http://localhost:8000/health
```
*Doit répondre quelque chose comme `{"status":"ok","database":"connected"}`.*

---

## Partie 8 — Trouver l'adresse IP du conteneur

Dans l'interface web Proxmox, clique sur ton conteneur `tabby-backend` dans la liste de gauche : l'IP s'affiche directement dans l'onglet **Summary**, sous une forme comme `192.168.1.XX`.

Note cette adresse, tu en as besoin pour l'étape suivante.

---

## Partie 9 — Connecter l'app Flutter

Sur ton PC (pas dans le conteneur), ouvre dans Cursor le fichier :
```
app/lib/core/api/api_client.dart
```

En debug sur le wifi de la maison, l'app utilise encore `http://192.168.1.XX:8000`. Pour l'accès **hors maison en HTTPS**, ne touche plus ce fichier : lance plutôt :

```
flutter run --dart-define=API_BASE_URL=https://<TON_DOMAINE>
```

*(voir la partie 11 pour le domaine)*

---

## Partie 10 — Tester

1. Connecte ton téléphone Android au **même réseau wifi** que ta box/routeur (celui utilisé par ton Proxmox).
2. Lance l'app depuis Cursor sur ton téléphone (`flutter run`, ou bouton Run).
3. Regarde la pastille sur l'écran Home :
   - **Verte** → tout fonctionne, le Lot 0 est validé.
   - **Rouge** → vérifie dans l'ordre : le téléphone est bien sur le même wifi, l'IP dans `api_client.dart` est correcte, `docker compose ps` montre bien `api` en `running`.

---

## Partie 11 — Accès hors maison (HTTPS via Nginx Proxy Manager)

Même principe que Jellyfin. **Pas de Caddy** : NPM gère déjà les certificats et les ports 80/443 de la box.

### 1. DNS

Chez ton registrar, reproduis exactement ce que tu as pour `jellyfin.landrodie.fr` :

- soit un enregistrement **A** `tabby` → la même IP publique,
- soit un **CNAME** / wildcard `*.landrodie.fr` déjà en place (rien à ajouter).

### 2. Proxy Host dans NPM

| Champ | Valeur |
|---|---|
| Domain Names | `tabby.landrodie.fr` |
| Scheme | `http` |
| Forward Hostname / IP | IP LAN du LXC `tabby-backend` |
| Forward Port | `8000` |
| SSL | certificat Let's Encrypt, **Force SSL** coché |

Aucun port forwarding supplémentaire sur la box.

### 3. `.env` du backend

```
PUBLIC_ORIGIN=https://tabby.landrodie.fr
```

Puis `docker compose up -d` (sans profil https).

Vérifie : `curl https://tabby.landrodie.fr/health`

### 4. App Flutter

```
flutter run --dart-define=API_BASE_URL=https://tabby.landrodie.fr
```

Pour un APK release, le même `--dart-define` est obligatoire (le binaire refuse le HTTP).

Le port `8000` reste utile en wifi maison pour le debug. **Ne le forward jamais** sur la box : seul NPM doit y accéder en LAN.

---

## En cas de blocage

Colle-moi directement :
- la commande exacte que tu as tapée,
- le message d'erreur complet affiché.

Pas besoin de comprendre le message toi-même — je le lirai pour toi.
