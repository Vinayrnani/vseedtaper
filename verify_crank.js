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
    check(assetV !== null && +assetV >= 68, 'ASSET_V>=68 got ' + assetV);

    const parts = await page.evaluate(() => {
      let n = 0;
      (window._partMeshes['crank'] || []).forEach(s => s.traverse(o => { if (o.isMesh) n++; }));
      return { crank: n };
    });
    console.log('PARTS ' + JSON.stringify(parts));
    check(parts.crank > 0, 'crank has meshes got ' + parts.crank);

    const piv = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const rp = new THREE.Vector3(); window._root.getWorldPosition(rp);
      const cm = new THREE.Vector3();
      window._pivots.crankMount.getWorldPosition(cm).sub(rp);
      return [+cm.x.toFixed(2), +cm.y.toFixed(2)];
    });
    console.log('PIV crankMount ' + JSON.stringify(piv));
    check(Math.abs(piv[0] - 152) < 1.5 && Math.abs(piv[1] - 104.93) < 1.5, 'crankMount ~(152,104.9) got ' + piv);

    // crank still drives drum 2:1 (nothing else touched)
    async function rots() {
      return await page.evaluate(() => ({
        crank: window._crankSpinner.rotation.z,
        drum: window._drumPivot.rotation.z
      }));
    }
    await page.evaluate(() => { window._overrideAngle = 0.7; });
    await page.waitForTimeout(300);
    const r0 = await rots();
    await page.evaluate(() => { window._overrideAngle = 0.7 + Math.PI / 3; });
    await page.waitForTimeout(300);
    const r1 = await rots();
    const dc = r1.crank - r0.crank;
    const got = (r1.drum - r0.drum) / dc;
    check(Math.abs(got - (-0.5)) < 0.035, 'drum ratio want -0.5 got ' + got.toFixed(3));
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

    // viewer maps CAD (x,y,z) -> root (x, z, -y)
    // shaft-into-gear closeup (crank part only: arm+boss+shaft+gear are one
    // fused part): CAD cam (190,90,140) -> viewer (190,140,-90); CAD tgt (152,70,105) -> viewer (152,105,-70)
    await shot('v102_crank_shaft.png', [190, 140, -90], [152, 105, -70], ['crank'], Math.PI / 5);
    // handle-gap side view: CAD cam (260,80,105) -> viewer (260,105,-80); CAD tgt (155,75,100) -> viewer (155,100,-75)
    await shot('v102_crank_handle.png', [260, 105, -80], [155, 100, -75], ['crank', 'chassis'], null);

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
