const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');

// v53 verify: TRUE 6-PROFILE FOLDER REBUILD TAKE 2 (user REJECTS v50 pipe).
// CAD six_turner(): eccentric tongue lift [0.2,0.9,1.6] (entry fused
// shallow -> exit floating overlap, 1.1 daylight seam), tall +Y ramp
// blade, trumpet flare (mouth r+2.0); slot open full length (2mm seam,
// no ring); footprint/tabs/bore kept; fail-loud seam/burial asserts.
// Viewer: _sixTurner floating-overlap hooks (seamGap 1.1), ASSET_V 37,
// plow GLB rebuilt. Live proof: animating + turner end-on/iso + full
// machine t0/t1, 0 errors.
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
    console.log('ASSET_V (expect 37):', assetV);
    check(assetV === '37', 'ASSET_V 37 (plow GLB rebuilt)');

    const t = await page.evaluate(() => ({
      seamGap: window._sixTurner.seamGap, shutX: window._sixTurner.shutX,
      stages: window._sixTurner.stages, entry: window._sixTurner.entry, exit: window._sixTurner.exit
    }));
    console.log('_sixTurner:', JSON.stringify(t));
    check(t.seamGap === 1.1, 'seamGap 1.1 (floating overlap daylight)');
    check(t.shutX === undefined, 'no shutX (exit never shuts into a tube)');
    check(/floats open/.test(t.stages), 'stages note tongue floats open');
    check(/daylight/.test(t.exit), 'exit notes daylight gap, no ring');

    // Turner world box: CAD local x -0.5..34.35 at turner_start 126 ->
    // world x 25.5..60.35 (world = CADx-100); axis at world y~13.2, z~35.
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
    // End-on down the bore axis (axis at world y~13.2, z~35, entry x~26, exit x~60).
    await shot('v53_turner_entry.png', [-34, 13, 35], [45, 13, 35], ['plow'], null);
    await shot('v53_turner_exit.png', [105, 13, 35], [45, 13, 35], ['plow'], null);
    await shot('v53_turner_iso.png', [45 + 45, 13 + 30, 35 + 40], [43, 10, 28], ['plow'], null);
    await page.evaluate(() => { window._showAllParts(); window._overrideAngle = null; window._setPanelCollapsed(false); });
    await page.evaluate(() => {
      window._camera.position.set(30, 320, 200);
      window._controls.target.set(30, 0, 25);
      window._controls.update();
    });
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v53_anim_t0.png') });
    console.log('Shot: v53_anim_t0.png (animating)');
    await page.waitForTimeout(2500);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v53_anim_t1.png') });
    console.log('Shot: v53_anim_t1.png (animating, +2.5s)');
    pruneShots();

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');

    if (fail) { console.log('VERIFY_V53_RESULT: FAIL - ' + fail); process.exitCode = 1; }
    else console.log('VERIFY_V53_RESULT: PASS');
  } finally {
    await pool.releaseBrowser(browser);
  }
})().catch(e => { console.error('VERIFY_V53_RESULT: ERROR', e); process.exit(1); });
