/** Enlaces universales de Google Maps y utilidades de coordenadas. */

export function gmapsLink(lat: number, lng: number): string {
  return `https://www.google.com/maps/search/?api=1&query=${lat},${lng}`
}

export function directionsLink(
  from: { lat: number; lng: number } | null,
  to: { lat: number; lng: number },
  mode: 'walking' | 'driving' | 'transit' = 'walking',
): string {
  const base = `https://www.google.com/maps/dir/?api=1&destination=${to.lat},${to.lng}&travelmode=${mode}`
  return from ? `${base}&origin=${from.lat},${from.lng}` : base
}

/**
 * Extrae coordenadas de texto pegado: "-8.5069, 115.2625", un enlace de Google
 * Maps con @lat,lng o con ?q=lat,lng. Devuelve null si no encuentra nada válido.
 */
export function parseCoords(input: string): { lat: number; lng: number } | null {
  if (!input) return null
  const patterns = [/@(-?\d+\.\d+),(-?\d+\.\d+)/, /[?&]q=(-?\d+\.\d+),\s*(-?\d+\.\d+)/, /(-?\d+\.\d+)[,\s]+(-?\d+\.\d+)/]

  for (const re of patterns) {
    const m = input.match(re)
    if (!m || !m[1] || !m[2]) continue
    const lat = Number(m[1])
    const lng = Number(m[2])
    if (Number.isFinite(lat) && Number.isFinite(lng) && Math.abs(lat) <= 90 && Math.abs(lng) <= 180) {
      return { lat, lng }
    }
  }
  return null
}

/** Distancia en km entre dos puntos. Sirve para "a X km", nunca para tiempos. */
export function haversineKm(
  a: { lat: number; lng: number },
  b: { lat: number; lng: number },
): number {
  const R = 6371
  const dLat = ((b.lat - a.lat) * Math.PI) / 180
  const dLng = ((b.lng - a.lng) * Math.PI) / 180
  const lat1 = (a.lat * Math.PI) / 180
  const lat2 = (b.lat * Math.PI) / 180
  const h =
    Math.sin(dLat / 2) ** 2 + Math.sin(dLng / 2) ** 2 * Math.cos(lat1) * Math.cos(lat2)
  return Math.round(2 * R * Math.asin(Math.sqrt(h)) * 100) / 100
}
