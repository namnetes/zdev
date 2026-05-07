# api/ — Conteneur FastAPI (zapi)

Ce répertoire contient le code source et la configuration de la `zapi` :
l'API backend du projet zdev, exposée sur le port 5000.

---

## Contenu du répertoire

```
api/
├── Dockerfile          ← Image Docker de l'API
├── pyproject.toml      ← Dépendances, build system, configuration Ruff
├── .python-version     ← Version Python imposée (3.14)
├── uv.lock             ← Fichier de verrouillage des dépendances
└── src/
    └── zapi/
        ├── __init__.py
        └── main.py     ← Application FastAPI
```

---

## Fichiers

### `Dockerfile`

Construit l'image Docker de l'API à partir de `python:3.14-slim`. Utilise
[uv](https://docs.astral.sh/uv/) pour installer les dépendances de façon
reproductible.

Stratégie en deux phases pour optimiser le cache Docker :
1. Copie `pyproject.toml` et `uv.lock` puis installe les dépendances
   (`uv sync --frozen --no-dev`) — cette couche ne se reconstruira que si les
   dépendances changent.
2. Copie le code source (`src/`) puis finalise l'installation.

L'image démarre automatiquement avec :

```bash
uv run uvicorn zapi.main:app --host 0.0.0.0 --port 5000
```

### `pyproject.toml`

Source de vérité pour le projet Python. Définit :
- **Build system** : `hatchling` avec le package `src/zapi`
- **Dépendances** : `fastapi`, `pydantic`, `uvicorn`
- **Dépendances de développement** : `ruff` (linter/formateur)
- **Version Python minimale** : 3.14

### `.python-version`

Indique à `uv` la version Python à utiliser localement (`3.14`). Équivaut
à un `.nvmrc` pour Node.js — garantit que tous les développeurs utilisent la
même version.

### `uv.lock`

Fichier de verrouillage généré par `uv`. Fixe les versions exactes de toutes
les dépendances (directes et transitives) pour des builds parfaitement
reproductibles. **Doit être versionné** dans git.

---

## Code source — `src/zapi/`

Le code est organisé en [src layout](https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/)
pour éviter les conflits d'import lors des tests.

### `main.py`

Point d'entrée de l'application FastAPI. Contient :

- **`Status`** — modèle Pydantic retourné par l'endpoint racine :
  ```python
  class Status(BaseModel):
      status: str       # "running"
      engine: str       # "uv + ruff"
      timestamp: datetime
  ```

- **`GET /`** — endpoint de santé retournant un objet `Status`.

La documentation interactive générée automatiquement par FastAPI est disponible
sur `http://localhost:5000/docs` une fois l'API démarrée.

---

## Développement local

```bash
cd api

# Installer les dépendances (crée un environnement virtuel .venv/)
uv sync

# Démarrer l'API avec rechargement automatique
uv run uvicorn zapi.main:app --reload --host 0.0.0.0 --port 5000

# Vérifier et corriger le style de code
uv run ruff check . --fix
uv run ruff format .

# Lancer les tests
uv run pytest

# Ajouter une dépendance
uv add <paquet>
```

> Toujours utiliser `uv`. Ne jamais utiliser `pip` ou `poetry` directement.

---

## Tester l'API

### Depuis la machine hôte

```bash
# Réponse JSON brute
curl http://localhost:5000/

# Réponse formatée
curl -s http://localhost:5000/ | python3 -m json.tool
```

### Depuis le navigateur

| URL                              | Contenu                                      |
|----------------------------------|----------------------------------------------|
| `http://localhost:5000/`         | Réponse JSON brute                           |
| `http://localhost:5000/docs`     | Interface Swagger interactive (FastAPI)      |
| `http://localhost:5000/redoc`    | Documentation ReDoc                          |

### Depuis le conteneur `zdev-ide`

Les deux conteneurs partagent le réseau Docker `zdev_default`. `zdev-api` est
joignable depuis `zdev-ide` via son nom de service — pas besoin de passer par
l'hôte.

Depuis un terminal dans VS Code (ou `docker exec zdev-ide bash`) :

```bash
# curl
curl http://zdev-api:5000/

# curl avec formatage
curl -s http://zdev-api:5000/ | python3 -m json.tool
```

Réponse attendue :

```json
{
    "status": "running",
    "engine": "uv + ruff",
    "timestamp": "2026-05-07T21:00:00.000000"
}
```
