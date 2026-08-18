<script setup lang="ts">
import { onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { storeToRefs } from 'pinia'
import AppShell from '@/components/layout/AppShell.vue'
import { useAuthStore } from '@/stores/auth'
import { useTripStore } from '@/stores/trip'
import { supabaseConfigured } from '@/lib/supabase'

const route = useRoute()
const auth = useAuthStore()
const tripStore = useTripStore()
const { isLoggedIn } = storeToRefs(auth)

onMounted(async () => {
  await auth.init()
  if (auth.isLoggedIn) await tripStore.load()
})

// Al iniciar o cerrar sesión, recargamos o vaciamos los datos del viaje.
watch(isLoggedIn, async (logged) => {
  if (logged) await tripStore.load()
})
</script>

<template>
  <div v-if="!supabaseConfigured" class="p-6 text-center">
    <h1 class="text-lg font-semibold text-danger">Configuración incompleta</h1>
    <p class="mt-2 text-sm text-muted">
      Faltan <code>VITE_SUPABASE_URL</code> o <code>VITE_SUPABASE_ANON_KEY</code>.
    </p>
  </div>

  <RouterView v-else-if="route.meta.public" />

  <AppShell v-else>
    <RouterView />
  </AppShell>
</template>
