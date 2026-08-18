<script setup lang="ts">
import { RouterLink, useRoute } from 'vue-router'
import { Home, Map, Bed, Route, Wallet, ListChecks } from 'lucide-vue-next'

const route = useRoute()

const items = [
  { to: '/', label: 'Inicio', icon: Home },
  { to: '/map', label: 'Mapa', icon: Map },
  { to: '/stays', label: 'Hoteles', icon: Bed },
  { to: '/routes', label: 'Rutas', icon: Route },
  { to: '/budget', label: 'Dinero', icon: Wallet },
  { to: '/checklists', label: 'Tareas', icon: ListChecks },
]

const isActive = (to: string) => (to === '/' ? route.path === '/' : route.path.startsWith(to))
</script>

<template>
  <nav
    class="fixed bottom-0 inset-x-0 z-30 bg-surface/95 backdrop-blur border-t border-line"
    style="padding-bottom: env(safe-area-inset-bottom)"
    aria-label="Navegación principal"
  >
    <ul class="mx-auto max-w-5xl grid grid-cols-6">
      <li v-for="item in items" :key="item.to">
        <RouterLink
          :to="item.to"
          class="tap flex flex-col items-center justify-center gap-0.5 py-2 text-[11px]"
          :class="isActive(item.to) ? 'text-primary font-semibold' : 'text-muted'"
          :aria-current="isActive(item.to) ? 'page' : undefined"
        >
          <component :is="item.icon" :size="20" />
          {{ item.label }}
        </RouterLink>
      </li>
    </ul>
  </nav>
</template>
