FROM node:22-bookworm

# Install Bun (required for build scripts) and gosu for entrypoint user switching
RUN curl -fsSL https://bun.sh/install | bash && \
    apt-get update && \
    apt-get install -y --no-install-recommends gosu && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app

ARG OPENCLAW_DOCKER_APT_PACKAGES=""
RUN if [ -n "$OPENCLAW_DOCKER_APT_PACKAGES" ]; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $OPENCLAW_DOCKER_APT_PACKAGES && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
    fi

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

RUN pnpm install --frozen-lockfile

COPY . .
RUN OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build
# Force pnpm for UI build (Bun may fail on ARM/Synology architectures)
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

ENV NODE_ENV=production

# Allow non-root user to write temp files during runtime/tests.
RUN chown -R node:node /app

# Create /data directory for Railway volume mount
RUN mkdir -p /data && chown -R node:node /data

# Copy entrypoint script for permission handling
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

# Start gateway server.
# Uses shell form so we can reference env vars.
# Railway sets PORT; SETUP_PASSWORD enables the /setup wizard.
# OPENCLAW_GATEWAY_TOKEN is optional for API/webhook access.
#
# See docs/railway.mdx for full setup instructions.
CMD ["sh", "-c", "node dist/index.js gateway --allow-unconfigured --bind lan --port ${PORT:-8080}"]
