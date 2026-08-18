<script setup lang="ts">
import { computed } from 'vue'
import { storeToRefs } from 'pinia'
import { RouterLink } from 'vue-router'
import { AlertTriangle, Info, TriangleAlert } from 'lucide-vue-next'
import { useTripStore } from '@/stores/trip'
import { formatRange, daysUntil, nightsBetween } from '@/lib/dates'
import { formatMoney, perNight } from '@/lib/money'
import StatusBadge from '@/components/places/StatusBadge.vue'

const tripStore = useTripStore()
const { trip, zones, alerts, chosenStayByZone, decidedAccommodationTotal, nightsCovered } =
  storeToRefs(tripStore)

const countdown = computed(() => {
  if (!trip.value) return null
  return daysUntil(trip.value.start_date)
})

const totalNights = computed(() =>
  trip.value ? (nightsBetween(trip.value.start_date, trip.value.end_date) ?? 0) : 0,
)

const icon = { danger: TriangleAlert, warn: AlertTriangle, info: Info }
const alertClass = {
  danger: 'text-danger',
  warn: 'text-warn',
  info: 'text-muted',
}
</script>

<template>
  <div v-if="trip" class="space-y-5">
    <!-- Cuenta atrás -->
    <section class="card p-4">
      <p class="text-sm text-muted">
        {{ trip.destination ?? 'Bali' }} · {{ formatRange(trip.start_date, trip.end_date) }}
      </p>
      <p v-if="countdown !== null && countdown > 0" class="mt-1 text-2xl font-semibold">
        Faltan {{ countdown }} días
      </p>
      <p v-else-if="countdown !== null && countdown <= 0" class="mt-1 text-2xl font-semibold">
        ¡De viaje!
      </p>
    </section>

    <!-- Avisos y riesgos -->
    <section v-if="alerts.length" class="card p-4">
      <h2 class="font-semibold">Pendiente de resolver</h2>
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

    <!-- Alojamiento por zona -->
    <section>
      <h2 class="mb-2 font-semibold">Dónde dormimos</h2>
      <div class="space-y-3">
        <article v-for="z in zones" :key="z.id" class="card p-4">
          <div class="flex items-start justify-between gap-3">
            <div class="min-w-0">
              <p class="font-medium">{{ z.name }}</p>
              <p class="text-xs text-muted">{{ formatRange(z.start_date, z.end_date) }}</p>
            </div>
            <StatusBadge v-if="chosenStayByZone[z.id]" :status="chosenStayByZone[z.id]!.status" />
            <span v-else class="chip bg-warn/15 text-warn">Sin decidir</span>
          </div>

          <div v-if="chosenStayByZone[z.id]" class="mt-3">
            <p class="font-medium">{{ chosenStayByZone[z.id]!.name }}</p>
            <p class="text-sm text-muted">
              {{ formatMoney(chosenStayByZone[z.id]!.price_amount, chosenStayByZone[z.id]!.price_currency ?? 'EUR') }}
              <template v-if="perNight(chosenStayByZone[z.id]!.price_amount, chosenStayByZone[z.id]!.stay_details?.nights ?? null)">
                ·
                {{ formatMoney(perNight(chosenStayByZone[z.id]!.price_amount, chosenStayByZone[z.id]!.stay_details?.nights ?? null), 'EUR') }}/noche
              </template>
              <span v-if="chosenStayByZone[z.id]!.price_pending" class="chip ml-1 bg-warn/15 text-warn">
                precio por confirmar
              </span>
            </p>
          </div>
          <RouterLink v-else to="/stays" class="mt-3 inline-block text-sm text-primary underline">
            Ver candidatos
          </RouterLink>
        </article>
      </div>
    </section>

    <!-- Resumen económico -->
    <section class="card p-4">
      <h2 class="font-semibold">Alojamiento decidido</h2>
      <p class="mt-1 text-2xl font-semibold">{{ formatMoney(decidedAccommodationTotal) }}</p>
      <p class="text-sm text-muted">
        {{ nightsCovered }} de {{ totalNights }} noches cubiertas · para {{ trip.travellers }} personas
      </p>
      <p class="mt-2 text-xs text-muted">
        Solo cuenta lo seleccionado o reservado. No incluye vuelos, traslados, actividades ni comidas.
      </p>
    </section>
  </div>

  <div v-else class="card p-6 text-center">
    <p class="font-medium">Todavía no hay ningún viaje</p>
    <p class="mt-1 text-sm text-muted">
      Ejecuta <code>select public.seed_bali_2026('tu@correo.com');</code> en Supabase para cargar
      los datos del viaje.
    </p>
  </div>
</template>
