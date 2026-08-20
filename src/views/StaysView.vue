<script setup lang="ts">
import { computed, ref } from 'vue'
import { storeToRefs } from 'pinia'
import { Star, Waves, Coffee, ChevronRight } from 'lucide-vue-next'
import { useTripStore } from '@/stores/trip'
import { formatMoney, formatWithEur, perNight, toEur } from '@/lib/money'
import { formatRange } from '@/lib/dates'
import StatusBadge from '@/components/places/StatusBadge.vue'
import Cover from '@/components/ui/Cover.vue'
import PlaceDetailSheet from '@/components/places/PlaceDetailSheet.vue'
import type { Place, PlaceStatus } from '@/types/domain'

const tripStore = useTripStore()
const { zones, stays, fxRate } = storeToRefs(tripStore)

const showDiscarded = ref(false)
const zoneFilter = ref<string | 'all'>('all')
const detail = ref<Place | null>(null)

// Orden de decisión: primero lo cerrado, luego lo que aún se está valorando.
const RANK: Record<PlaceStatus, number> = {
  reservado: 0,
  seleccionado: 1,
  favorito: 2,
  candidato: 3,
  planificado: 4,
  idea: 5,
  realizado: 6,
  descartado: 7,
}

const visible = computed(() =>
  stays.value
    .filter((s) => showDiscarded.value || s.status !== 'descartado')
    .filter((s) => zoneFilter.value === 'all' || s.zone_id === zoneFilter.value)
    .sort((a, b) => RANK[a.status] - RANK[b.status] || (a.price_amount ?? 1e9) - (b.price_amount ?? 1e9)),
)

const grouped = computed(() =>
  zones.value
    .map((z) => ({ zone: z, items: visible.value.filter((s) => s.zone_id === z.id) }))
    .filter((g) => g.items.length),
)

const discardedCount = computed(() => stays.value.filter((s) => s.status === 'descartado').length)
</script>

<template>
  <div class="space-y-4">
    <header class="flex flex-wrap items-center gap-2">
      <h1 class="mr-auto text-2xl font-bold">Alojamientos</h1>
      <select
        v-model="zoneFilter"
        class="tap rounded border border-line bg-surface px-2 text-sm"
        aria-label="Filtrar por zona"
      >
        <option value="all">Todas las zonas</option>
        <option v-for="z in zones" :key="z.id" :value="z.id">{{ z.name }}</option>
      </select>
      <button
        v-if="discardedCount"
        class="tap rounded border border-line px-2 text-sm text-muted"
        @click="showDiscarded = !showDiscarded"
      >
        {{ showDiscarded ? 'Ocultar' : 'Ver' }} descartados ({{ discardedCount }})
      </button>
    </header>

    <section v-for="g in grouped" :key="g.zone.id">
      <h2 class="mb-2 text-sm font-semibold text-muted">
        {{ g.zone.name }} · {{ formatRange(g.zone.start_date, g.zone.end_date) }}
      </h2>

      <ul class="space-y-3">
        <li
          v-for="s in g.items"
          :key="s.id"
          class="card overflow-hidden"
          :class="s.status === 'descartado' ? 'opacity-50' : ''"
        >
          <Cover :src="s.cover_image_url" kind="stay" height="h-32">
            <span class="absolute right-3 top-3">
              <StatusBadge :status="s.status" />
            </span>
          </Cover>

          <div class="p-4">
            <h3 class="font-display text-lg font-semibold leading-tight tracking-tightest">
              {{ s.name }}
            </h3>

          <p class="mt-1 text-sm">
            <span class="font-semibold">
              {{ formatWithEur(s.price_amount, s.price_currency, fxRate) }}
            </span>
            <span
              v-if="perNight(toEur(s.price_amount, s.price_currency, fxRate), s.stay_details?.nights ?? null)"
              class="text-muted"
            >
              ·
              {{ formatMoney(perNight(toEur(s.price_amount, s.price_currency, fxRate), s.stay_details?.nights ?? null)) }}/noche
            </span>
          </p>

          <div class="mt-2 flex flex-wrap items-center gap-1.5 text-xs">
            <span v-if="s.price_pending" class="chip bg-warn/15 text-warn">precio por confirmar</span>
            <span v-if="s.rating" class="chip bg-line/50 text-muted">
              <Star :size="12" /> {{ s.rating }}
              <template v-if="s.rating_count">· {{ s.rating_count }}</template>
            </span>
            <span v-if="s.stay_details?.pool === 'privada'" class="chip bg-sea/15 text-sea">
              <Waves :size="12" /> piscina privada
            </span>
            <span v-else-if="s.stay_details?.pool === 'compartida'" class="chip bg-line/50 text-muted">
              <Waves :size="12" /> piscina
            </span>
            <span v-if="s.stay_details?.breakfast_included" class="chip bg-line/50 text-muted">
              <Coffee :size="12" /> desayuno
            </span>
            <span v-if="s.stay_details?.room_size_m2" class="chip bg-line/50 text-muted">
              {{ s.stay_details.room_size_m2 }} m²
            </span>
            <span v-if="s.stay_details?.pay_at_property" class="chip bg-accent/15 text-accent">
              pago en destino
            </span>
          </div>

          <p v-if="s.notes" class="mt-2 text-sm text-muted">{{ s.notes }}</p>

          <details v-if="s.pros.length || s.cons.length" class="mt-2 text-sm">
            <summary class="tap cursor-pointer text-primary">Pros y contras</summary>
            <ul class="mt-1 space-y-0.5">
              <li v-for="p in s.pros" :key="p" class="text-ok">+ {{ p }}</li>
              <li v-for="c in s.cons" :key="c" class="text-danger">− {{ c }}</li>
            </ul>
          </details>

          <div class="mt-3 flex flex-wrap items-center gap-2">
            <select
              :value="s.status"
              class="tap rounded border border-line bg-surface px-2 text-sm"
              :aria-label="`Cambiar estado de ${s.name}`"
              @change="tripStore.setStatus(s.id, ($event.target as HTMLSelectElement).value as PlaceStatus)"
            >
              <option value="idea">Idea</option>
              <option value="candidato">Candidato</option>
              <option value="favorito">Favorito</option>
              <option value="seleccionado">Seleccionado</option>
              <option value="reservado">Reservado</option>
              <option value="descartado">Descartado</option>
            </select>
            <button
              class="tap ml-auto inline-flex items-center gap-1 rounded border border-line px-3 text-sm"
              @click="detail = s"
            >
              Ver ficha <ChevronRight :size="14" />
            </button>
            </div>
          </div>
        </li>
      </ul>
    </section>

    <PlaceDetailSheet v-if="detail" :place="detail" @close="detail = null" />

    <p v-if="!grouped.length" class="card p-6 text-center text-sm text-muted">
      No hay alojamientos que cumplan el filtro.
    </p>
  </div>
</template>
