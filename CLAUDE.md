# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

A containerized mainframe development environment with two components:

- **`ide/`** — Docker image running [code-server](https://github.com/coder/code-server) (VS Code in the browser), pre-loaded with IBM mainframe tools (Zowe CLI, IBM Z Open Editor), Python tooling, and ~35 VS Code extensions.
- **`api/`** — FastAPI backend (Python 3.14) served alongside the IDE.

The IDE is **ephemeral by design**: all user data persists via host-mounted volumes under `~/zdev/`. Destroying the container loses nothing.

Designed to run on **macOS Apple Silicon (ARM64) at work behind a proxy** and on **Linux Ubuntu 24.04 (AMD64) at home without proxy** — the same Dockerfile and Makefile handle both automatically.

---

## Common commands

```bash
make help           # list all available commands
make build          # build both images (auto-detects arch, proxy from HTTP_PROXY)
make up             # docker compose up -d
make down           # docker compose down
make logs           # docker compose logs -f
make setup-host     # one-time: creates ~/zdev/ on the host
make fetch-ext      # download .vsix files from the Marketplace
```

Override proxy manually: `make build PROXY=http://10.0.0.1:3128`

### Python / api (local dev)

```bash
cd api
uv sync                      # install / sync dependencies
uv run uvicorn zapi.main:app --reload --host 0.0.0.0 --port 5000
uv run ruff check . --fix
uv run pytest
uv add <package>
```

**Always use `uv`. Never `pip` or `poetry`.**

---

## Repository structure

```
zdev/
├── Makefile                              ← build / run / setup (single entry point)
├── docker-compose.yml                    ← reads vars from .env
├── .env.example                          ← template: HTTP_PROXY, TZ, IDE_PASSWORD
│
├── ide/                                  ← container code-server
│   ├── Dockerfile                        ← one file, multi-platform (AMD64 + ARM64)
│   ├── entrypoint.sh                     ← applies config after volume mounts
│   ├── ruff.toml                         ← Python linter config (inside container)
│   ├── settings.json                     ← VS Code user settings (inside container)
│   ├── setup_host.sh                     ← creates ~/zdev/ on the host
│   ├── fetch_extensions.sh               ← downloads .vsix from Marketplace
│   ├── copilot/
│   │   ├── instructions.md               ← Copilot global instructions
│   │   └── instructions/
│   │       ├── mainframe.instructions.md ← COBOL, JCL, z/OS
│   │       └── open.instructions.md      ← Python, Bash, TypeScript
│   ├── extensions/                       ← pre-downloaded .vsix (gitignored, .gitkeep)
│   └── zowe/                             ← Zowe CLI offline archives
│
└── api/                                  ← container FastAPI
    ├── Dockerfile
    ├── pyproject.toml                    ← hatchling build, deps, dev deps
    ├── .python-version                   ← Python 3.14
    ├── uv.lock
    └── src/
        └── zapi/
            ├── __init__.py
            └── main.py
```

---

## Architecture

```
docker-compose.yml
├── zdev-ide  context: ide/   port 8443  ← code-server + mainframe tools
│             ~/zdev/projects           → /home/zdev/workspace
│             ~/zdev/zowe               → /home/zdev/.zowe
│             ~/zdev/editor/settings   → .../code-server/User
│             ~/zdev/editor/extensions → .../code-server/extensions
│             ~/zdev/cache/{npm,pip}   → /home/zdev/.{npm,.cache/pip}
│             ~/zdev/.{zshrc,gitconfig} → /home/zdev/…
│             ~/.ssh                   → /home/zdev/.ssh  :ro
└── zdev-api  context: api/   port 5000  ← FastAPI (uvicorn)
```

**Proxy handling:** `HTTP_PROXY` / `HTTPS_PROXY` are passed as `--build-arg` at build time and **cleared** from the final image (step 12 of the Dockerfile). The running container never carries proxy settings.

**Config files at runtime:** `ruff.toml`, `settings.json`, and `copilot/` are copied to `/tmp/` in the image. `entrypoint.sh` copies them to `~/` at each container start, *after* volumes are mounted — otherwise the volume mounts would hide them.

**Offline extensions:** `.vsix` files are baked into the image from `ide/extensions/`, avoiding Marketplace access in restricted networks.

---

## Python standards (api and scripts)

- **Type hints** required on all function signatures (parameters and return type).
- **f-strings** only — no `%` formatting, no `.format()`.
- **`pathlib.Path`** for all filesystem paths — never `os.path`.
- **`logging`** for production output; `print()` only in one-off scripts or CLI entry points.
- **Specific exceptions** only — never bare `except:` or `except Exception:`.
- Line length: **88 characters** (Ruff/Black style).

### Docstrings

Every `.py` file requires a **module-level docstring** summarising purpose, inputs, outputs, and key assumptions. Target a reader who knows Python basics but nothing about the business domain or z/OS.

Public functions use **Google-style docstrings** with `Args`, `Returns` (unless `None`), and `Raises` sections.

### Naming

| Element | Convention |
|---|---|
| Variable / function | `snake_case` |
| Class | `PascalCase` |
| Module-level constant | `UPPER_SNAKE_CASE` |
| Private helper | `_leading_underscore` |

---

## Bash standards

- Start every script with `set -euo pipefail`.
- Line length: **80 characters**; use `\` for continuation.

---

## TypeScript (VS Code extension development)

TypeScript is mandatory — never plain JavaScript. Use Node.js + `npm` (not `uv`).

Key rules:
- Enable `strict` mode in `tsconfig.json` (non-negotiable).
- No `any` type — use `unknown` + type guards.
- Every `Disposable` must be pushed to `context.subscriptions`.
- Webviews must define a strict CSP — never `'unsafe-inline'` in `script-src`.
- Use `vscode.workspace.fs` for file I/O (works in remote/virtual FS).
- Line length: **120 characters**.

Full conventions: `ide/copilot/instructions/open.instructions.md`

---

## Mainframe (COBOL / JCL / z/OS)

Full IBM Enterprise COBOL 6.5, JCL, VSAM, Db2, and CICS standards: `ide/copilot/instructions/mainframe.instructions.md`
