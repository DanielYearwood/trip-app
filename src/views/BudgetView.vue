<script setup lang="ts">
import { computed, ref } from 'vue'
import { storeToRefs } from 'pinia'
import { Check, Plus, Trash2 } from 'lucide-vue-next'
import { useTripStore } from '@/stores/trip'
import { useExpensesStore } from '@/stores/expenses'
import { formatMoney, perPerson, toEur } from '@/lib/money'
import Sheet from '@/components/ui/Sheet.vue'
import type { ExpenseCategory } from '@/types/domain'

const tripStore = useTripStore()
const expenses = useExpensesStore()
const { trip, zones, stays, chosenStayByZone, fxRate } = storeToRefs(tripStore)
const { active, previsto, pagado, pendiente, porCategoria, sinConvertir } = storeToRefs(expenses)

const CATEGORIES: { value: ExpenseCategory; label: string }[] = [
  { value: 'alojamiento', label: 'Alojamiento' },
  { value: 'transporte_internacional', label: 'Vuelos' },
  { value: 'transporte_local', label: 'Transporte en destino' },
  { value: 'actividad', label: 'Actividades' },
  { value: 'comida', label: 'Comida' },
  { value: 'compras', label: 'Compras' },
  { value: 'tasas_visado', label: 'Visado y tasas' },
  { value: 'seguro', label: 'Seguro' },
  { value: 'salud', label: 'Salud' },
  { value: 'otros', label: 'Otros' },
]
const catLabel = (c: ExpenseCategory) => CATEGORIES.find((x) => x.value === c)?.label ?? c

// --- Alta rápida de gasto ---
const adding = ref(false)
const form = ref({ label: '', amount: null as number | null, category: 'otros' as ExpenseCategory, paid: false })

async function submit() {
  if (!trip.value || !form.value.label.trim() || form.value.amount === null) return
  const created = await expenses.create({
    trip_id: trip.value.id,
    label: form.value.label.trim(),
    category: form.value.category,
    amount: form.value.amount,
  })
  if (created && form.value.paid) await expenses.togglePaid(created.id)
  form.value = { label: '', amount: null, category: 'otros', paid: false }
  adding.value = false
}

// --- Simulador de lo que falta por decidir ---
const openZones = computed(() =>
  zones.value
    .filter((z) => !chosenStayByZone.value[z.id])
    .map((z) => ({
      zone: z,
      options: stays.value
        .filter((s) => s.zone_id === z.id && s.status !== 'descartado' && s.price_amount !== null)
        .map((s) => ({ ...s, eur: toEur(s.price_amount, s.price_currency, fxRate.value) ?? 0 }))
        .sort((a, b) => a.eur - b.eur),
    }))
    .filter((g) => g.options.length),
)

const cheapestExtra = computed(() =>
  openZones.value.reduce((acc, g) => acc + (g.options[0]?.eur ?? 0), 0),
)

const porPersona = computed(() => perPerson(previsto.value, trip.value?.travellers ?? 2))
</script>

<template>
  <div class="space-y-4">
    <header class="flex items-center gap-2">
      <h1 class="mr-auto text-lg font-semibold">Dinero</h1>
      <button
        class="tap inline-flex items-center gap-1 rounded bg-primary px-3 text-sm text-white"
        @click="adding = true"
      >
        <Plus :size="16" /> Gasto
      </button>
    </header>

    <!-- Resumen -->
    <section class="card p-4">
      <p class="text-sm text-muted">Previsto en total</p>
      <p class="text-3xl font-semibold">{{ formatMoney(previsto) }}</p>
      <p class="text-sm text-muted">{{ formatMoney(porPersona) }} por persona</p>

      <div class="mt-4 grid grid-cols-2 gap-3 text-sm">
        <div class="rounded bg-ok/10 p-3">
          <p class="text-muted">Pagado</p>
          <p class="text-lg font-semibold text-ok">{{ formatMoney(pagado) }}</p>
        </div>
        <div class="rounded bg-warn/10 p-3">
          <p class="text-muted">Pendiente</p>
          <p class="text-lg font-semibold text-warn">{{ formatMoney(pendiente) }}</p>
        </div>
      </div>

      <div v-if="previsto > 0" class="mt-3 h-2 overflow-hidden rounded-full bg-line">
        <div class="h-full bg-ok" :style="{ width: `${Math.min(100, (pagado / previsto) * 100)}%` }" />
      </div>

      <p v-if="sinConvertir" class="mt-3 text-xs text-warn">
        {{ sinConvertir }} gasto(s) en moneda extranjera sin conversión: no entran en el total.
      </p>
    </section>

    <!-- Por categoría -->
    <section v-if="porCategoria.length" class="card p-4">
      <h2 class="font-semibold">Por categoría</h2>
      <ul class="mt-2 space-y-1 text-sm">
        <li v-for="[cat, v] in porCategoria" :key="cat" class="flex justify-between gap-3">
          <span class="text-muted">{{ catLabel(cat) }}</span>
          <span class="tabular-nums">{{ formatMoney(v.total) }}</span>
        </li>
      </ul>
    </section>

    <!-- Lista de gastos -->
    <section>
      <h2 class="mb-2 font-semibold">Gastos</h2>
      <ul class="space-y-2">
        <li v-for="e in active" :key="e.id" class="card flex items-start gap-3 p-3">
          <button
            class="tap mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full border-2"
            :class="e.status === 'pagado' ? 'border-ok bg-ok text-white' : 'border-line text-transparent'"
            :aria-label="e.status === 'pagado' ? `Marcar ${e.label} como no pagado` : `Marcar ${e.label} como pagado`"
            @click="expenses.togglePaid(e.id)"
          >
            <Check :size="14" />
          </button>

          <div class="min-w-0 flex-1">
            <p class="text-sm font-medium leading-tight">{{ e.label }}</p>
            <p class="text-xs text-muted">
              {{ catLabel(e.category) }}
              <span v-if="e.status === 'pagado'" class="text-ok">· pagado</span>
              <span v-else-if="e.status === 'comprometido'" class="text-warn">· reservado sin pagar</span>
            </p>
          </div>

          <div class="shrink-0 text-right">
            <p class="text-sm font-semibold tabular-nums">
              {{ formatMoney(e.amount_eur ?? e.amount, 'EUR') }}
            </p>
            <p v-if="e.currency !== 'EUR'" class="text-xs text-muted">
              {{ formatMoney(e.amount, e.currency) }}
            </p>
            <button
              class="tap text-xs text-muted hover:text-danger"
              :aria-label="`Borrar ${e.label}`"
              @click="expenses.remove(e.id)"
            >
              <Trash2 :size="14" />
            </button>
          </div>
        </li>
      </ul>

      <p v-if="!active.length" class="card p-6 text-center text-sm text-muted">
        Todavía no hay gastos. Añade el primero con el botón de arriba.
      </p>
    </section>

    <!-- Simulador -->
    <section v-if="openZones.length" class="card p-4">
      <h2 class="font-semibold">Lo que falta por decidir</h2>
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
              {{ formatMoney(o.eur) }}
              <span v-if="i > 0 && g.options[0]" class="text-xs">
                (+{{ formatMoney(o.eur - g.options[0]!.eur) }})
              </span>
            </span>
          </li>
        </ul>
      </div>

      <p class="mt-4 border-t border-line pt-3 text-sm">
        Con la opción más barata de lo que queda:
        <strong>{{ formatMoney(previsto + cheapestExtra) }}</strong>
      </p>
    </section>

    <!-- Alta de gasto -->
    <Sheet v-if="adding" title="Nuevo gasto" @close="adding = false">
      <form class="space-y-4" @submit.prevent="submit">
        <div>
          <label class="block text-sm font-medium" for="lbl">Concepto</label>
          <input
            id="lbl"
            v-model="form.label"
            required
            placeholder="Cena, fast boat, entrada…"
            class="tap mt-1 w-full rounded border border-line bg-surface px-3"
          />
        </div>
        <div>
          <label class="block text-sm font-medium" for="amt">Importe (€)</label>
          <input
            id="amt"
            v-model.number="form.amount"
            type="number"
            step="0.01"
            min="0"
            inputmode="decimal"
            required
            class="tap mt-1 w-full rounded border border-line bg-surface px-3"
          />
        </div>
        <div>
          <label class="block text-sm font-medium" for="cat">Categoría</label>
          <select
            id="cat"
            v-model="form.category"
            class="tap mt-1 w-full rounded border border-line bg-surface px-3"
          >
            <option v-for="c in CATEGORIES" :key="c.value" :value="c.value">{{ c.label }}</option>
          </select>
        </div>
        <label class="flex items-center gap-2 text-sm">
          <input v-model="form.paid" type="checkbox" class="h-4 w-4" />
          Ya está pagado
        </label>
        <button type="submit" class="tap w-full rounded bg-primary px-4 font-medium text-white">
          Añadir
        </button>
      </form>
    </Sheet>
  </div>
</template>
