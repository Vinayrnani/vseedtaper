const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');

// v70 verify (STEP 1 ONLY): bigger drum gear 44T / roller pinion 16T M2.
// Checks: status=ready, animating, DRUM_RATIO 16/44, GEAR_PHASE PI/16,
// _setRotations kinematics (drum/crank/twister), drum-gear world size ~92,
// tape-static regression, 0 console errors, ASSET_V 51.
// Shots: 1 close-up of the new bigger drum gear + 1 wide with roller gear.
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

    // Step-1 ratio constants.
    const ratios = await page.evaluate(() => ({
      drumRatio: 16 / 44,
      gearPhase: Math.PI / 16,
    }));
    const gotRatio = await page.evaluate(() => window._setRotations ? (function () {
      window._setRotations(Math.PI * 2);
      const d = window._pivots.drum.rotation.z;
      const c = window._crankSpinner.rotation.z;
      const t = window._pivots.twister.rotation.x;
      const lo = window._pivots.lower.rotation.z;
      window._overrideAngle = null;
      return { d, c, t, lo };
    })() : null);
    console.log('kinematics at 1 crank rev:', JSON.stringify(gotRatio));
    check(gotRatio && Math.abs(gotRatio.d - Math.PI * 2 * ratios.drumRatio) < 1e-6,
      `drum = crank * 16/44 (got ${gotRatio && gotRatio.d})`);
    check(gotRatio && Math.abs(gotRatio.c - (-Math.PI * 2 - ratios.gearPhase)) < 1e-6,
      `crank rigid with roller + 11.25deg phase (got ${gotRatio && gotRatio.c})`);
    check(gotRatio && Math.abs(gotRatio.t - (-6 * ratios.drumRatio * Math.PI * 2)) < 1e-6,
      `twister = -6x drum (got ${gotRatio && gotRatio.t})`);
    check(gotRatio && Math.abs(gotRatio.lo - gotRatio.c) < 1e-9, 'roller rigid with crank (senses kept)');

    // Drum-gear world size proof: 44T M2 -> outer dia 92 (was 84).
    // Drum-gear geometry size proof: 44T M2 -> outer dia 92 (was 84).
    // NOTE: read geometry.boundingBox (rotation-invariant); world AABBs
    // inflate under drumPivot rotation (corner-transform artefact).
    const cartBox = await page.evaluate(() => {
      let gx = 0, gy = 0, gz = 0, n = 0;
      (window._partMeshes.cartridge || []).forEach(g => g.traverse(m => {
        if (m.isMesh && m.geometry && m.geometry.attributes.position) {
          m.geometry.computeBoundingBox();
          const s = new THREE.Vector3(); m.geometry.boundingBox.getSize(s);
          gx = Math.max(gx, s.x); gy = Math.max(gy, s.y); gz = Math.max(gz, s.z); n++;
        }
      }));
      return { gx, gy, gz, n };
    });
    console.log('cartridge geometry box:', JSON.stringify(cartBox));
    check(!!cartBox && cartBox.gx > 88 && cartBox.gx < 96 && cartBox.gy > 88 && cartBox.gy < 96,
      `drum gear 44T outer ~92 (got ${cartBox && cartBox.gx}/${cartBox && cartBox.gy})`);

    // Tape-static regression (v45): ribbon stays centred while animating.
    await page.evaluate(() => { window._overrideAngle = 0.6; });
    await page.waitForTimeout(200);
    const tx0 = await page.evaluate(() => window._tapeFold.flat.position.x);
    await page.waitForTimeout(1200);
    const tx1 = await page.evaluate(() => window._tapeFold.flat.position.x);
    console.log(`tapeGroup.x frozen=${tx0} animating=${tx1}`);
    check(tx0 === tx1 && tx0 === 97, `tape ribbon STATIC, centred CAD span (got ${tx0}/${tx1})`);

    await page.evaluate(() => window._setPanelCollapsed(true));
    await page.evaluate(() => {
      const top = window._root.parent || window._root;
      top.traverse(o => { if (o.isLine) o.visible = false; });
    });
    async function shot(f, cam, tgt, only, ang) {
      await page.evaluate((o) => { if (o) window._setOnlyVisible(o); else window._showAllParts(); }, only || null);
      if (ang === null || ang === undefined) await page.evaluate(() => { window._overrideAngle = null; });
      else await page.evaluate((a) => { window._overrideAngle = a; }, ang);
      await page.evaluate(([c, t]) => {
        window._camera.position.set(c[0], c[1], c[2]);
        window._controls.target.set(t[0], t[1], t[2]);
        window._controls.update();
      }, [cam, tgt]);
      await page.waitForTimeout(450);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      console.log('Shot:', f);
    }
    // Drum world pivot (root-local (100,60,-30) + root offset).
    const drumW = await page.evaluate(() => {
      const v = new THREE.Vector3();
      window._pivots.drum.getWorldPosition(v);
      return [v.x, v.y, v.z];
    });
    const rollerW = await page.evaluate(() => {
      const v = new THREE.Vector3();
      window._pivots.lower.getWorldPosition(v);
      return [v.x, v.y, v.z];
    });
    console.log('drum world:', JSON.stringify(drumW), 'roller world:', JSON.stringify(rollerW));
    // 1) close-up of the new bigger drum gear (chassis hidden: gear plane
    // faces world +z, drum body sits behind it).
    await shot('v70_drum_gear_closeup.png',
      [drumW[0] + 25, drumW[1] + 20, drumW[2] + 105],
      [drumW[0], drumW[1], drumW[2] + 15],
      ['cartridge'], 0.6);
    // 2) wide with roller gear (both gears + mesh span, chassis hidden).
    const mid = [(drumW[0] + rollerW[0]) / 2, (drumW[1] + rollerW[1]) / 2, (drumW[2] + rollerW[2]) / 2];
    await shot('v70_gears_wide.png',
      [mid[0] + 70, mid[1] + 80, mid[2] + 210],
      [mid[0] - 10, mid[1] - 15, mid[2] - 5],
      ['cartridge', 'rollers_lower', 'rollers_upper', 'crank'], null);

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 51):', assetV);
    check(assetV === '51', 'ASSET_V 51 (v70 step-1 gear/GLB rebuild)');
    await page.close();

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await pool.releaseBrowser(browser);
  }
})();
