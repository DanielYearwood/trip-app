<script setup lang="ts">
import { ref, computed } from 'vue'
import { ExternalLink, Search } from 'lucide-vue-next'
import Sheet from '@/components/ui/Sheet.vue'
import CommentThread from '@/components/comments/CommentThread.vue'
import { useTripStore } from '@/stores/trip'
import { MODE_LABEL, type RouteMode, type RouteStatus, type TripRoute } from '@/types/domain'

const props = defineProps<{ route: TripRoute }>()
const emit = defineEmits<{ close: [] }>()

const tripStore = useTripStore()
const r = props.route

const from = ref(r.from_label ?? '')
const to = ref(r.to_label ?? '')
const mode = ref<RouteMode>(r.mode)
const date = ref(r.date ?? '')
const status = ref<RouteStatus>(r.status)
const cost = ref<number | null>(r.cost_amount)
const currency = ref(r.cost_currency ?? 'EUR')
const operator = ref(r.operator ?? '')
const bookingUrl = ref((r as TripRoute & { booking_url?: string }).booking_url ?? '')
const bookingRef = ref((r as TripRoute & { booking_reference?: string }).booking_reference ?? '')
const riskNotes = ref(r.risk_notes ?? '')
const notes = ref(r.notes ?? '')
const saving = ref(false)

/** Buscadores útiles, precargados con el origen y el destino de este tramo. */
const research = computed(() => {
  const a = encodeURIComponent(from.value || '')
  const b = encodeURIComponent(to.value || '')
  return [
    {
      label: 'Rome2Rio: qué opciones existen',
      url: `https://www.rome2rio.com/es/map/${a}/${b}`,
      hint: 'Para orientarte: combinaciones, duración y precio aproximado.',
    },
    {
      label: '12Go: horarios y reserva',
      url: `https://12go.asia/es/travel/${b}`,
      hint: 'Aquí sí se reserva. Compara operadores y horas de salida.',
    },
    {
      label: 'Google: opiniones del operador',
      url: `https://www.google.com/search?q=${a}+${b}+fast+boat+opiniones`,
      hint: 'Lo que Rome2Rio no te dice: fiabilidad y qué pasa si hay retraso.',
    },
  ]
})

async function save() {
  saving.value = true
  await tripStore.updateRoute(r.id, {
    from_label: from.value.trim() || null,
    to_label: to.value.trim() || null,
    mode: mode.value,
    date: date.value || null,
    status: status.value,
    cost_amount: cost.value,
    cost_currency: currency.value,
    operator: operator.value.trim() || null,
    risk_notes: riskNotes.value.trim() || null,
    notes: notes.value.trim() || null,
    ...(bookingUrl.value.trim() ? { booking_url: bookingUrl.value.trim() } : { booking_url: null }),
    ...(bookingRef.value.trim()
      ? { booking_reference: bookingRef.value.trim() }
      : { booking_reference: null }),
  } as Partial<TripRoute>)
  saving.value = false
  emit('close')
}
</script>

<template>
  <Sheet :title="`${from || '?'} → ${to || '?'}`" @close="emit('close')">
    <form class="space-y-4" @submit.prevent="save">
      <!-- Cómo investigarlo -->
      <section class="rounded bg-primary/5 p-3">
        <h3 class="flex items-center gap-1.5 text-sm font-semibold">
          <Search :size="14" /> Cómo mirarlo
        </h3>
        <ul class="mt-2 space-y-2">
          <li v-for="x in research" :key="x.label">
            <a
              :href="x.url"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1 text-sm text-primary underline"
            >
              <ExternalLink :size="13" /> {{ x.label }}
            </a>
            <p class="text-xs text-muted">{{ x.hint }}</p>
          </li>
        </ul>
      </section>

      <div class="grid grid-cols-2 gap-2">
        <div>
          <label class="block text-sm font-medium" :for="`from-${r.id}`">Desde</label>
          <input :id="`from-${r.id}`" v-model="from" class="tap mt-1 w-full rounded border border-line bg-surface px-2" />
        </div>
        <div>
          <label class="block text-sm font-medium" :for="`to-${r.id}`">Hasta</label>
          <input :id="`to-${r.id}`" v-model="to" class="tap mt-1 w-full rounded border border-line bg-surface px-2" />
        </div>
      </div>

      <div class="grid grid-cols-2 gap-2">
        <div>
          <label class="block text-sm font-medium" :for="`mode-${r.id}`">Medio</label>
          <select :id="`mode-${r.id}`" v-model="mode" class="tap mt-1 w-full rounded border border-line bg-surface px-2">
            <option v-for="(label, value) in MODE_LABEL" :key="value" :value="value">{{ label }}</option>
          </select>
        </div>
        <div>
          <label class="block text-sm font-medium" :for="`date-${r.id}`">Fecha</label>
          <input :id="`date-${r.id}`" v-model="date" type="date" class="tap mt-1 w-full rounded border border-line bg-surface px-2" />
        </div>
      </div>

      <div>
        <label class="block text-sm font-medium" :for="`st-${r.id}`">Estado</label>
        <select :id="`st-${r.id}`" v-model="status" class="tap mt-1 w-full rounded border border-line bg-surface px-2">
          <option value="idea">Idea</option>
          <option value="requiere_confirmacion">Por confirmar</option>
          <option value="reservada">Reservada</option>
          <option value="confirmada">Confirmada</option>
          <option value="en_riesgo">En riesgo</option>
          <option value="descartada">Descartada</option>
        </select>
      </div>

      <div class="grid grid-cols-2 gap-2">
        <div>
          <label class="block text-sm font-medium" :for="`cost-${r.id}`">Coste</label>
          <input :id="`cost-${r.id}`" v-model.number="cost" type="number" step="0.01" min="0" inputmode="decimal"
                 class="tap mt-1 w-full rounded border border-line bg-surface px-2" />
        </div>
        <div>
          <label class="block text-sm font-medium" :for="`cur-${r.id}`">Moneda</label>
          <select :id="`cur-${r.id}`" v-model="currency" class="tap mt-1 w-full rounded border border-line bg-surface px-2">
            <option>EUR</option>
            <option>IDR</option>
            <option>USD</option>
          </select>
        </div>
      </div>

      <div>
        <label class="block text-sm font-medium" :for="`op-${r.id}`">Operador</label>
        <input :id="`op-${r.id}`" v-model="operator" placeholder="Eka Jaya, Wahana, conductor…"
               class="tap mt-1 w-full rounded border border-line bg-surface px-2" />
      </div>

      <div>
        <label class="block text-sm font-medium" :for="`url-${r.id}`">Enlace de reserva</label>
        <input :id="`url-${r.id}`" v-model="bookingUrl" type="url" placeholder="https://…"
               class="tap mt-1 w-full rounded border border-line bg-surface px-2" />
      </div>

      <div>
        <label class="block text-sm font-medium" :for="`bref-${r.id}`">Localizador</label>
        <input :id="`bref-${r.id}`" v-model="bookingRef"
               class="tap mt-1 w-full rounded border border-line bg-surface px-2" />
      </div>

      <div>
        <label class="block text-sm font-medium" :for="`risk-${r.id}`">Qué hay que comprobar</label>
        <textarea :id="`risk-${r.id}`" v-model="riskNotes" rows="3"
                  class="mt-1 w-full rounded border border-line bg-surface p-2 text-sm" />
      </div>

      <div>
        <label class="block text-sm font-medium" :for="`n-${r.id}`">Notas</label>
        <textarea :id="`n-${r.id}`" v-model="notes" rows="2"
                  class="mt-1 w-full rounded border border-line bg-surface p-2 text-sm" />
      </div>

      <div class="flex gap-2">
        <button type="submit" :disabled="saving"
                class="tap flex-1 rounded bg-primary px-4 font-medium text-white disabled:opacity-60">
          {{ saving ? 'Guardando…' : 'Guardar' }}
        </button>
        <button type="button" class="tap rounded border border-line px-4" @click="emit('close')">
          Cancelar
        </button>
      </div>
    </form>

    <hr class="my-4 border-line" />
    <CommentThread entity-type="route" :entity-id="r.id" />
  </Sheet>
</template>
