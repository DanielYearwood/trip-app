<script setup lang="ts">
import { computed, ref } from 'vue'
import { storeToRefs } from 'pinia'
import { CloudRain, Clock, Plus, CalendarClock, ExternalLink, ChevronRight } from 'lucide-vue-next'
import { useTripStore } from '@/stores/trip'
import { useCommentsStore } from '@/stores/comments'
import { useAuthStore } from '@/stores/auth'
import { supabase, errorMessage } from '@/lib/supabase'
import { formatMoney } from '@/lib/money'
import { formatDate } from '@/lib/dates'
import StatusBadge from '@/components/places/StatusBadge.vue'
import Cover from '@/components/ui/Cover.vue'
import ActivitySheet from '@/components/places/ActivitySheet.vue'
import Sheet from '@/components/ui/Sheet.vue'
import type { Place } from '@/types/domain'

const tripStore = useTripStore()
const comments = useCommentsStore()
const auth = useAuthStore()
const { zones, activities } = storeToRefs(tripStore)

const detail = ref<Place | null>(null)
const zoneFilter = ref<string | 'all'>('all')
const onlyBooking = ref(false)
const onlyRainSafe = ref(false)
const showDiscarded = ref(false)

const adding = ref(false)
const form = ref({ name: '', zone_id: '' as string, notes: '' })
const creating = ref(false)
const createError = ref<string | null>(null)

const RANK: Record<string, number> = {
  reservado: 0, planificado: 1, favorito: 2, candidato: 3, idea: 4, realizado: 5, descartado: 6,
}

const visible = computed(() =>
  activities.value
    .filter((a) => showDiscarded.value || a.status !== 'descartado')
    .filter((a) => zoneFilter.value === 'all' || a.zone_id === zoneFilter.value)
    .filter((a) => !onlyBooking.value || a.activity_details?.booking_required)
    .filter((a) => !onlyRainSafe.value || a.activity_details?.weather_dependent === false)
    .sort((a, b) => (RANK[a.status] ?? 9) - (RANK[b.status] ?? 9) || a.name.localeCompare(b.name)),
)

const grouped = computed(() => {
  const byZone = zones.value.map((z) => ({
    name: z.name,
    items: visible.value.filter((a) => a.zone_id === z.id),
  }))
  const general = visible.value.filter((a) => !a.zone_id)
  return [...byZone, { name: 'Cualquier zona', items: general }].filter((g) => g.items.length)
})

const needBooking = computed(
  () => activities.value.filter((a) => a.activity_details?.booking_required && a.status !== 'reservado' && a.status !== 'descartado').length,
)

function hours(min: number | null | undefined) {
  if (!min) return null
  return min >= 60 ? `${Math.round((min / 60) * 10) / 10} h` : `${min} min`
}

async function createActivity() {
  if (!tripStore.trip || !form.value.name.trim()) return
  creating.value = true
  createError.value = null

  const { data, error } = await supabase
    .from('places')
    .insert({
      trip_id: tripStore.trip.id,
      zone_id: form.value.zone_id || null,
      name: form.value.name.trim(),
      kind: 'activity',
      status: 'idea',
      notes: form.value.notes.trim() || null,
      created_by: auth.user?.id ?? null,
    })
    .select()
    .single()

  if (error) {
    createError.value = errorMessage(error)
    creating.value = false
    return
  }

  // La ficha de detalle es una fila aparte; sin ella no se pueden guardar
  // duración, precio ni reserva.
  await supabase.from('activity_details').insert({ place_id: data.id, people: tripStore.trip.travellers })
  await tripStore.load()

  form.value = { name: '', zone_id: '', notes: '' }
  adding.value = false
  creating.value = false
}
</script>

<template>
  <div class="space-y-4">
    <header class="flex flex-wrap items-center gap-2">
      <h1 class="mr-auto text-2xl font-bold">Planes</h1>
      <button
        class="tap inline-flex items-center gap-1 rounded bg-primary px-3 text-sm text-white"
        @click="adding = true"
      >
        <Plus :size="16" /> Añadir
      </button>
    </header>

    <p v-if="needBooking" class="card flex items-start gap-2 p-3 text-sm">
      <CalendarClock :size="16" class="mt-0.5 shrink-0 text-warn" />
      <span><strong>{{ needBooking }}</strong> plan(es) necesitan reserva previa y todavía no están reservados.</span>
    </p>

    <!-- Filtros -->
    <div class="flex flex-wrap gap-2 text-sm">
      <select v-model="zoneFilter" class="tap rounded border border-line bg-surface px-2" aria-label="Filtrar por zona">
        <option value="all">Todas las zonas</option>
        <option v-for="z in zones" :key="z.id" :value="z.id">{{ z.name }}</option>
      </select>
      <button
        class="tap rounded border px-2"
        :class="onlyBooking ? 'border-primary text-primary' : 'border-line text-muted'"
        @click="onlyBooking = !onlyBooking"
      >
        Hay que reservar
      </button>
      <button
        class="tap rounded border px-2"
        :class="onlyRainSafe ? 'border-primary text-primary' : 'border-line text-muted'"
        @click="onlyRainSafe = !onlyRainSafe"
      >
        Valen con lluvia
      </button>
      <button
        class="tap rounded border border-line px-2 text-muted"
        @click="showDiscarded = !showDiscarded"
      >
        {{ showDiscarded ? 'Ocultar' : 'Ver' }} descartados
      </button>
    </div>

    <section v-for="g in grouped" :key="g.name">
      <h2 class="mb-2 text-sm font-semibold text-muted">{{ g.name }}</h2>
      <ul class="space-y-2">
        <li v-for="a in g.items" :key="a.id">
          <button
            class="card-tap w-full overflow-hidden text-left"
            :class="a.status === 'descartado' ? 'opacity-50' : ''"
            @click="detail = a"
          >
            <Cover :src="a.cover_image_url" kind="activity" height="h-28">
              <span class="absolute right-3 top-3">
                <StatusBadge :status="a.status" />
              </span>
            </Cover>

            <div class="p-4">
              <p class="font-display text-base font-semibold leading-tight tracking-tightest">
                {{ a.name }}
              </p>
              <p v-if="a.category" class="text-xs text-muted">{{ a.category }}</p>

            <div class="mt-2 flex flex-wrap items-center gap-1.5 text-xs">
              <span v-if="hours(a.activity_details?.duration_minutes)" class="chip bg-line/50 text-muted">
                <Clock :size="12" /> {{ hours(a.activity_details?.duration_minutes) }}
              </span>
              <span v-if="a.activity_details?.price_per_person" class="chip bg-line/50 text-muted">
                {{ formatMoney(a.activity_details.price_per_person) }} p.p.
              </span>
              <span v-if="a.activity_details?.weather_dependent" class="chip bg-warn/15 text-warn">
                <CloudRain :size="12" /> depende del tiempo
              </span>
              <span v-if="a.activity_details?.booking_required" class="chip bg-accent/15 text-accent">
                hay que reservar
              </span>
              <span v-if="a.activity_details?.booking_deadline" class="chip bg-danger/10 text-danger">
                antes del {{ formatDate(a.activity_details.booking_deadline, 'd MMM') }}
              </span>
              <span v-for="t in a.tags" :key="t" class="chip bg-line/40 text-muted">{{ t }}</span>
            </div>

            <p v-if="a.notes" class="mt-2 text-sm text-muted">{{ a.notes }}</p>

            <p class="mt-2 flex items-center gap-1 text-xs text-primary">
              Abrir y planificar <ChevronRight :size="13" />
              <span v-if="comments.countFor('place', a.id)" class="text-muted">
                · {{ comments.countFor('place', a.id) }} nota(s)
              </span>
            </p>
            </div>
          </button>
        </li>
      </ul>
    </section>

    <p v-if="!grouped.length" class="card p-6 text-center text-sm text-muted">
      No hay planes con esos filtros.
    </p>

    <!-- Fuentes fiables -->
    <section class="card p-4">
      <h2 class="font-semibold">Dónde buscar y reservar</h2>
      <p class="mt-1 text-sm text-muted">
        Dentro de cada plan tienes estos mismos buscadores ya rellenados con su nombre.
      </p>
      <ul class="mt-2 space-y-2 text-sm">
        <li>
          <a href="https://www.getyourguide.es/bali-l373/" target="_blank" rel="noopener noreferrer"
             class="inline-flex items-center gap-1 text-primary underline">
            <ExternalLink :size="13" /> GetYourGuide · Bali
          </a>
          <p class="text-xs text-muted">La más fiable en cancelaciones: normalmente gratis hasta 24 h antes.</p>
        </li>
        <li>
          <a href="https://www.klook.com/es/city/62-bali-things-to-do/" target="_blank" rel="noopener noreferrer"
             class="inline-flex items-center gap-1 text-primary underline">
            <ExternalLink :size="13" /> Klook · Bali
          </a>
          <p class="text-xs text-muted">Muy fuerte en Asia y suele salir más barata. Comparad con GetYourGuide.</p>
        </li>
        <li>
          <a href="https://www.viator.com/es-ES/Bali/d95" target="_blank" rel="noopener noreferrer"
             class="inline-flex items-center gap-1 text-primary underline">
            <ExternalLink :size="13" /> Viator · Bali
          </a>
          <p class="text-xs text-muted">Catálogo enorme pero calidad irregular: mirad opiniones antes.</p>
        </li>
        <li>
          <a href="https://www.magicseaweed.com" target="_blank" rel="noopener noreferrer"
             class="inline-flex items-center gap-1 text-primary underline">
            <ExternalLink :size="13" /> Windy y estado del mar
          </a>
          <p class="text-xs text-muted">Para el snorkel de Gili y para los días de barco.</p>
        </li>
      </ul>
      <p class="mt-3 text-xs text-muted">
        Enlazo a los buscadores y no a tours concretos a propósito: precios y disponibilidad cambian
        constantemente, y un enlace fijo os daría una información falsa dentro de dos semanas.
      </p>
    </section>

    <ActivitySheet v-if="detail" :place="detail" @close="detail = null" />

    <Sheet v-if="adding" title="Nuevo plan" @close="adding = false">
      <form class="space-y-4" @submit.prevent="createActivity">
        <div>
          <label class="block text-sm font-medium" for="an">Qué es</label>
          <input id="an" v-model="form.name" required placeholder="Clase de surf, cena en…, mercado de…"
                 class="tap mt-1 w-full rounded border border-line bg-surface px-3" />
        </div>
        <div>
          <label class="block text-sm font-medium" for="az">Zona</label>
          <select id="az" v-model="form.zone_id" class="tap mt-1 w-full rounded border border-line bg-surface px-3">
            <option value="">Cualquiera</option>
            <option v-for="z in zones" :key="z.id" :value="z.id">{{ z.name }}</option>
          </select>
        </div>
        <div>
          <label class="block text-sm font-medium" for="anotes">Notas</label>
          <textarea id="anotes" v-model="form.notes" rows="3"
                    class="mt-1 w-full rounded border border-line bg-surface p-2 text-sm" />
        </div>
        <p v-if="createError" class="text-sm text-danger">{{ createError }}</p>
        <button type="submit" :disabled="creating"
                class="tap w-full rounded bg-primary px-4 font-medium text-white disabled:opacity-60">
          {{ creating ? 'Creando…' : 'Añadir plan' }}
        </button>
      </form>
    </Sheet>
  </div>
</template>
