-- =========================================================
-- seed_bali_2026.sql — datos iniciales del viaje
-- Ver README.md sección 3.
--
-- Uso (SQL Editor de Supabase, tras el primer login del propietario):
--     select public.seed_bali_2026('daniel@ejemplo.com');
--
-- Es idempotente: si el viaje ya existe, no duplica nada.
--
-- NOTA SOBRE PRECIOS: los importes proceden de una investigación previa en
-- Booking cuya fecha exacta no consta. Por eso casi todos entran con
-- price_pending = true y checked_at = null. La única excepción es Moson,
-- que es una reserva real confirmada. No se inventa ninguna fecha de
-- comprobación ni coordenada de alojamiento: los pines se colocan a mano
-- desde la bandeja "Falta ubicar".
-- =========================================================

create or replace function public.seed_bali_2026(p_owner_email text)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_owner uuid;
  v_trip  uuid;
  v_gili  uuid;
  v_ubud  uuid;
  v_semi  uuid;
  v_list  uuid;
  d       date;
begin
  select id into v_owner from auth.users where lower(email) = lower(p_owner_email);
  if v_owner is null then
    raise exception 'No existe ningún usuario con el email %. Inicia sesión una vez antes de sembrar.', p_owner_email;
  end if;

  -- ---------------------------------------------------------
  -- Viaje
  -- ---------------------------------------------------------
  select id into v_trip from public.trips where slug = 'bali-2026';

  if v_trip is null then
    insert into public.trips (name, slug, destination, start_date, end_date,
                              base_currency, local_currency, travellers, created_by)
    values ('Bali 2026', 'bali-2026', 'Bali e islas Gili, Indonesia',
            date '2026-10-08', date '2026-10-21', 'EUR', 'IDR', 2, v_owner)
    returning id into v_trip;
  end if;

  insert into public.trip_members (trip_id, user_id, role)
  values (v_trip, v_owner, 'owner')
  on conflict (trip_id, user_id) do nothing;

  -- ---------------------------------------------------------
  -- Zonas. Los centros son aproximados y sirven solo para encuadrar
  -- el mapa; no son ubicaciones de ningún alojamiento concreto.
  -- ---------------------------------------------------------
  insert into public.zones (trip_id, name, slug, start_date, end_date, color, center_lat, center_lng, sort_order, notes)
  values
    (v_trip, 'Gili Trawangan',   'gili',     date '2026-10-09', date '2026-10-12', '#06B6D4', -8.350000, 116.040000, 1,
     'Sin coches ni motos: a pie, bici o cidomo. La distancia al puerto y al núcleo pesa mucho.'),
    (v_trip, 'Ubud',             'ubud',     date '2026-10-12', date '2026-10-16', '#0F766E', -8.506900, 115.262500, 2,
     'Cultura, naturaleza y excursiones. Alojamiento aún por decidir.'),
    (v_trip, 'Seminyak/Legian',  'seminyak', date '2026-10-16', date '2026-10-20', '#F59E0B', -8.690000, 115.168000, 3,
     'El tráfico manda: las distancias a pie son más fiables que los kilómetros.')
  on conflict (trip_id, slug) do nothing;

  select id into v_gili from public.zones where trip_id = v_trip and slug = 'gili';
  select id into v_ubud from public.zones where trip_id = v_trip and slug = 'ubud';
  select id into v_semi from public.zones where trip_id = v_trip and slug = 'seminyak';

  -- Si ya hay lugares, damos por hecho que la siembra se hizo antes.
  if exists (select 1 from public.places where trip_id = v_trip) then
    return v_trip;
  end if;

  -- ---------------------------------------------------------
  -- Alojamientos
  -- ---------------------------------------------------------
  with nuevos as (
    insert into public.places
      (trip_id, zone_id, name, kind, status, discard_reason, price_amount, price_currency,
       price_basis, price_pending, price_source, rating, rating_count, location_rating,
       pros, cons, notes, created_by)
    values
      -- Gili Trawangan
      (v_trip, v_gili, 'Pearl of Trawangan', 'stay', 'seleccionado', null, 375.00, 'EUR',
       'total', true, 'booking', 9.0, 3299, null,
       array['Primera línea de playa','Dos piscinas','Habitación grande de 52 m²','~10 min a pie del puerto'],
       array['El más caro del viaje','Precio pendiente de reconfirmar'],
       'Suar Deluxe con desayuno y cancelación flexible. Es el capricho del viaje: donde más compensa gastar.', v_owner),
      (v_trip, v_gili, 'Jali Resort', 'stay', 'candidato', null, 141.00, 'EUR',
       'total', true, 'booking', 9.4, null, null,
       array['Mejor ahorro real','Restaurante muy bien valorado','Desayuno incluido'],
       array['No está frente al mar','~1,2 km del puerto'],
       'La opción inteligente si se quiere ahorrar de verdad en Gili.', v_owner),
      (v_trip, v_gili, 'Martas Hotel', 'stay', 'candidato', null, 139.00, 'EUR',
       'total', true, 'booking', 9.1, 781, null,
       array['~10 min a pie del puerto','Piscina','Muy bien valorado','Desayuno'],
       array['Sencillo, poco especial'],
       'Alternativa económica y práctica.', v_owner),
      (v_trip, v_gili, 'PinkCoco Gili Trawangan', 'stay', 'candidato', null, 188.00, 'EUR',
       'total', true, 'booking', 9.2, 871, null,
       array['Solo adultos','Frente a la playa','Habitaciones de 46 m²','Muy fotogénico'],
       array['Costa oeste, zona de atardecer','~15 min del puerto','Requiere bici o cidomo a menudo'],
       'Mejor para pareja, playa y tranquilidad que para entrar y salir.', v_owner),
      (v_trip, v_gili, 'Lighthouse Hotel', 'stay', 'candidato', null, 262.00, 'EUR',
       'total', true, 'booking', null, 70, 9.9,
       array['Nuevo','Frente al mar','Dos piscinas','A 100 m del puerto'],
       array['Pocas opiniones todavía','En plena zona de movimiento'],
       'La sorpresa de la búsqueda. Pedir habitación alejada de la zona del puerto.', v_owner),
      (v_trip, v_gili, 'The Beach House Resort', 'stay', 'candidato', null, 274.00, 'EUR',
       'total', true, 'booking', null, null, null,
       array['Frente al mar','Piscina infinita','~5 min a pie del puerto'],
       array['Más céntrico y potencialmente ruidoso','Algunas habitaciones bastante pequeñas'],
       'El sustituto más parecido a Pearl, pero con poco ahorro.', v_owner),
      (v_trip, v_gili, 'Gili Teak Beach Front Resort', 'stay', 'candidato', null, 262.00, 'EUR',
       'total', true, 'booking', null, null, null,
       array['Estilo boutique','Playa'],
       array['Más alejado del núcleo'],
       'Alternativa de estilo; precio demasiado parecido a Pearl para compensar.', v_owner),

      -- Ubud
      (v_trip, v_ubud, 'Divara Ubud', 'stay', 'favorito', null, 104.00, 'EUR',
       'total', true, 'booking', 9.3, null, 9.0,
       array['Relación calidad-precio excepcional','Habitación de 22 m² con vistas a la piscina','Desayuno','Cancelación gratuita','Palacio de Ubud a ~15 min a pie'],
       array['No tiene nivel de resort','Disponibilidad muy justa'],
       'Barato por oportunidad, no por ser malo. Favorito actual para Ubud.', v_owner),
      (v_trip, v_ubud, 'Ubud Suarga Private Pool Villa', 'stay', 'candidato', null, 192.00, 'EUR',
       'total', true, 'booking', null, null, null,
       array['Villa completa de 56 m²','Piscina privada','Desayuno','Cancelación gratuita'],
       array['~4,1 km del centro','Grab para todo'],
       'Seleccionar expresamente la categoría "Villa with Private Pool". Piscina privada por 50 € menos que Korurua.', v_owner),
      (v_trip, v_ubud, 'Taman Amartha Hotel', 'stay', 'candidato', null, 208.00, 'EUR',
       'total', true, 'booking', 9.2, null, 9.0,
       array['Dos piscinas','~15 min a pie del centro','Desayuno','Cancelación hasta el día de llegada'],
       array['Habitación básica de solo 17 m²'],
       'Práctico y agradable, pero menos especial que Korurua por poca diferencia.', v_owner),
      (v_trip, v_ubud, 'Korurua Dijiwa Ubud', 'stay', 'candidato', null, 242.00, 'EUR',
       'total', true, 'booking', 9.2, null, 8.9,
       array['Suite Tirta de 45 m²','Jardines, spa y yoga','Desayuno excepcional','Cancelación gratuita','Traslado al centro'],
       array['Fuera del centro','Depende de shuttle o taxi'],
       'El más bonito: aquí el alojamiento forma parte de la experiencia.', v_owner),
      (v_trip, v_ubud, 'Rumah Kayu Resort', 'stay', 'candidato', null, 286.00, 'EUR',
       'total', true, 'booking', 9.4, null, null,
       array['Buen resort','Estética muy cuidada'],
       array['~5,6 km del centro'],
       'Alternativa estética; comprobar ubicación y condiciones antes de decidir.', v_owner),
      (v_trip, v_ubud, 'Wooden Stone Eco Villa', 'stay', 'candidato', null, 410.00, 'EUR',
       'total', true, 'booking', null, null, null,
       array['Preciosa','Villa'],
       array['~5,4 km del centro, ~20 min en coche','Cara'],
       'Opción especial de precio alto.', v_owner),
      (v_trip, v_ubud, 'Bubu Mesari Ubud Villa', 'stay', 'descartado', 'sin_disponibilidad', null, 'EUR',
       null, true, 'booking', 9.4, null, null,
       array['Piscina privada','Centro real de Ubud'],
       array['Sin disponibilidad para 12–16/10','Muchos escalones de acceso'],
       'Sin disponibilidad en las fechas correctas tras cambiar el orden del viaje.', v_owner),
      (v_trip, v_ubud, 'Temple Tree by Soobali', 'stay', 'descartado', 'sin_disponibilidad', null, 'EUR',
       null, true, 'booking', null, null, null,
       array[]::text[],
       array['Sin disponibilidad para 12–16/10','Avisa de obras cercanas y posible ruido'],
       'Descartada incluso si volviera a haber disponibilidad, por las obras.', v_owner),
      (v_trip, v_ubud, 'Nadisa Villa', 'stay', 'descartado', 'sin_disponibilidad', null, 'EUR',
       null, true, 'booking', null, null, null, array[]::text[], array['Sin disponibilidad para 12–16/10'], null, v_owner),
      (v_trip, v_ubud, 'Kappat Ubud Villa', 'stay', 'descartado', 'sin_disponibilidad', 320.00, 'EUR',
       'total', true, 'booking', 9.5, null, null,
       array['Villa con piscina privada y jardín','Solo adultos'],
       array['Sin disponibilidad para 12–16/10','Está en Kedewatan, lejos del centro'],
       null, v_owner),
      (v_trip, v_ubud, 'Villa Kayu Lama', 'stay', 'descartado', 'sin_disponibilidad', null, 'EUR',
       null, true, 'booking', null, null, null, array[]::text[], array['Sin disponibilidad para 12–16/10'], null, v_owner),

      -- Seminyak / Legian
      (v_trip, v_semi, 'Moson Bali Villa Legian', 'stay', 'reservado', null, 129.00, 'EUR',
       'total', false, 'booking', 8.6, 1303, 8.5,
       array['Reservado y cerrado','Desayuno muy bien valorado','Piscina compartida y jardín','Relación calidad-precio muy fuerte','Pago en el alojamiento'],
       array['Dewi Sri, interior de Legian','Playa de Legian a ~2,1 km','Grab frecuente para playa y cenas','A pesar del nombre, la piscina NO es privada'],
       'RESERVADO. Habitación extragrande con vistas a la piscina, 16–20/10, 2 personas. Falta registrar la fecha límite exacta de cancelación gratuita.', v_owner),
      (v_trip, v_semi, 'My Secret Home', 'stay', 'candidato', null, 198.72, 'EUR',
       'total', true, 'booking', 9.4, null, 9.6,
       array['A pocos pasos de Double Six Beach','Habitación superior de 40 m²','Piscina y jardín tropical','Desayuno y cancelación gratuita'],
       array['Más pensión boutique que resort','Acceso por callejuela estrecha','Hay animales en la propiedad','Habitaciones altas con escaleras'],
       'La mejor ubicación del tramo si se prioriza salir andando.', v_owner),
      (v_trip, v_semi, 'Fourteen Roses Beach Hotel', 'stay', 'candidato', null, 174.88, 'EUR',
       'total', true, 'booking', 8.9, null, 9.2,
       array['Dos piscinas','Habitación de 30 m²','Desayuno y cancelación','~10 min a pie de Kuta Beach'],
       array['Es Legian/Kuta, no Seminyak'],
       'El punto intermedio entre precio y ubicación.', v_owner),
      (v_trip, v_semi, 'Bali Ginger Suites and Villa', 'stay', 'candidato', null, 244.21, 'EUR',
       'total', true, 'booking', 9.2, null, 9.4,
       array['Suite junto a la piscina','Céntrico, rodeado de restaurantes','Desayuno y cancelación'],
       array['El más caro de los candidatos del tramo','~500 m de la playa'],
       'La elección segura si se prefiere un hotel convencional.', v_owner),
      (v_trip, v_semi, 'The Eight Bali', 'stay', 'candidato', null, 126.76, 'EUR',
       'total', true, 'booking', 9.0, null, 8.9,
       array['Habitación de 35 m²','Piscina compartida','Cancelación gratuita','Muy buena calidad por el precio'],
       array['Sin desayuno en la tarifa vista','Playa a ~2,6 km','Bastantes desplazamientos en Grab'],
       'La villa de 75 m² con piscina privada del mismo alojamiento costaba 385 €.', v_owner),
      (v_trip, v_semi, 'Seminyak Paradiso Hotel', 'stay', 'candidato', null, 122.72, 'EUR',
       'total', true, 'booking', 7.5, 633, 9.0,
       array['Muy céntrico: Camplung Tanduk/Dyanapura','A pocos minutos a pie de la playa','Barato','Desayuno'],
       array['Valoración de solo 7,5','Instalaciones antiguas','Nivel general modesto'],
       'Solo si el criterio número uno es evitar taxis gastando poco.', v_owner),
      (v_trip, v_semi, 'DLeafy Seminyak', 'stay', 'candidato', null, 108.65, 'EUR',
       'total', true, 'booking', 8.9, 222, 8.0,
       array['Barato','Limpio y tranquilo','Piscina compartida'],
       array['Ubicación 8,0, fuera de la parte caminable','Acceso por callejón de ~75 m donde no llegan los coches','Sin desayuno'],
       'Poco práctico sin moto. The Eight parece más equilibrado por ~18 € más.', v_owner)
    returning id, name, zone_id
  )
  insert into public.stay_details
    (place_id, stay_type, check_in, check_out, room_type, room_size_m2, guests, pool,
     breakfast_included, pay_at_property, free_cancellation)
  select
    n.id,
    case
      when n.name in ('Ubud Suarga Private Pool Villa','Wooden Stone Eco Villa','Bubu Mesari Ubud Villa',
                      'Nadisa Villa','Kappat Ubud Villa','Villa Kayu Lama','Moson Bali Villa Legian') then 'villa'
      when n.name in ('Jali Resort','Rumah Kayu Resort','The Beach House Resort','Scallywags Resort',
                      'Gili Teak Beach Front Resort') then 'resort'
      else 'hotel'
    end,
    case n.zone_id when v_gili then date '2026-10-09' when v_ubud then date '2026-10-12' else date '2026-10-16' end,
    case n.zone_id when v_gili then date '2026-10-12' when v_ubud then date '2026-10-16' else date '2026-10-20' end,
    case n.name
      when 'Pearl of Trawangan'             then 'Suar Deluxe'
      when 'Moson Bali Villa Legian'        then 'Habitación extragrande con vistas a la piscina'
      when 'Korurua Dijiwa Ubud'            then 'Suite Tirta'
      when 'My Secret Home'                 then 'Habitación superior'
      when 'Divara Ubud'                    then 'Habitación con vistas a la piscina'
      when 'Ubud Suarga Private Pool Villa' then 'Villa with Private Pool'
      else null
    end,
    case n.name
      when 'Pearl of Trawangan'             then 52
      when 'Korurua Dijiwa Ubud'            then 45
      when 'My Secret Home'                 then 40
      when 'The Eight Bali'                 then 35
      when 'Fourteen Roses Beach Hotel'     then 30
      when 'Divara Ubud'                    then 22
      when 'Taman Amartha Hotel'            then 17
      when 'PinkCoco Gili Trawangan'        then 46
      when 'Ubud Suarga Private Pool Villa' then 56
      else null
    end,
    2,
    case
      when n.name in ('Ubud Suarga Private Pool Villa','Bubu Mesari Ubud Villa','Kappat Ubud Villa') then 'privada'
      else 'compartida'
    end,
    case when n.name in ('The Eight Bali','DLeafy Seminyak') then false
         when n.name in ('Pearl of Trawangan','Moson Bali Villa Legian','Jali Resort','Martas Hotel',
                         'PinkCoco Gili Trawangan','Lighthouse Hotel','Divara Ubud','Korurua Dijiwa Ubud',
                         'Taman Amartha Hotel','Ubud Suarga Private Pool Villa','My Secret Home',
                         'Fourteen Roses Beach Hotel','Bali Ginger Suites and Villa','Seminyak Paradiso Hotel') then true
         else null end,
    (n.name = 'Moson Bali Villa Legian'),
    case when n.name in ('Pearl of Trawangan','Moson Bali Villa Legian','Divara Ubud','Korurua Dijiwa Ubud',
                         'Taman Amartha Hotel','Ubud Suarga Private Pool Villa','My Secret Home',
                         'Fourteen Roses Beach Hotel','Bali Ginger Suites and Villa','The Eight Bali') then true
         else null end
  from nuevos n;

  -- ---------------------------------------------------------
  -- Actividades e ideas
  -- ---------------------------------------------------------
  with act as (
    insert into public.places (trip_id, zone_id, name, kind, category, status, tags, notes, created_by)
    values
      (v_trip, v_gili, 'Snorkel en Gili (tortugas, Gili Meno, statues)', 'activity', 'snorkel', 'idea',
       array['snorkel','mar','imprescindible'], 'Medio día o día completo. Depende del estado del mar.', v_owner),
      (v_trip, v_gili, 'Sunset en la costa oeste y swings', 'activity', 'sunset', 'idea',
       array['sunset','gratis'], 'Gratis. Ir andando o en bici.', v_owner),
      (v_trip, v_gili, 'Vuelta a la isla en bicicleta', 'activity', 'aire libre', 'idea',
       array['bici','gratis'], '~2 h. Alternativa de lluvia: spa o café.', v_owner),
      (v_trip, v_ubud, 'Mount Batur sunrise trekking', 'activity', 'trekking', 'idea',
       array['amanecer','trekking','reservar'], 'Recogida sobre las 02:00. Requiere reserva previa y depende mucho del tiempo.', v_owner),
      (v_trip, v_ubud, 'Rafting río Ayung o Telaga Waja', 'activity', 'aventura', 'idea',
       array['rafting','reservar'], 'Medio día. Suele incluir traslado.', v_owner),
      (v_trip, v_ubud, 'Arrozales de Tegallalang y swing', 'activity', 'paisaje', 'idea',
       array['arrozales','foto'], 'Medio día. Combinar con Tirta Empul.', v_owner),
      (v_trip, v_ubud, 'Templos: Tirta Empul, Gunung Kawi, Saraswati', 'activity', 'templo', 'idea',
       array['templo','cultura'], 'Sarong obligatorio. Mejor por la mañana.', v_owner),
      (v_trip, v_ubud, 'Monkey Forest', 'activity', 'naturaleza', 'idea',
       array['centro','a pie'], '~1,5 h. Céntrico, se llega andando.', v_owner),
      (v_trip, v_ubud, 'Campuhan Ridge Walk', 'activity', 'paseo', 'idea',
       array['amanecer','gratis','a pie'], 'Al amanecer. Gratis.', v_owner),
      (v_trip, v_ubud, 'Cascadas: Tibumana, Tegenungan, Kanto Lampo', 'activity', 'naturaleza', 'idea',
       array['cascadas','conductor'], 'Requieren conductor. Agrupar en un solo día.', v_owner),
      (v_trip, v_semi, 'Double Six Beach y sunset', 'activity', 'playa', 'idea',
       array['playa','sunset'], 'Grab desde Moson.', v_owner),
      (v_trip, v_semi, 'Beach club (Potato Head, Ku De Ta, La Plancha)', 'activity', 'beach club', 'idea',
       array['ambiente','reservar'], 'Reserva recomendable. Comprobar consumo mínimo.', v_owner),
      (v_trip, v_semi, 'Templo de Uluwatu y danza Kecak', 'activity', 'templo', 'idea',
       array['sunset','conductor','cultura'], 'Excursión de tarde. Conductor privado.', v_owner),
      (v_trip, v_semi, 'Canggu: cafés, tiendas y Echo Beach', 'activity', 'paseo', 'idea',
       array['cafes','compras'], 'Medio día. Tráfico impredecible.', v_owner),
      (v_trip, null, 'Clase de cocina balinesa', 'activity', 'gastronomía', 'idea',
       array['lluvia-ok','reservar'], 'Reserva previa. Plan ideal para día de lluvia.', v_owner),
      (v_trip, null, 'Spa / masaje balinés', 'activity', 'bienestar', 'idea',
       array['lluvia-ok','flexible'], 'Relleno flexible de cualquier tarde.', v_owner)
    returning id, name
  )
  insert into public.activity_details (place_id, people, weather_dependent, booking_required, effort_level)
  select
    a.id,
    2,
    a.name in ('Snorkel en Gili (tortugas, Gili Meno, statues)',
               'Sunset en la costa oeste y swings',
               'Vuelta a la isla en bicicleta',
               'Mount Batur sunrise trekking',
               'Rafting río Ayung o Telaga Waja',
               'Campuhan Ridge Walk',
               'Double Six Beach y sunset',
               'Arrozales de Tegallalang y swing'),
    a.name in ('Mount Batur sunrise trekking','Rafting río Ayung o Telaga Waja',
               'Beach club (Potato Head, Ku De Ta, La Plancha)','Clase de cocina balinesa'),
    case when a.name = 'Mount Batur sunrise trekking' then 'alto'
         when a.name in ('Rafting río Ayung o Telaga Waja','Campuhan Ridge Walk','Vuelta a la isla en bicicleta') then 'medio'
         else 'bajo' end
  from act a;

  -- ---------------------------------------------------------
  -- Rutas. El tramo del 9/10 nace en riesgo a propósito.
  -- ---------------------------------------------------------
  insert into public.routes (trip_id, from_label, to_label, mode, date, status, risk_level, risk_notes, notes, created_by)
  values
    (v_trip, 'Barcelona (BCN)', 'Denpasar (DPS)', 'flight', date '2026-10-08', 'confirmada', null, null,
     'Llegada a DPS el 09/10 a las 08:25.', v_owner),
    (v_trip, 'Aeropuerto DPS', 'Puerto (Padang Bai o Serangan)', 'private_driver', date '2026-10-09', 'en_riesgo', 'alto',
     'Comprobar: hora límite real del fast boat, puerto exacto, tiempo de inmigración y equipaje, tráfico desde DPS y política del operador ante retrasos.',
     'Plan B: primera noche en Bali (Sanur o Canggu) si no hay conexión razonablemente segura.', v_owner),
    (v_trip, 'Puerto de Bali', 'Gili Trawangan', 'fast_boat', date '2026-10-09', 'en_riesgo', 'alto',
     'Depende del vuelo de llegada y del estado del mar. Sin reservar todavía: falta operador y hora.',
     'Este es el punto más frágil de todo el viaje.', v_owner),
    (v_trip, 'Gili Trawangan', 'Puerto de Bali', 'fast_boat', date '2026-10-12', 'requiere_confirmacion', 'medio',
     'Elegir operador y hora compatibles con la llegada a Ubud.', null, v_owner),
    (v_trip, 'Puerto de Bali', 'Ubud', 'private_driver', date '2026-10-12', 'requiere_confirmacion', 'bajo', null, null, v_owner),
    (v_trip, 'Ubud', 'Seminyak/Legian', 'private_driver', date '2026-10-16', 'requiere_confirmacion', 'bajo',
     null, 'Contar con tráfico: puede llevar bastante más de lo que marca el mapa.', v_owner),
    (v_trip, 'Moson Bali Villa Legian', 'Aeropuerto DPS', 'grab', date '2026-10-20', 'requiere_confirmacion', 'medio',
     'Vuelo a las 19:20. Salir con margen amplio por el tráfico de Legian.', null, v_owner),
    (v_trip, 'Denpasar (DPS)', 'Barcelona (BCN)', 'flight', date '2026-10-20', 'confirmada', null, null,
     'Salida 20/10 a las 19:20, llegada a BCN el 21/10 a las 13:15.', v_owner);

  -- ---------------------------------------------------------
  -- Días del itinerario (08/10 → 21/10)
  -- ---------------------------------------------------------
  d := date '2026-10-08';
  while d <= date '2026-10-21' loop
    insert into public.itinerary_days (trip_id, date, zone_id, title)
    values (
      v_trip, d,
      case
        when d between date '2026-10-09' and date '2026-10-11' then v_gili
        when d between date '2026-10-12' and date '2026-10-15' then v_ubud
        when d between date '2026-10-16' and date '2026-10-19' then v_semi
        else null
      end,
      case
        when d = date '2026-10-08' then 'Vuelo Barcelona → Bali'
        when d = date '2026-10-09' then 'Llegada a DPS y traslado a Gili Trawangan'
        when d = date '2026-10-12' then 'Gili → Ubud'
        when d = date '2026-10-16' then 'Ubud → Seminyak/Legian'
        when d = date '2026-10-20' then 'Último día y vuelo de vuelta'
        when d = date '2026-10-21' then 'Llegada a Barcelona'
        else null
      end
    )
    on conflict (trip_id, date) do nothing;
    d := d + 1;
  end loop;

  -- ---------------------------------------------------------
  -- Checklists
  -- ---------------------------------------------------------
  insert into public.checklists (trip_id, name, sort_order)
  values (v_trip, 'Antes de salir', 1), (v_trip, 'Documentos', 2),
         (v_trip, 'Equipaje', 3), (v_trip, 'En destino', 4);

  select id into v_list from public.checklists where trip_id = v_trip and name = 'Antes de salir';
  insert into public.checklist_items (checklist_id, trip_id, label, sort_order) values
    (v_list, v_trip, 'Confirmar el fast boat del 9/10 y su hora límite', 1),
    (v_list, v_trip, 'Registrar la fecha límite de cancelación gratuita de Moson', 2),
    (v_list, v_trip, 'Decidir el alojamiento de Ubud', 3),
    (v_list, v_trip, 'Contratar el seguro de viaje y guardar la póliza', 4),
    (v_list, v_trip, 'Descargar mapas offline de Bali y Lombok', 5),
    (v_list, v_trip, 'Avisar al banco y preparar tarjeta sin comisiones', 6),
    (v_list, v_trip, 'Descargar el paquete de indonesio en Google Translate', 7),
    (v_list, v_trip, 'Definir el presupuesto total del viaje en la app', 8);

  select id into v_list from public.checklists where trip_id = v_trip and name = 'Documentos';
  insert into public.checklist_items (checklist_id, trip_id, label, sort_order) values
    (v_list, v_trip, 'Comprobar vigencia del pasaporte (mínimo 6 meses)', 1),
    (v_list, v_trip, 'Comprobar requisitos de entrada vigentes (e-VOA) en la web oficial', 2),
    (v_list, v_trip, 'Comprobar la declaración de aduanas electrónica (e-CD) en la web oficial', 3),
    (v_list, v_trip, 'Subir a la app las confirmaciones de vuelo y de hotel', 4);

  -- ---------------------------------------------------------
  -- Apps y herramientas
  -- ---------------------------------------------------------
  insert into public.tools (trip_id, name, category, notes, sort_order) values
    (v_trip, 'Grab', 'transporte', 'Coche, moto y comida en Bali. NO opera en Gili.', 1),
    (v_trip, 'Gojek', 'transporte', 'Alternativa a Grab. Merece la pena comparar precio.', 2),
    (v_trip, 'Google Maps (mapas offline)', 'mapas', 'Descargar Bali y Lombok antes de salir.', 3),
    (v_trip, 'Organic Maps', 'mapas', 'Mapa offline de respaldo.', 4),
    (v_trip, '12Go y operadores de fast boat', 'transporte', 'Reserva y horarios de barcos.', 5),
    (v_trip, 'Booking.com', 'alojamiento', 'Reservas y condiciones de cancelación.', 6),
    (v_trip, 'WhatsApp', 'comunicacion', 'Canal habitual de hoteles y conductores.', 7),
    (v_trip, 'Wise / Revolut', 'dinero', 'Cambio y pagos con tarjeta.', 8),
    (v_trip, 'XE Currency', 'dinero', 'Conversión offline IDR ↔ EUR.', 9),
    (v_trip, 'Google Translate (indonesio offline)', 'idioma', 'Descargar el paquete antes de salir.', 10),
    (v_trip, 'Windy / Meteoblue', 'clima', 'Estado del mar para los fast boats.', 11),
    (v_trip, 'e-VOA Indonesia (web oficial)', 'tramites', 'Verificar requisitos vigentes cerca de la fecha.', 12),
    (v_trip, 'Declaración de aduanas electrónica (e-CD)', 'tramites', 'Verificar requisitos vigentes cerca de la fecha.', 13);

  -- ---------------------------------------------------------
  -- Contactos
  -- ---------------------------------------------------------
  insert into public.contacts (trip_id, name, contact_type, phone, whatsapp, notes) values
    (v_trip, 'Moson Bali Villa Legian', 'alojamiento', '+62 819-9908-4565', '+6281999084565', 'Reserva del 16 al 20 de octubre.'),
    (v_trip, 'Pearl of Trawangan', 'alojamiento', null, null, 'Pendiente de registrar teléfono.'),
    (v_trip, 'Emergencias Indonesia', 'emergencia', '112', null, null),
    (v_trip, 'Embajada de España en Yakarta', 'embajada', null, null, 'Pendiente de registrar.'),
    (v_trip, 'Seguro de viaje', 'seguro', null, null, 'Pendiente: número de póliza y asistencia 24 h.'),
    (v_trip, 'Conductor privado en Bali', 'transporte', null, null, 'Pendiente de contratar.');

  return v_trip;
end $$;

revoke all on function public.seed_bali_2026(text) from public;
