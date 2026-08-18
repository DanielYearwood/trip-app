<script setup lang="ts">
import { computed, ref } from 'vue'
import { storeToRefs } from 'pinia'
import { TriangleAlert, ChevronRight, ExternalLink } from 'lucide-vue-next'
import { useTripStore } from '@/stores/trip'
import { formatDate } from '@/lib/dates'
import { formatMoney } from '@/lib/money'
import { MODE_LABEL, ROUTE_STATUS_LABEL, type RouteStatus, type TripRoute } from '@/types/domain'
import { useCommentsStore } from '@/stores/comments'
import RouteSheet from '@/components/routes/RouteSheet.vue'

const { routes } = storeToRefs(useTripStore())
const comments = useCommentsStore()
const editing = ref<TripRoute | null>(null)

const ordered = computed(() =>
  [...routes.value].sort((a, b) => (a.date ?? '').localeCompare(b.date ?? '')),
)

const statusClass: Record<RouteStatus, string> = {
  idea: 'bg-line/60 text-muted',
  requiere_confirmacion: 'bg-warn/15 text-warn',
  reservada: 'bg-sea/15 text-sea',
  confirmada: 'bg-ok/15 text-ok',
  en_riesgo: 'bg-danger/15 text-danger',
  descartada: 'bg-line/40 text-muted line-through',
}
</script>

<template>
  <div class="space-y-4">
    <h1 class="text-lg font-semibold">Rutas y transportes</h1>

    <ol class="space-y-3">
      <li v-for="r in ordered" :key="r.id" class="card p-4">
        <button class="w-full text-left" @click="editing = r">
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <p class="text-xs text-muted">{{ formatDate(r.date, 'EEE d MMM') }}</p>
            <p class="font-medium leading-tight">
              {{ r.from_label ?? '?' }} → {{ r.to_label ?? '?' }}
            </p>
            <p class="text-sm text-muted">{{ MODE_LABEL[r.mode] }}</p>
          </div>
          <span class="chip shrink-0" :class="statusClass[r.status]">
            {{ ROUTE_STATUS_LABEL[r.status] }}
          </span>
        </div>

        <p v-if="r.cost_amount !== null" class="mt-1 text-sm">
          {{ formatMoney(r.cost_amount, r.cost_currency ?? 'EUR') }}
        </p>

        <div
          v-if="r.risk_notes"
          class="mt-3 flex items-start gap-2 rounded bg-danger/5 p-2 text-sm text-danger"
        >
          <TriangleAlert :size="16" class="mt-0.5 shrink-0" />
          <span>{{ r.risk_notes }}</span>
        </div>

        <p v-if="r.notes" class="mt-2 text-sm text-muted">{{ r.notes }}</p>

          <p class="mt-2 flex items-center gap-1 text-xs text-primary">
            Abrir y editar <ChevronRight :size="13" />
            <span v-if="comments.countFor('route', r.id)" class="text-muted">
              · {{ comments.countFor('route', r.id) }} nota(s)
            </span>
          </p>
        </button>
      </li>
    </ol>

    <p v-if="!ordered.length" class="card p-6 text-center text-sm text-muted">
      Todavía no hay rutas cargadas.
    </p>

    <section class="card p-4">
      <h2 class="font-semibold">Dónde mirar los barcos</h2>
      <p class="mt-1 text-sm text-muted">
        Rome2Rio va bien para ver qué opciones existen. Para reservar y comparar horas, 12Go y las
        webs de los operadores. Cada ruta lleva dentro sus propios enlaces ya rellenados.
      </p>
      <ul class="mt-2 space-y-1 text-sm">
        <li>
          <a href="https://12go.asia/es/travel/bali/gili-trawangan" target="_blank" rel="noopener noreferrer"
             class="inline-flex items-center gap-1 text-primary underline">
            <ExternalLink :size="13" /> 12Go · Bali → Gili Trawangan
          </a>
        </li>
        <li>
          <a href="https://www.gilitickets.com" target="_blank" rel="noopener noreferrer"
             class="inline-flex items-center gap-1 text-primary underline">
            <ExternalLink :size="13" /> Gili Tickets · horarios de operadores
          </a>
        </li>
        <li>
          <a href="https://www.rome2rio.com/es/map/Aeropuerto-Ngurah-Rai-DPS/Gili-Trawangan"
             target="_blank" rel="noopener noreferrer"
             class="inline-flex items-center gap-1 text-primary underline">
            <ExternalLink :size="13" /> Rome2Rio · DPS → Gili Trawangan
          </a>
        </li>
      </ul>
    </section>

    <RouteSheet v-if="editing" :route="editing" @close="editing = null" />
  </div>
</template>
