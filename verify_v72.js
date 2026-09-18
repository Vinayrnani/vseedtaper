const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');

// v72 verify: gear-driven orbital thread twister (twister east +
// minimal drum44 chain, all y=12 back plane).
// Checks: status=ready, animating, DRUM_RATIO 16/44,
// _setRotations kinematics (drum/compound/shaft/ring),
// new parts present, tape-static regression, 0 console errors,
// ASSET_V 52, screenshots.
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

    // v72 ratio constants.
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
    check(gotRatio && Math.abs(gotRatio.t - (-(418/27) * Math.PI * 2)) < 1e-6,
      `twister = -418/27x drum (got ${gotRatio && gotRatio.t})`);
    check(gotRatio && Math.abs(gotRatio.lo - gotRatio.c) < 1e-9, 'roller rigid with crank (senses kept)');

    // New parts present.
    const hasCompound = await page.evaluate(() => !!window._partMeshes.intermediate_compound);
    const hasDriveShaft = await page.evaluate(() => !!window._partMeshes.drive_shaft);
    check(hasCompound, 'intermediate_compound part loaded');
    check(hasDriveShaft, 'drive_shaft part loaded');

    // Twister pivot position (v72: 186 root-local, world x=86 due to root offset).
    const twPos = await page.evaluate(() => {
      const v = new THREE.Vector3();
      window._pivots.twister.getWorldPosition(v);
      // Convert to root-local: subtract root position (-100, 0, 55)
      return [v.x + 100, v.y, v.z - 55];
    });
    console.log('twister root-local pos:', JSON.stringify(twPos));
    check(twPos[0] > 180 && twPos[0] < 195, `twister root-local x ~186 (got ${twPos[0]})`);

    // Tape-static regression (v45): ribbon stays centred while animating.
    await page.evaluate(() => { window._overrideAngle = 0.6; });
    await page.waitForTimeout(200);
    const tx0 = await page.evaluate(() => window._tapeFold.flat.position.x);
    await page.waitForTimeout(1200);
    const tx1 = await page.evaluate(() => window._tapeFold.flat.position.x);
    console.log(`tapeGroup.x frozen=${tx0} animating=${tx1}`);
    check(tx0 === tx1 && tx0 === 112, `tape ribbon STATIC, centred CAD span (got ${tx0}/${tx1})`);

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
    const twW = await page.evaluate(() => {
      const v = new THREE.Vector3();
      window._pivots.twister.getWorldPosition(v);
      return [v.x + 100, v.y, v.z - 55];
    });
    console.log('twister world:', JSON.stringify(twW));
    // 1) close-up of the twister bevel (chassis hidden).
    await shot('v72_twister_bevel_closeup.png',
      [twW[0] + 25, twW[1] + 20, twW[2] + 105],
      [twW[0], twW[1], twW[2] + 15],
      ['twister', 'intermediate_compound', 'drive_shaft'], 0.6);
    // 2) wide with compound + drive shaft.
    await shot('v72_gears_wide.png',
      [150, 80, 250],
      [156, 12, 57],
      ['chassis', 'intermediate_compound', 'drive_shaft', 'twister'], null);

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 52):', assetV);
    check(assetV === '52', 'ASSET_V 52 (v72 gear/GLB rebuild)');
    await page.close();

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await pool.releaseBrowser(browser);
  }
})();
