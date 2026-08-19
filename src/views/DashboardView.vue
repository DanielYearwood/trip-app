<script setup lang="ts">
import { computed } from 'vue'
import { storeToRefs } from 'pinia'
import { RouterLink } from 'vue-router'
import { AlertTriangle, Info, TriangleAlert, ChevronRight, Plane, ListChecks } from 'lucide-vue-next'
import { useTripStore } from '@/stores/trip'
import { useExpensesStore } from '@/stores/expenses'
import { useChecklistsStore } from '@/stores/checklists'
import { formatRange, formatDate, daysUntil, nightsBetween } from '@/lib/dates'
import { formatMoney } from '@/lib/money'

const tripStore = useTripStore()
const expenses = useExpensesStore()
const checklists = useChecklistsStore()
const { trip, zones, places, routes, alerts, chosenStayByZone } = storeToRefs(tripStore)
const { pagado, previsto } = storeToRefs(expenses)
const { pendingCount } = storeToRefs(checklists)

const countdown = computed(() => (trip.value ? daysUntil(trip.value.start_date) : null))

const flights = computed(() =>
  routes.value.filter((r) => r.mode === 'flight').sort((a, b) => (a.date ?? '').localeCompare(b.date ?? '')),
)

function nightsOf(z: { start_date: string | null; end_date: string | null }) {
  return nightsBetween(z.start_date, z.end_date) ?? 0
}

function activityCount(zoneId: string) {
  return places.value.filter(
    (p) => p.kind === 'activity' && p.zone_id === zoneId && p.status !== 'descartado',
  ).length
}

const icon = { danger: TriangleAlert, warn: AlertTriangle, info: Info }
const alertClass = { danger: 'text-danger', warn: 'text-warn', info: 'text-muted' }
</script>

<template>
  <div v-if="trip" class="space-y-5">
    <!-- Cuenta atrás -->
    <section class="card p-4">
      <p class="text-sm text-muted">
        {{ trip.destination ?? 'Bali' }} · {{ formatRange(trip.start_date, trip.end_date) }}
      </p>
      <p v-if="countdown !== null && countdown > 0" class="mt-1 text-3xl font-semibold">
        Faltan {{ countdown }} días
      </p>
      <p v-else class="mt-1 text-3xl font-semibold">¡De viaje!</p>
    </section>

    <!-- Pendiente -->
    <section v-if="alerts.length" class="card p-4">
      <h2 class="font-semibold">Pendiente</h2>
      <ul class="mt-2 space-y-2">
        <li v-for="(a, i) in alerts" :key="i" class="flex items-start gap-2 text-sm">
          <component :is="icon[a.level]" :size="16" class="mt-0.5 shrink-0" :class="alertClass[a.level]" />
          <RouterLink v-if="a.to" :to="a.to" class="underline decoration-line hover:decoration-ink">
            {{ a.text }}
          </RouterLink>
          <span v-else>{{ a.text }}</span>
        </li>
      </ul>
    </section>

    <!-- Los tres tramos: el corazón de la app -->
    <section>
      <h2 class="mb-2 font-semibold">El viaje</h2>
      <div class="space-y-3">
        <RouterLink
          v-for="z in zones"
          :key="z.id"
          :to="`/zona/${z.slug}`"
          class="card block p-4 hover:border-primary/50"
        >
          <div class="flex items-start justify-between gap-3">
            <div class="min-w-0">
              <p class="text-lg font-semibold">{{ z.name }}</p>
              <p class="text-xs text-muted">
                {{ formatRange(z.start_date, z.end_date) }} · {{ nightsOf(z) }} noches
              </p>
            </div>
            <ChevronRight :size="20" class="mt-1 shrink-0 text-muted" />
          </div>

          <dl class="mt-3 space-y-1 text-sm">
            <div class="flex justify-between gap-3">
              <dt class="text-muted">Hotel</dt>
              <dd v-if="chosenStayByZone[z.id]" class="min-w-0 truncate text-right">
                {{ chosenStayByZone[z.id]!.name }}
                <span
                  class="ml-1 text-xs"
                  :class="chosenStayByZone[z.id]!.status === 'reservado' ? 'text-ok' : 'text-warn'"
                >
                  {{ chosenStayByZone[z.id]!.status === 'reservado' ? '· reservado' : '· sin reservar' }}
                </span>
              </dd>
              <dd v-else class="text-right font-medium text-warn">Sin decidir</dd>
            </div>
            <div class="flex justify-between gap-3">
              <dt class="text-muted">Planes</dt>
              <dd>{{ activityCount(z.id) }}</dd>
            </div>
          </dl>
        </RouterLink>
      </div>
    </section>

    <!-- Vuelos -->
    <section v-if="flights.length" class="card p-4">
      <h2 class="flex items-center gap-1.5 font-semibold"><Plane :size="16" /> Vuelos</h2>
      <ul class="mt-2 space-y-1 text-sm">
        <li v-for="f in flights" :key="f.id" class="flex justify-between gap-3">
          <span class="min-w-0 truncate text-muted">{{ f.from_label }} → {{ f.to_label }}</span>
          <span class="shrink-0">{{ formatDate(f.date, 'd MMM') }}</span>
        </li>
      </ul>
    </section>

    <!-- Accesos -->
    <div class="grid grid-cols-2 gap-3">
      <RouterLink to="/budget" class="card p-4 hover:border-primary/50">
        <p class="text-sm text-muted">Pagado</p>
        <p class="text-xl font-semibold">{{ formatMoney(pagado) }}</p>
        <p class="text-xs text-muted">de {{ formatMoney(previsto) }} previsto</p>
      </RouterLink>

      <RouterLink to="/checklists" class="card p-4 hover:border-primary/50">
        <p class="flex items-center gap-1.5 text-sm text-muted"><ListChecks :size="14" /> Tareas</p>
        <p class="text-xl font-semibold">{{ pendingCount }}</p>
        <p class="text-xs text-muted">pendientes</p>
      </RouterLink>
    </div>

    <div class="flex flex-wrap gap-2 text-sm">
      <RouterLink to="/places" class="tap rounded border border-line px-3 text-muted">Todos los planes</RouterLink>
      <RouterLink to="/stays" class="tap rounded border border-line px-3 text-muted">Todos los hoteles</RouterLink>
      <RouterLink to="/routes" class="tap rounded border border-line px-3 text-muted">Todos los traslados</RouterLink>
    </div>
  </div>

  <div v-else class="card p-6 text-center">
    <p class="font-medium">Todavía no hay ningún viaje</p>
    <p class="mt-1 text-sm text-muted">
      Si acabas de entrar y ves esto, pide que te añadan al viaje: sin ser miembro no se ve nada.
    </p>
  </div>
</template>
