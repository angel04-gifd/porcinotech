alter table public.alimentos
  add column if not exists kg_por_cerdo_dia numeric(8,3) not null default 1
  check (kg_por_cerdo_dia > 0);

create or replace function public.aplicar_consumo_alimento()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  stock_actual numeric(12,2);
begin
  if tg_op in ('UPDATE', 'DELETE') then
    update public.alimentos
    set existencia_kg = existencia_kg + old.cantidad_kg,
        updated_at = now()
    where id = old.alimento_id;

    if tg_op = 'DELETE' then
      return old;
    end if;
  end if;

  select existencia_kg
  into stock_actual
  from public.alimentos
  where id = new.alimento_id
  for update;

  if not found then
    raise exception 'El alimento no existe.';
  end if;

  if stock_actual < new.cantidad_kg then
    raise exception 'Stock insuficiente. Disponible: % kg.', stock_actual;
  end if;

  update public.alimentos
  set existencia_kg = existencia_kg - new.cantidad_kg,
      updated_at = now()
  where id = new.alimento_id;

  return new;
end;
$$;

drop trigger if exists descontar_stock_por_consumo on public.consumos;
create trigger descontar_stock_por_consumo
before insert or update or delete on public.consumos
for each row execute function public.aplicar_consumo_alimento();
