# ide/setup_host.sh — ligne par ligne

`setup_host.sh` crée l'arborescence `~/zdev/` sur votre machine hôte.
Ces dossiers sont montés comme volumes Docker dans le conteneur `zdev-ide`,
garantissant la persistance de vos données entre les redémarrages.

**Fichier :** `ide/setup_host.sh`
**Déclenché par :** `make setup-host` (une seule fois lors de l'installation)
**Résultat :** `~/zdev/` avec la structure complète

---

## Pourquoi ce script est nécessaire

Sans `~/zdev/` sur l'hôte, Docker ne peut pas créer les volumes au démarrage
du conteneur. De plus, certains fichiers (`.zshrc`, `.gitconfig`) doivent
exister **avant** le démarrage du conteneur, sinon Docker crée des dossiers
à la place de fichiers.

!!! warning "Attention : réinitialisation complète"
    Si `~/zdev/` existe déjà, **ce script le supprime avant de le recréer**.
    Sauvegardez `~/zdev/projects/` si vous avez des fichiers de travail
    avant de relancer `make setup-host`.

---

## En-tête et variable principale

```bash
#!/usr/bin/env bash
set -euo pipefail

ZDEV_DIR="$HOME/zdev"
```

`$HOME` est la variable d'environnement standard qui pointe vers le dossier
home de l'utilisateur courant (ex. `/home/alice` ou `/Users/alice` sur macOS).

---

## Suppression de l'ancienne arborescence

```bash
if [ -d "$ZDEV_DIR" ]; then
    echo "Suppression de l'ancienne arborescence $ZDEV_DIR..."
    if ! rm -rf "$ZDEV_DIR" 2>/dev/null; then
        echo "  → droits insuffisants, nouvelle tentative avec sudo..."
        sudo rm -rf "$ZDEV_DIR"
    fi
fi
```

La double tentative (d'abord sans `sudo`, puis avec) est nécessaire car
les volumes Docker sont parfois créés avec les droits `root` à l'intérieur
du conteneur. Le dossier `~/zdev/` peut donc appartenir partiellement à `root`,
rendant `rm -rf` impossible sans élévation de droits.

`2>/dev/null` — Redirige les messages d'erreur du premier `rm` vers le néant
(on ne veut pas voir "Permission denied" si on va réessayer avec sudo).

`if ! rm -rf "$ZDEV_DIR" 2>/dev/null; then` — La commande `!` inverse le
code de retour : si `rm` échoue (code ≠ 0), la condition est vraie → on
passe dans le `then`.

---

## Création des dossiers

```bash
mkdir -p "$ZDEV_DIR/projects"
mkdir -p "$ZDEV_DIR/zowe"
mkdir -p "$ZDEV_DIR/editor/settings"
mkdir -p "$ZDEV_DIR/editor/extensions"
mkdir -p "$ZDEV_DIR/cache/npm"
mkdir -p "$ZDEV_DIR/cache/pip"
```

`mkdir -p` — Crée le dossier et tous ses parents si nécessaire, sans erreur
si le dossier existe déjà.

Chaque dossier correspond exactement à un volume défini dans `docker-compose.yml` :

| Dossier créé | Volume Docker | Chemin dans le conteneur |
|---|---|---|
| `~/zdev/projects/` | `~/zdev/projects:/home/zdev/workspace` | `/home/zdev/workspace` |
| `~/zdev/zowe/` | `~/zdev/zowe:/home/zdev/.zowe` | `/home/zdev/.zowe` |
| `~/zdev/editor/settings/` | `~/zdev/editor/settings:/home/zdev/.local/share/code-server/User` | Paramètres VS Code |
| `~/zdev/editor/extensions/` | `~/zdev/editor/extensions:/home/zdev/.local/share/code-server/extensions` | Extensions VS Code |
| `~/zdev/cache/npm/` | `~/zdev/cache/npm:/home/zdev/.npm` | Cache npm |
| `~/zdev/cache/pip/` | `~/zdev/cache/pip:/home/zdev/.cache/pip` | Cache pip/uv |

---

## Création de .zshrc

```bash
cat > "$ZDEV_DIR/.zshrc" << 'EOF'
# ~/.zshrc — configuration du shell zsh dans le conteneur zdev-ide.
# Ce fichier est persisté dans ~/zdev/.zshrc sur la machine hôte.

# ── zdev API ──────────────────────────────────────────────────────────────────
zdev() {
    local path="${1:-/}"
    curl -s "http://zdev-api:5000${path}"
}
EOF
```

**`cat > fichier << 'EOF'`** — C'est un "heredoc" : permet d'écrire un
fichier multi-lignes directement dans le script. Les guillemets autour de
`'EOF'` désactivent l'interprétation des variables à l'intérieur (on veut
que `${1:-/}` reste tel quel dans le fichier, pas qu'il soit évalué par bash).

La fonction `zdev()` permet d'appeler l'API depuis le terminal VS Code :

```bash
zdev          # → curl -s "http://zdev-api:5000/"
zdev /jobs    # → curl -s "http://zdev-api:5000/jobs"
```

`${1:-/}` — Le premier argument passé à la fonction, ou `/` si aucun argument.

`http://zdev-api:5000` — Fonctionne car les deux conteneurs (`zdev-ide` et
`zdev-api`) partagent le réseau Docker `zdev_default`. Docker résout le nom
`zdev-api` automatiquement.

---

## Création de .gitconfig

```bash
touch "$ZDEV_DIR/.gitconfig"
```

`touch` crée un fichier vide s'il n'existe pas (sans le modifier s'il existe).

Docker exige que les fichiers montés comme volumes existent sur l'hôte
avant le démarrage du conteneur. Si `.gitconfig` n'existe pas, Docker
créerait un **dossier** à la place — et Git échouerait à le lire.

Ce fichier vide sera rempli par Git quand l'utilisateur fera ses premiers
`git config` dans le conteneur.

---

## Droits d'accès

```bash
chmod -R 755 "$ZDEV_DIR"
chown -R "$(id -u):$(id -g)" "$ZDEV_DIR"
chmod 644 "$ZDEV_DIR/.zshrc" "$ZDEV_DIR/.gitconfig"
```

`chmod -R 755` — Donne au propriétaire tous les droits (lecture, écriture,
exécution), aux autres la lecture et l'exécution. `-R` : récursif.

`chown -R "$(id -u):$(id -g)"` — Assigne l'arborescence à l'utilisateur
courant. `$(id -u)` retourne l'UID (User ID) et `$(id -g)` le GID (Group ID).

`chmod 644 .zshrc .gitconfig` — Fichiers de configuration : lecture/écriture
pour le propriétaire, lecture seule pour les autres.

---

## Résumé affiché

À la fin du script, l'arborescence créée est affichée :

```
Arborescence initialisée :

  ~/zdev/
  ├── projects/          → /home/zdev/workspace
  ├── zowe/              → /home/zdev/.zowe
  ├── editor/
  │   ├── settings/      → .../code-server/User
  │   └── extensions/    → .../code-server/extensions
  ├── cache/
  │   ├── npm/           → /home/zdev/.npm
  │   └── pip/           → /home/zdev/.cache/pip
  ├── .zshrc             → /home/zdev/.zshrc
  └── .gitconfig         → /home/zdev/.gitconfig

  ~/.ssh  (existant)     → /home/zdev/.ssh  (lecture seule)
```

!!! note "Clés SSH"
    `~/.ssh` n'est pas créé par ce script — il est supposé exister déjà.
    Il est monté en **lecture seule** dans le conteneur (`:ro` dans
    docker-compose.yml) pour protéger vos clés privées.
