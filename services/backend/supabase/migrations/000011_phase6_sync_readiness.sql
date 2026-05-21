create table public.pending_uploads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  asset_id uuid references public.meal_assets(id) on delete cascade,
  storage_bucket text not null,
  storage_path text not null,
  thumb_storage_path text,
  sha256 text,
  mime_type text not null default 'image/jpeg',
  status text not null default 'pending' check (status in ('pending', 'uploading', 'uploaded', 'failed')),
  retry_count integer not null default 0,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  uploaded_at timestamptz,
  unique (user_id, storage_bucket, storage_path)
);

create index idx_pending_uploads_user_status
on public.pending_uploads (user_id, status, created_at);

create trigger trg_pending_uploads_updated_at
before update on public.pending_uploads
for each row execute function public.set_updated_at();

alter table public.pending_uploads enable row level security;

create policy pending_uploads_select_own
on public.pending_uploads for select to authenticated
using (user_id = (select auth.uid()));

create table public.export_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  client_request_id text not null,
  export_type text not null default 'journal_csv' check (export_type in ('journal_csv', 'nutrition_json')),
  status text not null default 'queued' check (status in ('queued', 'processing', 'completed', 'failed')),
  filters jsonb not null default '{}'::jsonb,
  result_storage_path text,
  error_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (user_id, client_request_id)
);

create index idx_export_requests_user_created_at
on public.export_requests (user_id, created_at desc);

create trigger trg_export_requests_updated_at
before update on public.export_requests
for each row execute function public.set_updated_at();

alter table public.export_requests enable row level security;

create policy export_requests_select_own
on public.export_requests for select to authenticated
using (user_id = (select auth.uid()));

drop policy if exists daily_rollups_insert_own on public.daily_rollups;
drop policy if exists daily_rollups_update_own on public.daily_rollups;
drop policy if exists daily_rollups_delete_own on public.daily_rollups;
drop policy if exists custom_foods_insert_own on public.custom_foods;
drop policy if exists custom_foods_update_own on public.custom_foods;
drop policy if exists custom_foods_delete_own on public.custom_foods;
drop policy if exists meal_templates_insert_own on public.meal_templates;
drop policy if exists meal_templates_update_own on public.meal_templates;
drop policy if exists meal_templates_delete_own on public.meal_templates;
drop policy if exists body_measurements_insert_own on public.body_measurements;
drop policy if exists body_measurements_update_own on public.body_measurements;
drop policy if exists body_measurements_delete_own on public.body_measurements;

create or replace function public.purge_expired_api_idempotency(p_limit integer default 1000)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_deleted integer;
begin
  delete from public.api_idempotency
  where id in (
    select id
    from public.api_idempotency
    where expires_at < now()
    order by expires_at
    limit greatest(1, least(coalesce(p_limit, 1000), 10000))
  );

  get diagnostics v_deleted = row_count;
  return v_deleted;
end;
$$;

revoke all on function public.purge_expired_api_idempotency(integer) from public;
grant execute on function public.purge_expired_api_idempotency(integer) to service_role;
