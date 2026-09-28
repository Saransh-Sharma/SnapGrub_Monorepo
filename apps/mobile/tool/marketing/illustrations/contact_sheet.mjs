// Renders a 4×4 contact sheet of all illustrations for quick review.
import { writeFileSync, readdirSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { shoot, cleanup } from '../headless.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const dir = resolve(here, '../../../marketing/illustrations');
const files = readdirSync(dir).filter((f) => f.endsWith('.png') && f !== 'contact-sheet.png').sort();
const cells = files.map((f) => `<figure><img src="${f}"><figcaption>${f.replace('.png', '')}</figcaption></figure>`).join('');
const html = join(dir, '.contact.html');
writeFileSync(html, `<!doctype html><meta charset=utf-8><style>
body{margin:0;background:#EDE5D8;font:600 15px -apple-system,sans-serif;color:#3a342c}
main{display:grid;grid-template-columns:repeat(4,300px);gap:0}
figure{margin:0;position:relative}img{width:300px;height:300px;display:block}
figcaption{position:absolute;left:8px;bottom:6px;background:rgba(255,255,255,.8);padding:2px 6px;border-radius:6px}
</style><main>${cells}</main>`);
await shoot(`file://${html}`, join(dir, 'contact-sheet.png'), 1200, 300 * Math.ceil(files.length / 4));
cleanup();
console.log('contact sheet written');
