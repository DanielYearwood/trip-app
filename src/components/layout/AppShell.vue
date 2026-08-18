<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { RouterLink } from 'vue-router'
import { LogOut } from 'lucide-vue-next'
import BottomNav from './BottomNav.vue'
import { useAuthStore } from '@/stores/auth'
import { useTripStore } from '@/stores/trip'
import { formatRange } from '@/lib/dates'

const auth = useAuthStore()
const tripStore = useTripStore()
const { trip, loading, error } = storeToRefs(tripStore)
</script>

<template>
  <div class="min-h-screen flex flex-col">
    <header class="sticky top-0 z-20 bg-surface/95 backdrop-blur border-b border-line">
      <div class="mx-auto max-w-5xl px-4 h-14 flex items-center justify-between gap-3">
        <RouterLink to="/" class="min-w-0">
          <span class="block font-semibold truncate">{{ trip?.name ?? 'Bali 2026' }}</span>
          <span v-if="trip" class="block text-xs text-muted truncate">
            {{ formatRange(trip.start_date, trip.end_date) }} · {{ trip.travellers }} personas
          </span>
        </RouterLink>

        <button
          class="tap flex items-center gap-1.5 text-sm text-muted hover:text-ink px-2 rounded"
          aria-label="Cerrar sesión"
          @click="auth.signOut()"
        >
          <LogOut :size="18" />
          <span class="hidden sm:inline">Salir</span>
        </button>
      </div>
    </header>

    <main class="flex-1 mx-auto w-full max-w-5xl px-4 py-4 pb-24">
      <p v-if="error" class="card p-3 mb-4 text-sm text-danger border-danger/40">{{ error }}</p>

      <div v-if="loading && !trip" class="space-y-3" aria-busy="true">
        <div class="h-24 rounded-card bg-line/40 animate-pulse" />
        <div class="h-24 rounded-card bg-line/40 animate-pulse" />
      </div>

      <slot v-else />
    </main>

    <BottomNav />
  </div>
</template>
