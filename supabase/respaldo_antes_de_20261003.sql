-- Respaldo de seguridad antes de separar las granjas (solo lectura sobre public).
create schema if not exists respaldo_20261020;
create table if not exists respaldo_20261020.perfiles as table public.perfiles;
create table if not exists respaldo_20261020.corrales as table public.corrales;
create table if not exists respaldo_20261020.cerdos as table public.cerdos;
create table if not exists respaldo_20261020.alimentos as table public.alimentos;
create table if not exists respaldo_20261020.consumos as table public.consumos;
create table if not exists respaldo_20261020.partos as table public.partos;
select 'perfiles' t, count(*) from respaldo_20261020.perfiles
union all select 'corrales', count(*) from respaldo_20261020.corrales
union all select 'cerdos', count(*) from respaldo_20261020.cerdos
union all select 'alimentos', count(*) from respaldo_20261020.alimentos
union all select 'consumos', count(*) from respaldo_20261020.consumos
union all select 'partos', count(*) from respaldo_20261020.partos;
