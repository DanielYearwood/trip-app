<script setup lang="ts">
import { RouterLink } from 'vue-router'
</script>

<template>
  <div class="min-h-screen flex flex-col items-center justify-center p-6 text-center">
    <p class="text-5xl">🏝️</p>
    <h1 class="mt-4 text-xl font-semibold">Esta página no existe</h1>
    <p class="mt-1 text-sm text-muted">Te has salido del mapa.</p>
    <RouterLink to="/" class="tap mt-6 rounded bg-primary px-4 py-2 font-medium text-white">
      Volver al inicio
    </RouterLink>
  </div>
</template>
