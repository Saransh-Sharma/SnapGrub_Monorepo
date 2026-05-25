create table public.meal_assets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_bucket text not null,
  storage_path text not null,
  thumb_storage_path text,
  sha256 text not null,
  mime_type text not null,
  width integer,
  height integer,
  size_bytes bigint,
  retention_until timestamptz,
  created_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (storage_bucket, storage_path)
);

create index idx_meal_assets_user_created_at
on public.meal_assets (user_id, created_at desc);

create index idx_meal_assets_retention
on public.meal_assets (retention_until)
where deleted_at is null;

create table public.analysis_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  client_request_id text not null,
  analysis_mode text not null check (analysis_mode in ('photo', 'text', 'barcode')),
  status text not null check (status in ('queued', 'processing', 'completed', 'failed')),
  asset_id uuid references public.meal_assets(id) on delete set null,
  input_payload jsonb not null default '{}'::jsonb,
  provider text,
  model_name text,
  latency_ms integer,
  error_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (user_id, client_request_id)
);

create index idx_analysis_jobs_status_created_at
on public.analysis_jobs (status, created_at);

create index idx_analysis_jobs_user_created_at
on public.analysis_jobs (user_id, created_at desc);

create trigger trg_analysis_jobs_updated_at
before update on public.analysis_jobs
for each row execute function public.set_updated_at();

create table public.analysis_revisions (
  id uuid primary key default gen_random_uuid(),
  analysis_job_id uuid not null references public.analysis_jobs(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  revision_no integer not null,
  title text,
  meal_type text,
  calories_kcal numeric(10,2) not null default 0,
  protein_g numeric(10,2) not null default 0,
  carbs_g numeric(10,2) not null default 0,
  fat_g numeric(10,2) not null default 0,
  confidence_overall numeric(4,3),
  confidence_breakdown jsonb not null default '{}'::jsonb,
  warnings text[] not null default '{}',
  provenance jsonb not null default '{}'::jsonb,
  result_payload jsonb not null,
  created_at timestamptz not null default now(),
  unique (analysis_job_id, revision_no)
);

create index idx_analysis_revisions_job_revision
on public.analysis_revisions (analysis_job_id, revision_no desc);

create table public.analysis_candidates (
  id uuid primary key default gen_random_uuid(),
  analysis_revision_id uuid not null references public.analysis_revisions(id) on delete cascade,
  rank integer not null,
  candidate_title text,
  confidence numeric(4,3),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (analysis_revision_id, rank)
);

create table public.model_invocations (
  id uuid primary key default gen_random_uuid(),
  analysis_job_id uuid references public.analysis_jobs(id) on delete set null,
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null,
  model_name text not null,
  purpose text not null default 'photo_analysis',
  status text not null check (status in ('started', 'completed', 'failed')),
  latency_ms integer,
  input_tokens integer,
  output_tokens integer,
  estimated_cost_usd numeric(12,6),
  error_code text,
  request_payload jsonb not null default '{}'::jsonb,
  response_payload jsonb,
  created_at timestamptz not null default now()
);

create index idx_model_invocations_user_created_at
on public.model_invocations (user_id, created_at desc);

create index idx_model_invocations_job_created_at
on public.model_invocations (analysis_job_id, created_at desc);

alter table public.meals
  add constraint meals_analysis_job_id_fkey
  foreign key (analysis_job_id) references public.analysis_jobs(id) on delete set null;

alter table public.meals
  add constraint meals_photo_asset_id_fkey
  foreign key (photo_asset_id) references public.meal_assets(id) on delete set null;

alter table public.meal_assets enable row level security;
alter table public.analysis_jobs enable row level security;
alter table public.analysis_revisions enable row level security;
alter table public.analysis_candidates enable row level security;
alter table public.model_invocations enable row level security;

create policy meal_assets_select_own on public.meal_assets for select to authenticated
using (user_id = (select auth.uid()));
create policy meal_assets_insert_own on public.meal_assets for insert to authenticated
with check (user_id = (select auth.uid()));
create policy meal_assets_update_own on public.meal_assets for update to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy analysis_jobs_select_own on public.analysis_jobs for select to authenticated
using (user_id = (select auth.uid()));

create policy analysis_revisions_select_own on public.analysis_revisions for select to authenticated
using (user_id = (select auth.uid()));

create policy analysis_candidates_select_own on public.analysis_candidates for select to authenticated
using (
  exists (
    select 1
    from public.analysis_revisions ar
    where ar.id = analysis_candidates.analysis_revision_id
      and ar.user_id = (select auth.uid())
  )
);

create policy model_invocations_select_own on public.model_invocations for select to authenticated
using (user_id = (select auth.uid()));

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
  v_event public.correction_events%rowtype;
  v_event_type text;
  v_source text;
  v_analysis_job_id uuid;
  v_photo_asset_id uuid;
begin
  if p_user_id is null then
    raise exception 'user_id is required' using errcode = '22023';
  end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'items must contain at least one item' using errcode = '22023';
  end if;

  v_source := coalesce(p_meal->>'source', '');
  if v_source not in ('manual', 'duplicate', 'photo') then
    raise exception 'source is not enabled in this phase' using errcode = '22023';
  end if;

  v_analysis_job_id := nullif(p_meal->>'analysis_job_id', '')::uuid;
  v_photo_asset_id := nullif(p_meal->>'photo_asset_id', '')::uuid;

  if v_source = 'photo' then
    if v_analysis_job_id is null or v_photo_asset_id is null then
      raise exception 'photo meals require analysis_job_id and photo_asset_id' using errcode = '22023';
    end if;
    if not exists (
      select 1
      from public.analysis_jobs aj
      join public.meal_assets ma on ma.id = aj.asset_id
      where aj.id = v_analysis_job_id
        and aj.user_id = p_user_id
        and aj.asset_id = v_photo_asset_id
        and ma.user_id = p_user_id
        and aj.status = 'completed'
    ) then
      raise exception 'analysis_job_id and photo_asset_id are invalid for this user' using errcode = '22023';
    end if;
  elsif v_analysis_job_id is not null or v_photo_asset_id is not null then
    raise exception 'analysis_job_id and photo_asset_id are only valid for photo meals' using errcode = '22023';
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
      analysis_job_id,
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
      provenance_type,
      photo_asset_id
    )
    values (
      coalesce(p_meal_id, gen_random_uuid()),
      p_user_id,
      p_meal->>'client_id',
      v_analysis_job_id,
      nullif(p_meal->>'title', ''),
      p_meal->>'meal_type',
      v_source,
      (p_meal->>'logged_at')::timestamptz,
      p_meal->>'timezone',
      0,
      0,
      0,
      0,
      nullif(p_meal->>'confidence_overall', '')::numeric,
      nullif(p_meal->>'provenance_type', ''),
      v_photo_asset_id
    )
    returning * into v_meal;
    v_event_type := 'meal_created';
  else
    v_old_day := public.meal_rollup_day(v_existing.logged_at, v_existing.timezone);
    update public.meals
    set
      analysis_job_id = v_analysis_job_id,
      title = nullif(p_meal->>'title', ''),
      meal_type = p_meal->>'meal_type',
      source = v_source,
      logged_at = (p_meal->>'logged_at')::timestamptz,
      timezone = p_meal->>'timezone',
      confidence_overall = nullif(p_meal->>'confidence_overall', '')::numeric,
      provenance_type = nullif(p_meal->>'provenance_type', ''),
      photo_asset_id = v_photo_asset_id,
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

  insert into public.correction_events (user_id, meal_id, analysis_job_id, event_type, before_value, after_value)
  values (
    p_user_id,
    v_meal.id,
    v_meal.analysis_job_id,
    v_event_type,
    case when v_existing.id is null then null else to_jsonb(v_existing) end,
    to_jsonb(v_meal)
  )
  returning * into v_event;

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
    'daily_rollup', to_jsonb(v_rollup),
    'correction_events', jsonb_build_array(to_jsonb(v_event))
  );
end;
$$;

revoke all on function public.upsert_user_meal(uuid, uuid, jsonb, jsonb, integer) from public, anon, authenticated;
grant execute on function public.upsert_user_meal(uuid, uuid, jsonb, jsonb, integer) to service_role;
