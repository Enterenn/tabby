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

## Partie 4 — Récupérer le backend depuis GitHub (sparse-checkout)

Le dépôt GitHub contient aussi l'app Flutter et la doc. Le LXC n'exécute
que l'API : on clone le même repo, mais on ne matérialise que `backend/`.
Les blobs Flutter ne sont pas téléchargés.

```bash
git clone --filter=blob:none --sparse <URL_DE_TON_REPO> tabby
```
*Remplace `<URL_DE_TON_REPO>` par l'URL de ton repo GitHub (ex. `https://github.com/tonpseudo/tabby.git`). `--filter=blob:none` évite de télécharger les fichiers dont tu n'as pas besoin. `--sparse` active le checkout partiel.*

```bash
cd tabby
git sparse-checkout set backend
```
*Seul le dossier `backend/` apparaît dans le working tree. `app/` et `docs/` restent dans l'historique Git mais ne sont pas écrits sur le disque.*

```bash
ls
```
*Tu dois voir `backend/` (et éventuellement `.git`). Pas de dossier `app/`.*

```bash
cd backend
```
*Toutes les commandes des parties suivantes se tapent depuis ce dossier.*

### Clone déjà présent (conversion sans recréer les volumes)

Si le LXC a déjà un `git clone` complet et que Docker tourne, ne reclones
pas : tu garderais le même `.env` et les mêmes volumes Postgres.

**Avant** le sparse-checkout, vérifie que les secrets sont bien dans `backend/`
(ils ne sont pas dans Git) :

```bash
ls -la backend/.env backend/firebase.json
```

S'ils manquent, **arrête-toi** et récupère-les (backup, ou depuis les
conteneurs encore en cours — voir « En cas de blocage »). Ne fais pas
`docker compose down` ni `up -d` tant qu'ils ne sont pas revenus.

```bash
cd /chemin/vers/tabby
```
*Adapte le chemin (`pwd` depuis `backend/` puis `cd ..` si besoin).*

```bash
git sparse-checkout init --cone
git sparse-checkout set backend
```
*Git retire `app/` et `docs/` du disque. `backend/.env`, `backend/firebase.json` et les volumes Docker (`postgres_data`, `uploads_data`) ne bougent pas s'ils étaient déjà là.*

```bash
ls
```
*Attendu : `backend/` seulement (plus `app/`). Ensuite `cd backend` comme d'habitude.*

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

Mise à jour type (depuis `backend/`) :

```bash
git -C .. pull --ff-only
docker compose up -d --build
docker compose exec api alembic upgrade head
```
*`git -C ..` pull depuis la racine du clone (là où vit `.git`), pas depuis `backend/`. Le sparse-checkout ne récupère toujours que `backend/`.*

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

### `.env` / `firebase.json` introuvables alors que l'API tourne

Ne fais **pas** `docker compose down` ni `up -d` : les conteneurs ont encore
les secrets en mémoire. Recrée les fichiers depuis Docker, **sans les
afficher** (ne les colle pas dans un chat) :

```bash
cd ~/tabby/backend

# Chercher une copie oubliée ailleurs sur le LXC
find /root /opt /home -name '.env' -o -name 'firebase.json' -o -name '*firebase-adminsdk*.json' 2>/dev/null

# Recréer .env depuis les conteneurs en cours
python3 - <<'PY'
import json, subprocess, pathlib
def env_of(name):
    out = subprocess.check_output(
        ["docker", "inspect", name, "--format", "{{json .Config.Env}}"],
        text=True,
    )
    return dict(item.split("=", 1) for item in json.loads(out))
api, db = env_of("backend-api-1"), env_of("backend-db-1")
pw = db.get("POSTGRES_PASSWORD") or ""
if not pw:
    url = api.get("DATABASE_URL", "")
    if "://" in url and "@" in url:
        creds = url.split("://", 1)[1].split("@", 1)[0]
        if ":" in creds:
            pw = creds.split(":", 1)[1]
pathlib.Path(".env").write_text(
    "SECRET_KEY=" + api.get("SECRET_KEY", "") + "\n"
    + "POSTGRES_PASSWORD=" + pw + "\n"
    + "DEBUG=" + api.get("DEBUG", "false") + "\n"
    + "PUBLIC_ORIGIN=" + api.get("PUBLIC_ORIGIN", "") + "\n"
    + "DATABASE_URL=postgresql+asyncpg://tabby:CHANGE_ME@localhost:5432/tabby\n",
    encoding="utf-8",
)
print("wrote .env (keys present:", bool(api.get("SECRET_KEY")), bool(pw), ")")
PY

# Recopier Firebase depuis le conteneur (si le fichier n'est pas vide)
docker cp backend-api-1:/run/secrets/firebase.json ./firebase.json
wc -c .env firebase.json
```

Vérifie ensuite, toujours sans afficher les valeurs :

```bash
grep -E '^(SECRET_KEY|POSTGRES_PASSWORD|PUBLIC_ORIGIN|DEBUG)=' .env | sed 's/=.*/=***set***/'
```

Si `SECRET_KEY` ou `POSTGRES_PASSWORD` sortent vides, les conteneurs avaient
déjà été lancés sans `.env` : il faut retrouver un backup, pas en générer
de nouveaux (le volume Postgres garde l'ancien mot de passe).
