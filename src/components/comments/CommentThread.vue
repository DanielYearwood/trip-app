<script setup lang="ts">
import { ref, computed } from 'vue'
import { Trash2 } from 'lucide-vue-next'
import { useCommentsStore } from '@/stores/comments'
import { useAuthStore } from '@/stores/auth'
import { useTripStore } from '@/stores/trip'

const props = defineProps<{ entityType: string; entityId: string }>()

const comments = useCommentsStore()
const auth = useAuthStore()
const tripStore = useTripStore()

const draft = ref('')
const sending = ref(false)

const thread = computed(() => comments.forEntity(props.entityType, props.entityId))

function when(iso: string) {
  const mins = Math.round((Date.now() - new Date(iso).getTime()) / 60000)
  if (mins < 1) return 'ahora'
  if (mins < 60) return `hace ${mins} min`
  const h = Math.round(mins / 60)
  if (h < 24) return `hace ${h} h`
  return `hace ${Math.round(h / 24)} d`
}

async function submit() {
  if (!draft.value.trim() || !tripStore.trip || sending.value) return
  sending.value = true
  await comments.add(tripStore.trip.id, props.entityType, props.entityId, draft.value)
  draft.value = ''
  sending.value = false
}
</script>

<template>
  <section>
    <h3 class="text-sm font-semibold">
      Notas<span v-if="thread.length" class="text-muted"> ({{ thread.length }})</span>
    </h3>

    <ul v-if="thread.length" class="mt-2 space-y-2">
      <li v-for="c in thread" :key="c.id" class="rounded bg-line/30 p-2.5 text-sm">
        <div class="flex items-baseline justify-between gap-2">
          <span class="text-xs font-medium">{{ comments.authorName(c.author_id) }}</span>
          <span class="text-xs text-muted">{{ when(c.created_at) }}</span>
        </div>
        <p class="mt-1 whitespace-pre-wrap">{{ c.body }}</p>
        <button
          v-if="c.author_id === auth.user?.id"
          class="tap mt-1 text-xs text-muted hover:text-danger"
          :aria-label="'Borrar nota'"
          @click="comments.remove(c.id)"
        >
          <Trash2 :size="13" />
        </button>
      </li>
    </ul>
    <p v-else class="mt-2 text-sm text-muted">Todavía no hay notas aquí.</p>

    <form class="mt-2 flex gap-2" @submit.prevent="submit">
      <textarea
        v-model="draft"
        rows="2"
        placeholder="Escribe una nota…"
        class="min-w-0 flex-1 rounded border border-line bg-surface p-2 text-sm"
        @keydown.ctrl.enter="submit"
      />
      <button
        type="submit"
        :disabled="!draft.trim() || sending"
        class="tap self-end rounded bg-primary px-3 text-sm text-white disabled:opacity-50"
      >
        Añadir
      </button>
    </form>
  </section>
</template>
