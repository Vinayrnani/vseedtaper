const path = require('path');
const pool = require('./playwright_pool');
// v61: clean-sheet parametric U-to-spiral-swirl plow — open-U entry
// dia 21 (180deg, no hook, world x126) winding to near-closed spiral
// exit dia 9 (352deg + 190deg spiral-diving hook, 1.0 daylight gap,
// world x159) + flat entry tray 13.8x16x0.8 west of the large mouth
// (world 112..125.8).
// Coords are three-world (root-local + root offset (-100,0,55)).
const SHOT_DIR = path.join(__dirname, 'screenshots');
(async () => {
  const { browser, page } = await pool.newPage({ width: 1600, height: 1000 });
  const fails = [];
  const check = (c, m) => { console.log((c ? 'PASS' : 'FAIL') + ' ' + m); if (!c) fails.push(m); };
  try {
    await page.goto(`http://localhost:9099/index.html?v=${Date.now()}`);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 30000 });
    await page.evaluate(() => { window._overrideAngle = 0; window._setOnlyVisible(['plow']); window._setPanelCollapsed(true); if (window._twister) window._twister.lines.forEach(l => l.visible = false); });
    const T = [36, 15, 25];
    async function shot(f, cam, tgt) {
      await page.evaluate(([c, t2]) => {
        window._camera.position.set(c[0], c[1], c[2]);
        window._controls.target.set(t2[0], t2[1], t2[2]);
        window._controls.update();
      }, [cam, tgt || T]);
      await page.waitForTimeout(500);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      console.log('Shot:', f);
    }
    await shot('v61_plow_front.png', [-5, 20, 29]);
    await shot('v61_plow_back.png', [97, 15, 25]);
    await shot('v61_plow_top.png', [36, 78, 25]);
    await shot('v61_plow_tray.png', [2, 58, 14], [32, 8, 18]);
    const hooks = await page.evaluate(() => ({
      six: window._sixTurner,
      assetV: document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1],
      plowMeshes: (window._partMeshes.plow || []).length,
    }));
    console.log('HOOKS', JSON.stringify(hooks));
    check(hooks.assetV === '45', 'ASSET_V 45 (plow GLB rebuilt)');
    check(hooks.plowMeshes > 0, 'plow mesh loaded solo');
    check(hooks.six.entryBore === 21 && hooks.six.exitBore === 9, 'hooks entry 21 / exit 9');
    check(hooks.six.seamGap === 1.0, 'hooks daylight gap 1.0');
    check(JSON.stringify(hooks.six.tray) === JSON.stringify([112, 125.8, 16]), 'hooks tray [112,125.8,16]');
    check(/open[- ]U/.test(hooks.six.entry) && /spiral/.test(hooks.six.stages), 'hooks describe U-to-spiral entry');
    // Full assembly: tray must sit clear in the machine, nothing displaced.
    await page.evaluate(() => document.getElementById('btnAllOn').click());
    await page.evaluate(() => {
      window._camera.position.set(250, 220, 220);
      window._controls.target.set(20, 40, 0);
      window._controls.update();
    });
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v61_full.png') });
    console.log('Shot: v61_full.png');
    console.log(fails.length ? 'V61_FAIL' : 'V61_DONE');
    if (fails.length) process.exitCode = 1;
  } finally {
    await pool.releaseBrowser(browser);
  }
})().catch(e => { console.error('V61_ERROR', e); process.exit(1); });
