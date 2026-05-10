# Vue d'ensemble de l'architecture

## Services

| Service     | Port | Base image         | Rôle                                              |
|-------------|------|--------------------|---------------------------------------------------|
| `zdev-ide`  | 8443 | Debian bookworm-slim | code-server + IBM mainframe tools               |
| `zdev-api`  | 5000 | python:3.14-slim   | API FastAPI (backend du projet)                   |

Les deux services sont définis dans `docker-compose.yml` et partagent le réseau
Docker `zdev_default` — `zdev-ide` peut appeler `zdev-api` via
`http://zdev-api:5000` sans passer par l'hôte.

---

## Versions clés dans `zdev-ide`

| Composant       | Version  | Référence de compatibilité                                    |
|-----------------|----------|---------------------------------------------------------------|
| Node.js LTS     | **22.22.2** | Zowe v3 supporte 20, 22, 24 — Node 22 recommandé (LTS jusqu'en avril 2027) |
| Java            | JDK 21   | Minimum JRE 17 pour Z Open Editor ; JDK 21 recommandé        |
| Zowe CLI        | v3.4 (`zowe-v3-lts`) | Versions Node 25+ **non supportées**             |
| code-server     | 4.117.0  | VS Code API 1.90.0+                                          |
| Python          | 3.x      | Disponible pour les scripts et le SDK Zowe Python            |

!!! note "Source des versions"
    Versions validées par [namnetes/zowe-client](https://github.com/namnetes/zowe-client)
    — référence à consulter avant toute mise à jour.

---

## Structure du projet

```
zdev/
├── Makefile                  ← Point d'entrée unique (build, run, setup)
├── docker-compose.yml        ← Définition des deux services
├── .env.example              ← Template de configuration
│
├── ide/                      ← Conteneur IDE (code-server + outils IBM)
│   ├── Dockerfile            ← Multi-platform (AMD64/ARM64)
│   ├── entrypoint.sh         ← Extension sync + startup logic
│   ├── settings.json         ← Paramètres VS Code injectés au démarrage
│   ├── ruff.toml             ← Configuration linter Python
│   ├── setup_host.sh         ← Crée ~/zdev/ sur l'hôte
│   ├── fetch_extensions.sh   ← Télécharge les .vsix
│   ├── copilot/              ← Instructions GitHub Copilot
│   │   ├── instructions.md   ← Instructions globales (tous fichiers)
│   │   └── instructions/
│   │       ├── mainframe.instructions.md  ← COBOL, JCL, z/OS, Db2, CICS
│   │       └── scripting.instructions.md  ← Python, Bash, TypeScript
│   ├── extensions/           ← Fichiers .vsix (gitignorés)
│   └── zowe/                 ← Archives Zowe CLI hors-ligne (offline)
│
└── api/                      ← Conteneur API (FastAPI + uvicorn)
    ├── Dockerfile
    ├── pyproject.toml
    └── src/zapi/
```

---

## Multi-plateforme

Un seul `Dockerfile` gère les deux architectures. La détection se fait via
`uname -m` dans le `Makefile` :

| Machine                   | Plateforme       |
|---------------------------|------------------|
| Linux x86_64              | `linux/amd64`    |
| macOS Apple Silicon (M1+) | `linux/arm64`    |

---

## Proxy d'entreprise

Le proxy est passé au build via `--build-arg` et **supprimé de l'image finale**.
Le conteneur en cours d'exécution ne connaît pas le proxy.

```mermaid
flowchart LR
    subgraph build["Build (une fois)"]
        proxy["HTTP_PROXY\n--build-arg"]
        dockerfile["Dockerfile\nétapes proxy-aware"]
        image["Image finale\nsans proxy"]
        proxy --> dockerfile --> image
    end

    subgraph runtime["Runtime"]
        container["Conteneur\naucun proxy"]
    end

    image --> container

    classDef startStop fill:#e1f5fe,stroke:#01579b
    classDef data fill:#fff3e0,stroke:#e65100
    classDef error fill:#ffebee,stroke:#c62828
    class proxy data
    class dockerfile,image startStop
    class container startStop
```
