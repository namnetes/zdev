#!/usr/bin/env bash
# =============================================================================
# fetch_extensions.sh — Téléchargement des extensions VS Code pour installation
#                        hors-ligne dans le conteneur zdev-ide.
#
# Pourquoi ce script existe
# ─────────────────────────
# Le conteneur installe les extensions depuis des fichiers .vsix locaux plutôt
# que depuis le Marketplace Microsoft. Cette approche est nécessaire dans les
# réseaux d'entreprise où le conteneur Docker n'a pas accès à Internet.
# Ce script est exécuté une seule fois sur la machine hôte (qui, elle, a accès
# au Marketplace), avant de construire l'image Docker avec `make build`.
#
# Ce que fait ce script
# ─────────────────────
#   1. Interroge l'API publique du Marketplace pour obtenir la version la plus
#      récente de chaque extension demandée.
#   2. Télécharge le fichier .vsix (paquet d'installation VS Code).
#   3. Lit les dépendances déclarées dans chaque .vsix et les télécharge
#      automatiquement (appels récursifs).
#   4. Stocke tous les fichiers dans le dossier extensions/.
#
# Utilisation
# ───────────
#   ./fetch_extensions.sh
#   ./fetch_extensions.sh --proxy http://mon-proxy:3128
#   ./fetch_extensions.sh --no-proxy
#   ./fetch_extensions.sh --help
#
# Options
# ───────
#   --proxy <url>   Proxy HTTP à utiliser (ex : http://10.0.0.1:3128).
#                   Par défaut, la variable d'environnement HTTP_PROXY est
#                   utilisée si elle est définie.
#   --no-proxy      Désactive tout proxy, même si HTTP_PROXY est défini.
#   --help, -h      Affiche cette aide.
#
# Prérequis
# ─────────
#   curl     — téléchargement des fichiers
#   python3  — lecture des réponses JSON de l'API Marketplace
#   unzip    — lecture du contenu des fichiers .vsix (archives ZIP)
# =============================================================================
set -euo pipefail


# ── Constantes ────────────────────────────────────────────────────────────────

# Dossier de destination des fichiers .vsix.
# Chemin relatif au dossier ide/ depuis lequel ce script est exécuté.
readonly OUTPUT_DIR="extensions"

# URL de base de l'API publique du Marketplace Microsoft.
# Cette API est accessible sans authentification et renvoie les métadonnées
# (version, dépendances, etc.) de chaque extension.
readonly MARKETPLACE_API="https://marketplace.visualstudio.com/_apis/public/gallery"


# ── Variables d'état ──────────────────────────────────────────────────────────

# Proxy HTTP. Par défaut, on lit HTTP_PROXY depuis l'environnement du shell.
# Reste vide si aucun proxy n'est nécessaire.
PROXY="${HTTP_PROXY:-}"

# Liste des extensions qui ont échoué, pour le récapitulatif final.
declare -a ERRORS=()

# Chaîne de déduplication : évite de télécharger deux fois la même extension
# (une extension peut être listée directement ET comme dépendance d'une autre).
# Format : "::editeur1.nom1::editeur2.nom2::"
SEEN_IDS=""


# ── Fonctions utilitaires ─────────────────────────────────────────────────────

# Affiche un message d'information (texte en bleu).
log_info() { echo -e "\033[0;34mℹ\033[0m  $*"; }

# Affiche un message de succès (texte en vert).
log_ok()   { echo -e "\033[0;32m✓\033[0m  $*"; }

# Affiche un message d'erreur (texte en rouge) sur la sortie d'erreur standard.
log_err()  { echo -e "\033[0;31m✗\033[0m  $*" >&2; }

# Affiche l'aide et quitte.
show_help() {
    cat << 'EOF'
Utilisation :
  ./fetch_extensions.sh [--proxy <url>] [--no-proxy] [--help]

Options :
  --proxy <url>   Proxy HTTP (ex : --proxy http://mon-proxy:3128)
                  Par défaut : valeur de la variable HTTP_PROXY.
  --no-proxy      Désactive tout proxy.
  --help, -h      Affiche cette aide.

Les fichiers .vsix sont téléchargés dans le dossier extensions/.
Relancez ce script avant chaque `make build` pour mettre à jour les extensions.
EOF
    exit 0
}

# Vérifie que les outils nécessaires sont disponibles sur la machine hôte.
# Arrête le script avec un message clair si un outil est absent.
check_prerequisites() {
    local missing=0
    for tool in curl python3 unzip; do
        if ! command -v "$tool" > /dev/null 2>&1; then
            log_err "Outil manquant : '${tool}'. Installez-le avant de relancer ce script."
            missing=1
        fi
    done
    [[ $missing -eq 0 ]] || exit 1
}


# ── Lecture des arguments ─────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
    case "$1" in
        --proxy)
            if [[ -z "${2:-}" ]]; then
                log_err "--proxy requiert une URL en argument (ex : --proxy http://hote:3128)"
                exit 1
            fi
            PROXY="$2"
            shift 2
            ;;
        --no-proxy)
            PROXY=""
            shift
            ;;
        --help | -h)
            show_help
            ;;
        *)
            log_err "Option inconnue : '$1'. Utilisez --help pour voir les options."
            exit 1
            ;;
    esac
done


# ── Configuration de curl ─────────────────────────────────────────────────────

# Les options sont dans un tableau pour être réutilisées dans chaque appel curl
# sans copier-coller. Un tableau est plus sûr qu'une chaîne car il gère
# correctement les espaces dans les valeurs (ex : URL avec espaces).
#
#   -f  : retourne une erreur si le serveur répond HTTP >= 400
#   -s  : mode silencieux (pas d'indicateur de progression)
#   -S  : affiche quand même les erreurs en mode silencieux
#   -L  : suit les redirections HTTP
#   --compressed : accepte les réponses compressées (réduit la bande passante)
CURL_OPTS=(-fsSL --compressed)

if [[ -n "$PROXY" ]]; then
    CURL_OPTS+=(--proxy "$PROXY")
fi


# ── Préparation du dossier de sortie ─────────────────────────────────────────

# On repart d'un dossier vide pour éviter d'accumuler d'anciennes versions.
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"


# =============================================================================
# fetch_extension <identifiant> [indentation]
#
# Télécharge une extension VS Code et, récursivement, toutes ses dépendances.
#
# Arguments :
#   $1  Identifiant de l'extension au format "editeur.nom"
#       Exemples : "ms-python.python", "IBM.zopeneditor"
#   $2  (optionnel) Préfixe d'indentation, utilisé uniquement pour l'affichage
#       des dépendances lors des appels récursifs.
#
# Retour :
#   0  Succès
#   1  Échec (extension introuvable, erreur réseau, etc.)
# =============================================================================
fetch_extension() {
    local ext_id="$1"
    local indent="${2:-}"

    # ── Déduplication ────────────────────────────────────────────────────────
    # Si cette extension a déjà été traitée (directement ou comme dépendance
    # d'une autre), on passe sans rien faire pour éviter les doublons.
    if [[ "::${SEEN_IDS}::" == *"::${ext_id}::"* ]]; then
        return 0
    fi
    SEEN_IDS="${SEEN_IDS}::${ext_id}"

    # L'identifiant d'une extension VS Code est toujours "editeur.nom".
    # L'API Marketplace attend ces deux parties séparément.
    local publisher="${ext_id%%.*}"  # Tout avant le premier point
    local ext_name="${ext_id#*.}"    # Tout après le premier point

    printf "%s  ↓ %-52s " "$indent" "$ext_id"

    # ── Étape 1 : obtenir la dernière version ─────────────────────────────────
    # On interroge l'API JSON du Marketplace. La valeur flags=914 est une
    # combinaison de champs à inclure dans la réponse (versions, statistiques,
    # propriétés) — c'est la valeur standard utilisée par VS Code lui-même.
    local version
    version=$(
        curl "${CURL_OPTS[@]}" \
            --request POST \
            "${MARKETPLACE_API}/extensionquery?api-version=3.0-preview.1" \
            --header "Content-Type: application/json" \
            --header "Accept: application/json;api-version=3.0-preview.1" \
            --data "{
                \"filters\": [{\"criteria\": [{\"filterType\": 7, \"value\": \"${ext_id}\"}]}],
                \"flags\": 914
            }" \
        | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data['results'][0]['extensions'][0]['versions'][0]['version'])
except (KeyError, IndexError, ValueError):
    sys.exit(1)
" 2>/dev/null
    ) || {
        echo "INTROUVABLE"
        log_err "Impossible de récupérer '${ext_id}'. Vérifiez l'identifiant ou le proxy."
        return 1
    }

    # ── Étape 2 : télécharger le fichier .vsix ────────────────────────────────
    # Un .vsix est une archive ZIP contenant le code et les métadonnées de
    # l'extension. C'est le format utilisé par VS Code pour les installations
    # hors-ligne.
    local vsix_file="${OUTPUT_DIR}/${ext_id}-${version}.vsix"

    curl "${CURL_OPTS[@]}" \
        --output "${vsix_file}" \
        "${MARKETPLACE_API}/publishers/${publisher}/vsextensions/${ext_name}/${version}/vspackage" \
    || {
        echo ""
        log_err "Échec du téléchargement de '${ext_id}' v${version}."
        rm -f "${vsix_file}"
        return 1
    }

    echo "v${version}"

    # ── Étape 3 : résoudre les dépendances ────────────────────────────────────
    # Certaines extensions déclarent des dépendances obligatoires envers
    # d'autres extensions (champ "extensionDependencies" dans package.json).
    # On les lit directement depuis le .vsix (qui est un ZIP) pour les
    # télécharger automatiquement sans avoir à les lister manuellement.
    local deps
    deps=$(
        unzip -p "${vsix_file}" "extension/package.json" 2>/dev/null \
        | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for dep in data.get('extensionDependencies', []):
        print(dep)
except Exception:
    pass
" 2>/dev/null || true
    )

    if [[ -n "$deps" ]]; then
        while IFS= read -r dep; do
            [[ -z "$dep" ]] && continue
            printf "%s      └─ dépendance : %s\n" "$indent" "$dep"
            fetch_extension "$dep" "${indent}      "
        done <<< "$deps"
    fi
}


# =============================================================================
# POINT D'ENTRÉE
# =============================================================================

check_prerequisites

# Largeur intérieure du cadre (nombre de caractères entre les deux ║).
# Doit correspondre au nombre de ═ dans les lignes horizontales ci-dessous.
readonly BOX_INNER=68

# Affiche une ligne de contenu dans le cadre avec alignement automatique
# du bord droit. Calcule le padding selon la longueur réelle du contenu,
# ce qui évite tout décalage si la valeur est plus courte ou plus longue
# que prévu (ex : URL de proxy longue).
#
# Usage : box_line "  Label : valeur"
box_line() {
    local content="$1"
    local pad=$(( BOX_INNER - ${#content} ))
    [[ $pad -lt 0 ]] && pad=0
    printf "║%s%*s║\n" "$content" "$pad" ""
}

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║         Téléchargement des extensions VS Code (.vsix)              ║"
echo "╠════════════════════════════════════════════════════════════════════╣"
box_line "  Proxy   : ${PROXY:-aucun}"
box_line "  Dossier : ${OUTPUT_DIR}/"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""


# =============================================================================
# LISTE DES EXTENSIONS
#
# Pour ajouter une extension :
#   1. Trouvez son identifiant sur https://marketplace.visualstudio.com
#      (visible dans l'URL ou dans la section "More Info" de la page).
#   2. Ajoutez une ligne : fetch_extension "editeur.nom" || ERRORS+=("editeur.nom")
#
# Le "|| ERRORS+=(...)" permet au script de continuer même si une extension
# échoue, et d'en garder trace pour le récapitulatif final.
# =============================================================================

# ── Python ────────────────────────────────────────────────────────────────────
fetch_extension "ms-python.python"              || ERRORS+=("ms-python.python")
fetch_extension "ms-python.debugpy"             || ERRORS+=("ms-python.debugpy")
fetch_extension "ms-python.vscode-pylance"      || ERRORS+=("ms-python.vscode-pylance")
fetch_extension "ms-python.vscode-python-envs"  || ERRORS+=("ms-python.vscode-python-envs")
fetch_extension "charliermarsh.ruff"            || ERRORS+=("charliermarsh.ruff")

# ── Formats de données ────────────────────────────────────────────────────────
fetch_extension "tamasfe.even-better-toml"      || ERRORS+=("tamasfe.even-better-toml")
fetch_extension "ZainChen.json"                 || ERRORS+=("ZainChen.json")
fetch_extension "redhat.vscode-yaml"            || ERRORS+=("redhat.vscode-yaml")
fetch_extension "mechatroner.rainbow-csv"       || ERRORS+=("mechatroner.rainbow-csv")

# ── Interface ─────────────────────────────────────────────────────────────────
fetch_extension "PKief.material-icon-theme"     || ERRORS+=("PKief.material-icon-theme")
fetch_extension "PKief.material-product-icons"  || ERRORS+=("PKief.material-product-icons")
fetch_extension "Catppuccin.catppuccin-vsc"     || ERRORS+=("Catppuccin.catppuccin-vsc")

# ── IA — GitHub Copilot (abonnement GitHub requis) ───────────────────────────
fetch_extension "GitHub.copilot"                || ERRORS+=("GitHub.copilot")
fetch_extension "GitHub.copilot-chat"           || ERRORS+=("GitHub.copilot-chat")

# ── Documentation ─────────────────────────────────────────────────────────────
fetch_extension "yzhang.markdown-all-in-one"    || ERRORS+=("yzhang.markdown-all-in-one")

# ── IBM Application Delivery Foundation for z/OS (ADFz) ──────────────────────
# Ce pack est une méta-extension (pas de code, uniquement des métadonnées).
# Pour une installation hors-ligne, chaque membre doit être téléchargé
# individuellement — c'est ce que font les lignes ci-dessous.
#
# Attention : les extensions suivantes nécessitent une licence IBM à l'exécution :
#   zopendebug, compiledcodecoverage, zfilemanager, zfaultanalyzer, apa-extension
fetch_extension "IBM.zcommoncomponent"              || ERRORS+=("IBM.zcommoncomponent")
fetch_extension "IBM.zopeneditor"                   || ERRORS+=("IBM.zopeneditor")
fetch_extension "IBM.zopendebug"                    || ERRORS+=("IBM.zopendebug")
fetch_extension "IBM.compiledcodecoverage"          || ERRORS+=("IBM.compiledcodecoverage")
fetch_extension "Zowe.vscode-extension-for-zowe"    || ERRORS+=("Zowe.vscode-extension-for-zowe")
fetch_extension "Zowe.cics-extension-for-zowe"      || ERRORS+=("Zowe.cics-extension-for-zowe")
fetch_extension "IBM.zfilemanager"                  || ERRORS+=("IBM.zfilemanager")
fetch_extension "IBM.zfaultanalyzer"                || ERRORS+=("IBM.zfaultanalyzer")
fetch_extension "IBM.apa-extension"                 || ERRORS+=("IBM.apa-extension")
fetch_extension "IBM.db2forzosdeveloperextension"   || ERRORS+=("IBM.db2forzosdeveloperextension")


# =============================================================================
# RÉCAPITULATIF
# =============================================================================

vsix_count=$(find "$OUTPUT_DIR" -maxdepth 1 -name "*.vsix" | wc -l | tr -d ' ')

echo ""
echo "────────────────────────────────────────────────────────────────────"

if [[ ${#ERRORS[@]} -eq 0 ]]; then
    log_ok "${vsix_count} extension(s) téléchargée(s) dans ${OUTPUT_DIR}/"
else
    log_info "${vsix_count} extension(s) téléchargée(s) dans ${OUTPUT_DIR}/"
    echo ""
    log_err "${#ERRORS[@]} extension(s) en échec :"
    for ext in "${ERRORS[@]}"; do
        echo "       • ${ext}"
    done
    echo ""
    echo "  Causes possibles :"
    echo "    • Identifiant incorrect (vérifiez sur marketplace.visualstudio.com)"
    echo "    • Pas de connexion Internet depuis cette machine"
    echo "    • Proxy requis → relancez avec : --proxy http://hote:port"
    echo ""
    exit 1
fi

echo "────────────────────────────────────────────────────────────────────"
echo ""
