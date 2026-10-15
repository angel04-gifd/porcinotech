-- El arete identifica al cerdo en toda la granja, no solo por usuario.
-- Ejecutar después de que los aretes existentes sean únicos (formato 0001, 0002, …).
create unique index if not exists cerdos_arete_unico on public.cerdos (arete);
