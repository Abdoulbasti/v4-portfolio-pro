# syntax=docker/dockerfile:1

# Versions figées. NODE_VERSION doit rester aligné sur .nvmrc.
ARG NODE_VERSION=24
ARG NGINX_VERSION=1.30

############################
# Stage: deps
############################
# Debian (glibc) plutôt qu'Alpine : sharp, lmdb et msgpackr-extract
# téléchargent des binaires précompilés pour glibc.
FROM node:${NODE_VERSION}-trixie-slim AS deps

# HUSKY=0 : le script `prepare` (husky install) ne fait rien, il n'y a pas de
# dépôt git dans l'image.
ENV GATSBY_TELEMETRY_DISABLED=1 \
    HUSKY=0 \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_AUDIT=false \
    NPM_CONFIG_UPDATE_NOTIFIER=false

WORKDIR /app
RUN chown node:node /app
USER node

COPY --chown=node:node package.json package-lock.json ./
# Installation complète :
#   - pas de --omit=dev : .babelrc (babel-preset-gatsby) et gatsby-config.js
#     (gatsby-remark-code-titles) utilisent des devDependencies au build ;
#   - pas de --ignore-scripts : sharp 0.32 télécharge libvips dans son script
#     d'installation.
RUN --mount=type=cache,target=/home/node/.npm,uid=1000,gid=1000 npm ci

############################
# Stage: development
############################
# Utilisé par docker-compose.dev.yml (gatsby develop + Compose Watch).
FROM deps AS development
COPY --chown=node:node . .
# Créés ici pour que les volumes nommés montés dessus appartiennent à `node`.
RUN mkdir -p .cache public
EXPOSE 8000
# Binaire appelé directement (pas via npm) pour recevoir les signaux d'arrêt.
CMD ["node_modules/.bin/gatsby", "develop", "--host", "0.0.0.0", "--port", "8000"]

############################
# Stage: build
############################
# Pas de cache BuildKit sur .cache : conserver .cache sans public/ fait
# disparaître les images générées par sharp. Chaque build part de zéro.
FROM deps AS build
COPY --chown=node:node . .
RUN npm run build

############################
# Stage: production
############################
# nginx sert les fichiers statiques de public/ (non-root, uid 101, port 8080).
# Caddy (vps-infrastructure) reste le seul point d'entrée : TLS et routage.
FROM nginxinc/nginx-unprivileged:${NGINX_VERSION}-alpine AS production

LABEL org.opencontainers.image.source="https://github.com/Abdoulbasti/v4-portfolio-pro" \
      org.opencontainers.image.description="Portfolio d'Abdoulbasti MUKAILA (Gatsby) servi par nginx" \
      org.opencontainers.image.licenses="MIT"

COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf
# Fichiers détenus par root : nginx peut les lire mais pas les modifier.
COPY --from=build /app/public /usr/share/nginx/html

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q --spider http://127.0.0.1:8080/healthz || exit 1
