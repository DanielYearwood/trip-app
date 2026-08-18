<script setup lang="ts">
import { computed } from 'vue'
import { storeToRefs } from 'pinia'
import { TriangleAlert } from 'lucide-vue-next'
import { useTripStore } from '@/stores/trip'
import { formatDate } from '@/lib/dates'
import { formatMoney } from '@/lib/money'
import { MODE_LABEL, ROUTE_STATUS_LABEL, type RouteStatus } from '@/types/domain'

const { routes } = storeToRefs(useTripStore())

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
      </li>
    </ol>

    <p v-if="!ordered.length" class="card p-6 text-center text-sm text-muted">
      Todavía no hay rutas cargadas.
    </p>
  </div>
</template>
