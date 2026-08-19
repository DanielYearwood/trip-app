<script setup lang="ts">
import { ref, computed } from 'vue'
import { Bed, Mountain, Waves, Ship, Utensils, Camera, ShoppingBag, MapPin } from 'lucide-vue-next'
import type { PlaceKind } from '@/types/domain'

const props = withDefaults(
  defineProps<{
    src?: string | null
    kind?: PlaceKind
    /** Alto de la imagen. Las tarjetas de lista usan uno más bajo. */
    height?: string
  }>(),
  { src: null, kind: 'other', height: 'h-40' },
)

// Si la URL está rota, caemos al degradado en vez de dejar el hueco roto.
const failed = ref(false)
const showImage = computed(() => Boolean(props.src) && !failed.value)

const ICON: Record<PlaceKind, unknown> = {
  stay: Bed,
  activity: Mountain,
  beach: Waves,
  transport: Ship,
  food: Utensils,
  viewpoint: Camera,
  shopping: ShoppingBag,
  health: MapPin,
  other: MapPin,
}
</script>

<template>
  <div class="relative overflow-hidden" :class="height">
    <img
      v-if="showImage"
      :src="src!"
      alt=""
      loading="lazy"
      class="h-full w-full object-cover transition duration-700 hover:scale-105"
      @error="failed = true"
    />
    <div v-else class="cover-fallback h-full w-full">
      <component :is="ICON[kind]" :size="28" class="text-primary/40" />
    </div>
    <slot />
  </div>
</template>
