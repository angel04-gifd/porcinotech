create table public.perfiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nombre text,
  rol text not null default 'operador' check (rol in ('admin', 'operador')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.corrales (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  nombre text not null, capacidad integer not null check (capacidad > 0),
  estado text not null default 'normal' check (estado in ('normal', 'mantenimiento', 'alerta')),
  ubicacion text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table public.cerdos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  corral_id uuid references public.corrales(id) on delete set null,
  arete text not null, raza text, peso numeric(10,2) check (peso >= 0),
  fecha_nacimiento date, sexo text not null check (sexo in ('macho', 'hembra')),
  estado text not null default 'activo' check (estado in ('activo', 'vendido', 'fallecido', 'baja')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (user_id, arete)
);

create table public.alimentos (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  nombre text not null, tipo text, existencia_kg numeric(12,2) not null default 0 check (existencia_kg >= 0),
  costo_por_kg numeric(12,2) not null default 0 check (costo_por_kg >= 0),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table public.consumos (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  alimento_id uuid not null references public.alimentos(id) on delete restrict,
  corral_id uuid references public.corrales(id) on delete set null,
  cantidad_kg numeric(12,2) not null check (cantidad_kg > 0), fecha date not null default current_date,
  observaciones text, created_at timestamptz not null default now()
);

create table public.partos (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  cerda_id uuid not null references public.cerdos(id) on delete restrict,
  fecha_monta date not null, fecha_estimada_parto date not null,
  fecha_parto date, lechones_nacidos integer check (lechones_nacidos >= 0),
  lechones_vivos integer check (lechones_vivos >= 0 and lechones_vivos <= coalesce(lechones_nacidos, lechones_vivos)),
  observaciones text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check (fecha_estimada_parto = fecha_monta + 114)
);

create or replace function public.crear_perfil_usuario() returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.perfiles (user_id, nombre, rol) values (new.id, coalesce(new.raw_user_meta_data ->> 'nombre', ''), 'operador');
  return new;
end;
$$;

create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.crear_perfil_usuario();

alter table public.perfiles enable row level security;
alter table public.corrales enable row level security;
alter table public.cerdos enable row level security;
alter table public.alimentos enable row level security;
alter table public.consumos enable row level security;
alter table public.partos enable row level security;

create policy "perfiles propios" on public.perfiles for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "corrales propios" on public.corrales for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "cerdos propios" on public.cerdos for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "alimentos propios" on public.alimentos for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "consumos propios" on public.consumos for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "partos propios" on public.partos for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
