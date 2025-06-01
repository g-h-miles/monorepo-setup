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
      exclude: ['@tanstack/react-start-server'],
    },
    ssr: {
      noExternal: ['@tanstack/react-start-server'],
    },
    resolve: {
      alias: {
        'node:stream': 'stream',
        'node:stream/web': 'stream/web',
      },
    },
  },
})
