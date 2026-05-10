# Makefile — ligne par ligne

Le `Makefile` est le **point d'entrée unique** du projet. Toutes les opérations
(build, démarrage, téléchargement des extensions, documentation) sont accessibles
via `make <commande>`.

**Fichier :** `Makefile`
**Utilisé par :** tout le monde, dès la première installation

---

## Qu'est-ce que Make ?

`make` est un outil de construction universel, présent sur tous les systèmes
Linux et macOS. Il lit un `Makefile` qui définit des **cibles** (targets) et
les commandes pour les atteindre.

```bash
make         # Exécute la cible par défaut (ici : help)
make build   # Exécute la cible "build"
make up      # Exécute la cible "up"
```

L'avantage de Make : une interface cohérente quelle que soit la technologie
sous-jacente (Docker, Python, Node.js…). `make build` fonctionne qu'on soit
sur Linux x86_64 ou macOS ARM.

---

## En-tête et commentaires

```makefile
# ─────────────────────────────────────────────────────────────────────────────
# zdev — interface de build et d'exploitation
#
# Utilisation :
#   make build          Build les deux images (IDE + API)
#   make up             Démarre les conteneurs
#   ...
# ─────────────────────────────────────────────────────────────────────────────
```

Ces commentaires servent aussi à la cible `help` (voir plus bas) qui les
affiche en couleur dans le terminal.

---

## Variables globales

```makefile
PORT     ?= 8001
PID_FILE := .mkdocs.pid
```

`?=` — Assigne la valeur uniquement si la variable n'est pas déjà définie.
Permet de la surcharger : `make docs PORT=9000`.

`:=` — Assignation immédiate (évaluée au moment de la lecture du Makefile).

---

## Cible par défaut

```makefile
.DEFAULT_GOAL := help
```

Quand on tape `make` sans argument, Make exécute la cible `help` (voir bas
du Makefile). Sans cette ligne, Make exécuterait la première cible définie.

---

## Détection automatique de la plateforme

```makefile
ARCH := $(shell uname -m)
ifeq ($(ARCH),x86_64)
  PLATFORM := linux/amd64
else
  PLATFORM := linux/arm64
endif
```

`$(shell uname -m)` — Exécute la commande `uname -m` et capture sa sortie.
`uname -m` retourne :
- `x86_64` sur Linux 64 bits classique
- `aarch64` sur macOS Apple Silicon et ARM Linux

Le résultat est utilisé comme argument `--platform` pour `docker build`,
ce qui garantit que l'image construite correspond à l'architecture de la
machine.

---

## Gestion du proxy

```makefile
PROXY ?= $(HTTP_PROXY)

IDE_BUILD_ARGS := --platform $(PLATFORM)
ifneq ($(strip $(PROXY)),)
  IDE_BUILD_ARGS += --build-arg HTTP_PROXY=$(PROXY) --build-arg HTTPS_PROXY=$(PROXY)
endif
```

**Priorité du proxy :**
1. `PROXY=http://…` passé comme argument Make → priorité maximale
2. Variable d'environnement `HTTP_PROXY` → lu si `PROXY` n'est pas défini
3. Pas de proxy → les `--build-arg` ne sont pas ajoutés

`$(strip …)` — Supprime les espaces en début et fin de chaîne. Nécessaire
car une variable définie mais vide (`PROXY=`) ne doit pas activer le proxy.

`ifneq (val,)` — "si val est différent de vide" → condition Make.

---

## Déclaration des cibles `.PHONY`

```makefile
.PHONY: build build-ide build-api up down logs setup-host fetch-ext clean \
        docs docs-start docs-stop docs-build help
```

`.PHONY` indique à Make que ces cibles ne correspondent pas à des fichiers
sur le disque. Sans cette déclaration, si un fichier nommé `build` existait
dans le dossier, Make refuserait d'exécuter la cible `build` (il penserait
que la "cible" est déjà à jour).

---

## Cibles Docker

### build

```makefile
build: build-ide build-api  ## Build les deux images Docker
```

`build` dépend de `build-ide` et `build-api` : Make les exécute dans l'ordre.
Le `##` après la description est utilisé par la cible `help` pour l'affichage.

### build-ide

```makefile
build-ide:                   ## Build l'image IDE (code-server, multi-plateforme)
	docker build $(IDE_BUILD_ARGS) \
		-f ide/Dockerfile \
		-t zdev-ide:latest \
		ide/
```

`$(IDE_BUILD_ARGS)` — Contient `--platform linux/amd64` (ou arm64) et
éventuellement les arguments proxy.

`-f ide/Dockerfile` — Spécifie le Dockerfile à utiliser.

`-t zdev-ide:latest` — Nomme et tague l'image produite. `latest` est le
tag par défaut.

`ide/` — Le contexte de build : Docker peut accéder à tous les fichiers
de ce dossier pendant le build.

!!! note "Indentation avec Tab"
    Dans un Makefile, les commandes d'une cible **doivent** commencer par
    une tabulation (Tab, pas des espaces). C'est une règle historique de Make.

### up / down / logs

```makefile
up:                          ## Démarre les conteneurs (détaché)
	docker compose up -d

down:                        ## Arrête et supprime les conteneurs
	docker compose down

logs:                        ## Affiche les logs en temps réel
	docker compose logs -f
```

`-d` (detached) — Démarre les conteneurs en arrière-plan. Sans ce flag,
Make resterait bloqué à afficher les logs.

`-f` (follow) — Affiche les logs en continu, comme `tail -f`.
`Ctrl+C` pour quitter.

### setup-host et fetch-ext

```makefile
setup-host:                  ## Crée ~/zdev/ sur l'hôte (première installation)
	./ide/setup_host.sh

fetch-ext:                   ## Télécharge les .vsix (proxy auto depuis HTTP_PROXY)
	cd ide && ./fetch_extensions.sh $(if $(strip $(PROXY)),--proxy $(PROXY),)
```

`$(if cond,val_vrai,val_faux)` — Fonction conditionnelle de Make.
Si `$(strip $(PROXY))` n'est pas vide, ajoute `--proxy $(PROXY)`,
sinon n'ajoute rien.

`cd ide && ./fetch_extensions.sh` — Le `&&` garantit que `fetch_extensions.sh`
est exécuté depuis le dossier `ide/`. Le script utilise des chemins relatifs
et suppose d'y être exécuté.

### clean

```makefile
clean:                       ## Supprime les images Docker locales
	docker rmi -f zdev-ide:latest zdev-api:latest 2>/dev/null || true
```

`-f` — Force la suppression même si le conteneur tourne encore.

`2>/dev/null || true` — Le `rmi` échoue si les images n'existent pas.
`|| true` ignore cet échec (retourne toujours 0).

---

## Cibles MkDocs

```makefile
docs:                        ## Démarre MkDocs en mode live-reload (port $(PORT))
	uv run mkdocs serve --dev-addr 0.0.0.0:$(PORT)

docs-start:                  ## Démarre MkDocs en arrière-plan
	uv run mkdocs serve --dev-addr 0.0.0.0:$(PORT) & echo $$! > $(PID_FILE)

docs-stop:                   ## Arrête le serveur MkDocs en arrière-plan
	@if [ -f $(PID_FILE) ]; then \
		kill $$(cat $(PID_FILE)) && rm $(PID_FILE); \
	else \
		echo "No MkDocs server running ($(PID_FILE) not found)"; \
	fi

docs-build:                  ## Génère le site statique dans site/
	uv run mkdocs build
```

`uv run mkdocs` — Exécute MkDocs dans l'environnement virtuel géré par `uv`
(dépendances définies dans le `pyproject.toml` de la racine).

`--dev-addr 0.0.0.0:$(PORT)` — Écoute sur toutes les interfaces réseau,
pas seulement `localhost`. Permet d'accéder depuis un autre appareil du réseau.

`& echo $$! > $(PID_FILE)` — Lance MkDocs en arrière-plan (`&`) et sauvegarde
son PID (numéro de processus) dans `.mkdocs.pid`. `$$!` est le PID du
dernier processus lancé en arrière-plan. Dans un Makefile, `$$` s'écrit
avec deux `$` car Make consomme le premier.

---

## Cible help

```makefile
help:                        ## Affiche cette aide
	@echo ""
	@echo "  zdev — commandes disponibles"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "  Plateforme détectée : $(PLATFORM)"
	@echo "  Proxy               : $(if $(strip $(PROXY)),$(PROXY),aucun)"
	@echo ""
```

`@` devant une commande — Empêche Make d'afficher la commande elle-même
(n'affiche que la sortie). Sans `@`, Make affiche `echo ""` avant le résultat.

La commande `grep | awk` extrait automatiquement toutes les lignes du Makefile
qui contiennent `## Description` et les formate en colonnes colorées.

Résultat de `make help` :

```
  zdev — commandes disponibles

  build              Build les deux images Docker
  build-ide          Build l'image IDE (code-server, multi-plateforme)
  build-api          Build l'image API (FastAPI)
  up                 Démarre les conteneurs (détaché)
  down               Arrête et supprime les conteneurs
  …

  Plateforme détectée : linux/amd64
  Proxy               : aucun
```

---

## Résumé des commandes

| Commande | Usage typique | Fréquence |
|----------|---------------|-----------|
| `make setup-host` | Première installation | Une fois |
| `make fetch-ext` | Avant chaque `make build` | Occasionnel |
| `make build` | Construction des images | Après changement du Dockerfile |
| `make build-ide` | Rebuild uniquement l'IDE | Après changement d'extension |
| `make build-api` | Rebuild uniquement l'API | Après changement du code Python |
| `make up` | Démarrer les conteneurs | Quotidien |
| `make down` | Arrêter les conteneurs | Quotidien |
| `make logs` | Diagnostiquer un problème | À la demande |
| `make clean` | Libérer de l'espace disque | Occasionnel |
| `make docs` | Prévisualiser la documentation | En développement |
