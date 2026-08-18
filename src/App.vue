<script setup lang="ts">
import { onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { storeToRefs } from 'pinia'
import AppShell from '@/components/layout/AppShell.vue'
import { useAuthStore } from '@/stores/auth'
import { useTripStore } from '@/stores/trip'
import { useExpensesStore } from '@/stores/expenses'
import { useCommentsStore } from '@/stores/comments'
import { useChecklistsStore } from '@/stores/checklists'
import { supabaseConfigured } from '@/lib/supabase'

const route = useRoute()
const auth = useAuthStore()
const tripStore = useTripStore()
const { isLoggedIn } = storeToRefs(auth)

const expenses = useExpensesStore()
const comments = useCommentsStore()
const checklists = useChecklistsStore()

async function loadAll() {
  await tripStore.load()
  if (!tripStore.trip) return
  const id = tripStore.trip.id
  await Promise.all([expenses.load(id), comments.load(id), checklists.load(id)])
}

onMounted(async () => {
  await auth.init()
  if (auth.isLoggedIn) await loadAll()
})

// Al iniciar o cerrar sesión, recargamos o vaciamos los datos del viaje.
watch(isLoggedIn, async (logged) => {
  if (logged) await loadAll()
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
