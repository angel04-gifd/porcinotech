-- Reglas de negocio que la app antes solo validaba en pantalla.
-- Requiere 20260930 (tablas y roles) y 20261001 (arete único). Es idempotente.

-- 1. Gestación fallida: libera a la cerda cuando no llega a parir.
alter table public.partos
  add column if not exists fallida boolean not null default false;

alter table public.partos drop constraint if exists partos_fallida_sin_parto;
alter table public.partos
  add constraint partos_fallida_sin_parto
  check (not (fallida and fecha_parto is not null));

-- Una cerda solo puede tener una gestación en curso a la vez.
-- Si falla, hay cerdas con dos gestaciones pendientes: márcalas como fallidas
-- (update public.partos set fallida = true where id = '...') y vuelve a ejecutar.
create unique index if not exists partos_una_gestacion_pendiente
  on public.partos (cerda_id)
  where fecha_parto is null and not fallida;

-- 2. Validación de inseminaciones y partos.
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
    where id = new.cerda_id;

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

drop trigger if exists validar_parto on public.partos;
create trigger validar_parto
before insert or update on public.partos
for each row execute function public.validar_parto();

-- 3. Validación de cerdos: capacidad del corral y gestación en curso.
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
       where cerda_id = new.id and fecha_parto is null and not fallida
     ) then
    raise exception
      'La cerda tiene una gestación en curso. Registra el parto o márcala como fallida primero.';
  end if;

  -- Un corral no admite más cerdos activos que su capacidad. Solo se revisa
  -- al ingresar (alta, cambio de corral o reactivación), así los corrales que
  -- ya estaban llenos no bloquean ediciones sin relación.
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
    where id = new.corral_id
    for update;

    select count(*)
    into ocupantes
    from public.cerdos
    where corral_id = new.corral_id
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

drop trigger if exists validar_cerdo on public.cerdos;
create trigger validar_cerdo
before insert or update on public.cerdos
for each row execute function public.validar_cerdo();

-- 4. Peso razonable (no revisa filas anteriores).
alter table public.cerdos drop constraint if exists cerdos_peso_maximo;
alter table public.cerdos
  add constraint cerdos_peso_maximo check (peso <= 500) not valid;

notify pgrst, 'reload schema';
