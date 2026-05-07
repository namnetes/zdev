#!/bin/bash
# Point d'entrée du conteneur zdev-vscode.
# Lancé automatiquement par Docker au démarrage du conteneur (ENTRYPOINT).
# Ce script est l'endroit approprié pour toute initialisation à chaque démarrage
# (ex. synchronisation de repos, installation d'extensions supplémentaires).
set -euo pipefail

# Exemple : forcer l'installation d'extensions à chaque démarrage
# (utile pour des extensions non incluses dans l'image, installées depuis un registry).
# EXTENSIONS=(
#   "IBM.zopeneditor"
#   "IBM.zowe-explorer"
#   "IBM.cics-explorer"
# )
#for ext in "${EXTENSIONS[@]}"; do
#  code-server --install-extension "$ext" || true
#done

# Export JAVA_HOME pour l'utilisateur code-server, qui en a besoin pour certaines
# extensions (ex. Z Open Editor).
export JAVA_HOME=/opt/java
export PATH="$JAVA_HOME/bin:$PATH"

cp /tmp/ruff.toml /home/zdev/ruff.toml
cp /tmp/settings.json /home/zdev/.local/share/code-server/User/settings.json
cp -r /tmp/copilot/ /home/zdev/.config/copilot/

# Synchronisation des extensions intégrées à l'image vers le volume utilisateur.
#
# Problème : Docker monte le volume après la création de l'image, masquant les
# extensions installées dans /home/zdev/. On les installe donc dans /opt/ pendant
# le build, puis on les copie ici après que le volume est en place.
#
# On reconstruit aussi extensions.json (avec les chemins corrects) et on vide
# .obsolete — sinon code-server supprime les extensions qu'il ne reconnaît pas.
STAGED="/opt/code-server/extensions"
USEREXT="/home/zdev/.local/share/code-server/extensions"
if [ -d "$STAGED" ]; then
    mkdir -p "$USEREXT"

    # Copie des répertoires d'extensions manquants
    for ext_dir in "$STAGED"/*/; do
        [ -d "$ext_dir" ] || continue
        ext_name=$(basename "$ext_dir")
        if [ ! -d "$USEREXT/$ext_name" ]; then
            cp -r "$ext_dir" "$USEREXT/"
        fi
    done

    # Reconstruction de extensions.json avec les chemins pointant vers le volume.
    # Les extensions installées par l'utilisateur via l'UI sont conservées.
    python3 - <<'PYEOF'
import json, os

staged_json = "/opt/code-server/extensions/extensions.json"
user_dir    = "/home/zdev/.local/share/code-server/extensions"
dest_json   = f"{user_dir}/extensions.json"

if not os.path.exists(staged_json):
    raise SystemExit

with open(staged_json) as f:
    staged = json.load(f)

for e in staged:
    if "location" in e and "path" in e["location"]:
        e["location"]["path"] = e["location"]["path"].replace(
            "/opt/code-server/extensions", user_dir
        )

try:
    with open(dest_json) as f:
        existing = json.load(f)
except Exception:
    existing = []

staged_ids = {e["identifier"]["id"] for e in staged}
extras = [e for e in existing if e["identifier"]["id"] not in staged_ids]

with open(dest_json, "w") as f:
    json.dump(staged + extras, f)
PYEOF

    # Vider .obsolete : code-server supprime toute extension listée ici.
    echo '{}' > "$USEREXT/.obsolete"
fi

# Lancer code-server.
# --bind-addr 0.0.0.0:8443 : écoute sur toutes les interfaces réseau du conteneur,
#   ce qui permet à Docker de router le port 8443 depuis l'hôte.
# Le point final "." ouvre le workspace (/home/zdev/workspace via le répertoire courant).
# exec remplace le processus shell par code-server — les signaux Docker (SIGTERM)
# sont ainsi transmis directement à code-server pour un arrêt propre.
exec code-server --bind-addr 0.0.0.0:8443 .
