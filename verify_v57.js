const path = require('path');
const pool = require('./playwright_pool');
// v57: hollow overlapping-plate loft — entry (open-C), exit (6-spiral),
// top (taper) + bore-axis macros proving hollow + slit.
// Three-world: entry face (26,17,25), exit face (59,17,25), axis y=17,z=25.
const SHOT_DIR = path.join(__dirname, 'screenshots');
(async () => {
  const { browser, page } = await pool.newPage({ width: 1600, height: 1000 });
  try {
    await page.goto(`http://localhost:9099/index.html?v=${Date.now()}`);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 30000 });
    await page.evaluate(() => { window._overrideAngle = 0; window._setOnlyVisible(['plow']); window._setPanelCollapsed(true); if (window._twister) window._twister.lines.forEach(l => l.visible = false); });
    async function shot(f, cam, tgt) {
      await page.evaluate(([c, t2]) => {
        window._camera.position.set(c[0], c[1], c[2]);
        window._controls.target.set(t2[0], t2[1], t2[2]);
        window._controls.update();
      }, [cam, tgt]);
      await page.waitForTimeout(500);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      console.log('Shot:', f);
    }
    const T = [42, 15, 25];
    await shot('v57_plow_entry.png', [-5, 20, 29], T);
    await shot('v57_plow_exit.png', [97, 15, 25], T);
    await shot('v57_plow_top.png', [42, 78, 25], T);
    await shot('v57_bore_entry_macro.png', [6, 17, 25], [32, 17, 25]);
    await shot('v57_bore_exit_macro.png', [79, 17, 25], [50, 17, 25]);
    console.log('V57_DONE');
  } finally {
    await pool.releaseBrowser(browser);
  }
})().catch(e => { console.error('V57_ERROR', e); process.exit(1); });
