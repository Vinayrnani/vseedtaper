const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v37 verify: v36 MVP tail build (thread-bind + vertical pull + wind-up).
// Checks: animating + synced downstream chain (twister -3x crank about X,
// pull +/-2x about Y, takeup -2x about Z), _twister hooks (bind 167,
// 2 arms, 6 orbits/drum), thread helix lines present, pivots at
// bind/pull/wind stations, new GLBs load (min_z=0, no errors),
// R->L order + crank back wall + lane/hover regressions intact,
// ASSET_V 23. Shots: screenshots/v37_*.png (max 25, prune oldest).
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
  if (!cond && !fail) fail = msg;
}

(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
  try {
    const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
    const errors = [];
    page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
    page.on('pageerror', err => errors.push(err.message));
    await page.goto(`http://localhost:9099/index.html?v=${V}`);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 25000 });
    console.log('Desktop: status=ready');

    // animating (live, no override)
    await page.evaluate(() => { window._overrideAngle = null; });
    await page.waitForTimeout(500);
    const a0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.waitForTimeout(800);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    check(a0 !== a1, 'animating true (crankSpinner rotates)');

    // downstream chain sync: sample twister/pull/takeup across two frames
    const sync = await page.evaluate(() => {
      const g = (p) => ({ x: p.rotation.x, y: p.rotation.y, z: p.rotation.z });
      return {
        c0: window._crankSpinner.rotation.z,
        tw0: window._pivots.twister.rotation.x,
        pa0: window._pivots.pullA.rotation.y,
        pb0: window._pivots.pullB.rotation.y,
        tk0: window._pivots.takeup.rotation.z,
        drum0: window._drumPivot.rotation.z
      };
    });
    await page.waitForTimeout(700);
    const sync1 = await page.evaluate(() => ({
      c1: window._crankSpinner.rotation.z,
      tw1: window._pivots.twister.rotation.x,
      pa1: window._pivots.pullA.rotation.y,
      pb1: window._pivots.pullB.rotation.y,
      tk1: window._pivots.takeup.rotation.z,
      drum1: window._drumPivot.rotation.z
    }));
    const dC = sync1.c1 - sync.c0;
    console.log('Sync deltas:', JSON.stringify({ dC, dTw: sync1.tw1 - sync.tw0, dPa: sync1.pa1 - sync.pa0, dPb: sync1.pb1 - sync.pb0, dTk: sync1.tk1 - sync.tk0, dDrum: sync1.drum1 - sync.drum0 }));
    check(Math.abs(dC) > 1e-4, 'crank advances while animating');
    if (Math.abs(dC) > 1e-4) {
      // crankSpinner.rotation.z = -crankAngle - phase: dC = -dCrank
      const dCrank = -dC;
      check(Math.abs((sync1.tw1 - sync.tw0) / dCrank + 3) < 0.05, `twister -3x crank (got ${(sync1.tw1 - sync.tw0) / dCrank})`);
      check(Math.abs((sync1.pa1 - sync.pa0) / dCrank - 2) < 0.05, `pullA +2x crank (got ${(sync1.pa1 - sync.pa0) / dCrank})`);
      check(Math.abs((sync1.pb1 - sync.pb0) / dCrank + 2) < 0.05, `pullB -2x crank (got ${(sync1.pb1 - sync.pb0) / dCrank})`);
      check(Math.abs((sync1.tk1 - sync.tk0) / dCrank + 2) < 0.05, `takeup -2x crank (got ${(sync1.tk1 - sync.tk0) / dCrank})`);
      check(Math.abs((sync1.drum1 - sync.drum0) / dCrank - 0.5) < 0.05, `drum +0.5x crank kept (got ${(sync1.drum1 - sync.drum0) / dCrank})`);
      // twister = 6x drum magnitude
      check(Math.abs(Math.abs((sync1.tw1 - sync.tw0) / (sync1.drum1 - sync.drum0)) - 6) < 0.1, 'twister 6 orbits per drum rev (one bind per seed)');
    }
    await page.evaluate(() => { window._overrideAngle = 0.6; });

    // _twister proof hooks
    const tw = await page.evaluate(() => {
      const t = window._twister;
      if (!t) return null;
      return { bindX: t.bindX, arms: t.arms, orbitsPerDrum: t.orbitsPerDrum, pullX: t.pullX, takeupX: t.takeupX, nLines: t.lines.length };
    });
    console.log('Twister:', JSON.stringify(tw));
    check(!!tw, '_twister hooks present');
    if (tw) {
      check(tw.bindX === 167, `bind station 167 = plow_end+8 (got ${tw.bindX})`);
      check(tw.arms === 2, `2 thread arms (got ${tw.arms})`);
      check(tw.orbitsPerDrum === 6, `6 orbits per drum rev (got ${tw.orbitsPerDrum})`);
      check(tw.pullX === 181 && tw.takeupX === 186, `pull 181 / wind-up 186 (got ${tw.pullX}/${tw.takeupX})`);
      check(tw.nLines === 2, `2 procedural thread lines (got ${tw.nLines})`);
    }

    // pivots at stations + thread line points near bind zone
    const piv = await page.evaluate(() => ({
      twx: window._pivots.twister.position.x,
      pax: window._pivots.pullA.position.x,
      pbx: window._pivots.pullB.position.x,
      tkx: window._pivots.takeup.position.x,
      thrPts: window._twister.lines[0].geometry.attributes.position.count
    }));
    console.log('Pivots:', JSON.stringify(piv));
    check(piv.twx === 167 && piv.pax === 181 && piv.pbx === 181 && piv.tkx === 186, 'pivots at bind/pull/wind stations');
    check(piv.thrPts === 42, 'thread helix has 42 points');

    // new GLBs loaded with content + min_z=0 (local export coords)
    const glbs = await page.evaluate(() => {
      const out = {};
      ['twister', 'pull_a', 'pull_b', 'takeup'].forEach(id => {
        const meshes = window._partMeshes[id] || [];
        let n = 0, minZ = Infinity;
        meshes.forEach(o => o.traverse(m => {
          if (m.isMesh && m.geometry && m.geometry.attributes.position) {
            const p = m.geometry.attributes.position;
            n += p.count;
            for (let i = 0; i < p.count; i++) { const z = p.getZ(i); if (z < minZ) minZ = z; }
          }
        }));
        out[id] = { verts: n, minZ: n ? Math.round(minZ * 100) / 100 : null };
      });
      return out;
    });
    console.log('GLBs:', JSON.stringify(glbs));
    ['twister', 'pull_a', 'pull_b', 'takeup'].forEach(id => {
      check(glbs[id] && glbs[id].verts > 100, `${id}.glb loaded (${glbs[id] ? glbs[id].verts : 0} verts)`);
      if (glbs[id] && glbs[id].verts) check(Math.abs(glbs[id].minZ) < 0.01, `${id} min_z=0 (got ${glbs[id].minZ})`);
    });

    // lane + hover regressions intact
    const fold = await page.evaluate(() => ({ laneZ: window._tapeFold.laneZ, tapeLen: window._tapeFold.tapeLen }));
    check(fold.laneZ === 13 && fold.tapeLen === 220, `lane 13 + tape 220 (got ${fold.laneZ}/${fold.tapeLen})`);
    const seal = await page.evaluate(() => window._dropSeal || null);
    check(seal && seal.bore === 7.6 && seal.hoverGap === 10, 'hover seal intact (ID7.6, gap 10)');

    // beauty shots: bind closeup, pull/wind closeup, full animating
    await page.evaluate(() => { window._setOnlyVisible(['plow', 'twister', 'pull_a', 'pull_b', 'tape', 'seeds']); });
    await page.evaluate(() => {
      window._camera.position.set(60, 30, 60);
      window._controls.target.set(67, 17, 25);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v37_bind_closeup.png') });
    await page.evaluate(() => { window._setOnlyVisible(['pull_a', 'pull_b', 'takeup', 'twister', 'tape', 'seeds']); });
    await page.evaluate(() => {
      window._camera.position.set(85, 40, 70);
      window._controls.target.set(86, 20, 25);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v37_pull_wind.png') });
    await page.evaluate(() => { window._overrideAngle = null; });
    await page.waitForTimeout(500);
    await page.evaluate(() => { window._showAllParts(); });
    await page.evaluate(() => {
      window._camera.position.set(300, 220, 300);
      window._controls.target.set(-20, 55, 40);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v37_anim.png') });

    // R->L order + crank back wall regression
    const order = await page.evaluate(() => ({
      drum: window._pivots.drum.position.x,
      shroud: window._pivots.shroud.position.x,
      lower: window._pivots.lower.position.x,
      crankZ: window._pivots.crankMount.position.z,
      takeupX: window._pivots.takeup.position.x
    }));
    console.log('Order:', JSON.stringify(order));
    check(order.drum > order.shroud && order.shroud > order.lower, 'R->L order drum>shroud>roller');
    check(order.crankZ === 8, 'crank back wall (mount z=8 <=> Y=-8)');
    check(order.takeupX > order.drum, 'wind-up east of drum');

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');

    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 23):', assetV);
    check(assetV === '23', 'ASSET_V 23 (GLBs rebuilt)');
    await page.close();

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
