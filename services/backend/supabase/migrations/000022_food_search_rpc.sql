-- Ranked catalog search. Substring matches come back in table order, so a
-- page of them can miss the exact food once the catalog holds thousands of
-- rows. Trigram indexes keep `ilike '%q%'` fast at that size.

create index if not exists idx_canonical_foods_normalized_name_trgm
on public.canonical_foods using gin (normalized_name gin_trgm_ops);

create index if not exists idx_food_aliases_normalized_alias_trgm
on public.food_aliases using gin (normalized_alias gin_trgm_ops);

create index if not exists idx_branded_products_normalized_name_trgm
on public.branded_products using gin (normalized_name gin_trgm_ops);

-- Active catalog foods whose name or alias contains p_query, best first:
-- exact (4), "query ..." prefix (3), whole word (2), substring (1). Trigram
-- similarity, always below 1 for a non-exact match, orders within a tier and
-- can never lift a match into the next one.
create or replace function public.search_canonical_foods(
  p_query text,
  p_limit integer default 25
)
returns table (canonical_food_id uuid, score real)
language sql
stable
security definer
set search_path = public, extensions
as $$
  with q as (
    select trim(regexp_replace(lower(coalesce(p_query, '')), '[%_\\]', '', 'g')) as text
  ),
  hits as (
    select cf.id as food_id, cf.normalized_name as matched
    from public.canonical_foods cf
    cross join q
    where cf.is_active
      and q.text <> ''
      and cf.normalized_name ilike '%' || q.text || '%'
    union all
    select fa.canonical_food_id, fa.normalized_alias
    from public.food_aliases fa
    join public.canonical_foods cf
      on cf.id = fa.canonical_food_id and cf.is_active
    cross join q
    where q.text <> ''
      and fa.normalized_alias ilike '%' || q.text || '%'
  ),
  scored as (
    select
      h.food_id,
      max(
        case
          when h.matched = q.text then 4
          when h.matched like q.text || ' %' then 3
          when ' ' || h.matched || ' ' like '% ' || q.text || ' %' then 2
          else 1
        end + similarity(h.matched, q.text)
      )::real as score,
      min(length(h.matched)) as shortest
    from hits h
    cross join q
    group by h.food_id
  )
  select s.food_id, s.score
  from scored s
  order by s.score desc, s.shortest asc, s.food_id
  limit least(greatest(coalesce(p_limit, 25), 1), 50)
$$;

revoke all on function public.search_canonical_foods(text, integer)
from public, anon, authenticated;

grant execute on function public.search_canonical_foods(text, integer)
to service_role;
