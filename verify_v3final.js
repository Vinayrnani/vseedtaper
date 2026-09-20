const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');

const SHOT_DIR = path.join(__dirname, 'screenshots');
fs.mkdirSync(SHOT_DIR, { recursive: true });
function pruneShots(max) {
  const files = fs.readdirSync(SHOT_DIR)
    .filter(f => f.endsWith('.png'))
    .map(f => ({ f, m: fs.statSync(path.join(SHOT_DIR, f)).mtimeMs }))
    .sort((a, b) => a.m - b.m);
  while (files.length > max) {
    const old = files.shift();
    fs.unlinkSync(path.join(SHOT_DIR, old.f));
    console.log('Pruned old screenshot:', old.f);
  }
}
pruneShots(20);

const IDS = ['chassis','cartridge','hopper','rollers','rollers_upper','crank','folder','twister','layshaft'];
let fails = [];
function check(cond, msg) {
  console.log((cond ? 'PASS ' : 'FAIL ') + msg);
  if (!cond) fails.push(msg);
}

(async () => {
  const { browser, page } = await pool.newPage({ width: 1600, height: 1000 });
  try {
    const errors = [];
    page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
    page.on('pageerror', err => errors.push(String((err && err.message) || err)));
    await page.goto('http://localhost:9099/index.html?v=' + Date.now());
    await page.waitForFunction(() => {
      const el = document.getElementById('status');
      return el && /ready/.test(el.textContent);
    }, { timeout: 45000 });
    console.log('status:', await page.evaluate(() => document.getElementById('status').textContent));

    const assetV = await page.evaluate(() => (document.documentElement.innerHTML.match(/ASSET_V = (\d+)/) || [])[1]);
    console.log('ASSET_V:', assetV);
    check(assetV === '57', 'ASSET_V is 57 (fresh v3 rebuild)');

    const loadErr = await page.evaluate(() => {
      const el = document.getElementById('errors');
      return { hidden: !el || el.style.display === 'none', html: el ? el.innerHTML.slice(0, 200) : '' };
    });
    console.log('load errors box:', JSON.stringify(loadErr));
    check(loadErr.hidden, 'no failed GLB loads');

    const partStats = await page.evaluate((ids) => {
      const out = {};
      ids.forEach(id => {
        const arr = window._partMeshes[id] || [];
        let meshes = 0, verts = 0;
        const bb = new THREE.Box3();
        arr.forEach(s => s.traverse(o => {
          if (o.isMesh) {
            meshes++;
            const g = o.geometry;
            verts += (g.attributes && g.attributes.position) ? g.attributes.position.count : 0;
            bb.expandByObject(o);
          }
        }));
        out[id] = { scenes: arr.length, meshes, verts,
          bbox: bb.isEmpty() ? null : [bb.min.toArray().map(v => +v.toFixed(1)), bb.max.toArray().map(v => +v.toFixed(1))] };
      });
      return out;
    }, IDS);
    console.log('Part stats: ' + JSON.stringify(partStats));
    IDS.forEach(id => check(partStats[id].scenes > 0 && partStats[id].verts > 0, id + ' renders (verts=' + partStats[id].verts + ')'));
    const sigs = IDS.map(id => partStats[id].verts + '|' + JSON.stringify(partStats[id].bbox));
    const distinct = new Set(sigs).size;
    console.log('distinct geometry signatures: ' + distinct + '/9');
    check(distinct === 9, 'all 9 GLBs distinct geometry (prev bug: 9 identical full-machine exports)');

    const hopperParent = await page.evaluate(() => {
      const h = (window._partMeshes.hopper || [])[0];
      if (!h) return 'missing';
      if (h.parent === window._root) return 'root';
      if (h.parent === window._drumPivot) return 'drumPivot';
      return 'other';
    });
    console.log('hopper parent:', hopperParent);
    check(hopperParent === 'root', 'hopper parented to root (prev bug: drumPivot)');

    const cam = await page.evaluate(() => ({
      pos: window._camera.position.toArray().map(v => +v.toFixed(1)),
      tgt: window._controls.target.toArray().map(v => +v.toFixed(1))
    }));
    console.log('default camera:', JSON.stringify(cam));
    check(Math.hypot(cam.pos[0]-200, cam.pos[1]-140, cam.pos[2]-250) < 5, 'default cam pos ~(200,140,250), got ' + JSON.stringify(cam.pos));
    check(Math.hypot(cam.tgt[0]-0, cam.tgt[1]-15, cam.tgt[2]-90) < 5, 'default target ~(0,15,90), got ' + JSON.stringify(cam.tgt));

    const framing = await page.evaluate(() => {
      const box = new THREE.Box3();
      Object.keys(window._partMeshes).forEach(id => {
        (window._partMeshes[id] || []).forEach(s => s.traverse(o => { if (o.isMesh) box.expandByObject(o); }));
      });
      let allIn = true;
      for (const x of [box.min.x, box.max.x]) for (const y of [box.min.y, box.max.y]) for (const z of [box.min.z, box.max.z]) {
        const v = new THREE.Vector3(x, y, z).project(window._camera);
        if (Math.abs(v.x) > 1 || Math.abs(v.y) > 1 || v.z > 1) allIn = false;
      }
      return { box: [box.min.toArray().map(v => +v.toFixed(1)), box.max.toArray().map(v => +v.toFixed(1))], allIn };
    });
    console.log('machine bbox + in-frame:', JSON.stringify(framing));
    check(framing.allIn, 'whole machine fits in frame at load');

    const pivOk = await page.evaluate(() => !!window._pivots && !!window._pivots.drum && !!window._pivots.twister && !!window._crankSpinner);
    check(pivOk, 'animation pivots exposed (_pivots.drum/twister, _crankSpinner)');
    const r0 = await page.evaluate(() => ({ drum: window._pivots.drum.rotation.z, tw: window._pivots.twister.rotation.x, crank: window._crankSpinner.rotation.z }));
    await page.waitForTimeout(800);
    const r1 = await page.evaluate(() => ({ drum: window._pivots.drum.rotation.z, tw: window._pivots.twister.rotation.x, crank: window._crankSpinner.rotation.z }));
    const dCrank = Math.abs(r1.crank - r0.crank), dDrum = Math.abs(r1.drum - r0.drum), dTw = Math.abs(r1.tw - r0.tw);
    console.log('anim deltas/800ms: crank=' + dCrank.toFixed(3) + ' drum=' + dDrum.toFixed(3) + ' twister=' + dTw.toFixed(3));
    check(dCrank > 0.05 && dDrum > 0 && dTw > 0, 'animation running (crank+drum+twister all move)');
    check(dDrum < dCrank && dTw > dCrank, 'drum slow + twister fast relative to crank');
    const ratio = dTw / Math.max(dDrum, 1e-9);
    console.log('twister:drum ratio=' + ratio.toFixed(1) + ' (expect ~30 = 2.5/(1/12))');
    check(ratio > 20 && ratio < 40, 'twister:drum speed ratio ~30');

    async function shot(name) {
      await page.screenshot({ path: path.join(SHOT_DIR, name) });
      console.log('Shot: ' + name);
    }
    await page.evaluate(() => { window._overrideAngle = null; window._showAllParts(); });
    await page.waitForTimeout(400);
    const allVis = await page.evaluate((ids) => ids.map(id => (window._partMeshes[id] || []).some(s => s.visible)), IDS);
    check(allVis.every(v => v), 'all 9 parts visible in full view');
    await shot('v3fin_full.png');

    for (const id of ['crank', 'twister', 'hopper']) {
      await page.evaluate(p => window._isolatePart(p), id);
      await page.waitForTimeout(350);
      const onlyOn = await page.evaluate(() => Object.keys(window._toggleGroups).filter(k => window._toggleGroups[k].objects.some(o => o && o.visible)));
      check(onlyOn.length === 1 && onlyOn[0] === id, 'solo ' + id + ' shows ONLY itself (visible=' + JSON.stringify(onlyOn) + ')');
      await shot('v3fin_solo_' + id + '.png');
    }

    await page.evaluate(() => { window._showAllParts(); window._camera.position.set(200, 140, 250); window._controls.target.set(0, 15, 90); window._controls.update(); });
    await page.waitForTimeout(900);
    await shot('v3fin_anim.png');

    await page.waitForTimeout(300);
    console.log('Console errors: ' + errors.length + ' ' + JSON.stringify(errors.slice(0, 5)));
    check(errors.length === 0, '0 console errors');

    pruneShots(25);
    console.log('\nV3FINAL: ' + (fails.length ? 'FAIL (' + fails.length + '): ' + JSON.stringify(fails) : 'ALL CHECKS PASSED'));
    if (fails.length) process.exitCode = 1;
  } finally {
    await pool.releaseBrowser(browser);
  }
})().catch(err => { console.error('V3FINAL ERROR:', err); process.exit(1); });
