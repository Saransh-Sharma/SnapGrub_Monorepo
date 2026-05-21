drop policy if exists daily_rollups_insert_own on public.daily_rollups;
drop policy if exists daily_rollups_update_own on public.daily_rollups;
drop policy if exists daily_rollups_delete_own on public.daily_rollups;

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
    raise exception 'expected revision mismatch' using errcode = '40001';
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
  v_existing public.meals%rowtype;
  v_meal public.meals%rowtype;
  v_rollup public.daily_rollups%rowtype;
  v_day date;
  v_items jsonb;
  v_event public.correction_events%rowtype;
begin
  select * into v_existing
  from public.meals
  where id = p_meal_id and user_id = p_user_id;

  if v_existing.id is null then
    raise exception 'meal not found' using errcode = '02000';
  end if;
  if p_expected_revision is not null and v_existing.revision <> p_expected_revision then
    raise exception 'expected revision mismatch' using errcode = '40001';
  end if;

  update public.meals
  set deleted_at = now(), revision = revision + 1
  where id = p_meal_id and user_id = p_user_id
  returning * into v_meal;

  insert into public.correction_events (user_id, meal_id, analysis_job_id, event_type, before_value, after_value)
  values (p_user_id, v_meal.id, v_meal.analysis_job_id, 'meal_deleted', to_jsonb(v_existing), to_jsonb(v_meal))
  returning * into v_event;

  v_day := public.meal_rollup_day(v_meal.logged_at, v_meal.timezone);
  v_rollup := public.refresh_daily_rollup(p_user_id, v_day);

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
revoke all on function public.delete_user_meal(uuid, uuid, integer) from public, anon, authenticated;
grant execute on function public.upsert_user_meal(uuid, uuid, jsonb, jsonb, integer) to service_role;
grant execute on function public.delete_user_meal(uuid, uuid, integer) to service_role;
