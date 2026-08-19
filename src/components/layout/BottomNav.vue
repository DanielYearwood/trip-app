<script setup lang="ts">
import { RouterLink, useRoute } from 'vue-router'
import { Home, Map, Wallet } from 'lucide-vue-next'

const route = useRoute()

const items = [
  { to: '/', label: 'Viaje', icon: Home },
  { to: '/map', label: 'Mapa', icon: Map },
  { to: '/budget', label: 'Dinero', icon: Wallet },
]

const isActive = (to: string) => (to === '/' ? route.path === '/' : route.path.startsWith(to))
</script>

<template>
  <nav
    class="fixed bottom-0 inset-x-0 z-30 bg-surface/90 backdrop-blur-xl border-t border-line"
    style="padding-bottom: env(safe-area-inset-bottom)"
    aria-label="Navegación principal"
  >
    <ul class="mx-auto max-w-5xl grid grid-cols-3">
      <li v-for="item in items" :key="item.to">
        <RouterLink
          :to="item.to"
          class="tap flex flex-col items-center justify-center gap-1 py-2.5 text-xs"
          :class="isActive(item.to) ? 'text-primary font-semibold' : 'text-muted'"
          :aria-current="isActive(item.to) ? 'page' : undefined"
        >
          <component :is="item.icon" :size="22" />
          {{ item.label }}
        </RouterLink>
      </li>
    </ul>
  </nav>
</template>
