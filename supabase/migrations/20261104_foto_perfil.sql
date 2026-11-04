-- Foto de perfil subida por el usuario.
--  * perfiles.foto_url guarda la dirección de la foto (tiene prioridad sobre la de Google).
--  * El bucket público "avatars" guarda los archivos: cada usuario solo escribe en su
--    propia carpeta (avatars/<id del usuario>/avatar.jpg), hasta 2 MB y solo JPG, PNG o WebP.
--
-- Ejecutar en el SQL Editor de Supabase ANTES de instalar la versión 1.0.7.

alter table public.perfiles add column if not exists foto_url text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

drop policy if exists "avatars: lectura" on storage.objects;
create policy "avatars: lectura" on storage.objects
  for select using (bucket_id = 'avatars');

drop policy if exists "avatars: subir la propia" on storage.objects;
create policy "avatars: subir la propia" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars: cambiar la propia" on storage.objects;
create policy "avatars: cambiar la propia" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars: borrar la propia" on storage.objects;
create policy "avatars: borrar la propia" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

notify pgrst, 'reload schema';
