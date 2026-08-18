<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ExternalLink, MapPin, Navigation, Pencil, Star, Phone } from 'lucide-vue-next'
import Sheet from '@/components/ui/Sheet.vue'
import StatusBadge from './StatusBadge.vue'
import PlaceEditSheet from './PlaceEditSheet.vue'
import CommentThread from '@/components/comments/CommentThread.vue'
import { useTripStore } from '@/stores/trip'
import { formatMoney, perNight } from '@/lib/money'
import { formatRange, formatDate } from '@/lib/dates'
import { gmapsLink, directionsLink } from '@/lib/maps'
import { KIND_LABEL, type Place } from '@/types/domain'

const props = defineProps<{ place: Place }>()
const emit = defineEmits<{ close: [] }>()

const router = useRouter()
const tripStore = useTripStore()
const editing = ref(false)

const p = computed(() => tripStore.places.find((x) => x.id === props.place.id) ?? props.place)
const d = computed(() => p.value.stay_details)
const located = computed(() => p.value.lat !== null && p.value.lng !== null)
const approx = computed(() => p.value.geocode_source === 'calle_aproximada')
const unverified = computed(() => p.value.geocode_source === 'nominatim_por_verificar')

function showOnMap() {
  emit('close')
  router.push({ path: '/map', query: { focus: p.value.id } })
}
</script>

<template>
  <Sheet :title="p.name" @close="emit('close')">
    <div class="space-y-4">
      <div class="flex flex-wrap items-center gap-2">
        <StatusBadge :status="p.status" />
        <span class="chip bg-line/50 text-muted">{{ KIND_LABEL[p.kind] }}</span>
        <span class="chip bg-line/50 text-muted">{{ tripStore.zoneName(p.zone_id) }}</span>
      </div>

      <!-- Precio -->
      <div>
        <p class="text-2xl font-semibold">
          {{ formatMoney(p.price_amount, p.price_currency ?? 'EUR') }}
        </p>
        <p v-if="perNight(p.price_amount, d?.nights ?? null)" class="text-sm text-muted">
          {{ formatMoney(perNight(p.price_amount, d?.nights ?? null)) }} por noche ·
          {{ d?.nights }} noches
        </p>
        <p class="mt-1 flex flex-wrap gap-1.5 text-xs">
          <span v-if="p.price_pending" class="chip bg-warn/15 text-warn">precio por confirmar</span>
          <span v-if="p.checked_at" class="chip bg-line/50 text-muted">
            comprobado el {{ formatDate(p.checked_at, 'd MMM yyyy') }}
          </span>
        </p>
      </div>

      <!-- Estancia -->
      <dl v-if="d" class="grid grid-cols-2 gap-x-3 gap-y-2 text-sm">
        <div v-if="d.check_in">
          <dt class="text-xs text-muted">Fechas</dt>
          <dd>{{ formatRange(d.check_in, d.check_out) }}</dd>
        </div>
        <div v-if="d.room_type">
          <dt class="text-xs text-muted">Habitación</dt>
          <dd>{{ d.room_type }}<span v-if="d.room_size_m2"> · {{ d.room_size_m2 }} m²</span></dd>
        </div>
        <div v-if="d.pool">
          <dt class="text-xs text-muted">Piscina</dt>
          <dd>{{ d.pool }}</dd>
        </div>
        <div v-if="d.breakfast_included !== null">
          <dt class="text-xs text-muted">Desayuno</dt>
          <dd>{{ d.breakfast_included ? 'Incluido' : 'No incluido' }}</dd>
        </div>
        <div v-if="d.free_cancellation">
          <dt class="text-xs text-muted">Cancelación</dt>
          <dd :class="d.cancellation_deadline ? '' : 'text-warn'">
            {{ d.cancellation_deadline
              ? `Gratis hasta el ${formatDate(d.cancellation_deadline, 'd MMM')}`
              : 'Gratis, falta la fecha límite' }}
          </dd>
        </div>
        <div v-if="d.booking_reference">
          <dt class="text-xs text-muted">Localizador</dt>
          <dd class="font-mono text-xs">{{ d.booking_reference }}</dd>
        </div>
      </dl>

      <!-- Valoración -->
      <p v-if="p.rating" class="flex items-center gap-1 text-sm">
        <Star :size="14" class="text-accent" />
        <strong>{{ p.rating }}</strong>
        <span v-if="p.rating_count" class="text-muted">· {{ p.rating_count }} opiniones</span>
        <span v-if="p.location_rating" class="text-muted">· ubicación {{ p.location_rating }}</span>
      </p>

      <p v-if="p.notes" class="whitespace-pre-wrap rounded bg-line/25 p-3 text-sm">{{ p.notes }}</p>

      <div v-if="p.pros.length || p.cons.length" class="space-y-0.5 text-sm">
        <p v-for="x in p.pros" :key="x" class="text-ok">+ {{ x }}</p>
        <p v-for="x in p.cons" :key="x" class="text-danger">− {{ x }}</p>
      </div>

      <p v-if="p.address" class="text-sm text-muted">{{ p.address }}</p>

      <!-- Ubicación -->
      <div>
        <p v-if="approx" class="mb-2 text-xs text-warn">
          Ubicación aproximada: es la calle, no el hotel exacto. Ábrelo en el mapa y arrastra el
          pin, o pega el enlace de Google Maps.
        </p>
        <p v-else-if="unverified" class="mb-2 text-xs text-muted">
          Ubicación automática sin verificar. Compruébala antes de fiarte.
        </p>
        <p v-else-if="!located" class="mb-2 text-xs text-warn">
          Todavía sin ubicar en el mapa.
        </p>

        <div class="flex flex-wrap gap-2">
          <button
            class="tap inline-flex items-center gap-1 rounded border border-line px-3 text-sm"
            @click="showOnMap"
          >
            <MapPin :size="14" /> {{ located ? 'Ver en el mapa' : 'Ubicar en el mapa' }}
          </button>
          <a
            v-if="located"
            :href="gmapsLink(p.lat!, p.lng!)"
            target="_blank"
            rel="noopener noreferrer"
            class="tap inline-flex items-center gap-1 rounded border border-line px-3 text-sm"
          >
            <ExternalLink :size="14" /> Google Maps
          </a>
          <a
            v-if="located"
            :href="directionsLink(null, { lat: p.lat!, lng: p.lng! }, 'walking')"
            target="_blank"
            rel="noopener noreferrer"
            class="tap inline-flex items-center gap-1 rounded border border-line px-3 text-sm"
          >
            <Navigation :size="14" /> Cómo llegar
          </a>
          <a
            v-if="p.booking_url"
            :href="p.booking_url"
            target="_blank"
            rel="noopener noreferrer"
            class="tap inline-flex items-center gap-1 rounded border border-line px-3 text-sm"
          >
            <ExternalLink :size="14" /> Booking
          </a>
          <a
            v-if="p.phone"
            :href="`tel:${p.phone.replace(/\s/g, '')}`"
            class="tap inline-flex items-center gap-1 rounded border border-line px-3 text-sm"
          >
            <Phone :size="14" /> Llamar
          </a>
          <button
            class="tap inline-flex items-center gap-1 rounded bg-primary px-3 text-sm text-white"
            @click="editing = true"
          >
            <Pencil :size="14" /> Editar
          </button>
        </div>
      </div>

      <hr class="border-line" />

      <CommentThread entity-type="place" :entity-id="p.id" />
    </div>

    <PlaceEditSheet v-if="editing" :place="p" @close="editing = false" />
  </Sheet>
</template>
