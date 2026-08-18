import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

/**
 * `false` cuando faltan las variables de entorno. La app sigue arrancando y
 * muestra un aviso claro en vez de romperse con una pantalla en blanco.
 */
export const supabaseConfigured = Boolean(url && anonKey)

if (!supabaseConfigured) {
  console.error(
    'Faltan VITE_SUPABASE_URL o VITE_SUPABASE_ANON_KEY. Copia .env.example a .env.local y rellénalas.',
  )
}

export const supabase = createClient(url ?? 'http://localhost', anonKey ?? 'anon', {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
})

/** Mensaje de error legible en español a partir de lo que devuelve Supabase. */
export function errorMessage(error: unknown): string {
  if (!error) return 'Error desconocido'
  if (typeof error === 'string') return error
  const e = error as { message?: string; error_description?: string }
  const raw = e.error_description ?? e.message ?? ''

  if (raw.includes('Invalid login credentials')) return 'Credenciales incorrectas.'
  if (raw.includes('Email not confirmed')) return 'Falta confirmar el correo.'
  if (raw.includes('rate limit') || raw.includes('For security purposes')) {
    return 'Demasiados intentos seguidos. Espera un minuto y vuelve a probar.'
  }
  if (raw.includes('violates row-level security')) {
    return 'No tienes permiso para hacer eso en este viaje.'
  }
  if (raw.includes('Failed to fetch') || raw.includes('NetworkError')) {
    return 'Sin conexión. Comprueba la red e inténtalo otra vez.'
  }
  return raw || 'Ha ocurrido un error.'
}
