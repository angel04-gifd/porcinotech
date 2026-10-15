create or replace function public.es_administrador()
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select exists (
    select 1
    from public.perfiles
    where user_id = auth.uid()
      and rol = 'admin'
  );
$$;

revoke all on function public.es_administrador() from public;
grant execute on function public.es_administrador() to authenticated;

revoke insert, update, delete on public.perfiles from anon, authenticated;
grant select on public.perfiles to authenticated;
grant update (nombre) on public.perfiles to authenticated;

alter table public.perfiles enable row level security;
alter table public.cerdos enable row level security;
alter table public.corrales enable row level security;
alter table public.alimentos enable row level security;
alter table public.consumos enable row level security;
alter table public.partos enable row level security;

drop policy if exists "perfiles propios" on public.perfiles;
drop policy if exists "cerdos propios" on public.cerdos;
drop policy if exists "corrales propios" on public.corrales;
drop policy if exists "alimentos propios" on public.alimentos;
drop policy if exists "consumos propios" on public.consumos;
drop policy if exists "partos propios" on public.partos;
drop policy if exists "alimentos catalogo compartido" on public.alimentos;
drop policy if exists "alimentos lectura propia o admin" on public.alimentos;

drop policy if exists "perfiles actualizar nombre propio o admin" on public.perfiles;
drop policy if exists "cerdos lectura propia o admin" on public.cerdos;
drop policy if exists "cerdos insertar propio o admin" on public.cerdos;
drop policy if exists "cerdos actualizar propio o admin" on public.cerdos;
drop policy if exists "cerdos eliminar admin" on public.cerdos;
drop policy if exists "corrales lectura propia o admin" on public.corrales;
drop policy if exists "corrales insertar admin" on public.corrales;
drop policy if exists "corrales insertar propio o admin" on public.corrales;
drop policy if exists "corrales actualizar estado propio o admin" on public.corrales;
drop policy if exists "corrales eliminar admin" on public.corrales;
drop policy if exists "alimentos escritura admin" on public.alimentos;
drop policy if exists "consumos lectura propia o admin" on public.consumos;
drop policy if exists "consumos insertar propio o admin" on public.consumos;
drop policy if exists "consumos modificar admin" on public.consumos;
drop policy if exists "consumos eliminar admin" on public.consumos;
drop policy if exists "partos lectura propia o admin" on public.partos;
drop policy if exists "partos insertar propio o admin" on public.partos;
drop policy if exists "partos modificar admin" on public.partos;
drop policy if exists "partos eliminar admin" on public.partos;

drop policy if exists "perfiles lectura propia o admin" on public.perfiles;
create policy "perfiles lectura propia o admin"
on public.perfiles for select to authenticated
using (user_id = auth.uid() or public.es_administrador());

create policy "perfiles actualizar nombre propio o admin"
on public.perfiles for update to authenticated
using (user_id = auth.uid() or public.es_administrador())
with check (user_id = auth.uid() or public.es_administrador());

create policy "cerdos lectura propia o admin"
on public.cerdos for select to authenticated
using (user_id = auth.uid() or public.es_administrador());
create policy "cerdos insertar propio o admin"
on public.cerdos for insert to authenticated
with check (user_id = auth.uid() or public.es_administrador());
create policy "cerdos actualizar propio o admin"
on public.cerdos for update to authenticated
using (user_id = auth.uid() or public.es_administrador())
with check (user_id = auth.uid() or public.es_administrador());
create policy "cerdos eliminar admin"
on public.cerdos for delete to authenticated
using (public.es_administrador());

create policy "corrales lectura propia o admin"
on public.corrales for select to authenticated
using (user_id = auth.uid() or public.es_administrador());
create policy "corrales insertar propio o admin"
on public.corrales for insert to authenticated
with check (user_id = auth.uid() or public.es_administrador());
create policy "corrales actualizar estado propio o admin"
on public.corrales for update to authenticated
using (user_id = auth.uid() or public.es_administrador())
with check (user_id = auth.uid() or public.es_administrador());
create policy "corrales eliminar admin"
on public.corrales for delete to authenticated
using (public.es_administrador());
revoke update on public.corrales from anon, authenticated;
grant update (estado, updated_at) on public.corrales to authenticated;

create policy "alimentos catalogo compartido"
on public.alimentos for select to authenticated
using (auth.uid() is not null);
create policy "alimentos escritura admin"
on public.alimentos for all to authenticated
using (public.es_administrador())
with check (public.es_administrador());

create policy "consumos lectura propia o admin"
on public.consumos for select to authenticated
using (user_id = auth.uid() or public.es_administrador());
create policy "consumos insertar propio o admin"
on public.consumos for insert to authenticated
with check (user_id = auth.uid() or public.es_administrador());
create policy "consumos modificar admin"
on public.consumos for update to authenticated
using (public.es_administrador())
with check (public.es_administrador());
create policy "consumos eliminar admin"
on public.consumos for delete to authenticated
using (public.es_administrador());

create policy "partos lectura propia o admin"
on public.partos for select to authenticated
using (user_id = auth.uid() or public.es_administrador());
create policy "partos insertar propio o admin"
on public.partos for insert to authenticated
with check (user_id = auth.uid() or public.es_administrador());
create policy "partos modificar admin"
on public.partos for update to authenticated
using (public.es_administrador())
with check (public.es_administrador());
create policy "partos eliminar admin"
on public.partos for delete to authenticated
using (public.es_administrador());
