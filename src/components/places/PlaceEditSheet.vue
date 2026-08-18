<script setup lang="ts">
import { ref, computed } from 'vue'
import Sheet from '@/components/ui/Sheet.vue'
import { useTripStore } from '@/stores/trip'
import { useExpensesStore } from '@/stores/expenses'
import type { Place, PlaceStatus } from '@/types/domain'
import { formatMoney } from '@/lib/money'

const props = defineProps<{ place: Place }>()
const emit = defineEmits<{ close: [] }>()

const tripStore = useTripStore()
const expenses = useExpensesStore()

const p = props.place
const d = p.stay_details

// Copias locales: no tocamos el store hasta que se pulsa Guardar.
const price = ref<number | null>(p.price_amount)
const currency = ref(p.price_currency ?? 'EUR')
const pending = ref(p.price_pending)
const checkedAt = ref(p.checked_at ?? new Date().toISOString().slice(0, 10))
const status = ref<PlaceStatus>(p.status)
const notes = ref(p.notes ?? '')
const roomType = ref(d?.room_type ?? '')
const breakfast = ref(d?.breakfast_included ?? false)
const freeCancel = ref(d?.free_cancellation ?? false)
const deadline = ref(d?.cancellation_deadline ? d.cancellation_deadline.slice(0, 10) : '')
const bookingRef = ref(d?.booking_reference ?? '')

const saving = ref(false)
const isStay = computed(() => p.kind === 'stay')

/** Gasto ya vinculado a este alojamiento, si existe. */
const linked = computed(() => expenses.items.find((e) => e.place_id === p.id) ?? null)

async function save() {
  saving.value = true

  await tripStore.updatePlace(p.id, {
    price_amount: price.value,
    price_currency: currency.value,
    price_pending: pending.value,
    checked_at: price.value === null ? null : checkedAt.value,
    status: status.value,
    notes: notes.value.trim() || null,
  })

  if (isStay.value && d) {
    await tripStore.updateStayDetails(p.id, {
      room_type: roomType.value.trim() || null,
      breakfast_included: breakfast.value,
      free_cancellation: freeCancel.value,
      cancellation_deadline: deadline.value ? `${deadline.value}T23:59:00+08:00` : null,
      booking_reference: bookingRef.value.trim() || null,
    })
  }

  // Si hay un gasto vinculado y el precio ha cambiado, se mantiene en sintonía.
  if (linked.value && price.value !== null && linked.value.amount !== price.value) {
    await expenses.update(linked.value.id, {
      amount: price.value,
      currency: currency.value,
      amount_eur: currency.value === 'EUR' ? price.value : null,
    })
  }

  saving.value = false
  emit('close')
}

/** Crea la partida de gasto de este alojamiento si todavía no existe. */
async function createExpense() {
  if (!tripStore.trip || price.value === null) return
  await expenses.create({
    trip_id: tripStore.trip.id,
    place_id: p.id,
    label: p.name,
    category: p.kind === 'stay' ? 'alojamiento' : 'actividad',
    amount: price.value,
    currency: currency.value,
    status: status.value === 'reservado' ? 'comprometido' : 'previsto',
  })
}
</script>

<template>
  <Sheet :title="p.name" @close="emit('close')">
    <form class="space-y-4" @submit.prevent="save">
      <div>
        <label class="block text-sm font-medium" :for="`price-${p.id}`">Precio total</label>
        <div class="mt-1 flex gap-2">
          <input
            :id="`price-${p.id}`"
            v-model.number="price"
            type="number"
            step="0.01"
            min="0"
            inputmode="decimal"
            placeholder="Sin precio"
            class="tap min-w-0 flex-1 rounded border border-line bg-surface px-3"
          />
          <select v-model="currency" class="tap rounded border border-line bg-surface px-2" aria-label="Moneda">
            <option>EUR</option>
            <option>IDR</option>
            <option>USD</option>
          </select>
        </div>
      </div>

      <div>
        <label class="block text-sm font-medium" :for="`checked-${p.id}`">Comprobado el</label>
        <input
          :id="`checked-${p.id}`"
          v-model="checkedAt"
          type="date"
          class="tap mt-1 w-full rounded border border-line bg-surface px-3"
        />
        <p class="mt-1 text-xs text-muted">Un precio sin fecha no dice nada. Pon cuándo lo viste.</p>
      </div>

      <label class="flex items-center gap-2 text-sm">
        <input v-model="pending" type="checkbox" class="h-4 w-4" />
        Precio por confirmar
      </label>

      <div>
        <label class="block text-sm font-medium" :for="`status-${p.id}`">Estado</label>
        <select
          :id="`status-${p.id}`"
          v-model="status"
          class="tap mt-1 w-full rounded border border-line bg-surface px-3"
        >
          <option value="idea">Idea</option>
          <option value="candidato">Candidato</option>
          <option value="favorito">Favorito</option>
          <option value="seleccionado">Seleccionado (decidido, sin reservar)</option>
          <option value="reservado">Reservado</option>
          <option value="realizado">Realizado</option>
          <option value="descartado">Descartado</option>
        </select>
      </div>

      <template v-if="isStay && d">
        <hr class="border-line" />

        <div>
          <label class="block text-sm font-medium" :for="`room-${p.id}`">Habitación</label>
          <input
            :id="`room-${p.id}`"
            v-model="roomType"
            class="tap mt-1 w-full rounded border border-line bg-surface px-3"
          />
        </div>

        <label class="flex items-center gap-2 text-sm">
          <input v-model="breakfast" type="checkbox" class="h-4 w-4" />
          Desayuno incluido
        </label>

        <label class="flex items-center gap-2 text-sm">
          <input v-model="freeCancel" type="checkbox" class="h-4 w-4" />
          Cancelación gratuita
        </label>

        <div v-if="freeCancel">
          <label class="block text-sm font-medium" :for="`dl-${p.id}`">Cancelar antes del</label>
          <input
            :id="`dl-${p.id}`"
            v-model="deadline"
            type="date"
            class="tap mt-1 w-full rounded border border-line bg-surface px-3"
          />
        </div>

        <div>
          <label class="block text-sm font-medium" :for="`ref-${p.id}`">Localizador</label>
          <input
            :id="`ref-${p.id}`"
            v-model="bookingRef"
            placeholder="Referencia de la reserva"
            class="tap mt-1 w-full rounded border border-line bg-surface px-3"
          />
        </div>
      </template>

      <div>
        <label class="block text-sm font-medium" :for="`notes-${p.id}`">Notas</label>
        <textarea
          :id="`notes-${p.id}`"
          v-model="notes"
          rows="4"
          class="mt-1 w-full rounded border border-line bg-surface p-3 text-sm"
        />
      </div>

      <hr class="border-line" />

      <div v-if="linked" class="rounded bg-line/30 p-3 text-sm">
        <p class="font-medium">Gasto vinculado</p>
        <p class="text-muted">
          {{ formatMoney(linked.amount, linked.currency) }} ·
          {{ linked.status === 'pagado' ? 'pagado' : 'sin pagar' }}
        </p>
        <button
          type="button"
          class="tap mt-2 rounded border border-line px-3 text-sm"
          @click="expenses.togglePaid(linked!.id)"
        >
          {{ linked.status === 'pagado' ? 'Marcar como no pagado' : 'Marcar como pagado' }}
        </button>
      </div>
      <button
        v-else-if="price !== null"
        type="button"
        class="tap w-full rounded border border-line px-3 text-sm"
        @click="createExpense"
      >
        Crear su gasto en el presupuesto
      </button>

      <div class="flex gap-2 pt-2">
        <button
          type="submit"
          :disabled="saving"
          class="tap flex-1 rounded bg-primary px-4 font-medium text-white disabled:opacity-60"
        >
          {{ saving ? 'Guardando…' : 'Guardar' }}
        </button>
        <button type="button" class="tap rounded border border-line px-4" @click="emit('close')">
          Cancelar
        </button>
      </div>
    </form>
  </Sheet>
</template>
