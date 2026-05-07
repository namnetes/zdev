#!/usr/bin/env bash
# =============================================================================
# setup_host.sh — Initialisation de l'arborescence ~/zdev/ sur la machine hôte
#
# Ces dossiers sont montés comme volumes Docker dans le conteneur zdev-ide.
# Ils garantissent que vos données (projets, configuration, profils Zowe…)
# sont conservées même si le conteneur est supprimé et recréé.
#
# À exécuter une seule fois lors de la première installation, ou pour
# repartir d'un environnement entièrement vierge.
#
# Usage :
#   ./setup_host.sh
#
# ATTENTION : si ~/zdev/ existe déjà, il sera supprimé avant recréation.
# Sauvegardez ~/zdev/projects/ si vous avez des fichiers de travail.
# =============================================================================
set -euo pipefail

ZDEV_DIR="$HOME/zdev"

# ── Nettoyage de l'état précédent ─────────────────────────────────────────────
# Les volumes Docker sont parfois créés par root à l'intérieur du conteneur.
# Si rm échoue (Permission non accordée), on retente avec sudo.
if [ -d "$ZDEV_DIR" ]; then
    echo "Suppression de l'ancienne arborescence $ZDEV_DIR..."
    if ! rm -rf "$ZDEV_DIR" 2>/dev/null; then
        echo "  → droits insuffisants, nouvelle tentative avec sudo..."
        sudo rm -rf "$ZDEV_DIR"
    fi
fi

# ── Création des dossiers ─────────────────────────────────────────────────────
# Chaque mkdir correspond exactement à un volume défini dans docker-compose.yml.

# Espace de travail principal — monté dans /home/zdev/workspace
mkdir -p "$ZDEV_DIR/projects"

# Profils et connexions Zowe CLI — monté dans /home/zdev/.zowe
# Contient les profils z/OS (hôtes, credentials, régions CICS…).
# Sans ce dossier, Zowe doit être reconfiguré à chaque recréation du conteneur.
mkdir -p "$ZDEV_DIR/zowe"

# Paramètres VS Code (settings.json, keybindings.json, snippets…)
# monté dans /home/zdev/.local/share/code-server/User
mkdir -p "$ZDEV_DIR/editor/settings"

# Extensions VS Code installées depuis l'interface VS Code
# montées dans /home/zdev/.local/share/code-server/extensions
# (les extensions embarquées dans l'image restent séparées)
mkdir -p "$ZDEV_DIR/editor/extensions"

# Caches — accélèrent les installations répétées à l'intérieur du conteneur
mkdir -p "$ZDEV_DIR/cache/npm"  # monté dans /home/zdev/.npm
mkdir -p "$ZDEV_DIR/cache/pip"  # monté dans /home/zdev/.cache/pip

# ── Fichiers de configuration ─────────────────────────────────────────────────
# Docker exige que les fichiers montés existent sur l'hôte avant le démarrage
# du conteneur. On les crée vides s'ils n'existent pas.
touch "$ZDEV_DIR/.zshrc"     # monté dans /home/zdev/.zshrc
touch "$ZDEV_DIR/.gitconfig" # monté dans /home/zdev/.gitconfig

# ── Droits d'accès ────────────────────────────────────────────────────────────
chmod -R 755 "$ZDEV_DIR"
chown -R "$(id -u):$(id -g)" "$ZDEV_DIR"
chmod 644 "$ZDEV_DIR/.zshrc" "$ZDEV_DIR/.gitconfig"

# ── Résumé ────────────────────────────────────────────────────────────────────
echo ""
echo "Arborescence initialisée :"
echo ""
echo "  $ZDEV_DIR/"
echo "  ├── projects/          → /home/zdev/workspace"
echo "  ├── zowe/              → /home/zdev/.zowe"
echo "  ├── editor/"
echo "  │   ├── settings/      → .../code-server/User"
echo "  │   └── extensions/    → .../code-server/extensions"
echo "  ├── cache/"
echo "  │   ├── npm/           → /home/zdev/.npm"
echo "  │   └── pip/           → /home/zdev/.cache/pip"
echo "  ├── .zshrc             → /home/zdev/.zshrc"
echo "  └── .gitconfig         → /home/zdev/.gitconfig"
echo ""
echo "  ~/.ssh  (existant)     → /home/zdev/.ssh  (lecture seule)"
echo ""
