create table public.user_food_defaults (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  food_ref_kind text not null check (food_ref_kind in ('canonical', 'branded', 'custom', 'manual')),
  food_ref_id text not null,
  food_name text not null,
  preferred_quantity numeric(10,2) not null default 1 check (preferred_quantity > 0),
  preferred_unit text not null,
  preferred_grams numeric(10,2),
  calories_kcal numeric(10,2) not null default 0,
  protein_g numeric(10,2) not null default 0,
  carbs_g numeric(10,2) not null default 0,
  fat_g numeric(10,2) not null default 0,
  last_used_at timestamptz not null default now(),
  use_count integer not null default 1 check (use_count > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, food_ref_kind, food_ref_id)
);

create index idx_user_food_defaults_user_last_used
on public.user_food_defaults (user_id, last_used_at desc);

create trigger trg_user_food_defaults_updated_at
before update on public.user_food_defaults
for each row execute function public.set_updated_at();

create table public.weekly_insights (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  week_start date not null,
  insight_type text not null check (
    insight_type in (
      'protein_target_hit_rate',
      'most_repeated_meal',
      'highest_variance_meal_slot',
      'logging_streak',
      'average_intake_vs_target',
      'next_week_suggestion'
    )
  ),
  title text not null,
  summary text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'ready' check (status in ('ready', 'insufficient_data')),
  generated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, week_start, insight_type)
);

create index idx_weekly_insights_user_week
on public.weekly_insights (user_id, week_start desc);

create trigger trg_weekly_insights_updated_at
before update on public.weekly_insights
for each row execute function public.set_updated_at();

alter table public.user_food_defaults enable row level security;
alter table public.weekly_insights enable row level security;

create policy user_food_defaults_select_own
on public.user_food_defaults for select to authenticated
using (user_id = (select auth.uid()));

create policy weekly_insights_select_own
on public.weekly_insights for select to authenticated
using (user_id = (select auth.uid()));

insert into public.feature_flags (key, enabled, rollout_percent, rules, description)
values ('weekly_insights.enabled', false, 0, '{}'::jsonb, 'Show lightweight weekly retention insights.')
on conflict (key) do update set
  enabled = excluded.enabled,
  rollout_percent = excluded.rollout_percent,
  rules = excluded.rules,
  description = excluded.description,
  updated_at = now();

create or replace function public.refresh_user_food_defaults_for_meal(
  p_user_id uuid,
  p_meal_id uuid
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer := 0;
begin
  insert into public.user_food_defaults (
    user_id,
    food_ref_kind,
    food_ref_id,
    food_name,
    preferred_quantity,
    preferred_unit,
    preferred_grams,
    calories_kcal,
    protein_g,
    carbs_g,
    fat_g,
    last_used_at,
    use_count
  )
  select
    m.user_id,
    mi.food_ref_kind,
    coalesce(
      mi.canonical_food_id::text,
      mi.branded_product_id::text,
      mi.custom_food_id::text,
      lower(regexp_replace(mi.name, '\s+', ' ', 'g'))
    ) as food_ref_id,
    mi.name,
    mi.quantity,
    mi.unit,
    mi.grams_estimated,
    mi.calories_kcal,
    mi.protein_g,
    mi.carbs_g,
    mi.fat_g,
    m.logged_at,
    1
  from public.meal_items mi
  join public.meals m on m.id = mi.meal_id
  where m.user_id = p_user_id
    and m.id = p_meal_id
    and m.deleted_at is null
  on conflict (user_id, food_ref_kind, food_ref_id) do update set
    food_name = excluded.food_name,
    preferred_quantity = excluded.preferred_quantity,
    preferred_unit = excluded.preferred_unit,
    preferred_grams = excluded.preferred_grams,
    calories_kcal = excluded.calories_kcal,
    protein_g = excluded.protein_g,
    carbs_g = excluded.carbs_g,
    fat_g = excluded.fat_g,
    last_used_at = greatest(public.user_food_defaults.last_used_at, excluded.last_used_at),
    use_count = public.user_food_defaults.use_count + 1;

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function public.refresh_user_food_defaults_for_meal(uuid, uuid) from public, anon, authenticated;
grant execute on function public.refresh_user_food_defaults_for_meal(uuid, uuid) to service_role;
