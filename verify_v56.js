const path = require('path');
const pool = require('./playwright_pool');
// v56: solo thin-wall tapered 6-folder vs Front/Back/Top.jpg —
// entry (open-C), exit (6-spiral flare), top (taper).
// Coords are three-world (root-local + root offset (-100,0,55)).
// Part centre ~ (42.5, 17, 25), entry face x~26, exit face x~59.
const SHOT_DIR = path.join(__dirname, 'screenshots');
(async () => {
  const { browser, page } = await pool.newPage({ width: 1600, height: 1000 });
  try {
    await page.goto(`http://localhost:9099/index.html?v=${Date.now()}`);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 30000 });
    await page.evaluate(() => { window._overrideAngle = 0; window._setOnlyVisible(['plow']); window._setPanelCollapsed(true); if (window._twister) window._twister.lines.forEach(l => l.visible = false); });
    const T = [42, 15, 25];
    async function shot(f, cam) {
      await page.evaluate(([c, t2]) => {
        window._camera.position.set(c[0], c[1], c[2]);
        window._controls.target.set(t2[0], t2[1], t2[2]);
        window._controls.update();
      }, [cam, T]);
      await page.waitForTimeout(500);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      console.log('Shot:', f);
    }
    await shot('v56_plow_front.png', [-5, 20, 29]);
    await shot('v56_plow_back.png', [97, 15, 25]);
    await shot('v56_plow_top.png', [42, 78, 25]);
    const hooks = await page.evaluate(() => ({
      six: window._sixTurner,
      plowMeshes: (window._partMeshes.plow || []).length,
    }));
    console.log('HOOKS', JSON.stringify(hooks));
    console.log('V56_DONE');
  } finally {
    await pool.releaseBrowser(browser);
  }
})().catch(e => { console.error('V56_ERROR', e); process.exit(1); });
