# syntax=docker/dockerfile:1

# Pinned versions for reproducible builds: bump them deliberately.
ARG NODE_VERSION=26.13.1-alpine3.24
ARG NGINX_VERSION=1.30.8-alpine

# ---- Stage 1: build the Angular application ---------------------------------
FROM node:${NODE_VERSION} AS build
WORKDIR /src

# Dependencies first: this layer is reused as long as the lockfile is unchanged
COPY package.json package-lock.json ./
RUN npm ci

# Then the sources, and the production build
COPY . .
RUN npm run build

# ---- Stage 2: serve the static files with Nginx -----------------------------
FROM nginx:${NGINX_VERSION} AS runtime

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=build /src/dist/olympic-games-starter/browser /app

# Run the whole server as the unprivileged nginx user, not only its workers.
# nginx.conf already writes its pid and temp files to /tmp; the served files
# stay owned by root, so the server can read them but not modify them.
USER nginx

EXPOSE 80
