/**
 * Renders each prototype screen in headless Chromium and writes PNGs to ../design/screens.
 *
 *   npm install
 *   npm run export
 */

import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join } from 'node:path';
import { mkdir, rm } from 'node:fs/promises';
import puppeteer from 'puppeteer';

const here = dirname(fileURLToPath(import.meta.url));
const indexUrl = pathToFileURL(join(here, 'index.html')).href;
const outDir = join(here, '..', 'design', 'screens');

const PHONE_SCREENS = [
  ['01-home', 'home'],
  ['02-create-session', 'create'],
  ['03-session-code', 'create-code'],
  ['04-runner-dashboard', 'runner'],
  ['05-runner-proximity-alert', 'runner-alert'],
  ['06-join-session', 'join'],
  ['07-spectator-map', 'spectator'],
  ['08-spectator-details', 'spectator-expanded'],
  ['09-spectator-proximity-alert', 'spectator-alert'],
  ['10-settings', 'settings'],
];

const WATCH_SCREENS = [
  ['11-watch-tracking', 'watch-tracking'],
  ['12-watch-alert', 'watch-alert'],
];

async function capture(page, { target, screen, file, selector }) {
  await page.goto(`${indexUrl}?export=${target}&screen=${screen}`, { waitUntil: 'networkidle0' });
  await page.waitForFunction(() => window.__protoReady === true, { timeout: 15000 });
  await page.evaluate(() => document.fonts.ready);
  await new Promise((resolve) => setTimeout(resolve, 350));

  const element = await page.$(selector);
  if (!element) throw new Error(`Missing ${selector} for ${screen}`);
  await element.screenshot({ path: join(outDir, `${file}.png`), omitBackground: true });
  console.log(`  ${file}.png`);
}

async function main() {
  await rm(outDir, { recursive: true, force: true });
  await mkdir(outDir, { recursive: true });

  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--allow-file-access-from-files', '--hide-scrollbars'],
  });

  try {
    const page = await browser.newPage();
    // Viewport must exceed the device frame, or element screenshots get clipped.
    await page.setViewport({ width: 900, height: 1100, deviceScaleFactor: 2 });

    console.log('Exporting iPhone screens:');
    for (const [file, screen] of PHONE_SCREENS) {
      await capture(page, { target: 'phone', screen, file, selector: '.device' });
    }

    console.log('Exporting Apple Watch screens:');
    for (const [file, screen] of WATCH_SCREENS) {
      await capture(page, { target: 'watch', screen, file, selector: '.watch' });
    }
  } finally {
    await browser.close();
  }

  console.log(`\nDone — PNGs written to ${outDir}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
