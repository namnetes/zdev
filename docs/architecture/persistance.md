# Persistance des données & Proxy

## Volumes Docker

Toutes les données utilisateur sont stockées sur la machine hôte dans `~/zdev/`
et survivent à la suppression et à la recréation des conteneurs.

| Dossier hôte                  | Dossier dans le conteneur                     |
|-------------------------------|-----------------------------------------------|
| `~/zdev/projects/`            | `/home/zdev/workspace`                        |
| `~/zdev/zowe/`                | `/home/zdev/.zowe`                            |
| `~/zdev/editor/settings/`     | `~/.local/share/code-server/User`             |
| `~/zdev/editor/extensions/`   | `~/.local/share/code-server/extensions`       |
| `~/zdev/cache/npm/`           | `/home/zdev/.npm`                             |
| `~/zdev/cache/pip/`           | `/home/zdev/.cache/pip`                       |
| `~/zdev/.zshrc`               | `/home/zdev/.zshrc`                           |
| `~/zdev/.gitconfig`           | `/home/zdev/.gitconfig`                       |
| `~/.ssh` *(lecture seule)*    | `/home/zdev/.ssh`                             |

### Arborescence `~/zdev/`

```
~/zdev/
├── projects/           → /home/zdev/workspace
├── zowe/               → /home/zdev/.zowe
├── editor/
│   ├── settings/       → ~/.local/share/code-server/User
│   └── extensions/     → ~/.local/share/code-server/extensions
├── cache/
│   ├── npm/            → /home/zdev/.npm
│   └── pip/            → /home/zdev/.cache/pip
├── .zshrc              → /home/zdev/.zshrc
└── .gitconfig          → /home/zdev/.gitconfig
```

---

## Paramètres VS Code

`settings.json` est copié dans le volume **uniquement au premier démarrage**
(si absent). Les modifications ultérieures faites par l'utilisateur dans l'IDE
sont préservées entre les redémarrages.

`ruff.toml` est copié à chaque démarrage — c'est un fichier de configuration
géré par le projet, pas par l'utilisateur.

---

## Proxy d'entreprise

```bash
# Via variable d'environnement shell
export HTTP_PROXY=http://mon-proxy:3128
make build

# Via argument Make (prioritaire sur HTTP_PROXY)
make build PROXY=http://mon-proxy:3128
make fetch-ext PROXY=http://user:pass@proxy:port
```

Le proxy est injecté uniquement au moment du build via `--build-arg HTTP_PROXY`
et `--build-arg HTTPS_PROXY`, puis **supprimé de l'image finale** (`ENV
HTTP_PROXY=` à la dernière étape du Dockerfile). Le conteneur en cours
d'exécution ne connaît pas le proxy — l'image peut être distribuée sans risque.
