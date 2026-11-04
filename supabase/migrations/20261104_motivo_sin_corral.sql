-- Un cerdo sin corral debe indicar por qué: venta, matadero, fallecimiento,
-- cuarentena, traslado u otro motivo. La app lo exige al editar un cerdo que
-- no tiene corral; en la base queda opcional para no invalidar los cerdos
-- anteriores, que todavía no tienen motivo.
--
-- Ejecutar en el SQL Editor de Supabase ANTES de instalar la versión 1.0.7.

alter table public.cerdos
  add column if not exists motivo_sin_corral text
  check (motivo_sin_corral is null or char_length(motivo_sin_corral) <= 60);

notify pgrst, 'reload schema';
