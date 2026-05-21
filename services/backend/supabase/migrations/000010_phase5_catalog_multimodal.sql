create table public.canonical_foods (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  normalized_name text not null,
  category text,
  default_unit text,
  default_quantity numeric(10,2),
  default_grams numeric(10,2),
  source_type text not null,
  source_id text,
  license_tag text,
  source_quality text,
  region_tags text[] not null default '{}',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (source_type, source_id)
);

create index idx_canonical_foods_normalized_name
on public.canonical_foods (normalized_name);

create trigger trg_canonical_foods_updated_at
before update on public.canonical_foods
for each row execute function public.set_updated_at();

create table public.food_aliases (
  id uuid primary key default gen_random_uuid(),
  canonical_food_id uuid not null references public.canonical_foods(id) on delete cascade,
  alias text not null,
  normalized_alias text not null,
  locale text,
  region text,
  created_at timestamptz not null default now()
);

create unique index food_aliases_unique_alias_locale_region
on public.food_aliases (canonical_food_id, normalized_alias, coalesce(locale, ''), coalesce(region, ''));

create index idx_food_aliases_normalized_alias
on public.food_aliases (normalized_alias);

create table public.food_nutrients (
  id uuid primary key default gen_random_uuid(),
  canonical_food_id uuid not null references public.canonical_foods(id) on delete cascade,
  per_grams numeric(10,2) not null default 100,
  calories_kcal numeric(10,2) not null default 0,
  protein_g numeric(10,2) not null default 0,
  carbs_g numeric(10,2) not null default 0,
  fat_g numeric(10,2) not null default 0,
  fiber_g numeric(10,2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (canonical_food_id, per_grams)
);

create trigger trg_food_nutrients_updated_at
before update on public.food_nutrients
for each row execute function public.set_updated_at();

create table public.food_portions (
  id uuid primary key default gen_random_uuid(),
  canonical_food_id uuid not null references public.canonical_foods(id) on delete cascade,
  unit text not null,
  qualifier text,
  grams numeric(10,2) not null,
  locale text,
  region text,
  confidence numeric(4,3) not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index food_portions_unique_unit_locale_region
on public.food_portions (canonical_food_id, unit, coalesce(qualifier, ''), coalesce(locale, ''), coalesce(region, ''));

create trigger trg_food_portions_updated_at
before update on public.food_portions
for each row execute function public.set_updated_at();

create table public.branded_products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  brand text,
  normalized_name text not null,
  serving_quantity numeric(10,2),
  serving_unit text,
  serving_grams numeric(10,2),
  calories_kcal_per_100g numeric(10,2) not null default 0,
  protein_g_per_100g numeric(10,2) not null default 0,
  carbs_g_per_100g numeric(10,2) not null default 0,
  fat_g_per_100g numeric(10,2) not null default 0,
  calories_kcal_per_serving numeric(10,2),
  protein_g_per_serving numeric(10,2),
  carbs_g_per_serving numeric(10,2),
  fat_g_per_serving numeric(10,2),
  ingredients_text text,
  source_type text not null,
  source_id text not null,
  license_tag text,
  source_quality text,
  raw_payload jsonb not null default '{}'::jsonb,
  last_verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (source_type, source_id)
);

create index idx_branded_products_brand_normalized_name
on public.branded_products (brand, normalized_name);

create trigger trg_branded_products_updated_at
before update on public.branded_products
for each row execute function public.set_updated_at();

create table public.product_barcodes (
  barcode text primary key,
  branded_product_id uuid not null references public.branded_products(id) on delete cascade,
  barcode_type text not null default 'ean_upc',
  region text,
  created_at timestamptz not null default now()
);

create index idx_product_barcodes_product
on public.product_barcodes (branded_product_id);

create table public.catalog_food_mappings (
  id uuid primary key default gen_random_uuid(),
  source_type text not null,
  source_food_id text not null,
  canonical_food_id uuid not null references public.canonical_foods(id) on delete cascade,
  mapping_method text not null,
  mapping_confidence numeric(4,3) not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (source_type, source_food_id)
);

create index idx_catalog_food_mappings_canonical
on public.catalog_food_mappings (canonical_food_id);

create trigger trg_catalog_food_mappings_updated_at
before update on public.catalog_food_mappings
for each row execute function public.set_updated_at();

create table public.catalog_ingest_runs (
  id uuid primary key default gen_random_uuid(),
  source_type text not null,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  status text not null,
  rows_seen bigint not null default 0,
  rows_inserted bigint not null default 0,
  rows_updated bigint not null default 0,
  details jsonb not null default '{}'::jsonb
);

create index idx_catalog_ingest_runs_source_started
on public.catalog_ingest_runs (source_type, started_at desc);

alter table public.analysis_jobs
  drop constraint if exists analysis_jobs_analysis_mode_check;

alter table public.analysis_jobs
  add constraint analysis_jobs_analysis_mode_check
  check (analysis_mode in ('photo', 'text', 'barcode', 'label', 'voice'));

alter table public.meal_items
  add constraint meal_items_canonical_food_id_fkey
  foreign key (canonical_food_id) references public.canonical_foods(id) on delete set null;

alter table public.meal_items
  add constraint meal_items_branded_product_id_fkey
  foreign key (branded_product_id) references public.branded_products(id) on delete set null;

alter table public.canonical_foods enable row level security;
alter table public.food_aliases enable row level security;
alter table public.food_nutrients enable row level security;
alter table public.food_portions enable row level security;
alter table public.branded_products enable row level security;
alter table public.product_barcodes enable row level security;
alter table public.catalog_food_mappings enable row level security;
alter table public.catalog_ingest_runs enable row level security;

create policy canonical_foods_read_authenticated on public.canonical_foods
for select to authenticated using (is_active);

create policy food_aliases_read_authenticated on public.food_aliases
for select to authenticated using (
  exists (
    select 1 from public.canonical_foods cf
    where cf.id = food_aliases.canonical_food_id
      and cf.is_active
  )
);

create policy food_nutrients_read_authenticated on public.food_nutrients
for select to authenticated using (
  exists (
    select 1 from public.canonical_foods cf
    where cf.id = food_nutrients.canonical_food_id
      and cf.is_active
  )
);

create policy food_portions_read_authenticated on public.food_portions
for select to authenticated using (
  exists (
    select 1 from public.canonical_foods cf
    where cf.id = food_portions.canonical_food_id
      and cf.is_active
  )
);

create policy branded_products_read_authenticated on public.branded_products
for select to authenticated using (true);

create policy product_barcodes_read_authenticated on public.product_barcodes
for select to authenticated using (true);

create policy catalog_food_mappings_read_authenticated on public.catalog_food_mappings
for select to authenticated using (true);

with foods(source_id, name, category, unit, quantity, grams, calories, protein, carbs, fat, region_tags) as (
  values
    ('curated:roti', 'Roti', 'indian_bread', 'roti', 1, 40, 297, 9.8, 46.0, 7.5, array['IN']),
    ('curated:chapati', 'Chapati', 'indian_bread', 'piece', 1, 40, 297, 9.8, 46.0, 7.5, array['IN']),
    ('curated:phulka', 'Phulka', 'indian_bread', 'piece', 1, 35, 260, 8.7, 42.0, 5.5, array['IN']),
    ('curated:paratha', 'Paratha', 'indian_bread', 'piece', 1, 80, 330, 7.0, 45.0, 13.0, array['IN']),
    ('curated:naan', 'Naan', 'indian_bread', 'piece', 1, 90, 310, 9.0, 55.0, 6.0, array['IN']),
    ('curated:steamed_rice', 'Steamed rice', 'grain', 'bowl', 1, 150, 130, 2.7, 28.0, 0.3, array['IN']),
    ('curated:basmati_rice', 'Basmati rice cooked', 'grain', 'bowl', 1, 150, 121, 3.5, 25.0, 0.4, array['IN']),
    ('curated:dal_tadka', 'Dal tadka', 'lentils', 'katori', 1, 180, 118, 6.0, 16.0, 3.4, array['IN']),
    ('curated:dal_makhani', 'Dal makhani', 'lentils', 'katori', 1, 180, 160, 7.0, 18.0, 7.0, array['IN']),
    ('curated:rajma', 'Rajma curry', 'legumes', 'katori', 1, 180, 125, 6.5, 20.0, 2.5, array['IN']),
    ('curated:chole', 'Chole', 'legumes', 'katori', 1, 180, 150, 7.0, 23.0, 4.0, array['IN']),
    ('curated:paneer_butter_masala', 'Paneer butter masala', 'curry', 'katori', 1, 180, 220, 9.0, 9.0, 17.0, array['IN']),
    ('curated:palak_paneer', 'Palak paneer', 'curry', 'katori', 1, 180, 170, 8.0, 7.0, 12.0, array['IN']),
    ('curated:aloo_sabzi', 'Aloo sabzi', 'curry', 'katori', 1, 150, 150, 2.5, 22.0, 6.0, array['IN']),
    ('curated:bhindi_sabzi', 'Bhindi sabzi', 'curry', 'katori', 1, 150, 110, 2.0, 12.0, 6.0, array['IN']),
    ('curated:curd', 'Curd', 'dairy', 'katori', 1, 120, 61, 3.5, 4.7, 3.3, array['IN']),
    ('curated:idli', 'Idli', 'south_indian', 'piece', 1, 40, 145, 4.3, 29.0, 0.8, array['IN']),
    ('curated:dosa', 'Dosa', 'south_indian', 'piece', 1, 100, 168, 3.9, 29.0, 3.7, array['IN']),
    ('curated:sambar', 'Sambar', 'south_indian', 'katori', 1, 180, 70, 3.5, 10.0, 2.0, array['IN']),
    ('curated:poha', 'Poha', 'breakfast', 'bowl', 1, 180, 180, 3.5, 32.0, 5.0, array['IN']),
    ('curated:upma', 'Upma', 'breakfast', 'bowl', 1, 180, 160, 4.0, 28.0, 4.5, array['IN']),
    ('curated:biryani_chicken', 'Chicken biryani', 'rice_dish', 'plate', 1, 300, 170, 8.0, 20.0, 6.0, array['IN']),
    ('curated:biryani_veg', 'Vegetable biryani', 'rice_dish', 'plate', 1, 300, 150, 4.0, 24.0, 4.5, array['IN']),
    ('curated:paneer_tikka', 'Paneer tikka', 'starter', 'piece', 4, 120, 250, 14.0, 8.0, 18.0, array['IN']),
    ('curated:boiled_egg', 'Boiled egg', 'protein', 'piece', 1, 50, 155, 13.0, 1.1, 11.0, array['GLOBAL']),
    ('curated:chicken_breast', 'Chicken breast cooked', 'protein', 'g', 100, 100, 165, 31.0, 0.0, 3.6, array['GLOBAL']),
    ('curated:banana', 'Banana', 'fruit', 'piece', 1, 118, 89, 1.1, 23.0, 0.3, array['GLOBAL']),
    ('curated:apple', 'Apple', 'fruit', 'piece', 1, 180, 52, 0.3, 14.0, 0.2, array['GLOBAL']),
    ('curated:oats', 'Oats cooked', 'grain', 'bowl', 1, 240, 71, 2.5, 12.0, 1.5, array['GLOBAL']),
    ('curated:milk', 'Milk', 'dairy', 'cup', 1, 244, 61, 3.2, 4.8, 3.3, array['GLOBAL'])
)
insert into public.canonical_foods (
  source_type, source_id, name, normalized_name, category, default_unit, default_quantity,
  default_grams, license_tag, source_quality, region_tags
)
select
  'curated', source_id, name, lower(name), category, unit, quantity,
  grams, 'snapgrub-curated', 'starter', region_tags
from foods
on conflict (source_type, source_id) do update
set name = excluded.name,
    normalized_name = excluded.normalized_name,
    category = excluded.category,
    default_unit = excluded.default_unit,
    default_quantity = excluded.default_quantity,
    default_grams = excluded.default_grams,
    license_tag = excluded.license_tag,
    source_quality = excluded.source_quality,
    region_tags = excluded.region_tags;

with nutrients(source_id, calories, protein, carbs, fat) as (
  values
    ('curated:roti', 297, 9.8, 46.0, 7.5), ('curated:chapati', 297, 9.8, 46.0, 7.5),
    ('curated:phulka', 260, 8.7, 42.0, 5.5), ('curated:paratha', 330, 7.0, 45.0, 13.0),
    ('curated:naan', 310, 9.0, 55.0, 6.0), ('curated:steamed_rice', 130, 2.7, 28.0, 0.3),
    ('curated:basmati_rice', 121, 3.5, 25.0, 0.4), ('curated:dal_tadka', 118, 6.0, 16.0, 3.4),
    ('curated:dal_makhani', 160, 7.0, 18.0, 7.0), ('curated:rajma', 125, 6.5, 20.0, 2.5),
    ('curated:chole', 150, 7.0, 23.0, 4.0), ('curated:paneer_butter_masala', 220, 9.0, 9.0, 17.0),
    ('curated:palak_paneer', 170, 8.0, 7.0, 12.0), ('curated:aloo_sabzi', 150, 2.5, 22.0, 6.0),
    ('curated:bhindi_sabzi', 110, 2.0, 12.0, 6.0), ('curated:curd', 61, 3.5, 4.7, 3.3),
    ('curated:idli', 145, 4.3, 29.0, 0.8), ('curated:dosa', 168, 3.9, 29.0, 3.7),
    ('curated:sambar', 70, 3.5, 10.0, 2.0), ('curated:poha', 180, 3.5, 32.0, 5.0),
    ('curated:upma', 160, 4.0, 28.0, 4.5), ('curated:biryani_chicken', 170, 8.0, 20.0, 6.0),
    ('curated:biryani_veg', 150, 4.0, 24.0, 4.5), ('curated:paneer_tikka', 250, 14.0, 8.0, 18.0),
    ('curated:boiled_egg', 155, 13.0, 1.1, 11.0), ('curated:chicken_breast', 165, 31.0, 0.0, 3.6),
    ('curated:banana', 89, 1.1, 23.0, 0.3), ('curated:apple', 52, 0.3, 14.0, 0.2),
    ('curated:oats', 71, 2.5, 12.0, 1.5), ('curated:milk', 61, 3.2, 4.8, 3.3)
)
insert into public.food_nutrients (canonical_food_id, per_grams, calories_kcal, protein_g, carbs_g, fat_g)
select cf.id, 100, n.calories, n.protein, n.carbs, n.fat
from nutrients n
join public.canonical_foods cf on cf.source_type = 'curated' and cf.source_id = n.source_id
on conflict (canonical_food_id, per_grams) do update
set calories_kcal = excluded.calories_kcal,
    protein_g = excluded.protein_g,
    carbs_g = excluded.carbs_g,
    fat_g = excluded.fat_g;

with aliases(source_id, alias, locale, region) as (
  values
    ('curated:roti', 'roti', 'en-IN', 'IN'), ('curated:roti', 'fulka', 'en-IN', 'IN'),
    ('curated:chapati', 'chapati', 'en-IN', 'IN'), ('curated:phulka', 'phulka', 'en-IN', 'IN'),
    ('curated:steamed_rice', 'chawal', 'en-IN', 'IN'), ('curated:dal_tadka', 'dal', 'en-IN', 'IN'),
    ('curated:rajma', 'rajma chawal', 'en-IN', 'IN'), ('curated:chole', 'chana masala', 'en-IN', 'IN'),
    ('curated:paneer_butter_masala', 'paneer butter masala', 'en-IN', 'IN'),
    ('curated:curd', 'dahi', 'en-IN', 'IN'), ('curated:idli', 'idli', 'en-IN', 'IN'),
    ('curated:sambar', 'sambhar', 'en-IN', 'IN'), ('curated:poha', 'poha', 'en-IN', 'IN'),
    ('curated:biryani_chicken', 'chicken biryani', 'en-IN', 'IN'),
    ('curated:biryani_veg', 'veg biryani', 'en-IN', 'IN')
)
insert into public.food_aliases (canonical_food_id, alias, normalized_alias, locale, region)
select cf.id, a.alias, lower(a.alias), a.locale, a.region
from aliases a
join public.canonical_foods cf on cf.source_type = 'curated' and cf.source_id = a.source_id
on conflict do nothing;

with portions(source_id, unit, grams, locale, region) as (
  values
    ('curated:roti', 'roti', 40, 'en-IN', 'IN'), ('curated:chapati', 'piece', 40, 'en-IN', 'IN'),
    ('curated:phulka', 'piece', 35, 'en-IN', 'IN'), ('curated:paratha', 'piece', 80, 'en-IN', 'IN'),
    ('curated:steamed_rice', 'bowl', 150, 'en-IN', 'IN'), ('curated:dal_tadka', 'katori', 180, 'en-IN', 'IN'),
    ('curated:rajma', 'katori', 180, 'en-IN', 'IN'), ('curated:chole', 'katori', 180, 'en-IN', 'IN'),
    ('curated:paneer_butter_masala', 'katori', 180, 'en-IN', 'IN'), ('curated:curd', 'katori', 120, 'en-IN', 'IN'),
    ('curated:idli', 'piece', 40, 'en-IN', 'IN'), ('curated:dosa', 'piece', 100, 'en-IN', 'IN'),
    ('curated:sambar', 'katori', 180, 'en-IN', 'IN'), ('curated:poha', 'bowl', 180, 'en-IN', 'IN'),
    ('curated:biryani_chicken', 'plate', 300, 'en-IN', 'IN'), ('curated:paneer_tikka', 'piece', 30, 'en-IN', 'IN'),
    ('curated:banana', 'piece', 118, 'en-US', null), ('curated:apple', 'piece', 180, 'en-US', null),
    ('curated:milk', 'cup', 244, 'en-US', null)
)
insert into public.food_portions (canonical_food_id, unit, grams, locale, region, confidence)
select cf.id, p.unit, p.grams, p.locale, p.region, 0.85
from portions p
join public.canonical_foods cf on cf.source_type = 'curated' and cf.source_id = p.source_id
on conflict do nothing;

insert into public.branded_products (
  name, brand, normalized_name, serving_quantity, serving_unit, serving_grams,
  calories_kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g,
  calories_kcal_per_serving, protein_g_per_serving, carbs_g_per_serving, fat_g_per_serving,
  source_type, source_id, license_tag, source_quality, raw_payload, last_verified_at
)
values
  ('Parle-G Original Gluco Biscuits', 'Parle', 'parle-g original gluco biscuits', 1, 'pack', 56,
   450, 7, 78, 13, 252, 3.9, 43.7, 7.3, 'curated_hot_cache', 'barcode:8901719101018', 'snapgrub-curated', 'starter', '{}'::jsonb, now()),
  ('Kurkure Masala Munch', 'Kurkure', 'kurkure masala munch', 1, 'pack', 90,
   545, 7, 56, 33, 491, 6.3, 50.4, 29.7, 'curated_hot_cache', 'barcode:8901491101831', 'snapgrub-curated', 'starter', '{}'::jsonb, now()),
  ('Amul Taaza Toned Milk', 'Amul', 'amul taaza toned milk', 1, 'cup', 200,
   58, 3.0, 4.8, 3.0, 116, 6, 9.6, 6, 'curated_hot_cache', 'barcode:8901262010123', 'snapgrub-curated', 'starter', '{}'::jsonb, now())
on conflict (source_type, source_id) do update
set name = excluded.name,
    brand = excluded.brand,
    normalized_name = excluded.normalized_name,
    serving_quantity = excluded.serving_quantity,
    serving_unit = excluded.serving_unit,
    serving_grams = excluded.serving_grams,
    calories_kcal_per_100g = excluded.calories_kcal_per_100g,
    protein_g_per_100g = excluded.protein_g_per_100g,
    carbs_g_per_100g = excluded.carbs_g_per_100g,
    fat_g_per_100g = excluded.fat_g_per_100g,
    calories_kcal_per_serving = excluded.calories_kcal_per_serving,
    protein_g_per_serving = excluded.protein_g_per_serving,
    carbs_g_per_serving = excluded.carbs_g_per_serving,
    fat_g_per_serving = excluded.fat_g_per_serving,
    last_verified_at = excluded.last_verified_at;

insert into public.product_barcodes (barcode, branded_product_id, region)
select replace(source_id, 'barcode:', ''), id, 'IN'
from public.branded_products
where source_type = 'curated_hot_cache'
on conflict (barcode) do update
set branded_product_id = excluded.branded_product_id,
    region = excluded.region;

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
  if v_source not in ('manual', 'duplicate', 'photo', 'barcode', 'text', 'voice') then
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
    raise exception 'expected revision mismatch' using errcode = '40001';
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
