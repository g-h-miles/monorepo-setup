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

# Debug: Check if nginx.conf exists
RUN echo "Checking for nginx.conf:" && \
    ls -la /app/apps/${PROJECT}/ && \
    echo "Contents of apps/${PROJECT}:"

# Final image using nginx
FROM --platform=${TARGETPLATFORM:-linux/amd64} nginx:alpine AS runner
ARG PROJECT=vite-admin

# Copy the built files and nginx config
COPY --from=builder /app/apps/${PROJECT}/dist /usr/share/nginx/html/
COPY --from=builder /app/apps/${PROJECT}/nginx.conf /etc/nginx/conf.d/default.conf

ARG PORT=3000
ENV PORT=${PORT}
EXPOSE ${PORT}

# Install wget for health check
RUN apk add --no-cache wget

# Configure nginx
CMD ["nginx", "-g", "daemon off;"]

# Add health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --quiet --tries=1 --spider http://localhost:${PORT:-3000} || exit 1
