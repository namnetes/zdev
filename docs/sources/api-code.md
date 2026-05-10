# Code de l'API — ligne par ligne

L'API `zdev-api` est une application Python construite avec FastAPI.
Elle tourne dans son propre conteneur Docker et expose des endpoints HTTP
appelables depuis VS Code ou depuis votre machine.

---

## Structure des fichiers

```
api/
├── Dockerfile              ← Construction de l'image zdev-api
├── pyproject.toml          ← Dépendances Python et configuration
├── .python-version         ← Version Python exigée (3.14)
├── uv.lock                 ← Versions exactes des dépendances (à versionner)
└── src/
    └── zapi/
        ├── __init__.py     ← Marque le dossier comme package Python
        └── main.py         ← Code de l'application FastAPI
```

---

## api/Dockerfile

```dockerfile
FROM python:3.14-slim

WORKDIR /app

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

COPY README.md ./
COPY src/ ./src/
RUN uv sync --frozen --no-dev

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/')"

CMD ["uv", "run", "uvicorn", "zapi.main:app", "--host", "0.0.0.0", "--port", "5000"]
```

### Optimisation des couches Docker

Le Dockerfile est structuré en **deux phases de copie** pour optimiser
le cache Docker :

**Phase 1 (dépendances) :**
```dockerfile
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project
```

`--frozen` — Utilise exactement les versions de `uv.lock` (pas de résolution).
`--no-dev` — N'installe pas les dépendances de développement (Ruff).
`--no-install-project` — N'installe pas le package `zapi` lui-même (juste ses dépendances).

Cette couche est mise en cache par Docker. Elle n'est reconstruite que si
`pyproject.toml` ou `uv.lock` changent — ce qui arrive rarement.

**Phase 2 (code source) :**
```dockerfile
COPY README.md ./
COPY src/ ./src/
RUN uv sync --frozen --no-dev
```

`README.md` est requis par Hatchling (le backend de build Python) pour
compiler le package `zapi`.

Cette couche est invalidée dès que le code source change — c'est voulu.

### COPY --from (multi-stage)

```dockerfile
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
```

Cette syntaxe copie le binaire `uv` depuis l'image officielle `uv`
(sur le registre GitHub Container Registry) sans avoir à faire de
`RUN pip install uv` ou de `curl`. C'est la méthode recommandée par l'équipe
Astral pour Docker.

### CMD

```dockerfile
CMD ["uv", "run", "uvicorn", "zapi.main:app", "--host", "0.0.0.0", "--port", "5000"]
```

`uvicorn` est le serveur ASGI (Asynchronous Server Gateway Interface) qui
fait tourner l'application FastAPI.

`zapi.main:app` — Chemin de l'objet application : package `zapi`, module
`main`, variable `app`.

`--host 0.0.0.0` — Écoute sur toutes les interfaces (pas seulement `localhost`).
Nécessaire pour que Docker puisse router le port 5000 depuis l'hôte.

---

## api/pyproject.toml

```toml
[project]
name = "zapi"
version = "0.1.0"
requires-python = ">=3.14"
dependencies = [
    "fastapi>=0.136.1",
    "pydantic>=2.13.4",
    "uvicorn>=0.46.0",
]

[dependency-groups]
dev = ["ruff>=0.15.12"]
```

`requires-python = ">=3.14"` — Garantit que le package ne peut être installé
qu'avec Python 3.14+. Bloque les erreurs d'incompatibilité silencieuses.

**Dépendances de production :**

| Paquet | Rôle |
|--------|------|
| `fastapi` | Framework web Python, validation des données, génération de docs automatique |
| `pydantic` | Validation et sérialisation des données (utilisé par FastAPI) |
| `uvicorn` | Serveur web ASGI pour exécuter l'application FastAPI |

**Dépendances de développement :**

| Paquet | Rôle |
|--------|------|
| `ruff` | Linter et formateur Python (n'entre pas dans l'image de production) |

---

## api/.python-version

```
3.14
```

Ce fichier d'une ligne indique à `uv` quelle version Python utiliser
quand on travaille localement :

```bash
cd api
uv sync   # uv lit .python-version et installe Python 3.14 si nécessaire
```

---

## api/uv.lock

Le fichier `uv.lock` contient les versions **exactes** et les **hashes**
de toutes les dépendances (directes et transitives). Exemple :

```toml
[[package]]
name = "fastapi"
version = "0.136.1"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "pydantic" },
    { name = "starlette" },
    { name = "typing-extensions" },
]
wheels = [
    { url = "...", hash = "sha256:abc123…" },
]
```

!!! important "Ne jamais supprimer uv.lock"
    `uv.lock` **doit être versionné** dans Git. Il garantit que tout le monde
    (développeurs, CI, Docker) installe exactement les mêmes versions.
    Sans lui, `uv sync` pourrait installer des versions légèrement différentes
    qui causent des comportements inattendus.

---

## api/src/zapi/main.py

```python
from datetime import datetime

from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="zapi API")


class Status(BaseModel):
    """Modèle de données pour la réponse de l'endpoint racine."""

    status: str
    engine: str
    timestamp: datetime


@app.get("/", response_model=Status)
async def root() -> Status:
    """Endpoint racine de l'API."""
    return Status(status="running", engine="uv + ruff", timestamp=datetime.now())
```

### Imports

```python
from fastapi import FastAPI
from pydantic import BaseModel
```

`FastAPI` — Classe principale qui représente l'application web.

`BaseModel` — Classe de base Pydantic pour définir des modèles de données.
Pydantic valide automatiquement les types et génère la documentation OpenAPI.

### L'objet app

```python
app = FastAPI(title="zapi API")
```

C'est l'objet central de l'application. Il est référencé par uvicorn au
démarrage (`zapi.main:app`). Le `title` apparaît dans la documentation
Swagger (`/docs`).

### Le modèle Status

```python
class Status(BaseModel):
    status: str
    engine: str
    timestamp: datetime
```

`BaseModel` de Pydantic génère automatiquement :
- La validation des types en entrée/sortie
- La sérialisation JSON
- Le schéma OpenAPI (visible dans `/docs`)

Les annotations de type (`str`, `datetime`) sont **obligatoires** — elles
définissent ce que FastAPI accepte et retourne.

### L'endpoint GET /

```python
@app.get("/", response_model=Status)
async def root() -> Status:
    return Status(status="running", engine="uv + ruff", timestamp=datetime.now())
```

`@app.get("/")` — Décore la fonction pour en faire un handler HTTP GET
sur le chemin `/`.

`response_model=Status` — FastAPI utilise ce modèle pour valider la réponse
et générer la documentation.

`async def` — Fonction asynchrone. FastAPI est basé sur `asyncio` et tire
parti de l'asynchronisme pour gérer de nombreuses requêtes simultanées
sans bloquer.

**Réponse retournée :**
```json
{
    "status": "running",
    "engine": "uv + ruff",
    "timestamp": "2026-05-10T14:30:00.123456"
}
```

---

## Documentation interactive automatique

FastAPI génère automatiquement deux interfaces de documentation :

| URL | Interface | Usage |
|-----|-----------|-------|
| `http://localhost:5000/docs` | Swagger UI | Tester les endpoints interactivement |
| `http://localhost:5000/redoc` | ReDoc | Lire la documentation |

---

## Développement local

```bash
cd api

# Installer les dépendances (crée .venv/)
uv sync

# Démarrer l'API avec rechargement automatique
uv run uvicorn zapi.main:app --reload --host 0.0.0.0 --port 5000

# Linter et formateur
uv run ruff check . --fix
uv run ruff format .

# Tests
uv run pytest
```

`--reload` — Redémarre automatiquement le serveur quand vous modifiez
un fichier Python. Ne pas utiliser en production.

---

## Ajouter un endpoint

Pour ajouter un endpoint, modifiez `api/src/zapi/main.py` :

```python
from typing import List


class Dataset(BaseModel):
    name: str
    type: str
    size: int


@app.get("/datasets", response_model=List[Dataset])
async def list_datasets() -> List[Dataset]:
    """Liste les datasets z/OS disponibles."""
    # Futur : appeler Zowe CLI ou z/OSMF
    return [
        Dataset(name="USER.COBOL.PDS", type="PDS", size=120),
        Dataset(name="USER.DATA.KSDS", type="VSAM", size=5000),
    ]
```

L'endpoint apparaît automatiquement dans la documentation Swagger
sans aucune configuration supplémentaire.
