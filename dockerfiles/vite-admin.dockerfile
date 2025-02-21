ARG NODE_VERSION=18.18.0

# Alpine image
FROM node:${NODE_VERSION}-alpine AS alpine
RUN apk update
RUN apk add --no-cache libc6-compat

# Setup pnpm and turbo on the alpine base
FROM alpine as base
RUN npm install pnpm turbo --global
RUN pnpm config set store-dir ~/.pnpm-store

# Prune projects
FROM base AS pruner
ARG PROJECT=vite-admin

WORKDIR /app
COPY . .
RUN turbo prune --scope=${PROJECT} --docker

# Build the project
FROM base AS builder
ARG PROJECT=vite-admin

WORKDIR /app

# Copy lockfile and package.json's of isolated subworkspace
COPY --from=pruner /app/out/pnpm-lock.yaml ./pnpm-lock.yaml
COPY --from=pruner /app/out/pnpm-workspace.yaml ./pnpm-workspace.yaml
COPY --from=pruner /app/out/json/ .

# First install dependencies
RUN --mount=type=cache,id=pnpm,target=~/.pnpm-store pnpm install --frozen-lockfile

# Copy source code of isolated subworkspace
COPY --from=pruner /app/out/full/ .

# Build the Vite app
RUN turbo build --filter=${PROJECT}

# Final image using nginx
FROM nginx:alpine AS runner
ARG PROJECT=vite-admin

# Copy the built assets to nginx serve directory
COPY --from=builder /app/apps/${PROJECT}/dist /usr/share/nginx/html

# Copy custom nginx config
COPY --from=builder /app/apps/${PROJECT}/nginx.conf /etc/nginx/conf.d/default.conf

ARG PORT=3000
ENV PORT=${PORT}

EXPOSE ${PORT}

# Use shell form to interpolate PORT env var
CMD sed -i -e 's/$PORT/'"$PORT"'/g' /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'
