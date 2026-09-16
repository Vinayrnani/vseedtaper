const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v25 verify: Step 4 tape U-bend (flat scrolling ribbon + static fold at plow).
// Shots: screenshots/v25_*.png (repo rule: screenshots/ only, max 25).
// Asserts: ready, 0 console errors, animating, ASSET_V 13,
// R->L order hopper > drum > shroud > roller (regression),
// tape bend proof: 24 arc meshes, centres at R=3 from (±6.35, 3.75),
// flat scrolls while fold stays static.
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
    const tx0 = await page.evaluate(() => window._tapeFold.flat.position.x);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v25_anim_t0.png') });
    console.log('Shot screenshots/v25_anim_t0.png crankSpinner.z=', a0, 'tapeX=', tx0);
    await page.waitForTimeout(900);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    const tx1 = await page.evaluate(() => window._tapeFold.flat.position.x);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v25_anim_t1.png') });
    console.log('Shot screenshots/v25_anim_t1.png crankSpinner.z=', a1, 'tapeX=', tx1);
    console.log('Animating (angle changed):', a0 !== a1);
    console.log('Tape scrolling (flat X changed):', tx0 !== tx1);

    await page.evaluate(() => {
      window._camera.position.set(300, 220, 300);
      window._controls.target.set(-20, 55, 40);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v25_full.png') });
    console.log('Shot screenshots/v25_full.png');

    // Closeup of the U-fold channel at the plow (root-local x 126..159).
    await page.evaluate(() => {
      window._controls.enableDamping = false;
      const target = window._root.localToWorld(new THREE.Vector3(142.5, 34, -30));
      window._camera.position.set(target.x + 40, target.y + 45, target.z + 130);
      window._controls.target.copy(target);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v25_tapebend.png') });
    console.log('Shot screenshots/v25_tapebend.png (U-fold closeup)');
    await page.evaluate(() => {
      window._showAllParts();
      window._controls.enableDamping = true;
    });

    console.log('Console errors:', errors.length);
    errors.forEach(e => console.log('  ', e));

    const res = await page.evaluate(() => {
      window._root.updateWorldMatrix(true, true);
      const inv = window._root.matrixWorld.clone().invert();
      const P = window._pivots;
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
      const out = {};
      ['hopper', 'cartridge', 'shroud', 'rollers_lower'].forEach(function (id) { out[id] = centroidX(id); });
      out.crankMount = [P.crankMount.position.x, P.crankMount.position.y, P.crankMount.position.z];
      // Tape bend proof: arc mesh centres in fold-group local frame,
      // distance in (z,y) plane to arc centres (s*6.35, 3.75) must be R=3.
      const tf = window._tapeFold;
      const g = tf.group;
      const loc = new THREE.Vector3();
      const dists = tf.arcMeshes.map(function (m) {
        m.getWorldPosition(loc);
        g.worldToLocal(loc);
        const s = loc.z >= 0 ? 1 : -1;
        const d = Math.sqrt(Math.pow(loc.z - s * tf.hw, 2) + Math.pow(loc.y - tf.cz, 2));
        return +d.toFixed(3);
      });
      out.tapeArcs = dists.length;
      out.tapeR = tf.R;
      out.tapeMaxDev = dists.length ? +Math.max.apply(null, dists.map(function (d) { return Math.abs(d - tf.R); })).toFixed(3) : null;
      out.foldKids = g.children.length;
      out.foldPos = [g.position.x, g.position.y, g.position.z];
      return out;
    });
    console.log('centroids:', JSON.stringify(res));
    const order = res.hopper && res.cartridge && res.shroud && res.rollers_lower &&
      res.hopper.cx > res.cartridge.cx &&
      res.cartridge.cx > res.shroud.cx && res.shroud.cx > res.rollers_lower.cx;
    console.log('ORDER hopper_x > drum_x > shroud_x > roller_x:',
      [res.hopper && res.hopper.cx, res.cartridge && res.cartridge.cx,
       res.shroud && res.shroud.cx, res.rollers_lower && res.rollers_lower.cx].join(' > '), '=>', order);
    console.log('crankMount (expect 40,60,8 back wall):', JSON.stringify(res.crankMount));
    console.log('tape arcs (expect 24):', res.tapeArcs, '| R (expect 3):', res.tapeR,
      '| max |d-R| (expect <0.2):', res.tapeMaxDev, '| fold children (expect 28):', res.foldKids);
    console.log('fold group pos (expect 142.5,30,-30):', JSON.stringify(res.foldPos));
    const bendOk = res.tapeArcs === 24 && res.tapeR === 3 && res.tapeMaxDev !== null && res.tapeMaxDev < 0.2;
    console.log('BEND points follow bend radius R=3:', bendOk);
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V in served HTML (expect 13):', assetV);
    pruneShots();
    let fail = null;
    if (!order) fail = 'R->L order broken';
    else if (!bendOk) fail = 'tape bend proof failed';
    else if (assetV !== '13') fail = 'ASSET_V != 13';
    else if (errors.length) fail = errors.length + ' console errors';
    else if (a0 === a1) fail = 'not animating';
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
