create extension if not exists pg_trgm;

alter table public.devices
  drop constraint if exists devices_install_id_key;

create unique index if not exists devices_user_install_id_unique
on public.devices (user_id, install_id);

alter table public.meals
  drop constraint if exists meals_confidence_overall_range,
  add constraint meals_confidence_overall_range
    check (confidence_overall is null or confidence_overall between 0 and 1);

alter table public.meal_items
  drop constraint if exists meal_items_confidence_range,
  add constraint meal_items_confidence_range
    check (confidence is null or confidence between 0 and 1);

alter table public.food_portions
  drop constraint if exists food_portions_confidence_range,
  add constraint food_portions_confidence_range
    check (confidence between 0 and 1);

alter table public.catalog_food_mappings
  drop constraint if exists catalog_food_mappings_confidence_range,
  add constraint catalog_food_mappings_confidence_range
    check (mapping_confidence between 0 and 1);

alter table public.export_requests
  drop constraint if exists export_requests_status_check,
  add constraint export_requests_status_check
    check (status in ('queued', 'processing', 'completed', 'failed', 'expired'));

drop policy if exists meals_insert_own on public.meals;
drop policy if exists meals_update_own on public.meals;
drop policy if exists meals_delete_own on public.meals;
drop policy if exists meal_items_insert_own on public.meal_items;
drop policy if exists meal_items_update_own on public.meal_items;
drop policy if exists meal_items_delete_own on public.meal_items;
drop policy if exists correction_events_insert_own on public.correction_events;
drop policy if exists meal_assets_insert_own on public.meal_assets;
drop policy if exists meal_assets_update_own on public.meal_assets;

create index if not exists idx_canonical_foods_normalized_name_trgm
on public.canonical_foods using gin (normalized_name gin_trgm_ops);

create index if not exists idx_food_aliases_normalized_alias_trgm
on public.food_aliases using gin (normalized_alias gin_trgm_ops);

create index if not exists idx_branded_products_normalized_name_trgm
on public.branded_products using gin (normalized_name gin_trgm_ops);

create table if not exists public.job_runs (
  id uuid primary key default gen_random_uuid(),
  job_name text not null,
  request_id uuid,
  status text not null check (status in ('running', 'completed', 'failed')),
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  counts jsonb not null default '{}'::jsonb,
  error_summary jsonb not null default '{}'::jsonb
);

create index if not exists idx_job_runs_name_started
on public.job_runs (job_name, started_at desc);

alter table public.job_runs enable row level security;

grant all privileges on public.job_runs to service_role;

create or replace function public.mark_expired_exports_failed(p_limit integer default 1000)
returns table(id uuid, user_id uuid, result_storage_bucket text, result_storage_path text)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  with expired as (
    select er.id, er.user_id, er.result_storage_bucket, er.result_storage_path
    from public.export_requests er
    where er.status = 'completed'
      and er.expires_at is not null
      and er.expires_at < now()
    order by er.expires_at
    limit greatest(1, least(coalesce(p_limit, 1000), 10000))
  ),
  updated as (
    update public.export_requests er
    set
      status = 'expired',
      error_code = 'EXPIRED',
      signed_url = null,
      signed_url_expires_at = null
    from expired
    where er.id = expired.id
    returning expired.id, expired.user_id, expired.result_storage_bucket, expired.result_storage_path
  )
  select * from updated;
end;
$$;

revoke all on function public.mark_expired_exports_failed(integer) from public;
grant execute on function public.mark_expired_exports_failed(integer) to service_role;
