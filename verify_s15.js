const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');
const SHOT_DIR = path.join(__dirname, 'screenshots');
fs.mkdirSync(SHOT_DIR, { recursive: true });
// Prune oldest non-s11..s15 first to cap 25 (6 new shots -> keep <=19 before capture).
(function prune() {
  let files = fs.readdirSync(SHOT_DIR).filter(f => f.endsWith('.png'))
    .map(f => ({ f, m: fs.statSync(path.join(SHOT_DIR, f)).mtimeMs })).sort((a, b) => a.m - b.m);
  while (files.length > 19) {
    const idx = files.findIndex(o => !/^s1[1-5]_/.test(o.f));
    const o = idx >= 0 ? files.splice(idx, 1)[0] : files.shift();
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
    // Hide white wireframe trail (thread lines are root-level, outside toggleGroups) for clean shots.
    await page.evaluate(() => {
      (window._twister.lines || []).forEach(l => { l.visible = false; });
      window._showAllParts();
      window._overrideAngle = 0.7;
    });
    await page.waitForTimeout(400);
    // Sanity: dipped ribbon present (234 shingles), dip bottom near platform top 19.5.
    const dip = await page.evaluate(() => {
      let n = 0, minY = 1e9;
      window._root.updateMatrixWorld(true);
      const v = new window.THREE.Vector3();
      (window._tapeFold.flat.children[0] ? window._tapeFold.flat.children : []).forEach(m => {
        m.getWorldPosition(v); n++;
        if (v.y < minY) minY = v.y;
      });
      return { n, minY: +minY.toFixed(2) };
    });
    console.log('DIP ' + JSON.stringify(dip));
    check(dip.n >= 200, 'dipped ribbon shingles>=200 got ' + dip.n);
    await page.evaluate(() => window._setPanelCollapsed(true));

    async function shot(f, cam, tgt, only, ang) {
      const err0 = errors.length;
      await page.evaluate(o => { if (o) window._setOnlyVisible(o); else window._showAllParts(); }, only || null);
      await page.evaluate(() => { (window._twister.lines || []).forEach(l => { l.visible = false; }); });
      if (ang === null || ang === undefined) await page.evaluate(() => { window._overrideAngle = null; });
      else await page.evaluate(a => { window._overrideAngle = a; }, ang);
      await page.evaluate(ct => { window._camera.position.set(ct[0][0], ct[0][1], ct[0][2]); window._controls.target.set(ct[1][0], ct[1][1], ct[1][2]); window._controls.update(); }, [cam, tgt]);
      await page.waitForTimeout(450);
      const st = await page.evaluate(() => document.getElementById('status').textContent);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      const fp = path.join(SHOT_DIR, f);
      const sz = fs.statSync(fp).size;
      const fresh = (Date.now() - fs.statSync(fp).mtimeMs) < 60000;
      const errs = errors.length - err0;
      console.log('Shot: ' + f + ' size=' + sz + ' fresh=' + fresh + ' errs=' + errs + ' status=' + JSON.stringify(st.slice(0, 40)));
      check(sz > 0, f + ' nonzero');
      check(fresh, f + ' fresh');
      check(errs === 0, f + ' 0 console errors');
      check(st.includes('ready'), f + ' status=ready');
    }

    const ANG = 0.7;
    await shot('s15_tape_side.png', [91, 27, 55], [91, 21, -34], ['tape'], ANG);
    await shot('s15_tape_iso.png', [58, 60, 30], [88, 20, -34], ['tape'], ANG);
    await shot('s15_plow_machine.png', [150, 130, -175], [165, 28, -30], null, ANG);
    await shot('s15_hopper_top.png', [50, 235, -18], [50, 55, -34], ['hopper'], ANG);
    await shot('s15_gearb_back.png', [155, 32, 45], [155, 32, -56], ['gear_B'], Math.PI / 5);
    const ch = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const bb = new window.THREE.Box3();
      (window._partMeshes['chassis'] || []).forEach(s => s.traverse(o => { if (o.isMesh) bb.expandByObject(o); }));
      const c = bb.getCenter(new window.THREE.Vector3()); return [c.x, c.y, c.z];
    });
    await shot('s15_assembly.png', [ch[0] - 300, ch[1] + 170, ch[2] + 300], ch, null, ANG);

    console.log('total errors: ' + errors.length);
    errors.forEach(e => console.log('   ' + e));
    check(errors.length === 0, '0 console errors overall');
    await page.evaluate(() => { (window._twister.lines || []).forEach(l => { l.visible = true; }); });
    await page.close();
    if (failures.length) { console.error('VERIFY FAILED(' + failures.length + '):'); failures.forEach(f => console.error(' - ' + f)); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await pool.releaseBrowser(browser);
  }
})();
