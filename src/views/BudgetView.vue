<script setup lang="ts">
import { computed } from 'vue'
import { storeToRefs } from 'pinia'
import { useTripStore } from '@/stores/trip'
import { formatMoney, perPerson } from '@/lib/money'

const tripStore = useTripStore()
const { trip, zones, stays, chosenStayByZone, decidedAccommodationTotal } = storeToRefs(tripStore)

/**
 * Simulador: coste del viaje según qué candidato se elija en cada zona sin
 * decidir. No toca la base de datos; solo enseña el delta.
 */
const openZones = computed(() =>
  zones.value
    .filter((z) => !chosenStayByZone.value[z.id])
    .map((z) => ({
      zone: z,
      options: stays.value
        .filter((s) => s.zone_id === z.id && s.status !== 'descartado' && s.price_amount !== null)
        .sort((a, b) => (a.price_amount ?? 0) - (b.price_amount ?? 0)),
    }))
    .filter((g) => g.options.length),
)

const cheapestExtra = computed(() =>
  openZones.value.reduce((acc, g) => acc + (g.options[0]?.price_amount ?? 0), 0),
)
</script>

<template>
  <div class="space-y-4">
    <h1 class="text-lg font-semibold">Dinero</h1>

    <section class="card p-4">
      <p class="text-sm text-muted">Alojamiento ya decidido</p>
      <p class="mt-1 text-3xl font-semibold">{{ formatMoney(decidedAccommodationTotal) }}</p>
      <p v-if="trip" class="text-sm text-muted">
        {{ formatMoney(perPerson(decidedAccommodationTotal, trip.travellers)) }} por persona
      </p>
    </section>

    <section v-if="openZones.length" class="card p-4">
      <h2 class="font-semibold">Qué falta por cerrar</h2>
      <p class="mt-1 text-sm text-muted">
        Los candidatos no cuentan en el total. Esto es lo que sumaría cada opción.
      </p>

      <div v-for="g in openZones" :key="g.zone.id" class="mt-4">
        <p class="text-sm font-medium">{{ g.zone.name }}</p>
        <ul class="mt-1 space-y-1 text-sm">
          <li v-for="(o, i) in g.options" :key="o.id" class="flex justify-between gap-3">
            <span class="min-w-0 truncate" :class="i === 0 ? 'font-medium' : 'text-muted'">
              {{ o.name }}
            </span>
            <span class="shrink-0 tabular-nums" :class="i === 0 ? 'font-medium' : 'text-muted'">
              {{ formatMoney(o.price_amount, o.price_currency ?? 'EUR') }}
              <span v-if="i > 0 && g.options[0]?.price_amount != null" class="text-xs">
                (+{{ formatMoney((o.price_amount ?? 0) - (g.options[0]!.price_amount ?? 0)) }})
              </span>
            </span>
          </li>
        </ul>
      </div>

      <p class="mt-4 border-t border-line pt-3 text-sm">
        Total con la opción más barata de cada zona pendiente:
        <strong>{{ formatMoney(decidedAccommodationTotal + cheapestExtra) }}</strong>
      </p>
    </section>

    <p class="card p-4 text-sm text-muted">
      Los gastos detallados (vuelos, traslados, actividades, comida) todavía no están cargados.
      En cuanto se registren aquí aparecerán el previsto, el comprometido, el pagado y el reparto
      entre los dos.
    </p>
  </div>
</template>
