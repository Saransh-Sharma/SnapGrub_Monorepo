alter table public.profiles enable row level security;
alter table public.nutrition_goals enable row level security;
alter table public.devices enable row level security;
alter table public.feature_flags enable row level security;
alter table public.analytics_events enable row level security;

create policy profiles_select_own
on public.profiles for select to authenticated
using (id = (select auth.uid()));

create policy profiles_insert_own
on public.profiles for insert to authenticated
with check (id = (select auth.uid()));

create policy profiles_update_own
on public.profiles for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

create policy nutrition_goals_select_own
on public.nutrition_goals for select to authenticated
using (user_id = (select auth.uid()));

create policy nutrition_goals_insert_own
on public.nutrition_goals for insert to authenticated
with check (user_id = (select auth.uid()));

create policy nutrition_goals_update_own
on public.nutrition_goals for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy nutrition_goals_delete_own
on public.nutrition_goals for delete to authenticated
using (user_id = (select auth.uid()));

create policy devices_select_own
on public.devices for select to authenticated
using (user_id = (select auth.uid()));

create policy devices_insert_own
on public.devices for insert to authenticated
with check (user_id = (select auth.uid()));

create policy devices_update_own
on public.devices for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy devices_delete_own
on public.devices for delete to authenticated
using (user_id = (select auth.uid()));

create policy feature_flags_read_authenticated
on public.feature_flags for select to authenticated
using (true);

create policy analytics_events_insert_own_or_pre_auth
on public.analytics_events for insert to authenticated
with check (user_id is null or user_id = (select auth.uid()));
