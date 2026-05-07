# zdev — Environnement de développement mainframe sous Docker

**zdev** est un environnement de développement complet pour IBM z/OS, accessible
depuis un navigateur, prêt à l'emploi sans installation manuelle d'outils.

Il fonctionne sur **macOS Apple Silicon (ARM64)** en entreprise derrière un proxy
et sur **Linux Ubuntu 24.04 (AMD64)** à domicile — le même `Dockerfile` et le
même `Makefile` gèrent les deux automatiquement.

---

## Ce que contient zdev

| Conteneur   | Port  | Rôle                                              |
|-------------|-------|---------------------------------------------------|
| `zdev-ide`  | 8443  | VS Code dans le navigateur + outils mainframe IBM |
| `zdev-api`  | 5000  | API FastAPI (backend du projet)                   |

**Outils inclus dans l'IDE :**

- [code-server](https://github.com/coder/code-server) — VS Code dans le navigateur
- [Zowe CLI v3](https://docs.zowe.org/) + plugins (CICS, MQ, FTP, RSE API)
- IBM Z Open Editor, Zowe Explorer, Db2, CICS, Fault Analyzer
- Java 21 (requis par les extensions IBM)
- Python 3 + `uv` (gestionnaire de paquets) + MkDocs Material
- Node.js LTS, GitHub Copilot, Ruff

---

## Prérequis

| Outil                         | Rôle                        |
|-------------------------------|-----------------------------|
| Docker (Engine ou Desktop)    | Fait tourner les conteneurs |
| Make                          | Lance les commandes projet  |
| ~10 Go d'espace disque libre  | Image + volumes             |

---

## Première installation

Ces étapes ne sont à réaliser **qu'une seule fois**.

### 1 — Cloner le dépôt

```bash
git clone <url-du-dépôt> zdev
cd zdev
```

### 2 — Configurer l'environnement

```bash
cp .env.example .env
```

Éditez `.env` pour ajuster le mot de passe et le fuseau horaire :

```ini
HTTP_PROXY=          # Laisser vide si pas de proxy
TZ=Europe/Paris
IDE_PASSWORD=zdev
```

### 3 — Créer les répertoires hôte

```bash
make setup-host
```

Crée `~/zdev/` sur votre machine avec les dossiers montés dans le conteneur.
Vos projets, profils Zowe et paramètres VS Code y seront conservés.

### 4 — Télécharger les extensions VS Code

```bash
make fetch-ext
# Avec proxy : make fetch-ext PROXY=http://mon-proxy:3128
```

### 5 — Construire et démarrer

```bash
make build    # 10 à 20 minutes à la première construction
make up
```

VS Code est accessible sur **http://localhost:8443** (mot de passe : `zdev`).

---

## Utilisation quotidienne

```bash
make up       # Démarrer les conteneurs
make down     # Arrêter les conteneurs
make logs     # Afficher les logs en temps réel
make help     # Voir toutes les commandes disponibles
```

Le conteneur redémarre automatiquement au démarrage de la machine
(`restart: unless-stopped`).

---

## Structure du projet

```
zdev/
├── Makefile                  ← Point d'entrée unique (build, run, setup)
├── docker-compose.yml        ← Définition des deux services
├── .env.example              ← Template de configuration
│
├── ide/                      ← Conteneur IDE (code-server + outils IBM)
│   ├── Dockerfile
│   ├── entrypoint.sh
│   ├── settings.json
│   ├── ruff.toml
│   ├── setup_host.sh
│   ├── fetch_extensions.sh
│   ├── copilot/              ← Instructions GitHub Copilot
│   ├── extensions/           ← Fichiers .vsix (gitignorés)
│   └── zowe/                 ← Archives Zowe CLI hors-ligne
│
└── api/                      ← Conteneur API (FastAPI + uvicorn)
    ├── Dockerfile
    ├── pyproject.toml
    └── src/zapi/
```

Voir `ide/README.md` et `api/README.md` pour le détail de chaque répertoire.

---

## Persistance des données

Toutes les données utilisateur sont stockées sur la machine hôte dans `~/zdev/`.
Supprimer et recréer le conteneur ne perd aucune donnée.

| Dossier hôte                  | Dossier conteneur                          |
|-------------------------------|--------------------------------------------|
| `~/zdev/projects/`            | `/home/zdev/workspace`                     |
| `~/zdev/zowe/`                | `/home/zdev/.zowe`                         |
| `~/zdev/editor/settings/`     | `~/.local/share/code-server/User`          |
| `~/zdev/editor/extensions/`   | `~/.local/share/code-server/extensions`    |
| `~/zdev/cache/npm/`           | `/home/zdev/.npm`                          |
| `~/zdev/cache/pip/`           | `/home/zdev/.cache/pip`                    |
| `~/zdev/.zshrc`               | `/home/zdev/.zshrc`                        |
| `~/zdev/.gitconfig`           | `/home/zdev/.gitconfig`                    |
| `~/.ssh` *(lecture seule)*    | `/home/zdev/.ssh`                          |

---

## Proxy d'entreprise

Définissez `HTTP_PROXY` dans votre shell avant de builder :

```bash
export HTTP_PROXY=http://mon-proxy:3128
make build
```

Ou passez le proxy directement :

```bash
make build PROXY=http://mon-proxy:3128
```

Le proxy est utilisé uniquement pendant le build et **supprimé de l'image
finale** — le conteneur en cours d'exécution ne le connaît pas.

---

## Dépannage rapide

```bash
make logs                    # Consulter les logs des conteneurs
docker compose ps            # Vérifier l'état (attendu : "running")
make down && make up         # Redémarrer proprement
```

| Problème                          | Solution                                                              |
|-----------------------------------|-----------------------------------------------------------------------|
| VS Code ne répond pas             | Attendre 30 s, puis rafraîchir (F5)                                   |
| Mot de passe refusé               | Vérifier `IDE_PASSWORD` dans `.env`                                   |
| Port 8443 déjà utilisé            | Changer le port dans `docker-compose.yml`                             |
| Erreur proxy 407 pendant le build | `make build PROXY=http://user:pass@proxy:port`                        |
| Extensions absentes               | Attendre 15 s (sync au 1er démarrage), rafraîchir. Sinon : `make down && make up` |
| Extensions manquantes après build | `make fetch-ext` puis `make build-ide`                                |
| Paramètres non conservés          | Vérifier que `~/zdev/` existe (`make setup-host`)                     |

> **Premier démarrage :** `entrypoint.sh` copie les extensions depuis l'image
> vers le volume hôte avant de lancer VS Code. Cette opération prend
> 10 à 15 secondes. Les démarrages suivants sont immédiats (extensions déjà
> dans le volume). Voir `ide/README.md` pour le détail du mécanisme.
