<script setup lang="ts">
import { onMounted, onBeforeUnmount } from 'vue'
import { X } from 'lucide-vue-next'

defineProps<{ title: string }>()
const emit = defineEmits<{ close: [] }>()

function onKey(e: KeyboardEvent) {
  if (e.key === 'Escape') emit('close')
}

onMounted(() => {
  document.addEventListener('keydown', onKey)
  document.body.style.overflow = 'hidden'
})
onBeforeUnmount(() => {
  document.removeEventListener('keydown', onKey)
  document.body.style.overflow = ''
})
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-end sm:items-center sm:justify-center">
    <div class="absolute inset-0 bg-black/40" @click="emit('close')" />

    <!-- Hoja inferior en móvil, modal centrado en escritorio -->
    <div
      class="relative w-full sm:max-w-lg max-h-[88vh] overflow-y-auto bg-surface
             rounded-t-2xl sm:rounded-card shadow-card"
      role="dialog"
      aria-modal="true"
      :aria-label="title"
    >
      <header
        class="sticky top-0 flex items-center justify-between gap-3 border-b border-line
               bg-surface px-4 py-3"
      >
        <h2 class="font-semibold">{{ title }}</h2>
        <button class="tap -mr-2 px-2 text-muted" aria-label="Cerrar" @click="emit('close')">
          <X :size="20" />
        </button>
      </header>

      <div class="p-4" style="padding-bottom: calc(1rem + env(safe-area-inset-bottom))">
        <slot />
      </div>
    </div>
  </div>
</template>
