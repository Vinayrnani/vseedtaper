const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v22 verify: R->L order hopper > drum > shroud > roller, spool graze fixed.
// Shots: screenshots/v22_*.png (repo rule: screenshots/ only, max 25).
// Asserts: ready, 0 console errors, animating, pivots (drum 100,
// lower/upper/crank 40, shroud 58, spool -4), mean-X order chain,
// spool cones Box3 disjoint from rollers_lower + cartridge.
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
    await page.screenshot({ path: path.join(SHOT_DIR, 'v22_anim_t0.png') });
    console.log('Shot screenshots/v22_anim_t0.png crankSpinner.z=', a0);
    await page.waitForTimeout(900);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v22_anim_t1.png') });
    console.log('Shot screenshots/v22_anim_t1.png crankSpinner.z=', a1);
    console.log('Animating (angle changed):', a0 !== a1);

    await page.evaluate(() => {
      window._camera.position.set(300, 220, 300);
      window._controls.target.set(-20, 55, 40);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v22_full.png') });
    console.log('Shot screenshots/v22_full.png');

    // Oblique aerial for R->L order reading (damping off so the shot
    // framing can't drift; camera read back + logged before each shot).
    // NOTE: a near-vertical top-down here rendered as a side view twice
    // (degenerate polar?), so use a 3/4 aerial instead.
    await page.evaluate(() => {
      window._controls.enableDamping = false;
      const target = window._root.localToWorld(new THREE.Vector3(70, 40, -30));
      window._camera.position.set(target.x + 140, target.y + 250, target.z + 170);
      window._controls.target.copy(target);
      window._controls.update();
      return { cam: window._camera.position.toArray().map(z => Math.round(z)),
               tgt: window._controls.target.toArray().map(z => Math.round(z)) };
    }).then(r => console.log('order cam/tgt:', JSON.stringify(r)));
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v22_order.png') });
    console.log('Shot screenshots/v22_order.png');

    // Shroud tunnel closeup: isolate shroud (walls hidden, no occlusion),
    // camera front-top-right in root-local terms.
    await page.evaluate(() => {
      window._setOnlyVisible(['shroud']);
      const target = window._root.localToWorld(new THREE.Vector3(71, 17, -30));
      window._camera.position.set(target.x + 60, target.y + 80, target.z - 110);
      window._controls.target.copy(target);
      window._controls.update();
      return { cam: window._camera.position.toArray().map(z => Math.round(z)),
               tgt: window._controls.target.toArray().map(z => Math.round(z)) };
    }).then(r => console.log('shroud cam/tgt:', JSON.stringify(r)));
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v22_shroud.png') });
    console.log('Shot screenshots/v22_shroud.png');

    // Spool vs roller-gear gap closeup: isolate cones + lower roller,
    // camera from the open west end above the gap.
    await page.evaluate(() => {
      window._setOnlyVisible(['cones_a', 'cones_b', 'rollers_lower']);
      window._setRotations(0);
      const target = window._root.localToWorld(new THREE.Vector3(26, 60, -20));
      window._camera.position.set(target.x - 110, target.y + 55, target.z - 25);
      window._controls.target.copy(target);
      window._controls.update();
      return { cam: window._camera.position.toArray().map(z => Math.round(z)),
               tgt: window._controls.target.toArray().map(z => Math.round(z)) };
    }).then(r => console.log('spool cam/tgt:', JSON.stringify(r)));
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v22_spool.png') });
    console.log('Shot screenshots/v22_spool.png');
    await page.evaluate(() => {
      window._showAllParts();
      window._controls.enableDamping = true;
    });

    console.log('Console errors:', errors.length);
    errors.forEach(e => console.log('  ', e));

    // Pivots + R->L mean-X order + spool clearance (all root-local).
    const res = await page.evaluate(() => {
      window._setRotations(0);
      window._root.updateWorldMatrix(true, true);
      const inv = window._root.matrixWorld.clone().invert();
      const shift = new THREE.Vector3(100, 0, -55); // world->root-local (root has no rotation)
      const v = new THREE.Vector3();
      function meanX(partId) {
        let sx = 0, n = 0;
        (window._partMeshes[partId] || []).forEach(function (obj) {
          obj.traverse(function (nd) {
            if (!nd.isMesh || !nd.geometry || !nd.geometry.attributes) return;
            const pos = nd.geometry.attributes.position;
            for (let i = 0; i < pos.count; i += 7) {
              v.fromBufferAttribute(pos, i).applyMatrix4(nd.matrixWorld).applyMatrix4(inv);
              sx += v.x; n++;
            }
          });
        });
        return { x: +(sx / Math.max(1, n)).toFixed(2), n: n };
      }
      function boxOf(ids) {
        // EXACT vertex min/max (NOT Box3.setFromObject: its non-precise path
        // rotates the AABB corners, inflating ±22.15 to ±25.34 under the 9°
        // gear phase and faking an overlap).
        const mn = [+1e9, +1e9, +1e9], mx = [-1e9, -1e9, -1e9];
        ids.forEach(function (id) {
          (window._partMeshes[id] || []).forEach(function (obj) {
            obj.traverse(function (nd) {
              if (!nd.isMesh || !nd.geometry || !nd.geometry.attributes) return;
              const pos = nd.geometry.attributes.position;
              for (let i = 0; i < pos.count; i++) {
                v.fromBufferAttribute(pos, i).applyMatrix4(nd.matrixWorld).applyMatrix4(inv);
                if (v.x < mn[0]) mn[0] = v.x; if (v.x > mx[0]) mx[0] = v.x;
                if (v.y < mn[1]) mn[1] = v.y; if (v.y > mx[1]) mx[1] = v.y;
                if (v.z < mn[2]) mn[2] = v.z; if (v.z > mx[2]) mx[2] = v.z;
              }
            });
          });
        });
        const f = a => a.map(z => +z.toFixed(2));
        return { min: f(mn), max: f(mx),
                 _box: { min: { x: mn[0], y: mn[1], z: mn[2] }, max: { x: mx[0], y: mx[1], z: mx[2] } } };
      }
      function gap3(a, b) {
        const dx = Math.max(0, Math.max(a.min.x - b.max.x, b.min.x - a.max.x));
        const dy = Math.max(0, Math.max(a.min.y - b.max.y, b.min.y - a.max.y));
        const dz = Math.max(0, Math.max(a.min.z - b.max.z, b.min.z - a.max.z));
        return { dx: +dx.toFixed(2), dy: +dy.toFixed(2), dz: +dz.toFixed(2),
                 d: +Math.hypot(dx, dy, dz).toFixed(2), hit: dx === 0 && dy === 0 && dz === 0 };
      }
      const P = window._pivots;
      const out = {
        drumPiv: [P.drum.position.x, P.drum.position.y, P.drum.position.z],
        lowerPiv: [P.lower.position.x, P.lower.position.y, P.lower.position.z],
        crankMount: [P.crankMount.position.x, P.crankMount.position.y, P.crankMount.position.z],
        shroudPiv: [P.shroud.position.x, P.shroud.position.y, P.shroud.position.z],
        spoolPiv: [P.spool.position.x, P.spool.position.y, P.spool.position.z],
        order: {
          hopper: meanX('hopper'), cartridge: meanX('cartridge'),
          shroud: meanX('shroud'), roller: meanX('rollers_lower')
        }
      };
      const spoolB = boxOf(['cones_a', 'cones_b']);
      const rollerB = boxOf(['rollers_lower']);
      const drumB = boxOf(['cartridge']);
      const shroudB = boxOf(['shroud']);
      out.spoolBox = [spoolB.min, spoolB.max];
      out.shroudBox = [shroudB.min, shroudB.max];
      out.spoolVsRoller = gap3(spoolB._box, rollerB._box);
      out.spoolVsDrum = gap3(spoolB._box, drumB._box);
      window._overrideAngle = null;
      return out;
    });
    console.log('pivots drum/lower/crank/shroud/spool:', JSON.stringify(res.drumPiv), JSON.stringify(res.lowerPiv),
      JSON.stringify(res.crankMount), JSON.stringify(res.shroudPiv), JSON.stringify(res.spoolPiv));
    console.log('pivots ok (drum100/roller40/crank40/shroud58/spool-6):',
      res.drumPiv[0] === 100 && res.lowerPiv[0] === 40 && res.crankMount[0] === 40 &&
      res.shroudPiv[0] === 58 && res.spoolPiv[0] === -6);
    const o = res.order;
    console.log('mean-X hopper/drum/shroud/roller:', o.hopper.x, o.cartridge.x, o.shroud.x, o.roller.x);
    const orderOk = o.hopper.x > o.cartridge.x && o.cartridge.x > o.shroud.x && o.shroud.x > o.roller.x;
    console.log('R->L ORDER (hopper > drum > shroud > roller):', orderOk);
    console.log('spool box (root-local):', JSON.stringify(res.spoolBox));
    console.log('shroud box (root-local):', JSON.stringify(res.shroudBox));
    console.log('spool vs rollers_lower gap:', JSON.stringify(res.spoolVsRoller), 'CLEAR:', !res.spoolVsRoller.hit);
    console.log('spool vs cartridge gap:', JSON.stringify(res.spoolVsDrum), 'CLEAR:', !res.spoolVsDrum.hit);
    pruneShots();
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
