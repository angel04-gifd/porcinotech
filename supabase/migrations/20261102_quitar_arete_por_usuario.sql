-- El arete ya es único por granja (índice cerdos_arete_unico_granja), pero quedó
-- el candado viejo "único por usuario". Con varias granjas, la primera cerda
-- nueva de una segunda granja intenta el arete 0001 y choca con el 0001 de la
-- primera granja del mismo usuario ("Ese dato ya está registrado").
-- También haría fallar «Eliminar mi cuenta» de un operador al pasar sus cerdos
-- al administrador. Quitarlo no pierde ninguna protección real.

alter table public.cerdos drop constraint if exists cerdos_user_id_arete_key;

notify pgrst, 'reload schema';
