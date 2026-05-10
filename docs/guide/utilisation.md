# Utilisation quotidienne

## Commandes courantes

```bash
make up       # Démarrer les conteneurs
make down     # Arrêter les conteneurs
make logs     # Afficher les logs en temps réel
make help     # Voir toutes les commandes disponibles
```

Le conteneur redémarre automatiquement au démarrage de la machine
(`restart: unless-stopped` dans `docker-compose.yml`).

---

## Accès aux interfaces

| URL                          | Interface                            |
|------------------------------|--------------------------------------|
| `http://localhost:8443`      | VS Code dans le navigateur           |
| `http://localhost:5000`      | API FastAPI (JSON)                   |
| `http://localhost:5000/docs` | Documentation interactive (Swagger)  |

---

## Commandes Make complètes

| Commande         | Description                                             |
|------------------|---------------------------------------------------------|
| `make build`     | Build les deux images Docker (IDE + API)                |
| `make build-ide` | Build uniquement l'image IDE                            |
| `make build-api` | Build uniquement l'image API                            |
| `make up`        | Démarrer les conteneurs (mode détaché)                  |
| `make down`      | Arrêter et supprimer les conteneurs                     |
| `make logs`      | Streamer les logs des deux services                     |
| `make setup-host`| Créer `~/zdev/` sur l'hôte                             |
| `make fetch-ext` | Télécharger les extensions `.vsix`                      |
| `make clean`     | Supprimer les images Docker locales                     |

### Gestion du proxy

```bash
# Via variable d'environnement shell
export HTTP_PROXY=http://mon-proxy:3128
make build

# Via argument Make (prioritaire sur HTTP_PROXY)
make build PROXY=http://mon-proxy:3128
make fetch-ext PROXY=http://mon-proxy:3128
```

---

## Développement de l'API

```bash
cd api
uv sync                                   # Installer les dépendances
uv run uvicorn zapi.main:app \
    --reload --host 0.0.0.0 --port 5000   # Démarrer avec rechargement auto
uv run ruff check . --fix                 # Linter
uv run ruff format .                      # Formater
uv run pytest                             # Tests
uv add <paquet>                           # Ajouter une dépendance
```

!!! note
    Toujours utiliser `uv`. Ne jamais utiliser `pip` ou `poetry` directement.

---

## Appeler l'API depuis l'IDE

La fonction `zdev` est disponible dans le terminal VS Code (définie dans `~/zdev/.zshrc`) :

```bash
zdev            # GET http://zdev-api:5000/  → statut de l'API
zdev /datasets  # GET http://zdev-api:5000/datasets
```

Les deux conteneurs partagent le réseau Docker `zdev_default`, permettant à
`zdev-ide` d'appeler `zdev-api` par son nom de service sans passer par l'hôte.
