FROM python:3.14-slim

WORKDIR /app

# Copie du binaire uv depuis l'image officielle (méthode recommandée par Astral).
# Évite un `pip install uv` ou un `curl` supplémentaire dans l'image.
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# ── Couche dépendances ────────────────────────────────────────────────────────
# Copiée séparément du code source pour maximiser le cache Docker.
# Cette couche n'est reconstruite que si pyproject.toml ou uv.lock changent,
# ce qui est rare par rapport aux changements du code source.
#
# --frozen        : utilise exactement les versions de uv.lock (pas de résolution)
# --no-dev        : exclut les dépendances de développement (ruff)
# --no-install-project : installe uniquement les dépendances, pas le package zapi lui-même
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

# ── Couche code source ────────────────────────────────────────────────────────
# README.md est requis par hatchling (backend de build Python) pour compiler
# le package zapi. Sans lui, `uv sync` échoue à l'étape d'installation.
COPY README.md ./
COPY src/ ./src/
RUN uv sync --frozen --no-dev

EXPOSE 5000

# Healthcheck Python natif (curl n'est pas dans python:3.14-slim).
# Docker considère le conteneur "healthy" quand l'endpoint / répond HTTP 200.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/')"

# Lance uvicorn (serveur ASGI) sur toutes les interfaces réseau du conteneur.
# zapi.main:app = module zapi.main, variable app (l'objet FastAPI).
CMD ["uv", "run", "uvicorn", "zapi.main:app", "--host", "0.0.0.0", "--port", "5000"]
