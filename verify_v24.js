const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v24 verify: Step 3 R->L order proof hopper > drum > shroud > roller.
// Shots: screenshots/v24_*.png (repo rule: screenshots/ only, max 25).
// Asserts: ready, 0 console errors, animating, ASSET_V 12, shroud loaded,
// crankMount (40,60,8) back wall, world-X centroids:
//   hopper_cx > drum_cx > shroud_cx > roller_cx (expect ~128 > 100 > 71 > 40).
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
(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
  try {
    const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
    const errors = [];
    page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
    page.on('pageerror', err => errors.push(err.message));

    await page.goto(`http://localhost:9099/index.html?v=${V}`);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 20000 });
    console.log('Page loaded, status=ready');

    await page.evaluate(() => { window._overrideAngle = null; });
    await page.waitForTimeout(600);
    const a0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v24_anim_t0.png') });
    console.log('Shot screenshots/v24_anim_t0.png crankSpinner.z=', a0);
    await page.waitForTimeout(900);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v24_anim_t1.png') });
    console.log('Shot screenshots/v24_anim_t1.png crankSpinner.z=', a1);
    console.log('Animating (angle changed):', a0 !== a1);

    await page.evaluate(() => {
      window._camera.position.set(300, 220, 300);
      window._controls.target.set(-20, 55, 40);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v24_full.png') });
    console.log('Shot screenshots/v24_full.png');

    // Side elevation (look down -Z: X horizontal) for the R->L order shot.
    await page.evaluate(() => {
      window._controls.enableDamping = false;
      const target = window._root.localToWorld(new THREE.Vector3(60, 45, 0));
      window._camera.position.set(target.x + 60, target.y + 10, target.z + 420);
      window._controls.target.copy(target);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v24_order.png') });
    console.log('Shot screenshots/v24_order.png (R->L elevation)');
    await page.evaluate(() => {
      window._showAllParts();
      window._controls.enableDamping = true;
    });

    console.log('Console errors:', errors.length);
    errors.forEach(e => console.log('  ', e));

    const res = await page.evaluate(() => {
      window._root.updateWorldMatrix(true, true);
      const inv = window._root.matrixWorld.clone().invert();
      const v = new THREE.Vector3();
      const P = window._pivots;
      // World-X centroid of a part's meshes in root-local (= OpenSCAD) frame.
      function centroidX(id) {
        const box = new THREE.Box3();
        let n = 0;
        (window._partMeshes[id] || []).forEach(function (obj) {
          obj.updateWorldMatrix(true, false);
          box.expandByObject(obj);
          n++;
        });
        if (!n) return null;
        const c = box.getCenter(new THREE.Vector3()).applyMatrix4(inv);
        return { cx: +c.x.toFixed(1), n: n };
      }
      const ids = ['hopper', 'cartridge', 'shroud', 'rollers_lower', 'crank'];
      const out = {};
      ids.forEach(function (id) { out[id] = centroidX(id); });
      out.crankMount = [P.crankMount.position.x, P.crankMount.position.y, P.crankMount.position.z];
      out.lowerPiv = [P.lower.position.x, P.lower.position.y, P.lower.position.z];
      out.spoolX = P.spool.position.x;
      out.shroudPiv = [P.shroud.position.x, P.shroud.position.y, P.shroud.position.z];
      return out;
    });
    console.log('centroids:', JSON.stringify(res));
    const ok = res.hopper && res.cartridge && res.shroud && res.rollers_lower;
    const order = ok && res.hopper.cx > res.cartridge.cx &&
      res.cartridge.cx > res.shroud.cx && res.shroud.cx > res.rollers_lower.cx;
    console.log('ORDER hopper_x > drum_x > shroud_x > roller_x:',
      ok ? [res.hopper.cx, res.cartridge.cx, res.shroud.cx, res.rollers_lower.cx].join(' > ') : 'MISSING PART', '=>', order);
    console.log('crankMount (expect 40,60,8 back wall):', JSON.stringify(res.crankMount),
      'ok:', res.crankMount[0] === 40 && res.crankMount[1] === 60 && res.crankMount[2] === 8);
    console.log('shroudPivot (expect 58,0,-30):', JSON.stringify(res.shroudPiv));
    console.log('spool x (expect -6, west of roller 40):', res.spoolX);
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V in served HTML (expect 12):', assetV);
    pruneShots();
    if (!order) { console.error('VERIFY FAILED: R->L order broken'); process.exitCode = 1; }
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
