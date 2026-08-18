import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          // Leaflet solo se carga en la vista de mapa; lo mantenemos fuera
          // del bundle inicial para no penalizar el arranque en 4G.
          leaflet: ['leaflet', 'leaflet.markercluster'],
          supabase: ['@supabase/supabase-js'],
        },
      },
    },
  },
})
