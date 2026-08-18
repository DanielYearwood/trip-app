<script setup lang="ts">
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const email = ref('')
const sending = ref(false)
const sent = ref(false)

async function submit() {
  if (!email.value.trim() || sending.value) return
  sending.value = true
  sent.value = await auth.sendMagicLink(email.value.trim())
  sending.value = false
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center p-6">
    <div class="w-full max-w-sm">
      <h1 class="text-2xl font-semibold">Bali 2026</h1>
      <p class="mt-1 text-sm text-muted">
        Del 9 al 20 de octubre · Gili Trawangan, Ubud y Seminyak
      </p>

      <form v-if="!sent" class="mt-8 space-y-3" @submit.prevent="submit">
        <label class="block text-sm font-medium" for="email">Tu correo</label>
        <input
          id="email"
          v-model="email"
          type="email"
          required
          autocomplete="email"
          placeholder="tu@correo.com"
          class="tap w-full rounded border border-line bg-surface px-3 py-2"
        />
        <button
          type="submit"
          :disabled="sending"
          class="tap w-full rounded bg-primary px-4 py-2 font-medium text-white disabled:opacity-60"
        >
          {{ sending ? 'Enviando…' : 'Enviar enlace de acceso' }}
        </button>
        <p v-if="auth.error" class="text-sm text-danger">{{ auth.error }}</p>
        <p class="text-xs text-muted">
          Te llega un enlace al correo. No hay contraseña que recordar.
        </p>
      </form>

      <div v-else class="mt-8 card p-4">
        <p class="font-medium">Revisa tu correo</p>
        <p class="mt-1 text-sm text-muted">
          Si <strong>{{ email }}</strong> tiene acceso, recibirá un enlace para entrar. Ábrelo en
          este mismo dispositivo.
        </p>
        <button class="tap mt-3 text-sm text-primary underline" @click="sent = false">
          Usar otro correo
        </button>
      </div>
    </div>
  </div>
</template>
