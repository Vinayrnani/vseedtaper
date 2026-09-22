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
    check(assetV === '56', 'ASSET_V=56 got ' + assetV);

    const pivots = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const rp = new THREE.Vector3(); window._root.getWorldPosition(rp);
      const out = {};
      ['twister', 'pullA', 'pullB', 'takeup'].forEach(k => {
        const p = new THREE.Vector3();
        window._pivots[k].getWorldPosition(p).sub(rp);
        out[k] = [+p.x.toFixed(1), +p.y.toFixed(1), +p.z.toFixed(1)];
      });
      const meta = window._twister || {};
      out.bindX = meta.bindX;
      out.pullX = meta.pullX;
      out.takeupX = meta.takeupX;
      return out;
    });
    console.log('PIVOTS ' + JSON.stringify(pivots));
    check(Math.abs(pivots.twister[0] - 184) < 1.5, 'twister pivot x ~184 got ' + pivots.twister[0]);
    check(Math.abs(pivots.pullA[0] - 206) < 1.5, 'pullA pivot x ~206 got ' + pivots.pullA[0]);
    check(Math.abs(pivots.pullB[0] - 206) < 1.5, 'pullB pivot x ~206 got ' + pivots.pullB[0]);
    check(Math.abs(pivots.takeup[0] - 238) < 1.5, 'takeup pivot x ~238 got ' + pivots.takeup[0]);
    check(pivots.bindX === 184, 'window._twister.bindX=184 got ' + pivots.bindX);
    check(pivots.pullX === 206, 'window._twister.pullX=206 got ' + pivots.pullX);
    check(pivots.takeupX === 238, 'window._twister.takeupX=238 got ' + pivots.takeupX);

    const a0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.waitForTimeout(700);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    check(a0 !== a1, 'animating crankSpinner ' + a0.toFixed(3) + ' -> ' + a1.toFixed(3));

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

    // 1 overview (live free anim)
    await shot('v88_overview.png', [ch[0] - 300, ch[1] + 170, ch[2] + 300], ch, null, null);

    // 2 twister closeup around bind/pull/takeup zone
    await shot('v88_twister_closeup.png', [184 + 70, 17 + 30, -34 + 90], [206, 17, -34], null, null);

    // 3 animated mid-cycle (frozen angle so camera can catch mid stroke)
    await shot('v88_anim_mid.png', [ch[0] - 300, ch[1] + 170, ch[2] + 300], ch, null, Math.PI / 2);

    // 4 tape static (all parts, free anim, framed along ribbon)
    await shot('v88_tape_static.png', [103, 80, 220], [103, 13, -30], null, null);

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
