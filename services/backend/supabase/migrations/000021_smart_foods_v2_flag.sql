insert into public.feature_flags (key, enabled, rollout_percent, rules, description)
values (
  'smart_foods_v2.enabled',
  false,
  0,
  '{}'::jsonb,
  'Show ranked Smart repeats from recent meals, templates, and learned defaults.'
)
on conflict (key) do update set
  enabled = excluded.enabled,
  rollout_percent = excluded.rollout_percent,
  rules = excluded.rules,
  description = excluded.description,
  updated_at = now();
