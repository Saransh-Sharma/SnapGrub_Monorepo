create table public.body_measurements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  measured_at timestamptz not null default now(),
  weight_kg numeric(8,3) check (weight_kg is null or weight_kg between 20 and 400),
  body_fat_pct numeric(5,2) check (body_fat_pct is null or body_fat_pct between 2 and 80),
  source text not null default 'manual' check (source in ('manual', 'onboarding', 'imported')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_body_measurements_user_measured_at
on public.body_measurements (user_id, measured_at desc);

create trigger trg_body_measurements_updated_at
before update on public.body_measurements
for each row execute function public.set_updated_at();

create table public.feature_flag_overrides (
  id uuid primary key default gen_random_uuid(),
  flag_key text not null references public.feature_flags(key) on delete cascade,
  scope_type text not null check (scope_type in ('user', 'device', 'email', 'build_env')),
  scope_id text not null,
  forced_value jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (flag_key, scope_type, scope_id)
);

create trigger trg_feature_flag_overrides_updated_at
before update on public.feature_flag_overrides
for each row execute function public.set_updated_at();

alter table public.body_measurements enable row level security;
alter table public.feature_flag_overrides enable row level security;

create policy body_measurements_select_own
on public.body_measurements for select to authenticated
using (user_id = (select auth.uid()));

create policy body_measurements_insert_own
on public.body_measurements for insert to authenticated
with check (user_id = (select auth.uid()));

create policy body_measurements_update_own
on public.body_measurements for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy body_measurements_delete_own
on public.body_measurements for delete to authenticated
using (user_id = (select auth.uid()));

-- No client policies for feature_flag_overrides. Edge Functions resolve overrides server-side.
