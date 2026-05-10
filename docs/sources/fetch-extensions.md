# ide/fetch_extensions.sh — ligne par ligne

`fetch_extensions.sh` télécharge les extensions VS Code depuis le Marketplace
Microsoft et les stocke localement en fichiers `.vsix`. Ces fichiers sont ensuite
inclus dans l'image Docker lors du build.

**Fichier :** `ide/fetch_extensions.sh`
**Déclenché par :** `make fetch-ext` (sur la machine hôte, avant le build)
**Résultat :** des fichiers `*.vsix` dans `ide/extensions/`

---

## Pourquoi ce script existe

```
Problème : le conteneur ne peut pas accéder à Internet
           (réseau d'entreprise restreint).

Solution :
  1. Télécharger les .vsix sur la machine hôte (qui a accès à Internet)
  2. Les intégrer dans l'image Docker lors du build
  3. Les installer depuis les fichiers locaux → zéro accès réseau dans le conteneur
```

Cette approche est appelée **installation hors-ligne** (offline install).

---

## Utilisation

```bash
# Utilisation simple (proxy lu depuis HTTP_PROXY)
make fetch-ext

# Avec proxy explicite
make fetch-ext PROXY=http://mon-proxy:3128

# Appel direct avec options
cd ide
./fetch_extensions.sh --proxy http://mon-proxy:3128
./fetch_extensions.sh --no-proxy
./fetch_extensions.sh --help
```

---

## En-tête du script

```bash
#!/usr/bin/env bash
set -euo pipefail
```

`#!/usr/bin/env bash` — Différent de `#!/bin/bash` : cherche `bash` dans le
PATH plutôt qu'à un chemin fixe. Plus portable (macOS et Linux ont bash à des
endroits différents).

---

## Constantes

```bash
readonly OUTPUT_DIR="extensions"
readonly MARKETPLACE_API="https://marketplace.visualstudio.com/_apis/public/gallery"
```

`readonly` — Déclare une variable en lecture seule. Toute tentative de
modification ultérieure cause une erreur. C'est une bonne pratique pour les
constantes.

`OUTPUT_DIR` — Chemin relatif par rapport au dossier `ide/` depuis lequel
le script est exécuté.

`MARKETPLACE_API` — L'URL de base de l'API publique du Marketplace Microsoft.
Cette API est accessible sans authentification et retourne les métadonnées
des extensions (version, dépendances, URL de téléchargement).

---

## Variables d'état

```bash
PROXY="${HTTP_PROXY:-}"
declare -a ERRORS=()
SEEN_IDS=""
```

`${HTTP_PROXY:-}` — Lit la variable d'environnement `HTTP_PROXY`. Si elle
n'est pas définie, utilise une chaîne vide (pas d'erreur). Le `:-` est un
opérateur de substitution bash.

`declare -a ERRORS=()` — Déclare un tableau vide. Les extensions qui échouent
au téléchargement y sont ajoutées pour le récapitulatif final.

`SEEN_IDS` — Chaîne qui accumule les IDs des extensions déjà traitées.
Format : `"::editeur1.nom1::editeur2.nom2::"`. La double-colonne permet
une recherche exacte (évite les faux positifs pour des IDs proches).

---

## Fonctions utilitaires

```bash
log_info() { echo -e "\033[0;34mℹ\033[0m  $*"; }
log_ok()   { echo -e "\033[0;32m✓\033[0m  $*"; }
log_err()  { echo -e "\033[0;31m✗\033[0m  $*" >&2; }
```

`\033[0;34m` — Séquence ANSI pour colorier le texte en bleu.
`\033[0m` — Réinitialise la couleur.

`$*` — Tous les arguments de la fonction (équivalent à `$@` mais comme une seule chaîne).

`>&2` — Redirige vers `stderr` (sortie d'erreur standard). Séparation des
messages d'erreur des messages normaux — utile si la sortie est redirigée.

---

## Configuration de curl

```bash
CURL_OPTS=(-fsSL --compressed)
if [[ -n "$PROXY" ]]; then
    CURL_OPTS+=(--proxy "$PROXY")
fi
```

Le tableau `CURL_OPTS` regroupe les options curl communes à tous les appels :

| Option | Signification |
|--------|---------------|
| `-f` | Retourne une erreur (exit code 22) si HTTP ≥ 400 |
| `-s` | Mode silencieux (pas d'indicateur de progression) |
| `-S` | Affiche quand même les erreurs en mode silencieux |
| `-L` | Suit les redirections HTTP (301, 302…) |
| `--compressed` | Accepte les réponses gzip — réduit la bande passante |

L'utilisation d'un tableau plutôt qu'une chaîne est importante : elle gère
correctement les espaces dans les valeurs (ex. une URL de proxy avec un port).

---

## Fonction principale : `fetch_extension`

C'est la fonction centrale du script. Elle télécharge une extension et
toutes ses dépendances de manière récursive.

### Déduplication

```bash
if [[ "::${SEEN_IDS}::" == *"::${ext_id}::"* ]]; then
    return 0
fi
SEEN_IDS="${SEEN_IDS}::${ext_id}"
```

Si une extension apparaît dans deux listes (directement + comme dépendance
d'une autre), on ne la télécharge qu'une seule fois.

`*"::${ext_id}::"*` — La syntaxe `*...*` dans un `[[` est un glob : vérifie
si la chaîne contient le motif. Les doubles-colons évitent les correspondances
partielles.

### Décomposition de l'identifiant

```bash
local publisher="${ext_id%%.*}"  # Tout avant le premier point
local ext_name="${ext_id#*.}"    # Tout après le premier point
```

L'identifiant d'une extension VS Code est toujours `editeur.nom`.
Exemples : `ms-python.python`, `IBM.zopeneditor`.

`%%.*` — Supprime le suffixe le plus long correspondant `.*` (depuis la fin).
`#*.` — Supprime le préfixe le plus court correspondant `*.` (depuis le début).

### Étape 1 : obtenir la version

```bash
version=$(
    curl "${CURL_OPTS[@]}" \
        --request POST \
        "${MARKETPLACE_API}/extensionquery?api-version=3.0-preview.1" \
        --header "Content-Type: application/json" \
        --data "{
            \"filters\": [{\"criteria\": [{\"filterType\": 7, \"value\": \"${ext_id}\"}]}],
            \"flags\": 914
        }" \
    | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data['results'][0]['extensions'][0]['versions'][0]['version'])
"
)
```

On appelle l'API REST du Marketplace avec une requête POST. Le corps JSON
est la même requête que VS Code lui-même envoie pour chercher des extensions.

`flags=914` — Combinaison de flags qui indique quels champs inclure dans
la réponse (versions, statistiques, propriétés…). C'est la valeur standard
utilisée par VS Code.

`python3 -c "…"` — Petit programme Python inline pour extraire la version
depuis la réponse JSON. Plus robuste que `jq` car Python est toujours installé,
`jq` ne l'est pas forcément.

### Étape 2 : télécharger le .vsix

```bash
local vsix_file="${OUTPUT_DIR}/${ext_id}-${version}.vsix"
curl "${CURL_OPTS[@]}" \
    --output "${vsix_file}" \
    "${MARKETPLACE_API}/publishers/${publisher}/vsextensions/${ext_name}/${version}/vspackage"
```

Un `.vsix` est une archive ZIP contenant le code et les métadonnées d'une
extension VS Code. L'URL de téléchargement suit le format standard de l'API
Marketplace.

### Étape 3 : résoudre les dépendances

```bash
deps=$(
    unzip -p "${vsix_file}" "extension/package.json" 2>/dev/null \
    | python3 -c "
import sys, json
data = json.load(sys.stdin)
for dep in data.get('extensionDependencies', []):
    print(dep)
"
)
```

Chaque `.vsix` contient un fichier `package.json` (comme tout projet Node.js).
Ce fichier peut lister des extensions dont celle-ci dépend (`extensionDependencies`).

`unzip -p` — Extrait un fichier de l'archive directement vers `stdout` (sans
créer de fichier temporaire sur le disque).

Si des dépendances sont trouvées, `fetch_extension` s'appelle elle-même
récursivement pour les télécharger :

```bash
if [[ -n "$deps" ]]; then
    while IFS= read -r dep; do
        [[ -z "$dep" ]] && continue
        fetch_extension "$dep" "${indent}      "
    done <<< "$deps"
fi
```

---

## Liste des extensions téléchargées

```bash
# Shell
fetch_extension "timonwong.shellcheck"
fetch_extension "mkhl.shfmt"

# Python
fetch_extension "ms-python.python"
fetch_extension "ms-python.debugpy"
fetch_extension "ms-python.vscode-pylance"
fetch_extension "ms-python.vscode-python-envs"
fetch_extension "charliermarsh.ruff"

# Formats de données
fetch_extension "tamasfe.even-better-toml"
fetch_extension "ZainChen.json"
fetch_extension "redhat.vscode-yaml"
fetch_extension "redhat.vscode-xml"
fetch_extension "mechatroner.rainbow-csv"

# Interface
fetch_extension "PKief.material-icon-theme"
fetch_extension "PKief.material-product-icons"
fetch_extension "Catppuccin.catppuccin-vsc"

# IA
fetch_extension "GitHub.copilot"
fetch_extension "GitHub.copilot-chat"

# Git et documentation
fetch_extension "mhutchie.git-graph"
fetch_extension "yzhang.markdown-all-in-one"

# IBM z/OS
fetch_extension "IBM.zcommoncomponent"
fetch_extension "IBM.zopeneditor"
fetch_extension "IBM.zopendebug"
fetch_extension "IBM.compiledcodecoverage"
fetch_extension "Zowe.vscode-extension-for-zowe"
fetch_extension "Zowe.cics-extension-for-zowe"
fetch_extension "IBM.zfilemanager"
fetch_extension "IBM.zfaultanalyzer"
fetch_extension "IBM.apa-extension"
fetch_extension "IBM.db2forzosdeveloperextension"
```

Le pattern `|| ERRORS+=("editeur.nom")` après chaque appel permet au script
de **continuer** si une extension échoue, et d'en garder trace pour le
récapitulatif final.

---

## Ajouter une nouvelle extension

1. Trouvez son identifiant sur [marketplace.visualstudio.com](https://marketplace.visualstudio.com)
   (visible dans l'URL ou dans la section "More Info" de la page)
2. Ajoutez une ligne dans la section correspondante :
   ```bash
   fetch_extension "editeur.nom"  || ERRORS+=("editeur.nom")
   ```
3. Relancez `make fetch-ext`
4. Relancez `make build-ide`

---

## Récapitulatif final

À la fin du script, un résumé est affiché :

```
────────────────────────────────────────────────────────────────────
✓  35 extension(s) téléchargée(s) dans extensions/
────────────────────────────────────────────────────────────────────
```

En cas d'erreurs :

```
ℹ  33 extension(s) téléchargée(s) dans extensions/

✗  2 extension(s) en échec :
       • IBM.some-extension
       • GitHub.copilot

  Causes possibles :
    • Identifiant incorrect (vérifiez sur marketplace.visualstudio.com)
    • Pas de connexion Internet depuis cette machine
    • Proxy requis → relancez avec : --proxy http://hote:port
```
