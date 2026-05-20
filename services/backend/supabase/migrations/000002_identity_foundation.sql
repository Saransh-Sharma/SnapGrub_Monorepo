create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_path text,
  locale text not null default 'en-US',
  timezone text not null,
  unit_system text not null default 'metric'
    check (unit_system in ('metric', 'imperial')),
  country_code text,
  cuisine_preferences text[] not null default '{}',
  cloud_media_storage boolean not null default true,
  save_original_photos boolean not null default false,
  ai_improvement_consent boolean not null default false,
  onboarding_completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create table public.nutrition_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  goal_type text not null
    check (goal_type in ('lose', 'maintain', 'gain', 'custom')),
  calories_kcal numeric(10,2) not null check (calories_kcal between 500 and 6000),
  protein_g numeric(10,2) not null check (protein_g between 0 and 500),
  carbs_g numeric(10,2) not null check (carbs_g between 0 and 800),
  fat_g numeric(10,2) not null check (fat_g between 0 and 400),
  fiber_g numeric(10,2) check (fiber_g is null or fiber_g between 0 and 200),
  starts_on date not null default current_date,
  ends_on date,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_on is null or ends_on >= starts_on)
);

create unique index one_active_goal_per_user
on public.nutrition_goals (user_id)
where is_active;

create index idx_nutrition_goals_user_starts_on
on public.nutrition_goals (user_id, starts_on desc);

create trigger trg_nutrition_goals_updated_at
before update on public.nutrition_goals
for each row execute function public.set_updated_at();

create table public.devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  install_id text not null,
  platform text not null check (platform in ('ios', 'android')),
  app_version text,
  build_number text,
  push_token text,
  last_seen_at timestamptz not null default now(),
  last_sync_cursor text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (install_id)
);

create index idx_devices_user_last_seen
on public.devices (user_id, last_seen_at desc);

create trigger trg_devices_updated_at
before update on public.devices
for each row execute function public.set_updated_at();

create table public.feature_flags (
  key text primary key,
  enabled boolean not null default false,
  rollout_percent integer not null default 100 check (rollout_percent between 0 and 100),
  rules jsonb not null default '{}'::jsonb,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_feature_flags_updated_at
before update on public.feature_flags
for each row execute function public.set_updated_at();

create table public.analytics_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  device_id uuid references public.devices(id) on delete set null,
  event_name text not null,
  properties jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null,
  received_at timestamptz not null default now()
);

create index idx_analytics_events_name_occurred
on public.analytics_events (event_name, occurred_at desc);

create index idx_analytics_events_user_occurred
on public.analytics_events (user_id, occurred_at desc);
