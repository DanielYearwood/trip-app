# Bali Trip Planner

Aplicación web colaborativa y *mobile-first* para organizar de principio a fin un viaje a Bali: alojamientos, actividades, lugares, rutas, itinerario, pagos, presupuesto, comentarios, documentos y enlaces útiles, todo conectado a un mapa.

> **Este README es el contrato funcional y técnico del proyecto.**
> Está escrito para que una persona o una IA pueda implementar el producto completo sin tener que reconstruir el contexto del viaje ni tomar decisiones estructurales a ciegas.
> Si algo no está aquí, se decide siguiendo los principios de la sección 1 y se documenta en el PR correspondiente.

---

## Índice

- [0. Estado del proyecto](#0-estado-del-proyecto)
- [1. Visión y principios de producto](#1-visión-y-principios-de-producto)
- [2. Contexto canónico del viaje](#2-contexto-canónico-del-viaje)
- [3. Datos iniciales (seed)](#3-datos-iniciales-seed)
- [4. Usuarios, acceso y colaboración](#4-usuarios-acceso-y-colaboración)
- [5. Arquitectura de navegación](#5-arquitectura-de-navegación)
- [6. Módulos funcionales](#6-módulos-funcionales)
- [7. Modelo de datos](#7-modelo-de-datos)
- [8. Seguridad y RLS](#8-seguridad-y-rls)
- [9. Reglas de negocio y cálculos](#9-reglas-de-negocio-y-cálculos)
- [10. Stack técnico y estructura](#10-stack-técnico-y-estructura)
- [11. Diseño, UI y accesibilidad](#11-diseño-ui-y-accesibilidad)
- [12. PWA y comportamiento offline](#12-pwa-y-comportamiento-offline)
- [13. Variables de entorno](#13-variables-de-entorno)
- [14. Fases de desarrollo](#14-fases-de-desarrollo)
- [15. Pruebas y criterios de aceptación](#15-pruebas-y-criterios-de-aceptación)
- [16. Despliegue](#16-despliegue)
- [17. Instrucciones para la IA que escriba el código](#17-instrucciones-para-la-ia-que-escriba-el-código)
- [18. Anexos](#18-anexos)

---

## 0. Estado del proyecto

| Elemento | Estado |
|---|---|
| Repositorio | `DanielYearwood/trip-app` — creado, vacío |
| Código de aplicación | No existe todavía |
| Base de datos | Supabase — proyecto por crear |
| Hosting | Vercel — proyecto por crear |
| Especificación | Este README |

**Hechos del viaje que el código debe dar por ciertos:**

- Viaje para 2 personas: **Daniel** y **Elena**.
- Fechas en destino: **9 – 20 de octubre de 2026**.
- Orden acordado: **Gili Trawangan → Ubud → Seminyak/Legian**.
- **No se conducirá moto ni coche.** Ubicación, trayectos a pie, Grab/Gojek, taxis, conductor privado y barcos son factores prioritarios en toda la aplicación.
- Alojamiento elegido en Gili: **Pearl of Trawangan**.
- Alojamiento reservado en Seminyak/Legian: **Moson Bali Villa Legian**.
- Alojamiento de Ubud: **pendiente de decisión** (hay candidatos con precios ya comprobados).

---

## 1. Visión y principios de producto

La aplicación debe responder de forma inmediata, sin rebuscar en chats ni correos:

- ¿Qué tenemos **decidido, reservado, pagado o pendiente**?
- ¿**Dónde** está cada hotel, actividad, restaurante, puerto o punto de interés?
- ¿Qué tenemos **cerca** y **cómo llegamos sin conducir**?
- ¿Qué hacemos **cada día** y cuánto tiempo requiere cada traslado?
- ¿Cuánto hemos **presupuestado, comprometido, pagado**, y cuánto queda?
- ¿**Quién pagó** cada cosa y cómo queda el reparto entre los dos?
- ¿Qué **alternativas** tenemos si llueve, cambia un barco o descartamos un plan?
- ¿Dónde están las **reservas, enlaces, notas y comentarios** compartidos?

No debe ser una hoja de cálculo disfrazada ni una página estática. Debe sentirse como una aplicación de viaje sencilla, visual y compartida.

### 1.1 Principios

1. **El mapa y el día a día son el centro**, no pantallas accesorias.
2. **Una única fuente de verdad.** Los totales se calculan desde los datos; nunca se copian entre pantallas ni se escriben a mano en la UI.
3. **Información accionable.** Cada ficha permite abrir el enlace oficial, ver la ubicación, obtener indicaciones, comentar o cambiar su estado.
4. **Optimizada para móvil.** Se usará durante el viaje, con una mano, con conexión variable y con sol de frente.
5. **Sin moto.** Todo lugar debe poder evaluarse por distancia a pie, taxi/Grab, conductor o barco. Siempre visible el "cómo llegar sin conducir".
6. **Precios trazables.** Importe, moneda, **fecha de comprobación**, qué incluye, estado de pago y política de cancelación. Un precio sin fecha es un rumor.
7. **Decisiones reversibles.** `idea`, `candidato`, `favorito`, `seleccionado`, `reservado` y `descartado` son estados distintos. **Descartar nunca borra**: atenúa y se puede recuperar.
8. **Privacidad desde el inicio.** El viaje solo lo ven sus miembros. Documentos y datos personales nunca quedan públicos.
9. **Nada inventado.** Si falta un dato (precio, coordenada, horario), se marca como pendiente. La app jamás rellena huecos con estimaciones presentadas como hechos.
10. **Rápido de editar.** Añadir un gasto o mover una actividad de día debe costar menos de 15 segundos.

### 1.2 Fuera de alcance (MVP)

- Scraping o consulta automática de precios de Booking u otras OTAs.
- Motor propio de cálculo de rutas por carretera en tiempo real.
- Reservar o pagar dentro de la app.
- Chat en tiempo real (los comentarios por entidad son suficientes).
- Gestión avanzada multi-viaje: el modelo lo soporta, la UI se optimiza para un viaje activo.

---

## 2. Contexto canónico del viaje

### 2.1 Fechas y zonas

| Tramo | Entrada | Salida | Noches | Objetivo |
|---|---|---|---|---|
| **Gili Trawangan** | 09/10/2026 | 12/10/2026 | 3 | Playa, snorkel, descanso y ambiente de isla |
| **Ubud** | 12/10/2026 | 16/10/2026 | 4 | Cultura, naturaleza, excursiones y base para explorar |
| **Seminyak/Legian** | 16/10/2026 | 20/10/2026 | 4 | Restaurantes, playa, ambiente, compras y cierre cómodo |

Total: **11 noches**.

### 2.2 Vuelos conocidos

| Tramo | Fecha | Hora |
|---|---|---|
| Salida Barcelona (BCN) | 08/10/2026 | — |
| Llegada Denpasar (DPS) | 09/10/2026 | 08:25 |
| Salida Denpasar (DPS) | 20/10/2026 | 19:20 |
| Llegada Barcelona (BCN) | 21/10/2026 | 13:15 |

Los vuelos se modelan como **rutas** (`routes.mode = 'flight'`) ancladas al itinerario, no como texto suelto.

### 2.3 Riesgo logístico visible (obligatorio en el dashboard)

El traslado **DPS → puerto → Gili Trawangan el mismo 9 de octubre** debe figurar como **riesgo abierto** hasta estar reservado y confirmado. Su ficha debe recoger:

- Hora límite real de salida del fast boat elegido.
- Puerto de salida (Padang Bai, Serangan u otro) y tiempo por carretera desde DPS.
- Tiempo estimado de inmigración, recogida de equipaje y tráfico.
- Política del operador si el vuelo o el barco se retrasan o cancelan.
- Estado del mar / temporada y margen de seguridad.
- **Plan B**: primera noche en Bali (Sanur o Canggu) si no hay conexión razonablemente segura.

Por eso el modelo de rutas soporta `status = 'en_riesgo' | 'requiere_confirmacion'` y **rutas alternativas** vinculadas a una principal.

### 2.4 Restricciones permanentes

- **Sin moto ni coche propio.** Cada lugar debe responder: minutos a pie desde el alojamiento del tramo, y coste/tiempo aproximado en Grab/Gojek/taxi/cidomo.
- En **Gili Trawangan no hay coches ni motos**: solo a pie, bicicleta o cidomo. La distancia al puerto y al núcleo pesa más que en Bali.
- En **Seminyak/Legian el tráfico es el factor dominante**: un trayecto corto en kilómetros puede ser largo en tiempo. Las distancias a pie son más fiables que las distancias en coche.

---

## 3. Datos iniciales (seed)

> **Regla crítica:** ninguno de estos importes es un precio en vivo. Cada precio se guarda con `checked_at`, `currency`, `source` y `notes`. La UI muestra **"precio comprobado el {fecha}"** y marca `price_pending = true` cuando falten tarifa o condiciones actuales. **No se automatiza Booking en el MVP.**

### 3.1 Alojamientos decididos

#### Gili Trawangan — Pearl of Trawangan

| Campo | Valor |
|---|---|
| Estado | `seleccionado` (pasa a `reservado` al confirmar el pago real) |
| Fechas | 09/10/2026 → 12/10/2026 (3 noches) |
| Habitación preferida | Suar Deluxe, ~52 m² |
| Régimen | Desayuno incluido y cancelación flexible |
| Precio orientativo | ~375 € total — **requiere confirmación** antes de tratarlo como presupuesto definitivo |
| Piscina | Compartida (dos piscinas) |
| Motivo | Hotel más especial del viaje: primera línea de playa, piscinas, habitación grande, ~10 min a pie del puerto, buen equilibrio entre ambiente y descanso |

#### Seminyak/Legian — Moson Bali Villa Legian

| Campo | Valor |
|---|---|
| Estado | `reservado` |
| Fechas | 16/10/2026 → 20/10/2026 (4 noches) |
| Habitación | Habitación extragrande con vistas a la piscina |
| Piscina | **Compartida**, no privada (pese al nombre "Villa") |
| Precio | **129 €** total, 2 personas, 4 noches |
| Régimen | Desayuno incluido |
| Pago | **En el alojamiento** (`pay_at_property = true`) |
| Cancelación | Gratuita — **falta registrar la fecha límite exacta** |
| Teléfono | +62 819-9908-4565 |
| Ubicación | Dewi Sri, interior de Legian. Playa de Legian a ~2,1 km |
| Motivo | Relación calidad/precio muy fuerte; el ahorro se destina a Gili y a actividades. Implica Grab/Gojek frecuente para playa y cenas |

### 3.2 Ubud — candidatos pendientes de decisión

| Alojamiento | Estado | Precio orientativo (4 noches) | Tipo / piscina | Idea principal |
|---|---|---|---|---|
| **Divara Ubud** | `favorito` | 104 € | Hotel, piscina compartida | Mejor relación calidad/precio; ~15 min a pie del Palacio |
| **Ubud Suarga Private Pool Villa** | `candidato` | 192 € | Villa, **piscina privada**, 56 m² | Experiencia privada barata; ~4,1 km del centro (Grab siempre) |
| **Taman Amartha Hotel** | `candidato` | 208 € | Hotel, dos piscinas | Buen equilibrio; ~15 min a pie del centro; habitación básica 17 m² |
| **Korurua Dijiwa Ubud** | `candidato` | 242 € | Hotel tipo retiro, suite 45 m² | El más bonito y especial; depende de shuttle/taxi |
| **Rumah Kayu Resort** | `candidato` | 286 € | Resort/villa | Alternativa estética; ~5,6 km del centro |
| **Wooden Stone Eco Villa** | `candidato` | 410 € | Villa | Opción especial de precio alto; ~5,4 km del centro |

Sin disponibilidad en 12–16/10 en la última comprobación (cargar como `descartado`, motivo `sin_disponibilidad`): Bubu Mesari Ubud Villa, Temple Tree by Soobali, Nadisa Villa, Kappat Ubud Villa, Villa Kayu Lama.

### 3.3 Gili Trawangan — alternativas conocidas

| Alojamiento | Estado | Precio orientativo (3 noches) | Observación |
|---|---|---|---|
| Jali Resort | `candidato` | 141 € | Mejor ahorro real; no está frente al mar, ~1,2 km del puerto |
| Martas Hotel | `candidato` | 139 € | Sencillo y bien valorado; ~10 min a pie del puerto |
| PinkCoco Gili Trawangan | `candidato` | 188 € | Solo adultos, muy visual; costa oeste (zona atardecer) |
| Lighthouse Hotel | `candidato` | 262 € | Nuevo, frente al mar, ~100 m del puerto; pocas opiniones |
| The Beach House Resort | `candidato` | 274 € | El sustituto más parecido a Pearl; más céntrico y ruidoso |
| Gili Teak Beach Front Resort | `candidato` | ~262 € | Boutique y playa; más alejado |

Descartados por ubicación errónea: **Hani Hideaway** (está en Gili Air) y **Jeeva Santai Villas** (está en Senggigi, Lombok).

### 3.4 Seminyak/Legian — alternativas conocidas

| Alojamiento | Estado | Precio orientativo (4 noches) | Valoración / ubicación | Observación |
|---|---|---|---|---|
| My Secret Home | `candidato` | 198,72 € | 9,4 / 9,6 | Mejor ubicación (junto a Double Six); acceso por callejuela, hay animales en la propiedad |
| Fourteen Roses Beach Hotel | `candidato` | 174,88 € | 8,9 / 9,2 | Punto intermedio, dos piscinas; es Legian/Kuta, no Seminyak |
| Bali Ginger Suites and Villa | `candidato` | 244,21 € | 9,2 / 9,4 | Bonito, tranquilo y céntrico |
| The Eight Bali | `candidato` | 126,76 € | 9,0 / 8,9 | Sin desayuno en la tarifa vista; playa a ~2,6 km |
| Seminyak Paradiso Hotel | `candidato` | 122,72 € | 7,5 / 9,0 | Muy céntrico y barato; calidad claramente inferior |
| DLeafy Seminyak | `candidato` | 108,65 € | 8,9 / 8,0 | Barato y limpio; poco práctico sin moto |

### 3.5 Actividades a precargar (estado `idea` o `candidato`)

| Zona | Actividad | Notas para la ficha |
|---|---|---|
| Gili T. | Snorkel (tortugas / Gili Meno / statues) | Medio día o día completo; depende del mar |
| Gili T. | Sunset costa oeste y swings | Gratis; a pie o en bici |
| Gili T. | Vuelta a la isla en bicicleta | ~2 h; alternativa de lluvia: spa o café |
| Ubud | Mount Batur sunrise trekking | Recogida ~02:00; reserva previa; muy dependiente del tiempo |
| Ubud | Rafting río Ayung o Telaga Waja | Medio día; suele incluir traslado |
| Ubud | Arrozales de Tegallalang y swing | Medio día; combinar con Tirta Empul |
| Ubud | Templos: Tirta Empul, Gunung Kawi, Saraswati | Sarong obligatorio; mejor por la mañana |
| Ubud | Monkey Forest | ~1,5 h; céntrico y a pie |
| Ubud | Campuhan Ridge Walk | Al amanecer; gratis |
| Ubud | Cascadas: Tibumana, Tegenungan, Kanto Lampo | Requieren conductor; agrupar en un día |
| Seminyak | Double Six Beach y sunset | Grab desde Moson |
| Seminyak | Beach club (Potato Head, Ku De Ta, La Plancha) | Reserva recomendable; comprobar consumo mínimo |
| Uluwatu | Templo de Uluwatu y danza Kecak | Excursión de tarde; conductor privado |
| Canggu | Cafés, tiendas y Echo Beach | Medio día; tráfico impredecible |
| General | Clase de cocina balinesa | Reserva previa; plan ideal para día de lluvia |
| General | Spa / masaje balinés | Relleno flexible de cualquier tarde |

> Ninguna se precarga como `reservada`, ni con horario ni precio inventados. Se cargan con `status = 'idea'`, `price = null`, `checked_at = null`.

### 3.6 Rutas a precargar

| Ruta | Modo | Estado inicial |
|---|---|---|
| BCN → DPS (08–09/10) | `flight` | `confirmada` |
| DPS → puerto (Padang Bai / Serangan) 09/10 | `private_driver` | **`en_riesgo`** |
| Puerto → Gili Trawangan 09/10 | `fast_boat` | **`en_riesgo`** |
| Gili Trawangan → puerto Bali 12/10 | `fast_boat` | `requiere_confirmacion` |
| Puerto → Ubud 12/10 | `private_driver` | `requiere_confirmacion` |
| Ubud → Seminyak/Legian 16/10 | `private_driver` | `requiere_confirmacion` |
| Moson Bali Villa → DPS 20/10 | `grab` | `requiere_confirmacion` |
| DPS → BCN (20–21/10) | `flight` | `confirmada` |

### 3.7 Apps y herramientas a precargar

| App | Categoría | Para qué |
|---|---|---|
| Grab | transporte | Coche/moto/comida en Bali; **no opera en Gili** |
| Gojek | transporte | Alternativa a Grab; comparar precio |
| Google Maps (mapas offline) | mapas | Descargar Bali y Lombok antes de salir |
| Organic Maps / Maps.me | mapas | Mapa offline de respaldo |
| 12Go y operadores de fast boat | transporte | Reserva y horarios de barcos |
| Booking.com | alojamiento | Reservas y condiciones |
| WhatsApp | comunicación | Canal habitual de hoteles y conductores |
| Wise / Revolut | dinero | Cambio y pagos con tarjeta |
| XE Currency | dinero | Conversión offline IDR ↔ EUR |
| Google Translate (indonesio offline) | idioma | Descargar el paquete antes de salir |
| Windy / Meteoblue | clima | Estado del mar para los fast boats |
| e-VOA Indonesia (web oficial) | trámites | **Verificar requisitos vigentes cerca de la fecha** |
| Declaración de aduanas electrónica (e-CD) | trámites | **Verificar requisitos vigentes cerca de la fecha** |

> Los dos últimos se cargan como tareas de checklist con recordatorio, **no** como información dada por buena: los requisitos de entrada cambian y deben comprobarse en la web oficial antes de viajar.

### 3.8 Contactos a precargar

| Contacto | Tipo | Dato |
|---|---|---|
| Moson Bali Villa Legian | alojamiento | +62 819-9908-4565 |
| Pearl of Trawangan | alojamiento | Pendiente |
| Emergencias Indonesia | emergencia | 112 |
| Embajada / Consulado de España en Yakarta | emergencia | Pendiente de registrar |
| Seguro de viaje | seguro | Pendiente: póliza y teléfono de asistencia 24 h |
| Conductor privado Bali | transporte | Pendiente de contratar |

---

## 4. Usuarios, acceso y colaboración

### 4.1 Roles

| Rol | Puede |
|---|---|
| `owner` | Todo: crear el viaje, invitar, cambiar roles, borrar el viaje |
| `editor` | Crear y modificar lugares, planes, rutas, gastos, comentarios y reservas |
| `viewer` | Solo lectura; útil para compartir el planning con familia |

Daniel y Elena son **miembros del mismo viaje** (`owner` y `editor`/`owner`). **No se crean dos copias del viaje.**

### 4.2 Autenticación

- **Supabase Auth** con email + *magic link* como opción principal.
- Google OAuth como añadido opcional posterior (fase 4).
- Invitación mediante enlace con token de un solo uso, o invitación por email.
- Tras iniciar sesión, el usuario solo accede a viajes de los que es miembro. Esto se garantiza en la base de datos vía RLS, **no** en el cliente.
- Sesión persistente; el usuario no debería tener que volver a entrar durante el viaje.

### 4.3 Colaboración

- **Comentarios** en alojamientos, actividades, lugares, días, rutas y gastos.
- Autor y fecha visibles. Editar o borrar solo el autor o un `owner`.
- **Realtime** (Supabase Realtime) opcional en el MVP, recomendado en fase 3: si Elena marca un hotel como favorito, Daniel lo ve sin recargar.
- **Historial ligero** (`activity_log`) de cambios importantes: estado de decisión, importe, estado de pago y datos de reserva.
- Indicador "actualizado por {nombre} hace {tiempo}" en las fichas.

---

## 5. Arquitectura de navegación

### 5.1 Navegación móvil

Barra inferior fija con cinco accesos:

`Inicio` · `Mapa` · `Plan` · `Dinero` · `Más`

Botón flotante `+` (FAB) para añadir rápidamente: **lugar, alojamiento, actividad, gasto, ruta o nota**. El FAB abre un *bottom sheet* con las seis opciones y el formulario mínimo de cada una (nombre + zona + estado; el resto es opcional).

`Más` agrupa: Alojamientos, Actividades y lugares, Rutas y transportes, Documentos y reservas, Apps y contactos, Checklists, Ajustes.

### 5.2 Navegación de escritorio

Sidebar persistente:

- Resumen
- Mapa
- Itinerario
- Alojamientos
- Actividades y lugares
- Rutas y transportes
- Presupuesto y gastos
- Documentos y reservas
- Apps y contactos
- Checklists
- Ajustes

### 5.3 Rutas de la aplicación

```
/                            → redirige a /trips o /login
/login                       → magic link
/invite/:token               → aceptar invitación
/trips                       → lista de viajes del usuario
/trips/:tripId               → dashboard/resumen
/trips/:tripId/map           → mapa
/trips/:tripId/itinerary     → itinerario por días
/trips/:tripId/itinerary/:date
/trips/:tripId/stays         → alojamientos
/trips/:tripId/stays/:placeId
/trips/:tripId/places        → actividades y lugares
/trips/:tripId/places/:placeId
/trips/:tripId/compare       → comparador (2–4 elementos)
/trips/:tripId/routes        → rutas y transportes
/trips/:tripId/routes/:routeId
/trips/:tripId/budget        → presupuesto y gastos
/trips/:tripId/budget/settle → reparto y liquidación
/trips/:tripId/documents     → documentos y reservas
/trips/:tripId/tools         → apps, enlaces y contactos
/trips/:tripId/checklists    → listas de tareas y equipaje
/trips/:tripId/settings      → ajustes del viaje y miembros
*                            → 404
```

Los filtros relevantes se reflejan en la URL para poder compartir una vista:
`?zone=ubud&kind=activity&status=favorito&paid=false&maxPrice=250`

---

## 6. Módulos funcionales

### 6.1 Dashboard (`/trips/:tripId`)

Es la primera pantalla y debe ser útil tanto **antes** como **durante** el viaje.

**Bloques obligatorios:**

1. **Cuenta atrás** hasta el 8/10/2026 (salida) y, durante el viaje, "día 3 de 12 — Ubud".
2. **Próxima acción importante**: la fecha límite más cercana entre cancelaciones gratuitas, reservas pendientes y pagos. Con enlace directo a la ficha.
3. **Alertas y riesgos** (lista, no decorativa):
   - Rutas en estado `en_riesgo` o `requiere_confirmacion` — **el traslado DPS → Gili del 9/10 aparece aquí hasta que se confirme**.
   - Elementos sin coordenadas.
   - Elementos sin precio o con `price_pending`.
   - Alojamientos `reservado` sin `cancellation_deadline` registrada (caso actual de Moson).
   - Días del itinerario vacíos.
   - Cancelaciones gratuitas que vencen en menos de 7 días.
4. **Resumen de alojamientos por zona**: tarjeta por tramo con hotel elegido o "pendiente", fechas, precio y estado de pago. Ubud debe mostrarse claramente como **pendiente de decisión**.
5. **Presupuesto**: previsto / comprometido / pagado / pendiente, con barra de progreso y enlace a `/budget`.
6. **Hoy y mañana** (durante el viaje) o **primer día** (antes): resumen del itinerario.
7. **Mini mapa** con los elementos `favorito`, `seleccionado` y `reservado`.
8. **Accesos rápidos**: vuelos, seguro, documentos, contactos de emergencia.

**Modo viaje:** si `today` está entre `start_date` y `end_date`, el dashboard prioriza "Hoy" arriba del todo y muestra el alojamiento actual con su dirección y teléfono a un toque.

### 6.2 Mapa (`/trips/:tripId/map`)

El corazón visual de la app. Acepta alojamientos, actividades, restaurantes, playas, puertos, aeropuertos, tiendas, centros médicos, puntos fotográficos y cualquier lugar personalizado.

**Funciones mínimas:**

- Marcadores por tipo, con **icono y color diferenciados**.
- Distinción visual de estado: `candidato`, `favorito`, `seleccionado`/`reservado`, `descartado`.
- **Clustering** al alejar el zoom (`leaflet.markercluster`).
- **Filtros** por zona, tipo, estado, día del itinerario, pagado/pendiente, rango de precio y etiquetas.
- **Buscador** por nombre, etiqueta o dirección.
- **Tarjeta al pulsar un marcador**: foto, nombre, tipo, estado, precio, distancia a pie desde el alojamiento del tramo, nota corta y acciones.
- Botones: `Ver ficha`, `Abrir en Google Maps`, `Cómo llegar`, `Añadir al día…`, `Comentar`.
- **Geocodificación** de dirección cuando haya proveedor configurado (Nominatim con política de uso respetada, o Photon).
- **Colocación o corrección manual del pin**: obligatorio como alternativa siempre disponible (arrastrar marcador o pegar coordenadas / enlace de Google Maps del que se extraigan lat/lng).
- Bandeja **"Falta ubicar"** con los elementos sin coordenadas, para arrastrarlos al mapa.
- **Ver solo el plan de un día** (selector de fecha) y dibujar el recorrido de ese día en orden.
- **Centrar por zona**: botones rápidos Gili / Ubud / Seminyak.
- Botón "mi ubicación" (geolocalización del navegador), útil durante el viaje.
- Los elementos `descartado` se muestran atenuados y están **ocultos por defecto**.

**Tecnología de mapa:**

- MVP: **Leaflet + OpenStreetMap**.
- **No usar la API de pago de Google Maps para dibujar el mapa.**
- En producción **no abusar del servidor público de teselas de OSM**: configurar un proveedor compatible mediante `VITE_MAP_TILE_URL` (por ejemplo MapTiler, Stadia Maps o Carto) y mostrar siempre su atribución.
- Sí se generan **enlaces universales de Google Maps** para navegación:
  - Ver punto: `https://www.google.com/maps/search/?api=1&query={lat},{lng}`
  - Indicaciones: `https://www.google.com/maps/dir/?api=1&origin={lat},{lng}&destination={lat},{lng}&travelmode=walking|driving`
- Las rutas se guardan inicialmente como **tramos con origen/destino y una geometría opcional** (`GeoJSON LineString` dibujada a mano). El cálculo vial en tiempo real queda fuera del MVP.

**Esquema visual de marcadores:**

| Tipo | Color sugerido | Icono |
|---|---|---|
| Alojamiento | Violeta | cama |
| Actividad | Verde | senderismo |
| Restaurante / café | Naranja | cubiertos |
| Playa / punto natural | Turquesa | ola |
| Transporte / puerto / aeropuerto | Azul | barco o avión |
| Salud / emergencia | Rojo | cruz |
| Compras / servicio | Amarillo | bolsa |
| Mirador / foto | Rosa | cámara |

### 6.3 Alojamientos (`/trips/:tripId/stays`)

Vista de **tarjetas** (por defecto en móvil) y vista de **tabla** (por defecto en escritorio), agrupables por zona.

**Campos de la ficha:**

- Nombre, zona, dirección, latitud y longitud.
- Tipo: hotel, villa, resort, hostal, apartamento, homestay.
- **Piscina**: privada, compartida o ninguna.
- Fechas (`check_in`, `check_out`), **noches calculadas**, tipo de habitación y m².
- Precio total, **precio por noche calculado**, moneda original y conversión de referencia a EUR.
- Desayuno incluido, pago en destino, cancelación gratuita y **fecha límite de cancelación**.
- Estado de decisión: `candidato`, `favorito`, `seleccionado`, `reservado`, `descartado` (+ motivo de descarte).
- Estado de pago: `sin_coste`, `no_pagado`, `deposito`, `parcialmente_pagado`, `pagado`, `reembolsado`.
- Valoración, número de opiniones y valoración de ubicación (opcionales, **con fecha de consulta**).
- Pros, contras, ambiente, **comodidad sin moto** y distancias a puntos clave (playa, puerto, centro).
- Enlace de Booking, web oficial, teléfono, email.
- Fotos por URL o subida privada. **No copiar contenido protegido de forma masiva**; una foto de portada por alojamiento es suficiente.
- Comentarios y adjuntos (confirmación de reserva en PDF).

**Comportamientos obligatorios:**

- Al marcar un alojamiento como `reservado`, ofrecer **crear o vincular su partida de gasto**; si ya existe, vincular, **nunca duplicar**.
- Al marcar `seleccionado` un alojamiento de una zona, avisar si ya había otro `seleccionado`/`reservado` en la misma zona y ofrecer degradarlo a `candidato`.
- Detectar **solapes de fechas** entre alojamientos activos y advertir.
- Detectar **huecos**: noches del viaje sin alojamiento activo (hoy: ninguna, pero Ubud está solo en `favorito`).
- Ordenaciones: precio total, precio/noche, valoración, distancia al centro, estado.

### 6.4 Actividades y lugares (`/trips/:tripId/places`)

Una ficha puede representar una **actividad reservable** o un **lugar de interés**.

**Campos:**

- Nombre, categoría, zona y ubicación.
- Estado: `idea`, `candidato`, `favorito`, `planificado`, `reservado`, `realizado`, `descartado`.
- Duración estimada.
- Precio por persona o por grupo, y número de personas.
- Horario o ventana horaria recomendada.
- **Dependencia climática** y **alternativa de lluvia** (referencia a otro lugar/actividad).
- Necesidad de reserva y fecha límite.
- Proveedor, URL, referencia de reserva y estado de pago.
- Qué llevar, nivel de esfuerzo, notas.
- Día asignado del itinerario, si lo hay.
- Etiquetas libres (`snorkel`, `templo`, `sunset`, `barato`, `lluvia-ok`…).

**Comportamientos:**

- Botón `Añadir al día…` que crea el `itinerary_item` correspondiente.
- Al pasar a `reservado`, ofrecer crear la partida de gasto vinculada.
- Filtro rápido **"planes para día de lluvia"** (`weather_dependent = false` o con alternativa definida).
- Vista agrupada por zona con contador de horas planificadas por día.

### 6.5 Comparador (`/trips/:tripId/compare`)

- Seleccionar de **2 a 4** elementos del mismo tipo (normalmente alojamientos de la misma zona).
- Tabla en paralelo: precio total, precio/noche, valoración, ubicación, piscina, desayuno, cancelación, distancia a pie a puntos clave, pros y contras.
- Resaltar automáticamente el mejor valor de cada fila (más barato, mejor valorado, más cerca).
- Botón directo para marcar uno como `seleccionado` y degradar el resto a `candidato`.
- El estado de la comparación va en la URL (`?ids=a,b,c`) para poder compartirla.

### 6.6 Itinerario (`/trips/:tripId/itinerary`)

- Un registro por **día real del viaje**: del 08/10/2026 al 21/10/2026 (incluye días de vuelo).
- Cada día muestra: zona, alojamiento vigente esa noche, elementos planificados en orden, traslados y notas.
- **Reordenar** elementos por arrastre; **mover** un elemento a otro día.
- Elementos con hora opcional; si no hay hora, se ordenan manualmente.
- Aviso de **sobrecarga**: suma de duraciones + traslados por encima de ~10 h.
- Aviso de **incoherencia de zona**: actividad en Ubud un día en que se duerme en Gili.
- Vista **timeline** vertical en móvil y **columnas por día** en escritorio.
- Botón "ver este día en el mapa".
- Campo **plan B por lluvia** a nivel de día.
- Exportación del itinerario a texto/markdown para copiarlo a WhatsApp.

### 6.7 Rutas y transportes (`/trips/:tripId/routes`)

Modela todo desplazamiento: vuelos, fast boats, conductores privados, Grab/Gojek, traslados a pie, bicicleta y cidomo.

**Campos:**

- Origen y destino (lugar del viaje o etiqueta libre como "Aeropuerto DPS").
- Modo: `walk`, `bike`, `cidomo`, `grab`, `taxi`, `private_driver`, `shuttle`, `fast_boat`, `ferry`, `flight`, `other`.
- Fecha, hora de salida y de llegada, duración y distancia estimadas.
- Coste y moneda, quién paga, estado de pago.
- Operador, enlace de reserva, referencia y teléfono de contacto.
- Estado: `idea`, `requiere_confirmacion`, `reservada`, `confirmada`, `en_riesgo`, `descartada`.
- **Nivel de riesgo** y notas de riesgo (obligatorio rellenar en el tramo DPS → Gili).
- **Ruta alternativa**: una ruta puede apuntar a otra como plan B (`alternative_of`).
- Geometría opcional (`GeoJSON LineString`) para dibujar el tramo en el mapa.

**Comportamientos:**

- Vista cronológica de todos los traslados del viaje.
- Las rutas `en_riesgo` aparecen destacadas en el dashboard hasta resolverse.
- Botón "abrir indicaciones en Google Maps" cuando hay coordenadas en ambos extremos.
- **Estimador de Grab**: campo simple `cost_estimate` editable a mano + nota de referencia. No se integra con la API de Grab.
- Al crear una ruta con coste, ofrecer crear la partida de gasto vinculada.

### 6.8 Presupuesto y gastos (`/trips/:tripId/budget`)

Este módulo responde a "cuánto dinero llevamos entre las cosas marcadas".

**Vistas:**

1. **Resumen**: presupuesto total definido, **previsto** (todo lo activo), **comprometido** (reservado no pagado), **pagado**, **pendiente de pago** y **restante frente al presupuesto**. Todo con desglose por categoría y por zona.
2. **Lista de gastos** con filtros por categoría, zona, día, estado de pago y pagador.
3. **Reparto** (`/budget/settle`): cuánto ha puesto cada uno y quién debe a quién.
4. **Simulador**: activar/desactivar candidatos para ver cómo cambia el total. Por ejemplo, comparar el total del viaje con Divara (104 €) frente a Korurua (242 €) en Ubud.

**Categorías:** `alojamiento`, `transporte_internacional`, `transporte_local`, `actividad`, `comida`, `compras`, `tasas_visado`, `seguro`, `salud`, `otros`.

**Estados de pago:** `previsto`, `comprometido`, `parcialmente_pagado`, `pagado`, `reembolsado`, `cancelado`.

**Reglas:**

- Un gasto puede estar vinculado a un alojamiento, una actividad o una ruta; o ser libre (comida diaria, souvenirs).
- Cada gasto guarda importe, moneda, **importe convertido a EUR**, tipo de cambio usado y fecha del cambio.
- **Marcar como pagado** en un toque desde la lista, la ficha o el mapa.
- Los alojamientos con `pay_at_property = true` (Moson) cuentan como **comprometido**, no como pagado, hasta el check-in.
- El presupuesto de referencia se define en ajustes (total y opcionalmente diario para comida/extras).
- **Gasto diario**: campo rápido para registrar el gasto en efectivo del día durante el viaje, con conversión IDR → EUR.
- Todos los totales se calculan en el cliente a partir de los datos, o mediante una vista SQL; nunca se almacenan denormalizados sin recalcular.

**Reparto entre viajeros:**

- Por defecto **50/50** entre los dos miembros.
- Soporta reparto `igual`, `porcentaje`, `importe_exacto` y `solo_uno`.
- Pantalla de liquidación: "Elena debe 87,50 € a Daniel" con botón "marcar liquidado".

### 6.9 Documentos y reservas (`/trips/:tripId/documents`)

- Subida de PDF e imágenes a **Supabase Storage en bucket privado**.
- Acceso mediante **URLs firmadas de corta duración**. Nunca bucket público.
- Tipos: `reserva_alojamiento`, `billete_vuelo`, `billete_barco`, `seguro`, `visado`, `pasaporte`, `vacunas`, `otro`.
- Cada documento puede vincularse a un alojamiento, actividad, ruta o al viaje.
- Campos: título, tipo, referencia de reserva, fecha relevante, notas.
- **Marcado explícito de documento sensible** (pasaporte): oculto por defecto tras un toque de confirmación.
- Descarga y apertura desde el móvil, con opción de "disponible offline" (cachear el archivo).

### 6.10 Apps, enlaces y contactos (`/trips/:tripId/tools`)

- Lista de apps útiles con categoría, enlace a la tienda y nota de uso (sección 3.7).
- Enlaces útiles: blogs, guías, listas de restaurantes, mapa de fast boats.
- Contactos: alojamientos, conductores, seguro, emergencias, embajada (sección 3.8).
- Cada contacto con botones `Llamar` (`tel:`) y `WhatsApp` (`https://wa.me/{numero}`).

### 6.11 Checklists (`/trips/:tripId/checklists`)

- Listas predefinidas al crear el viaje: **Antes de salir**, **Equipaje**, **Documentos**, **En destino**.
- Ítems con responsable (Daniel/Elena), fecha límite y estado.
- Ítems iniciales obligatorios:
  - Confirmar fast boat del 9/10 y su hora límite.
  - Registrar la fecha límite de cancelación de Moson.
  - Decidir alojamiento de Ubud.
  - Comprobar requisitos de entrada vigentes (e-VOA / e-CD) en la web oficial.
  - Contratar seguro de viaje y guardar la póliza.
  - Descargar mapas offline de Bali y Lombok.
  - Avisar al banco / configurar tarjeta sin comisiones.
  - Comprobar vigencia del pasaporte (mínimo 6 meses).
- Barra de progreso por lista y contador en el dashboard.

### 6.12 Comentarios (transversal)

- Disponibles en alojamientos, actividades, lugares, días, rutas, gastos y documentos.
- Texto plano con saltos de línea y enlaces autodetectados. Sin editor rico en el MVP.
- Autor, avatar y fecha relativa ("hace 2 h").
- Contador de comentarios visible en las tarjetas y en el marcador del mapa.
- Notificación ligera en el dashboard: "3 comentarios nuevos desde tu última visita".

### 6.13 Búsqueda global

- Un único campo (`Cmd/Ctrl + K` en escritorio, lupa en móvil) que busca en lugares, alojamientos, actividades, rutas, gastos, documentos y comentarios.
- Resultados agrupados por tipo, con acceso directo a la ficha.

### 6.14 Ajustes (`/trips/:tripId/settings`)

- Nombre y fechas del viaje.
- Miembros: invitar, cambiar rol, expulsar.
- **Moneda base** (EUR) y **moneda de destino** (IDR) con tipo de cambio manual y su fecha.
- Presupuesto objetivo total y diario.
- Zonas del viaje: nombre, fechas, color y orden.
- Preferencias: mostrar descartados, unidades, formato de fecha, tema claro/oscuro.
- Exportar todos los datos del viaje a JSON (copia de seguridad).

---

## 7. Modelo de datos

Base de datos: **PostgreSQL en Supabase**. Todas las tablas de dominio cuelgan de `trips` y llevan `trip_id` para simplificar RLS.

### 7.1 Decisiones de modelado

- **Enums como `text` + `CHECK`**, no como tipos `enum` de Postgres: añadir un valor nuevo es una migración trivial y no bloquea.
- **`places` es la tabla central polimórfica** de "cosas con ubicación". Los alojamientos y actividades extienden `places` con tablas 1-1 (`stay_details`, `activity_details`). Esto evita duplicar nombre, coordenadas, estado, notas y comentarios.
- **El dinero vive en `expenses`**, no en las fichas. Una ficha puede tener `price_amount` como *referencia comprobada*; el gasto real y su estado de pago están en `expenses`. Nunca se suman precios de fichas para calcular el presupuesto.
- **`numeric(12,2)`** para importes, con `currency` en ISO-4217. Se guarda además `amount_eur` cacheado + `fx_rate` + `fx_date` para que un cambio de tipo no reescriba el histórico.
- **Nada se borra.** `status = 'descartado'` y `deleted_at` para borrado lógico.
- `created_by`, `updated_by`, `created_at`, `updated_at` en todas las tablas editables.

### 7.2 Esquema SQL

```sql
-- =========================================================
-- 00_extensions.sql
-- =========================================================
create extension if not exists "pgcrypto";

-- =========================================================
-- 01_profiles.sql
-- =========================================================
create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  avatar_url  text,
  created_at  timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =========================================================
-- 02_trips.sql
-- =========================================================
create table public.trips (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  slug           text unique,
  destination    text,
  start_date     date not null,
  end_date       date not null,
  base_currency  char(3) not null default 'EUR',   -- moneda en la que pensamos
  local_currency char(3) not null default 'IDR',   -- moneda del destino
  budget_total   numeric(12,2),
  budget_daily   numeric(12,2),
  travellers     int not null default 2,
  created_by     uuid not null references auth.users(id),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  constraint trips_dates_ok check (end_date >= start_date)
);

create table public.trip_members (
  trip_id   uuid not null references public.trips(id) on delete cascade,
  user_id   uuid not null references auth.users(id) on delete cascade,
  role      text not null default 'editor' check (role in ('owner','editor','viewer')),
  joined_at timestamptz not null default now(),
  primary key (trip_id, user_id)
);

create table public.trip_invites (
  id         uuid primary key default gen_random_uuid(),
  trip_id    uuid not null references public.trips(id) on delete cascade,
  email      text,
  role       text not null default 'editor' check (role in ('owner','editor','viewer')),
  token      text not null unique default encode(gen_random_bytes(24), 'hex'),
  expires_at timestamptz not null default (now() + interval '30 days'),
  accepted_at timestamptz,
  accepted_by uuid references auth.users(id),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

-- =========================================================
-- 03_zones.sql   (Gili / Ubud / Seminyak)
-- =========================================================
create table public.zones (
  id         uuid primary key default gen_random_uuid(),
  trip_id    uuid not null references public.trips(id) on delete cascade,
  name       text not null,
  slug       text not null,
  start_date date,
  end_date   date,
  color      text,
  center_lat numeric(9,6),
  center_lng numeric(9,6),
  sort_order int not null default 0,
  notes      text,
  unique (trip_id, slug)
);

-- =========================================================
-- 04_places.sql   (tabla central: todo lo que tiene ubicación)
-- =========================================================
create table public.places (
  id            uuid primary key default gen_random_uuid(),
  trip_id       uuid not null references public.trips(id) on delete cascade,
  zone_id       uuid references public.zones(id) on delete set null,

  name          text not null,
  kind          text not null check (kind in (
                  'stay','activity','food','beach','transport',
                  'health','shopping','viewpoint','other')),
  category      text,                 -- libre: 'templo', 'snorkel', 'beach club'...
  status        text not null default 'idea' check (status in (
                  'idea','candidato','favorito','seleccionado','planificado',
                  'reservado','realizado','descartado')),
  discard_reason text,                -- 'sin_disponibilidad', 'caro', 'mal_ubicado'...

  address       text,
  lat           numeric(9,6),
  lng           numeric(9,6),
  geocode_source text,                -- 'manual' | 'nominatim' | 'gmaps_link'

  -- precio de referencia comprobado (NO es el presupuesto)
  price_amount  numeric(12,2),
  price_currency char(3) default 'EUR',
  price_basis   text check (price_basis in ('total','por_noche','por_persona','por_grupo')),
  price_pending boolean not null default false,
  price_source  text,                 -- 'booking', 'web oficial', 'whatsapp'
  checked_at    date,                 -- fecha en que se comprobó el precio

  rating         numeric(3,1),
  rating_count   int,
  location_rating numeric(3,1),
  rating_checked_at date,

  -- movilidad sin moto
  walk_minutes_to_center int,
  walk_minutes_to_beach  int,
  walk_minutes_to_port   int,
  transport_notes text,

  booking_url   text,
  website_url   text,
  gmaps_url     text,
  phone         text,
  email         text,
  cover_image_url text,

  pros          text[] not null default '{}',
  cons          text[] not null default '{}',
  tags          text[] not null default '{}',
  notes         text,

  created_by    uuid references auth.users(id),
  updated_by    uuid references auth.users(id),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz
);

create index places_trip_idx    on public.places (trip_id);
create index places_zone_idx    on public.places (zone_id);
create index places_kind_idx    on public.places (trip_id, kind);
create index places_status_idx  on public.places (trip_id, status);
create index places_geo_idx     on public.places (lat, lng);

-- Detalle de alojamiento (1-1 con places donde kind = 'stay')
create table public.stay_details (
  place_id      uuid primary key references public.places(id) on delete cascade,
  stay_type     text check (stay_type in ('hotel','villa','resort','hostal','apartamento','homestay','otro')),
  check_in      date,
  check_out     date,
  nights        int generated always as (greatest((check_out - check_in), 0)) stored,
  room_type     text,
  room_size_m2  int,
  guests        int not null default 2,
  pool          text check (pool in ('privada','compartida','ninguna')),
  breakfast_included boolean,
  pay_at_property    boolean not null default false,
  free_cancellation  boolean,
  cancellation_deadline timestamptz,
  booking_reference  text,
  distance_to_beach_m  int,
  distance_to_center_m int,
  constraint stay_dates_ok check (check_out is null or check_in is null or check_out >= check_in)
);

-- Detalle de actividad (1-1 con places donde kind = 'activity')
create table public.activity_details (
  place_id           uuid primary key references public.places(id) on delete cascade,
  duration_minutes   int,
  price_per_person   numeric(12,2),
  price_group        numeric(12,2),
  people             int not null default 2,
  time_window_start  time,
  time_window_end    time,
  weather_dependent  boolean not null default false,
  rain_alternative_place_id uuid references public.places(id) on delete set null,
  booking_required   boolean not null default false,
  booking_deadline   date,
  provider           text,
  booking_reference  text,
  effort_level       text check (effort_level in ('bajo','medio','alto')),
  what_to_bring      text
);

-- =========================================================
-- 05_itinerary.sql
-- =========================================================
create table public.itinerary_days (
  id       uuid primary key default gen_random_uuid(),
  trip_id  uuid not null references public.trips(id) on delete cascade,
  date     date not null,
  zone_id  uuid references public.zones(id) on delete set null,
  title    text,
  summary  text,
  rain_plan text,
  notes    text,
  unique (trip_id, date)
);

create table public.itinerary_items (
  id          uuid primary key default gen_random_uuid(),
  trip_id     uuid not null references public.trips(id) on delete cascade,
  day_id      uuid not null references public.itinerary_days(id) on delete cascade,
  place_id    uuid references public.places(id) on delete cascade,
  route_id    uuid,                      -- FK añadida tras crear routes
  title       text,                      -- libre si no hay place ni route
  start_time  time,
  end_time    time,
  duration_minutes int,
  sort_order  int not null default 0,
  status      text not null default 'planificado' check (status in (
                'planificado','confirmado','realizado','cancelado')),
  notes       text,
  created_by  uuid references auth.users(id),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index itinerary_items_day_idx on public.itinerary_items (day_id, sort_order);

-- =========================================================
-- 06_routes.sql
-- =========================================================
create table public.routes (
  id            uuid primary key default gen_random_uuid(),
  trip_id       uuid not null references public.trips(id) on delete cascade,

  from_place_id uuid references public.places(id) on delete set null,
  to_place_id   uuid references public.places(id) on delete set null,
  from_label    text,                    -- 'Aeropuerto DPS', 'Puerto de Padang Bai'
  to_label      text,
  from_lat numeric(9,6), from_lng numeric(9,6),
  to_lat   numeric(9,6), to_lng   numeric(9,6),

  mode          text not null check (mode in (
                  'walk','bike','cidomo','grab','taxi','private_driver',
                  'shuttle','fast_boat','ferry','flight','other')),
  date          date,
  depart_at     timestamptz,
  arrive_at     timestamptz,
  duration_minutes int,
  distance_km   numeric(8,2),

  cost_amount   numeric(12,2),
  cost_currency char(3) default 'EUR',
  cost_is_estimate boolean not null default true,

  operator      text,
  booking_url   text,
  booking_reference text,
  contact_phone text,

  status        text not null default 'idea' check (status in (
                  'idea','requiere_confirmacion','reservada','confirmada',
                  'en_riesgo','descartada')),
  risk_level    text check (risk_level in ('bajo','medio','alto')),
  risk_notes    text,
  alternative_of uuid references public.routes(id) on delete set null,

  geometry      jsonb,                   -- GeoJSON LineString opcional
  notes         text,

  created_by    uuid references auth.users(id),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz
);

create index routes_trip_date_idx on public.routes (trip_id, date);

alter table public.itinerary_items
  add constraint itinerary_items_route_fk
  foreign key (route_id) references public.routes(id) on delete cascade;

-- =========================================================
-- 07_money.sql
-- =========================================================
create table public.fx_rates (
  id      uuid primary key default gen_random_uuid(),
  base    char(3) not null,
  quote   char(3) not null,
  rate    numeric(18,8) not null,
  as_of   date not null,
  source  text,
  unique (base, quote, as_of)
);

create table public.expenses (
  id          uuid primary key default gen_random_uuid(),
  trip_id     uuid not null references public.trips(id) on delete cascade,
  place_id    uuid references public.places(id) on delete set null,
  route_id    uuid references public.routes(id) on delete set null,
  day_id      uuid references public.itinerary_days(id) on delete set null,

  label       text not null,
  category    text not null check (category in (
                'alojamiento','transporte_internacional','transporte_local',
                'actividad','comida','compras','tasas_visado','seguro','salud','otros')),

  amount      numeric(12,2) not null,
  currency    char(3) not null default 'EUR',
  amount_eur  numeric(12,2),             -- cacheado
  fx_rate     numeric(18,8),
  fx_date     date,

  status      text not null default 'previsto' check (status in (
                'previsto','comprometido','parcialmente_pagado',
                'pagado','reembolsado','cancelado')),
  amount_paid numeric(12,2) not null default 0,
  paid_by     uuid references auth.users(id),
  paid_at     timestamptz,
  payment_method text check (payment_method in ('tarjeta','efectivo','transferencia','en_destino','otro')),
  due_date    date,

  split_type  text not null default 'igual' check (split_type in ('igual','porcentaje','importe_exacto','solo_uno')),
  receipt_document_id uuid,              -- FK añadida tras crear documents
  notes       text,

  created_by  uuid references auth.users(id),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz,
  constraint expenses_amount_positive check (amount >= 0),
  constraint expenses_paid_ok check (amount_paid >= 0 and amount_paid <= amount)
);

create index expenses_trip_idx   on public.expenses (trip_id);
create index expenses_status_idx on public.expenses (trip_id, status);

create table public.expense_shares (
  id         uuid primary key default gen_random_uuid(),
  expense_id uuid not null references public.expenses(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  share_pct    numeric(6,3),
  share_amount numeric(12,2),
  settled    boolean not null default false,
  unique (expense_id, user_id)
);

-- =========================================================
-- 08_content.sql
-- =========================================================
create table public.documents (
  id          uuid primary key default gen_random_uuid(),
  trip_id     uuid not null references public.trips(id) on delete cascade,
  entity_type text check (entity_type in ('trip','place','route','expense','day')),
  entity_id   uuid,
  title       text not null,
  doc_type    text not null check (doc_type in (
                'reserva_alojamiento','billete_vuelo','billete_barco','seguro',
                'visado','pasaporte','vacunas','recibo','otro')),
  storage_path text,                     -- bucket privado 'trip-docs'
  external_url text,
  mime_type   text,
  size_bytes  bigint,
  reference   text,
  relevant_date date,
  is_sensitive boolean not null default false,
  notes       text,
  uploaded_by uuid references auth.users(id),
  created_at  timestamptz not null default now()
);

alter table public.expenses
  add constraint expenses_receipt_fk
  foreign key (receipt_document_id) references public.documents(id) on delete set null;

create table public.comments (
  id          uuid primary key default gen_random_uuid(),
  trip_id     uuid not null references public.trips(id) on delete cascade,
  entity_type text not null check (entity_type in ('place','route','expense','day','document','trip')),
  entity_id   uuid not null,
  parent_id   uuid references public.comments(id) on delete cascade,
  body        text not null,
  author_id   uuid not null references auth.users(id) on delete cascade,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

create index comments_entity_idx on public.comments (trip_id, entity_type, entity_id);

create table public.checklists (
  id      uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips(id) on delete cascade,
  name    text not null,
  sort_order int not null default 0
);

create table public.checklist_items (
  id           uuid primary key default gen_random_uuid(),
  checklist_id uuid not null references public.checklists(id) on delete cascade,
  trip_id      uuid not null references public.trips(id) on delete cascade,
  label        text not null,
  done         boolean not null default false,
  done_at      timestamptz,
  assignee_id  uuid references auth.users(id) on delete set null,
  due_date     date,
  notes        text,
  sort_order   int not null default 0
);

create table public.tools (
  id       uuid primary key default gen_random_uuid(),
  trip_id  uuid not null references public.trips(id) on delete cascade,
  name     text not null,
  category text check (category in ('transporte','mapas','alojamiento','dinero','idioma','clima','comunicacion','tramites','otros')),
  url      text,
  ios_url  text,
  android_url text,
  notes    text,
  sort_order int not null default 0
);

create table public.contacts (
  id       uuid primary key default gen_random_uuid(),
  trip_id  uuid not null references public.trips(id) on delete cascade,
  place_id uuid references public.places(id) on delete set null,
  name     text not null,
  contact_type text check (contact_type in ('alojamiento','transporte','actividad','emergencia','seguro','embajada','otro')),
  phone    text,
  whatsapp text,
  email    text,
  notes    text
);

create table public.activity_log (
  id          uuid primary key default gen_random_uuid(),
  trip_id     uuid not null references public.trips(id) on delete cascade,
  actor_id    uuid references auth.users(id) on delete set null,
  entity_type text not null,
  entity_id   uuid,
  action      text not null,            -- 'create' | 'update' | 'status_change' | 'delete'
  field       text,
  before_value jsonb,
  after_value  jsonb,
  created_at  timestamptz not null default now()
);

create index activity_log_trip_idx on public.activity_log (trip_id, created_at desc);

-- =========================================================
-- 09_triggers.sql
-- =========================================================
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

do $$
declare t text;
begin
  foreach t in array array[
    'trips','places','itinerary_items','routes','expenses','comments'
  ] loop
    execute format(
      'create trigger trg_touch_%1$s before update on public.%1$s
         for each row execute function public.touch_updated_at()', t);
  end loop;
end $$;
```

### 7.3 Vistas de conveniencia

```sql
-- Resumen de presupuesto por viaje
create or replace view public.v_budget_summary as
select
  e.trip_id,
  sum(coalesce(e.amount_eur, e.amount)) filter (where e.status <> 'cancelado')                as previsto_eur,
  sum(coalesce(e.amount_eur, e.amount)) filter (where e.status = 'comprometido')              as comprometido_eur,
  sum(e.amount_paid)                                                                          as pagado_eur,
  sum(coalesce(e.amount_eur, e.amount) - e.amount_paid)
      filter (where e.status not in ('cancelado','reembolsado'))                              as pendiente_eur
from public.expenses e
where e.deleted_at is null
group by e.trip_id;

-- Gasto por categoría
create or replace view public.v_budget_by_category as
select trip_id, category,
       sum(coalesce(amount_eur, amount)) as total_eur,
       sum(amount_paid)                  as pagado_eur
from public.expenses
where deleted_at is null and status <> 'cancelado'
group by trip_id, category;

-- Quién ha puesto cuánto
create or replace view public.v_settlement as
select e.trip_id, e.paid_by as user_id, sum(e.amount_paid) as aportado_eur
from public.expenses e
where e.deleted_at is null and e.amount_paid > 0
group by e.trip_id, e.paid_by;
```

> Las vistas heredan RLS de las tablas base si se crean con `security_invoker = true` (Postgres 15+). Declararlas así:
> `alter view public.v_budget_summary set (security_invoker = true);` — repetir en todas.

---

## 8. Seguridad y RLS

**Regla de oro: RLS activado en todas las tablas de dominio, sin excepción.** El cliente usa únicamente la `anon key`. La `service_role key` **jamás** llega al navegador ni al repositorio.

### 8.1 Funciones auxiliares

```sql
create or replace function public.is_trip_member(p_trip uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.trip_members m
    where m.trip_id = p_trip and m.user_id = auth.uid()
  );
$$;

create or replace function public.is_trip_editor(p_trip uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.trip_members m
    where m.trip_id = p_trip and m.user_id = auth.uid()
      and m.role in ('owner','editor')
  );
$$;

create or replace function public.is_trip_owner(p_trip uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.trip_members m
    where m.trip_id = p_trip and m.user_id = auth.uid() and m.role = 'owner'
  );
$$;
```

> `security definer` evita la recursión infinita clásica de RLS cuando una política sobre `trip_members` consulta `trip_members`.

### 8.2 Políticas

```sql
alter table public.profiles        enable row level security;
alter table public.trips           enable row level security;
alter table public.trip_members    enable row level security;
alter table public.trip_invites    enable row level security;
alter table public.zones           enable row level security;
alter table public.places          enable row level security;
alter table public.stay_details    enable row level security;
alter table public.activity_details enable row level security;
alter table public.itinerary_days  enable row level security;
alter table public.itinerary_items enable row level security;
alter table public.routes          enable row level security;
alter table public.expenses        enable row level security;
alter table public.expense_shares  enable row level security;
alter table public.documents       enable row level security;
alter table public.comments        enable row level security;
alter table public.checklists      enable row level security;
alter table public.checklist_items enable row level security;
alter table public.tools           enable row level security;
alter table public.contacts        enable row level security;
alter table public.activity_log    enable row level security;
alter table public.fx_rates        enable row level security;

-- Perfiles: cada uno el suyo; lectura de los miembros de tus viajes
create policy profiles_self on public.profiles
  for all using (id = auth.uid()) with check (id = auth.uid());

create policy profiles_read_teammates on public.profiles
  for select using (
    exists (
      select 1 from public.trip_members m1
      join public.trip_members m2 on m1.trip_id = m2.trip_id
      where m1.user_id = auth.uid() and m2.user_id = profiles.id
    )
  );

-- Viajes
create policy trips_select on public.trips
  for select using (public.is_trip_member(id));
create policy trips_insert on public.trips
  for insert with check (created_by = auth.uid());
create policy trips_update on public.trips
  for update using (public.is_trip_editor(id)) with check (public.is_trip_editor(id));
create policy trips_delete on public.trips
  for delete using (public.is_trip_owner(id));

-- Miembros
create policy members_select on public.trip_members
  for select using (public.is_trip_member(trip_id));
create policy members_write on public.trip_members
  for all using (public.is_trip_owner(trip_id)) with check (public.is_trip_owner(trip_id));

-- Patrón genérico para las tablas con trip_id.
-- Repetir literalmente para: zones, places, itinerary_days, itinerary_items,
-- routes, expenses, documents, checklists, checklist_items, tools, contacts.
create policy places_select on public.places
  for select using (public.is_trip_member(trip_id));
create policy places_insert on public.places
  for insert with check (public.is_trip_editor(trip_id));
create policy places_update on public.places
  for update using (public.is_trip_editor(trip_id)) with check (public.is_trip_editor(trip_id));
create policy places_delete on public.places
  for delete using (public.is_trip_editor(trip_id));

-- Tablas hijas sin trip_id: se resuelven por el padre
create policy stay_details_all on public.stay_details
  for all using (
    exists (select 1 from public.places p where p.id = stay_details.place_id and public.is_trip_member(p.trip_id))
  ) with check (
    exists (select 1 from public.places p where p.id = stay_details.place_id and public.is_trip_editor(p.trip_id))
  );

create policy expense_shares_all on public.expense_shares
  for all using (
    exists (select 1 from public.expenses e where e.id = expense_shares.expense_id and public.is_trip_member(e.trip_id))
  ) with check (
    exists (select 1 from public.expenses e where e.id = expense_shares.expense_id and public.is_trip_editor(e.trip_id))
  );

-- Comentarios: leer todos los del viaje; editar/borrar solo los propios
create policy comments_select on public.comments
  for select using (public.is_trip_member(trip_id));
create policy comments_insert on public.comments
  for insert with check (public.is_trip_editor(trip_id) and author_id = auth.uid());
create policy comments_update on public.comments
  for update using (author_id = auth.uid()) with check (author_id = auth.uid());
create policy comments_delete on public.comments
  for delete using (author_id = auth.uid() or public.is_trip_owner(trip_id));

-- Log: solo lectura para miembros; escritura desde triggers/servidor
create policy activity_log_select on public.activity_log
  for select using (public.is_trip_member(trip_id));
create policy activity_log_insert on public.activity_log
  for insert with check (public.is_trip_member(trip_id));

-- Tipos de cambio: lectura para autenticados
create policy fx_select on public.fx_rates for select using (auth.role() = 'authenticated');

-- Invitaciones: el owner gestiona; el invitado canjea por RPC
create policy invites_owner on public.trip_invites
  for all using (public.is_trip_owner(trip_id)) with check (public.is_trip_owner(trip_id));
```

### 8.3 Canje de invitación

El invitado **no** puede leer `trip_invites` (no es miembro todavía). El canje se hace con una función `security definer`:

```sql
create or replace function public.redeem_invite(p_token text)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_invite public.trip_invites;
begin
  select * into v_invite from public.trip_invites
   where token = p_token and accepted_at is null and expires_at > now();
  if not found then raise exception 'Invitación inválida o caducada'; end if;

  insert into public.trip_members (trip_id, user_id, role)
  values (v_invite.trip_id, auth.uid(), v_invite.role)
  on conflict (trip_id, user_id) do nothing;

  update public.trip_invites
     set accepted_at = now(), accepted_by = auth.uid()
   where id = v_invite.id;

  return v_invite.trip_id;
end $$;

revoke all on function public.redeem_invite(text) from public;
grant execute on function public.redeem_invite(text) to authenticated;
```

### 8.4 Storage

- Bucket **`trip-docs`**, **privado**. Nunca público.
- Convención de ruta: `{trip_id}/{entity_type}/{document_id}-{nombre}`.
- Políticas de storage que comprueban pertenencia al viaje leyendo el primer segmento de la ruta:

```sql
create policy "trip docs read" on storage.objects
  for select using (
    bucket_id = 'trip-docs'
    and public.is_trip_member(((storage.foldername(name))[1])::uuid)
  );

create policy "trip docs write" on storage.objects
  for insert with check (
    bucket_id = 'trip-docs'
    and public.is_trip_editor(((storage.foldername(name))[1])::uuid)
  );
```

- El cliente accede a los archivos mediante **`createSignedUrl`** con caducidad corta (300 s).
- Límite de subida: 10 MB por archivo. Tipos permitidos: PDF, JPEG, PNG, WebP, HEIC.

---

## 9. Reglas de negocio y cálculos

### 9.1 Estados y transiciones

**Alojamientos y lugares** (`places.status`):

```
idea → candidato → favorito → seleccionado → reservado → realizado
  ↘         ↘          ↘            ↘
              descartado  (siempre reversible, nunca borra)
```

- Solo **un** alojamiento por zona puede estar en `seleccionado` o `reservado`. Al promover otro, la app pide confirmación y degrada el anterior a `candidato`.
- `descartado` exige `discard_reason`.
- Todo cambio de `status` escribe en `activity_log`.

**Rutas** (`routes.status`): `idea → requiere_confirmacion → reservada → confirmada`, con `en_riesgo` como marca transversal y `descartada` como salida.

**Gastos** (`expenses.status`): `previsto → comprometido → parcialmente_pagado → pagado`, con `reembolsado` y `cancelado` como estados finales.

### 9.2 Cálculo del presupuesto

| Métrica | Definición |
|---|---|
| **Previsto** | Suma de `amount_eur` de todos los gastos no cancelados |
| **Comprometido** | Gastos en `comprometido` (reservado, aún no pagado). Incluye Moson por `pay_at_property` |
| **Pagado** | Suma de `amount_paid` |
| **Pendiente** | `previsto − pagado`, excluyendo cancelados y reembolsados |
| **Restante** | `trips.budget_total − previsto` |
| **Por persona** | `previsto / trips.travellers` |
| **Por día** | `previsto / número de días del viaje` |

Reglas:

- Un alojamiento `reservado` **debe** tener su gasto asociado; si no lo tiene, aparece como alerta en el dashboard.
- Los precios de fichas en estado `candidato` **no** entran en el presupuesto: entran en el **simulador**, que calcula "total si eligiéramos X".
- El simulador muestra siempre el delta frente a la selección actual (ej.: *Ubud: Divara 104 € vs Korurua 242 € → +138 €*).

### 9.3 Conversión de moneda

- Moneda de trabajo: **EUR**. Moneda de destino: **IDR**.
- Al guardar un gasto en IDR se calcula `amount_eur = amount * fx_rate` y se persisten `fx_rate` y `fx_date`.
- El tipo de cambio se introduce **manualmente** en ajustes (fuente y fecha visibles). Opcionalmente, en fase 4, una Edge Function diaria consulta una API pública gratuita y escribe en `fx_rates`.
- **Cambiar el tipo de cambio actual no reescribe importes históricos.** Existe una acción explícita "recalcular con el tipo de hoy" que pide confirmación.
- Formato: `Intl.NumberFormat('es-ES', { style: 'currency', currency })`. IDR sin decimales.

### 9.4 Reparto entre viajeros

- Por defecto `split_type = 'igual'` → 50/50 entre los dos miembros.
- `porcentaje`: se guardan `share_pct` que deben sumar 100.
- `importe_exacto`: se guardan `share_amount` que deben sumar `amount`.
- `solo_uno`: un único `expense_share` con el 100 %.
- **Liquidación**: para cada usuario, `aportado − debido`. La pantalla muestra la transferencia mínima que salda la diferencia ("Elena → Daniel: 87,50 €") y permite marcar `settled = true` en bloque.

### 9.5 Validaciones y avisos automáticos

La app debe generar avisos (no bloqueos) cuando:

| Condición | Aviso |
|---|---|
| Noches del viaje sin alojamiento activo | "Faltan N noches por cubrir" |
| Dos alojamientos activos con fechas solapadas | "Solape del {fecha} al {fecha}" |
| `free_cancellation = true` sin `cancellation_deadline` | "Falta la fecha límite de cancelación" (caso Moson) |
| `cancellation_deadline` a menos de 7 días | "Vence la cancelación gratuita de {hotel}" |
| Ruta en `en_riesgo` o `requiere_confirmacion` | Aparece en el bloque de riesgos del dashboard |
| Lugar sin `lat`/`lng` | Entra en la bandeja "Falta ubicar" |
| Precio sin `checked_at` o `price_pending = true` | Chip "precio por confirmar" |
| Día del itinerario con más de ~10 h planificadas | "Día muy cargado" |
| Actividad en zona distinta a la del alojamiento del día | "¿Seguro? Ese día dormís en {zona}" |
| Alojamiento `reservado` sin gasto asociado | "Añade el gasto de {hotel}" |
| Actividad con `booking_deadline` pasada y sin reservar | "Se ha pasado la fecha de reserva" |

### 9.6 Cálculos derivados en cliente

- `nights = check_out − check_in`.
- `price_per_night = price_amount / nights`.
- `price_per_person = price_amount / guests`.
- Distancia aproximada entre dos puntos: **fórmula de Haversine** (suficiente para "a X km"), nunca presentada como tiempo de trayecto real.
- Los **minutos a pie** son un campo editable a mano (`walk_minutes_to_*`), no un cálculo: en Bali la distancia lineal engaña.

---

## 10. Stack técnico y estructura

### 10.1 Stack

| Capa | Elección | Motivo |
|---|---|---|
| Framework | **Vue 3** + `<script setup>` + **TypeScript** (modo estricto) | Ligero, curva suave, excelente con Vite |
| Build | **Vite 5+** | Estándar de Vue, arranque instantáneo |
| Estado | **Pinia** | Store por dominio, tipado, sencillo |
| Rutas | **Vue Router 4** | Rutas anidadas y guards de sesión |
| Estilos | **Tailwind CSS** + tokens CSS propios | Rápido, consistente, mobile-first |
| Mapa | **Leaflet 1.9** + `leaflet.markercluster` | Gratuito, sin API de pago |
| Backend | **Supabase** (Postgres + Auth + Storage + Realtime) | Todo incluido, RLS real |
| Cliente BD | `@supabase/supabase-js` v2 | — |
| Validación | **Zod** | Valida formularios y payloads |
| Fechas | **date-fns** + locale `es` | Ligero y tree-shakeable |
| Utilidades | **VueUse** | `useStorage`, `useGeolocation`, `useMediaQuery` |
| Iconos | **lucide-vue-next** | Coherentes y ligeros |
| PWA | `vite-plugin-pwa` | Instalable y offline |
| Tests unitarios | **Vitest** + Vue Test Utils | — |
| Tests E2E | **Playwright** (fase 3+) | Flujos críticos |
| Lint/format | ESLint + Prettier + `vue-tsc` | — |
| Hosting | **Vercel** | Despliegue automático desde `main` |

**Prohibiciones explícitas:**

- No usar la API de pago de Google Maps para renderizar el mapa.
- No añadir un backend propio (Node/Express): Supabase y las Edge Functions bastan.
- No usar librerías de UI pesadas (Vuetify, PrimeVue, Quasar): componentes propios + Tailwind.
- No introducir SSR/Nuxt: es una SPA privada, no necesita SEO.
- No meter la `service_role key` en el cliente ni en el repo.

### 10.2 Estructura de carpetas

```
trip-app/
├─ README.md                     ← este documento
├─ index.html
├─ package.json
├─ vite.config.ts
├─ tailwind.config.js
├─ tsconfig.json
├─ .env.example
├─ .gitignore
├─ vercel.json
├─ supabase/
│  ├─ migrations/
│  │  ├─ 0001_init.sql
│  │  ├─ 0002_rls.sql
│  │  ├─ 0003_views.sql
│  │  └─ 0004_storage.sql
│  ├─ seed/
│  │  └─ seed_bali_2026.sql      ← datos de la sección 3
│  └─ functions/                 ← Edge Functions (fase 4)
├─ public/
│  ├─ icons/                     ← iconos PWA 192/512, maskable
│  └─ manifest.webmanifest
└─ src/
   ├─ main.ts
   ├─ App.vue
   ├─ router/index.ts
   ├─ lib/
   │  ├─ supabase.ts             ← cliente único
   │  ├─ maps.ts                 ← enlaces gmaps, haversine, parseo de coordenadas
   │  ├─ money.ts                ← formato y conversión
   │  ├─ dates.ts
   │  └─ validation.ts           ← esquemas Zod
   ├─ types/
   │  ├─ database.ts             ← generado con `supabase gen types typescript`
   │  └─ domain.ts               ← tipos de dominio y uniones de estado
   ├─ stores/
   │  ├─ auth.ts
   │  ├─ trip.ts
   │  ├─ places.ts
   │  ├─ itinerary.ts
   │  ├─ routes.ts
   │  ├─ budget.ts
   │  ├─ comments.ts
   │  └─ ui.ts                   ← filtros, tema, panel abierto
   ├─ composables/
   │  ├─ useTripId.ts
   │  ├─ useFilters.ts           ← sincroniza filtros con la URL
   │  ├─ useMap.ts
   │  ├─ useRealtime.ts
   │  └─ useToast.ts
   ├─ components/
   │  ├─ ui/                     ← Button, Card, Sheet, Modal, Chip, Field, Toast…
   │  ├─ map/                    ← MapView, MarkerLayer, MapFilters, PlacePopup, PinPicker
   │  ├─ places/                 ← PlaceCard, PlaceForm, PlaceDetail, StatusBadge, PriceTag
   │  ├─ stays/                  ← StayCard, StayTable, StayCompare
   │  ├─ itinerary/              ← DayColumn, DayTimeline, ItemRow, DayPicker
   │  ├─ routes/                 ← RouteCard, RouteForm, RiskBadge
   │  ├─ budget/                 ← BudgetSummary, ExpenseRow, ExpenseForm, SettleView, Simulator
   │  ├─ comments/               ← CommentList, CommentForm
   │  └─ layout/                 ← AppShell, BottomNav, Sidebar, Fab, SearchPalette
   └─ views/
      ├─ LoginView.vue
      ├─ InviteView.vue
      ├─ TripsView.vue
      ├─ DashboardView.vue
      ├─ MapView.vue
      ├─ ItineraryView.vue
      ├─ StaysView.vue
      ├─ PlacesView.vue
      ├─ CompareView.vue
      ├─ RoutesView.vue
      ├─ BudgetView.vue
      ├─ DocumentsView.vue
      ├─ ToolsView.vue
      ├─ ChecklistsView.vue
      ├─ SettingsView.vue
      └─ NotFoundView.vue
```

### 10.3 Convenciones de código

- TypeScript **estricto**: `strict: true`, sin `any` salvo justificación en comentario.
- Componentes en `PascalCase.vue`; composables `useAlgo.ts`; stores `useAlgoStore`.
- **Nada de acceso directo a Supabase desde los componentes**: siempre a través de un store o composable.
- Tipos generados desde la base de datos, no escritos a mano:
  `npx supabase gen types typescript --project-id <id> > src/types/database.ts`
- Textos de la interfaz **en español**. Si más adelante se quiere i18n, centralizar en `src/i18n/es.ts` desde el principio.
- Commits en **Conventional Commits** (`feat:`, `fix:`, `chore:`, `docs:`).
- Una rama por fase (`feat/fase-2-mapa`), PR contra `main`.
- Errores: nunca `console.log` silencioso. Toda operación fallida muestra un toast con mensaje en español y registra el error en consola con contexto.

---

## 11. Diseño, UI y accesibilidad

### 11.1 Tono visual

Cálido y de viaje, no corporativo. Referencias: verde selva, arena, turquesa de mar. Fondos claros, tarjetas con sombra suave, radios generosos (12–16 px), tipografía legible a pleno sol.

### 11.2 Tokens

```css
:root {
  --color-bg:        #FAF9F6;
  --color-surface:   #FFFFFF;
  --color-text:      #1C2321;
  --color-muted:     #6B7280;
  --color-border:    #E5E3DD;

  --color-primary:   #0F766E;  /* verde selva  */
  --color-accent:    #F59E0B;  /* ámbar        */
  --color-sea:       #06B6D4;  /* turquesa     */

  --color-success:   #16A34A;
  --color-warning:   #D97706;
  --color-danger:    #DC2626;

  --radius:          14px;
  --shadow-card:     0 1px 2px rgba(0,0,0,.05), 0 4px 12px rgba(0,0,0,.06);
}
```

Modo oscuro mediante `@media (prefers-color-scheme: dark)` y clase `.dark`, redefiniendo únicamente los tokens.

### 11.3 Colores semánticos de estado

| Estado | Color | Uso |
|---|---|---|
| `idea` | gris | Chip neutro |
| `candidato` | ámbar | 🟡 |
| `favorito` | rosa/rojo | ❤️ |
| `seleccionado` | teal | Marcador relleno |
| `reservado` | verde | 🟢 + borde sólido |
| `descartado` | gris al 40 % | ⚫ atenuado |
| `en_riesgo` | rojo | Badge con icono de aviso |

El color **nunca** es el único portador de información: siempre acompaña icono o texto.

### 11.4 Reglas de UI

- **Mobile-first.** Diseñar a 390 px y escalar. Objetivos táctiles ≥ 44 px.
- Formularios en *bottom sheet* en móvil y modal en escritorio.
- Acciones destructivas siempre con confirmación y opción de deshacer (toast con "Deshacer" durante 5 s).
- Estados vacíos con texto útil y un botón de acción ("Aún no hay actividades en Ubud. Añadir la primera").
- Skeletons en carga, nunca *spinners* a pantalla completa.
- Números de dinero **siempre** con moneda y, si procede, chip de fecha de comprobación.
- Toda ficha muestra, si existe: precio, estado, zona, distancia a pie y contador de comentarios.

### 11.5 Accesibilidad

- Contraste mínimo AA (4.5:1) en texto.
- Navegación completa por teclado en escritorio; foco visible.
- `aria-label` en todos los botones de solo icono.
- Los marcadores del mapa tienen alternativa en lista (la vista `/places` cubre esto).
- Respetar `prefers-reduced-motion`.

---

## 12. PWA y comportamiento offline

Durante el viaje habrá zonas con poca cobertura (barco a Gili, arrozales).

- **Instalable**: `manifest.webmanifest` con nombre "Bali 2026", iconos 192/512 + maskable, `display: standalone`, `theme_color: #0F766E`.
- **Service worker** con `vite-plugin-pwa` (estrategia `autoUpdate`):
  - App shell y assets: **precache**.
  - Teselas del mapa: `CacheFirst` con caducidad (máx. ~400 entradas, 30 días).
  - Datos de Supabase: `NetworkFirst` con *fallback* a caché.
- **Caché local de lectura**: el último snapshot del viaje se guarda en `localStorage`/IndexedDB (`useStorage` de VueUse) para que la app abra y muestre datos sin conexión.
- **Escrituras offline**: fuera del MVP. Si no hay conexión, la UI lo indica claramente y **bloquea el guardado** con un aviso, en vez de fingir que se ha guardado. (Cola de escritura diferida: fase 4.)
- Indicador de conexión en la cabecera cuando se está offline.
- Documentos marcados como "disponible offline" se descargan y cachean explícitamente.

---

## 13. Variables de entorno

`.env.example` (versionado, sin valores reales):

```bash
# Supabase (públicas, seguras con RLS activado)
VITE_SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOi...

# Mapa: proveedor de teselas. NO usar el servidor público de OSM en producción.
VITE_MAP_TILE_URL=https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
VITE_MAP_TILE_ATTRIBUTION=&copy; OpenStreetMap contributors
VITE_MAP_TILE_API_KEY=

# Geocodificación opcional (Nominatim / Photon). Vacío = solo pin manual.
VITE_GEOCODER_URL=

# Entorno
VITE_APP_ENV=development
```

Reglas:

- `.env`, `.env.local` y cualquier clave real van en `.gitignore`.
- La `SUPABASE_SERVICE_ROLE_KEY` **solo** existe en el entorno local del desarrollador o en Edge Functions. **Nunca** con prefijo `VITE_`.
- Las mismas variables se cargan en Vercel para *Production*, *Preview* y *Development*.

---

## 14. Fases de desarrollo

Cada fase termina en algo usable y desplegado. **No pasar a la siguiente sin cumplir sus criterios de aceptación** (sección 15).

### Fase 0 — Arranque (medio día)

- Proyecto Vite + Vue 3 + TS + Tailwind + Router + Pinia.
- Cliente Supabase, `.env.example`, ESLint/Prettier, `vercel.json`.
- Layout base: `AppShell`, `BottomNav`, `Sidebar`, tema y tokens.
- Despliegue inicial en Vercel con una pantalla "Hola".

### Fase 1 — Datos y acceso (MVP núcleo)

- Migraciones SQL completas (secciones 7 y 8) aplicadas.
- Auth con magic link, guard de sesión, `/invite/:token`.
- Seed con **todos** los datos de la sección 3.
- CRUD de alojamientos, actividades y lugares (tarjetas + formularios).
- Estados de decisión funcionando con historial.
- Dashboard v1: alojamientos por zona, alertas y cuenta atrás.

### Fase 2 — Mapa y filtros

- Leaflet con marcadores por tipo y estado, clustering.
- Filtros por zona/tipo/estado/precio/etiqueta, sincronizados con la URL.
- Tarjeta de marcador con acciones y enlaces a Google Maps.
- Pin manual, pegado de coordenadas y bandeja "Falta ubicar".
- Vista "solo el plan del día X".

### Fase 3 — Plan y dinero

- Itinerario por días con arrastrar y soltar, avisos de zona y sobrecarga.
- Rutas y transportes, con riesgo del 9/10 destacado.
- Presupuesto: gastos, categorías, marcar pagado, reparto y liquidación.
- Simulador de candidatos.
- Comentarios en todas las entidades.
- Realtime en `places`, `expenses` e `itinerary_items`.

### Fase 4 — Viaje y extras

- PWA instalable, caché offline y documentos offline.
- Documentos con Storage privado y URLs firmadas.
- Checklists, apps y contactos.
- Búsqueda global (`Cmd/Ctrl + K`).
- Comparador de alojamientos.
- Exportación a JSON y a texto para WhatsApp.
- Opcional: Edge Function de tipos de cambio y Google OAuth.

---

## 15. Pruebas y criterios de aceptación

### 15.1 Pruebas automáticas

- **Unitarias (Vitest)** obligatorias en: `money.ts` (conversión y formato), `dates.ts` (noches, solapes, días del viaje), cálculo de presupuesto, reparto y liquidación, y `maps.ts` (haversine y parseo de enlaces de Google Maps).
- **Componentes**: `PlaceCard`, `ExpenseForm`, `BudgetSummary`.
- **RLS**: script que, con dos usuarios de prueba (uno miembro y otro no), verifica que el no miembro **no** puede leer ni escribir nada del viaje. Esta prueba es obligatoria antes de subir datos reales.
- **E2E (Playwright, fase 3+)**: login → ver dashboard → añadir lugar → colocarlo en el mapa → asignarlo a un día → crear gasto → marcarlo pagado.

### 15.2 Criterios de aceptación por fase

**Fase 1**

- [ ] Daniel y Elena entran con magic link y ven **el mismo** viaje.
- [ ] Un usuario ajeno autenticado no ve absolutamente nada del viaje (verificado contra la API, no solo en la UI).
- [ ] Los 3 tramos, los 2 alojamientos decididos y todos los candidatos de la sección 3 están cargados con sus precios y `checked_at`.
- [ ] Cambiar el estado de un alojamiento queda registrado con autor y fecha.
- [ ] El dashboard muestra Ubud como **pendiente de decisión**.

**Fase 2**

- [ ] Todos los elementos con coordenadas aparecen en el mapa con el color de su tipo y el estilo de su estado.
- [ ] Los filtros funcionan combinados y sobreviven a recargar la página (van en la URL).
- [ ] Un elemento sin coordenadas puede ubicarse arrastrando un pin o pegando un enlace de Google Maps.
- [ ] "Cómo llegar" abre Google Maps con origen y destino correctos.
- [ ] Los descartados están ocultos por defecto y se pueden mostrar.

**Fase 3**

- [ ] El itinerario cubre del 08/10 al 21/10 y permite mover elementos entre días.
- [ ] El tramo DPS → Gili del 9/10 aparece como riesgo en el dashboard hasta marcarlo confirmado.
- [ ] El total del presupuesto cuadra con la suma de los gastos, verificado a mano.
- [ ] Marcar un gasto como pagado actualiza el resumen sin recargar.
- [ ] La liquidación calcula correctamente quién debe a quién con un reparto 50/50.
- [ ] El simulador muestra el delta al cambiar el alojamiento de Ubud.

**Fase 4**

- [ ] La app se instala en el móvil y abre sin conexión mostrando el último estado conocido.
- [ ] Sin conexión, intentar guardar avisa claramente y no pierde datos.
- [ ] Un documento subido solo es accesible mediante URL firmada y caduca.
- [ ] La búsqueda global encuentra un hotel, una actividad y un gasto.

### 15.3 Presupuesto de rendimiento

- Primera carga útil < 3 s en 4G.
- Bundle inicial < 300 kB gzip (Leaflet cargado de forma diferida solo en la vista de mapa).
- El mapa debe manejar 300 marcadores sin tirones (clustering activo).

---

## 16. Despliegue

### 16.1 Supabase

1. Crear proyecto (región recomendada: `eu-central` o `eu-west`).
2. Aplicar migraciones en orden desde `supabase/migrations/` (SQL Editor o `supabase db push`).
3. Ejecutar `supabase/seed/seed_bali_2026.sql`.
4. Crear el bucket **privado** `trip-docs` y aplicar `0004_storage.sql`.
5. Auth → activar Email (magic link); configurar **Site URL** y **Redirect URLs** con el dominio de Vercel y `http://localhost:5173`.
6. Comprobar que **todas** las tablas tienen RLS activado (el aviso de Supabase debe estar limpio).

### 16.2 Vercel

1. Importar el repositorio `DanielYearwood/trip-app`.
2. Framework preset: **Vite**. Build: `npm run build`. Output: `dist`.
3. Variables de entorno (Production, Preview y Development): las de la sección 13.
4. `vercel.json` con reescritura SPA:

```json
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

5. Despliegue automático desde `main`; cada PR genera un *preview*.
6. Tras el primer despliegue, añadir la URL definitiva a las Redirect URLs de Supabase.

### 16.3 Reparto de tareas

- **La IA que escriba el código**: todo el contenido de `src/`, `supabase/migrations/` y `supabase/seed/`, más los PR contra `main`.
- **Claude (esta sesión)**: creación de los proyectos de Supabase y Vercel, carga de variables de entorno, aplicación de migraciones y seed, primer despliegue y comprobación de que el sitio funciona.

> Requisito para publicar en GitHub desde una integración: permisos **Contents: Read and write** y, si se trabaja por PR, **Pull requests: Read and write** sobre `DanielYearwood/trip-app`.

---

## 17. Instrucciones para la IA que escriba el código

Léelas antes de escribir la primera línea.

### 17.1 Reglas duras

1. **Este README es la especificación.** Si algo no está definido, elige la opción más simple, deja un comentario `// DECISIÓN:` explicando por qué y anótalo en el PR.
2. **No inventes datos del viaje.** Precios, valoraciones, coordenadas y horarios solo pueden salir de la sección 3. Lo que no esté ahí se carga como `null` con `price_pending = true`, nunca estimado.
3. **No hardcodees totales ni resúmenes.** Todo número visible se calcula a partir de la base de datos.
4. **RLS antes que datos reales.** No cargues el seed hasta que la prueba de aislamiento entre usuarios (sección 15.1) pase.
5. **Interfaz en español**, incluidos mensajes de error, estados vacíos y validaciones.
6. **Mobile-first siempre.** Si un componente solo funciona bien en escritorio, no está terminado.
7. **Nunca uses una API de mapas de pago** ni el servidor público de teselas de OSM en producción.
8. **Ninguna clave secreta en el cliente ni en el repo.** Solo `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY`.
9. **Descartar no borra.** Implementa el borrado lógico desde el principio.
10. **Una fase, un PR.** No mezcles fases; cada PR debe dejar la app desplegable.

### 17.2 Orden de trabajo recomendado

1. Fase 0 completa y desplegada antes de tocar el dominio.
2. Migraciones → tipos generados (`database.ts`) → stores → componentes → vistas.
3. Seed al final de la fase 1, ya con RLS verificado.
4. Leaflet en carga diferida (`defineAsyncComponent`) para no engordar el bundle inicial.
5. Presupuesto después del itinerario: los gastos se enganchan a lugares y rutas ya existentes.

### 17.3 Checklist antes de cada PR

- [ ] `npm run build` y `vue-tsc --noEmit` sin errores.
- [ ] ESLint y Prettier limpios.
- [ ] Probado a 390 px de ancho.
- [ ] Sin `console.log` de depuración ni `any` sin justificar.
- [ ] Sin claves ni datos personales en el diff.
- [ ] Los criterios de aceptación de la fase se cumplen.
- [ ] README actualizado si has cambiado el modelo de datos o el contrato.

### 17.4 Preguntas que NO hay que preguntar (ya están decididas)

- Framework: Vue 3 + TS. Backend: Supabase. Hosting: Vercel. Mapa: Leaflet + OSM.
- Idioma de la interfaz: español.
- Moneda de trabajo: EUR; moneda de destino: IDR.
- Orden del viaje: Gili → Ubud → Seminyak.
- Reparto por defecto de gastos: 50/50.
- Booking **no** se automatiza.

### 17.5 Preguntas que SÍ hay que trasladar a Daniel

- Alojamiento definitivo de Ubud (hoy `Divara Ubud` es solo `favorito`).
- Fecha límite exacta de cancelación gratuita de Moson.
- Operador y hora del fast boat del 9/10.
- Presupuesto total objetivo del viaje (`trips.budget_total`).
- Correo de Elena para la invitación.

---

## 18. Anexos

### 18.1 Glosario de estados

| Ámbito | Valores |
|---|---|
| Lugar / alojamiento | `idea`, `candidato`, `favorito`, `seleccionado`, `planificado`, `reservado`, `realizado`, `descartado` |
| Ruta | `idea`, `requiere_confirmacion`, `reservada`, `confirmada`, `en_riesgo`, `descartada` |
| Gasto | `previsto`, `comprometido`, `parcialmente_pagado`, `pagado`, `reembolsado`, `cancelado` |
| Ítem de itinerario | `planificado`, `confirmado`, `realizado`, `cancelado` |
| Miembro | `owner`, `editor`, `viewer` |

### 18.2 Categorías de gasto

`alojamiento` · `transporte_internacional` · `transporte_local` · `actividad` · `comida` · `compras` · `tasas_visado` · `seguro` · `salud` · `otros`

### 18.3 Modos de transporte

`walk` · `bike` · `cidomo` · `grab` · `taxi` · `private_driver` · `shuttle` · `fast_boat` · `ferry` · `flight` · `other`

### 18.4 Comandos habituales

```bash
npm install
npm run dev              # http://localhost:5173
npm run build
npm run preview
npm run lint
npm run test
npx vue-tsc --noEmit

# Supabase
npx supabase link --project-ref <ref>
npx supabase db push
npx supabase gen types typescript --project-id <ref> > src/types/database.ts
```

### 18.5 Resumen económico de partida

Combinación actual (pendiente de cerrar Ubud):

| Tramo | Alojamiento | Estado | Importe |
|---|---|---|---|
| Gili Trawangan (3 n.) | Pearl of Trawangan, Suar Deluxe | `seleccionado` | ~375 € *(por confirmar)* |
| Ubud (4 n.) | **Pendiente** — `Divara Ubud` como favorito | `favorito` | 104 € *(referencia)* |
| Seminyak/Legian (4 n.) | Moson Bali Villa Legian | `reservado` | 129 € |
| **Total alojamiento (11 n.)** | | | **~608 €** |

No incluye vuelos, traslados, fast boats, actividades, comidas ni seguro. La app debe calcular este total sola a partir de los datos, **nunca** mostrarlo escrito a mano.

### 18.6 Licencia y privacidad

Proyecto **privado y personal**. Sin licencia pública. Contiene datos de viaje y, potencialmente, documentos personales: el repositorio no debe incluir jamás datos reales de pasaporte, reservas ni claves. Todo eso vive en Supabase con RLS y en Storage privado.
