-- La tabla perfiles solo deja actualizar columnas concretas (permiso por columna).
-- Sin este permiso, subir la foto de perfil falla con "permission denied for table perfiles".
-- La política de filas ya limita el cambio al propio perfil de cada usuario.
--
-- Ejecutar en el SQL Editor de Supabase (ya aplicado en el proyecto de PorcinoTech).

grant update (foto_url) on public.perfiles to authenticated;

notify pgrst, 'reload schema';
