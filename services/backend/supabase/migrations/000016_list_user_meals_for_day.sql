create or replace function public.list_user_meals_for_day(
  p_user_id uuid,
  p_day date,
  p_limit integer default 100
)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(to_jsonb(m) || jsonb_build_object('items', coalesce(mi.items, '[]'::jsonb)) order by m.logged_at desc),
    '[]'::jsonb
  )
  from (
    select *
    from public.meals
    where user_id = p_user_id
      and deleted_at is null
      and public.meal_rollup_day(logged_at, timezone) = p_day
    order by logged_at desc
    limit least(greatest(coalesce(p_limit, 100), 1), 500)
  ) m
  left join lateral (
    select jsonb_agg(to_jsonb(item) order by item.position) as items
    from public.meal_items item
    where item.meal_id = m.id
  ) mi on true
$$;

revoke all on function public.list_user_meals_for_day(uuid, date, integer)
from public, anon, authenticated;

grant execute on function public.list_user_meals_for_day(uuid, date, integer)
to service_role;

