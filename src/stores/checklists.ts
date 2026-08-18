import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase, errorMessage } from '@/lib/supabase'

export interface Checklist {
  id: string
  trip_id: string
  name: string
  sort_order: number
}

export interface ChecklistItem {
  id: string
  checklist_id: string
  trip_id: string
  label: string
  done: boolean
  done_at: string | null
  due_date: string | null
  url: string | null
  notes: string | null
  sort_order: number
}

export const useChecklistsStore = defineStore('checklists', () => {
  const lists = ref<Checklist[]>([])
  const items = ref<ChecklistItem[]>([])
  const error = ref<string | null>(null)

  const pendingCount = computed(() => items.value.filter((i) => !i.done).length)

  function itemsOf(listId: string) {
    return items.value
      .filter((i) => i.checklist_id === listId)
      .sort((a, b) => Number(a.done) - Number(b.done) || a.sort_order - b.sort_order)
  }

  async function load(tripId: string) {
    const [l, i] = await Promise.all([
      supabase.from('checklists').select('*').eq('trip_id', tripId).order('sort_order'),
      supabase.from('checklist_items').select('*').eq('trip_id', tripId).order('sort_order'),
    ])
    if (l.error) error.value = errorMessage(l.error)
    else lists.value = l.data ?? []
    if (i.error) error.value = errorMessage(i.error)
    else items.value = i.data ?? []
  }

  async function toggle(id: string) {
    const it = items.value.find((x) => x.id === id)
    if (!it) return
    const done = !it.done
    it.done = done
    it.done_at = done ? new Date().toISOString() : null
    const { error: err } = await supabase
      .from('checklist_items')
      .update({ done, done_at: it.done_at })
      .eq('id', id)
    if (err) {
      it.done = !done
      error.value = errorMessage(err)
    }
  }

  async function add(listId: string, tripId: string, label: string, url: string | null) {
    const { data, error: err } = await supabase
      .from('checklist_items')
      .insert({ checklist_id: listId, trip_id: tripId, label, url, sort_order: 100 })
      .select()
      .single()
    if (err) {
      error.value = errorMessage(err)
      return
    }
    items.value.push(data)
  }

  async function remove(id: string) {
    const { error: err } = await supabase.from('checklist_items').delete().eq('id', id)
    if (err) {
      error.value = errorMessage(err)
      return
    }
    items.value = items.value.filter((i) => i.id !== id)
  }

  async function setUrl(id: string, url: string | null) {
    const it = items.value.find((x) => x.id === id)
    if (it) it.url = url
    await supabase.from('checklist_items').update({ url }).eq('id', id)
  }

  return { lists, items, error, pendingCount, itemsOf, load, toggle, add, remove, setUrl }
})
