const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');
const SHOT_DIR = path.join(__dirname, 'screenshots');
fs.mkdirSync(SHOT_DIR, { recursive: true });
(function prune() {
  const files = fs.readdirSync(SHOT_DIR).filter(f => f.endsWith('.png'))
    .map(f => ({ f, m: fs.statSync(path.join(SHOT_DIR, f)).mtimeMs })).sort((a, b) => a.m - b.m);
  while (files.length > 15) {
    const o = files.shift();
    fs.unlinkSync(path.join(SHOT_DIR, o.f));
    console.log('Pruned:', o.f);
  }
})();
const V = Date.now();
const failures = [];
function check(cond, msg) {
  console.log((cond ? 'PASS ' : 'FAIL ') + msg);
  if (!cond) failures.push(msg);
}
(async () => {
  const bp = await pool.newPage({ width: 1600, height: 1000 });
  const browser = bp.browser, page = bp.page;
  try {
    const errors = [];
    page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
    page.on('pageerror', err => errors.push(err.message));
    await page.goto('http://localhost:9099/index.html?v=' + V);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 30000 });
    console.log('status=ready');
    await page.evaluate(() => { window._overrideAngle = null; window._showAllParts(); });
    await page.waitForTimeout(400);
    const a0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.waitForTimeout(700);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    check(a0 !== a1, 'animating crankSpinner ' + a0.toFixed(3) + ' -> ' + a1.toFixed(3));
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V:', assetV);
    check(assetV === '60', 'ASSET_V=60 got ' + assetV);
    const parts = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const rp = new THREE.Vector3(); window._root.getWorldPosition(rp);
      const out = { root: [+rp.x.toFixed(1), +rp.y.toFixed(1), +rp.z.toFixed(1)] };
      ['gear_ring', 'gear_drum', 'gear_shaft_a', 'gear_shaft_b', 'gear_shaft_c', 'gear_shaft_d', 'gear_shaft_e', 'gear_pinion', 'chassis', 'cartridge'].forEach(id => {
        const bb = new THREE.Box3();
        const arr = window._partMeshes[id] || [];
        let n = 0, v = 0;
        arr.forEach(s => s.traverse(o => { if (o.isMesh) { n++; v += o.geometry.attributes.position.count; bb.expandByObject(o); } }));
        const c = bb.getCenter(new THREE.Vector3()).sub(rp);
        const sz = bb.getSize(new THREE.Vector3());
        out[id] = { scenes: arr.length, meshes: n, verts: v,
          world: [+c.x.toFixed(1), +c.y.toFixed(1), +c.z.toFixed(1)],
          size: [+sz.x.toFixed(1), +sz.y.toFixed(1), +sz.z.toFixed(1)] };
      });
      const pv = {};
      ['gearDrum', 'gearA', 'gearB', 'gearC', 'gearD', 'gearE', 'gearPinion', 'gearRing', 'drum', 'twister'].forEach(k => {
        const p = new THREE.Vector3(); window._pivots[k].getWorldPosition(p).sub(rp);
        pv[k] = [+p.x.toFixed(1), +p.y.toFixed(1), +p.z.toFixed(1)];
      });
      out.pivots = pv;
      return out;
    });
    console.log('PARTS ' + JSON.stringify(parts));
    ['gear_ring', 'gear_drum', 'gear_shaft_a', 'gear_shaft_b', 'gear_shaft_c', 'gear_shaft_d', 'gear_shaft_e', 'gear_pinion'].forEach(id => {
      check(parts[id].scenes > 0 && parts[id].verts > 100, id + ' renders verts=' + parts[id].verts);
    });
    // Pivot positions (M-frame): OpenSCAD (x,y,z) -> (x,z,-y)
    function pivotCheck(k, want) {
      const got = parts.pivots[k];
      const ok = got.length === want.length && want.every((w, i) => Math.abs(got[i] - w) < 0.15);
      check(ok, k + ' pivot ' + JSON.stringify(want) + ' got ' + JSON.stringify(got));
    }
    pivotCheck('gearDrum', [100, 60, -14.05]);
    pivotCheck('gearA', [155, 60, -32]);
    pivotCheck('gearB', [135.5, 59.79, -32]);
    pivotCheck('gearC', [125.5, 43.04, -32]);
    pivotCheck('gearD', [145, 43.04, -32]);
    pivotCheck('gearE', [145, 25.04, -32]);
    pivotCheck('gearPinion', [149.5, 25.04, -49.4]);
    pivotCheck('gearRing', [173, 17, -30]);
    // Ring bbox centre root-local ~171.5 (pivot 173 minus crown-west offset)
    check(parts.gear_ring.world[0] > 170 && parts.gear_ring.world[0] < 173, 'ring root-local x~171.5 got ' + parts.gear_ring.world[0]);
    // Shaft A bbox centre root-local ~ (155,60,-32); rod along viewer -Z (OpenSCAD Y)
    check(parts.gear_shaft_a.world[0] > 154 && parts.gear_shaft_a.world[0] < 156, 'shaftA root-local x~155 got ' + parts.gear_shaft_a.world[0]);
    async function rots(ang) {
      await page.evaluate(a => { window._overrideAngle = a; }, ang);
      await page.waitForTimeout(350);
      return await page.evaluate(() => {
        window._root.updateMatrixWorld(true);
        return {
          drum: window._pivots.drum.rotation.z,
          gd: window._pivots.gearDrum.rotation.z,
          a: window._pivots.gearA.rotation.z,
          b: window._pivots.gearB.rotation.z,
          c: window._pivots.gearC.rotation.z,
          d: window._pivots.gearD.rotation.z,
          e: window._pivots.gearE.rotation.z,
          pin: window._pivots.gearPinion.rotation.x,
          ring: window._pivots.gearRing.rotation.x
        };
      });
    }
    const r0 = await rots(0), r1 = await rots(Math.PI);
    const dD = r1.drum - r0.drum;
    const dA = r1.a - r0.a, dB = r1.b - r0.b, dC = r1.c - r0.c, dDg = r1.d - r0.d, dE = r1.e - r0.e, dP = r1.pin - r0.pin, dR = r1.ring - r0.ring;
    console.log('DELTAS drum=' + dD.toFixed(4) + ' A=' + dA.toFixed(4) + ' B=' + dB.toFixed(4) + ' C=' + dC.toFixed(4) + ' D=' + dDg.toFixed(4) + ' E=' + dE.toFixed(4) + ' pin=' + dP.toFixed(4) + ' ring=' + dR.toFixed(4));
    function ratio(dx, want) { return Math.abs(Math.abs(dx / dD) - want) / want < 0.03; }
    check(ratio(dA, 4.0), 'A ratio 4.0 got ' + (dA / dD).toFixed(3));
    check(ratio(dB, 6.4), 'B ratio 6.4 got ' + (dB / dD).toFixed(3));
    check(ratio(dC, 10.24), 'C ratio 10.24 got ' + (dC / dD).toFixed(3));
    check(ratio(dDg, 16.384), 'D ratio 16.384 got ' + (dDg / dD).toFixed(3));
    check(ratio(dE, 22.94), 'E ratio 22.94 got ' + (dE / dD).toFixed(3));
    check(ratio(dP, 22.94), 'pinion ratio 22.94 got ' + (dP / dD).toFixed(3));
    check(ratio(dR, 17.2032), 'ring ratio 17.2032 got ' + (dR / dD).toFixed(3));
    check(dA * dD > 0, 'A same dir as drum');
    check(dB * dD < 0, 'B opposite drum');
    check(dC * dD > 0, 'C same dir as drum');
    check(dDg * dD < 0, 'D opposite drum');
    check(dE * dD > 0, 'E same dir as drum');
    check(dP * dD < 0, 'pinion opposite drum');
    check(dR * dD > 0, 'ring same dir as drum');
    await page.evaluate(() => { window._overrideAngle = null; });
    await page.waitForTimeout(200);
    await page.evaluate(() => window._setPanelCollapsed(true));
    const WP = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      function centre(id) {
        const bb = new THREE.Box3();
        (window._partMeshes[id] || []).forEach(s => s.traverse(o => { if (o.isMesh) bb.expandByObject(o); }));
        const c = bb.getCenter(new THREE.Vector3()); return [c.x, c.y, c.z];
      }
      return { ring: centre('gear_ring'), pin: centre('gear_pinion'), ch: centre('chassis'), a: centre('gear_shaft_a'), e: centre('gear_shaft_e') };
    });
    async function shot(f, cam, tgt, only, ang) {
      await page.evaluate(o => { if (o) window._setOnlyVisible(o); else window._showAllParts(); }, only || null);
      if (ang === null || ang === undefined) await page.evaluate(() => { window._overrideAngle = null; });
      else await page.evaluate(a => { window._overrideAngle = a; }, ang);
      await page.evaluate(ct => { window._camera.position.set(ct[0][0], ct[0][1], ct[0][2]); window._controls.target.set(ct[1][0], ct[1][1], ct[1][2]); window._controls.update(); }, [cam, tgt]);
      await page.waitForTimeout(450);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      console.log('Shot: ' + f);
    }
    const R = WP.ring, CH = WP.ch;
    await shot('rv75_full.png', [CH[0] - 300, CH[1] + 170, CH[2] + 300], CH, null, null);
    await shot('rv75_geartrain.png', [CH[0] - 60, CH[1] + 260, CH[2] + 120], [CH[0] + 40, CH[1] + 20, CH[2] - 20], null, null);
    await shot('rv75_ring_east.png', [R[0] + 95, R[1] + 18, R[2] + 35], R, ['gear_ring', 'gear_pinion'], 0.6);
    await shot('rv75_ring_west.png', [R[0] - 90, R[1] - 30, R[2] + 70], R, ['gear_ring', 'gear_pinion'], 2.2);
    await shot('rv75_pinion_mesh.png', [R[0] + 60, R[1] - 30, R[2] + 110], R, ['gear_ring', 'gear_pinion'], 0.6);
    await shot('rv75_anim_t0.png', [CH[0] - 300, CH[1] + 170, CH[2] + 300], CH, null, 0);
    await shot('rv75_anim_t1.png', [CH[0] - 300, CH[1] + 170, CH[2] + 300], CH, null, Math.PI);
    console.log('errors: ' + errors.length);
    errors.forEach(e => console.log('   ' + e));
    check(errors.length === 0, '0 console errors');
    await page.close();
    if (failures.length) { console.error('VERIFY FAILED(' + failures.length + '):'); failures.forEach(f => console.error(' - ' + f)); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await pool.releaseBrowser(browser);
  }
})();