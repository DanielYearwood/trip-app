/**
 * Tipos de dominio. Reflejan el esquema de supabase/migrations/0001_init.sql.
 * Cuando el proyecto esté estable conviene generar database.ts con
 *   supabase gen types typescript --project-id <ref>
 * y hacer que estos tipos deriven de allí.
 */

export type Role = 'owner' | 'editor' | 'viewer'

export type PlaceKind =
  | 'stay'
  | 'activity'
  | 'food'
  | 'beach'
  | 'transport'
  | 'health'
  | 'shopping'
  | 'viewpoint'
  | 'other'

export type PlaceStatus =
  | 'idea'
  | 'candidato'
  | 'favorito'
  | 'seleccionado'
  | 'planificado'
  | 'reservado'
  | 'realizado'
  | 'descartado'

export type RouteMode =
  | 'walk'
  | 'bike'
  | 'cidomo'
  | 'grab'
  | 'taxi'
  | 'private_driver'
  | 'shuttle'
  | 'fast_boat'
  | 'ferry'
  | 'flight'
  | 'other'

export type RouteStatus =
  | 'idea'
  | 'requiere_confirmacion'
  | 'reservada'
  | 'confirmada'
  | 'en_riesgo'
  | 'descartada'

export type ExpenseStatus =
  | 'previsto'
  | 'comprometido'
  | 'parcialmente_pagado'
  | 'pagado'
  | 'reembolsado'
  | 'cancelado'

export type ExpenseCategory =
  | 'alojamiento'
  | 'transporte_internacional'
  | 'transporte_local'
  | 'actividad'
  | 'comida'
  | 'compras'
  | 'tasas_visado'
  | 'seguro'
  | 'salud'
  | 'otros'

export interface Trip {
  id: string
  name: string
  slug: string | null
  destination: string | null
  start_date: string
  end_date: string
  base_currency: string
  local_currency: string
  budget_total: number | null
  budget_daily: number | null
  travellers: number
}

export interface Zone {
  id: string
  trip_id: string
  name: string
  slug: string
  start_date: string | null
  end_date: string | null
  color: string | null
  center_lat: number | null
  center_lng: number | null
  sort_order: number
  notes: string | null
}

export interface StayDetails {
  place_id: string
  stay_type: string | null
  check_in: string | null
  check_out: string | null
  nights: number | null
  room_type: string | null
  room_size_m2: number | null
  guests: number
  pool: 'privada' | 'compartida' | 'ninguna' | null
  breakfast_included: boolean | null
  pay_at_property: boolean
  free_cancellation: boolean | null
  cancellation_deadline: string | null
  booking_reference: string | null
}

export interface Place {
  id: string
  trip_id: string
  zone_id: string | null
  name: string
  kind: PlaceKind
  category: string | null
  status: PlaceStatus
  discard_reason: string | null
  address: string | null
  lat: number | null
  lng: number | null
  geocode_source: string | null
  price_amount: number | null
  price_currency: string | null
  price_basis: 'total' | 'por_noche' | 'por_persona' | 'por_grupo' | null
  price_pending: boolean
  price_source: string | null
  checked_at: string | null
  rating: number | null
  rating_count: number | null
  location_rating: number | null
  walk_minutes_to_center: number | null
  walk_minutes_to_beach: number | null
  walk_minutes_to_port: number | null
  booking_url: string | null
  website_url: string | null
  phone: string | null
  cover_image_url: string | null
  pros: string[]
  cons: string[]
  tags: string[]
  notes: string | null
  updated_at: string
  /** Presente cuando la consulta hace join con stay_details. */
  stay_details?: StayDetails | null
}

export interface TripRoute {
  id: string
  trip_id: string
  from_label: string | null
  to_label: string | null
  mode: RouteMode
  date: string | null
  status: RouteStatus
  risk_level: 'bajo' | 'medio' | 'alto' | null
  risk_notes: string | null
  cost_amount: number | null
  cost_currency: string | null
  operator: string | null
  notes: string | null
}

export interface Expense {
  id: string
  trip_id: string
  place_id: string | null
  route_id: string | null
  label: string
  category: ExpenseCategory
  amount: number
  currency: string
  amount_eur: number | null
  status: ExpenseStatus
  amount_paid: number
  paid_by: string | null
  due_date: string | null
}

/** Etiquetas en español para mostrar en la interfaz. */
export const STATUS_LABEL: Record<PlaceStatus, string> = {
  idea: 'Idea',
  candidato: 'Candidato',
  favorito: 'Favorito',
  seleccionado: 'Seleccionado',
  planificado: 'Planificado',
  reservado: 'Reservado',
  realizado: 'Realizado',
  descartado: 'Descartado',
}

export const ROUTE_STATUS_LABEL: Record<RouteStatus, string> = {
  idea: 'Idea',
  requiere_confirmacion: 'Por confirmar',
  reservada: 'Reservada',
  confirmada: 'Confirmada',
  en_riesgo: 'En riesgo',
  descartada: 'Descartada',
}

export const MODE_LABEL: Record<RouteMode, string> = {
  walk: 'A pie',
  bike: 'Bicicleta',
  cidomo: 'Cidomo',
  grab: 'Grab',
  taxi: 'Taxi',
  private_driver: 'Conductor privado',
  shuttle: 'Shuttle',
  fast_boat: 'Fast boat',
  ferry: 'Ferry',
  flight: 'Vuelo',
  other: 'Otro',
}

export const KIND_LABEL: Record<PlaceKind, string> = {
  stay: 'Alojamiento',
  activity: 'Actividad',
  food: 'Restaurante',
  beach: 'Playa',
  transport: 'Transporte',
  health: 'Salud',
  shopping: 'Compras',
  viewpoint: 'Mirador',
  other: 'Otro',
}
