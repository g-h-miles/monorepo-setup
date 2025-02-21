ARG NODE_VERSION=18.18.0

# Alpine image
FROM --platform=${BUILDPLATFORM:-linux/amd64} node:${NODE_VERSION}-alpine AS alpine
RUN apk update
RUN apk add --no-cache libc6-compat

# Setup pnpm and turbo on the alpine base
FROM alpine as base
RUN npm install pnpm turbo --global
RUN pnpm config set store-dir ~/.pnpm-store

# Prune projects
FROM base AS pruner
ARG PROJECT=astro

WORKDIR /app
COPY . .
RUN turbo prune --scope=${PROJECT} --docker

# Build the project
FROM base AS builder
ARG PROJECT=astro

WORKDIR /app

# Copy lockfile and package.json's of isolated subworkspace
COPY --from=pruner /app/out/pnpm-lock.yaml ./pnpm-lock.yaml
COPY --from=pruner /app/out/pnpm-workspace.yaml ./pnpm-workspace.yaml
COPY --from=pruner /app/out/json/ .

# First install dependencies
RUN --mount=type=cache,id=pnpm,target=~/.pnpm-store pnpm install --frozen-lockfile

# Copy source code of isolated subworkspace
COPY --from=pruner /app/out/full/ .

# Build the Astro app
RUN turbo build --filter=${PROJECT}
RUN ls -la /app/apps/${PROJECT}/dist
RUN ls -la /app/apps/${PROJECT}/dist/_astro || echo "No _astro directory"

# Final image using nginx
FROM --platform=${TARGETPLATFORM:-linux/amd64} nginx:alpine AS runner
ARG PROJECT=astro

# Copy the built files
COPY --from=builder /app/apps/${PROJECT}/dist /usr/share/nginx/html

# Add a basic nginx config if one doesn't exist
COPY --from=builder /app/apps/${PROJECT}/nginx.conf /etc/nginx/conf.d/default.conf || \
COPY <<EOF /etc/nginx/conf.d/default.conf
server {
    listen ${PORT:-3001};
    server_name _;
    root /usr/share/nginx/html;
    index index.html;
    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

ARG PORT=3001
ENV PORT=${PORT}
EXPOSE ${PORT}

# Configure nginx to use environment variables
CMD sed -i -e 's/$PORT/'"$PORT"'/g' /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'
