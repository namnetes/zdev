FROM python:3.14-slim

WORKDIR /app

# Installation de uv depuis l'image officielle (pas de pip install uv)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Couche dépendances (invalidée uniquement si pyproject.toml ou uv.lock changent)
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

# Couche source (README.md requis par hatchling pour le build du package)
COPY README.md ./
COPY src/ ./src/
RUN uv sync --frozen --no-dev

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/')"

CMD ["uv", "run", "uvicorn", "zapi.main:app", "--host", "0.0.0.0", "--port", "5000"]
