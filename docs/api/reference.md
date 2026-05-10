# API Reference — zdev-api

L'API FastAPI tourne sur le port **5000**. Elle est accessible depuis la machine
hôte et depuis le conteneur `zdev-ide` via le réseau Docker.

## Endpoints

### `GET /` — Statut de l'API

Retourne un objet JSON indiquant que l'API est opérationnelle.

**Réponse :**

```json
{
    "status": "running",
    "engine": "uv + ruff",
    "timestamp": "2026-05-07T21:00:00.000000"
}
```

**Schéma Pydantic :**

| Champ       | Type       | Description                    |
|-------------|------------|--------------------------------|
| `status`    | `str`      | Toujours `"running"`           |
| `engine`    | `str`      | Stack Python utilisée          |
| `timestamp` | `datetime` | Heure de la requête (UTC)      |

---

## Accès

=== "Depuis l'hôte"

    ```bash
    curl http://localhost:5000/
    curl -s http://localhost:5000/ | python3 -m json.tool
    ```

=== "Depuis zdev-ide"

    ```bash
    curl http://zdev-api:5000/
    # ou via la fonction zdev définie dans .zshrc :
    zdev
    ```

=== "Interface Swagger"

    Ouvrir **http://localhost:5000/docs** dans le navigateur.

---

## Développement local

```bash
cd api
uv sync
uv run uvicorn zapi.main:app --reload --host 0.0.0.0 --port 5000
```

La documentation interactive (Swagger UI) est disponible sur
`http://localhost:5000/docs` et ReDoc sur `http://localhost:5000/redoc`.

---

## Structure du code

```
api/
├── Dockerfile              ← python:3.14-slim, uv, src layout
├── pyproject.toml          ← fastapi, pydantic, uvicorn + ruff (dev)
├── .python-version         ← 3.14
├── uv.lock                 ← Versionné — builds reproductibles
└── src/
    └── zapi/
        ├── __init__.py
        └── main.py         ← Application FastAPI
```

!!! note "Design futur"
    L'API est conçue pour être appelée via `curl` depuis le terminal VS Code.
    Les futurs endpoints (`/datasets`, `/jobs/submit`, etc.) utiliseront une
    authentification légère par clé API dans le header, adaptée au déploiement
    local/LAN.
