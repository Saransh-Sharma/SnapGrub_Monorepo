create or replace function public.persist_rule_analysis(
  p_user_id uuid,
  p_client_request_id text,
  p_mode text,
  p_input_payload jsonb,
  p_result_payload jsonb,
  p_model_name text,
  p_latency_ms integer,
  p_request_payload jsonb,
  p_response_payload jsonb
)
returns setof public.analysis_jobs
language plpgsql
security definer
set search_path = public
as $$
declare
  v_job public.analysis_jobs%rowtype;
  v_result_payload jsonb;
  v_warnings text[];
begin
  insert into public.analysis_jobs (
    user_id,
    client_request_id,
    analysis_mode,
    status,
    input_payload,
    provider,
    model_name,
    latency_ms,
    completed_at
  )
  values (
    p_user_id,
    p_client_request_id,
    p_mode,
    'completed',
    coalesce(p_input_payload, '{}'::jsonb),
    'snapgrub',
    p_model_name,
    p_latency_ms,
    now()
  )
  on conflict (user_id, client_request_id) do nothing
  returning * into v_job;

  if v_job.id is null then
    select *
      into v_job
    from public.analysis_jobs
    where user_id = p_user_id
      and client_request_id = p_client_request_id;

    return next v_job;
    return;
  end if;

  v_result_payload = jsonb_set(
    coalesce(p_result_payload, '{}'::jsonb),
    '{provenance}',
    coalesce(p_result_payload->'provenance', '{}'::jsonb) ||
      jsonb_build_object('analysis_id', v_job.id),
    true
  );

  select coalesce(array_agg(warning->>'message'), '{}'::text[])
    into v_warnings
  from jsonb_array_elements(
    coalesce(p_result_payload#>'{confidence,warnings}', '[]'::jsonb)
  ) as warning;

  insert into public.analysis_revisions (
    analysis_job_id,
    user_id,
    revision_no,
    title,
    meal_type,
    calories_kcal,
    protein_g,
    carbs_g,
    fat_g,
    confidence_overall,
    confidence_breakdown,
    warnings,
    provenance,
    result_payload
  )
  values (
    v_job.id,
    p_user_id,
    1,
    p_result_payload->>'title',
    p_result_payload->>'meal_type',
    coalesce((p_result_payload#>>'{total,calories_kcal}')::numeric, 0),
    coalesce((p_result_payload#>>'{total,protein_g}')::numeric, 0),
    coalesce((p_result_payload#>>'{total,carbs_g}')::numeric, 0),
    coalesce((p_result_payload#>>'{total,fat_g}')::numeric, 0),
    (p_result_payload#>>'{confidence,overall}')::numeric,
    coalesce(p_result_payload->'confidence', '{}'::jsonb),
    v_warnings,
    coalesce(v_result_payload->'provenance', '{}'::jsonb),
    v_result_payload
  );

  insert into public.model_invocations (
    analysis_job_id,
    user_id,
    provider,
    model_name,
    purpose,
    status,
    latency_ms,
    request_payload,
    response_payload
  )
  values (
    v_job.id,
    p_user_id,
    'snapgrub',
    p_model_name,
    p_mode || '_analysis',
    'completed',
    p_latency_ms,
    coalesce(p_request_payload, '{}'::jsonb),
    p_response_payload
  );

  return next v_job;
end;
$$;

revoke all on function public.persist_rule_analysis(
  uuid,
  text,
  text,
  jsonb,
  jsonb,
  text,
  integer,
  jsonb,
  jsonb
) from public, anon, authenticated;

grant execute on function public.persist_rule_analysis(
  uuid,
  text,
  text,
  jsonb,
  jsonb,
  text,
  integer,
  jsonb,
  jsonb
) to service_role;
