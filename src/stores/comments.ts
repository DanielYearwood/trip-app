import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase, errorMessage } from '@/lib/supabase'
import { useAuthStore } from './auth'

export interface Comment {
  id: string
  trip_id: string
  entity_type: string
  entity_id: string
  body: string
  author_id: string
  created_at: string
}

export const useCommentsStore = defineStore('comments', () => {
  const items = ref<Comment[]>([])
  const names = ref<Record<string, string>>({})
  const loading = ref(false)
  const error = ref<string | null>(null)

  function forEntity(type: string, id: string) {
    return items.value
      .filter((c) => c.entity_type === type && c.entity_id === id)
      .sort((a, b) => a.created_at.localeCompare(b.created_at))
  }

  function countFor(type: string, id: string) {
    return items.value.filter((c) => c.entity_type === type && c.entity_id === id).length
  }

  function authorName(id: string) {
    return names.value[id] ?? 'Alguien'
  }

  async function load(tripId: string) {
    loading.value = true
    const [c, p] = await Promise.all([
      supabase.from('comments').select('*').eq('trip_id', tripId).is('deleted_at', null),
      supabase.from('profiles').select('id, display_name'),
    ])
    if (c.error) error.value = errorMessage(c.error)
    else items.value = c.data ?? []
    if (!p.error) {
      names.value = Object.fromEntries(
        (p.data ?? []).map((r: { id: string; display_name: string }) => [r.id, r.display_name]),
      )
    }
    loading.value = false
  }

  async function add(tripId: string, entityType: string, entityId: string, body: string) {
    const auth = useAuthStore()
    if (!auth.user) return
    const { data, error: err } = await supabase
      .from('comments')
      .insert({
        trip_id: tripId,
        entity_type: entityType,
        entity_id: entityId,
        body: body.trim(),
        author_id: auth.user.id,
      })
      .select()
      .single()
    if (err) {
      error.value = errorMessage(err)
      return
    }
    items.value.push(data)
  }

  async function remove(id: string) {
    const { error: err } = await supabase
      .from('comments')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id)
    if (err) {
      error.value = errorMessage(err)
      return
    }
    items.value = items.value.filter((c) => c.id !== id)
  }

  return { items, loading, error, forEntity, countFor, authorName, load, add, remove }
})
