// Composes captioned App Store marketing panels from raw screenshots.
//   node tool/marketing/frames/compose.mjs
import { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { shoot, cleanup } from '../headless.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const mobile = resolve(here, '../../..');
const out = join(mobile, 'marketing/out');
const fonts = join(mobile, 'assets/fonts');
const template = readFileSync(join(here, 'frame.html'), 'utf8');
const captions = JSON.parse(readFileSync(join(here, '../captions.json'), 'utf8'));
const SIZES = { '6.9': [1320, 2868], '6.5': [1284, 2778] };
const escape = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');

let count = 0;
for (const [size, [W, H]] of Object.entries(SIZES)) {
  for (const theme of ['light', 'dark']) {
    const rawDir = join(out, size, 'raw', theme);
    if (!existsSync(rawDir)) continue;
    const dest = join(out, size, 'framed', theme);
    mkdirSync(dest, { recursive: true });
    for (const file of readdirSync(rawDir).filter((f) => f.endsWith('.png')).sort()) {
      const key = file.replace('.png', '');
      const caption = captions[key];
      if (!caption) {
        console.warn(`  no caption for ${key}; skipped`);
        continue;
      }
      const lines = caption.headline.split('\n').length;
      const subTop = 210 + lines * 132 + 34;
      const phoneTop = subTop + 150;
      const html = template
        .replaceAll('{{FONTS}}', `file://${fonts}`)
        .replaceAll('{{W}}', String(W))
        .replaceAll('{{H}}', String(H))
        .replaceAll('{{SHOT_W}}', String(W))
        .replaceAll('{{SHOT_H}}', String(H))
        .replaceAll('{{SUB_TOP}}', String(subTop))
        .replaceAll('{{PHONE_TOP}}', String(phoneTop))
        .replaceAll('{{CLASSES}}', `${theme} ${caption.accent ?? ''}`)
        .replaceAll('{{HEADLINE}}', escape(caption.headline))
        .replaceAll('{{SUBLINE}}', escape(caption.subline))
        .replaceAll('{{SHOT}}', `file://${join(rawDir, file)}`);
      const page = join(dest, `.${key}.html`);
      writeFileSync(page, html);
      await shoot(`file://${page}`, join(dest, file), W, H);
      rmSync(page);
      count++;
      console.log(`  framed ${size}/${theme}/${key}`);
    }
  }
}
cleanup();
console.log(`${count} framed panels`);
