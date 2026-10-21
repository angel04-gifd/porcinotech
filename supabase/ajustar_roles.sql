-- Deja los roles de las cuentas de prueba como deben ser.
-- Ejecútalo DESPUÉS de 20261003_multi_granja.sql (cambia los correos si hace falta).
--   * El administrador administra «Granja principal» (donde están los cerdos).
--   * El operador pertenece a esa granja solo como operador; se quitan las
--     granjas vacías que haya creado por error.
do $$
declare
  correo_admin text := 'jovmez0409@gmail.com';
  correo_operador text := 'jared0102@gmail.com';
  g uuid;
  adm uuid;
  op uuid;
begin
  select id into g from public.granjas order by created_at limit 1;
  select id into adm from auth.users where lower(email) = lower(correo_admin);
  select id into op from auth.users where lower(email) = lower(correo_operador);
  if g is null then
    raise exception 'Primero ejecuta 20261003_multi_granja.sql';
  end if;

  if adm is not null then
    insert into public.membresias (user_id, granja_id, rol)
    values (adm, g, 'admin')
    on conflict (user_id, granja_id) do update set rol = 'admin';
    update public.perfiles set tipo_cuenta = 'admin' where user_id = adm;
    perform public.activar_granja(adm, g);
  end if;

  if op is not null then
    delete from public.granjas
    where creada_por = op
      and id <> g
      and not exists (select 1 from public.cerdos c where c.granja_id = granjas.id);
    delete from public.membresias where user_id = op and granja_id <> g;
    insert into public.membresias (user_id, granja_id, rol)
    values (op, g, 'operador')
    on conflict (user_id, granja_id) do update set rol = 'operador';
    update public.perfiles set tipo_cuenta = 'operador' where user_id = op;
    perform public.activar_granja(op, g);
  end if;
end;
$$;

select u.email, m.rol, g.nombre as granja
from public.membresias m
join auth.users u on u.id = m.user_id
join public.granjas g on g.id = m.granja_id
order by u.email;
