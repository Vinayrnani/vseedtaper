const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v20 verify: drum gear moved to BACK side (world Y~12, was Y~48).
// Shots: screenshots/v20_*.png (repo rule: screenshots/ only, max 25).
// Asserts: ready, 0 console errors, animation actually running
// (crank angle changes between two live frames), gear root-local mean
// z ~= -12 (back, offset +18 from drum pivot), drum body coaxial with
// pivot at 4 angles (mount recentered correctly), hopper bounds,
// crank orbit r~=45, drop x~=100.
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

    // Live animating preview: ensure override off so rAF animation runs.
    await page.evaluate(() => { window._overrideAngle = null; });
    await page.waitForTimeout(600);
    const a0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v20_anim_t0.png') });
    console.log('Shot screenshots/v20_anim_t0.png crankAngle=', a0);
    await page.waitForTimeout(900);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v20_anim_t1.png') });
    console.log('Shot screenshots/v20_anim_t1.png crankAngle=', a1);
    console.log('Animating (angle changed):', a0 !== a1);

    // Full assembly still shot while animating.
    await page.evaluate(() => {
      window._camera.position.set(300, 220, 300);
      window._controls.target.set(-20, 55, 40);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v20_full.png') });
    console.log('Shot screenshots/v20_full.png');

    // Back-side closeup on the drum gear (gear should sit behind drum).
    await page.evaluate(() => {
      const p = new THREE.Vector3();
      window._drumPivot.getWorldPosition(p);
      window._camera.position.set(p.x + 80, p.y + 50, p.z + 110);
      window._controls.target.copy(p);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v20_gear_back.png') });
    console.log('Shot screenshots/v20_gear_back.png');

    console.log('Console errors:', errors.length);
    errors.forEach(e => console.log('  ', e));

    // v20 gear-side + drum-coaxial checks (root-local frame).
    const gear = await page.evaluate(() => {
      const root = window._root;
      window._setRotations(0);
      root.updateWorldMatrix(true, true);
      const inv = root.matrixWorld.clone().invert();
      const dp = window._drumPivot.position; // (100,60,-30) root-local
      const v = new THREE.Vector3();
      let gz = 0, gn = 0, bx = 0, by = 0, bn = 0;
      (window._partMeshes.cartridge || []).forEach(o => o.updateWorldMatrix(true, true));
      (window._partMeshes.cartridge || []).forEach(function (obj) {
        obj.traverse(function (n) {
          if (!n.isMesh || !n.geometry || !n.geometry.attributes) return;
          const pos = n.geometry.attributes.position;
          for (let i = 0; i < pos.count; i += 2) {
            v.fromBufferAttribute(pos, i).applyMatrix4(n.matrixWorld).applyMatrix4(inv);
            const rad = Math.hypot(v.x - dp.x, v.y - dp.y);
            if (rad > 30) { gz += v.z; gn++; }       // gear teeth only (drum r25, flanges r26.5)
            else { bx += v.x; by += v.y; bn++; }     // drum body + hub
          }
        });
      });
      window._overrideAngle = null;
      return {
        gearMeanZ: +(gz / Math.max(1, gn)).toFixed(2), gearN: gn,
        bodyCX: +(bx / Math.max(1, bn)).toFixed(2), bodyCY: +(by / Math.max(1, bn)).toFixed(2),
        piv: [dp.x, dp.y, dp.z]
      };
    });
    const off = gear.gearMeanZ - gear.piv[2];
    console.log('gear root-local meanZ:', gear.gearMeanZ, '(n=' + gear.gearN + ') pivotZ:', gear.piv[2],
      'offset:', off.toFixed(2), '| BACK ok (offset>+10, meanZ~-12):', off > 10 && Math.abs(gear.gearMeanZ + 12) < 3);
    console.log('drum body centroid (expect ~100,60):', gear.bodyCX, gear.bodyCY,
      'coaxial ok:', Math.hypot(gear.bodyCX - 100, gear.bodyCY - 60) < 1.5);

    // Drum stays coaxial while spinning (mount recentered, no wobble).
    for (let i = 0; i < 4; i++) {
      const c = await page.evaluate((a) => {
        window._setRotations(a);
        window._root.updateWorldMatrix(true, true);
        const inv = window._root.matrixWorld.clone().invert();
        const dp = window._drumPivot.position;
        const v = new THREE.Vector3();
        let bx = 0, by = 0, bn = 0;
        (window._partMeshes.cartridge || []).forEach(function (obj) {
          obj.traverse(function (n) {
            if (!n.isMesh || !n.geometry || !n.geometry.attributes) return;
            const pos = n.geometry.attributes.position;
            for (let k = 0; k < pos.count; k += 5) {
              v.fromBufferAttribute(pos, k).applyMatrix4(n.matrixWorld).applyMatrix4(inv);
              if (Math.hypot(v.x - dp.x, v.y - dp.y) < 27) { bx += v.x; by += v.y; bn++; }
            }
          });
        });
        window._overrideAngle = null;
        return { dx: +(bx / bn - dp.x).toFixed(3), dy: +(by / bn - dp.y).toFixed(3) };
      }, i * 0.25 * Math.PI * 2);
      console.log(`  spin a=${i * 90}deg: off-axis=(${c.dx},${c.dy}) wobble=${Math.hypot(c.dx, c.dy).toFixed(3)}`);
    }

    const layout = await page.evaluate(() => {
      const out = {};
      const root = window._root;
      window._setRotations(0);
      root.updateWorldMatrix(true, true);
      const inv = root.matrixWorld.clone().invert();
      const bb = new THREE.Box3();
      window._partMeshes.hopper.forEach(o => bb.expandByObject(o));
      const loc = bb.clone().applyMatrix4(inv);
      out.hopperMinX = +loc.min.x.toFixed(2);
      out.hopperMaxX = +loc.max.x.toFixed(2);
      out.hopperMinY = +loc.min.y.toFixed(2);
      const cm = window._pivots.crankMount.position;
      out.crankMount = [cm.x, cm.y, cm.z];
      window._setRotations(0.7);
      root.updateWorldMatrix(true, true);
      const seeds = window._toggleGroups.seeds.objects;
      const drop = seeds[seeds.length - 1];
      const ds = new THREE.Vector3();
      drop.getWorldPosition(ds);
      ds.applyMatrix4(inv);
      out.dropSeed = [+ds.x.toFixed(2), +ds.y.toFixed(2), +ds.z.toFixed(2)];
      window._overrideAngle = null;
      return out;
    });
    console.log('hopper x:', layout.hopperMinX, '..', layout.hopperMaxX,
      '| LEFT ok:', layout.hopperMinX > 69 && layout.hopperMinX < 75,
      '| RIGHT ok:', layout.hopperMaxX > 180 && layout.hopperMaxX < 186);
    console.log('hopper minY (~30.5):', layout.hopperMinY, Math.abs(layout.hopperMinY - 30.5) < 1.5);
    console.log('crankMount LEFT (x<100):', layout.crankMount, layout.crankMount[0] < 100);
    console.log('dropSeed x~=100:', layout.dropSeed, Math.abs(layout.dropSeed[0] - 100) < 2);

    const radii = [];
    for (let i = 0; i < 4; i++) {
      const angle = i * 0.25 * Math.PI * 2;
      const q = await page.evaluate((a) => {
        window._setRotations(a);
        const THREE = window.THREE;
        const spinner = window._crankSpinner;
        spinner.updateWorldMatrix(true, true);
        const pts = [];
        spinner.traverse((n) => {
          if (n.isMesh && n.geometry && n.geometry.attributes) {
            const pos = n.geometry.attributes.position;
            const v = new THREE.Vector3();
            for (let i = 0; i < pos.count; i += 3) {
              v.fromBufferAttribute(pos, i).applyMatrix4(n.matrixWorld);
              const local = spinner.worldToLocal(v.clone());
              if (local.x > 30 && local.z < -12) pts.push([v.x, v.y, v.z]);
            }
          }
        });
        if (!pts.length) return null;
        const c = [0, 0, 0];
        pts.forEach(p => { c[0] += p[0]; c[1] += p[1]; c[2] += p[2]; });
        c[0] /= pts.length; c[1] /= pts.length; c[2] /= pts.length;
        const rl = [c[0] + 100, c[1], c[2] - 55];
        return { x: rl[0], y: -rl[2], z: rl[1], n: pts.length };
      }, angle);
      if (q) {
        const r = Math.hypot(q.x - 77.5, q.z - 60);
        radii.push(r);
        console.log(`  a=${i * 90}deg: radius=${r.toFixed(3)}`);
      } else { console.log(`  a=${i * 90}deg: NO GRIP FOUND`); }
      await page.waitForTimeout(150);
    }
    if (radii.length) {
      const avg = radii.reduce((a, b) => a + b, 0) / radii.length;
      console.log(`  crank avg=${avg.toFixed(3)} ok:${Math.abs(avg - 45) <= 1}`);
    }
    pruneShots();
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
