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
    console.log('Desktop: status=ready');

    await page.evaluate(() => { window._overrideAngle = null; window._showAllParts(); });
    await page.waitForTimeout(400);

    // ASSET_V check
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 57):', assetV);
    check(assetV === '57', 'ASSET_V 57');

    // All 9 parts loaded
    const partStats = await page.evaluate(() => {
      const ids = ['chassis', 'cartridge', 'hopper', 'rollers', 'rollers_upper', 'crank', 'folder', 'twister', 'layshaft'];
      const out = {};
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
        out[id] = { scenes: arr.length, meshes, verts, bbox: bb.isEmpty() ? null : [bb.min.toArray(), bb.max.toArray()] };
      });
      return out;
    });
    console.log('Part stats: ' + JSON.stringify(partStats, null, 2));
    const allParts = ['chassis', 'cartridge', 'hopper', 'rollers', 'rollers_upper', 'crank', 'folder', 'twister', 'layshaft'];
    allParts.forEach(id => {
      check(partStats[id].scenes > 0 && partStats[id].verts > 0, `${id} renders (verts=${partStats[id].verts})`);
    });

    // Hopper parented to root (not drumPivot)
    const hopperParent = await page.evaluate(() => {
      const hopper = window._partMeshes.hopper;
      if (!hopper || !hopper[0]) return null;
      let p = hopper[0].parent;
      while (p && p !== window._root) {
        if (p === window._drumPivot) return 'drumPivot';
        p = p.parent;
      }
      return p === window._root ? 'root' : 'unknown';
    });
    console.log('Hopper parent:', hopperParent);
    check(hopperParent === 'root', 'Hopper parented to root');

    // Animation check
    const a0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.waitForTimeout(700);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    check(a0 !== a1, 'animating true (crankSpinner rotates)');

    // Console errors check
    await page.waitForTimeout(500);
    console.log('Console errors:', errors.length);
    check(errors.length === 0, '0 console errors');

    // Solo part checks - each part shows only itself
    for (const id of allParts) {
      await page.evaluate((partId) => {
        window._overrideAngle = null;
        window._isolatePart(partId);
      }, id);
      await page.waitForTimeout(300);
      const soloStats = await page.evaluate(() => {
        const ids = ['chassis', 'cartridge', 'hopper', 'rollers', 'rollers_upper', 'crank', 'folder', 'twister', 'layshaft'];
        const out = {};
        ids.forEach(pid => {
          const arr = window._partMeshes[pid] || [];
          const vis = arr.some(s => s.visible);
          out[pid] = vis;
        });
        return out;
      });
      const onlyVisible = allParts.filter(pid => soloStats[pid]);
      check(onlyVisible.length === 1 && onlyVisible[0] === id, `solo ${id}: only visible=${onlyVisible}`);
    }

    // Full view - all parts visible, machine in frame
    await page.evaluate(() => { window._overrideAngle = null; window._showAllParts(); });
    await page.waitForTimeout(400);
    const allVisible = await page.evaluate(() => {
      const ids = ['chassis', 'cartridge', 'hopper', 'rollers', 'rollers_upper', 'crank', 'folder', 'twister', 'layshaft'];
      return ids.map(id => (window._partMeshes[id] || []).some(s => s.visible));
    });
    check(allVisible.every(v => v), 'all 9 parts visible in full view');

    // Camera framing check - machine bounds should be in view
    const camInfo = await page.evaluate(() => {
      return {
        camPos: window._camera.position.toArray(),
        target: window._controls.target.toArray()
      };
    });
    console.log('Camera:', JSON.stringify(camInfo));

    // Screenshots
    await page.evaluate(() => { window._camera.position.set(200, 140, 250); window._controls.target.set(0, 15, 90); window._controls.update(); });
    await page.waitForTimeout(300);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v3_full.png') });
    console.log('Shot: v3_full.png');

    await page.evaluate(() => { window._isolatePart('crank'); });
    await page.waitForTimeout(300);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v3_solo_crank.png') });
    console.log('Shot: v3_solo_crank.png');

    await page.evaluate(() => { window._isolatePart('hopper'); });
    await page.waitForTimeout(300);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v3_solo_hopper.png') });
    console.log('Shot: v3_solo_hopper.png');

    await page.evaluate(() => { window._isolatePart('rollers_upper'); });
    await page.waitForTimeout(300);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v3_solo_rollers_upper.png') });
    console.log('Shot: v3_solo_rollers_upper.png');

    await page.evaluate(() => { window._isolatePart('layshaft'); });
    await page.waitForTimeout(300);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v3_solo_layshaft.png') });
    console.log('Shot: v3_solo_layshaft.png');

    await page.evaluate(() => { window._isolatePart('twister'); });
    await page.waitForTimeout(300);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v3_solo_twister.png') });
    console.log('Shot: v3_solo_twister.png');

    pruneShots();
    console.log('\nAll checks done. Failures:', fail ? 1 : 0);
    if (fail) console.log('FAILED:', fail);
  } finally {
    await pool.releaseBrowser(browser);
  }
})().catch(err => { console.error(err); process.exit(1); });
