ARG NODE_VERSION=18.18.0

# Base image with Bun - use platform-specific image
FROM --platform=${BUILDPLATFORM:-linux/amd64} oven/bun:canary-alpine AS alpine
RUN apk update
RUN apk add --no-cache libc6-compat tree nodejs npm

# Setup pnpm and turbo
RUN npm install pnpm turbo --global
RUN pnpm config set store-dir ~/.pnpm-store

# Prune projects
FROM alpine AS pruner
ARG PROJECT=hono-api

WORKDIR /app
COPY . .
RUN turbo prune --scope=${PROJECT} --docker

# Build the project
FROM alpine AS builder
ARG PROJECT=hono-api

WORKDIR /app

# Copy lockfile and package.json's of isolated subworkspace
COPY --from=pruner /app/out/pnpm-lock.yaml ./pnpm-lock.yaml
COPY --from=pruner /app/out/pnpm-workspace.yaml ./pnpm-workspace.yaml
COPY --from=pruner /app/out/json/ .

# First install the dependencies (as they change less often)
RUN --mount=type=cache,id=pnpm,target=~/.pnpm-store pnpm install --frozen-lockfile

# Copy source code of isolated subworkspace
COPY --from=pruner /app/out/full/ .

# Add debug before build
RUN echo "Contents before build:" && ls -la apps/hono-api/
RUN echo "\nturbo.json contents:" && cat turbo.json

# Run build directly with bun
WORKDIR /app/apps/hono-api
RUN bun build src/index.ts --outdir dist --target=bun

# Return to app root
WORKDIR /app

# Add debug after build
RUN echo "Contents after build:" && ls -la apps/hono-api/

RUN --mount=type=cache,id=pnpm,target=~/.pnpm-store pnpm prune --prod --no-optional

# Add debug command
CMD ["sh", "-c", "\
echo '\n=== DIRECTORY STRUCTURE ===\n' && \
tree -a -I 'node_modules' . && \
echo '\n=== HONO-API DIRECTORY ===\n' && \
ls -la apps/hono-api/ && \
echo '\n=== PACKAGE.JSON ===\n' && \
cat apps/hono-api/package.json && \
echo '\n=== TURBO.JSON ===\n' && \
cat turbo.json && \
echo '\n=== DIST FOLDERS ===\n' && \
find . -type d -name 'dist' -not -path '*/node_modules/*' -exec sh -c 'echo \"\n\nContents of {}:\" && ls -la {}' \\;"]

# Final image - use platform-specific image
FROM --platform=${TARGETPLATFORM:-linux/amd64} oven/bun:canary-alpine AS runner
ARG PROJECT=hono-api

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nodejs
USER nodejs

WORKDIR /app

# Copy only the built files and dependencies
COPY --from=builder --chown=nodejs:nodejs /app/apps/hono-api/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/apps/hono-api/package.json ./package.json

ARG PORT=3003
ENV PORT=${PORT}
ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0
EXPOSE ${PORT}

# Start the server
CMD ["bun", "dist/index.js"]
