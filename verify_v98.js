const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');
const SHOT_DIR = path.join(__dirname, 'screenshots');
fs.mkdirSync(SHOT_DIR, { recursive: true });
(function prune() {
  const files = fs.readdirSync(SHOT_DIR).filter(f => f.endsWith('.png'))
    .map(f => ({ f, m: fs.statSync(path.join(SHOT_DIR, f)).mtimeMs })).sort((a, b) => a.m - b.m);
  while (files.length > 21) {
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

    const assetV = await page.evaluate(() => {
      const m = document.documentElement.innerHTML.match(/ASSET_V = (\d+)/);
      return m ? m[1] : null;
    });
    console.log('ASSET_V:', assetV);
    check(assetV !== null && +assetV >= 64, 'ASSET_V>=64 got ' + assetV);

    const parts = await page.evaluate(() => {
      const out = {};
      ['gear_A', 'gear_B'].forEach(id => {
        let n = 0;
        (window._partMeshes[id] || []).forEach(s => s.traverse(o => { if (o.isMesh) n++; }));
        out[id] = n;
      });
      return out;
    });
    console.log('PARTS ' + JSON.stringify(parts));
    check(parts.gear_A > 0, 'gear_A has meshes got ' + parts.gear_A);
    check(parts.gear_B > 0, 'gear_B has meshes got ' + parts.gear_B);

    const retired = await page.evaluate(() => ({
      defs: (document.documentElement.innerHTML.match(/gear_Bw|gear_Be|gear_C|bar1|barM|barE|pivotBw|pivotBe|pivotC/) || []).length,
      drive: Object.keys(window._drive.pivots)
    }));
    console.log('RETIRED ' + JSON.stringify(retired));
    check(retired.defs === 0, 'no old-train refs in page');
    check(JSON.stringify(retired.drive.sort()) === JSON.stringify(['A', 'B']), 'drive pivots [A,B] got ' + retired.drive);

    const piv = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const rp = new THREE.Vector3(); window._root.getWorldPosition(rp);
      const out = {};
      ['A', 'B'].forEach(k => {
        const p = new THREE.Vector3();
        window._drive.pivots[k].getWorldPosition(p).sub(rp);
        out[k] = [+p.x.toFixed(2), +p.y.toFixed(2), +p.z.toFixed(2)];
      });
      return out;
    });
    console.log('PIVOTS ' + JSON.stringify(piv));
    check(Math.abs(piv.A[0] - 162.52) < 1.5 && Math.abs(piv.A[1] - 76.04) < 1.5, 'pivotA ~(162.5,76.0) got ' + piv.A);
    check(Math.abs(piv.B[0] - 187.39) < 1.5 && Math.abs(piv.B[1] - 69.37) < 1.5, 'pivotB ~(187.4,69.4) got ' + piv.B);

    async function rots() {
      return await page.evaluate(() => ({
        crank: window._crankSpinner.rotation.z,
        A: window._drive.pivots.A.rotation.z,
        B: window._drive.pivots.B.rotation.z,
        tw: window._pivots.twister.rotation.x,
        drum: window._drumPivot.rotation.z
      }));
    }
    await page.evaluate(() => { window._overrideAngle = 0.7; });
    await page.waitForTimeout(300);
    const r0 = await rots();
    await page.evaluate(() => { window._overrideAngle = 0.7 + Math.PI / 3; });
    await page.waitForTimeout(300);
    const r1 = await rots();
    const d = k => r1[k] - r0[k];
    const dc = d('crank');
    console.log('dcrank=' + dc.toFixed(4));
    const ratio = (k, want) => {
      const got = d(k) / dc;
      const ok = Math.abs(got - want) < 0.03 * Math.abs(want) + 0.02;
      check(ok, k + ' ratio want ' + want + ' got ' + got.toFixed(3));
    };
    ratio('A', -2); ratio('B', 6); ratio('tw', 0); ratio('drum', -0.5);

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

    await shot('v98_overview.png', [ch[0] - 300, ch[1] + 170, ch[2] + 300], ch, null, null);
    await shot('v98_ABmesh.png', [5, 182, 69], [75, 72, -1], ['gear_A', 'gear_B', 'crank'], Math.PI / 5);

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
