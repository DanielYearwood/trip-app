import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase, errorMessage } from '@/lib/supabase'
import type { Place, Trip, TripRoute, Zone, PlaceStatus, StayDetails } from '@/types/domain'
import { nightsBetween, overlaps, daysUntil } from '@/lib/dates'

/** Estados que cuentan como "decisión tomada" para un alojamiento. */
const ACTIVE_STAY: PlaceStatus[] = ['seleccionado', 'reservado']

export interface Alert {
  level: 'danger' | 'warn' | 'info'
  text: string
  to?: string
}

export const useTripStore = defineStore('trip', () => {
  const trip = ref<Trip | null>(null)
  const zones = ref<Zone[]>([])
  const places = ref<Place[]>([])
  const routes = ref<TripRoute[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  const stays = computed(() => places.value.filter((p) => p.kind === 'stay'))
  const activities = computed(() => places.value.filter((p) => p.kind === 'activity'))

  const zoneBySlug = computed(() =>
    Object.fromEntries(zones.value.map((z) => [z.slug, z])) as Record<string, Zone>,
  )

  function zoneName(id: string | null): string {
    return zones.value.find((z) => z.id === id)?.name ?? 'Sin zona'
  }

  /** Alojamiento decidido de cada zona, o null si la zona sigue abierta. */
  const chosenStayByZone = computed(() => {
    const out: Record<string, Place | null> = {}
    for (const z of zones.value) {
      out[z.id] =
        stays.value.find((s) => s.zone_id === z.id && ACTIVE_STAY.includes(s.status)) ?? null
    }
    return out
  })

  /** Rutas que siguen sin cerrar. El traslado del 9/10 vive aquí. */
  const riskyRoutes = computed(() =>
    routes.value.filter((r) => r.status === 'en_riesgo' || r.status === 'requiere_confirmacion'),
  )

  const unlocated = computed(() =>
    places.value.filter((p) => p.status !== 'descartado' && (p.lat === null || p.lng === null)),
  )

  /**
   * Avisos del dashboard. Se calculan siempre desde los datos: nada de listas
   * escritas a mano (README 9.5).
   */
  const alerts = computed<Alert[]>(() => {
    const out: Alert[] = []

    for (const r of routes.value) {
      if (r.status === 'en_riesgo') {
        out.push({
          level: 'danger',
          text: `Tramo en riesgo: ${r.from_label ?? '?'} → ${r.to_label ?? '?'}`,
          to: '/routes',
        })
      }
    }

    for (const z of zones.value) {
      const chosen = chosenStayByZone.value[z.id]
      if (!chosen) {
        out.push({ level: 'warn', text: `${z.name}: alojamiento sin decidir`, to: '/stays' })
      } else if (chosen.status === 'seleccionado') {
        // Decidido no es reservado: hasta que no se reserve, ni el precio ni
        // la disponibilidad están sujetos a nada.
        out.push({
          level: 'warn',
          text: `${chosen.name}: decidido pero todavía sin reservar`,
          to: '/stays',
        })
      }
    }

    for (const s of stays.value) {
      if (!ACTIVE_STAY.includes(s.status)) continue
      const d = s.stay_details
      if (d?.free_cancellation && !d.cancellation_deadline) {
        out.push({
          level: 'warn',
          text: `${s.name}: falta la fecha límite de cancelación`,
          to: '/stays',
        })
      }
      const left = daysUntil(d?.cancellation_deadline ?? null)
      if (left !== null && left >= 0 && left <= 7) {
        out.push({
          level: 'danger',
          text: `${s.name}: la cancelación gratuita vence en ${left} día(s)`,
          to: '/stays',
        })
      }
    }

    // Solapes entre alojamientos activos
    const active = stays.value.filter((s) => ACTIVE_STAY.includes(s.status))
    for (let i = 0; i < active.length; i++) {
      for (let j = i + 1; j < active.length; j++) {
        const a = active[i]!
        const b = active[j]!
        if (
          overlaps(
            a.stay_details?.check_in ?? null,
            a.stay_details?.check_out ?? null,
            b.stay_details?.check_in ?? null,
            b.stay_details?.check_out ?? null,
          )
        ) {
          out.push({ level: 'danger', text: `Solape de fechas: ${a.name} y ${b.name}`, to: '/stays' })
        }
      }
    }

    if (unlocated.value.length) {
      out.push({
        level: 'info',
        text: `${unlocated.value.length} elemento(s) sin ubicar en el mapa`,
        to: '/map',
      })
    }

    return out
  })

  /** Total de las noches ya decididas. Los candidatos no cuentan. */
  const decidedAccommodationTotal = computed(() =>
    stays.value
      .filter((s) => ACTIVE_STAY.includes(s.status) && s.price_amount !== null)
      .reduce((acc, s) => acc + (s.price_amount ?? 0), 0),
  )

  const nightsCovered = computed(() =>
    stays.value
      .filter((s) => ACTIVE_STAY.includes(s.status))
      .reduce(
        (acc, s) =>
          acc + (nightsBetween(s.stay_details?.check_in ?? null, s.stay_details?.check_out ?? null) ?? 0),
        0,
      ),
  )

  async function load() {
    loading.value = true
    error.value = null
    try {
      const { data: trips, error: e1 } = await supabase
        .from('trips')
        .select('*')
        .order('start_date')
        .limit(1)
      if (e1) throw e1
      trip.value = trips?.[0] ?? null
      if (!trip.value) return

      const tripId = trip.value.id
      const [z, p, r] = await Promise.all([
        supabase.from('zones').select('*').eq('trip_id', tripId).order('sort_order'),
        supabase
          .from('places')
          .select('*, stay_details(*)')
          .eq('trip_id', tripId)
          .is('deleted_at', null)
          .order('name'),
        supabase.from('routes').select('*').eq('trip_id', tripId).order('date'),
      ])

      if (z.error) throw z.error
      if (p.error) throw p.error
      if (r.error) throw r.error

      zones.value = z.data ?? []
      places.value = (p.data ?? []).map((row: Record<string, unknown>) => ({
        ...(row as unknown as Place),
        // Supabase devuelve la relación 1-1 como array o como objeto según el caso.
        stay_details: Array.isArray(row.stay_details)
          ? (row.stay_details[0] ?? null)
          : ((row.stay_details as Place['stay_details']) ?? null),
      }))
      routes.value = r.data ?? []
    } catch (e) {
      error.value = errorMessage(e)
    } finally {
      loading.value = false
    }
  }

  /** Actualiza campos de un lugar. Optimista, con vuelta atrás si falla. */
  async function updatePlace(placeId: string, patch: Partial<Place>) {
    const idx = places.value.findIndex((p) => p.id === placeId)
    if (idx < 0) return false
    const previous = { ...places.value[idx]! }
    Object.assign(places.value[idx]!, patch)

    // stay_details viaja aparte: no es una columna de places.
    const { stay_details: _ignored, ...columns } = patch
    const { error: err } = await supabase.from('places').update(columns).eq('id', placeId)
    if (err) {
      places.value[idx] = previous
      error.value = errorMessage(err)
      return false
    }
    return true
  }

  async function updateStayDetails(placeId: string, patch: Partial<StayDetails>) {
    const place = places.value.find((p) => p.id === placeId)
    const previous = place?.stay_details ? { ...place.stay_details } : null
    if (place?.stay_details) Object.assign(place.stay_details, patch)

    const { error: err } = await supabase
      .from('stay_details')
      .update(patch)
      .eq('place_id', placeId)
    if (err) {
      if (place && previous) place.stay_details = previous
      error.value = errorMessage(err)
      return false
    }
    return true
  }

  /** Actualiza una ruta. Optimista, con vuelta atrás si falla. */
  async function updateRoute(routeId: string, patch: Partial<TripRoute>) {
    const idx = routes.value.findIndex((r) => r.id === routeId)
    if (idx < 0) return false
    const previous = { ...routes.value[idx]! }
    Object.assign(routes.value[idx]!, patch)

    const { error: err } = await supabase.from('routes').update(patch).eq('id', routeId)
    if (err) {
      routes.value[idx] = previous
      error.value = errorMessage(err)
      return false
    }
    return true
  }

  async function setStatus(placeId: string, status: PlaceStatus) {
    const place = places.value.find((p) => p.id === placeId)
    if (!place) return
    const previous = place.status
    place.status = status // optimista
    const { error: err } = await supabase.from('places').update({ status }).eq('id', placeId)
    if (err) {
      place.status = previous
      error.value = errorMessage(err)
    }
  }

  return {
    trip,
    zones,
    places,
    routes,
    loading,
    error,
    stays,
    activities,
    zoneBySlug,
    zoneName,
    chosenStayByZone,
    riskyRoutes,
    unlocated,
    alerts,
    decidedAccommodationTotal,
    nightsCovered,
    load,
    setStatus,
    updatePlace,
    updateStayDetails,
    updateRoute,
  }
})
