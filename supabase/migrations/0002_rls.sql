-- =========================================================
-- 0002_rls.sql — Row Level Security
-- Regla de oro: RLS activado en TODAS las tablas de dominio.
-- El cliente solo usa la anon key; la service_role nunca sale del servidor.
-- Ver README.md sección 8.
-- =========================================================

-- ---------------------------------------------------------
-- Funciones auxiliares (security definer para evitar recursión)
-- ---------------------------------------------------------
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

-- ---------------------------------------------------------
-- Activar RLS en todo
-- ---------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array[
    'profiles','trips','trip_members','trip_invites','zones','places',
    'stay_details','activity_details','itinerary_days','itinerary_items',
    'routes','expenses','expense_shares','documents','comments',
    'checklists','checklist_items','tools','contacts','activity_log','fx_rates'
  ] loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

-- ---------------------------------------------------------
-- Perfiles
-- ---------------------------------------------------------
drop policy if exists profiles_self on public.profiles;
create policy profiles_self on public.profiles
  for all using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists profiles_read_teammates on public.profiles;
create policy profiles_read_teammates on public.profiles
  for select using (
    exists (
      select 1 from public.trip_members m1
      join public.trip_members m2 on m1.trip_id = m2.trip_id
      where m1.user_id = auth.uid() and m2.user_id = profiles.id
    )
  );

-- ---------------------------------------------------------
-- Viajes
-- ---------------------------------------------------------
drop policy if exists trips_select on public.trips;
create policy trips_select on public.trips
  for select using (public.is_trip_member(id));

drop policy if exists trips_insert on public.trips;
create policy trips_insert on public.trips
  for insert with check (created_by = auth.uid());

drop policy if exists trips_update on public.trips;
create policy trips_update on public.trips
  for update using (public.is_trip_editor(id)) with check (public.is_trip_editor(id));

drop policy if exists trips_delete on public.trips;
create policy trips_delete on public.trips
  for delete using (public.is_trip_owner(id));

-- ---------------------------------------------------------
-- Miembros e invitaciones
-- ---------------------------------------------------------
drop policy if exists members_select on public.trip_members;
create policy members_select on public.trip_members
  for select using (public.is_trip_member(trip_id));

-- El creador se auto-inscribe como owner al crear el viaje.
drop policy if exists members_bootstrap on public.trip_members;
create policy members_bootstrap on public.trip_members
  for insert with check (
    user_id = auth.uid()
    and exists (select 1 from public.trips t where t.id = trip_id and t.created_by = auth.uid())
  );

drop policy if exists members_owner_write on public.trip_members;
create policy members_owner_write on public.trip_members
  for all using (public.is_trip_owner(trip_id)) with check (public.is_trip_owner(trip_id));

drop policy if exists invites_owner on public.trip_invites;
create policy invites_owner on public.trip_invites
  for all using (public.is_trip_owner(trip_id)) with check (public.is_trip_owner(trip_id));

-- ---------------------------------------------------------
-- Patrón genérico para las tablas con trip_id
-- ---------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array[
    'zones','places','itinerary_days','itinerary_items','routes',
    'expenses','documents','checklists','checklist_items','tools','contacts'
  ] loop
    execute format('drop policy if exists %1$s_select on public.%1$s', t);
    execute format('drop policy if exists %1$s_insert on public.%1$s', t);
    execute format('drop policy if exists %1$s_update on public.%1$s', t);
    execute format('drop policy if exists %1$s_delete on public.%1$s', t);

    execute format(
      'create policy %1$s_select on public.%1$s
         for select using (public.is_trip_member(trip_id))', t);
    execute format(
      'create policy %1$s_insert on public.%1$s
         for insert with check (public.is_trip_editor(trip_id))', t);
    execute format(
      'create policy %1$s_update on public.%1$s
         for update using (public.is_trip_editor(trip_id))
         with check (public.is_trip_editor(trip_id))', t);
    execute format(
      'create policy %1$s_delete on public.%1$s
         for delete using (public.is_trip_editor(trip_id))', t);
  end loop;
end $$;

-- ---------------------------------------------------------
-- Tablas hijas sin trip_id: se resuelven por el padre
-- ---------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['stay_details','activity_details'] loop
    execute format('drop policy if exists %1$s_all on public.%1$s', t);
    execute format(
      'create policy %1$s_all on public.%1$s
         for all using (
           exists (select 1 from public.places p
                    where p.id = %1$s.place_id and public.is_trip_member(p.trip_id))
         ) with check (
           exists (select 1 from public.places p
                    where p.id = %1$s.place_id and public.is_trip_editor(p.trip_id))
         )', t);
  end loop;
end $$;

drop policy if exists expense_shares_all on public.expense_shares;
create policy expense_shares_all on public.expense_shares
  for all using (
    exists (select 1 from public.expenses e
             where e.id = expense_shares.expense_id and public.is_trip_member(e.trip_id))
  ) with check (
    exists (select 1 from public.expenses e
             where e.id = expense_shares.expense_id and public.is_trip_editor(e.trip_id))
  );

-- ---------------------------------------------------------
-- Comentarios: leer todos los del viaje; editar/borrar solo los propios
-- ---------------------------------------------------------
drop policy if exists comments_select on public.comments;
create policy comments_select on public.comments
  for select using (public.is_trip_member(trip_id));

drop policy if exists comments_insert on public.comments;
create policy comments_insert on public.comments
  for insert with check (public.is_trip_editor(trip_id) and author_id = auth.uid());

drop policy if exists comments_update on public.comments;
create policy comments_update on public.comments
  for update using (author_id = auth.uid()) with check (author_id = auth.uid());

drop policy if exists comments_delete on public.comments;
create policy comments_delete on public.comments
  for delete using (author_id = auth.uid() or public.is_trip_owner(trip_id));

-- ---------------------------------------------------------
-- Log de actividad y tipos de cambio
-- ---------------------------------------------------------
drop policy if exists activity_log_select on public.activity_log;
create policy activity_log_select on public.activity_log
  for select using (public.is_trip_member(trip_id));

drop policy if exists activity_log_insert on public.activity_log;
create policy activity_log_insert on public.activity_log
  for insert with check (public.is_trip_member(trip_id));

drop policy if exists fx_select on public.fx_rates;
create policy fx_select on public.fx_rates
  for select using (auth.role() = 'authenticated');

-- ---------------------------------------------------------
-- Canje de invitación: el invitado aún no es miembro, así que
-- no puede leer trip_invites. Se canjea por función security definer.
-- ---------------------------------------------------------
create or replace function public.redeem_invite(p_token text)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_invite public.trip_invites;
begin
  select * into v_invite from public.trip_invites
   where token = p_token and accepted_at is null and expires_at > now();

  if not found then
    raise exception 'Invitación inválida o caducada';
  end if;

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
