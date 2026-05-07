# ide/ — Conteneur code-server (VS Code dans le navigateur)

Ce répertoire contient tout ce qui est nécessaire pour construire et configurer
le conteneur `zdev-ide` : l'IDE mainframe accessible depuis un navigateur.

---

## Contenu du répertoire

```
ide/
├── Dockerfile              ← Image Docker (AMD64 + ARM64, proxy, outils)
├── entrypoint.sh           ← Script de démarrage du conteneur
├── settings.json           ← Paramètres VS Code injectés au démarrage
├── ruff.toml               ← Configuration du linter Python (Ruff)
├── setup_host.sh           ← Crée ~/zdev/ sur la machine hôte
├── fetch_extensions.sh     ← Télécharge les .vsix depuis le Marketplace
├── copilot/                ← Instructions GitHub Copilot
│   ├── instructions.md     ← Instructions globales (tous types de fichiers)
│   └── instructions/
│       ├── mainframe.instructions.md  ← COBOL, JCL, z/OS, Db2, CICS
│       └── scripting.instructions.md       ← Python, Bash, TypeScript
├── extensions/             ← Fichiers .vsix pré-téléchargés (gitignorés)
└── zowe/                   ← Archives Zowe CLI hors-ligne (plugins)
```

---

## Fichiers

### `Dockerfile`

Construit l'image Docker de l'IDE. Un seul fichier gère les deux architectures
(AMD64 pour Linux, ARM64 pour macOS Apple Silicon) via une détection automatique
de `uname -m` dans les étapes `RUN`.

Étapes principales :
1. Paquets système de base (`curl`, `git`, `zsh`, `unzip`, `jq`…)
2. Police FiraCode (rendu confortable du code dans l'IDE)
3. Java 21 (requis par IBM Z Open Editor)
4. `uv` (gestionnaire de paquets Python ultra-rapide)
5. Node.js LTS (requis par Zowe CLI)
6. Zowe CLI v3 + plugins (CICS, MQ, FTP, RSE API)
7. code-server (VS Code dans le navigateur, port 8443)
8. Utilisateur non-root `zdev` (UID 1000) + création de `/opt/code-server/extensions/`
9. MkDocs Material + extensions Python
10. Fichiers de configuration copiés dans `/tmp/` (voir `entrypoint.sh`)
11. Extensions VS Code installées dans `/opt/code-server/extensions/` ← **hors volume**, voir ci-dessous
12. Suppression des variables proxy (l'image finale ne contient pas de proxy)
13. `entrypoint.sh` défini comme point d'entrée

Le proxy est passé uniquement au moment du build via `--build-arg` et effacé à
l'étape 12 — le conteneur en cours d'exécution ne connaît pas le proxy.

### `entrypoint.sh`

Exécuté à chaque démarrage du conteneur, **après** que Docker a monté les
volumes hôte.

Ce qu'il fait :
1. Copie `settings.json` → paramètres VS Code utilisateur
2. Copie `ruff.toml` → dossier personnel de `zdev`
3. Copie le dossier `copilot/` → configuration Copilot
4. **Synchronise les extensions** depuis `/opt/code-server/extensions/` vers le volume (voir ci-dessous)
5. Lance `code-server` sur le port 8443

---

## Mécanisme des extensions VS Code

Ce mécanisme répond à un problème fondamental lié aux volumes Docker.

### Le problème : le volume masque l'image

Docker monte les volumes **après** la création des couches de l'image. Si les
extensions étaient installées dans le chemin par défaut de code-server
(`/home/zdev/.local/share/code-server/extensions/`), le volume
`~/zdev/editor/extensions:/home/zdev/.local/share/code-server/extensions`
remplacerait ce dossier par le dossier vide de l'hôte au démarrage.

### La solution : staging dans `/opt/`

Les extensions sont installées dans `/opt/code-server/extensions/` lors du
build — un chemin **jamais monté** comme volume. À chaque démarrage,
`entrypoint.sh` les synchronise en trois étapes :

```
Build (une fois)
  └── code-server --extensions-dir /opt/code-server/extensions \
                  --install-extension *.vsix
        → installe dans /opt/code-server/extensions/
        → génère extensions.json avec chemins absolus vers /opt/

Démarrage du conteneur (à chaque fois)
  1. Docker monte ~/zdev/editor/extensions → /home/zdev/.local/.../extensions
  2. entrypoint.sh s'exécute :
       a. Copie les dossiers d'extensions manquants de /opt/ vers le volume
       b. Recopie extensions.json en corrigeant les chemins (/opt/ → volume)
       c. Réinitialise .obsolete à {}
  3. code-server démarre avec les extensions correctement enregistrées
```

### Pourquoi `extensions.json` et `.obsolete` sont critiques

**`extensions.json`** est le registre interne de code-server. Sans lui (ou
avec des chemins incorrects), code-server ne reconnaît pas les extensions
présentes dans le dossier et les marque comme orphelines à supprimer.

**`.obsolete`** est la liste des extensions que code-server doit supprimer au
prochain démarrage. Lorsque code-server trouve des extensions non enregistrées,
il les y inscrit toutes — elles disparaissent alors de l'interface. `entrypoint.sh`
réinitialise ce fichier à `{}` à chaque démarrage pour empêcher ce nettoyage.

### Persistance des extensions installées par l'utilisateur

Les extensions installées depuis l'interface VS Code vont directement dans le
volume (`~/zdev/editor/extensions/`) et persistent entre les redémarrages. Lors
de la reconstruction de `extensions.json`, `entrypoint.sh` préserve ces entrées
supplémentaires (fusion des extensions hors staging).

Si une extension du staging est supprimée du volume (manuellement ou par
code-server), elle est restaurée automatiquement au démarrage suivant.

---

### `settings.json`

Paramètres VS Code appliqués à l'utilisateur `zdev` à chaque démarrage du
conteneur. Définit notamment le thème, les extensions actives par défaut, la
configuration de Ruff comme linter Python, et les préférences d'édition.

Ces paramètres sont copiés dans le volume `~/zdev/editor/settings/` sur l'hôte
via `entrypoint.sh` — ils prennent effet immédiatement dans l'IDE.

### `ruff.toml`

Configuration du linter et formateur Python [Ruff](https://docs.astral.sh/ruff/).
Définit les règles activées, la longueur de ligne (88 caractères), les
conventions d'import, etc. Copié dans le dossier personnel de `zdev` à chaque
démarrage.

### `setup_host.sh`

Crée l'arborescence `~/zdev/` sur la machine hôte. Ces répertoires sont montés
comme volumes Docker dans le conteneur et assurent la persistance des données
(projets, profils Zowe, paramètres VS Code) même si le conteneur est supprimé.

À exécuter **une seule fois** lors de la première installation.

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

Le fichier `.zshrc` est créé avec une configuration de base incluant la fonction
`zdev` pour appeler l'API depuis le terminal VS Code :

```bash
zdev() { curl -s "http://zdev-api:5000${1:-/}"; }
# Exemples : zdev     → statut de l'API
#            zdev /datasets
```

> **Attention :** si `~/zdev/` existe déjà, ce script le supprime avant de le
> recréer. Sauvegardez `~/zdev/projects/` au préalable si nécessaire.

### `fetch_extensions.sh`

Télécharge les extensions VS Code depuis le Marketplace Microsoft sous forme de
fichiers `.vsix` dans le dossier `extensions/`. Ces fichiers sont ensuite intégrés
à l'image Docker lors du build, ce qui permet d'installer les extensions sans
accès réseau dans les environnements restreints (réseau d'entreprise).

Fonctionnalités :
- Résout automatiquement les dépendances entre extensions
- Évite les doublons (même extension déjà téléchargée)
- Prend en charge un proxy HTTP via `--proxy`
- Continue sur les erreurs individuelles et liste les échecs en fin d'exécution

```bash
# Sans proxy
./fetch_extensions.sh

# Avec proxy
./fetch_extensions.sh --proxy http://mon-proxy:3128
```

---

## Dossiers

### `copilot/`

Contient les instructions transmises à GitHub Copilot via la fonctionnalité
*custom instructions* de VS Code.

- **`instructions.md`** — instructions globales, appliquées à tous les fichiers.
  Définit le ton, le style de code, les règles de nommage communes.
- **`instructions/mainframe.instructions.md`** — instructions spécifiques au
  développement IBM z/OS : IBM Enterprise COBOL 6.5, JCL, VSAM, Db2, CICS,
  HLASM. Appliquées aux fichiers `.cbl`, `.jcl`, `.asm`, etc.
- **`instructions/scripting.instructions.md`** — instructions pour Python, Bash et
  TypeScript (développement ouvert). Appliquées aux fichiers `.py`, `.sh`, `.ts`.

Ces fichiers utilisent le champ `applyTo` dans leur en-tête pour cibler
automatiquement le bon type de fichier.

### `extensions/`

Dossier contenant les fichiers `.vsix` téléchargés par `fetch_extensions.sh`.
Ce dossier est **gitignored** (seul un `.gitkeep` est versionné) car les fichiers
peuvent peser plusieurs centaines de mégaoctets.

Il doit être peuplé avant de lancer `make build` :

```bash
make fetch-ext    # télécharge les .vsix
make build        # intègre les .vsix dans l'image
```

### `zowe/`

Contient les archives Zowe CLI hors-ligne (packages npm compressés) utilisées
pour installer Zowe et ses plugins sans accès à internet pendant le build.
Permet de construire l'image dans un réseau d'entreprise sans proxy npm.
