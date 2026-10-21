-- Varias granjas, cada una con sus propios datos.
--   * Cada persona se registra solo con correo y contraseña; todo lo que captura
--     queda en la nube ligado a su cuenta, así que al reinstalar la app basta con
--     iniciar sesión para recuperarlo.
--   * Una cuenta puede crear las granjas que quiera (es administradora de cada
--     una) y cambiar entre ellas. Los datos de una granja nunca se mezclan con los
--     de otra.
--   * Los operadores se unen a una granja con su código de invitación (el
--     administrador lo ve en «Mi granja»).
--   * Datos personales (nombre, teléfono, puesto) para identificar al equipo.
-- Requiere 20260930, 20261001 y 20261002. Es idempotente.
-- Los datos que ya existían quedan juntos en la «Granja principal».

-- 1. Tablas -----------------------------------------------------------------
create table if not exists public.granjas (
  id uuid primary key default gen_random_uuid(),
  nombre text not null default 'Mi granja',
  codigo_invitacion text not null unique
    default substr(replace(gen_random_uuid()::text, '-', ''), 1, 12),
  creada_por uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);
alter table public.granjas enable row level security;

-- Un usuario puede pertenecer a varias granjas, con un rol en cada una.
create table if not exists public.membresias (
  user_id uuid not null references auth.users(id) on delete cascade,
  granja_id uuid not null references public.granjas(id) on delete cascade,
  rol text not null default 'operador' check (rol in ('admin', 'operador')),
  created_at timestamptz not null default now(),
  primary key (user_id, granja_id)
);
alter table public.membresias enable row level security;
create index if not exists membresias_granja_idx on public.membresias (granja_id);

-- perfiles.granja_id = granja activa del usuario (puede ser null al inicio).
alter table public.perfiles
  add column if not exists granja_id uuid references public.granjas(id) on delete set null,
  add column if not exists correo text,
  add column if not exists telefono text,
  add column if not exists puesto text,
  add column if not exists tipo_cuenta text
    check (tipo_cuenta in ('admin', 'operador'));
alter table public.corrales
  add column if not exists granja_id uuid references public.granjas(id) on delete cascade;
alter table public.cerdos
  add column if not exists granja_id uuid references public.granjas(id) on delete cascade;
alter table public.alimentos
  add column if not exists granja_id uuid references public.granjas(id) on delete cascade;
alter table public.consumos
  add column if not exists granja_id uuid references public.granjas(id) on delete cascade;
alter table public.partos
  add column if not exists granja_id uuid references public.granjas(id) on delete cascade;

update public.perfiles p set correo = u.email
from auth.users u where u.id = p.user_id and p.correo is null;

-- 2. Funciones de apoyo -------------------------------------------------------
create or replace function public.mi_granja_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select granja_id from public.perfiles where user_id = auth.uid();
$$;
revoke all on function public.mi_granja_id() from public;
grant execute on function public.mi_granja_id() to authenticated;

create or replace function public.soy_miembro_de(p_granja uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.membresias
    where user_id = auth.uid() and granja_id = p_granja
  );
$$;
revoke all on function public.soy_miembro_de(uuid) from public;
grant execute on function public.soy_miembro_de(uuid) to authenticated;

create or replace function public.soy_admin_de(p_granja uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.membresias
    where user_id = auth.uid() and granja_id = p_granja and rol = 'admin'
  );
$$;
revoke all on function public.soy_admin_de(uuid) from public;
grant execute on function public.soy_admin_de(uuid) to authenticated;

-- El rol ahora depende de la granja activa.
create or replace function public.es_administrador()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.soy_admin_de(public.mi_granja_id());
$$;
revoke all on function public.es_administrador() from public;
grant execute on function public.es_administrador() to authenticated;

-- 3. Datos existentes: todos a la «Granja principal» ---------------------------
alter table public.consumos disable trigger descontar_stock_por_consumo;
do $$
declare
  g uuid;
begin
  select id into g from public.granjas order by created_at limit 1;
  if g is null then
    insert into public.granjas (nombre) values ('Granja principal') returning id into g;
  end if;
  update public.corrales set granja_id = g where granja_id is null;
  update public.cerdos set granja_id = g where granja_id is null;
  update public.alimentos set granja_id = g where granja_id is null;
  update public.consumos set granja_id = g where granja_id is null;
  update public.partos set granja_id = g where granja_id is null;
  -- Quienes ya tenían cuenta pasan a ser miembros con el rol que tenían.
  insert into public.membresias (user_id, granja_id, rol)
  select user_id, g, rol from public.perfiles
  on conflict do nothing;
  update public.perfiles set granja_id = g where granja_id is null;
  -- El tipo de cuenta (admin u operador) queda fijo con el rol que ya tenían.
  update public.perfiles set tipo_cuenta = rol where tipo_cuenta is null;
end;
$$;
alter table public.consumos enable trigger descontar_stock_por_consumo;

alter table public.corrales alter column granja_id set not null;
alter table public.cerdos alter column granja_id set not null;
alter table public.alimentos alter column granja_id set not null;
alter table public.consumos alter column granja_id set not null;
alter table public.partos alter column granja_id set not null;

-- La app no manda la granja: se completa sola con la granja activa.
alter table public.corrales alter column granja_id set default public.mi_granja_id();
alter table public.cerdos alter column granja_id set default public.mi_granja_id();
alter table public.alimentos alter column granja_id set default public.mi_granja_id();
alter table public.consumos alter column granja_id set default public.mi_granja_id();
alter table public.partos alter column granja_id set default public.mi_granja_id();

create index if not exists perfiles_granja_idx on public.perfiles (granja_id);
create index if not exists corrales_granja_idx on public.corrales (granja_id);
create index if not exists cerdos_granja_idx on public.cerdos (granja_id);
create index if not exists alimentos_granja_idx on public.alimentos (granja_id);
create index if not exists consumos_granja_idx on public.consumos (granja_id);
create index if not exists partos_granja_idx on public.partos (granja_id);

-- El arete es único dentro de cada granja.
drop index if exists public.cerdos_arete_unico;
create unique index if not exists cerdos_arete_unico_granja
  on public.cerdos (granja_id, arete);

-- 4. Registro y elección de granja --------------------------------------------
-- Una cuenta nueva solo crea su perfil; después elige crear una granja o
-- unirse a una con código.
create or replace function public.crear_perfil_usuario()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.perfiles (user_id, nombre, rol, correo)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'nombre', ''),
    'operador',
    new.email
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

-- Activa una granja para el usuario y copia su rol en esa granja al perfil.
create or replace function public.activar_granja(p_user uuid, p_granja uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.perfiles p
  set granja_id = p_granja,
      rol = coalesce(
        (select m.rol from public.membresias m
          where m.user_id = p_user and m.granja_id = p_granja),
        'operador'),
      updated_at = now()
  where p.user_id = p_user;
end;
$$;
revoke all on function public.activar_granja(uuid, uuid) from public;

create or replace function public.crear_granja(p_nombre text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  g uuid;
begin
  if auth.uid() is null then
    raise exception 'Inicia sesión primero.' using errcode = '42501';
  end if;
  -- El tipo de cuenta es fijo: las cuentas de operador no crean granjas.
  if (select tipo_cuenta from public.perfiles where user_id = auth.uid()) = 'operador' then
    raise exception 'Una cuenta de operador no puede crear granjas; solo se une con código.'
      using errcode = '42501';
  end if;
  if length(trim(coalesce(p_nombre, ''))) < 2 then
    raise exception 'Escribe un nombre para la granja.' using errcode = '22023';
  end if;
  insert into public.granjas (nombre, creada_por)
  values (trim(p_nombre), auth.uid())
  returning id into g;
  insert into public.membresias (user_id, granja_id, rol)
  values (auth.uid(), g, 'admin');
  update public.perfiles set tipo_cuenta = 'admin' where user_id = auth.uid();
  perform public.activar_granja(auth.uid(), g);
  return g;
end;
$$;
revoke all on function public.crear_granja(text) from public;
grant execute on function public.crear_granja(text) to authenticated;

create or replace function public.unirse_a_granja(p_codigo text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  g uuid;
begin
  if auth.uid() is null then
    raise exception 'Inicia sesión primero.' using errcode = '42501';
  end if;
  if (select tipo_cuenta from public.perfiles where user_id = auth.uid()) = 'admin' then
    raise exception 'Una cuenta de administrador crea sus propias granjas; no se une con código.'
      using errcode = '42501';
  end if;
  select id into g from public.granjas
  where lower(codigo_invitacion) = lower(trim(coalesce(p_codigo, '')));
  if g is null then
    raise exception 'Ese código de granja no existe. Pídeselo a tu administrador.'
      using errcode = 'P0002';
  end if;
  insert into public.membresias (user_id, granja_id, rol)
  values (auth.uid(), g, 'operador')
  on conflict do nothing;
  update public.perfiles set tipo_cuenta = 'operador' where user_id = auth.uid();
  perform public.activar_granja(auth.uid(), g);
  return g;
end;
$$;
revoke all on function public.unirse_a_granja(text) from public;
grant execute on function public.unirse_a_granja(text) to authenticated;

create or replace function public.cambiar_granja(p_granja uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.soy_miembro_de(p_granja) then
    raise exception 'No perteneces a esa granja.' using errcode = '42501';
  end if;
  perform public.activar_granja(auth.uid(), p_granja);
end;
$$;
revoke all on function public.cambiar_granja(uuid) from public;
grant execute on function public.cambiar_granja(uuid) to authenticated;

-- Granjas del usuario; el código de invitación solo lo ve su administrador.
create or replace function public.mis_granjas()
returns table (
  id uuid,
  nombre text,
  rol text,
  codigo_invitacion text,
  activa boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select g.id, g.nombre, m.rol,
         case when m.rol = 'admin' then g.codigo_invitacion end,
         g.id = public.mi_granja_id()
  from public.membresias m
  join public.granjas g on g.id = m.granja_id
  where m.user_id = auth.uid()
  order by g.created_at;
$$;
revoke all on function public.mis_granjas() from public;
grant execute on function public.mis_granjas() to authenticated;

-- Equipo de la granja activa (solo administrador): quién es cada operador.
create or replace function public.equipo_granja()
returns table (
  user_id uuid,
  nombre text,
  correo text,
  telefono text,
  puesto text,
  rol text,
  desde timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.es_administrador() then
    raise exception 'Solo un administrador puede ver el equipo.' using errcode = '42501';
  end if;
  return query
  select p.user_id, p.nombre, p.correo, p.telefono, p.puesto, m.rol, m.created_at
  from public.membresias m
  join public.perfiles p on p.user_id = m.user_id
  where m.granja_id = public.mi_granja_id()
  order by (m.rol = 'admin') desc, m.created_at;
end;
$$;
revoke all on function public.equipo_granja() from public;
grant execute on function public.equipo_granja() to authenticated;

-- El administrador puede sacar a un operador de la granja activa.
create or replace function public.quitar_operador(p_user uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  g uuid := public.mi_granja_id();
begin
  if not public.es_administrador() then
    raise exception 'Solo un administrador puede quitar operadores.' using errcode = '42501';
  end if;
  if p_user = auth.uid() then
    raise exception 'No puedes quitarte a ti mismo.' using errcode = '22023';
  end if;
  if exists (
    select 1 from public.membresias
    where user_id = p_user and granja_id = g and rol = 'admin'
  ) then
    raise exception 'No se puede quitar a un administrador.' using errcode = '22023';
  end if;
  delete from public.membresias where user_id = p_user and granja_id = g;
  update public.perfiles set granja_id = null, rol = 'operador'
  where user_id = p_user and granja_id = g;
end;
$$;
revoke all on function public.quitar_operador(uuid) from public;
grant execute on function public.quitar_operador(uuid) to authenticated;

-- 5. Políticas -----------------------------------------------------------------
do $$
declare
  policy_row record;
begin
  for policy_row in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = any(array[
        'perfiles', 'granjas', 'membresias', 'cerdos', 'corrales', 'alimentos',
        'consumos', 'partos', 'etapas_productivas'
      ])
  loop
    execute format(
      'drop policy %I on %I.%I',
      policy_row.policyname, policy_row.schemaname, policy_row.tablename
    );
  end loop;
end;
$$;

revoke all on public.granjas from anon, authenticated;
grant select (id, nombre, created_at) on public.granjas to authenticated;
grant update (nombre) on public.granjas to authenticated;
revoke all on public.membresias from anon, authenticated;
grant select on public.membresias to authenticated;

create policy "granjas consultar las mias"
on public.granjas for select to authenticated
using (public.soy_miembro_de(id));
create policy "granjas renombrar admin"
on public.granjas for update to authenticated
using (public.soy_admin_de(id))
with check (public.soy_admin_de(id));

create policy "membresias consultar propias o de mi granja (admin)"
on public.membresias for select to authenticated
using (user_id = auth.uid() or public.soy_admin_de(granja_id));

-- Perfiles: cada quien ve y edita sus datos personales; el administrador ve a
-- los miembros de su granja activa. rol y granja_id solo cambian con las funciones.
revoke insert, update, delete on public.perfiles from anon, authenticated;
grant select on public.perfiles to authenticated;
grant update (nombre, telefono, puesto, updated_at) on public.perfiles to authenticated;

create policy "perfiles consultar propio o equipo (admin)"
on public.perfiles for select to authenticated
using (
  user_id = auth.uid()
  or (
    public.es_administrador()
    and exists (
      select 1 from public.membresias m
      where m.user_id = perfiles.user_id and m.granja_id = public.mi_granja_id()
    )
  )
);
create policy "perfiles actualizar propio"
on public.perfiles for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- Cerdos: todos en la granja consultan, registran y editan; solo admin elimina.
create policy "cerdos lectura"
on public.cerdos for select to authenticated
using (granja_id = public.mi_granja_id());
create policy "cerdos registrar"
on public.cerdos for insert to authenticated
with check (
  granja_id = public.mi_granja_id()
  and (user_id = auth.uid() or public.es_administrador())
);
create policy "cerdos editar"
on public.cerdos for update to authenticated
using (granja_id = public.mi_granja_id())
with check (granja_id = public.mi_granja_id());
create policy "cerdos eliminar admin"
on public.cerdos for delete to authenticated
using (granja_id = public.mi_granja_id() and public.es_administrador());

-- Corrales: todos consultan y cambian estado; solo admin crea, edita y elimina.
create policy "corrales lectura"
on public.corrales for select to authenticated
using (granja_id = public.mi_granja_id());
create policy "corrales crear admin"
on public.corrales for insert to authenticated
with check (granja_id = public.mi_granja_id() and public.es_administrador());
create policy "corrales actualizar"
on public.corrales for update to authenticated
using (granja_id = public.mi_granja_id())
with check (granja_id = public.mi_granja_id());
create policy "corrales eliminar admin"
on public.corrales for delete to authenticated
using (granja_id = public.mi_granja_id() and public.es_administrador());

-- Alimentos: catálogo de la granja; solo admin lo modifica.
create policy "alimentos lectura"
on public.alimentos for select to authenticated
using (granja_id = public.mi_granja_id());
create policy "alimentos crear admin"
on public.alimentos for insert to authenticated
with check (granja_id = public.mi_granja_id() and public.es_administrador());
create policy "alimentos editar admin"
on public.alimentos for update to authenticated
using (granja_id = public.mi_granja_id() and public.es_administrador())
with check (granja_id = public.mi_granja_id());
create policy "alimentos eliminar admin"
on public.alimentos for delete to authenticated
using (granja_id = public.mi_granja_id() and public.es_administrador());

-- Consumos: todos consultan y registran; solo admin corrige o elimina.
create policy "consumos lectura"
on public.consumos for select to authenticated
using (granja_id = public.mi_granja_id());
create policy "consumos registrar"
on public.consumos for insert to authenticated
with check (
  granja_id = public.mi_granja_id()
  and (user_id = auth.uid() or public.es_administrador())
);
create policy "consumos editar admin"
on public.consumos for update to authenticated
using (granja_id = public.mi_granja_id() and public.es_administrador())
with check (granja_id = public.mi_granja_id());
create policy "consumos eliminar admin"
on public.consumos for delete to authenticated
using (granja_id = public.mi_granja_id() and public.es_administrador());

-- Partos: todos consultan y registran; solo admin elimina.
create policy "partos lectura"
on public.partos for select to authenticated
using (granja_id = public.mi_granja_id());
create policy "partos registrar"
on public.partos for insert to authenticated
with check (
  granja_id = public.mi_granja_id()
  and (user_id = auth.uid() or public.es_administrador())
);
create policy "partos editar"
on public.partos for update to authenticated
using (granja_id = public.mi_granja_id())
with check (granja_id = public.mi_granja_id());
create policy "partos eliminar admin"
on public.partos for delete to authenticated
using (granja_id = public.mi_granja_id() and public.es_administrador());

-- Etapas productivas: catálogo común de solo lectura (la app no lo edita).
create policy "etapas lectura"
on public.etapas_productivas for select to authenticated
using (auth.uid() is not null);

-- 6. Eliminar o archivar un cerdo: solo de la granja activa ---------------------
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

  if not exists (
    select 1 from public.cerdos
    where id = p_cerdo_id and granja_id = public.mi_granja_id()
  ) then
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

-- 7. Reglas de negocio limitadas a la granja ----------------------------------
-- Estas funciones corren con permisos de dueño (saltan RLS), así que cada
-- consulta se limita a la granja del registro: un operador no puede tocar el
-- stock, los corrales ni las cerdas de otra granja aunque conozca sus ids.
create or replace function public.aplicar_consumo_alimento()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  stock_actual numeric(12,2);
begin
  if tg_op in ('UPDATE', 'DELETE') then
    update public.alimentos
    set existencia_kg = existencia_kg + old.cantidad_kg,
        updated_at = now()
    where id = old.alimento_id and granja_id = old.granja_id;

    if tg_op = 'DELETE' then
      return old;
    end if;
  end if;

  select existencia_kg
  into stock_actual
  from public.alimentos
  where id = new.alimento_id and granja_id = new.granja_id
  for update;

  if not found then
    raise exception 'El alimento no existe.';
  end if;

  if stock_actual < new.cantidad_kg then
    raise exception 'Stock insuficiente. Disponible: % kg.', stock_actual;
  end if;

  update public.alimentos
  set existencia_kg = existencia_kg - new.cantidad_kg,
      updated_at = now()
  where id = new.alimento_id and granja_id = new.granja_id;

  return new;
end;
$$;

create or replace function public.validar_parto()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  cerda record;
begin
  if tg_op = 'INSERT' then
    select sexo, estado, fecha_nacimiento
    into cerda
    from public.cerdos
    where id = new.cerda_id and granja_id = new.granja_id;

    if not found then
      raise exception 'La cerda no existe.';
    end if;
    if cerda.sexo <> 'hembra' then
      raise exception 'Solo una hembra puede ser inseminada.';
    end if;
    if cerda.estado <> 'activo' then
      raise exception 'La cerda no está activa.';
    end if;
    if cerda.fecha_nacimiento is not null
       and new.fecha_monta < cerda.fecha_nacimiento then
      raise exception 'La inseminación no puede ser anterior al nacimiento de la cerda.';
    end if;
  end if;

  if new.fecha_parto is not null
     and (tg_op = 'INSERT' or new.fecha_parto is distinct from old.fecha_parto) then
    if new.fecha_parto < new.fecha_monta + 100 then
      raise exception
        'El parto no puede registrarse antes de 100 días de gestación (desde %).',
        new.fecha_monta + 100;
    end if;
    if new.fecha_parto > current_date then
      raise exception 'La fecha del parto no puede estar en el futuro.';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.validar_cerdo()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  corral record;
  ocupantes integer;
begin
  -- Una cerda gestante no puede dejar de ser hembra activa.
  if tg_op = 'UPDATE'
     and (new.sexo <> 'hembra' or new.estado <> 'activo')
     and (old.sexo = 'hembra' and old.estado = 'activo')
     and exists (
       select 1 from public.partos
       where cerda_id = new.id and granja_id = new.granja_id
         and fecha_parto is null and not fallida
     ) then
    raise exception
      'La cerda tiene una gestación en curso. Registra el parto o márcala como fallida primero.';
  end if;

  -- Un corral no admite más cerdos activos que su capacidad.
  if new.corral_id is not null then
    perform 1 from public.corrales
    where id = new.corral_id and granja_id = new.granja_id;
    if not found then
      raise exception 'El corral no existe.';
    end if;
  end if;

  if new.estado = 'activo'
     and new.corral_id is not null
     and (
       tg_op = 'INSERT'
       or new.corral_id is distinct from old.corral_id
       or old.estado <> 'activo'
     ) then
    select id, nombre, capacidad
    into corral
    from public.corrales
    where id = new.corral_id and granja_id = new.granja_id
    for update;

    select count(*)
    into ocupantes
    from public.cerdos
    where corral_id = new.corral_id
      and granja_id = new.granja_id
      and estado = 'activo'
      and id <> new.id;

    if ocupantes >= corral.capacidad then
      raise exception 'El corral % está lleno (% de %).',
        corral.nombre, ocupantes, corral.capacidad;
    end if;
  end if;

  return new;
end;
$$;

notify pgrst, 'reload schema';
