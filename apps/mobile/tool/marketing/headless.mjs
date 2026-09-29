// Headless Chromium screenshot helper shared by the marketing tools.
import { spawn } from 'node:child_process';
import { existsSync, statSync, rmSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const BROWSERS = [
  '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/Applications/Chromium.app/Contents/MacOS/Chromium',
];
const browser = BROWSERS.find(existsSync);
if (!browser) throw new Error('No Chromium-based browser found for headless rendering.');

const profile = mkdtempSync(join(tmpdir(), 'snapgrub-headless-'));

// Headless Chromium writes the screenshot and then idles; we watch for the
// file to stabilise and stop the process ourselves.
export function shoot(url, file, width, height) {
  return new Promise((resolveShot, reject) => {
    if (existsSync(file)) rmSync(file);
    const proc = spawn(browser, [
      '--headless=new', '--disable-gpu', '--hide-scrollbars',
      '--force-device-scale-factor=1', `--window-size=${width},${height}`,
      `--user-data-dir=${profile}`, '--no-first-run', '--no-default-browser-check',
      '--virtual-time-budget=4000', `--screenshot=${file}`, url,
    ], { stdio: 'ignore' });
    let last = -1, stable = 0;
    const started = Date.now();
    const timer = setInterval(() => {
      if (existsSync(file)) {
        const size = statSync(file).size;
        stable = size === last && size > 0 ? stable + 1 : 0;
        last = size;
        if (stable >= 2) {
          clearInterval(timer);
          proc.kill('SIGKILL');
          resolveShot(file);
        }
      } else if (Date.now() - started > 60000) {
        clearInterval(timer);
        proc.kill('SIGKILL');
        reject(new Error(`Timed out rendering ${url}`));
      }
    }, 250);
  });
}

export function cleanup() {
  // The browser may still be flushing its profile; retry, never fail the run.
  try {
    rmSync(profile, { recursive: true, force: true, maxRetries: 10, retryDelay: 200 });
  } catch {
    // Leftover temp profile in $TMPDIR is harmless.
  }
}
