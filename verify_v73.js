const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');

// v73 verify: 5 fixes from v72 failures (commit 5698d62 feat(v73)).
// (1) twister bore hollow open, (2) intermediate compound export renders,
// (3) drive shaft bevel pinion teeth, (4) chassis wall windows,
// (5) gear chain connectivity drum44->compound->shaft->ring bevel.
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
    await page.goto('http://localhost:9099/index.html?v=' + V);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 30000 });
    console.log('Desktop: status=ready');

    await page.evaluate(() => { window._overrideAngle = null; window._showAllParts(); });
    await page.waitForTimeout(400);
    const a0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.waitForTimeout(700);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    check(a0 !== a1, 'animating true (crankSpinner rotates)');

    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 54):', assetV);
    check(assetV === '54', 'ASSET_V 54 (v73 GLB rebuild)');

    const stats = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const out = {};
      const ids = ['twister', 'intermediate_compound', 'drive_shaft', 'chassis', 'cartridge'];
      ids.forEach(id => {
        const arr = window._partMeshes[id] || [];
        let meshes = 0, verts = 0;
        const bb = new THREE.Box3();
        arr.forEach(s => s.traverse(o => {
          if (o.isMesh) {
            meshes++;
            const g = o.geometry;
            verts += g.attributes && g.attributes.position ? g.attributes.position.count : 0;
            bb.expandByObject(o);
          }
        }));
        out[id] = { scenes: arr.length, meshes: meshes, verts: verts };
        if (arr.length) out[id].bbox = [bb.min.toArray(), bb.max.toArray()];
      });
      return out;
    });
    console.log('part stats: ' + JSON.stringify(stats));
    check(stats.twister.scenes > 0 && stats.twister.verts > 500, 'twister renders, verts=' + stats.twister.verts);
    check(stats.intermediate_compound.scenes > 0 && stats.intermediate_compound.verts > 500, 'compound renders, verts=' + stats.intermediate_compound.verts);
    check(stats.drive_shaft.scenes > 0 && stats.drive_shaft.verts > 500, 'drive shaft renders, verts=' + stats.drive_shaft.verts);
    // Fix 1: bore openness — raycast along world X through twister bbox centre.
    // Open bore => 0 hits; blocked bore (disc) => 1+ hits.
    const bore = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const bb = new THREE.Box3();
      const arr = window._partMeshes.twister || [];
      arr.forEach(s => s.traverse(o => { if (o.isMesh) bb.expandByObject(o); }));
      const c = bb.getCenter(new THREE.Vector3());
      const sz = bb.getSize(new THREE.Vector3());
      const rc = new THREE.Raycaster(new THREE.Vector3(c.x - 200, c.y, c.z), new THREE.Vector3(1, 0, 0), 0, 400);
      const hits = rc.intersectObjects(arr, true);
      return { cx: +c.x.toFixed(1), cy: +c.y.toFixed(1), cz: +c.z.toFixed(1),
        sx: +sz.x.toFixed(1), sy: +sz.y.toFixed(1), sz2: +sz.z.toFixed(1), hits: hits.length };
    });
    console.log('twister bore raycast: ' + JSON.stringify(bore));
    check(bore.hits === 0, 'twister bore OPEN along X, ray hits=' + bore.hits);

    // Fix 5: chain connectivity in root-local XY mesh plane (axles run along Z).
    // drum(100,60)->compound(156,57): 56.08 = 44+12 M2; compound->shaft(186,17):
    // 50 = 38+12 M2; shaft->ring(186,17): coaxial XY~0, bevel mesh along Z.
    const chain = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      function bbCentre(id) {
        const bb = new THREE.Box3();
        const arr = window._partMeshes[id] || [];
        arr.forEach(s => s.traverse(o => { if (o.isMesh) bb.expandByObject(o); }));
        const c = bb.getCenter(new THREE.Vector3());
        return [c.x + 100, c.y, c.z - 55];
      }
      function pivRL(p) {
        const v = new THREE.Vector3(); p.getWorldPosition(v);
        return [v.x + 100, v.y, v.z - 55];
      }
      function dxy(a, b) { return Math.hypot(a[0] - b[0], a[1] - b[1]); }
      const drum = pivRL(window._pivots.drum);
      const ring = pivRL(window._pivots.twister);
      const comp = bbCentre('intermediate_compound');
      const shaft = bbCentre('drive_shaft');
      return {
        drum: drum, comp: comp, shaft: shaft, ring: ring,
        drum_comp: +dxy(drum, comp).toFixed(2),
        comp_shaft: +dxy(comp, shaft).toFixed(2),
        shaft_ring_xy: +dxy(shaft, ring).toFixed(2),
        shaft_ring_dz: +Math.abs(shaft[2] - ring[2]).toFixed(2)
      };
    });
    console.log('chain root-local: ' + JSON.stringify(chain));
    check(Math.abs(chain.drum_comp - 56.08) < 5, 'drum44->compound mesh XY=' + chain.drum_comp + ' ~= 56.08');
    check(Math.abs(chain.comp_shaft - 50) < 5, 'compound38->shaft spur mesh XY=' + chain.comp_shaft + ' ~= 50');
    check(chain.shaft_ring_xy < 5, 'shaft/ring coaxial XY=' + chain.shaft_ring_xy + ' ~= 0');

    // Ring ~15.48x drum (418/27) via override angles 0 -> PI.
    const ratio = await page.evaluate(() => {
      window._overrideAngle = 0;
      return new Promise(res => setTimeout(() => {
        const d0 = window._pivots.drum.rotation.z;
        const t0 = window._pivots.twister.rotation.x;
        window._overrideAngle = Math.PI;
        setTimeout(() => {
          const d1 = window._pivots.drum.rotation.z;
          const t1 = window._pivots.twister.rotation.x;
          window._overrideAngle = null;
          res({ dd: d1 - d0, dt: t1 - t0 });
        }, 300);
      }, 300));
    });
    const rr = Math.abs(ratio.dt / ratio.dd);
    console.log('ring/drum ratio: ' + rr.toFixed(4) + ' expect ' + (418 / 27).toFixed(4));
    check(Math.abs(rr - 418 / 27) < 0.05, 'ring spins ~15.48x drum, got ' + rr.toFixed(3));

    // Tape static regression (v45): ribbon stays centred while animating.
    await page.evaluate(() => { window._overrideAngle = 0.6; });
    await page.waitForTimeout(200);
    const tx0 = await page.evaluate(() => window._tapeFold.flat.position.x);
    await page.waitForTimeout(900);
    const tx1 = await page.evaluate(() => window._tapeFold.flat.position.x);
    console.log('tapeGroup.x frozen=' + tx0 + ' animating=' + tx1);
    check(tx0 === tx1 && tx0 === 112, 'tape ribbon STATIC centred, got ' + tx0 + '/' + tx1);
    // Screenshots.
    await page.evaluate(() => window._setPanelCollapsed(true));
    await page.evaluate(() => {
      const top = window._root.parent || window._root;
      top.traverse(o => { if (o.isLine) o.visible = false; });
    });
    const WP = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      function centre(id) {
        const bb = new THREE.Box3();
        const arr = window._partMeshes[id] || [];
        arr.forEach(s => s.traverse(o => { if (o.isMesh) bb.expandByObject(o); }));
        const c = bb.getCenter(new THREE.Vector3());
        return [c.x, c.y, c.z];
      }
      const ch = new THREE.Box3();
      const charr = window._partMeshes.chassis || [];
      charr.forEach(s => s.traverse(o => { if (o.isMesh) ch.expandByObject(o); }));
      const cc = ch.getCenter(new THREE.Vector3());
      return { twister: centre('twister'), compound: centre('intermediate_compound'),
        shaft: centre('drive_shaft'), chassis: [cc.x, cc.y, cc.z] };
    });
    console.log('world centres: ' + JSON.stringify(WP));
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
    const T = WP.twister, C = WP.compound, S = WP.shaft, CH = WP.chassis;
    const mid = [(C[0] + S[0] + T[0]) / 3, (C[1] + S[1] + T[1]) / 3, (C[2] + S[2] + T[2]) / 3];
    await shot('v73_full_crankside.png', [CH[0] - 300, CH[1] + 170, CH[2] + 300], CH, null, null);
    await shot('v73_twister_bore.png', [T[0] + 80, T[1] + 6, T[2] + 6], T, ['twister'], 0.6);
    await shot('v73_twister_bevel_west.png', [T[0] - 80, T[1] + 15, T[2] + 25], T, ['twister', 'drive_shaft'], 0.6);
    await shot('v73_gearchain_naked.png', [mid[0] + 40, mid[1] - 60, mid[2] + 150], mid, ['twister', 'intermediate_compound', 'drive_shaft', 'cartridge'], 0.6);
    await shot('v73_gearchain_chassis.png', [mid[0] + 40, mid[1] - 60, mid[2] + 150], mid, ['chassis', 'twister', 'intermediate_compound', 'drive_shaft', 'cartridge'], 0.6);
    await shot('v73_compound.png', [C[0] + 30, C[1] - 40, C[2] + 70], C, ['intermediate_compound'], 0.6);
    await shot('v73_shaft.png', [S[0] + 30, S[1] - 40, S[2] + 70], S, ['drive_shaft'], 0.6);
    await shot('v73_anim_t0.png', [CH[0] - 300, CH[1] + 170, CH[2] + 300], CH, null, 0);
    await shot('v73_anim_t05.png', [CH[0] - 300, CH[1] + 170, CH[2] + 300], CH, null, Math.PI);

    console.log('Desktop errors: ' + errors.length);
    errors.forEach(e => console.log('   ' + e));
    check(errors.length === 0, 'desktop 0 console errors');
    await page.close();

    pruneShots();
    if (fail) { console.error('VERIFY FAILED: ' + fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await pool.releaseBrowser(browser);
  }
})();
