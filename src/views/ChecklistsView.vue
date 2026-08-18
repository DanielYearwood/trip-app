<script setup lang="ts">
import { ref, computed } from 'vue'
import { storeToRefs } from 'pinia'
import { Check, ExternalLink, Plus, Trash2, Link2 } from 'lucide-vue-next'
import { useChecklistsStore } from '@/stores/checklists'
import { useTripStore } from '@/stores/trip'
import CommentThread from '@/components/comments/CommentThread.vue'

const checklists = useChecklistsStore()
const tripStore = useTripStore()
const { lists, pendingCount } = storeToRefs(checklists)

const addingTo = ref<string | null>(null)
const newLabel = ref('')
const newUrl = ref('')
const editingUrlFor = ref<string | null>(null)
const urlDraft = ref('')

const total = computed(() => checklists.items.length)
const done = computed(() => checklists.items.filter((i) => i.done).length)

async function submit(listId: string) {
  if (!newLabel.value.trim() || !tripStore.trip) return
  await checklists.add(listId, tripStore.trip.id, newLabel.value.trim(), newUrl.value.trim() || null)
  newLabel.value = ''
  newUrl.value = ''
  addingTo.value = null
}

function startUrl(id: string, current: string | null) {
  editingUrlFor.value = id
  urlDraft.value = current ?? ''
}

async function saveUrl(id: string) {
  await checklists.setUrl(id, urlDraft.value.trim() || null)
  editingUrlFor.value = null
}
</script>

<template>
  <div class="space-y-4">
    <header>
      <h1 class="text-lg font-semibold">Cosas por hacer</h1>
      <p class="text-sm text-muted">{{ done }} de {{ total }} hechas · {{ pendingCount }} pendientes</p>
      <div v-if="total" class="mt-2 h-2 overflow-hidden rounded-full bg-line">
        <div class="h-full bg-ok" :style="{ width: `${(done / total) * 100}%` }" />
      </div>
    </header>

    <section v-for="l in lists" :key="l.id" class="card p-4">
      <div class="flex items-center justify-between gap-2">
        <h2 class="font-semibold">{{ l.name }}</h2>
        <button
          class="tap inline-flex items-center gap-1 rounded border border-line px-2 text-sm"
          @click="addingTo = addingTo === l.id ? null : l.id"
        >
          <Plus :size="14" /> Añadir
        </button>
      </div>

      <form v-if="addingTo === l.id" class="mt-3 space-y-2" @submit.prevent="submit(l.id)">
        <input
          v-model="newLabel"
          required
          placeholder="Qué hay que hacer"
          class="tap w-full rounded border border-line bg-surface px-3 text-sm"
        />
        <input
          v-model="newUrl"
          type="url"
          placeholder="Enlace (opcional): web para reservar, comparar…"
          class="tap w-full rounded border border-line bg-surface px-3 text-sm"
        />
        <button type="submit" class="tap w-full rounded bg-primary px-3 text-sm text-white">
          Añadir tarea
        </button>
      </form>

      <ul class="mt-3 space-y-2">
        <li v-for="it in checklists.itemsOf(l.id)" :key="it.id" class="flex items-start gap-2.5">
          <button
            class="tap mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded border-2"
            :class="it.done ? 'border-ok bg-ok text-white' : 'border-line text-transparent'"
            :aria-label="it.done ? `Desmarcar ${it.label}` : `Marcar ${it.label} como hecho`"
            @click="checklists.toggle(it.id)"
          >
            <Check :size="12" />
          </button>

          <div class="min-w-0 flex-1">
            <p class="text-sm" :class="it.done ? 'text-muted line-through' : ''">{{ it.label }}</p>

            <div class="mt-0.5 flex flex-wrap items-center gap-2">
              <a
                v-if="it.url"
                :href="it.url"
                target="_blank"
                rel="noopener noreferrer"
                class="inline-flex items-center gap-1 text-xs text-primary underline"
              >
                <ExternalLink :size="12" /> Abrir enlace
              </a>
              <button
                class="inline-flex items-center gap-1 text-xs text-muted hover:text-ink"
                @click="startUrl(it.id, it.url)"
              >
                <Link2 :size="12" /> {{ it.url ? 'Cambiar' : 'Poner enlace' }}
              </button>
              <button
                class="text-xs text-muted hover:text-danger"
                :aria-label="`Borrar ${it.label}`"
                @click="checklists.remove(it.id)"
              >
                <Trash2 :size="12" />
              </button>
            </div>

            <div v-if="editingUrlFor === it.id" class="mt-1 flex gap-2">
              <input
                v-model="urlDraft"
                type="url"
                placeholder="https://…"
                class="tap min-w-0 flex-1 rounded border border-line bg-surface px-2 text-sm"
                @keyup.enter="saveUrl(it.id)"
              />
              <button class="tap rounded bg-primary px-3 text-sm text-white" @click="saveUrl(it.id)">
                Guardar
              </button>
            </div>
          </div>
        </li>
      </ul>
    </section>

    <section class="card p-4">
      <CommentThread v-if="tripStore.trip" entity-type="trip" :entity-id="tripStore.trip.id" />
    </section>
  </div>
</template>
