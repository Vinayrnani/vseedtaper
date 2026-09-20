const { chromium } = require('playwright');
const path = require('path');
const SHOT_DIR = path.join(__dirname, 'screenshots');
(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
  try {
    const page = await browser.newPage({ viewport: { width: 1400, height: 900 } });
    const errors = [];
    page.on('pageerror', e => errors.push(e.message));
    for (const v of ['side', 'end', 'end2', 'top', 'iso']) {
      await page.goto(`http://localhost:9099/folder6_preview.html?view=${v}&v=${Date.now()}`);
      await page.waitForFunction(() => window._ready === true, { timeout: 20000 });
      await page.waitForTimeout(600);
      await page.screenshot({ path: path.join(SHOT_DIR, `f6_${v}.png`) });
      console.log('Shot: f6_' + v + '.png');
    }
    console.log('pageerrors:', errors.length, errors);
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('FAILED:', e); process.exit(1); });
