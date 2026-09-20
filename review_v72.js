const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');
const SHOT_DIR = path.join(__dirname, 'screenshots');
const V = Date.now();
let fail = null;
function check(cond, msg) {
  console.log((cond ? 'PASS ' : 'FAIL ') + msg);
  if (!cond && !fail) fail = msg;
}
function pruneShots() {
  const files = fs.readdirSync(SHOT_DIR).filter(f => f.endsWith('.png'))
    .map(f => ({ f, m: fs.statSync(path.join(SHOT_DIR, f)).mtimeMs }))
    .sort((a, b) => a.m - b.m);
  while (files.length > 25) {
    const old = files.shift();
    fs.unlinkSync(path.join(SHOT_DIR, old.f));
    console.log('Pruned old screenshot:', old.f);
  }
}
(async () => {
  const { browser, page } = await pool.newPage({ width: 1600, height: 1000 });
  try {
    const errors = [];
    page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
    page.on('pageerror', err => errors.push(err.message));
    await page.goto('http://localhost:9099/index.html?v=' + V);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 30000 });
    console.log('status text:', await page.evaluate(() => document.getElementById('status').textContent));
    await page.evaluate(() => { window._overrideAngle = null; window._showAllParts(); });
    await page.waitForTimeout(300);
    const a0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.waitForTimeout(700);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    check(a0 !== a1, 'animating (crank ' + a0 + ' -> ' + a1 + ')');
    const facts = await page.evaluate(() => {
      const out = { pivots: {}, meshBox: {}, parts: [] };
      try {
        const v = new THREE.Vector3();
        for (const k of Object.keys(window._pivots || {})) {
          window._pivots[k].getWorldPosition(v);
          out.pivots[k] = [+v.x.toFixed(1), +v.y.toFixed(1), +v.z.toFixed(1)];
        }
        out.parts = Object.keys(window._partMeshes || {});
        const box = new THREE.Box3();
        for (const k of Object.keys(window._partMeshes || {})) {
          box.setFromObject(window._partMeshes[k]);
          const s = new THREE.Vector3(); box.getSize(s);
          const c = new THREE.Vector3(); box.getCenter(c);
          out.meshBox[k] = { c: [+c.x.toFixed(1), +c.y.toFixed(1), +c.z.toFixed(1)], s: [+s.x.toFixed(1), +s.y.toFixed(1), +s.z.toFixed(1)] };
        }
      } catch (e) { out.err = e.message; }
      return out;
    });
    console.log('PIVOTS ' + JSON.stringify(facts.pivots));
    console.log('MESHBOX ' + JSON.stringify(facts.meshBox));
    console.log('PARTS ' + JSON.stringify(facts.parts));
    if (facts.err) console.log('facts err: ' + facts.err);
    const ratio = await page.evaluate(() => {
      window._setRotations(0);
      const d0 = window._pivots.drum.rotation.z, t0 = window._pivots.twister.rotation.x;
      window._setRotations(1.0);
      const d1 = window._pivots.drum.rotation.z, t1 = window._pivots.twister.rotation.x;
      window._overrideAngle = null;
      return { dd: d1 - d0, dt: t1 - t0, r: (t1 - t0) / (d1 - d0) };
    });
    console.log('RATIO ' + JSON.stringify(ratio));
    check(Math.abs(Math.abs(ratio.r) - 418 / 27) < 1e-6, 'ring spins ~15.48x drum (got ' + ratio.r + ')');
    const tape = await page.evaluate(async () => {
      window._overrideAngle = null;
      const xs = [];
      for (let i = 0; i < 97; i++) {
        xs.push(window._tapeFold.flat.position.x);
        await new Promise(r => setTimeout(r, 25));
      }
      const uniq = [...new Set(xs)];
      return { n: xs.length, uniq, first: xs[0] };
    });
    console.log('TAPE ' + JSON.stringify(tape));
    check(tape.uniq.length === 1 && tape.first === 112, 'tape static x=112 over 97 samples (got ' + JSON.stringify(tape.uniq) + ')');
    await page.evaluate(() => window._setPanelCollapsed(true));
    await page.evaluate(() => { const top = window._root.parent || window._root; top.traverse(o => { if (o.isLine) o.visible = false; }); });
    async function shot(f, cam, tgt, only, ang) {
      await page.evaluate((o) => { if (o) window._setOnlyVisible(o); else window._showAllParts(); }, only || null);
      if (ang === null || ang === undefined) await page.evaluate(() => { window._overrideAngle = null; });
      else await page.evaluate((a) => { window._overrideAngle = a; }, ang);
      await page.evaluate(([c, t]) => {
        window._camera.position.set(c[0], c[1], c[2]);
        window._controls.target.set(t[0], t[1], t[2]);
        window._controls.update();
      }, [cam, tgt]);
      await page.waitForTimeout(450);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      console.log('Shot:', f);
    }
    const A = await page.evaluate(() => {
      const v = new THREE.Vector3(); const o = {};
      for (const k of ['twister', 'drum']) { window._pivots[k].getWorldPosition(v); o[k] = [v.x, v.y, v.z]; }
      const box = new THREE.Box3().setFromObject(window._root);
      const c = new THREE.Vector3(), s = new THREE.Vector3();
      box.getCenter(c); box.getSize(s);
      o.rootC = [c.x, c.y, c.z]; o.rootS = [s.x, s.y, s.z];
      return o;
    });
    console.log('ANCHOR ' + JSON.stringify(A));
    const TW = A.twister, RC = A.rootC, RS = A.rootS;
    const L = Math.max(RS[0], RS[1], RS[2]);
    await shot('v72r_iso_full.png', [RC[0] + L * 0.75, RC[1] - L * 0.85, RC[2] + L * 0.55], RC, null, null);
    await shot('v72r_twister_thread.png', [TW[0] + 110, TW[1] - 25, TW[2] + 45], [TW[0], TW[1], TW[2]], null, 0.6);
    const midX = (A.drum[0] + TW[0]) / 2;
    await shot('v72r_gears_back.png', [midX, TW[1] - 150, TW[2] + 30], [midX, 12, TW[2]], null, 0.6);
    const rcam = [TW[0] + 55, TW[1] - 40, TW[2] + 55], rtgt = [TW[0], TW[1], TW[2]];
    await shot('v72r_anim_t0.png', rcam, rtgt, null, 0);
    const rot0 = await page.evaluate(() => window._pivots.twister.rotation.x);
    await shot('v72r_anim_t1.png', rcam, rtgt, null, 0.5);
    const rot1 = await page.evaluate(() => window._pivots.twister.rotation.x);
    console.log('ring rot t0=' + rot0 + ' t1=' + rot1 + ' deg=' + ((rot1 - rot0) * 180 / Math.PI).toFixed(1));
    check(rot0 !== rot1, 'ring advances between t=0 and t=0.5');
    console.log('errors:', errors.length); errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, '0 console errors');
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V:', assetV);
    check(assetV === '52', 'ASSET_V 52');
    await page.close();
    pruneShots();
    if (fail) { console.error('REVIEW FAILED:', fail); process.exitCode = 1; }
    else console.log('REVIEW PASSED');
  } finally {
    await pool.releaseBrowser(browser);
  }
})();
