import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Session, User } from '@supabase/supabase-js'
import { supabase, errorMessage } from '@/lib/supabase'

export const useAuthStore = defineStore('auth', () => {
  const session = ref<Session | null>(null)
  const user = ref<User | null>(null)
  const ready = ref(false)
  const error = ref<string | null>(null)

  const isLoggedIn = computed(() => Boolean(user.value))
  const displayName = computed(
    () => user.value?.user_metadata?.name ?? user.value?.email?.split('@')[0] ?? '',
  )

  async function init() {
    if (ready.value) return
    const { data } = await supabase.auth.getSession()
    session.value = data.session
    user.value = data.session?.user ?? null

    supabase.auth.onAuthStateChange((_event, s) => {
      session.value = s
      user.value = s?.user ?? null
    })

    ready.value = true
  }

  /** Envía el magic link. No revela si el correo existe o no. */
  async function sendMagicLink(email: string) {
    error.value = null
    const { error: err } = await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: `${window.location.origin}/` },
    })
    if (err) {
      error.value = errorMessage(err)
      return false
    }
    return true
  }

  async function signOut() {
    await supabase.auth.signOut()
    session.value = null
    user.value = null
  }

  return { session, user, ready, error, isLoggedIn, displayName, init, sendMagicLink, signOut }
})
