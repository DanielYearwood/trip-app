-- =========================================================
-- 0001_init.sql — esquema base de Bali Trip Planner
-- Ver README.md sección 7 para el contrato de este esquema.
-- =========================================================

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------
-- Perfiles
-- ---------------------------------------------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  avatar_url   text,
  created_at   timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------
-- Viajes y miembros
-- ---------------------------------------------------------
create table if not exists public.trips (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  slug           text unique,
  destination    text,
  start_date     date not null,
  end_date       date not null,
  base_currency  char(3) not null default 'EUR',
  local_currency char(3) not null default 'IDR',
  budget_total   numeric(12,2),
  budget_daily   numeric(12,2),
  travellers     int not null default 2,
  created_by     uuid not null references auth.users(id),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  constraint trips_dates_ok check (end_date >= start_date)
);

create table if not exists public.trip_members (
  trip_id   uuid not null references public.trips(id) on delete cascade,
  user_id   uuid not null references auth.users(id) on delete cascade,
  role      text not null default 'editor' check (role in ('owner','editor','viewer')),
  joined_at timestamptz not null default now(),
  primary key (trip_id, user_id)
);

create table if not exists public.trip_invites (
  id          uuid primary key default gen_random_uuid(),
  trip_id     uuid not null references public.trips(id) on delete cascade,
  email       text,
  role        text not null default 'editor' check (role in ('owner','editor','viewer')),
  token       text not null unique default encode(gen_random_bytes(24), 'hex'),
  expires_at  timestamptz not null default (now() + interval '30 days'),
  accepted_at timestamptz,
  accepted_by uuid references auth.users(id),
  created_by  uuid not null references auth.users(id),
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------
-- Zonas del viaje (Gili / Ubud / Seminyak)
-- ---------------------------------------------------------
create table if not exists public.zones (
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

-- ---------------------------------------------------------
-- Lugares: tabla central de todo lo que tiene ubicación
-- ---------------------------------------------------------
create table if not exists public.places (
  id             uuid primary key default gen_random_uuid(),
  trip_id        uuid not null references public.trips(id) on delete cascade,
  zone_id        uuid references public.zones(id) on delete set null,

  name           text not null,
  kind           text not null check (kind in (
                   'stay','activity','food','beach','transport',
                   'health','shopping','viewpoint','other')),
  category       text,
  status         text not null default 'idea' check (status in (
                   'idea','candidato','favorito','seleccionado','planificado',
                   'reservado','realizado','descartado')),
  discard_reason text,

  address        text,
  lat            numeric(9,6),
  lng            numeric(9,6),
  geocode_source text,

  price_amount   numeric(12,2),
  price_currency char(3) default 'EUR',
  price_basis    text check (price_basis in ('total','por_noche','por_persona','por_grupo')),
  price_pending  boolean not null default false,
  price_source   text,
  checked_at     date,

  rating            numeric(3,1),
  rating_count      int,
  location_rating   numeric(3,1),
  rating_checked_at date,

  walk_minutes_to_center int,
  walk_minutes_to_beach  int,
  walk_minutes_to_port   int,
  transport_notes        text,

  booking_url     text,
  website_url     text,
  gmaps_url       text,
  phone           text,
  email           text,
  cover_image_url text,

  pros  text[] not null default '{}',
  cons  text[] not null default '{}',
  tags  text[] not null default '{}',
  notes text,

  created_by uuid references auth.users(id),
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists places_trip_idx   on public.places (trip_id);
create index if not exists places_zone_idx   on public.places (zone_id);
create index if not exists places_kind_idx   on public.places (trip_id, kind);
create index if not exists places_status_idx on public.places (trip_id, status);
create index if not exists places_geo_idx    on public.places (lat, lng);

create table if not exists public.stay_details (
  place_id     uuid primary key references public.places(id) on delete cascade,
  stay_type    text check (stay_type in ('hotel','villa','resort','hostal','apartamento','homestay','otro')),
  check_in     date,
  check_out    date,
  nights       int generated always as (greatest((check_out - check_in), 0)) stored,
  room_type    text,
  room_size_m2 int,
  guests       int not null default 2,
  pool         text check (pool in ('privada','compartida','ninguna')),
  breakfast_included    boolean,
  pay_at_property       boolean not null default false,
  free_cancellation     boolean,
  cancellation_deadline timestamptz,
  booking_reference     text,
  distance_to_beach_m   int,
  distance_to_center_m  int,
  constraint stay_dates_ok check (check_out is null or check_in is null or check_out >= check_in)
);

create table if not exists public.activity_details (
  place_id                  uuid primary key references public.places(id) on delete cascade,
  duration_minutes          int,
  price_per_person          numeric(12,2),
  price_group               numeric(12,2),
  people                    int not null default 2,
  time_window_start         time,
  time_window_end           time,
  weather_dependent         boolean not null default false,
  rain_alternative_place_id uuid references public.places(id) on delete set null,
  booking_required          boolean not null default false,
  booking_deadline          date,
  provider                  text,
  booking_reference         text,
  effort_level              text check (effort_level in ('bajo','medio','alto')),
  what_to_bring             text
);

-- ---------------------------------------------------------
-- Itinerario
-- ---------------------------------------------------------
create table if not exists public.itinerary_days (
  id        uuid primary key default gen_random_uuid(),
  trip_id   uuid not null references public.trips(id) on delete cascade,
  date      date not null,
  zone_id   uuid references public.zones(id) on delete set null,
  title     text,
  summary   text,
  rain_plan text,
  notes     text,
  unique (trip_id, date)
);

create table if not exists public.itinerary_items (
  id               uuid primary key default gen_random_uuid(),
  trip_id          uuid not null references public.trips(id) on delete cascade,
  day_id           uuid not null references public.itinerary_days(id) on delete cascade,
  place_id         uuid references public.places(id) on delete cascade,
  route_id         uuid,
  title            text,
  start_time       time,
  end_time         time,
  duration_minutes int,
  sort_order       int not null default 0,
  status           text not null default 'planificado' check (status in (
                     'planificado','confirmado','realizado','cancelado')),
  notes            text,
  created_by       uuid references auth.users(id),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index if not exists itinerary_items_day_idx on public.itinerary_items (day_id, sort_order);

-- ---------------------------------------------------------
-- Rutas y transportes
-- ---------------------------------------------------------
create table if not exists public.routes (
  id            uuid primary key default gen_random_uuid(),
  trip_id       uuid not null references public.trips(id) on delete cascade,

  from_place_id uuid references public.places(id) on delete set null,
  to_place_id   uuid references public.places(id) on delete set null,
  from_label    text,
  to_label      text,
  from_lat numeric(9,6), from_lng numeric(9,6),
  to_lat   numeric(9,6), to_lng   numeric(9,6),

  mode text not null check (mode in (
         'walk','bike','cidomo','grab','taxi','private_driver',
         'shuttle','fast_boat','ferry','flight','other')),
  date             date,
  depart_at        timestamptz,
  arrive_at        timestamptz,
  duration_minutes int,
  distance_km      numeric(8,2),

  cost_amount      numeric(12,2),
  cost_currency    char(3) default 'EUR',
  cost_is_estimate boolean not null default true,

  operator          text,
  booking_url       text,
  booking_reference text,
  contact_phone     text,

  status text not null default 'idea' check (status in (
           'idea','requiere_confirmacion','reservada','confirmada',
           'en_riesgo','descartada')),
  risk_level     text check (risk_level in ('bajo','medio','alto')),
  risk_notes     text,
  alternative_of uuid references public.routes(id) on delete set null,

  geometry jsonb,
  notes    text,

  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists routes_trip_date_idx on public.routes (trip_id, date);

alter table public.itinerary_items
  drop constraint if exists itinerary_items_route_fk;
alter table public.itinerary_items
  add constraint itinerary_items_route_fk
  foreign key (route_id) references public.routes(id) on delete cascade;

-- ---------------------------------------------------------
-- Dinero
-- ---------------------------------------------------------
create table if not exists public.fx_rates (
  id     uuid primary key default gen_random_uuid(),
  base   char(3) not null,
  quote  char(3) not null,
  rate   numeric(18,8) not null,
  as_of  date not null,
  source text,
  unique (base, quote, as_of)
);

create table if not exists public.expenses (
  id       uuid primary key default gen_random_uuid(),
  trip_id  uuid not null references public.trips(id) on delete cascade,
  place_id uuid references public.places(id) on delete set null,
  route_id uuid references public.routes(id) on delete set null,
  day_id   uuid references public.itinerary_days(id) on delete set null,

  label    text not null,
  category text not null check (category in (
             'alojamiento','transporte_internacional','transporte_local',
             'actividad','comida','compras','tasas_visado','seguro','salud','otros')),

  amount     numeric(12,2) not null,
  currency   char(3) not null default 'EUR',
  amount_eur numeric(12,2),
  fx_rate    numeric(18,8),
  fx_date    date,

  status text not null default 'previsto' check (status in (
           'previsto','comprometido','parcialmente_pagado',
           'pagado','reembolsado','cancelado')),
  amount_paid    numeric(12,2) not null default 0,
  paid_by        uuid references auth.users(id),
  paid_at        timestamptz,
  payment_method text check (payment_method in ('tarjeta','efectivo','transferencia','en_destino','otro')),
  due_date       date,

  split_type          text not null default 'igual' check (split_type in ('igual','porcentaje','importe_exacto','solo_uno')),
  receipt_document_id uuid,
  notes               text,

  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint expenses_amount_positive check (amount >= 0),
  constraint expenses_paid_ok check (amount_paid >= 0 and amount_paid <= amount)
);

create index if not exists expenses_trip_idx   on public.expenses (trip_id);
create index if not exists expenses_status_idx on public.expenses (trip_id, status);

create table if not exists public.expense_shares (
  id           uuid primary key default gen_random_uuid(),
  expense_id   uuid not null references public.expenses(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  share_pct    numeric(6,3),
  share_amount numeric(12,2),
  settled      boolean not null default false,
  unique (expense_id, user_id)
);

-- ---------------------------------------------------------
-- Contenido: documentos, comentarios, checklists, apps, contactos, log
-- ---------------------------------------------------------
create table if not exists public.documents (
  id          uuid primary key default gen_random_uuid(),
  trip_id     uuid not null references public.trips(id) on delete cascade,
  entity_type text check (entity_type in ('trip','place','route','expense','day')),
  entity_id   uuid,
  title       text not null,
  doc_type    text not null check (doc_type in (
                'reserva_alojamiento','billete_vuelo','billete_barco','seguro',
                'visado','pasaporte','vacunas','recibo','otro')),
  storage_path  text,
  external_url  text,
  mime_type     text,
  size_bytes    bigint,
  reference     text,
  relevant_date date,
  is_sensitive  boolean not null default false,
  notes         text,
  uploaded_by   uuid references auth.users(id),
  created_at    timestamptz not null default now()
);

alter table public.expenses
  drop constraint if exists expenses_receipt_fk;
alter table public.expenses
  add constraint expenses_receipt_fk
  foreign key (receipt_document_id) references public.documents(id) on delete set null;

create table if not exists public.comments (
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

create index if not exists comments_entity_idx on public.comments (trip_id, entity_type, entity_id);

create table if not exists public.checklists (
  id         uuid primary key default gen_random_uuid(),
  trip_id    uuid not null references public.trips(id) on delete cascade,
  name       text not null,
  sort_order int not null default 0
);

create table if not exists public.checklist_items (
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

create table if not exists public.tools (
  id          uuid primary key default gen_random_uuid(),
  trip_id     uuid not null references public.trips(id) on delete cascade,
  name        text not null,
  category    text check (category in ('transporte','mapas','alojamiento','dinero','idioma','clima','comunicacion','tramites','otros')),
  url         text,
  ios_url     text,
  android_url text,
  notes       text,
  sort_order  int not null default 0
);

create table if not exists public.contacts (
  id           uuid primary key default gen_random_uuid(),
  trip_id      uuid not null references public.trips(id) on delete cascade,
  place_id     uuid references public.places(id) on delete set null,
  name         text not null,
  contact_type text check (contact_type in ('alojamiento','transporte','actividad','emergencia','seguro','embajada','otro')),
  phone        text,
  whatsapp     text,
  email        text,
  notes        text
);

create table if not exists public.activity_log (
  id           uuid primary key default gen_random_uuid(),
  trip_id      uuid not null references public.trips(id) on delete cascade,
  actor_id     uuid references auth.users(id) on delete set null,
  entity_type  text not null,
  entity_id    uuid,
  action       text not null,
  field        text,
  before_value jsonb,
  after_value  jsonb,
  created_at   timestamptz not null default now()
);

create index if not exists activity_log_trip_idx on public.activity_log (trip_id, created_at desc);

-- ---------------------------------------------------------
-- Triggers de updated_at
-- ---------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

do $$
declare t text;
begin
  foreach t in array array['trips','places','itinerary_items','routes','expenses','comments'] loop
    execute format('drop trigger if exists trg_touch_%1$s on public.%1$s', t);
    execute format(
      'create trigger trg_touch_%1$s before update on public.%1$s
         for each row execute function public.touch_updated_at()', t);
  end loop;
end $$;
