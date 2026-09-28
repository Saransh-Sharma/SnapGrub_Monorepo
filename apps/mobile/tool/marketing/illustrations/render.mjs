// Renders every SnapGrub food illustration to PNG with headless Edge/Chrome.
//   node tool/marketing/illustrations/render.mjs [dish ...]
import { mkdirSync } from 'node:fs';
import { shoot, cleanup } from '../headless.mjs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const out = resolve(here, '../../../marketing/illustrations');
const SIZE = 1200;
const ALL = [
  'overnight-oats', 'flat-white', 'avocado-toast', 'greek-yogurt-bowl',
  'poke-bowl', 'chicken-shawarma-wrap', 'caesar-salad', 'sushi-set',
  'salmon-greens', 'dal-rice', 'margherita-pizza', 'ramen',
  'berry-smoothie', 'apple-peanut-butter', 'dark-chocolate', 'hero-plate',
];
const dishes = process.argv.slice(2).length ? process.argv.slice(2) : ALL;
mkdirSync(out, { recursive: true });

for (const dish of dishes) {
  const url = `file://${join(here, 'index.html')}?dish=${dish}&size=${SIZE}`;
  const file = join(out, `${dish}.png`);
  await shoot(url, file, SIZE, SIZE);
  console.log(`✓ ${dish}`);
}
cleanup();
