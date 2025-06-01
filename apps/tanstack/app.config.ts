import tailwindcss from '@tailwindcss/vite'
import { defineConfig } from '@tanstack/react-start/config'
import tsConfigPaths from 'vite-tsconfig-paths'

export default defineConfig({
  vite: {
    plugins: [
      tsConfigPaths({
        projects: ['./tsconfig.json'],
      }),
      tailwindcss(),
    ],
    define: {
      process: {},
      'process.env': JSON.stringify(process.env),
    },
    optimizeDeps: {
      exclude: [
        '@tanstack/react-start-server',
        '@tanstack/react-start-server/dist/esm/transformStreamWithRouter.js',
      ],
    },
    ssr: {
      noExternal: ['@tanstack/react-start-server'],
      external: ['node:stream', 'node:stream/web', 'node:fs', 'node:path', 'node:async_hooks'],
    },
    build: {
      rollupOptions: {
        external: [
          'node:stream',
          'node:stream/web',
          'node:fs',
          'node:path',
          'node:async_hooks',
        ],
      },
    },
  },
  server: {
    preset: 'bun',
    experimental: {
      asyncContext: true,
    },
  },
})
