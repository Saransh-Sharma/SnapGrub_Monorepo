create table if not exists public.barcode_lookup_misses (
  barcode text not null,
  provider text not null,
  reason text not null check (reason in ('not_found', 'provider_unavailable')),
  checked_at timestamptz not null default now(),
  expires_at timestamptz not null,
  primary key (provider, barcode)
);

create index if not exists idx_barcode_lookup_misses_expires_at
on public.barcode_lookup_misses (expires_at);

create unique index if not exists devices_install_id_unique
on public.devices (install_id);

alter table public.barcode_lookup_misses enable row level security;

revoke all on public.barcode_lookup_misses from anon, authenticated;
grant all privileges on public.barcode_lookup_misses to service_role;

drop policy if exists model_invocations_select_own on public.model_invocations;

create or replace function public.enforce_meal_item_custom_food_owner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.custom_food_id is not null and not exists (
    select 1
    from public.custom_foods cf
    where cf.id = new.custom_food_id
      and cf.user_id = new.user_id
      and cf.deleted_at is null
  ) then
    raise exception 'custom_food_id is invalid for this user' using errcode = '22023';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_meal_items_custom_food_owner on public.meal_items;
create trigger trg_meal_items_custom_food_owner
before insert or update of custom_food_id, user_id on public.meal_items
for each row execute function public.enforce_meal_item_custom_food_owner();

create or replace function public.expired_export_artifacts(p_limit integer default 1000)
returns table(id uuid, user_id uuid, result_storage_bucket text, result_storage_path text)
language sql
security definer
set search_path = public
as $$
  select er.id, er.user_id, er.result_storage_bucket, er.result_storage_path
  from public.export_requests er
  where er.status = 'completed'
    and er.expires_at is not null
    and er.expires_at < now()
  order by er.expires_at
  limit greatest(1, least(coalesce(p_limit, 1000), 10000))
$$;

revoke all on function public.expired_export_artifacts(integer) from public, anon, authenticated;
grant execute on function public.expired_export_artifacts(integer) to service_role;

create or replace function public.mark_exports_expired(p_export_ids uuid[])
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  update public.export_requests
  set
    status = 'expired',
    error_code = 'EXPIRED',
    signed_url = null,
    signed_url_expires_at = null
  where id = any(coalesce(p_export_ids, '{}'::uuid[]))
    and status = 'completed';

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function public.mark_exports_expired(uuid[]) from public, anon, authenticated;
grant execute on function public.mark_exports_expired(uuid[]) to service_role;
