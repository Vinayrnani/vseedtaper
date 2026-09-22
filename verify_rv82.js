const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');
const SHOT_DIR = path.join(__dirname, 'screenshots');
fs.mkdirSync(SHOT_DIR, { recursive: true });
(function prune() {
  const files = fs.readdirSync(SHOT_DIR).filter(f => f.endsWith('.png'))
    .map(f => ({ f, m: fs.statSync(path.join(SHOT_DIR, f)).mtimeMs })).sort((a, b) => a.m - b.m);
  while (files.length > 22) {
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

    // Proof: gears gone but drum+handle+supports present
    const gearCheck = await page.evaluate(() => {
      const gears = window._partMeshes['gear'] || window._partMeshes['gears'];
      return { gearCount: gears ? gears.length : 0, partIds: Object.keys(window._partMeshes) };
    });
    check(gearCheck.gearCount === 0, 'gears removed: got ' + gearCheck.gearCount);
    console.log('Part IDs: ' + gearCheck.partIds.join(', '));

    // Ensure drum, crank, supports are present
    const present = await page.evaluate(() => {
      const ids = ['chassis', 'cartridge', 'crank', 'hopper', 'plow'];
      return ids.map(id => ({ id, count: (window._partMeshes[id] || []).length }));
    });
    present.forEach(p => check(p.count > 0, p.id + ' present: ' + p.count));

    // Collapsed panel
    await page.evaluate(() => window._setPanelCollapsed(true));
    await page.waitForTimeout(200);

    async function shot(f, cam, tgt, only, ang) {
      await page.evaluate(o => { if (o) window._setOnlyVisible(o); else window._showAllParts(); }, only || null);
      if (ang === null || ang === undefined) await page.evaluate(() => { window._overrideAngle = null; });
      else await page.evaluate(a => { window._overrideAngle = a; }, ang);
      await page.evaluate(ct => { window._camera.position.set(ct[0][0], ct[0][1], ct[0][2]); window._controls.target.set(ct[1][0], ct[1][1], ct[1][2]); window._controls.update(); }, [cam, tgt]);
      await page.waitForTimeout(500);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      console.log('Shot: ' + f);
    }

    // Chassis center for reference
    const ch = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const bb = new THREE.Box3();
      (window._partMeshes['chassis'] || []).forEach(s => s.traverse(o => { if (o.isMesh) bb.expandByObject(o); }));
      const c = bb.getCenter(new THREE.Vector3()); return [c.x, c.y, c.z];
    });

    // 1. Front/interior view (camera front, look at x=100..160 front plane)
    await shot('rv82_front.png', [130, 60, -200], [130, 50, -30], null, null);

    // 2. Solo drum (hide chassis)
    await shot('rv82_drum_solo.png', [100, 60, -120], [100, 50, -30], ['cartridge', 'tape', 'seeds'], null);

    // 3. Solo crank
    await shot('rv82_crank_solo.png', [160, 60, -120], [160, 50, -30], ['crank', 'chassis'], null);

    // 4. anim_t0 vs anim_t1 with distinct $t (0.0 vs 0.25) so drum rotation visible
    await shot('rv82_anim_t0.png', [ch[0] - 300, ch[1] + 170, ch[2] + 300], ch, null, 0);
    await shot('rv82_anim_t1.png', [ch[0] - 300, ch[1] + 170, ch[2] + 300], ch, null, Math.PI / 2);

    // 5. Mesh close-up framed on x=100..160 front plane (not clipped wall)
    await shot('rv82_mesh.png', [130, 55, -160], [130, 50, -30], null, null);

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
