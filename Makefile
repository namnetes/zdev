# ─────────────────────────────────────────────────────────────────────────────
# zdev — interface de build et d'exploitation
#
# Utilisation :
#   make build          Build les deux images (IDE + API)
#   make up             Démarre les conteneurs
#   make down           Arrête les conteneurs
#   make logs           Affiche les logs en temps réel
#   make setup-host     Crée ~/zdev/ sur l'hôte (première installation)
#   make fetch-ext      Télécharge les .vsix depuis le Marketplace
#   make clean          Supprime les images locales
#   make help           Affiche cette aide
#
# Variables d'environnement :
#   HTTP_PROXY          Proxy HTTP (lu depuis le shell ; ex: http://10.0.0.1:3128)
#   PROXY               Surcharge manuelle du proxy (ex: make build PROXY=http://...)
# ─────────────────────────────────────────────────────────────────────────────

PORT     ?= 8001
PID_FILE := .mkdocs.pid

.DEFAULT_GOAL := help

# Détection automatique de la plateforme cible
ARCH := $(shell uname -m)
ifeq ($(ARCH),x86_64)
  PLATFORM := linux/amd64
else
  PLATFORM := linux/arm64
endif

# Proxy : priorité à PROXY (argument make), puis HTTP_PROXY (shell)
PROXY ?= $(HTTP_PROXY)

# Arguments de build pour l'IDE
IDE_BUILD_ARGS := --platform $(PLATFORM)
ifneq ($(strip $(PROXY)),)
  IDE_BUILD_ARGS += --build-arg HTTP_PROXY=$(PROXY) --build-arg HTTPS_PROXY=$(PROXY)
endif

.PHONY: build build-ide build-api up down logs setup-host fetch-ext clean \
        docs docs-start docs-stop docs-build help

build: build-ide build-api  ## Build les deux images Docker

build-ide:                   ## Build l'image IDE (code-server, multi-plateforme)
	docker build $(IDE_BUILD_ARGS) \
		-f ide/Dockerfile \
		-t zdev-ide:latest \
		ide/

build-api:                   ## Build l'image API (FastAPI)
	docker build \
		-f api/Dockerfile \
		-t zdev-api:latest \
		api/

up:                          ## Démarre les conteneurs (détaché)
	docker compose up -d

down:                        ## Arrête et supprime les conteneurs
	docker compose down

logs:                        ## Affiche les logs en temps réel
	docker compose logs -f

setup-host:                  ## Crée ~/zdev/ sur l'hôte (première installation)
	./ide/setup_host.sh

fetch-ext:                   ## Télécharge les .vsix (proxy auto depuis HTTP_PROXY)
	cd ide && ./fetch_extensions.sh $(if $(strip $(PROXY)),--proxy $(PROXY),)

clean:                       ## Supprime les images Docker locales
	docker rmi -f zdev-ide:latest zdev-api:latest 2>/dev/null || true

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
