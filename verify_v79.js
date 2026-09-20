const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');
const SHOT_DIR = path.join(__dirname, 'screenshots');
fs.mkdirSync(SHOT_DIR, { recursive: true });
(function prune() {
  const files = fs.readdirSync(SHOT_DIR).filter(f => f.endsWith('.png'))
    .map(f => ({ f, m: fs.statSync(path.join(SHOT_DIR, f)).mtimeMs })).sort((a, b) => a.m - b.m);
  while (files.length > 20) {
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

    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V:', assetV);
    check(assetV === '43', 'ASSET_V=43 got ' + assetV);

    const a0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.waitForTimeout(700);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    check(a0 !== a1, 'animating crankSpinner ' + a0.toFixed(3) + ' -> ' + a1.toFixed(3));

    const pivots = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const rp = new THREE.Vector3(); window._root.getWorldPosition(rp);
      const out = {};
      ['drum', 'crankSpinner', 'shroud'].forEach(k => {
        const p = new THREE.Vector3();
        window._pivots[k].getWorldPosition(p).sub(rp);
        out[k] = [+p.x.toFixed(1), +p.y.toFixed(1), +p.z.toFixed(1)];
      });
      return out;
    });
    console.log('PIVOTS ' + JSON.stringify(pivots));

    function pivotCheck(k, want) {
      const got = pivots[k];
      const ok = got.length === want.length && want.every((w, i) => Math.abs(got[i] - w) < 0.15);
      check(ok, k + ' pivot ' + JSON.stringify(want) + ' got ' + JSON.stringify(got));
    }
    pivotCheck('drum', [100, 60, -30]);
    pivotCheck('crankSpinner', [160, 60, -68]);
    pivotCheck('shroud', [116, 0, -30]);

    const parts = await page.evaluate(() => {
      const out = {};
      ['chassis', 'hopper', 'shroud', 'cartridge', 'crank'].forEach(id => {
        const bb = new THREE.Box3();
        const arr = window._partMeshes[id] || [];
        let n = 0, v = 0;
        arr.forEach(s => s.traverse(o => { if (o.isMesh) { n++; v += o.geometry.attributes.position.count; bb.expandByObject(o); } }));
        out[id] = { scenes: arr.length, meshes: n, verts: v };
      });
      return out;
    });
    ['chassis', 'hopper', 'shroud', 'cartridge', 'crank'].forEach(id => {
      check(parts[id].scenes > 0 && parts[id].verts > 100, id + ' renders verts=' + parts[id].verts);
    });

    const hasRollers = await page.evaluate(() => {
      return !!(window._partMeshes['rollers_lower'] || window._partMeshes['rollers_upper']);
    });
    check(!hasRollers, 'no rollers_lower/rollers_upper parts loaded');

    async function rots(ang) {
      await page.evaluate(a => { window._overrideAngle = a; }, ang);
      await page.waitForTimeout(350);
      return await page.evaluate(() => ({
        crank: window._crankSpinner.rotation.z,
        drum: window._drumPivot.rotation.z,
        twister: window._pivots.twister.rotation.x,
        takeup: window._pivots.takeup.rotation.z
      }));
    }
    const r0 = await rots(0), r1 = await rots(Math.PI);
    const dCrank = r1.crank - r0.crank;
    const dDrum = r1.drum - r0.drum;
    const dTw = r1.twister - r0.twister;
    const dTu = r1.takeup - r0.takeup;
    console.log('DELTAS crank=' + dCrank.toFixed(4) + ' drum=' + dDrum.toFixed(4) +
      ' twister=' + dTw.toFixed(4) + ' takeup=' + dTu.toFixed(4));

    function ratio(dx, want) { return Math.abs(Math.abs(dx / dCrank) - Math.abs(want)) / Math.abs(want) < 0.03; }
    check(ratio(dDrum, 0.5), 'drum ratio 0.5 got ' + (dDrum / dCrank).toFixed(3));
    check(ratio(dTw, 3), 'twister ratio 3.0 got ' + (dTw / dCrank).toFixed(3));
    check(ratio(dTu, 2), 'takeup ratio 2.0 got ' + (dTu / dCrank).toFixed(3));

    check(dCrank > 0, 'crank positive direction');
    check(dDrum > 0, 'drum same direction as crank (0.5x)');
    check(dTw > 0, 'twister same direction as crank (3x)');
    check(dTu < 0, 'takeup opposite direction (-2x)');

    await page.evaluate(() => { window._overrideAngle = null; });
    await page.waitForTimeout(200);
    await page.evaluate(() => window._setPanelCollapsed(true));

    async function shot(f, cam, tgt, only, ang) {
      await page.evaluate(o => { if (o) window._setOnlyVisible(o); else window._showAllParts(); }, only || null);
      if (ang === null || ang === undefined) await page.evaluate(() => { window._overrideAngle = null; });
      else await page.evaluate(a => { window._overrideAngle = a; }, ang);
      await page.evaluate(ct => { window._camera.position.set(ct[0][0], ct[0][1], ct[0][2]); window._controls.target.set(ct[1][0], ct[1][1], ct[1][2]); window._controls.update(); }, [cam, tgt]);
      await page.waitForTimeout(450);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      console.log('Shot: ' + f);
    }

    const ch = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const bb = new THREE.Box3();
      (window._partMeshes['chassis'] || []).forEach(s => s.traverse(o => { if (o.isMesh) bb.expandByObject(o); }));
      const c = bb.getCenter(new THREE.Vector3()); return [c.x, c.y, c.z];
    });
    await shot('rv79_full.png', [ch[0] - 300, ch[1] + 170, ch[2] + 300], ch, null, null);
    await shot('rv79_crank_side.png', [160, 80, -150], [160, 50, -30], null, null);
    await shot('rv79_shroud_east.png', [120, 60, -100], [120, 30, -30], ['shroud', 'cartridge', 'chassis'], null);
    await shot('rv79_anim_t0.png', [ch[0] - 300, ch[1] + 170, ch[2] + 300], ch, null, 0);
    await shot('rv79_anim_t1.png', [ch[0] - 300, ch[1] + 170, ch[2] + 300], ch, null, Math.PI);

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
