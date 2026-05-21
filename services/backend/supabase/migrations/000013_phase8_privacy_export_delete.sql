alter table public.export_requests
  add column if not exists result_storage_bucket text,
  add column if not exists signed_url text,
  add column if not exists signed_url_expires_at timestamptz,
  add column if not exists expires_at timestamptz,
  add column if not exists size_bytes bigint,
  add column if not exists content_type text,
  add column if not exists row_counts jsonb not null default '{}'::jsonb;

create index if not exists idx_export_requests_expires_at
on public.export_requests (expires_at)
where status = 'completed';

create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  requested_by uuid not null,
  status text not null default 'processing'
    check (status in ('processing', 'completed', 'failed')),
  confirmation text not null,
  deleted_storage_objects integer not null default 0,
  deleted_at timestamptz,
  error_code text,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_account_deletion_requests_user_created
on public.account_deletion_requests (user_id, created_at desc);

drop trigger if exists trg_account_deletion_requests_updated_at on public.account_deletion_requests;
create trigger trg_account_deletion_requests_updated_at
before update on public.account_deletion_requests
for each row execute function public.set_updated_at();

alter table public.account_deletion_requests enable row level security;

drop policy if exists account_deletion_requests_select_own on public.account_deletion_requests;
create policy account_deletion_requests_select_own
on public.account_deletion_requests for select to authenticated
using (user_id = (select auth.uid()));

create table if not exists public.api_rate_limits (
  user_id uuid not null,
  action text not null,
  window_start timestamptz not null,
  count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, action, window_start)
);

create index if not exists idx_api_rate_limits_updated_at
on public.api_rate_limits (updated_at);

drop trigger if exists trg_api_rate_limits_updated_at on public.api_rate_limits;
create trigger trg_api_rate_limits_updated_at
before update on public.api_rate_limits
for each row execute function public.set_updated_at();

alter table public.api_rate_limits enable row level security;

create or replace function public.consume_api_rate_limit(
  p_user_id uuid,
  p_action text,
  p_window_seconds integer,
  p_max_count integer
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_window_start timestamptz;
  v_count integer;
begin
  if p_user_id is null or p_action is null or p_window_seconds <= 0 or p_max_count <= 0 then
    return false;
  end if;

  v_window_start := to_timestamp(
    floor(extract(epoch from now()) / p_window_seconds) * p_window_seconds
  );

  insert into public.api_rate_limits (user_id, action, window_start, count)
  values (p_user_id, p_action, v_window_start, 1)
  on conflict (user_id, action, window_start)
  do update set count = public.api_rate_limits.count + 1
  returning count into v_count;

  return v_count <= p_max_count;
end;
$$;

revoke all on function public.consume_api_rate_limit(uuid, text, integer, integer) from public;
grant execute on function public.consume_api_rate_limit(uuid, text, integer, integer) to service_role;

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
      status = 'failed',
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

create or replace function public.expired_meal_assets(p_limit integer default 1000)
returns table(id uuid, user_id uuid, storage_bucket text, storage_path text, thumb_storage_path text)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select ma.id, ma.user_id, ma.storage_bucket, ma.storage_path, ma.thumb_storage_path
  from public.meal_assets ma
  where ma.deleted_at is null
    and ma.retention_until is not null
    and ma.retention_until < now()
  order by ma.retention_until
  limit greatest(1, least(coalesce(p_limit, 1000), 10000));
end;
$$;

revoke all on function public.expired_meal_assets(integer) from public;
grant execute on function public.expired_meal_assets(integer) to service_role;

create or replace function public.mark_meal_assets_deleted(p_asset_ids uuid[])
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  update public.meal_assets
  set deleted_at = now()
  where id = any(coalesce(p_asset_ids, '{}'::uuid[]))
    and deleted_at is null;

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function public.mark_meal_assets_deleted(uuid[]) from public;
grant execute on function public.mark_meal_assets_deleted(uuid[]) to service_role;

create or replace function public.users_due_for_weekly_insights(p_week_start date, p_limit integer default 500)
returns table(user_id uuid, timezone text)
language sql
security definer
set search_path = public
as $$
  select p.id, p.timezone
  from public.profiles p
  where exists (
    select 1
    from public.meals m
    where m.user_id = p.id
      and m.deleted_at is null
      and m.logged_at >= p_week_start::timestamptz
      and m.logged_at < (p_week_start + 7)::timestamptz
  )
  order by p.updated_at desc
  limit greatest(1, least(coalesce(p_limit, 500), 5000));
$$;

revoke all on function public.users_due_for_weekly_insights(date, integer) from public;
grant execute on function public.users_due_for_weekly_insights(date, integer) to service_role;
