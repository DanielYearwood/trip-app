import { differenceInCalendarDays, format, parseISO, isValid } from 'date-fns'
import { es } from 'date-fns/locale'

export function parse(d: string | null | undefined): Date | null {
  if (!d) return null
  const parsed = parseISO(d)
  return isValid(parsed) ? parsed : null
}

export function formatDate(d: string | null | undefined, pattern = 'd MMM'): string {
  const date = parse(d)
  return date ? format(date, pattern, { locale: es }) : '—'
}

export function formatLongDate(d: string | null | undefined): string {
  return formatDate(d, "EEEE d 'de' MMMM")
}

export function formatRange(from: string | null, to: string | null): string {
  const a = parse(from)
  const b = parse(to)
  if (!a || !b) return '—'
  const sameMonth = a.getMonth() === b.getMonth()
  return sameMonth
    ? `${format(a, 'd', { locale: es })}–${format(b, 'd MMM', { locale: es })}`
    : `${format(a, 'd MMM', { locale: es })} – ${format(b, 'd MMM', { locale: es })}`
}

/** Noches entre dos fechas. Null si falta alguna o el orden es incoherente. */
export function nightsBetween(from: string | null, to: string | null): number | null {
  const a = parse(from)
  const b = parse(to)
  if (!a || !b) return null
  const n = differenceInCalendarDays(b, a)
  return n >= 0 ? n : null
}

/** Días que faltan hasta una fecha. Negativo si ya pasó. */
export function daysUntil(target: string | null, from: Date = new Date()): number | null {
  const t = parse(target)
  if (!t) return null
  return differenceInCalendarDays(t, from)
}

/** ¿Se solapan dos estancias? Check-out y check-in el mismo día NO es solape. */
export function overlaps(
  aIn: string | null,
  aOut: string | null,
  bIn: string | null,
  bOut: string | null,
): boolean {
  const a1 = parse(aIn)
  const a2 = parse(aOut)
  const b1 = parse(bIn)
  const b2 = parse(bOut)
  if (!a1 || !a2 || !b1 || !b2) return false
  return a1 < b2 && b1 < a2
}

/** Todas las fechas ISO entre dos extremos, ambos incluidos. */
export function dateRange(from: string, to: string): string[] {
  const a = parse(from)
  const b = parse(to)
  if (!a || !b) return []
  const out: string[] = []
  const cursor = new Date(a)
  while (cursor <= b) {
    out.push(format(cursor, 'yyyy-MM-dd'))
    cursor.setDate(cursor.getDate() + 1)
  }
  return out
}
