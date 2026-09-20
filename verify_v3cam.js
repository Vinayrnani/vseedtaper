const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');

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
    await page.goto('http://localhost:9099/index.html?v=' + Date.now());
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 30000 });
    console.log('Desktop: status=ready');

    await page.evaluate(() => { window._overrideAngle = null; window._showAllParts(); });
    await page.waitForTimeout(500);

    // Check camera position
    const camPos = await page.evaluate(() => [
      +window._camera.position.x.toFixed(1),
      +window._camera.position.y.toFixed(1),
      +window._camera.position.z.toFixed(1)
    ]);
    console.log('Camera pos: ' + JSON.stringify(camPos));
    check(camPos[0] >= 350 && camPos[1] >= 200 && camPos[2] >= 400,
      'camera far enough (expect ~400,280,500), got ' + JSON.stringify(camPos));

    // Check machine bbox projects inside viewport
    const bboxCheck = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const bb = new THREE.Box3();
      const ids = Object.keys(window._partMeshes);
      ids.forEach(id => {
        (window._partMeshes[id] || []).forEach(s => s.traverse(o => {
          if (o.isMesh) bb.expandByObject(o);
        }));
      });
      if (bb.isEmpty()) return { ok: false, reason: 'empty bbox' };
      const size = new THREE.Vector3();
      const center = new THREE.Vector3();
      bb.getSize(size);
      bb.getCenter(center);
      const maxDim = Math.max(size.x, size.y, size.z, 1);
      const fov = window._camera.fov * (Math.PI / 180);
      const dist = Math.max(maxDim / (2 * Math.tan(fov / 2)) * 1.5, 100);
      const camDir = new THREE.Vector3();
      window._camera.getWorldDirection(camDir);
      const neededDist = dist;
      const actualDist = window._camera.position.distanceTo(center);
      // Camera should be at least 1.2x the needed distance for margin
      const margin = actualDist / neededDist;
      return { ok: margin >= 1.1, margin: +margin.toFixed(2),
        neededDist: +neededDist.toFixed(1), actualDist: +actualDist.toFixed(1),
        maxDim: +maxDim.toFixed(1) };
    });
    console.log('Framing check: ' + JSON.stringify(bboxCheck));
    check(bboxCheck.ok, 'full machine fits with margin (margin=' + bboxCheck.margin + ')');

    // Check 0 console errors
    console.log('Desktop errors: ' + errors.length);
    errors.forEach(e => console.log('   ' + e));
    check(errors.length === 0, 'desktop 0 console errors');

    // Screenshot: full machine
    await page.evaluate(() => window._setPanelCollapsed(true));
    await page.evaluate(() => {
      const top = window._root.parent || window._root;
      top.traverse(o => { if (o.isLine) o.visible = false; });
    });
    await page.screenshot({ path: path.join(SHOT_DIR, 'v3_full.png') });
    console.log('Shot: v3_full.png');

    // Screenshot: solo crank
    await page.evaluate(() => window._isolatePart('crank'));
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v3_solo_crank.png') });
    console.log('Shot: v3_solo_crank.png');

    // Screenshot: solo hopper
    await page.evaluate(() => window._isolatePart('hopper'));
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v3_solo_hopper.png') });
    console.log('Shot: v3_solo_hopper.png');

    pruneShots();
    if (fail) { console.error('VERIFY FAILED: ' + fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await pool.releaseBrowser(browser);
  }
})();
