do $$
declare
  target_user auth.users%rowtype;
begin
  select *
  into target_user
  from auth.users
  where lower(email) = lower('jovmez0409@gmail.com');

  if not found then
    raise exception 'Registra primero la cuenta jovmez0409@gmail.com en la app o en Supabase Auth.';
  end if;

  insert into public.perfiles (user_id, nombre, rol)
  values (
    target_user.id,
    coalesce(target_user.raw_user_meta_data ->> 'nombre', ''),
    'admin'
  )
  on conflict (user_id) do update
    set rol = 'admin', updated_at = now();
end;
$$;
