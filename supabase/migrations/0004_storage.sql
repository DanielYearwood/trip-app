-- =========================================================
-- 0004_storage.sql — bucket privado de documentos del viaje
-- Convención de ruta: {trip_id}/{entity_type}/{document_id}-{nombre}
-- El cliente accede siempre mediante createSignedUrl (300 s).
-- Ver README.md sección 8.4.
-- =========================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'trip-docs',
  'trip-docs',
  false,
  10485760,                                  -- 10 MB
  array['application/pdf','image/jpeg','image/png','image/webp','image/heic']
)
on conflict (id) do update
  set public             = excluded.public,
      file_size_limit    = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "trip docs read"   on storage.objects;
drop policy if exists "trip docs write"  on storage.objects;
drop policy if exists "trip docs update" on storage.objects;
drop policy if exists "trip docs delete" on storage.objects;

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

create policy "trip docs update" on storage.objects
  for update using (
    bucket_id = 'trip-docs'
    and public.is_trip_editor(((storage.foldername(name))[1])::uuid)
  );

create policy "trip docs delete" on storage.objects
  for delete using (
    bucket_id = 'trip-docs'
    and public.is_trip_editor(((storage.foldername(name))[1])::uuid)
  );
