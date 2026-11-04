-- Eliminar mi cuenta (requisito de Google Play / Amazon Appstore).
-- Ejecutar una vez en Supabase > SQL Editor.
--
-- Reglas:
--  * Administrador que es el único miembro de su granja: se borra la granja y sus datos.
--  * Administrador con operadores: se rechaza (debe quitarlos primero) para no
--    dejar a nadie sin sus datos.
--  * Operador: sus registros pasan al administrador de la granja (si no, el
--    "on delete cascade" los borraría) y después se borra su cuenta.

create or replace function public.eliminar_mi_cuenta()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  uid uuid := auth.uid();
  m record;
  admin_id uuid;
begin
  if uid is null then
    raise exception 'Debes iniciar sesión.';
  end if;

  for m in select granja_id, rol from public.membresias where user_id = uid loop
    if m.rol = 'admin' then
      if exists (
        select 1 from public.membresias
        where granja_id = m.granja_id and user_id <> uid
      ) then
        raise exception 'Eres administrador de una granja con operadores. Quítalos primero desde Perfil.';
      end if;
      delete from public.granjas where id = m.granja_id;
    else
      select user_id into admin_id
      from public.membresias
      where granja_id = m.granja_id and rol = 'admin'
      limit 1;

      if admin_id is not null then
        update public.consumos  set user_id = admin_id where granja_id = m.granja_id and user_id = uid;
        update public.partos    set user_id = admin_id where granja_id = m.granja_id and user_id = uid;
        update public.cerdos    set user_id = admin_id where granja_id = m.granja_id and user_id = uid;
        update public.alimentos set user_id = admin_id where granja_id = m.granja_id and user_id = uid;
        update public.corrales  set user_id = admin_id where granja_id = m.granja_id and user_id = uid;
      end if;
    end if;
  end loop;

  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.eliminar_mi_cuenta() from public, anon;
grant execute on function public.eliminar_mi_cuenta() to authenticated;

notify pgrst, 'reload schema';
