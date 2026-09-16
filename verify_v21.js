const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v21 verify: crank + roller moved WEST (x=40), gears meshed back-side (Y~12).
// Shots: screenshots/v21_*.png (repo rule: screenshots/ only, max 25).
// Asserts: ready, 0 console errors, animating, pivots at x=40, center dist 60,
// gear planes both root-local z~-12, tooth-gap phase (roller gap at 0deg,
// drum tooth at 180deg), crank orbit r~=45 about (40,60).
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
    await page.screenshot({ path: path.join(SHOT_DIR, 'v21_anim_t0.png') });
    console.log('Shot screenshots/v21_anim_t0.png crankSpinner.z=', a0);
    await page.waitForTimeout(900);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v21_anim_t1.png') });
    console.log('Shot screenshots/v21_anim_t1.png crankSpinner.z=', a1);
    console.log('Animating (angle changed):', a0 !== a1);

    await page.evaluate(() => {
      window._camera.position.set(300, 220, 300);
      window._controls.target.set(-20, 55, 40);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v21_full.png') });
    console.log('Shot screenshots/v21_full.png');

    // Mesh closeup: isolate the two gears (walls occlude them otherwise),
    // camera behind the mesh point looking at the tooth-into-gap contact.
    await page.evaluate(() => {
      window._setOnlyVisible(['cartridge', 'rollers_lower']);
      window._overrideAngle = 0;
      window._setRotations(0);
      const target = window._root.localToWorld(new THREE.Vector3(70, 60, -12));
      window._camera.position.set(target.x - 10, target.y + 55, target.z + 130);
      window._controls.target.copy(target);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v21_mesh.png') });
    console.log('Shot screenshots/v21_mesh.png');

    // Crank-side view: crank outside the front wall at roller axle x=40.
    await page.evaluate(() => {
      window._showAllParts();
      window._overrideAngle = null;
      const target = window._root.localToWorld(new THREE.Vector3(40, 45, -68));
      window._camera.position.set(target.x - 70, target.y + 70, target.z - 130);
      window._controls.target.copy(target);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v21_crank.png') });
    console.log('Shot screenshots/v21_crank.png');

    console.log('Console errors:', errors.length);
    errors.forEach(e => console.log('  ', e));

    // Pivots + center distance + gear planes (root-local).
    const mesh = await page.evaluate(() => {
      window._setRotations(0);
      window._root.updateWorldMatrix(true, true);
      const inv = window._root.matrixWorld.clone().invert();
      const v = new THREE.Vector3();
      function gearMeanZ(partId, piv, minRad) {
        let gz = 0, gn = 0;
        (window._partMeshes[partId] || []).forEach(function (obj) {
          obj.traverse(function (n) {
            if (!n.isMesh || !n.geometry || !n.geometry.attributes) return;
            const pos = n.geometry.attributes.position;
            for (let i = 0; i < pos.count; i += 2) {
              v.fromBufferAttribute(pos, i).applyMatrix4(n.matrixWorld).applyMatrix4(inv);
              if (Math.hypot(v.x - piv.x, v.y - piv.y) > minRad) { gz += v.z; gn++; }
            }
          });
        });
        return { meanZ: gz / Math.max(1, gn), n: gn };
      }
      const dp = window._drumPivot.position, lp = window._pivots.lower.position,
        up = window._pivots.upper.position, cm = window._pivots.crankMount.position;
      const dg = gearMeanZ('cartridge', dp, 30);
      const rg = gearMeanZ('rollers_lower', lp, 13);
      window._overrideAngle = null;
      return {
        drumPiv: [dp.x, dp.y, dp.z], lowerPiv: [lp.x, lp.y, lp.z],
        upperPiv: [up.x, up.y, up.z], crankMount: [cm.x, cm.y, cm.z],
        drumGearZ: +dg.meanZ.toFixed(2), drumGearN: dg.n,
        rollerGearZ: +rg.meanZ.toFixed(2), rollerGearN: rg.n
      };
    });
    const dist = Math.hypot(mesh.drumPiv[0] - mesh.lowerPiv[0], mesh.drumPiv[1] - mesh.lowerPiv[1]);
    console.log('pivots drum/lower/upper/crank:', JSON.stringify(mesh.drumPiv), JSON.stringify(mesh.lowerPiv),
      JSON.stringify(mesh.upperPiv), JSON.stringify(mesh.crankMount));
    console.log('pivots at x=40:', mesh.lowerPiv[0] === 40 && mesh.upperPiv[0] === 40 && mesh.crankMount[0] === 40);
    console.log('center distance (expect 60):', dist.toFixed(2), Math.abs(dist - 60) < 0.01);
    console.log('drum gear plane z (expect ~-12):', mesh.drumGearZ, Math.abs(mesh.drumGearZ + 12) < 2);
    console.log('roller gear plane z (expect ~-12):', mesh.rollerGearZ, Math.abs(mesh.rollerGearZ + 12) < 2);
    console.log('planes coaxial (diff<1):', Math.abs(mesh.drumGearZ - mesh.rollerGearZ).toFixed(2),
      Math.abs(mesh.drumGearZ - mesh.rollerGearZ) < 1);

    // Tooth-gap phase: roller must show a GAP toward the drum (+X = 0deg),
    // drum must show a TOOTH toward the roller (-X = 180deg).
    const phase = await page.evaluate(() => {
      window._setRotations(0);
      window._root.updateWorldMatrix(true, true);
      const inv = window._root.matrixWorld.clone().invert();
      const v = new THREE.Vector3();
      function tipAngles(partId, piv, minRad) {
        const angs = [];
        (window._partMeshes[partId] || []).forEach(function (obj) {
          obj.traverse(function (n) {
            if (!n.isMesh || !n.geometry || !n.geometry.attributes) return;
            const pos = n.geometry.attributes.position;
            for (let i = 0; i < pos.count; i += 2) {
              v.fromBufferAttribute(pos, i).applyMatrix4(n.matrixWorld).applyMatrix4(inv);
              const dx = v.x - piv.x, dy = v.y - piv.y;
              if (Math.hypot(dx, dy) > minRad) {
                let a = Math.atan2(dy, dx) * 180 / Math.PI;
                angs.push(a);
              }
            }
          });
        });
        return angs;
      }
      const dp = window._drumPivot.position, lp = window._pivots.lower.position;
      const rAngs = tipAngles('rollers_lower', lp, 19);   // roller tip r22/root 17.5
      const dAngs = tipAngles('cartridge', dp, 39);       // drum tip r42/root 37.5
      let rMin = 180;
      rAngs.forEach(a => { rMin = Math.min(rMin, Math.abs(a)); });
      let dMin = 180;
      dAngs.forEach(a => { dMin = Math.min(dMin, 180 - Math.abs(a)); });
      const lz = window._pivots.lower.rotation.z;
      window._overrideAngle = null;
      return { rMin: +rMin.toFixed(2), rN: rAngs.length, dMin: +dMin.toFixed(2), dN: dAngs.length, lowerRz: +lz.toFixed(4) };
    });
    console.log('roller phase offset at angle 0 (expect -9deg):', (phase.lowerRz * 180 / Math.PI).toFixed(2));
    console.log('roller min|angle| of tips (gap at 0 -> expect ~5, range 2.5..16):', phase.rMin, 'n=' + phase.rN,
      phase.rMin > 2.5 && phase.rMin < 16);
    console.log('drum min dist to 180deg (tooth at 180 -> expect <6):', phase.dMin, 'n=' + phase.dN, phase.dMin < 6);

    // Crank orbit about roller axis (scad coords, axis x=40 z=60).
    const radii = [];
    for (let i = 0; i < 4; i++) {
      const angle = i * 0.25 * Math.PI * 2;
      const q = await page.evaluate((a) => {
        window._setRotations(a);
        window._root.updateWorldMatrix(true, true);
        const inv = window._root.matrixWorld.clone().invert();
        const rp = window._root.position;
        const v = new THREE.Vector3();
        let sx = 0, sz = 0, n = 0;
        window._crankSpinner.traverse((node) => {
          if (!node.isMesh || !node.geometry || !node.geometry.attributes) return;
          const pos = node.geometry.attributes.position;
          for (let k = 0; k < pos.count; k += 2) {
            v.fromBufferAttribute(pos, k).applyMatrix4(node.matrixWorld).applyMatrix4(inv);
            const scx = v.x, scz = v.y; // root-local (x,y) == scad (x,z)
            if (Math.hypot(scx - 40, scz - 60) > 35) { sx += scx; sz += scz; n++; }
          }
        });
        window._overrideAngle = null;
        if (!n) return null;
        return { x: sx / n, z: sz / n, n: n };
      }, angle);
      if (q) {
        const r = Math.hypot(q.x - 40, q.z - 60);
        radii.push(r);
        console.log(`  a=${i * 90}deg: grip centroid=(${q.x.toFixed(1)},${q.z.toFixed(1)}) radius=${r.toFixed(3)}`);
      } else { console.log(`  a=${i * 90}deg: NO GRIP FOUND`); }
      await page.waitForTimeout(150);
    }
    if (radii.length) {
      const avg = radii.reduce((a, b) => a + b, 0) / radii.length;
      const spread = Math.max(...radii) - Math.min(...radii);
      console.log(`  crank avg=${avg.toFixed(3)} (expect ~45) spread=${spread.toFixed(3)} ok:${Math.abs(avg - 45) < 5 && spread < 3}`);
    }
    pruneShots();
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
