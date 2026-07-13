import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'

export default defineConfig({
  plugins: [svelte()],
  base: '/',
  build: {
    outDir: '../../priv/static',
    emptyOutDir: false,
    rollupOptions: {
      input: 'index.html'
    }
  },
  server: {
    proxy: {
      '/api': 'http://localhost:4000',
      '/auth': 'http://localhost:4000'
    }
  }
})
