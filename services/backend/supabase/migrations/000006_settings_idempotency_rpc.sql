create table public.api_idempotency (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  endpoint text not null,
  key text not null,
  request_hash text not null,
  response_status integer,
  response_body jsonb,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours'),
  unique (user_id, endpoint, key)
);

create index idx_api_idempotency_expires_at
on public.api_idempotency (expires_at);

alter table public.api_idempotency enable row level security;

create or replace function public.patch_user_settings(
  p_user_id uuid,
  p_profile_patch jsonb default '{}'::jsonb,
  p_active_goal_patch jsonb default null,
  p_body_measurement jsonb default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile public.profiles%rowtype;
  v_active_goal public.nutrition_goals%rowtype;
  v_measurement public.body_measurements%rowtype;
  v_existing_goal_id uuid;
  v_cuisine_value jsonb;
begin
  if p_user_id is null then
    raise exception 'user_id is required' using errcode = '22023';
  end if;

  p_profile_patch := coalesce(p_profile_patch, '{}'::jsonb);

  if p_profile_patch ? 'unit_system'
    and p_profile_patch->>'unit_system' not in ('metric', 'imperial') then
    raise exception 'unit_system is invalid' using errcode = '22023';
  end if;

  if p_profile_patch ? 'cuisine_preferences' then
    if jsonb_typeof(p_profile_patch->'cuisine_preferences') <> 'array' then
      raise exception 'cuisine_preferences must be an array' using errcode = '22023';
    end if;
    for v_cuisine_value in select value from jsonb_array_elements(p_profile_patch->'cuisine_preferences')
    loop
      if jsonb_typeof(v_cuisine_value) <> 'string' then
        raise exception 'cuisine_preferences must contain strings' using errcode = '22023';
      end if;
    end loop;
  end if;

  insert into public.profiles (
    id,
    display_name,
    locale,
    timezone,
    unit_system,
    country_code,
    cuisine_preferences,
    cloud_media_storage,
    save_original_photos,
    ai_improvement_consent,
    onboarding_completed_at
  )
  values (
    p_user_id,
    nullif(p_profile_patch->>'display_name', ''),
    coalesce(nullif(p_profile_patch->>'locale', ''), 'en-US'),
    coalesce(nullif(p_profile_patch->>'timezone', ''), 'UTC'),
    coalesce(nullif(p_profile_patch->>'unit_system', ''), 'metric'),
    nullif(p_profile_patch->>'country_code', ''),
    case
      when p_profile_patch ? 'cuisine_preferences'
        then array(select jsonb_array_elements_text(p_profile_patch->'cuisine_preferences'))
      else '{}'
    end,
    coalesce((p_profile_patch->>'cloud_media_storage')::boolean, true),
    coalesce((p_profile_patch->>'save_original_photos')::boolean, false),
    coalesce((p_profile_patch->>'ai_improvement_consent')::boolean, false),
    (p_profile_patch->>'onboarding_completed_at')::timestamptz
  )
  on conflict (id) do update set
    display_name = case when p_profile_patch ? 'display_name' then nullif(p_profile_patch->>'display_name', '') else profiles.display_name end,
    avatar_path = case when p_profile_patch ? 'avatar_path' then nullif(p_profile_patch->>'avatar_path', '') else profiles.avatar_path end,
    locale = case when p_profile_patch ? 'locale' then nullif(p_profile_patch->>'locale', '') else profiles.locale end,
    timezone = case when p_profile_patch ? 'timezone' then nullif(p_profile_patch->>'timezone', '') else profiles.timezone end,
    unit_system = case when p_profile_patch ? 'unit_system' then p_profile_patch->>'unit_system' else profiles.unit_system end,
    country_code = case when p_profile_patch ? 'country_code' then nullif(p_profile_patch->>'country_code', '') else profiles.country_code end,
    cuisine_preferences = case
      when p_profile_patch ? 'cuisine_preferences'
        then array(select jsonb_array_elements_text(p_profile_patch->'cuisine_preferences'))
      else profiles.cuisine_preferences
    end,
    cloud_media_storage = case when p_profile_patch ? 'cloud_media_storage' then (p_profile_patch->>'cloud_media_storage')::boolean else profiles.cloud_media_storage end,
    save_original_photos = case when p_profile_patch ? 'save_original_photos' then (p_profile_patch->>'save_original_photos')::boolean else profiles.save_original_photos end,
    ai_improvement_consent = case when p_profile_patch ? 'ai_improvement_consent' then (p_profile_patch->>'ai_improvement_consent')::boolean else profiles.ai_improvement_consent end,
    onboarding_completed_at = case when p_profile_patch ? 'onboarding_completed_at' then (p_profile_patch->>'onboarding_completed_at')::timestamptz else profiles.onboarding_completed_at end
  returning * into v_profile;

  if p_active_goal_patch is not null and p_active_goal_patch <> '{}'::jsonb then
    if not (
      p_active_goal_patch ? 'goal_type'
      and p_active_goal_patch ? 'calories_kcal'
      and p_active_goal_patch ? 'protein_g'
      and p_active_goal_patch ? 'carbs_g'
      and p_active_goal_patch ? 'fat_g'
    ) then
      raise exception 'active_goal_patch is incomplete' using errcode = '22023';
    end if;

    if p_active_goal_patch->>'goal_type' not in ('lose', 'maintain', 'gain', 'custom') then
      raise exception 'goal_type is invalid' using errcode = '22023';
    end if;
    if (p_active_goal_patch->>'calories_kcal')::numeric not between 500 and 6000 then
      raise exception 'calories_kcal is out of range' using errcode = '22023';
    end if;
    if (p_active_goal_patch->>'protein_g')::numeric not between 0 and 500 then
      raise exception 'protein_g is out of range' using errcode = '22023';
    end if;
    if (p_active_goal_patch->>'carbs_g')::numeric not between 0 and 800 then
      raise exception 'carbs_g is out of range' using errcode = '22023';
    end if;
    if (p_active_goal_patch->>'fat_g')::numeric not between 0 and 400 then
      raise exception 'fat_g is out of range' using errcode = '22023';
    end if;
    if p_active_goal_patch ? 'fiber_g'
      and p_active_goal_patch->>'fiber_g' is not null
      and (p_active_goal_patch->>'fiber_g')::numeric not between 0 and 200 then
      raise exception 'fiber_g is out of range' using errcode = '22023';
    end if;

    select id into v_existing_goal_id
    from public.nutrition_goals
    where user_id = p_user_id and is_active
    limit 1;

    if v_existing_goal_id is null then
      insert into public.nutrition_goals (
        user_id,
        goal_type,
        calories_kcal,
        protein_g,
        carbs_g,
        fat_g,
        fiber_g,
        starts_on,
        ends_on,
        is_active
      )
      values (
        p_user_id,
        p_active_goal_patch->>'goal_type',
        (p_active_goal_patch->>'calories_kcal')::numeric,
        (p_active_goal_patch->>'protein_g')::numeric,
        (p_active_goal_patch->>'carbs_g')::numeric,
        (p_active_goal_patch->>'fat_g')::numeric,
        nullif(p_active_goal_patch->>'fiber_g', '')::numeric,
        coalesce((p_active_goal_patch->>'starts_on')::date, current_date),
        nullif(p_active_goal_patch->>'ends_on', '')::date,
        true
      )
      returning * into v_active_goal;
    else
      update public.nutrition_goals
      set
        goal_type = p_active_goal_patch->>'goal_type',
        calories_kcal = (p_active_goal_patch->>'calories_kcal')::numeric,
        protein_g = (p_active_goal_patch->>'protein_g')::numeric,
        carbs_g = (p_active_goal_patch->>'carbs_g')::numeric,
        fat_g = (p_active_goal_patch->>'fat_g')::numeric,
        fiber_g = nullif(p_active_goal_patch->>'fiber_g', '')::numeric,
        starts_on = coalesce((p_active_goal_patch->>'starts_on')::date, starts_on),
        ends_on = nullif(p_active_goal_patch->>'ends_on', '')::date
      where id = v_existing_goal_id and user_id = p_user_id
      returning * into v_active_goal;
    end if;
  else
    select * into v_active_goal
    from public.nutrition_goals
    where user_id = p_user_id and is_active
    limit 1;
  end if;

  if p_body_measurement is not null and p_body_measurement <> 'null'::jsonb then
    if p_body_measurement ? 'weight_kg'
      and p_body_measurement->>'weight_kg' is not null
      and (p_body_measurement->>'weight_kg')::numeric not between 20 and 400 then
      raise exception 'weight_kg is out of range' using errcode = '22023';
    end if;
    if p_body_measurement ? 'body_fat_pct'
      and p_body_measurement->>'body_fat_pct' is not null
      and (p_body_measurement->>'body_fat_pct')::numeric not between 2 and 80 then
      raise exception 'body_fat_pct is out of range' using errcode = '22023';
    end if;

    insert into public.body_measurements (
      user_id,
      measured_at,
      weight_kg,
      body_fat_pct,
      source
    )
    values (
      p_user_id,
      coalesce((p_body_measurement->>'measured_at')::timestamptz, now()),
      nullif(p_body_measurement->>'weight_kg', '')::numeric,
      nullif(p_body_measurement->>'body_fat_pct', '')::numeric,
      coalesce(nullif(p_body_measurement->>'source', ''), 'onboarding')
    )
    returning * into v_measurement;
  end if;

  return jsonb_build_object(
    'profile', to_jsonb(v_profile),
    'active_goal', case when v_active_goal.id is null then null else to_jsonb(v_active_goal) end,
    'body_measurement', case when v_measurement.id is null then null else to_jsonb(v_measurement) end
  );
end;
$$;

revoke all on function public.patch_user_settings(uuid, jsonb, jsonb, jsonb) from public;
revoke all on function public.patch_user_settings(uuid, jsonb, jsonb, jsonb) from anon;
revoke all on function public.patch_user_settings(uuid, jsonb, jsonb, jsonb) from authenticated;
grant execute on function public.patch_user_settings(uuid, jsonb, jsonb, jsonb) to service_role;
