<script setup lang="ts">
import { computed, ref } from 'vue'
import { storeToRefs } from 'pinia'
import { useTripStore } from '@/stores/trip'
import StatusBadge from '@/components/places/StatusBadge.vue'

const tripStore = useTripStore()
const { zones, activities } = storeToRefs(tripStore)

const tagFilter = ref<string | 'all'>('all')

const allTags = computed(() => {
  const set = new Set<string>()
  activities.value.forEach((a) => a.tags.forEach((t) => set.add(t)))
  return [...set].sort()
})

const visible = computed(() =>
  activities.value.filter(
    (a) => a.status !== 'descartado' && (tagFilter.value === 'all' || a.tags.includes(tagFilter.value)),
  ),
)

const grouped = computed(() => {
  const withZone = zones.value.map((z) => ({
    name: z.name,
    items: visible.value.filter((a) => a.zone_id === z.id),
  }))
  const general = visible.value.filter((a) => !a.zone_id)
  return [...withZone, { name: 'Cualquier zona', items: general }].filter((g) => g.items.length)
})
</script>

<template>
  <div class="space-y-4">
    <header class="flex flex-wrap items-center gap-2">
      <h1 class="mr-auto text-lg font-semibold">Actividades y lugares</h1>
      <select
        v-model="tagFilter"
        class="tap rounded border border-line bg-surface px-2 text-sm"
        aria-label="Filtrar por etiqueta"
      >
        <option value="all">Todas</option>
        <option v-for="t in allTags" :key="t" :value="t">{{ t }}</option>
      </select>
    </header>

    <section v-for="g in grouped" :key="g.name">
      <h2 class="mb-2 text-sm font-semibold text-muted">{{ g.name }}</h2>
      <ul class="space-y-2">
        <li v-for="a in g.items" :key="a.id" class="card p-3">
          <div class="flex items-start justify-between gap-3">
            <div class="min-w-0">
              <p class="font-medium leading-tight">{{ a.name }}</p>
              <p v-if="a.category" class="text-xs text-muted">{{ a.category }}</p>
            </div>
            <StatusBadge :status="a.status" />
          </div>
          <p v-if="a.notes" class="mt-1 text-sm text-muted">{{ a.notes }}</p>
          <div v-if="a.tags.length" class="mt-2 flex flex-wrap gap-1">
            <span v-for="t in a.tags" :key="t" class="chip bg-line/50 text-muted">{{ t }}</span>
          </div>
        </li>
      </ul>
    </section>

    <p v-if="!grouped.length" class="card p-6 text-center text-sm text-muted">
      No hay actividades con ese filtro.
    </p>
  </div>
</template>
