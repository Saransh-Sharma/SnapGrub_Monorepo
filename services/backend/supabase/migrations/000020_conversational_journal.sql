create table public.daily_threads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  day date not null,
  timezone text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, day)
);

create trigger trg_daily_threads_updated_at
before update on public.daily_threads
for each row execute function public.set_updated_at();

create table public.thread_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.daily_threads(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  client_id text not null,
  role text not null check (role in ('user', 'assistant', 'system', 'tool')),
  kind text not null default 'text'
    check (kind in ('text', 'activity', 'mealProposal', 'mealEvent', 'error')),
  text_content text,
  payload jsonb not null default '{}'::jsonb,
  sequence integer not null,
  delivery_state text not null default 'delivered'
    check (delivery_state in ('pending', 'streaming', 'delivered', 'queued', 'failed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, client_id),
  unique (thread_id, sequence)
);

create index idx_thread_messages_thread_sequence
on public.thread_messages (thread_id, sequence);

create trigger trg_thread_messages_updated_at
before update on public.thread_messages
for each row execute function public.set_updated_at();

create table public.agent_runs (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.daily_threads(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  client_request_id text not null,
  status text not null default 'pending'
    check (status in ('pending', 'streaming', 'completed', 'failed')),
  cursor integer not null default 0,
  provider text,
  model_name text,
  input_tokens integer,
  output_tokens integer,
  latency_ms integer,
  error_code text,
  redacted_metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (user_id, client_request_id)
);

create index idx_agent_runs_thread_created
on public.agent_runs (thread_id, created_at desc);

create trigger trg_agent_runs_updated_at
before update on public.agent_runs
for each row execute function public.set_updated_at();

create table public.meal_change_proposals (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.daily_threads(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  agent_run_id uuid references public.agent_runs(id) on delete set null,
  message_id uuid references public.thread_messages(id) on delete set null,
  operation text not null check (operation in ('create', 'update', 'delete')),
  target_meal_id uuid references public.meals(id) on delete set null,
  expected_revision integer,
  draft_payload jsonb not null,
  status text not null default 'pending'
    check (status in ('pending', 'confirmed', 'edited', 'rejected', 'undone', 'expired')),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_meal_change_proposals_thread_created
on public.meal_change_proposals (thread_id, created_at);

create trigger trg_meal_change_proposals_updated_at
before update on public.meal_change_proposals
for each row execute function public.set_updated_at();

create table public.meal_visuals (
  id uuid primary key default gen_random_uuid(),
  meal_id uuid not null references public.meals(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  prompt_signature text not null,
  style_version text not null default 'studio-v1',
  status text not null default 'queued'
    check (status in ('queued', 'generating', 'ready', 'failed')),
  provider text,
  model_name text,
  storage_bucket text,
  storage_path text,
  thumb_storage_path text,
  dominant_color text,
  retry_count integer not null default 0,
  error_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (meal_id, prompt_signature)
);

create index idx_meal_visuals_user_created
on public.meal_visuals (user_id, created_at desc);

create trigger trg_meal_visuals_updated_at
before update on public.meal_visuals
for each row execute function public.set_updated_at();

alter table public.daily_threads enable row level security;
alter table public.thread_messages enable row level security;
alter table public.agent_runs enable row level security;
alter table public.meal_change_proposals enable row level security;
alter table public.meal_visuals enable row level security;

create policy daily_threads_select_own on public.daily_threads
for select to authenticated using (user_id = (select auth.uid()));
create policy daily_threads_insert_own on public.daily_threads
for insert to authenticated with check (user_id = (select auth.uid()));

create policy thread_messages_select_own on public.thread_messages
for select to authenticated using (user_id = (select auth.uid()));
create policy agent_runs_select_own on public.agent_runs
for select to authenticated using (user_id = (select auth.uid()));
create policy meal_change_proposals_select_own on public.meal_change_proposals
for select to authenticated using (user_id = (select auth.uid()));
create policy meal_visuals_select_own on public.meal_visuals
for select to authenticated using (user_id = (select auth.uid()));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'meal-generated-private',
  'meal-generated-private',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy read_own_generated_meals
on storage.objects for select to authenticated
using (
  bucket_id = 'meal-generated-private'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

insert into public.feature_flags (key, enabled, rollout_percent, rules, description)
values
  ('conversational_home.enabled', true, 100, '{}'::jsonb, 'Conversation-first daily journal.'),
  ('agent_streaming.enabled', true, 100, '{}'::jsonb, 'Stream food assistant runs.'),
  ('generated_meal_visuals.enabled', true, 100, '{}'::jsonb, 'Generate studio meal artwork.'),
  ('premium_motion.enabled', true, 100, '{}'::jsonb, 'Enable premium motion and shader effects.')
on conflict (key) do update set
  enabled = excluded.enabled,
  rollout_percent = excluded.rollout_percent,
  rules = excluded.rules,
  description = excluded.description,
  updated_at = now();
