-- Datos FICTICIOS de un mes de trabajo en una granja de demostración.
-- Ejecútalo DESPUÉS de 20261003_multi_granja.sql y ajustar_roles.sql.
--   * Crea «Granja Demo» (el administrador la ve con el botón de granja de la
--     barra superior); el operador se une como operador.
--   * Corrales, cerdos, alimentos, 30 días de consumos y partos, repartidos
--     entre administrador y operador.
--   * Es repetible: si ya existe «Granja Demo» de ese administrador, la rehace.
-- Para borrarla: ejecuta solo el bloque «Limpieza» de abajo.
do $$
declare
  correo_admin text := 'jovmez0409@gmail.com';
  correo_operador text := 'jared0102@gmail.com';
  adm uuid;
  op uuid;
  u uuid[];
  g uuid;
  c_gest uuid; c_mat uuid; c_des uuid; c_dev uuid; c_eng uuid;
  i int;
  d int;
  r record;
  cerda uuid;
begin
  select id into adm from auth.users where lower(email) = lower(correo_admin);
  select id into op from auth.users where lower(email) = lower(correo_operador);
  if adm is null then
    raise exception 'No existe la cuenta %', correo_admin;
  end if;
  if op is null then op := adm; end if;
  if not exists (select 1 from information_schema.tables
                 where table_schema = 'public' and table_name = 'membresias') then
    raise exception 'Primero ejecuta 20261003_multi_granja.sql';
  end if;
  u := array[adm, op];

  -- Rehacer la demo si ya existía.
  select id into g from public.granjas where nombre = 'Granja Demo' and creada_por = adm;
  if g is not null then
    delete from public.partos where granja_id = g;
    delete from public.consumos where granja_id = g;
    delete from public.cerdos where granja_id = g;
    delete from public.alimentos where granja_id = g;
    delete from public.corrales where granja_id = g;
    delete from public.membresias where granja_id = g;
    update public.perfiles set granja_id = null where granja_id = g;
    delete from public.granjas where id = g;
  end if;

  insert into public.granjas (nombre, creada_por) values ('Granja Demo', adm) returning id into g;
  insert into public.membresias (user_id, granja_id, rol) values (adm, g, 'admin');
  if op <> adm then
    insert into public.membresias (user_id, granja_id, rol) values (op, g, 'operador');
  end if;

  -- Corrales ------------------------------------------------------------------
  insert into public.corrales (user_id, granja_id, nombre, capacidad, estado, ubicacion, etapa, created_at)
  values (adm, g, 'Gestación', 8, 'normal', 'Nave A', 'gestacion', now() - interval '31 days')
  returning id into c_gest;
  insert into public.corrales (user_id, granja_id, nombre, capacidad, estado, ubicacion, etapa, created_at)
  values (adm, g, 'Maternidad', 6, 'normal', 'Nave B', 'lactancia', now() - interval '31 days')
  returning id into c_mat;
  insert into public.corrales (user_id, granja_id, nombre, capacidad, estado, ubicacion, etapa, created_at)
  values (adm, g, 'Destete', 10, 'alerta', 'Nave C', 'inicio', now() - interval '31 days')
  returning id into c_des;
  insert into public.corrales (user_id, granja_id, nombre, capacidad, estado, ubicacion, etapa, created_at)
  values (adm, g, 'Desarrollo', 12, 'mantenimiento', 'Nave D', 'desarrollo', now() - interval '31 days')
  returning id into c_dev;
  insert into public.corrales (user_id, granja_id, nombre, capacidad, estado, ubicacion, etapa, created_at)
  values (adm, g, 'Engorda', 15, 'normal', 'Nave E', 'engorda', now() - interval '31 days')
  returning id into c_eng;

  -- Alimentos (existencia inicial; los consumos la van descontando) -----------
  insert into public.alimentos (user_id, granja_id, nombre, tipo, existencia_kg, costo_por_kg, kg_por_cerdo_dia, etapa, created_at) values
    (adm, g, 'Iniciador 21%', 'Concentrado', 2500, 13.80, 0.9, 'inicio', now() - interval '31 days'),
    (adm, g, 'Desarrollo 16%', 'Concentrado', 2500, 9.60, 1.6, 'desarrollo', now() - interval '31 days'),
    (adm, g, 'Engorda 14%', 'Concentrado', 2500, 8.10, 2.4, 'engorda', now() - interval '31 days'),
    (adm, g, 'Gestación 14%', 'Concentrado', 2500, 8.40, 2.2, 'gestacion', now() - interval '31 days'),
    (adm, g, 'Lactancia 18%', 'Concentrado', 2500, 9.90, 5.5, 'lactancia', now() - interval '31 days');

  -- Cerdos --------------------------------------------------------------------
  -- Cerdas de gestación (1-6) y de maternidad (7-9), más un semental.
  for i in 1..9 loop
    insert into public.cerdos
      (user_id, granja_id, corral_id, arete, nombre, raza, peso, fecha_nacimiento, sexo, estado, created_at)
    values (
      u[1 + i % 2], g, case when i <= 6 then c_gest else c_mat end,
      'DM-S' || lpad(i::text, 2, '0'),
      (array['Lola','Rosita','Canela','Pinta','Manchas','Nube','Fresa','Paloma','Chata'])[i],
      (array['Landrace','Yorkshire','Duroc'])[1 + i % 3],
      180 + i * 4, current_date - (700 + i * 20), 'hembra', 'activo',
      now() - interval '30 days' + (i || ' hours')::interval
    );
  end loop;
  insert into public.cerdos
    (user_id, granja_id, corral_id, arete, nombre, raza, peso, fecha_nacimiento, sexo, estado, created_at)
  values (adm, g, c_gest, 'DM-V01', 'Toro', 'Duroc', 240, current_date - 900, 'macho', 'activo',
          now() - interval '30 days');

  -- Destete (8), desarrollo (10) y engorda (12).
  for i in 1..8 loop
    insert into public.cerdos
      (user_id, granja_id, corral_id, arete, raza, peso, fecha_nacimiento, sexo, estado, created_at)
    values (u[1 + i % 2], g, c_des, 'DM-D' || lpad(i::text, 2, '0'),
            (array['Landrace','Yorkshire','Duroc'])[1 + i % 3], 17 + i * 1.3,
            current_date - (46 + i), case when i % 2 = 0 then 'macho' else 'hembra' end,
            'activo', now() - interval '24 days' + (i || ' hours')::interval);
  end loop;
  for i in 1..10 loop
    insert into public.cerdos
      (user_id, granja_id, corral_id, arete, raza, peso, fecha_nacimiento, sexo, estado, created_at)
    values (u[1 + i % 2], g, c_dev, 'DM-R' || lpad(i::text, 2, '0'),
            (array['Landrace','Yorkshire','Duroc'])[1 + i % 3], 34 + i * 2.1,
            current_date - (100 + i * 2), case when i % 2 = 0 then 'macho' else 'hembra' end,
            'activo', now() - interval '27 days' + (i || ' hours')::interval);
  end loop;
  for i in 1..12 loop
    insert into public.cerdos
      (user_id, granja_id, corral_id, arete, raza, peso, fecha_nacimiento, sexo, estado, created_at)
    values (u[1 + i % 2], g, c_eng, 'DM-E' || lpad(i::text, 2, '0'),
            (array['Landrace','Yorkshire','Duroc'])[1 + i % 3], 66 + i * 3.2,
            current_date - (160 + i * 2), case when i % 2 = 0 then 'macho' else 'hembra' end,
            'activo', now() - interval '29 days' + (i || ' hours')::interval);
  end loop;
  -- Dos vendidos y uno fallecido este mes.
  insert into public.cerdos
    (user_id, granja_id, corral_id, arete, raza, peso, fecha_nacimiento, sexo, estado, created_at)
  values
    (adm, g, null, 'DM-X01', 'Yorkshire', 112, current_date - 210, 'macho', 'vendido', now() - interval '29 days'),
    (op, g, null, 'DM-X02', 'Landrace', 108, current_date - 205, 'hembra', 'vendido', now() - interval '29 days'),
    (op, g, null, 'DM-X03', 'Duroc', 11, current_date - 40, 'macho', 'fallecido', now() - interval '29 days');

  -- Partos ----------------------------------------------------------------------
  -- Tres partos recientes (cerdas en maternidad).
  for i in 7..9 loop
    select id into cerda from public.cerdos
      where granja_id = g and arete = 'DM-S' || lpad(i::text, 2, '0');
    insert into public.partos
      (user_id, granja_id, cerda_id, fecha_monta, fecha_estimada_parto, fecha_parto,
       lechones_nacidos, lechones_vivos, observaciones, created_at)
    values (u[1 + i % 2], g, cerda,
            current_date - (114 + (i - 6) * 3 + 14), current_date - ((i - 6) * 3 + 14),
            current_date - ((i - 6) * 3 + 14),
            9 + i % 4, 8 + i % 4,
            case i when 7 then 'Parto normal, camada pareja.'
                   when 8 then 'Sin complicaciones.'
                   else 'Un lechón débil, se vigila.' end,
            current_date - ((i - 6) * 3 + 14));
  end loop;
  -- Cuatro gestaciones en curso y una gestación fallida más una nueva.
  for i in 1..5 loop
    select id into cerda from public.cerdos
      where granja_id = g and arete = 'DM-S' || lpad(i::text, 2, '0');
    insert into public.partos
      (user_id, granja_id, cerda_id, fecha_monta, fecha_estimada_parto, observaciones, created_at)
    values (u[1 + i % 2], g, cerda,
            current_date - (i * 14 - 4), current_date - (i * 14 - 4) + 114,
            'Inseminación artificial.', current_date - (i * 14 - 4));
  end loop;
  select id into cerda from public.cerdos where granja_id = g and arete = 'DM-S06';
  insert into public.partos
    (user_id, granja_id, cerda_id, fecha_monta, fecha_estimada_parto, fallida, observaciones, created_at)
  values (op, g, cerda, current_date - 50, current_date - 50 + 114, true,
          'No quedó gestante, se repite.', current_date - 50);
  insert into public.partos
    (user_id, granja_id, cerda_id, fecha_monta, fecha_estimada_parto, observaciones, created_at)
  values (adm, g, cerda, current_date - 5, current_date - 5 + 114,
          'Segunda inseminación.', current_date - 5);

  -- Consumos diarios de los últimos 30 días ----------------------------------------
  for d in 0..29 loop
    for r in
      select c.id as cid, a.id as aid, a.kg_por_cerdo_dia as kg,
             (select count(*) from public.cerdos z
               where z.corral_id = c.id and z.estado = 'activo') as n
      from public.corrales c
      join public.alimentos a on a.etapa = c.etapa and a.granja_id = c.granja_id
      where c.granja_id = g
    loop
      insert into public.consumos
        (user_id, granja_id, alimento_id, corral_id, cantidad_kg, fecha, observaciones, created_at)
      values (u[1 + d % 2], g, r.aid, r.cid,
              round((r.n * r.kg * (0.92 + random() * 0.16))::numeric, 1),
              current_date - d, 'Ración diaria',
              ((current_date - d)::timestamp + time '07:30')::timestamptz);
    end loop;
  end loop;

  -- Que el administrador vea la demo si aún no tenía granja activa.
  update public.perfiles set granja_id = g, rol = 'admin' where user_id = adm and granja_id is null;
  update public.perfiles set granja_id = g, rol = 'operador' where user_id = op and op <> adm and granja_id is null;
end;
$$;

-- Resumen
select 'cerdos' as tabla, count(*) from public.cerdos c join public.granjas g on g.id = c.granja_id where g.nombre = 'Granja Demo'
union all select 'corrales', count(*) from public.corrales c join public.granjas g on g.id = c.granja_id where g.nombre = 'Granja Demo'
union all select 'consumos', count(*) from public.consumos c join public.granjas g on g.id = c.granja_id where g.nombre = 'Granja Demo'
union all select 'partos', count(*) from public.partos c join public.granjas g on g.id = c.granja_id where g.nombre = 'Granja Demo';

-- Limpieza (opcional): borra la granja demo y todos sus datos.
-- do $$
-- declare g uuid;
-- begin
--   select id into g from public.granjas where nombre = 'Granja Demo';
--   delete from public.partos where granja_id = g;
--   delete from public.consumos where granja_id = g;
--   delete from public.cerdos where granja_id = g;
--   delete from public.alimentos where granja_id = g;
--   delete from public.corrales where granja_id = g;
--   delete from public.membresias where granja_id = g;
--   update public.perfiles set granja_id = null where granja_id = g;
--   delete from public.granjas where id = g;
-- end;
-- $$;
