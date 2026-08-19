<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, RouterLink } from 'vue-router'
import { storeToRefs } from 'pinia'
import { ChevronRight, MapPin, CloudRain, Clock, Plus, ArrowRight } from 'lucide-vue-next'
import { useTripStore } from '@/stores/trip'
import { useCommentsStore } from '@/stores/comments'
import { formatMoney, perNight } from '@/lib/money'
import { formatRange, formatDate, nightsBetween } from '@/lib/dates'
import StatusBadge from '@/components/places/StatusBadge.vue'
import PlaceDetailSheet from '@/components/places/PlaceDetailSheet.vue'
import ActivitySheet from '@/components/places/ActivitySheet.vue'
import RouteSheet from '@/components/routes/RouteSheet.vue'
import CommentThread from '@/components/comments/CommentThread.vue'
import Cover from '@/components/ui/Cover.vue'
import { MODE_LABEL, ROUTE_STATUS_LABEL, type Place, type TripRoute } from '@/types/domain'

const route = useRoute()
const tripStore = useTripStore()
const comments = useCommentsStore()
const { zones, places, routes } = storeToRefs(tripStore)

const stayDetail = ref<Place | null>(null)
const activityDetail = ref<Place | null>(null)
const routeDetail = ref<TripRoute | null>(null)
const showOptions = ref(false)

const zone = computed(() => zones.value.find((z) => z.slug === route.params.slug))
const nights = computed(() =>
  zone.value ? nightsBetween(zone.value.start_date, zone.value.end_date) : null,
)

const zoneStays = computed(() =>
  places.value.filter((p) => p.kind === 'stay' && p.zone_id === zone.value?.id),
)
const chosen = computed(
  () => zoneStays.value.find((s) => s.status === 'reservado' || s.status === 'seleccionado') ?? null,
)
const options = computed(() =>
  zoneStays.value
    .filter((s) => s.id !== chosen.value?.id && s.status !== 'descartado')
    .sort((a, b) => (a.price_amount ?? 1e9) - (b.price_amount ?? 1e9)),
)

const zoneActivities = computed(() =>
  places.value
    .filter((p) => p.kind === 'activity' && p.zone_id === zone.value?.id && p.status !== 'descartado')
    .sort((a, b) => a.name.localeCompare(b.name)),
)

const arriving = computed(() =>
  routes.value.filter((r) => r.date === zone.value?.start_date && r.mode !== 'flight'),
)
const leaving = computed(() =>
  routes.value.filter((r) => r.date === zone.value?.end_date && r.mode !== 'flight'),
)

function hours(min: number | null | undefined) {
  if (!min) return null
  return min >= 60 ? `${Math.round((min / 60) * 10) / 10} h` : `${min} min`
}
</script>

<template>
  <div v-if="zone" class="space-y-5">
    <header>
      <RouterLink to="/" class="text-sm text-muted">‹ Volver al viaje</RouterLink>

      <div class="card mt-2 overflow-hidden">
        <Cover :src="zone.cover_image_url" kind="beach" height="h-40">
          <div class="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent" />
          <div class="absolute bottom-0 left-0 p-5 text-white">
            <h1 class="text-3xl font-bold leading-none drop-shadow">{{ zone.name }}</h1>
            <p class="mt-1 text-sm text-white/85 drop-shadow">
              {{ formatRange(zone.start_date, zone.end_date) }} · {{ nights }} noches
            </p>
          </div>
        </Cover>
        <p v-if="zone.notes" class="p-4 text-sm text-muted">{{ zone.notes }}</p>
      </div>
    </header>

    <!-- Dónde dormimos -->
    <section>
      <h2 class="section-title mb-3">Dónde dormimos</h2>

      <button v-if="chosen" class="card-tap w-full p-5 text-left" @click="stayDetail = chosen">
        <div class="flex items-start justify-between gap-3">
          <p class="font-medium">{{ chosen.name }}</p>
          <StatusBadge :status="chosen.status" />
        </div>
        <p class="mt-1 text-sm">
          <span class="font-semibold">{{ formatMoney(chosen.price_amount, chosen.price_currency ?? 'EUR') }}</span>
          <span v-if="perNight(chosen.price_amount, chosen.stay_details?.nights ?? null)" class="text-muted">
            · {{ formatMoney(perNight(chosen.price_amount, chosen.stay_details?.nights ?? null), chosen.price_currency ?? 'EUR') }}/noche
          </span>
        </p>
        <p v-if="chosen.stay_details?.cancellation_deadline" class="mt-1 text-xs text-muted">
          Cancelable hasta el {{ formatDate(chosen.stay_details.cancellation_deadline, 'd MMM') }}
        </p>
        <p class="mt-2 flex items-center gap-1 text-xs text-primary">
          Ver ficha completa <ChevronRight :size="13" />
        </p>
      </button>

      <div v-else class="card p-4">
        <p class="font-medium text-warn">Todavía sin decidir</p>
        <p class="mt-1 text-sm text-muted">Tenéis {{ options.length }} opción(es) guardadas.</p>
      </div>

      <button
        v-if="options.length"
        class="tap mt-2 w-full rounded border border-line px-3 text-sm text-muted"
        @click="showOptions = !showOptions"
      >
        {{ showOptions ? 'Ocultar' : 'Ver' }} las otras {{ options.length }} opciones
      </button>

      <ul v-if="showOptions" class="mt-2 space-y-2">
        <li v-for="s in options" :key="s.id">
          <button class="card-tap flex w-full items-center gap-3 p-4 text-left" @click="stayDetail = s">
            <span class="min-w-0 flex-1">
              <span class="block truncate text-sm font-medium">{{ s.name }}</span>
              <span class="block text-xs text-muted">
                {{ formatMoney(s.price_amount, s.price_currency ?? 'EUR') }}
                <template v-if="s.rating"> · {{ s.rating }}</template>
              </span>
            </span>
            <StatusBadge :status="s.status" />
          </button>
        </li>
      </ul>
    </section>

    <!-- Cómo llegamos y cómo salimos -->
    <section v-if="arriving.length || leaving.length">
      <h2 class="section-title mb-3">Cómo llegamos y salimos</h2>
      <ul class="space-y-2">
        <li v-for="r in [...arriving, ...leaving]" :key="r.id">
          <button class="card-tap w-full p-4 text-left" @click="routeDetail = r">
            <div class="flex items-start justify-between gap-3">
              <span class="min-w-0">
                <span class="block text-xs text-muted">
                  {{ formatDate(r.date, 'EEE d MMM') }} ·
                  {{ arriving.includes(r) ? 'llegada' : 'salida' }}
                </span>
                <span class="flex items-center gap-1 text-sm font-medium">
                  {{ r.from_label }} <ArrowRight :size="13" /> {{ r.to_label }}
                </span>
                <span class="text-xs text-muted">{{ MODE_LABEL[r.mode] }}</span>
              </span>
              <span
                class="chip shrink-0"
                :class="r.status === 'en_riesgo' ? 'bg-danger/15 text-danger'
                  : r.status === 'confirmada' || r.status === 'reservada' ? 'bg-ok/15 text-ok'
                  : 'bg-warn/15 text-warn'"
              >
                {{ ROUTE_STATUS_LABEL[r.status] }}
              </span>
            </div>
          </button>
        </li>
      </ul>
    </section>

    <!-- Qué hacemos -->
    <section>
      <div class="mb-2 flex items-center justify-between">
        <h2 class="section-title">Qué hacemos</h2>
        <RouterLink to="/places" class="tap inline-flex items-center gap-1 text-sm text-primary">
          <Plus :size="14" /> Añadir
        </RouterLink>
      </div>

      <ul v-if="zoneActivities.length" class="space-y-2">
        <li v-for="a in zoneActivities" :key="a.id">
          <button class="card-tap w-full p-4 text-left" @click="activityDetail = a">
            <div class="flex items-start justify-between gap-3">
              <p class="text-sm font-medium leading-tight">{{ a.name }}</p>
              <StatusBadge :status="a.status" />
            </div>
            <div class="mt-1.5 flex flex-wrap gap-1.5 text-xs">
              <span v-if="hours(a.activity_details?.duration_minutes)" class="chip bg-line/50 text-muted">
                <Clock :size="11" /> {{ hours(a.activity_details?.duration_minutes) }}
              </span>
              <span v-if="a.activity_details?.price_per_person" class="chip bg-line/50 text-muted">
                {{ formatMoney(a.activity_details.price_per_person) }} p.p.
              </span>
              <span v-if="a.activity_details?.weather_dependent" class="chip bg-warn/15 text-warn">
                <CloudRain :size="11" /> tiempo
              </span>
              <span v-if="a.activity_details?.booking_required" class="chip bg-accent/15 text-accent">
                reservar
              </span>
              <span v-if="comments.countFor('place', a.id)" class="chip bg-primary/10 text-primary">
                {{ comments.countFor('place', a.id) }} nota(s)
              </span>
            </div>
          </button>
        </li>
      </ul>
      <p v-else class="card p-4 text-center text-sm text-muted">
        Todavía no hay planes en {{ zone.name }}.
      </p>
    </section>

    <RouterLink
      :to="{ path: '/map', query: { zone: zone.slug } }"
      class="tap card flex items-center justify-center gap-2 p-3 text-sm font-medium text-primary"
    >
      <MapPin :size="16" /> Ver {{ zone.name }} en el mapa
    </RouterLink>

    <section class="card p-4">
      <CommentThread entity-type="zone" :entity-id="zone.id" />
    </section>

    <PlaceDetailSheet v-if="stayDetail" :place="stayDetail" @close="stayDetail = null" />
    <ActivitySheet v-if="activityDetail" :place="activityDetail" @close="activityDetail = null" />
    <RouteSheet v-if="routeDetail" :route="routeDetail" @close="routeDetail = null" />
  </div>

  <p v-else class="card p-6 text-center text-sm text-muted">Esa zona no existe.</p>
</template>
