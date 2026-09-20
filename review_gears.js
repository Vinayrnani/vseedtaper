const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');
// GEAR-TRAIN visual review (brutally critical): many angles, orientation + mesh checks.
const SHOT_DIR = path.join(__dirname, 'screenshots');
fs.mkdirSync(SHOT_DIR, { recursive: true });
(function prune() {
  const files = fs.readdirSync(SHOT_DIR).filter(f => f.endsWith('.png'))
    .map(f => ({ f, m: fs.statSync(path.join(SHOT_DIR, f)).mtimeMs })).sort((a, b) => a.m - b.m);
  while (files.length > 12) {
    const o = files.shift();
    fs.unlinkSync(path.join(SHOT_DIR, o.f));
    console.log('Pruned:', o.f);
  }
})();
const V = Date.now();
let fail = null;
function check(cond, msg) {
  console.log((cond ? 'PASS ' : 'FAIL ') + msg);
  if (cond === false && fail === null) fail = msg;
}
(async () => {
  const { browser, page } = await pool.newPage({ width: 1600, height: 1000 });
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
    check(a0 !== a1, 'animating (crankSpinner rotates)');
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V:', assetV);
    // A. world bbox per gear part -> thin axis ~ axle direction
    const geo = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const out = {};
      ['cartridge', 'intermediate_compound', 'drive_shaft', 'twister', 'chassis'].forEach(id => {
        const bb = new THREE.Box3();
        const arr = window._partMeshes[id] || [];
        let n = 0;
        arr.forEach(s => s.traverse(o => { if (o.isMesh) { n++; bb.expandByObject(o); } }));
        const c = bb.getCenter(new THREE.Vector3());
        const sz = bb.getSize(new THREE.Vector3());
        out[id] = { meshes: n,
          worldC: [+c.x.toFixed(1), +c.y.toFixed(1), +c.z.toFixed(1)],
          worldSize: [+sz.x.toFixed(1), +sz.y.toFixed(1), +sz.z.toFixed(1)],
          rootLocalC: [+(c.x + 100).toFixed(1), +(55 - c.z).toFixed(1), +c.y.toFixed(1)] };
      });
      const dw = new THREE.Vector3(); window._pivots.drum.getWorldPosition(dw);
      const rw = new THREE.Vector3(); window._pivots.twister.getWorldPosition(rw);
      out._drumPivotW = [+dw.x.toFixed(1), +dw.y.toFixed(1), +dw.z.toFixed(1)];
      out._ringPivotW = [+rw.x.toFixed(1), +rw.y.toFixed(1), +rw.z.toFixed(1)];
      return out;
    });
    console.log('GEO ' + JSON.stringify(geo, null, 1));
    function thinAxis(sz) {
      const labels = ['X', 'Y', 'Z'];
      let m = 0;
      for (let i = 1; i < 3; i++) if (sz[i] < sz[m]) m = i;
      return labels[m];
    }
    console.log('thin axes: compound=' + thinAxis(geo.intermediate_compound.worldSize) +
      ' shaft=' + thinAxis(geo.drive_shaft.worldSize) +
      ' twister=' + thinAxis(geo.twister.worldSize));
    // spur gears must share parallel axles: compound thin axis vs shaft thin axis
    check(thinAxis(geo.intermediate_compound.worldSize) === thinAxis(geo.drive_shaft.worldSize),
      'compound + shaft spur axles parallel (thin ' + thinAxis(geo.intermediate_compound.worldSize) +
      ' vs ' + thinAxis(geo.drive_shaft.worldSize) + ')');
    // chain straightness in root-local: drum pivot -> compound -> shaft -> ring pivot
    const chain = await page.evaluate(() => {
      function rl(v) { return [v.x + 100, 55 - v.z, v.y]; }
      window._root.updateMatrixWorld(true);
      function bbC(id) {
        const bb = new THREE.Box3();
        (window._partMeshes[id] || []).forEach(s => s.traverse(o => { if (o.isMesh) bb.expandByObject(o); }));
        return rl(bb.getCenter(new THREE.Vector3()));
      }
      const dp = new THREE.Vector3(); window._pivots.drum.getWorldPosition(dp);
      const rp = new THREE.Vector3(); window._pivots.twister.getWorldPosition(rp);
      const D = rl(dp), C = bbC('intermediate_compound'), S = bbC('drive_shaft'), R = rl(rp);
      function d(a, b) { return Math.hypot(a[0] - b[0], a[1] - b[1], a[2] - b[2]); }
      function ang(a, b, c) { // angle ABC in degrees
        const v1 = [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
        const v2 = [c[0] - b[0], c[1] - b[1], c[2] - b[2]];
        const dot = v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2];
        const n = Math.hypot(...v1) * Math.hypot(...v2);
        return +(Math.acos(Math.max(-1, Math.min(1, dot / n))) * 180 / Math.PI).toFixed(1);
      }
      return { D, C, S, R,
        dDC: +d(D, C).toFixed(2), dCS: +d(C, S).toFixed(2),
        kinkAtC: ang(D, C, S), kinkAtS: ang(C, S, R),
        ySpread: +Math.max(D[1], C[1], S[1], R[1]).toFixed(1) - +Math.min(D[1], C[1], S[1], R[1]).toFixed(1) };
    });
    console.log('CHAIN ' + JSON.stringify(chain));
    check(Math.abs(chain.dDC - 56.08) < 6, 'drum->compound mesh dist ~56.08, got ' + chain.dDC);
    check(Math.abs(chain.dCS - 50) < 6, 'compound->shaft mesh dist ~50, got ' + chain.dCS);
    check(chain.kinkAtC > 150, 'chain straight at compound (angle>150deg), got ' + chain.kinkAtC);
    // B. FROZEN test: do compound + shaft roll with the crank? (expect rotation delta > 0)
    async function snapState(ang) {
      await page.evaluate(a => { window._overrideAngle = a; }, ang);
      await page.waitForTimeout(350);
      return await page.evaluate(() => {
        window._root.updateMatrixWorld(true);
        function wq(arr) {
          const q = new THREE.Quaternion();
          arr[0].getWorldQuaternion(q);
          return [+q.x.toFixed(4), +q.y.toFixed(4), +q.z.toFixed(4), +q.w.toFixed(4)];
        }
        return {
          crank: +window._crankSpinner.rotation.z.toFixed(4),
          drum: +window._pivots.drum.rotation.z.toFixed(4),
          ring: +window._pivots.twister.rotation.x.toFixed(4),
          compQ: wq(window._partMeshes.intermediate_compound),
          shaftQ: wq(window._partMeshes.drive_shaft)
        };
      });
    }
    const s0 = await snapState(0);
    const s1 = await snapState(Math.PI);
    console.log('ROT t0 ' + JSON.stringify(s0));
    console.log('ROT t1 ' + JSON.stringify(s1));
    function qd(a, b) { // quaternion angular distance in degrees
      const dot = Math.abs(a[0]*b[0] + a[1]*b[1] + a[2]*b[2] + a[3]*b[3]);
      return +(2 * Math.acos(Math.min(1, dot)) * 180 / Math.PI).toFixed(2);
    }
    console.log('dCrank=' + Math.abs(s1.crank - s0.crank).toFixed(3) +
      ' dDrum=' + Math.abs(s1.drum - s0.drum).toFixed(3) +
      ' dRing=' + Math.abs(s1.ring - s0.ring).toFixed(3) +
      ' dComp=' + qd(s0.compQ, s1.compQ) + 'deg' +
      ' dShaft=' + qd(s0.shaftQ, s1.shaftQ) + 'deg');
    check(qd(s0.compQ, s1.compQ) > 5, 'compound ROLLS with crank (moved ' + qd(s0.compQ, s1.compQ) + 'deg over half crank rev)');
    check(qd(s0.shaftQ, s1.shaftQ) > 5, 'shaft ROLLS with crank (moved ' + qd(s0.shaftQ, s1.shaftQ) + 'deg over half crank rev)');
    // C. screenshots from MANY angles
    await page.evaluate(() => window._setPanelCollapsed(true));
    await page.evaluate(() => { (window._root.parent || window._root).traverse(o => { if (o.isLine) o.visible = false; }); });
    const WP = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      function centre(id) {
        const bb = new THREE.Box3();
        (window._partMeshes[id] || []).forEach(s => s.traverse(o => { if (o.isMesh) bb.expandByObject(o); }));
        const c = bb.getCenter(new THREE.Vector3());
        return [c.x, c.y, c.z];
      }
      const dp = new THREE.Vector3(); window._pivots.drum.getWorldPosition(dp);
      return { drum: [dp.x, dp.y, dp.z], comp: centre('intermediate_compound'),
        shaft: centre('drive_shaft'), twist: centre('twister'), ch: centre('chassis') };
    });
    console.log('WORLDC ' + JSON.stringify(WP));
    async function shot(f, cam, tgt, only, ang) {
      await page.evaluate(o => { if (o) window._setOnlyVisible(o); else window._showAllParts(); }, only || null);
      if (ang === null || ang === undefined) await page.evaluate(() => { window._overrideAngle = null; });
      else await page.evaluate(a => { window._overrideAngle = a; }, ang);
      await page.evaluate(ct => {
        window._camera.position.set(ct[0][0], ct[0][1], ct[0][2]);
        window._controls.target.set(ct[1][0], ct[1][1], ct[1][2]);
        window._controls.update();
      }, [cam, tgt]);
      await page.waitForTimeout(450);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      console.log('Shot: ' + f);
    }
    const D = WP.drum, C = WP.comp, S = WP.shaft, T = WP.twist, CH = WP.ch;
    const mid3 = [(C[0] + S[0] + T[0]) / 3, (C[1] + S[1] + T[1]) / 3, (C[2] + S[2] + T[2]) / 3];
    const midDC = [(D[0] + C[0]) / 2, (D[1] + C[1]) / 2, (D[2] + C[2]) / 2];
    const midST = [(S[0] + T[0]) / 2, (S[1] + T[1]) / 2, (S[2] + T[2]) / 2];
    const NAKED = ['cartridge', 'intermediate_compound', 'drive_shaft', 'twister'];
    await shot('g01_top_full.png', [CH[0], CH[1] + 500, CH[2] + 5], CH, null, null);
    await shot('g02_crankside_full.png', [CH[0] - 330, CH[1] + 180, CH[2] + 330], CH, null, null);
    await shot('g03_east_end_west.png', [T[0] + 230, T[1] + 30, T[2] + 15], D, null, null);
    await shot('g04_compound_close.png', [C[0] + 50, C[1] - 55, C[2] + 95], C, ['intermediate_compound'], 0.6);
    await shot('g05_shaft_close.png', [S[0] + 50, S[1] - 55, S[2] + 95], S, ['drive_shaft'], 0.6);
    await shot('g06_ring_west.png', [T[0] + 95, T[1] + 18, T[2] + 35], T, ['twister'], 0.6);
    await shot('g07_drum_compound_mesh.png', [midDC[0] + 30, midDC[1] - 40, midDC[2] + 150], midDC, ['cartridge', 'intermediate_compound'], 0.6);
    await shot('g08_shaft_ring_mesh.png', [midST[0] + 60, midST[1] - 30, midST[2] + 110], midST, ['drive_shaft', 'twister'], 0.6);
    await shot('g09_chain_naked_a.png', [mid3[0] + 60, mid3[1] - 90, mid3[2] + 200], mid3, NAKED, 0.6);
    await shot('g10_chain_naked_b.png', [mid3[0] - 140, mid3[1] + 120, mid3[2] + 170], mid3, NAKED, 0.6);
    await shot('g11_side_heights.png', [mid3[0], mid3[1] + 20, mid3[2] + 400], mid3, NAKED, 0.6);
    await shot('g12_chain_t0.png', [mid3[0] + 60, mid3[1] - 90, mid3[2] + 200], mid3, NAKED, 0);
    await shot('g13_chain_t1.png', [mid3[0] + 60, mid3[1] - 90, mid3[2] + 200], mid3, NAKED, Math.PI);
    console.log('errors: ' + errors.length);
    errors.forEach(e => console.log('   ' + e));
    check(errors.length === 0, '0 console errors');
    await page.close();
    if (fail) { console.error('REVIEW FAILED: ' + fail); process.exitCode = 1; }
    else console.log('REVIEW PASSED');
  } finally {
    await pool.releaseBrowser(browser);
  }
})();
