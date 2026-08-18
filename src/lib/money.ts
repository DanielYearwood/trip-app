/**
 * Formato y conversión de dinero.
 * Regla del README: un precio sin fecha de comprobación es un rumor, así que
 * `formatPrice` obliga a decidir qué hacer cuando falta el importe.
 */

const NO_DECIMALS = new Set(['IDR', 'JPY', 'KRW', 'VND'])

export function formatMoney(amount: number | null | undefined, currency = 'EUR'): string {
  if (amount === null || amount === undefined || Number.isNaN(amount)) return '—'
  const digits = NO_DECIMALS.has(currency) ? 0 : 2
  return new Intl.NumberFormat('es-ES', {
    style: 'currency',
    currency,
    minimumFractionDigits: digits,
    maximumFractionDigits: digits,
  }).format(amount)
}

/** Precio por noche a partir del total. Devuelve null si no se puede calcular. */
export function perNight(total: number | null, nights: number | null): number | null {
  if (total === null || !nights || nights <= 0) return null
  return Math.round((total / nights) * 100) / 100
}

/** Precio por persona a partir del total. */
export function perPerson(total: number | null, people: number | null): number | null {
  if (total === null || !people || people <= 0) return null
  return Math.round((total / people) * 100) / 100
}

export function convert(amount: number, rate: number): number {
  return Math.round(amount * rate * 100) / 100
}

/**
 * Suma en EUR usando amount_eur cuando existe y cayendo al importe original
 * solo si ya está en EUR. Nunca inventa un tipo de cambio.
 */
export function sumEur(
  rows: Array<{ amount: number; currency: string; amount_eur: number | null }>,
): number {
  return rows.reduce((acc, r) => {
    if (r.amount_eur !== null && r.amount_eur !== undefined) return acc + r.amount_eur
    if (r.currency === 'EUR') return acc + r.amount
    return acc
  }, 0)
}

/** Importes que no se pueden sumar por falta de conversión. Se avisa en la UI. */
export function unconvertedCount(
  rows: Array<{ currency: string; amount_eur: number | null }>,
): number {
  return rows.filter((r) => r.amount_eur === null && r.currency !== 'EUR').length
}
