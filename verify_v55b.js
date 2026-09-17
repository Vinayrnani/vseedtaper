const path = require('path');
const pool = require('./playwright_pool');
// v55b: tight axial daylight shots down the hollow bore (axis from
// live plow box: entry face x~25.4, exit x~60.4, axis y~11.6 z~25).
const SHOT_DIR = path.join(__dirname, 'screenshots');
(async () => {
  const { browser, page } = await pool.newPage({ width: 1600, height: 1000 });
  try {
    await page.goto(`http://localhost:9099/index.html?v=${Date.now()}`);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 30000 });
    await page.evaluate(() => { window._overrideAngle = null; window._setOnlyVisible(['plow']); window._setPanelCollapsed(true); });
    async function shot(f, cam, tgt) {
      await page.evaluate(([c, t2]) => {
        window._camera.position.set(c[0], c[1], c[2]);
        window._controls.target.set(t2[0], t2[1], t2[2]);
        window._controls.update();
      }, [cam, tgt]);
      await page.waitForTimeout(450);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      console.log('Shot:', f);
    }
    await shot('v55_bore_entry.png', [-15, 11.6, 25], [60, 11.6, 25]);
    await shot('v55_bore_exit.png', [100, 11.6, 25], [25, 11.6, 25]);
    const errs = [];
    page.on('pageerror', e => errs.push(e.message));
    console.log('V55B_DONE');
  } finally {
    await pool.releaseBrowser(browser);
  }
})().catch(e => { console.error('V55B_ERROR', e); process.exit(1); });
