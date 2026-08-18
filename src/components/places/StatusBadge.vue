<script setup lang="ts">
import { computed } from 'vue'
import { STATUS_LABEL, type PlaceStatus } from '@/types/domain'

const props = defineProps<{ status: PlaceStatus }>()

// El color nunca es el único portador de información: siempre lleva texto.
const classes: Record<PlaceStatus, string> = {
  idea: 'bg-line/60 text-muted',
  candidato: 'bg-accent/15 text-accent',
  favorito: 'bg-danger/10 text-danger',
  seleccionado: 'bg-sea/15 text-sea',
  planificado: 'bg-sea/15 text-sea',
  reservado: 'bg-ok/15 text-ok',
  realizado: 'bg-ok/10 text-ok',
  descartado: 'bg-line/40 text-muted line-through',
}

const cls = computed(() => classes[props.status])
const label = computed(() => STATUS_LABEL[props.status])
</script>

<template>
  <span class="chip" :class="cls">{{ label }}</span>
</template>
