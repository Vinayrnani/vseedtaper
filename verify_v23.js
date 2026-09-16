const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v23 verify: crank moved front wall (Y=68) -> back wall (Y=-8).
// Shots: screenshots/v23_*.png (repo rule: screenshots/ only, max 25).
// Asserts: ready, 0 console errors, animating, crankMount (40,60,8),
// crank grip on back side (scad Y<0, root-local Z>0 = opposite wall from
// v21 front crank at Z=-68), grip orbit r~=45 about (40,60) at 4 angles.
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
    await page.screenshot({ path: path.join(SHOT_DIR, 'v23_anim_t0.png') });
    console.log('Shot screenshots/v23_anim_t0.png crankSpinner.z=', a0);
    await page.waitForTimeout(900);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v23_anim_t1.png') });
    console.log('Shot screenshots/v23_anim_t1.png crankSpinner.z=', a1);
    console.log('Animating (angle changed):', a0 !== a1);

    await page.evaluate(() => {
      window._camera.position.set(300, 220, 300);
      window._controls.target.set(-20, 55, 40);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v23_full.png') });
    console.log('Shot screenshots/v23_full.png');

    // Crank closeup from the back side (root-local +Z = OpenSCAD -Y = back).
    await page.evaluate(() => {
      window._controls.enableDamping = false;
      const target = window._root.localToWorld(new THREE.Vector3(40, 55, 25));
      window._camera.position.set(target.x + 80, target.y + 70, target.z + 130);
      window._controls.target.copy(target);
      window._controls.update();
      return { cam: window._camera.position.toArray().map(z => Math.round(z)),
               tgt: window._controls.target.toArray().map(z => Math.round(z)) };
    }).then(r => console.log('crank cam/tgt:', JSON.stringify(r)));
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v23_crank.png') });
    console.log('Shot screenshots/v23_crank.png');
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
      const out = {
        crankMount: [P.crankMount.position.x, P.crankMount.position.y, P.crankMount.position.z],
        lowerPiv: [P.lower.position.x, P.lower.position.y, P.lower.position.z]
      };
      // Grip-tip orbit: most-negative scad-Y vertex of the crank meshes
      // (= grip far pole), radius in root-local X-Y about shaft axis (40,60).
      function tipAt(angle) {
        window._setRotations(angle);
        window._root.updateWorldMatrix(true, true);
        let best = null;
        (window._partMeshes['crank'] || []).forEach(function (obj) {
          obj.traverse(function (nd) {
            if (!nd.isMesh || !nd.geometry || !nd.geometry.attributes) return;
            const pos = nd.geometry.attributes.position;
            for (let i = 0; i < pos.count; i++) {
              v.fromBufferAttribute(pos, i).applyMatrix4(nd.matrixWorld).applyMatrix4(inv);
              const sy = -v.z; // root-local -> OpenSCAD Y
              if (best === null || sy < best.sy) best = { sy: sy, x: v.x, y: v.y, z: v.z };
            }
          });
        });
        return { r: +Math.hypot(best.x - 40, best.y - 60).toFixed(2),
                 sy: +best.sy.toFixed(1), z: +best.z.toFixed(1) };
      }
      out.tip0 = tipAt(0);
      out.tip90 = tipAt(Math.PI / 2);
      out.tip180 = tipAt(Math.PI);
      out.tip270 = tipAt(3 * Math.PI / 2);
      window._overrideAngle = null;
      return out;
    });
    console.log('crankMount (expect 40,60,8 = back wall):', JSON.stringify(res.crankMount));
    console.log('mount ok:', res.crankMount[0] === 40 && res.crankMount[1] === 60 && res.crankMount[2] === 8);
    console.log('grip tip t0/90/180/270:', JSON.stringify(res.tip0), JSON.stringify(res.tip90),
      JSON.stringify(res.tip180), JSON.stringify(res.tip270));
    const rs = [res.tip0.r, res.tip90.r, res.tip180.r, res.tip270.r];
    const spread = Math.max(...rs) - Math.min(...rs);
    console.log('orbit radii (expect ~=45 each):', rs.join(', '), 'spread:', spread.toFixed(2));
    console.log('orbit ok (all 37..53, spread<2):', rs.every(r => r > 37 && r < 53) && spread < 2);
    const backSide = [res.tip0, res.tip90, res.tip180, res.tip270].every(t => t.sy < 0 && t.z > 0);
    console.log('crank on BACK side (scad Y<0, root Z>0, opposite v21 front):', backSide);
    pruneShots();
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
