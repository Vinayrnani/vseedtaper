const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');

// v55 verify: HOLLOW 6 (Front/Back/Top.jpg: bore hollow see-through,
// no center post). CAD six_turner(): center fin tongue + wedge nose +
// bore rails DELETED; low flat base + outer side curl wings only
// (7 stations, left 30->270deg, right 20->180deg, roots bedded in
// outboard root walls); bore see-through full length (13 straight
// sightlines proven in CAD); footprint/tabs/$fn/tol kept.
// Viewer: hollow relabel + _sixTurner hooks, ASSET_V 39, plow rebuilt.
// Live proof: animating + entry (open C) / exit (6 spiral) / top,
// 0 errors.
const SHOT_DIR = path.join(__dirname, 'screenshots');
fs.mkdirSync(SHOT_DIR, { recursive: true });
function pruneShots() {
  const files = fs.readdirSync(SHOT_DIR)
    .filter(f => f.endsWith('.png'))
    .map(f => ({ f, m: fs.statSync(path.join(SHOT_DIR, f)).mtimeMs }))
    .sort((a, b) => a.m - b.m);
  while (files.length > 25) {
    const old = files.shift();
    fs.unlinkSync(path.join(SHOT_DIR, old.f));
    console.log('Pruned old screenshot:', old.f);
  }
}

const V = Date.now();
let fail = null;
function check(cond, msg) {
  console.log((cond ? 'PASS ' : 'FAIL ') + msg);
  if (!cond && !fail) fail = msg;
}

(async () => {
  const { browser, page } = await pool.newPage({ width: 1600, height: 1000 });
  try {
    const errors = [];
    page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
    page.on('pageerror', err => errors.push(err.message));
    await page.goto(`http://localhost:9099/index.html?v=${V}`);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 30000 });
    console.log('Desktop: status=ready');

    await page.evaluate(() => { window._overrideAngle = null; window._showAllParts(); });
    await page.waitForTimeout(400);
    const a0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.waitForTimeout(700);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    check(a0 !== a1, 'animating true (crankSpinner rotates)');

    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 39):', assetV);
    check(assetV === '39', 'ASSET_V 39 (plow GLB rebuilt)');

    const t = await page.evaluate(() => ({
      seamGap: window._sixTurner.seamGap, boreR: window._sixTurner.boreR,
      stages: window._sixTurner.stages, entry: window._sixTurner.entry, exit: window._sixTurner.exit
    }));
    console.log('_sixTurner:', JSON.stringify(t));
    check(t.boreR === 0, 'boreR 0 (no bore tube, hollow)');
    check(/hollow/i.test(t.stages), 'stages note hollow-6');
    check(/no center post/i.test(t.entry), 'entry notes no center post (open C)');
    check(/hollow bore/i.test(t.exit), 'exit notes hollow bore (6 spiral)');

    const plow = await page.evaluate(() => {
      const grp = (window._partMeshes['plow'] || [])[0];
      if (!grp) return null;
      const box = new THREE.Box3();
      grp.traverse(m => {
        if (m.isMesh && m.geometry && m.geometry.attributes.position) {
          m.updateWorldMatrix(true, false);
          box.expandByObject(m);
        }
      });
      if (box.isEmpty()) return null;
      const s = box.getSize(new THREE.Vector3()), c = box.getCenter(new THREE.Vector3());
      return { sx: s.x, sy: s.y, sz: s.z, cx: c.x, cy: c.y, cz: c.z };
    });
    console.log('plow box:', JSON.stringify(plow));
    check(!!plow, 'plow GLB present');
    check(!!plow && Math.abs(plow.sx - 34.9) < 1.2, `plow X span ~34.9 (got ${plow && plow.sx})`);
    check(!!plow && Math.abs(plow.cx - 43) < 1.5, `plow centred world x~43 (got ${plow && plow.cx})`);

    await page.evaluate(() => window._setPanelCollapsed(true));
    async function shot(f, cam, tgt, only, ang) {
      await page.evaluate((o) => { if (o) window._setOnlyVisible(o); else window._showAllParts(); }, only || null);
      if (ang === null || ang === undefined) await page.evaluate(() => { window._overrideAngle = null; });
      else await page.evaluate((a) => { window._overrideAngle = a; }, ang);
      await page.evaluate(([c, t2]) => {
        window._camera.position.set(c[0], c[1], c[2]);
        window._controls.target.set(t2[0], t2[1], t2[2]);
        window._controls.update();
      }, [cam, tgt]);
      await page.waitForTimeout(450);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      console.log('Shot:', f);
    }
    // Down the bore axis: entry sees open C, exit sees 6 spiral.
    await shot('v55_entry.png', [-34, 13, 35], [45, 13, 35], ['plow'], null);
    await shot('v55_exit.png', [105, 13, 35], [45, 13, 35], ['plow'], null);
    await shot('v55_top.png', [43, 13 + 70, 35], [43, 10, 28], ['plow'], null);
    await page.evaluate(() => { window._showAllParts(); window._overrideAngle = null; window._setPanelCollapsed(false); });
    await page.evaluate(() => {
      window._camera.position.set(30, 320, 200);
      window._controls.target.set(30, 0, 25);
      window._controls.update();
    });
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v55_anim_t0.png') });
    console.log('Shot: v55_anim_t0.png (animating)');
    await page.waitForTimeout(2500);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v55_anim_t1.png') });
    console.log('Shot: v55_anim_t1.png (animating, +2.5s)');
    pruneShots();

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');

    if (fail) { console.log('VERIFY_V55_RESULT: FAIL - ' + fail); process.exitCode = 1; }
    else console.log('VERIFY_V55_RESULT: PASS');
  } finally {
    await pool.releaseBrowser(browser);
  }
})().catch(e => { console.error('VERIFY_V55_RESULT: ERROR', e); process.exit(1); });
