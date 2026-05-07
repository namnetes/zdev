# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**zdev** is a containerized IBM z/OS mainframe development environment: VS Code in the browser (`zdev-ide`) plus a FastAPI backend (`zdev-api`), running on Linux (AMD64) and macOS Apple Silicon (ARM64) with enterprise proxy support.

## Commands

### Build & Run

```bash
cp .env.example .env          # Configure IDE_PASSWORD, TZ, HTTP_PROXY
make setup-host               # Create ~/zdev/ volume structure (first install)
make fetch-ext                # Download .vsix extensions from Marketplace
make build                    # Build both Docker images
make up                       # Start containers (detached)
make down                     # Stop containers
make logs                     # Stream logs from both services
make clean                    # Remove local images
```

Access: VS Code at `http://localhost:8443`, API at `http://localhost:5000`.

### API Development

```bash
cd api
uv sync                                                    # Install deps into .venv/
uv run uvicorn zapi.main:app --reload --host 0.0.0.0 --port 5000
uv run ruff check . --fix && uv run ruff format .
uv run pytest                                              # Run tests
uv add <package>                                           # Add dependency (updates uv.lock)
```

Always use `uv`, never `pip` directly.

## Architecture

### Services

| Service | Port | Base | Role |
|---------|------|------|------|
| `zdev-ide` | 8443 | Debian | code-server + IBM mainframe tools (Zowe CLI v3, Z Open Editor, Db2/CICS explorers) + Java 21, Node.js, Python |
| `zdev-api` | 5000 | Python 3.14-slim | FastAPI backend (MVP: single `GET /` status endpoint) |

### Critical Pattern: Extension Synchronization

Docker volumes are mounted *after* image layers, so extensions installed into code-server's default path would be masked by the volume. The workaround:

1. Extensions are staged in `/opt/code-server/extensions/` during image build (not masked).
2. `ide/entrypoint.sh` syncs staged extensions to the volume (`~/zdev/editor/extensions/`), rewrites `extensions.json` paths, and clears `.obsolete`.
3. `settings.json` is copied **only on first start** (if absent) — user UI customizations persist across restarts.
4. Extensions the user installs go directly to the volume and persist independently.

### Data Persistence

All user data lives in `~/zdev/` on the host and survives container recreation:

```
~/zdev/projects/          → /home/zdev/workspace
~/zdev/zowe/              → /home/zdev/.zowe
~/zdev/editor/settings/   → VS Code settings
~/zdev/editor/extensions/ → VS Code extensions (synced by entrypoint)
~/zdev/cache/npm|pip/     → package caches
~/.ssh                    → SSH keys (read-only)
```

### Proxy Support

Pass `HTTP_PROXY` via environment or `make build PROXY=http://...`. The proxy is used only at build time and stripped from the final image (safe for air-gapped distribution).

### Copilot Instructions

`ide/copilot/instructions/` contains two instruction files applied automatically by VS Code Copilot based on file glob patterns:
- `mainframe.instructions.md` — COBOL, JCL, z/OS, Db2, CICS
- `scripting.instructions.md` — Python, Bash, TypeScript

### API Future Design

The API (`zdev-api`) will expose functions callable from the VS Code terminal in the browser. The IDE terminal can reach the API via `http://zdev-api:5000/` (Docker Compose default network). A `zdev` shell function is pre-configured in `~/zdev/.zshrc` (written by `setup_host.sh`):

```bash
zdev() { curl -s "http://zdev-api:5000${1:-/}"; }
# Usage: zdev /datasets, zdev /jobs/submit
```

Future endpoints should be designed as simple HTTP calls usable with `curl`. Authentication should be lightweight (API key in header) given the local/LAN deployment model.

## Key Files

```
Makefile                        # Single build/orchestration entry point
docker-compose.yml              # Service definitions and volume mounts
.env.example                    # Config template (IDE_PASSWORD, TZ, HTTP_PROXY)
ide/
  Dockerfile                    # Multi-platform (AMD64/ARM64)
  entrypoint.sh                 # Extension sync + startup logic
  fetch_extensions.sh           # Download .vsix files from Marketplace
  setup_host.sh                 # Create ~/zdev/ directory structure
  copilot/instructions/         # GitHub Copilot instruction files
api/
  src/zapi/main.py              # FastAPI application
  pyproject.toml                # Dependencies and Ruff config
  uv.lock                       # Must be committed — ensures reproducible builds
```

## Design Decisions

- **`uv` over pip/poetry**: faster builds, simpler lock files, better for Docker layer caching.
- **Extensions in `/opt/`**: solves Docker volume masking without any compromise on persistence.
- **Makefile as entry point**: language-agnostic, handles platform detection (`uname -m`) automatically.
- **Offline `.vsix` install**: supports corporate firewalls; `make fetch-ext` downloads ahead of time.
- **`uv.lock` committed**: reproducible builds across all environments — never `.gitignore` it.
