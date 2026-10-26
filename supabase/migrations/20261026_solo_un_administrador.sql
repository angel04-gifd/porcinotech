-- Solo el administrador autorizado puede crear granjas; todos los demás entran
-- únicamente como operadores (unidos con un código de granja).
--   * La lista de administradores autorizados vive en la base de datos, en la
--     tabla administradores_autorizados. La app NO puede leerla ni cambiarla:
--     solo se edita desde el SQL Editor de Supabase.
--   * crear_granja() rechaza a cualquier cuenta que no esté en esa lista, así
--     que la regla se cumple aunque alguien use una versión vieja de la app.
--   * Las cuentas nuevas (correo o Google) siempre nacen como operador.
-- Requiere 20261003_multi_granja.sql. Es idempotente.

-- 1. Administradores autorizados -----------------------------------------------
create table if not exists public.administradores_autorizados (
  correo text primary key check (correo = lower(correo)),
  created_at timestamptz not null default now()
);
alter table public.administradores_autorizados enable row level security;
revoke all on public.administradores_autorizados from anon, authenticated;

-- CAMBIA este correo por el de tu cuenta de administrador si es otro.
insert into public.administradores_autorizados (correo)
values (lower('jovmez0409@gmail.com'))
on conflict do nothing;

-- ¿La cuenta que llama está autorizada como administrador? Exige correo
-- confirmado, para que nadie se haga pasar por otro correo.
create or replace function public.soy_admin_autorizado()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.administradores_autorizados a
    join auth.users u on lower(u.email) = a.correo
    where u.id = auth.uid()
      and u.email_confirmed_at is not null
  );
$$;
revoke all on function public.soy_admin_autorizado() from public;
grant execute on function public.soy_admin_autorizado() to authenticated;

-- 2. Crear granja: solo administradores autorizados ----------------------------
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
  -- Sin comas en el mensaje: la app lo muestra tal cual.
  if not public.soy_admin_autorizado() then
    raise exception 'Solo el administrador autorizado puede crear granjas. Únete con el código que te dio tu administrador.'
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

-- 3. Unirse con código: todas las cuentas excepto la del administrador ---------
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
  if public.soy_admin_autorizado() then
    raise exception 'Tu cuenta de administrador crea sus propias granjas; no se une con código.'
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

-- 4. Cuentas nuevas (correo o Google): siempre operador, con su nombre ----------
-- Google manda el nombre como «full_name» o «name»; el registro con correo, como «nombre».
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
    coalesce(
      nullif(new.raw_user_meta_data ->> 'nombre', ''),
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', ''),
      ''
    ),
    'operador',
    new.email
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

-- 5. OPCIONAL: quitar el rol de administrador a las demás cuentas ---------------
-- Las cuentas que ya habían creado una granja antes de esta regla siguen siendo
-- administradoras de ella. Si quieres que SOLO tu cuenta sea administradora,
-- quita los «--» de abajo y ejecútalo. Ojo: esas granjas se quedan sin
-- administrador hasta que tú decidas qué hacer con ellas.
--
-- update public.membresias m
-- set rol = 'operador'
-- where m.rol = 'admin'
--   and not exists (
--     select 1
--     from auth.users u
--     join public.administradores_autorizados a on lower(u.email) = a.correo
--     where u.id = m.user_id
--   );
-- update public.perfiles p
-- set rol = 'operador', tipo_cuenta = 'operador', updated_at = now()
-- where not exists (
--   select 1
--   from auth.users u
--   join public.administradores_autorizados a on lower(u.email) = a.correo
--   where u.id = p.user_id
-- );

notify pgrst, 'reload schema';
