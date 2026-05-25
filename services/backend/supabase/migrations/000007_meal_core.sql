create table public.custom_foods (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  client_id text not null,
  name text not null,
  brand text,
  serving_quantity numeric(10,2),
  serving_unit text,
  serving_grams numeric(10,2),
  calories_kcal numeric(10,2) not null default 0,
  protein_g numeric(10,2) not null default 0,
  carbs_g numeric(10,2) not null default 0,
  fat_g numeric(10,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (user_id, client_id)
);

create trigger trg_custom_foods_updated_at
before update on public.custom_foods
for each row execute function public.set_updated_at();

create table public.meals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  client_id text not null,
  analysis_job_id uuid,
  title text not null,
  meal_type text not null
    check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack', 'unknown')),
  source text not null
    check (source in ('photo', 'barcode', 'text', 'voice', 'manual', 'duplicate')),
  logged_at timestamptz not null,
  timezone text not null,
  calories_kcal numeric(10,2) not null default 0,
  protein_g numeric(10,2) not null default 0,
  carbs_g numeric(10,2) not null default 0,
  fat_g numeric(10,2) not null default 0,
  confidence_overall numeric(4,3),
  provenance_type text,
  photo_asset_id uuid,
  revision integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (user_id, client_id)
);

create index idx_meals_user_logged_at_active
on public.meals (user_id, logged_at desc)
where deleted_at is null;

create index idx_meals_user_updated_at
on public.meals (user_id, updated_at desc);

create trigger trg_meals_updated_at
before update on public.meals
for each row execute function public.set_updated_at();

create table public.meal_items (
  id uuid primary key default gen_random_uuid(),
  meal_id uuid not null references public.meals(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  client_id text not null,
  position integer not null,
  name text not null,
  food_ref_kind text not null default 'manual'
    check (food_ref_kind in ('canonical', 'branded', 'custom', 'manual')),
  canonical_food_id uuid,
  branded_product_id uuid,
  custom_food_id uuid references public.custom_foods(id),
  quantity numeric(10,2) not null check (quantity > 0),
  unit text not null,
  grams_estimated numeric(10,2),
  calories_kcal numeric(10,2) not null default 0 check (calories_kcal >= 0),
  protein_g numeric(10,2) not null default 0 check (protein_g >= 0),
  carbs_g numeric(10,2) not null default 0 check (carbs_g >= 0),
  fat_g numeric(10,2) not null default 0 check (fat_g >= 0),
  confidence numeric(4,3),
  source_type text,
  source_id text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (num_nonnulls(canonical_food_id, branded_product_id, custom_food_id) <= 1),
  unique (meal_id, client_id)
);

create index idx_meal_items_meal_position
on public.meal_items (meal_id, position);

create index idx_meal_items_user_created_at
on public.meal_items (user_id, created_at desc);

create trigger trg_meal_items_updated_at
before update on public.meal_items
for each row execute function public.set_updated_at();

create table public.meal_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  client_id text not null,
  title text not null,
  snapshot jsonb not null,
  source_meal_id uuid references public.meals(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (user_id, client_id)
);

create index idx_meal_templates_user_updated_at
on public.meal_templates (user_id, updated_at desc)
where deleted_at is null;

create trigger trg_meal_templates_updated_at
before update on public.meal_templates
for each row execute function public.set_updated_at();

create table public.daily_rollups (
  user_id uuid not null references auth.users(id) on delete cascade,
  day date not null,
  calories_kcal numeric(10,2) not null default 0,
  protein_g numeric(10,2) not null default 0,
  carbs_g numeric(10,2) not null default 0,
  fat_g numeric(10,2) not null default 0,
  meal_count integer not null default 0,
  has_photo_meal boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, day)
);

create table public.correction_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  meal_id uuid references public.meals(id) on delete set null,
  analysis_job_id uuid,
  event_type text not null,
  field_name text,
  before_value jsonb,
  after_value jsonb,
  reason text,
  created_at timestamptz not null default now()
);

create index idx_correction_events_user_created_at
on public.correction_events (user_id, created_at desc);

create index idx_correction_events_meal_created_at
on public.correction_events (meal_id, created_at desc);

alter table public.custom_foods enable row level security;
alter table public.meals enable row level security;
alter table public.meal_items enable row level security;
alter table public.meal_templates enable row level security;
alter table public.daily_rollups enable row level security;
alter table public.correction_events enable row level security;

create policy custom_foods_select_own on public.custom_foods for select to authenticated
using (user_id = (select auth.uid()));
create policy custom_foods_insert_own on public.custom_foods for insert to authenticated
with check (user_id = (select auth.uid()));
create policy custom_foods_update_own on public.custom_foods for update to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy custom_foods_delete_own on public.custom_foods for delete to authenticated
using (user_id = (select auth.uid()));

create policy meals_select_own on public.meals for select to authenticated
using (user_id = (select auth.uid()));
create policy meals_insert_own on public.meals for insert to authenticated
with check (user_id = (select auth.uid()));
create policy meals_update_own on public.meals for update to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy meals_delete_own on public.meals for delete to authenticated
using (user_id = (select auth.uid()));

create policy meal_items_select_own on public.meal_items for select to authenticated
using (user_id = (select auth.uid()));
create policy meal_items_insert_own on public.meal_items for insert to authenticated
with check (user_id = (select auth.uid()));
create policy meal_items_update_own on public.meal_items for update to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy meal_items_delete_own on public.meal_items for delete to authenticated
using (user_id = (select auth.uid()));

create policy meal_templates_select_own on public.meal_templates for select to authenticated
using (user_id = (select auth.uid()));
create policy meal_templates_insert_own on public.meal_templates for insert to authenticated
with check (user_id = (select auth.uid()));
create policy meal_templates_update_own on public.meal_templates for update to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy meal_templates_delete_own on public.meal_templates for delete to authenticated
using (user_id = (select auth.uid()));

create policy daily_rollups_select_own on public.daily_rollups for select to authenticated
using (user_id = (select auth.uid()));
create policy daily_rollups_insert_own on public.daily_rollups for insert to authenticated
with check (user_id = (select auth.uid()));
create policy daily_rollups_update_own on public.daily_rollups for update to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy daily_rollups_delete_own on public.daily_rollups for delete to authenticated
using (user_id = (select auth.uid()));

create policy correction_events_select_own on public.correction_events for select to authenticated
using (user_id = (select auth.uid()));
create policy correction_events_insert_own on public.correction_events for insert to authenticated
with check (user_id = (select auth.uid()));

create or replace function public.meal_rollup_day(p_logged_at timestamptz, p_timezone text)
returns date
language sql
immutable
as $$
  select (p_logged_at at time zone coalesce(nullif(p_timezone, ''), 'UTC'))::date
$$;

create or replace function public.refresh_daily_rollup(p_user_id uuid, p_day date)
returns public.daily_rollups
language plpgsql
security definer
set search_path = public
as $$
declare
  v_rollup public.daily_rollups%rowtype;
begin
  insert into public.daily_rollups (
    user_id,
    day,
    calories_kcal,
    protein_g,
    carbs_g,
    fat_g,
    meal_count,
    has_photo_meal,
    updated_at
  )
  select
    p_user_id,
    p_day,
    coalesce(sum(m.calories_kcal), 0),
    coalesce(sum(m.protein_g), 0),
    coalesce(sum(m.carbs_g), 0),
    coalesce(sum(m.fat_g), 0),
    count(m.id)::integer,
    coalesce(bool_or(m.source = 'photo'), false),
    now()
  from public.meals m
  where m.user_id = p_user_id
    and m.deleted_at is null
    and public.meal_rollup_day(m.logged_at, m.timezone) = p_day
  on conflict (user_id, day) do update set
    calories_kcal = excluded.calories_kcal,
    protein_g = excluded.protein_g,
    carbs_g = excluded.carbs_g,
    fat_g = excluded.fat_g,
    meal_count = excluded.meal_count,
    has_photo_meal = excluded.has_photo_meal,
    updated_at = now()
  returning * into v_rollup;

  return v_rollup;
end;
$$;

create or replace function public.upsert_user_meal(
  p_user_id uuid,
  p_meal_id uuid,
  p_meal jsonb,
  p_items jsonb,
  p_expected_revision integer default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_existing public.meals%rowtype;
  v_meal public.meals%rowtype;
  v_rollup public.daily_rollups%rowtype;
  v_old_day date;
  v_new_day date;
  v_item jsonb;
  v_items jsonb;
  v_event_type text;
begin
  if p_user_id is null then
    raise exception 'user_id is required' using errcode = '22023';
  end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'items must contain at least one item' using errcode = '22023';
  end if;
  if coalesce(p_meal->>'source', '') <> 'manual' and coalesce(p_meal->>'source', '') <> 'duplicate' then
    raise exception 'only manual and duplicate sources are enabled in Phase 3' using errcode = '22023';
  end if;
  if nullif(p_meal->>'analysis_job_id', '') is not null or nullif(p_meal->>'photo_asset_id', '') is not null then
    raise exception 'analysis_job_id and photo_asset_id are not enabled in Phase 3' using errcode = '22023';
  end if;

  if p_meal_id is not null then
    select * into v_existing
    from public.meals
    where id = p_meal_id and user_id = p_user_id;
  else
    select * into v_existing
    from public.meals
    where user_id = p_user_id and client_id = p_meal->>'client_id';
  end if;

  if v_existing.id is not null and p_expected_revision is not null and v_existing.revision <> p_expected_revision then
    raise exception 'expected revision mismatch' using errcode = 'P0001';
  end if;

  if v_existing.id is null then
    insert into public.meals (
      id,
      user_id,
      client_id,
      title,
      meal_type,
      source,
      logged_at,
      timezone,
      calories_kcal,
      protein_g,
      carbs_g,
      fat_g,
      confidence_overall,
      provenance_type
    )
    values (
      coalesce(p_meal_id, gen_random_uuid()),
      p_user_id,
      p_meal->>'client_id',
      nullif(p_meal->>'title', ''),
      p_meal->>'meal_type',
      p_meal->>'source',
      (p_meal->>'logged_at')::timestamptz,
      p_meal->>'timezone',
      0,
      0,
      0,
      0,
      nullif(p_meal->>'confidence_overall', '')::numeric,
      nullif(p_meal->>'provenance_type', '')
    )
    returning * into v_meal;
    v_event_type := 'meal_created';
  else
    v_old_day := public.meal_rollup_day(v_existing.logged_at, v_existing.timezone);
    update public.meals
    set
      title = nullif(p_meal->>'title', ''),
      meal_type = p_meal->>'meal_type',
      source = p_meal->>'source',
      logged_at = (p_meal->>'logged_at')::timestamptz,
      timezone = p_meal->>'timezone',
      confidence_overall = nullif(p_meal->>'confidence_overall', '')::numeric,
      provenance_type = nullif(p_meal->>'provenance_type', ''),
      revision = revision + 1,
      deleted_at = null
    where id = v_existing.id and user_id = p_user_id
    returning * into v_meal;
    delete from public.meal_items where meal_id = v_meal.id and user_id = p_user_id;
    v_event_type := 'meal_updated';
  end if;

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    insert into public.meal_items (
      meal_id,
      user_id,
      client_id,
      position,
      name,
      food_ref_kind,
      canonical_food_id,
      branded_product_id,
      custom_food_id,
      quantity,
      unit,
      grams_estimated,
      calories_kcal,
      protein_g,
      carbs_g,
      fat_g,
      confidence,
      source_type,
      source_id,
      notes
    )
    values (
      v_meal.id,
      p_user_id,
      v_item->>'client_id',
      coalesce((v_item->>'position')::integer, 0),
      nullif(v_item->>'name', ''),
      coalesce(nullif(v_item->>'food_ref_kind', ''), 'manual'),
      nullif(v_item->>'canonical_food_id', '')::uuid,
      nullif(v_item->>'branded_product_id', '')::uuid,
      nullif(v_item->>'custom_food_id', '')::uuid,
      (v_item->>'quantity')::numeric,
      v_item->>'unit',
      nullif(v_item->>'grams_estimated', '')::numeric,
      (v_item->>'calories_kcal')::numeric,
      (v_item->>'protein_g')::numeric,
      (v_item->>'carbs_g')::numeric,
      (v_item->>'fat_g')::numeric,
      nullif(v_item->>'confidence', '')::numeric,
      nullif(v_item->>'source_type', ''),
      nullif(v_item->>'source_id', ''),
      nullif(v_item->>'notes', '')
    );
  end loop;

  update public.meals
  set
    calories_kcal = totals.calories_kcal,
    protein_g = totals.protein_g,
    carbs_g = totals.carbs_g,
    fat_g = totals.fat_g
  from (
    select
      coalesce(sum(calories_kcal), 0) as calories_kcal,
      coalesce(sum(protein_g), 0) as protein_g,
      coalesce(sum(carbs_g), 0) as carbs_g,
      coalesce(sum(fat_g), 0) as fat_g
    from public.meal_items
    where meal_id = v_meal.id and user_id = p_user_id
  ) totals
  where meals.id = v_meal.id
  returning meals.* into v_meal;

  insert into public.correction_events (user_id, meal_id, analysis_job_id, event_type, after_value)
  values (p_user_id, v_meal.id, v_meal.analysis_job_id, v_event_type, to_jsonb(v_meal));

  v_new_day := public.meal_rollup_day(v_meal.logged_at, v_meal.timezone);
  if v_old_day is not null and v_old_day <> v_new_day then
    perform public.refresh_daily_rollup(p_user_id, v_old_day);
  end if;
  v_rollup := public.refresh_daily_rollup(p_user_id, v_new_day);

  select coalesce(jsonb_agg(to_jsonb(mi) order by mi.position), '[]'::jsonb)
  into v_items
  from public.meal_items mi
  where mi.meal_id = v_meal.id;

  return jsonb_build_object(
    'meal', to_jsonb(v_meal) || jsonb_build_object('items', v_items),
    'daily_rollup', to_jsonb(v_rollup)
  );
end;
$$;

create or replace function public.delete_user_meal(
  p_user_id uuid,
  p_meal_id uuid,
  p_expected_revision integer default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_meal public.meals%rowtype;
  v_rollup public.daily_rollups%rowtype;
  v_day date;
  v_items jsonb;
begin
  select * into v_meal
  from public.meals
  where id = p_meal_id and user_id = p_user_id;

  if v_meal.id is null then
    raise exception 'meal not found' using errcode = '02000';
  end if;
  if p_expected_revision is not null and v_meal.revision <> p_expected_revision then
    raise exception 'expected revision mismatch' using errcode = 'P0001';
  end if;

  update public.meals
  set deleted_at = now(), revision = revision + 1
  where id = p_meal_id and user_id = p_user_id
  returning * into v_meal;

  insert into public.correction_events (user_id, meal_id, analysis_job_id, event_type, before_value)
  values (p_user_id, v_meal.id, v_meal.analysis_job_id, 'meal_deleted', to_jsonb(v_meal));

  v_day := public.meal_rollup_day(v_meal.logged_at, v_meal.timezone);
  v_rollup := public.refresh_daily_rollup(p_user_id, v_day);

  select coalesce(jsonb_agg(to_jsonb(mi) order by mi.position), '[]'::jsonb)
  into v_items
  from public.meal_items mi
  where mi.meal_id = v_meal.id;

  return jsonb_build_object(
    'meal', to_jsonb(v_meal) || jsonb_build_object('items', v_items),
    'daily_rollup', to_jsonb(v_rollup)
  );
end;
$$;

revoke all on function public.refresh_daily_rollup(uuid, date) from public, anon, authenticated;
revoke all on function public.upsert_user_meal(uuid, uuid, jsonb, jsonb, integer) from public, anon, authenticated;
revoke all on function public.delete_user_meal(uuid, uuid, integer) from public, anon, authenticated;
grant execute on function public.refresh_daily_rollup(uuid, date) to service_role;
grant execute on function public.upsert_user_meal(uuid, uuid, jsonb, jsonb, integer) to service_role;
grant execute on function public.delete_user_meal(uuid, uuid, integer) to service_role;
