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

# Remove default nginx config
RUN rm -rf /etc/nginx/conf.d/* /etc/nginx/nginx.conf

# Copy the nginx configuration
COPY apps/${PROJECT}/nginx.conf /etc/nginx/nginx.conf

# Copy only the built files
COPY --from=builder /app/apps/${PROJECT}/dist /usr/share/nginx/html/

ARG PORT=3000
ENV PORT=${PORT}
EXPOSE ${PORT}

# Install wget and envsubst
RUN apk add --no-cache wget gettext

# Add health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --quiet --tries=1 --spider http://localhost:${PORT:-3000} || exit 1

CMD ["nginx", "-g", "daemon off;"]
