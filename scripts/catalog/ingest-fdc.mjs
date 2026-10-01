// Loads a USDA FoodData Central JSON download into the SnapGrub catalog.
//
//   node scripts/catalog/ingest-fdc.mjs --file FoodData_Central_foundation_food_json.json --dry-run
//   SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... node scripts/catalog/ingest-fdc.mjs --file <path>
//
// Re-running is safe: foods are upserted by (source_type, source_id).
// Roll back with: delete from public.canonical_foods where source_type = 'usda_fdc';
import fs from 'node:fs';

import { FDC_LICENSE_TAG, FDC_SOURCE_TYPE, fdcFoods, mapFdcFood } from './fdc.mjs';

const args = process.argv.slice(2);
const flag = (name) => args.includes(name);
const option = (name) => {
  const index = args.indexOf(name);
  return index >= 0 ? args[index + 1] : undefined;
};

const file = option('--file');
if (!file) {
  console.error('Usage: ingest-fdc.mjs --file <fdc.json> [--dry-run] [--limit N] [--allow-remote]');
  process.exit(2);
}

const limit = Number(option('--limit')) || Infinity;
const records = fdcFoods(JSON.parse(fs.readFileSync(file, 'utf8')));
const foods = [];
let skipped = 0;
for (const record of records) {
  if (foods.length >= limit) break;
  const mapped = mapFdcFood(record);
  if (mapped) foods.push(mapped);
  else skipped += 1;
}
console.log(`Read ${records.length} records: ${foods.length} usable, ${skipped} skipped (no macros).`);

if (flag('--dry-run')) {
  console.log(JSON.stringify(foods.slice(0, 3), null, 2));
  process.exit(0);
}

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) {
  console.error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required (or pass --dry-run).');
  process.exit(2);
}
const local = /^https?:\/\/(localhost|127\.0\.0\.1)(:|\/|$)/.test(url);
if (!local && !flag('--allow-remote')) {
  console.error(`Refusing to ingest into ${url}. Pass --allow-remote once the source and rollback plan are approved.`);
  process.exit(2);
}

const { createClient } = await import('@supabase/supabase-js');
const client = createClient(url, key, { auth: { persistSession: false } });

const run = await client
  .from('catalog_ingest_runs')
  .insert({ source_type: FDC_SOURCE_TYPE, status: 'running', details: { file } })
  .select('id')
  .single();
if (run.error) throw run.error;

let written = 0;
try {
  const BATCH = 200;
  for (let start = 0; start < foods.length; start += BATCH) {
    const batch = foods.slice(start, start + BATCH);
    const upserted = await client
      .from('canonical_foods')
      .upsert(
        batch.map((food) => ({
          source_type: FDC_SOURCE_TYPE,
          source_id: food.source_id,
          name: food.name,
          normalized_name: food.normalized_name,
          category: food.category,
          default_unit: food.default_unit,
          default_quantity: food.default_quantity,
          default_grams: food.default_grams,
          license_tag: FDC_LICENSE_TAG,
          source_quality: food.source_quality,
          region_tags: ['GLOBAL'],
        })),
        { onConflict: 'source_type,source_id' },
      )
      .select('id, source_id');
    if (upserted.error) throw upserted.error;
    const idBySource = new Map(upserted.data.map((row) => [row.source_id, row.id]));

    const nutrients = await client.from('food_nutrients').upsert(
      batch.map((food) => ({ canonical_food_id: idBySource.get(food.source_id), ...food.nutrients })),
      { onConflict: 'canonical_food_id,per_grams' },
    );
    if (nutrients.error) throw nutrients.error;

    // Portions have no plain unique key to upsert on, so replace them.
    const ids = [...idBySource.values()];
    const cleared = await client.from('food_portions').delete().in('canonical_food_id', ids);
    if (cleared.error) throw cleared.error;
    const portions = batch.flatMap((food) =>
      food.portions.map((portion) => ({
        canonical_food_id: idBySource.get(food.source_id),
        unit: portion.unit,
        grams: portion.grams,
      })),
    );
    if (portions.length > 0) {
      const inserted = await client.from('food_portions').insert(portions);
      if (inserted.error) throw inserted.error;
    }
    written += batch.length;
    console.log(`Upserted ${written}/${foods.length}`);
  }
  await client
    .from('catalog_ingest_runs')
    .update({
      status: 'completed',
      finished_at: new Date().toISOString(),
      rows_seen: records.length,
      rows_inserted: written,
      details: { file, skipped },
    })
    .eq('id', run.data.id);
  console.log('Catalog ingest completed.');
} catch (error) {
  await client
    .from('catalog_ingest_runs')
    .update({
      status: 'failed',
      finished_at: new Date().toISOString(),
      rows_seen: records.length,
      rows_inserted: written,
      details: { file, error: String(error?.message ?? error) },
    })
    .eq('id', run.data.id);
  throw error;
}
