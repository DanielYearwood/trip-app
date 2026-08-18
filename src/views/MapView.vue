<script setup lang="ts">
import { onMounted, onBeforeUnmount, ref, computed, watch } from 'vue'
import { storeToRefs } from 'pinia'
import type { Map as LeafletMap, LayerGroup } from 'leaflet'
import { useTripStore } from '@/stores/trip'
import { supabase, errorMessage } from '@/lib/supabase'
import { KIND_LABEL, type Place, type PlaceKind } from '@/types/domain'
import { gmapsLink, parseCoords } from '@/lib/maps'

const tripStore = useTripStore()
const { places, zones, unlocated } = storeToRefs(tripStore)

const el = ref<HTMLDivElement | null>(null)
const mapError = ref<string | null>(null)
const placing = ref<Place | null>(null)
const pasteValue = ref('')

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

const located = computed(() =>
  places.value.filter((p) => p.lat !== null && p.lng !== null && p.status !== 'descartado'),
)

function markerIcon(p: Place) {
  const dimmed = p.status === 'idea' || p.status === 'candidato'
  return L!.divIcon({
    className: '',
    html: `<span style="display:block;width:16px;height:16px;border-radius:50%;
      background:${COLOR[p.kind]};border:2px solid #fff;opacity:${dimmed ? 0.65 : 1};
      box-shadow:0 1px 4px rgba(0,0,0,.4)"></span>`,
    iconSize: [16, 16],
    iconAnchor: [8, 8],
  })
}

function render() {
  if (!map || !layer || !L) return
  layer.clearLayers()
  for (const p of located.value) {
    L.marker([p.lat!, p.lng!], { icon: markerIcon(p), title: p.name })
      .bindPopup(
        `<strong>${p.name}</strong><br><span style="color:#6B7280">${KIND_LABEL[p.kind]}</span><br>
         <a href="${gmapsLink(p.lat!, p.lng!)}" target="_blank" rel="noopener">Abrir en Google Maps</a>`,
      )
      .addTo(layer)
  }
  if (located.value.length) {
    map.fitBounds(L.latLngBounds(located.value.map((p) => [p.lat!, p.lng!] as [number, number])), {
      padding: [40, 40],
      maxZoom: 14,
    })
  }
}

async function savePin(p: Place, lat: number, lng: number) {
  const { error } = await supabase
    .from('places')
    .update({ lat, lng, geocode_source: 'manual' })
    .eq('id', p.id)
  if (error) {
    mapError.value = errorMessage(error)
    return
  }
  const local = places.value.find((x) => x.id === p.id)
  if (local) {
    local.lat = lat
    local.lng = lng
  }
  placing.value = null
  pasteValue.value = ''
  render()
}

function applyPasted() {
  if (!placing.value) return
  const coords = parseCoords(pasteValue.value)
  if (!coords) {
    mapError.value = 'No he podido leer coordenadas de ese texto. Prueba con "-8.5069, 115.2625".'
    return
  }
  mapError.value = null
  savePin(placing.value, coords.lat, coords.lng)
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
  } catch (e) {
    mapError.value = errorMessage(e)
  }
})

onBeforeUnmount(() => {
  map?.remove()
  map = null
})

watch(located, render)

function centerOn(slug: string) {
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
        @click="centerOn(z.slug)"
      >
        {{ z.name }}
      </button>
    </header>

    <p v-if="mapError" class="card border-danger/40 p-3 text-sm text-danger">{{ mapError }}</p>

    <div
      v-if="placing"
      class="card border-primary/50 p-3 text-sm"
      role="status"
    >
      <p class="font-medium">Colocando: {{ placing.name }}</p>
      <p class="mt-1 text-muted">Toca el mapa donde esté, o pega sus coordenadas.</p>
      <div class="mt-2 flex gap-2">
        <input
          v-model="pasteValue"
          placeholder="-8.5069, 115.2625"
          class="tap min-w-0 flex-1 rounded border border-line bg-surface px-2"
          @keyup.enter="applyPasted"
        />
        <button class="tap rounded bg-primary px-3 text-white" @click="applyPasted">Guardar</button>
        <button class="tap rounded border border-line px-3" @click="placing = null">Cancelar</button>
      </div>
    </div>

    <div ref="el" class="h-[60vh] w-full rounded-card border border-line" />

    <section v-if="unlocated.length" class="card p-4">
      <h2 class="font-semibold">Falta ubicar ({{ unlocated.length }})</h2>
      <p class="mt-1 text-sm text-muted">
        Estos elementos no tienen coordenadas todavía. Elige uno y colócalo en el mapa.
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
  </div>
</template>
