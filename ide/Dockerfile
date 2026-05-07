# syntax=docker/dockerfile:1
# Multi-platform : AMD64 (Linux/Ubuntu) et ARM64 (macOS Apple Silicon)
#
# Build args :
#   HTTP_PROXY / HTTPS_PROXY  — proxy entreprise ; vidés en fin de build
#   CODESERVER_VERSION        — version de code-server
#   NODE_VERSION              — version de Node.js LTS

FROM debian:bookworm-slim

ARG CODESERVER_VERSION=4.117.0
ARG NODE_VERSION=24.15.0

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY=localhost,127.0.0.1,10.0.0.0/8

ENV DEBIAN_FRONTEND=noninteractive \
    HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY} \
    http_proxy=${HTTP_PROXY} \
    https_proxy=${HTTPS_PROXY} \
    NO_PROXY=${NO_PROXY} \
    no_proxy=${NO_PROXY}


# ── 1. Paquets système ────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl file fontconfig fonts-dejavu-core \
    git htop iproute2 jq less \
    libcairo2 libgdk-pixbuf-2.0-0 libpangocairo-1.0-0 \
    lsof procps python3 python3-pip python3-venv \
    tree unzip vim wget zip zsh \
    && rm -rf /var/lib/apt/lists/*


# ── 2. Police Fira Code Nerd Font (icônes terminal + code-server) ─────────────
RUN curl -fsSL -o /tmp/FiraCode.zip \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip && \
    unzip /tmp/FiraCode.zip -d /usr/share/fonts/truetype/firacode && \
    rm /tmp/FiraCode.zip && fc-cache -f -v


# ── 3. Java JDK 21 LTS — Eclipse Temurin (arch détectée automatiquement) ──────
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        aarch64) JAVA_ARCH="aarch64" ;; \
        *)        JAVA_ARCH="x64" ;; \
    esac && \
    curl -fsSL -o /tmp/jdk.tar.gz \
        "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.10%2B7/OpenJDK21U-jdk_${JAVA_ARCH}_linux_hotspot_21.0.10_7.tar.gz" && \
    mkdir -p /opt/java && \
    tar -xzf /tmp/jdk.tar.gz -C /opt/java --strip-components=1 && \
    rm /tmp/jdk.tar.gz

ENV JAVA_HOME=/opt/java
ENV PATH="$JAVA_HOME/bin:$PATH"


# ── 4. uv — gestionnaire de paquets Python (binaire statique) ─────────────────
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        aarch64) UV_ARCH="aarch64-unknown-linux-gnu" ;; \
        *)        UV_ARCH="x86_64-unknown-linux-gnu" ;; \
    esac && \
    curl -fsSL -o /tmp/uv.tar.gz \
        "https://github.com/astral-sh/uv/releases/latest/download/uv-${UV_ARCH}.tar.gz" && \
    tar -xzf /tmp/uv.tar.gz -C /usr/local/bin --strip-components=1 && \
    rm /tmp/uv.tar.gz


# ── 5. Node.js LTS (téléchargement direct — contourne les restrictions proxy) ──
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        aarch64) NODE_ARCH="arm64" ;; \
        *)        NODE_ARCH="x64" ;; \
    esac && \
    curl -fsSL -o /tmp/node.tar.gz \
        "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.gz" && \
    tar -xzf /tmp/node.tar.gz -C /usr/local --strip-components=1 && \
    rm /tmp/node.tar.gz && npm cache clean --force


# ── 6. Zowe CLI + plugins ─────────────────────────────────────────────────────
RUN npm install -g @zowe/cli@zowe-v3-lts && \
    zowe plugins install @zowe/cics-for-zowe-cli@zowe-v3-lts && \
    zowe plugins install @zowe/mq-for-zowe-cli@zowe-v3-lts && \
    zowe plugins install @zowe/zos-ftp-for-zowe-cli@zowe-v3-lts && \
    zowe plugins install @ibm/rse-api-for-zowe-cli


# ── 7. code-server (VS Code dans le navigateur) ───────────────────────────────
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        aarch64) CS_ARCH="arm64" ;; \
        *)        CS_ARCH="amd64" ;; \
    esac && \
    curl -fsSL -o /tmp/code-server.tar.gz \
        "https://github.com/coder/code-server/releases/download/v${CODESERVER_VERSION}/code-server-${CODESERVER_VERSION}-linux-${CS_ARCH}.tar.gz" && \
    tar -xzf /tmp/code-server.tar.gz -C /opt && \
    mv /opt/code-server-* /opt/code-server && \
    ln -s /opt/code-server/bin/code-server /usr/local/bin/code-server && \
    rm /tmp/code-server.tar.gz


# ─────────────────────────────────────────────────────────────────────────────
# À partir d'ici : installation sous l'utilisateur zdev
# Les outils système (Java, Node, Zowe, code-server) sont installés en root
# pour être accessibles globalement ; la configuration utilisateur se fait
# en tant que zdev pour garantir les bons droits.
# ─────────────────────────────────────────────────────────────────────────────

# ── 8. Utilisateur zdev ───────────────────────────────────────────────────────
RUN useradd -m -s /usr/bin/zsh zdev && \
    mkdir -p /home/zdev/workspace \
             /home/zdev/.local/share/code-server/coder-logs \
             /home/zdev/.config/code-server \
             /opt/code-server/extensions && \
    chown -R zdev:zdev /home/zdev /opt/code-server

WORKDIR /home/zdev
USER zdev

ENV PATH="/usr/local/bin:/home/zdev/.local/bin:$PATH"


# ── 9. MkDocs Material ────────────────────────────────────────────────────────
RUN uv tool install --no-cache mkdocs \
    --with "mkdocs-material[imaging]" \
    --with mkdocs-minify-plugin \
    --with mkdocs-redirects \
    --with mkdocs-git-revision-date-localized-plugin

# Le shim mkdocs doit être accessible globalement (requis par les extensions VS Code)
USER root
RUN cp /home/zdev/.local/bin/mkdocs /usr/local/bin/mkdocs
USER zdev


# ── 10. Fichiers de configuration (copiés dans /tmp, appliqués au démarrage) ──
# Copie dans /tmp plutôt que directement dans ~/  pour que entrypoint.sh puisse
# les appliquer après le montage des volumes Docker (sinon les volumes les masquent).
RUN mkdir -p /home/zdev/.local/share/code-server/User \
             /home/zdev/.config/copilot/instructions

COPY --chown=zdev:zdev ruff.toml     /tmp/ruff.toml
COPY --chown=zdev:zdev settings.json /tmp/settings.json
COPY --chown=zdev:zdev copilot/      /tmp/copilot/


# ── 11. Extensions VS Code (installation offline depuis les .vsix locaux) ─────
COPY --chown=zdev:zdev extensions/ /tmp/extensions/
RUN set -e; \
    echo ""; \
    echo "┌────────────────────────────────────────────────────────────────────┐"; \
    echo "│              Installation des extensions VS Code                   │"; \
    echo "├────────────────────────────────────────────────────────┬───────────┤"; \
    printf "│ %-54s │ %-9s │\n" "Extension" "Version"; \
    echo "├────────────────────────────────────────────────────────┼───────────┤"; \
    count=0; \
    for vsix in /tmp/extensions/*.vsix; do \
        [ -f "$vsix" ] || continue; \
        base="$(basename "$vsix" .vsix)"; \
        ver="${base##*-}"; \
        id="${base%-"$ver"}"; \
        printf "│ %-54s │ %-9s │\n" "$id" "$ver"; \
        code-server --extensions-dir /opt/code-server/extensions \
                    --install-extension "$vsix" --force > /dev/null 2>&1; \
        count=$((count + 1)); \
    done; \
    echo "├────────────────────────────────────────────────────────┴───────────┤"; \
    printf "│  Total : %-59s│\n" "${count} extension(s) installée(s)"; \
    echo "└────────────────────────────────────────────────────────────────────┘"; \
    echo ""; \
    rm -rf /tmp/extensions


# ── 12. Nettoyage proxy (ne pas propager dans l'image finale) ─────────────────
ENV HTTP_PROXY="" HTTPS_PROXY="" http_proxy="" https_proxy="" NO_PROXY="" no_proxy=""


# ── 13. Entrypoint ────────────────────────────────────────────────────────────
COPY --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 8443

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -fsS http://localhost:8443/healthz || exit 1
