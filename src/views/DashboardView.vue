<script setup lang="ts">
import { computed } from 'vue'
import { storeToRefs } from 'pinia'
import { RouterLink } from 'vue-router'
import { AlertTriangle, Info, TriangleAlert, ArrowRight, Plane, ListChecks, Wallet } from 'lucide-vue-next'
import { useTripStore } from '@/stores/trip'
import { useExpensesStore } from '@/stores/expenses'
import { useChecklistsStore } from '@/stores/checklists'
import { formatRange, formatDate, daysUntil, nightsBetween } from '@/lib/dates'
import { formatMoney } from '@/lib/money'
import Cover from '@/components/ui/Cover.vue'

const tripStore = useTripStore()
const expenses = useExpensesStore()
const checklists = useChecklistsStore()
const { trip, zones, places, routes, alerts, chosenStayByZone } = storeToRefs(tripStore)
const { pagado, previsto } = storeToRefs(expenses)
const { pendingCount } = storeToRefs(checklists)

const countdown = computed(() => (trip.value ? daysUntil(trip.value.start_date) : null))

const flights = computed(() =>
  routes.value
    .filter((r) => r.mode === 'flight')
    .sort((a, b) => (a.date ?? '').localeCompare(b.date ?? '')),
)

const totalNights = computed(() =>
  zones.value.reduce((acc, z) => acc + (nightsBetween(z.start_date, z.end_date) ?? 0), 0),
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
  <div v-if="trip" class="space-y-8">
    <!-- Cabecera -->
    <header class="pt-2">
      <p class="text-sm font-medium uppercase tracking-widest text-muted">
        {{ trip.destination ?? 'Bali' }}
      </p>
      <h1 class="mt-1 text-5xl font-bold leading-[1.05]">
        <template v-if="countdown !== null && countdown > 0">
          Faltan<br /><span class="text-primary">{{ countdown }} días</span>
        </template>
        <span v-else class="text-primary">¡De viaje!</span>
      </h1>
      <p class="mt-3 text-sm text-muted">
        {{ formatRange(trip.start_date, trip.end_date) }} · {{ totalNights }} noches ·
        {{ trip.travellers }} personas
      </p>
    </header>

    <!-- Pendiente -->
    <section v-if="alerts.length" class="card p-5">
      <h2 class="section-title">Pendiente</h2>
      <ul class="mt-3 space-y-2.5">
        <li v-for="(a, i) in alerts" :key="i" class="flex items-start gap-2.5 text-sm">
          <component
            :is="icon[a.level]"
            :size="16"
            class="mt-0.5 shrink-0"
            :class="alertClass[a.level]"
          />
          <RouterLink v-if="a.to" :to="a.to" class="underline decoration-line hover:decoration-ink">
            {{ a.text }}
          </RouterLink>
          <span v-else>{{ a.text }}</span>
        </li>
      </ul>
    </section>

    <!-- Los tres tramos -->
    <section>
      <h2 class="section-title mb-3">El viaje</h2>
      <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <RouterLink
          v-for="(z, i) in zones"
          :key="z.id"
          :to="`/zona/${z.slug}`"
          class="card-tap group block overflow-hidden"
        >
          <Cover :src="z.cover_image_url" kind="beach" height="h-36">
            <span
              class="absolute left-4 top-4 rounded-full bg-black/45 px-2.5 py-1 text-xs font-medium text-white backdrop-blur-sm"
            >
              Tramo {{ i + 1 }}
            </span>
          </Cover>

          <div class="p-5">
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0">
                <h3 class="text-xl font-semibold leading-tight">{{ z.name }}</h3>
                <p class="mt-0.5 text-xs text-muted">
                  {{ formatRange(z.start_date, z.end_date) }} · {{ nightsOf(z) }} noches
                </p>
              </div>
              <ArrowRight
                :size="18"
                class="mt-1 shrink-0 text-muted transition group-hover:translate-x-0.5 group-hover:text-primary"
              />
            </div>

            <div class="mt-4 space-y-1.5 border-t border-line pt-3 text-sm">
              <div class="flex justify-between gap-3">
                <span class="text-muted">Hotel</span>
                <span v-if="chosenStayByZone[z.id]" class="min-w-0 truncate text-right font-medium">
                  {{ chosenStayByZone[z.id]!.name }}
                </span>
                <span v-else class="font-semibold text-warn">Sin decidir</span>
              </div>
              <div v-if="chosenStayByZone[z.id]" class="flex justify-between gap-3">
                <span class="text-muted">Estado</span>
                <span
                  class="font-medium"
                  :class="chosenStayByZone[z.id]!.status === 'reservado' ? 'text-ok' : 'text-warn'"
                >
                  {{ chosenStayByZone[z.id]!.status === 'reservado' ? 'Reservado' : 'Sin reservar' }}
                </span>
              </div>
              <div class="flex justify-between gap-3">
                <span class="text-muted">Planes</span>
                <span class="font-medium">{{ activityCount(z.id) }}</span>
              </div>
            </div>
          </div>
        </RouterLink>
      </div>
    </section>

    <!-- Dinero y tareas -->
    <div class="grid grid-cols-2 gap-4">
      <RouterLink to="/budget" class="card-tap p-5">
        <p class="flex items-center gap-1.5 text-xs uppercase tracking-wide text-muted">
          <Wallet :size="13" /> Pagado
        </p>
        <p class="mt-1 font-display text-3xl font-bold tracking-tightest">{{ formatMoney(pagado) }}</p>
        <p class="text-xs text-muted">de {{ formatMoney(previsto) }} previsto</p>
      </RouterLink>

      <RouterLink to="/checklists" class="card-tap p-5">
        <p class="flex items-center gap-1.5 text-xs uppercase tracking-wide text-muted">
          <ListChecks :size="13" /> Tareas
        </p>
        <p class="mt-1 font-display text-3xl font-bold tracking-tightest">{{ pendingCount }}</p>
        <p class="text-xs text-muted">pendientes</p>
      </RouterLink>
    </div>

    <!-- Vuelos -->
    <section v-if="flights.length" class="card p-5">
      <h2 class="section-title flex items-center gap-2"><Plane :size="16" /> Vuelos</h2>
      <ul class="mt-3 space-y-2 text-sm">
        <li v-for="f in flights" :key="f.id" class="flex items-baseline justify-between gap-3">
          <span class="min-w-0 truncate">{{ f.from_label }} → {{ f.to_label }}</span>
          <span class="shrink-0 text-xs text-muted">{{ formatDate(f.date, 'd MMM') }}</span>
        </li>
      </ul>
    </section>

    <div class="flex flex-wrap gap-2 pb-2">
      <RouterLink to="/places" class="btn-ghost">Todos los planes</RouterLink>
      <RouterLink to="/stays" class="btn-ghost">Todos los hoteles</RouterLink>
      <RouterLink to="/routes" class="btn-ghost">Todos los traslados</RouterLink>
    </div>
  </div>

  <div v-else class="card p-8 text-center">
    <p class="font-display text-lg font-semibold">Todavía no hay ningún viaje</p>
    <p class="mt-2 text-sm text-muted">
      Si acabas de entrar y ves esto, pide que te añadan al viaje: sin ser miembro no se ve nada.
    </p>
  </div>
</template>
