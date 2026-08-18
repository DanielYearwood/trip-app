import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase, errorMessage } from '@/lib/supabase'
import type { Expense, ExpenseCategory, ExpenseStatus } from '@/types/domain'
import { useAuthStore } from './auth'

export const useExpensesStore = defineStore('expenses', () => {
  const items = ref<Expense[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  const active = computed(() => items.value.filter((e) => e.status !== 'cancelado'))

  /** Todo lo que esperamos gastar, esté pagado o no. */
  const previsto = computed(() =>
    active.value.reduce((acc, e) => acc + (e.amount_eur ?? (e.currency === 'EUR' ? e.amount : 0)), 0),
  )

  const pagado = computed(() => active.value.reduce((acc, e) => acc + e.amount_paid, 0))

  const pendiente = computed(() =>
    active.value
      .filter((e) => e.status !== 'reembolsado')
      .reduce(
        (acc, e) => acc + ((e.amount_eur ?? (e.currency === 'EUR' ? e.amount : 0)) - e.amount_paid),
        0,
      ),
  )

  /** Importes en moneda extranjera sin conversión: no se pueden sumar. */
  const sinConvertir = computed(
    () => active.value.filter((e) => e.amount_eur === null && e.currency !== 'EUR').length,
  )

  const porCategoria = computed(() => {
    const map = new Map<ExpenseCategory, { total: number; pagado: number }>()
    for (const e of active.value) {
      const cur = map.get(e.category) ?? { total: 0, pagado: 0 }
      cur.total += e.amount_eur ?? (e.currency === 'EUR' ? e.amount : 0)
      cur.pagado += e.amount_paid
      map.set(e.category, cur)
    }
    return [...map.entries()].sort((a, b) => b[1].total - a[1].total)
  })

  async function load(tripId: string) {
    loading.value = true
    error.value = null
    const { data, error: err } = await supabase
      .from('expenses')
      .select('*')
      .eq('trip_id', tripId)
      .is('deleted_at', null)
      .order('created_at')
    if (err) error.value = errorMessage(err)
    else items.value = data ?? []
    loading.value = false
  }

  async function create(payload: {
    trip_id: string
    label: string
    category: ExpenseCategory
    amount: number
    currency?: string
    place_id?: string | null
    route_id?: string | null
    status?: ExpenseStatus
  }) {
    const auth = useAuthStore()
    const currency = payload.currency ?? 'EUR'
    const row = {
      ...payload,
      currency,
      amount_eur: currency === 'EUR' ? payload.amount : null,
      status: payload.status ?? 'previsto',
      created_by: auth.user?.id ?? null,
    }
    const { data, error: err } = await supabase.from('expenses').insert(row).select().single()
    if (err) {
      error.value = errorMessage(err)
      return null
    }
    items.value.push(data)
    return data as Expense
  }

  async function update(id: string, patch: Partial<Expense>) {
    const idx = items.value.findIndex((e) => e.id === id)
    const previous = idx >= 0 ? { ...items.value[idx]! } : null
    if (idx >= 0) Object.assign(items.value[idx]!, patch) // optimista

    const { error: err } = await supabase.from('expenses').update(patch).eq('id', id)
    if (err) {
      if (idx >= 0 && previous) items.value[idx] = previous
      error.value = errorMessage(err)
      return false
    }
    return true
  }

  /** Alterna entre pagado y previsto. Es la acción de un toque de la lista. */
  async function togglePaid(id: string) {
    const e = items.value.find((x) => x.id === id)
    if (!e) return
    const auth = useAuthStore()
    const paying = e.status !== 'pagado'
    await update(id, {
      status: paying ? 'pagado' : 'previsto',
      amount_paid: paying ? e.amount : 0,
      paid_by: paying ? (auth.user?.id ?? null) : null,
    })
  }

  async function remove(id: string) {
    const { error: err } = await supabase
      .from('expenses')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id)
    if (err) {
      error.value = errorMessage(err)
      return
    }
    items.value = items.value.filter((e) => e.id !== id)
  }

  return {
    items,
    loading,
    error,
    active,
    previsto,
    pagado,
    pendiente,
    sinConvertir,
    porCategoria,
    load,
    create,
    update,
    togglePaid,
    remove,
  }
})
