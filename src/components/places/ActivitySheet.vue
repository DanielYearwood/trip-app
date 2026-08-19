<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { ExternalLink, MapPin, Search, CloudRain } from 'lucide-vue-next'
import Sheet from '@/components/ui/Sheet.vue'
import CommentThread from '@/components/comments/CommentThread.vue'
import { useTripStore } from '@/stores/trip'
import { gmapsLink } from '@/lib/maps'
import type { Place, PlaceStatus } from '@/types/domain'

const props = defineProps<{ place: Place }>()
const emit = defineEmits<{ close: [] }>()

const router = useRouter()
const tripStore = useTripStore()
const p = props.place
const d = p.activity_details

const status = ref<PlaceStatus>(p.status)
const notes = ref(p.notes ?? '')
const cover = ref(p.cover_image_url ?? '')
const url = ref(p.website_url ?? '')
const duration = ref<number | null>(d?.duration_minutes ?? null)
const pricePerson = ref<number | null>(d?.price_per_person ?? null)
const weather = ref(d?.weather_dependent ?? false)
const needsBooking = ref(d?.booking_required ?? false)
const deadline = ref(d?.booking_deadline ?? '')
const provider = ref(d?.provider ?? '')
const whatToBring = ref(d?.what_to_bring ?? '')
const saving = ref(false)

/**
 * Buscadores fiables ya rellenados con el nombre de la actividad.
 * No enlazamos a un tour concreto porque los precios y la disponibilidad
 * cambian: se enlaza a la búsqueda para que la comprobéis vosotros.
 */
const links = computed(() => {
  const q = encodeURIComponent(p.name)
  const short = encodeURIComponent(p.name.split(':')[0]!.split('(')[0]!.trim())
  return [
    {
      label: 'GetYourGuide',
      url: `https://www.getyourguide.es/s/?q=${short}`,
      hint: 'Cancelación gratuita habitual hasta 24 h antes. Suele ser la más fiable.',
    },
    {
      label: 'Klook',
      url: `https://www.klook.com/es/search/?query=${short}`,
      hint: 'Muy fuerte en Asia. Precios a menudo más bajos que las demás.',
    },
    {
      label: 'Viator',
      url: `https://www.viator.com/es-ES/searchResults/all?text=${short}`,
      hint: 'Catálogo enorme, calidad más irregular. Mirad las opiniones.',
    },
    {
      label: 'Opiniones y consejos',
      url: `https://www.google.com/search?q=${q}+Bali+opiniones+consejos`,
      hint: 'Lo que no sale en las plataformas: mejor hora, si merece la pena, timos.',
    },
  ]
})

async function save() {
  saving.value = true
  await tripStore.updatePlace(p.id, {
    status: status.value,
    notes: notes.value.trim() || null,
    website_url: url.value.trim() || null,
    cover_image_url: cover.value.trim() || null,
  })
  if (d) {
    await tripStore.updateActivityDetails(p.id, {
      duration_minutes: duration.value,
      price_per_person: pricePerson.value,
      weather_dependent: weather.value,
      booking_required: needsBooking.value,
      booking_deadline: deadline.value || null,
      provider: provider.value.trim() || null,
      what_to_bring: whatToBring.value.trim() || null,
    })
  }
  saving.value = false
  emit('close')
}

function showOnMap() {
  emit('close')
  router.push({ path: '/map', query: { focus: p.id } })
}
</script>

<template>
  <Sheet :title="p.name" @close="emit('close')">
    <div class="space-y-4">
      <!-- Dónde mirarlo -->
      <section class="rounded bg-primary/5 p-3">
        <h3 class="flex items-center gap-1.5 text-sm font-semibold">
          <Search :size="14" /> Dónde mirarlo y reservarlo
        </h3>
        <ul class="mt-2 space-y-2">
          <li v-for="l in links" :key="l.label">
            <a
              :href="l.url"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1 text-sm text-primary underline"
            >
              <ExternalLink :size="13" /> {{ l.label }}
            </a>
            <p class="text-xs text-muted">{{ l.hint }}</p>
          </li>
        </ul>
      </section>

      <div class="flex flex-wrap gap-2">
        <button
          class="tap inline-flex items-center gap-1 rounded border border-line px-3 text-sm"
          @click="showOnMap"
        >
          <MapPin :size="14" /> {{ p.lat !== null ? 'Ver en el mapa' : 'Ubicar en el mapa' }}
        </button>
        <a
          v-if="p.lat !== null && p.lng !== null"
          :href="gmapsLink(p.lat, p.lng)"
          target="_blank"
          rel="noopener noreferrer"
          class="tap inline-flex items-center gap-1 rounded border border-line px-3 text-sm"
        >
          <ExternalLink :size="14" /> Google Maps
        </a>
      </div>

      <form class="space-y-4" @submit.prevent="save">
        <div>
          <label class="block text-sm font-medium" :for="`st-${p.id}`">Estado</label>
          <select
            :id="`st-${p.id}`"
            v-model="status"
            class="tap mt-1 w-full rounded border border-line bg-surface px-3"
          >
            <option value="idea">Idea suelta</option>
            <option value="candidato">Nos interesa</option>
            <option value="favorito">Lo queremos hacer</option>
            <option value="planificado">Planificado</option>
            <option value="reservado">Reservado</option>
            <option value="realizado">Hecho</option>
            <option value="descartado">Descartado</option>
          </select>
        </div>

        <div class="grid grid-cols-2 gap-2">
          <div>
            <label class="block text-sm font-medium" :for="`dur-${p.id}`">Duración (min)</label>
            <input
              :id="`dur-${p.id}`"
              v-model.number="duration"
              type="number"
              min="0"
              step="15"
              inputmode="numeric"
              class="tap mt-1 w-full rounded border border-line bg-surface px-2"
            />
          </div>
          <div>
            <label class="block text-sm font-medium" :for="`pp-${p.id}`">€ por persona</label>
            <input
              :id="`pp-${p.id}`"
              v-model.number="pricePerson"
              type="number"
              min="0"
              step="0.01"
              inputmode="decimal"
              class="tap mt-1 w-full rounded border border-line bg-surface px-2"
            />
          </div>
        </div>

        <label class="flex items-center gap-2 text-sm">
          <input v-model="weather" type="checkbox" class="h-4 w-4" />
          Depende del tiempo
        </label>

        <label class="flex items-center gap-2 text-sm">
          <input v-model="needsBooking" type="checkbox" class="h-4 w-4" />
          Hay que reservar con antelación
        </label>

        <div v-if="needsBooking">
          <label class="block text-sm font-medium" :for="`dl-${p.id}`">Reservar antes del</label>
          <input
            :id="`dl-${p.id}`"
            v-model="deadline"
            type="date"
            class="tap mt-1 w-full rounded border border-line bg-surface px-2"
          />
        </div>

        <div>
          <label class="block text-sm font-medium" :for="`pv-${p.id}`">Proveedor</label>
          <input
            :id="`pv-${p.id}`"
            v-model="provider"
            placeholder="Con quién lo hacemos"
            class="tap mt-1 w-full rounded border border-line bg-surface px-2"
          />
        </div>

        <div>
          <label class="block text-sm font-medium" :for="`u-${p.id}`">Enlace guardado</label>
          <input
            :id="`u-${p.id}`"
            v-model="url"
            type="url"
            placeholder="https://…"
            class="tap mt-1 w-full rounded border border-line bg-surface px-2"
          />
        </div>

        <div>
          <label class="block text-sm font-medium" :for="`wb-${p.id}`">Qué llevar</label>
          <input
            :id="`wb-${p.id}`"
            v-model="whatToBring"
            placeholder="Calzado, bañador, efectivo…"
            class="tap mt-1 w-full rounded border border-line bg-surface px-2"
          />
        </div>

        <div>
          <label class="block text-sm font-medium" :for="`cv-${p.id}`">Foto (URL)</label>
          <input
            :id="`cv-${p.id}`"
            v-model="cover"
            type="url"
            placeholder="https://…"
            class="tap mt-1 w-full rounded border border-line bg-surface px-2"
          />
        </div>

        <div>
          <label class="block text-sm font-medium" :for="`n-${p.id}`">Notas</label>
          <textarea
            :id="`n-${p.id}`"
            v-model="notes"
            rows="3"
            class="mt-1 w-full rounded border border-line bg-surface p-2 text-sm"
          />
        </div>

        <p v-if="weather" class="flex items-start gap-1.5 rounded bg-warn/10 p-2 text-xs text-warn">
          <CloudRain :size="14" class="mt-0.5 shrink-0" />
          Depende del tiempo: conviene tener un plan alternativo para ese día.
        </p>

        <div class="flex gap-2">
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

      <hr class="border-line" />
      <CommentThread entity-type="place" :entity-id="p.id" />
    </div>
  </Sheet>
</template>
