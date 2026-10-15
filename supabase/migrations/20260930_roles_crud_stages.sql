-- Etapas productivas, nombre de cerdos, etapa por corral y permisos por rol.
-- Requiere haber ejecutado antes 20260928 y 20260929 (define es_administrador()).
-- Es idempotente: puede ejecutarse más de una vez.

do $$
begin
  create type public.etapa_productiva_enum as enum (
    'pre_inicio',
    'inicio',
    'desarrollo',
    'engorda',
    'gestacion',
    'lactancia'
  );
exception
  when duplicate_object then null;
end;
$$;

create table if not exists public.etapas_productivas (
  etapa public.etapa_productiva_enum primary key,
  nombre text not null,
  orden smallint not null default 0,
  peso_min_kg numeric(6,2),
  peso_max_kg numeric(6,2),
  racion_sugerida_kg_por_cerdo_dia numeric(6,3) not null
    check (racion_sugerida_kg_por_cerdo_dia > 0),
  check (peso_min_kg is null or peso_max_kg is null or peso_max_kg > peso_min_kg)
);
alter table public.etapas_productivas
  add column if not exists orden smallint not null default 0;

insert into public.etapas_productivas
  (etapa, nombre, orden, peso_min_kg, peso_max_kg, racion_sugerida_kg_por_cerdo_dia)
values
  ('pre_inicio', 'Pre-inicio (<15 kg)', 1, null, 15, 0.450),
  ('inicio', 'Inicio (15-30 kg)', 2, 15, 30, 0.900),
  ('desarrollo', 'Desarrollo (30-60 kg)', 3, 30, 60, 1.600),
  ('engorda', 'Engorda (>60 kg)', 4, 60, null, 2.400),
  ('gestacion', 'Gestación', 5, null, null, 2.200),
  ('lactancia', 'Lactancia', 6, null, null, 5.500)
on conflict (etapa) do update set
  nombre = excluded.nombre,
  orden = excluded.orden,
  peso_min_kg = excluded.peso_min_kg,
  peso_max_kg = excluded.peso_max_kg,
  racion_sugerida_kg_por_cerdo_dia = excluded.racion_sugerida_kg_por_cerdo_dia;

alter table public.cerdos add column if not exists nombre text;
alter table public.alimentos
  add column if not exists etapa public.etapa_productiva_enum
  references public.etapas_productivas(etapa);
alter table public.corrales
  add column if not exists etapa public.etapa_productiva_enum
  not null default 'desarrollo'
  references public.etapas_productivas(etapa);

-- Roles: el cliente nunca puede cambiar `rol`; se asigna desde SQL Editor.
-- (Una versión previa usaba un trigger que también bloqueaba al SQL Editor.)
drop trigger if exists proteger_rol_perfil on public.perfiles;
drop function if exists public.proteger_rol_perfil();

-- Operador: solo puede cambiar el estado de un corral, no sus datos.
create or replace function public.proteger_corral_operador()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if auth.uid() is null or public.es_administrador() then
    return new;
  end if;
  if (new.nombre, new.capacidad, new.ubicacion, new.etapa, new.user_id)
     is distinct from
     (old.nombre, old.capacidad, old.ubicacion, old.etapa, old.user_id) then
    raise exception 'Solo un administrador puede modificar los datos del corral.'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists proteger_corral_operador on public.corrales;
create trigger proteger_corral_operador
before update on public.corrales
for each row execute function public.proteger_corral_operador();

alter table public.perfiles enable row level security;
alter table public.cerdos enable row level security;
alter table public.corrales enable row level security;
alter table public.alimentos enable row level security;
alter table public.consumos enable row level security;
alter table public.partos enable row level security;
alter table public.etapas_productivas enable row level security;

do $$
declare
  policy_row record;
begin
  for policy_row in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = any(array[
        'perfiles', 'cerdos', 'corrales', 'alimentos',
        'consumos', 'partos', 'etapas_productivas'
      ])
  loop
    execute format(
      'drop policy %I on %I.%I',
      policy_row.policyname,
      policy_row.schemaname,
      policy_row.tablename
    );
  end loop;
end;
$$;

revoke insert, update, delete on public.perfiles from anon, authenticated;
grant select on public.perfiles to authenticated;
grant update (nombre, updated_at) on public.perfiles to authenticated;
grant select, insert, update, delete on
  public.cerdos, public.corrales, public.alimentos,
  public.consumos, public.partos, public.etapas_productivas
  to authenticated;

-- La granja es compartida: todos los usuarios autenticados ven los mismos datos.
create policy "perfiles consultar propio o admin"
on public.perfiles for select to authenticated
using (user_id = auth.uid() or public.es_administrador());
create policy "perfiles actualizar propio"
on public.perfiles for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- Cerdos: todos consultan, registran y editan; solo admin elimina.
create policy "cerdos lectura"
on public.cerdos for select to authenticated
using (auth.uid() is not null);
create policy "cerdos registrar"
on public.cerdos for insert to authenticated
with check (user_id = auth.uid() or public.es_administrador());
create policy "cerdos editar"
on public.cerdos for update to authenticated
using (auth.uid() is not null)
with check (auth.uid() is not null);
create policy "cerdos eliminar admin"
on public.cerdos for delete to authenticated
using (public.es_administrador());

-- Corrales: todos consultan y cambian estado; solo admin crea, edita datos y elimina.
create policy "corrales lectura"
on public.corrales for select to authenticated
using (auth.uid() is not null);
create policy "corrales crear admin"
on public.corrales for insert to authenticated
with check (public.es_administrador());
create policy "corrales actualizar"
on public.corrales for update to authenticated
using (auth.uid() is not null)
with check (auth.uid() is not null);
create policy "corrales eliminar admin"
on public.corrales for delete to authenticated
using (public.es_administrador());

-- Alimentos: catálogo compartido, solo admin lo modifica.
create policy "alimentos lectura"
on public.alimentos for select to authenticated
using (auth.uid() is not null);
create policy "alimentos crear admin"
on public.alimentos for insert to authenticated
with check (public.es_administrador());
create policy "alimentos editar admin"
on public.alimentos for update to authenticated
using (public.es_administrador())
with check (public.es_administrador());
create policy "alimentos eliminar admin"
on public.alimentos for delete to authenticated
using (public.es_administrador());

-- Consumos: todos consultan y registran; solo admin corrige o elimina.
create policy "consumos lectura"
on public.consumos for select to authenticated
using (auth.uid() is not null);
create policy "consumos registrar"
on public.consumos for insert to authenticated
with check (user_id = auth.uid() or public.es_administrador());
create policy "consumos editar admin"
on public.consumos for update to authenticated
using (public.es_administrador())
with check (public.es_administrador());
create policy "consumos eliminar admin"
on public.consumos for delete to authenticated
using (public.es_administrador());

-- Partos: todos consultan, registran inseminación y parto real; solo admin elimina.
create policy "partos lectura"
on public.partos for select to authenticated
using (auth.uid() is not null);
create policy "partos registrar"
on public.partos for insert to authenticated
with check (user_id = auth.uid() or public.es_administrador());
create policy "partos editar"
on public.partos for update to authenticated
using (auth.uid() is not null)
with check (auth.uid() is not null);
create policy "partos eliminar admin"
on public.partos for delete to authenticated
using (public.es_administrador());

-- Etapas: lectura para todos, escritura solo admin.
create policy "etapas lectura"
on public.etapas_productivas for select to authenticated
using (auth.uid() is not null);
create policy "etapas crear admin"
on public.etapas_productivas for insert to authenticated
with check (public.es_administrador());
create policy "etapas editar admin"
on public.etapas_productivas for update to authenticated
using (public.es_administrador())
with check (public.es_administrador());
create policy "etapas eliminar admin"
on public.etapas_productivas for delete to authenticated
using (public.es_administrador());

create or replace function public.eliminar_o_archivar_cerdo(p_cerdo_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.es_administrador() then
    raise exception 'Solo un administrador puede eliminar o archivar cerdos.'
      using errcode = '42501';
  end if;

  if not exists (select 1 from public.cerdos where id = p_cerdo_id) then
    raise exception 'El cerdo solicitado no existe.' using errcode = 'P0002';
  end if;

  if exists (select 1 from public.partos where cerda_id = p_cerdo_id) then
    update public.cerdos
    set estado = 'baja', updated_at = now()
    where id = p_cerdo_id;
    return 'archivado';
  end if;

  delete from public.cerdos where id = p_cerdo_id;
  return 'eliminado';
end;
$$;

revoke all on function public.eliminar_o_archivar_cerdo(uuid) from public;
grant execute on function public.eliminar_o_archivar_cerdo(uuid) to authenticated;

-- Recarga el caché de PostgREST para que la app vea las columnas nuevas al instante.
notify pgrst, 'reload schema';
