<script setup lang="ts">
import { onMounted, onBeforeUnmount, ref, computed, watch } from 'vue'
import { storeToRefs } from 'pinia'
import { useRoute, useRouter } from 'vue-router'
import type { Map as LeafletMap, LayerGroup } from 'leaflet'
import { useTripStore } from '@/stores/trip'
import { useCommentsStore } from '@/stores/comments'
import { errorMessage } from '@/lib/supabase'
import { KIND_LABEL, STATUS_LABEL, type Place, type PlaceKind, type PlaceStatus } from '@/types/domain'
import { parseCoords } from '@/lib/maps'
import { formatMoney } from '@/lib/money'
import PlaceDetailSheet from '@/components/places/PlaceDetailSheet.vue'

const tripStore = useTripStore()
const comments = useCommentsStore()
const { places, zones, unlocated } = storeToRefs(tripStore)
const route = useRoute()
const router = useRouter()

const el = ref<HTMLDivElement | null>(null)
const mapError = ref<string | null>(null)
const placing = ref<Place | null>(null)
const selected = ref<Place | null>(null)
const pasteValue = ref('')

const kindFilter = ref<PlaceKind | 'all'>('all')
const zoneFilter = ref<string | 'all'>('all')
const statusFilter = ref<PlaceStatus | 'all'>('all')

let map: LeafletMap | null = null
let layer: LayerGroup | null = null
let L: typeof import('leaflet') | null = null

const COLOR: Record<PlaceKind, string> = {
  stay: '#8B5CF6',
  activity: '#16A34A',
  food: '#F59E0B',
  beach: '#06B6D4',
  transport: '#3B82F6',
  health: '#DC2626',
  shopping: '#EAB308',
  viewpoint: '#EC4899',
  other: '#6B7280',
}

/** Solo se ofrecen los tipos que existen de verdad en el viaje. */
const availableKinds = computed(() => {
  const set = new Set<PlaceKind>()
  places.value.forEach((p) => {
    if (p.lat !== null && p.status !== 'descartado') set.add(p.kind)
  })
  return [...set].sort()
})

const visible = computed(() =>
  places.value
    .filter((p) => p.lat !== null && p.lng !== null && p.status !== 'descartado')
    .filter((p) => kindFilter.value === 'all' || p.kind === kindFilter.value)
    .filter((p) => zoneFilter.value === 'all' || p.zone_id === zoneFilter.value)
    .filter((p) => statusFilter.value === 'all' || p.status === statusFilter.value)
    .sort((a, b) => a.kind.localeCompare(b.kind) || a.name.localeCompare(b.name)),
)

function markerIcon(p: Place) {
  const dim = p.status === 'idea' || p.status === 'candidato'
  const dashed = p.geocode_source === 'calle_aproximada'
  const size = selected.value?.id === p.id ? 22 : 16
  return L!.divIcon({
    className: '',
    html: `<span style="display:block;width:${size}px;height:${size}px;border-radius:50%;
      background:${COLOR[p.kind]};border:${dashed ? '2px dashed' : '2px solid'} #fff;
      opacity:${dim ? 0.6 : 1};box-shadow:0 1px 4px rgba(0,0,0,.45)"></span>`,
    iconSize: [size, size],
    iconAnchor: [size / 2, size / 2],
  })
}

function render() {
  if (!map || !layer || !L) return
  layer.clearLayers()
  for (const p of visible.value) {
    L.marker([p.lat!, p.lng!], { icon: markerIcon(p), title: p.name })
      .on('click', () => (selected.value = p))
      .addTo(layer)
  }
}

function fitAll() {
  if (!map || !L || !visible.value.length) return
  map.fitBounds(L.latLngBounds(visible.value.map((p) => [p.lat!, p.lng!] as [number, number])), {
    padding: [40, 40],
    maxZoom: 14,
  })
}

async function savePin(p: Place, lat: number, lng: number) {
  const ok = await tripStore.updatePlace(p.id, { lat, lng, geocode_source: 'manual' })
  if (!ok) return
  placing.value = null
  pasteValue.value = ''
  render()
}

function applyPasted() {
  if (!placing.value) return
  const coords = parseCoords(pasteValue.value)
  if (!coords) {
    mapError.value =
      'No he podido leer coordenadas de ahí. Prueba con "-8.5069, 115.2625" o pega el enlace de Google Maps.'
    return
  }
  mapError.value = null
  savePin(placing.value, coords.lat, coords.lng)
}

/** Desde el listado: centra el mapa y abre la ficha. */
function pick(p: Place) {
  selected.value = p
  if (map && p.lat !== null && p.lng !== null) map.setView([p.lat, p.lng], 16)
}

onMounted(async () => {
  try {
    L = await import('leaflet')
    await import('leaflet/dist/leaflet.css')
    if (!el.value) return

    map = L.map(el.value, { zoomControl: true }).setView([-8.5, 115.5], 8)
    L.tileLayer(
      import.meta.env.VITE_MAP_TILE_URL ?? 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      {
        attribution: import.meta.env.VITE_MAP_TILE_ATTRIBUTION ?? '&copy; OpenStreetMap',
        maxZoom: 19,
      },
    ).addTo(map)

    layer = L.layerGroup().addTo(map)
    map.on('click', (e: { latlng: { lat: number; lng: number } }) => {
      if (placing.value) savePin(placing.value, e.latlng.lat, e.latlng.lng)
    })

    render()

    const wantedZone = route.query.zone as string | undefined
    if (wantedZone) {
      const z = zones.value.find((x) => x.slug === wantedZone)
      if (z) {
        zoneFilter.value = z.id
        if (z.center_lat && z.center_lng) map.setView([z.center_lat, z.center_lng], 13)
        router.replace({ path: '/map' })
        return
      }
    }

    const wanted = route.query.focus as string | undefined
    const target = wanted ? places.value.find((p) => p.id === wanted) : null
    if (target?.lat != null) {
      pick(target)
      router.replace({ path: '/map' })
    } else if (target) {
      placing.value = target
      router.replace({ path: '/map' })
    } else {
      fitAll()
    }
  } catch (e) {
    mapError.value = errorMessage(e)
  }
})

onBeforeUnmount(() => {
  map?.remove()
  map = null
})

watch([visible, selected], render)

function centerOnZone(slug: string) {
  const z = zones.value.find((x) => x.slug === slug)
  if (z?.center_lat && z?.center_lng && map) map.setView([z.center_lat, z.center_lng], 13)
}
</script>

<template>
  <div class="space-y-3">
    <header class="flex flex-wrap items-center gap-2">
      <h1 class="mr-auto text-lg font-semibold">Mapa</h1>
      <button
        v-for="z in zones"
        :key="z.id"
        class="tap rounded border border-line px-2 text-sm"
        @click="centerOnZone(z.slug)"
      >
        {{ z.name }}
      </button>
      <button class="tap rounded border border-line px-2 text-sm" @click="fitAll">Ver todo</button>
    </header>

    <!-- Filtros -->
    <div class="space-y-2">
      <div class="flex flex-wrap items-center gap-1.5 text-xs">
        <button
          class="chip border"
          :class="kindFilter === 'all' ? 'border-primary text-primary' : 'border-line text-muted'"
          @click="kindFilter = 'all'"
        >
          Todo
        </button>
        <button
          v-for="k in availableKinds"
          :key="k"
          class="chip border"
          :class="kindFilter === k ? 'border-primary text-primary' : 'border-line text-muted'"
          @click="kindFilter = k"
        >
          <span class="inline-block h-2.5 w-2.5 rounded-full" :style="{ background: COLOR[k] }" />
          {{ KIND_LABEL[k] }}
        </button>
      </div>

      <div class="flex flex-wrap gap-2">
        <select
          v-model="zoneFilter"
          class="tap rounded border border-line bg-surface px-2 text-sm"
          aria-label="Filtrar por zona"
        >
          <option value="all">Todas las zonas</option>
          <option v-for="z in zones" :key="z.id" :value="z.id">{{ z.name }}</option>
        </select>
        <select
          v-model="statusFilter"
          class="tap rounded border border-line bg-surface px-2 text-sm"
          aria-label="Filtrar por estado"
        >
          <option value="all">Cualquier estado</option>
          <option value="reservado">Reservado</option>
          <option value="seleccionado">Seleccionado</option>
          <option value="favorito">Favorito</option>
          <option value="candidato">Candidato</option>
          <option value="idea">Idea</option>
        </select>
      </div>
    </div>

    <p v-if="mapError" class="card border-danger/40 p-3 text-sm text-danger">{{ mapError }}</p>

    <div v-if="placing" class="card border-primary/50 p-3 text-sm" role="status">
      <p class="font-medium">Colocando: {{ placing.name }}</p>
      <p class="mt-1 text-muted">Toca el mapa donde esté, o pega el enlace de Google Maps.</p>
      <div class="mt-2 flex gap-2">
        <input
          v-model="pasteValue"
          placeholder="Enlace de Google Maps o -8.5069, 115.2625"
          class="tap min-w-0 flex-1 rounded border border-line bg-surface px-2"
          @keyup.enter="applyPasted"
        />
        <button class="tap rounded bg-primary px-3 text-white" @click="applyPasted">Guardar</button>
        <button class="tap rounded border border-line px-3" @click="placing = null">Cancelar</button>
      </div>
    </div>

    <!-- Mapa + listado lateral -->
    <div class="grid gap-3 lg:grid-cols-[1fr_20rem]">
      <div ref="el" class="h-[55vh] w-full rounded-card border border-line lg:h-[70vh]" />

      <aside class="lg:h-[70vh] lg:overflow-y-auto">
        <p class="mb-2 text-sm font-semibold">
          En el mapa <span class="font-normal text-muted">({{ visible.length }})</span>
        </p>

        <ul class="space-y-2">
          <li v-for="p in visible" :key="p.id">
            <button
              class="card flex w-full items-start gap-2.5 p-2.5 text-left hover:border-primary/50"
              :class="selected?.id === p.id ? 'border-primary' : ''"
              @click="pick(p)"
            >
              <span
                class="mt-1 h-3 w-3 shrink-0 rounded-full"
                :style="{ background: COLOR[p.kind] }"
              />
              <span class="min-w-0 flex-1">
                <span class="block truncate text-sm font-medium">{{ p.name }}</span>
                <span class="block text-xs text-muted">
                  {{ KIND_LABEL[p.kind] }} · {{ STATUS_LABEL[p.status] }}
                  <template v-if="p.price_amount !== null">
                    · {{ formatMoney(p.price_amount, p.price_currency ?? 'EUR') }}
                  </template>
                </span>
                <span
                  v-if="comments.countFor('place', p.id)"
                  class="mt-0.5 inline-block text-xs text-primary"
                >
                  {{ comments.countFor('place', p.id) }} nota(s)
                </span>
              </span>
            </button>
          </li>
        </ul>

        <p v-if="!visible.length" class="card p-4 text-center text-sm text-muted">
          Nada que mostrar con esos filtros.
        </p>
      </aside>
    </div>

    <section v-if="unlocated.length" class="card p-4">
      <h2 class="font-semibold">Falta ubicar ({{ unlocated.length }})</h2>
      <p class="mt-1 text-sm text-muted">
        OpenStreetMap no conoce estos sitios. Elige uno y toca el mapa, o pega su enlace de Google
        Maps.
      </p>
      <ul class="mt-2 flex flex-wrap gap-2">
        <li v-for="p in unlocated" :key="p.id">
          <button
            class="tap rounded border border-line px-2 text-sm"
            :class="placing?.id === p.id ? 'border-primary text-primary' : ''"
            @click="placing = p"
          >
            {{ p.name }}
          </button>
        </li>
      </ul>
    </section>

    <PlaceDetailSheet v-if="selected" :place="selected" @close="selected = null" />
  </div>
</template>
