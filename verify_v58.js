const path = require('path');
const pool = require('./playwright_pool');
// v58: solo big-to-small 6-folder — front/west = BIG loose open-6
// entry dia 21 (world x126), back/east = SMALL tight curl exit dia 9
// (world x159), top = wide-left narrow-right taper.
// Coords are three-world (root-local + root offset (-100,0,55)).
// Part centre ~ (42.5, 17, 25), entry face x~26, exit face x~59.
const SHOT_DIR = path.join(__dirname, 'screenshots');
(async () => {
  const { browser, page } = await pool.newPage({ width: 1600, height: 1000 });
  const fails = [];
  const check = (c, m) => { console.log((c ? 'PASS' : 'FAIL') + ' ' + m); if (!c) fails.push(m); };
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
    await shot('v58_plow_front.png', [-5, 20, 29]);
    await shot('v58_plow_back.png', [97, 15, 25]);
    await shot('v58_plow_top.png', [42, 78, 25]);
    const hooks = await page.evaluate(() => ({
      six: window._sixTurner,
      assetV: document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1],
      plowMeshes: (window._partMeshes.plow || []).length,
    }));
    console.log('HOOKS', JSON.stringify(hooks));
    check(hooks.assetV === '42', 'ASSET_V 42 (plow GLB rebuilt)');
    check(hooks.plowMeshes > 0, 'plow mesh loaded solo');
    check(hooks.six.entryBore === 21 && hooks.six.exitBore === 9, 'hooks entry 21 / exit 9');
    check(hooks.six.seamGap === 1.0, 'hooks daylight gap 1.0');
    console.log(fails.length ? 'V58_FAIL' : 'V58_DONE');
    if (fails.length) process.exitCode = 1;
  } finally {
    await pool.releaseBrowser(browser);
  }
})().catch(e => { console.error('V58_ERROR', e); process.exit(1); });
