# ================================================================
#  Dockerfile — Agent Wazuh sur Ubuntu 22.04 (Jammy Jellyfish)
#  Auteur  : Péniel LAWSON-Body
#  Date    : 20 mars 2026
# ================================================================

FROM ubuntu:22.04

LABEL maintainer="Péniel LAWSON-Body"
LABEL description="Wazuh Agent 4.7.3 sur Ubuntu 22.04 Jammy"
LABEL version="4.7.3"

ARG WAZUH_VERSION=4.7.3
ENV DEBIAN_FRONTEND=noninteractive

# ── 1. Mise à jour et dépendances système ──────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    apt-transport-https \
    ca-certificates \
    netcat-openbsd \
    iputils-ping \
    net-tools \
    procps \
    sudo \
    wget \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# ── 2. Ajout de la clé GPG et du dépôt Wazuh ──────────────────
RUN curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH \
    | gpg --no-default-keyring \
          --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg \
          --import \
    && chmod 644 /usr/share/keyrings/wazuh.gpg

RUN echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] \
https://packages.wazuh.com/4.x/apt/ stable main" \
    > /etc/apt/sources.list.d/wazuh.list

# ── 3. Installation de l'agent Wazuh ──────────────────────────
RUN apt-get update \
    && apt-get install -y wazuh-agent=${WAZUH_VERSION}-1 \
    && rm -rf /var/lib/apt/lists/*

# ── 4. Copie du script d'entrypoint ───────────────────────────
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
