const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v35 verify: v34 checks adapted to thinnest-wall pipe (OD10/ID7.6/wall1.2
// L10, gap 10 kept, fold 4/R1.5 outer 7.8, mouth 7 < ID7.6) + ENTRY proof:
// 45deg lead-in flares present (exit r4.4/h0.6, throat r4.6/h0.8),
// throat centre aligned to drum drop x=100 (<0.5), drop path clear
// cylinder ID7.6, no lip step >0.3. Viewer: _dropSeal bore 7.6/wall 1.2,
// ASSET_V 22.
// Shots: screenshots/v35_*.png (max 25, prune oldest).
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

    // animating
    await page.evaluate(() => { window._overrideAngle = null; });
    await page.waitForTimeout(500);
    const a0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.waitForTimeout(800);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    check(a0 !== a1, 'animating true (crankSpinner rotates)');
    await page.evaluate(() => { window._overrideAngle = 0.6; });

    // FORM proof (unchanged lane)
    const fold = await page.evaluate(() => {
      const f = window._tapeFold;
      if (!f) return null;
      return {
        foldStart: f.foldStart, foldEnd: f.foldEnd, transitEnd: f.transitEnd,
        dropX: f.dropX, laneZ: f.laneZ, R: f.R, trough: 2 * f.hw, wall: f.wall, tapeLen: f.tapeLen
      };
    });
    console.log('Fold:', JSON.stringify(fold));
    check(!!fold, 'form proof hooks present (_tapeFold)');
    if (fold) {
      check(fold.foldStart >= 35 && fold.foldStart <= 45, `forming entry at nip 35..45 (got ${fold.foldStart})`);
      check(fold.foldEnd <= 75 - 4, `forming exit fully west of drum face (${fold.foldEnd} <= 71)`);
      check(fold.transitEnd === 126, `transit reaches plow mouth 126 (got ${fold.transitEnd})`);
      check(fold.laneZ === 13, `lane 13 (got ${fold.laneZ})`);
      check(fold.R === 1.5 && fold.trough === 4.0 && fold.wall === 5.5, 'v35 bend params kept (R1.5/trough4/wall5.5)');
      const outer = fold.trough + 2 * (fold.R + 0.4);
      check(Math.abs(outer - 7.8) < 0.01 && outer < 10, `fold outer ${outer} < OD10`);
      check(fold.trough + 2 * fold.R < 7.6, `pocket mouth inner 7 < ID7.6 (seed lands inside)`);
    }

    // HOVER proof: OD10/ID7.6/wall1.2/L10/gap10
    const seal = await page.evaluate(() => window._dropSeal || null);
    console.log('Hover:', JSON.stringify(seal));
    check(!!seal, 'hover proof hooks present (_dropSeal)');
    if (seal) {
      check(seal.bore === 7.6, `ID=7.6 thinnest wall (got ${seal.bore})`);
      check(seal.outer === 10, `OD=10 (got ${seal.outer})`);
      check(Math.abs((seal.outer - seal.bore) / 2 - 1.2) < 0.01, `wall=1.2 (got ${(seal.outer - seal.bore) / 2})`);
      check(seal.pipeLen === 10, `L=10 (got ${seal.pipeLen})`);
      check(seal.hoverGap === 10, `gap=10 (got ${seal.hoverGap})`);
      check(Math.abs(seal.tubeBottomWorld - 23.4) < 0.01, `pipe bottom 23.4 (got ${seal.tubeBottomWorld})`);
      check(Math.abs(seal.ribbonTop - 13.4) < 0.01, `ribbon top 13.4 (got ${seal.ribbonTop})`);
      check(seal.dropX === 100, `drop at x=100 (got ${seal.dropX})`);
    }

    // LIVE placement: pipe bottom 23.4, ribbon 13.4, gap 10
    const place = await page.evaluate(() => {
      const v = new THREE.Vector3();
      let tubeMin = Infinity;
      (window._partMeshes.hopper || []).forEach(o => o.traverse(m => {
        if (m.isMesh && m.geometry && m.geometry.attributes.position) {
          m.updateWorldMatrix(true, false);
          const p = m.geometry.attributes.position;
          for (let i = 0; i < p.count; i++) {
            v.set(p.getX(i), p.getY(i), p.getZ(i)).applyMatrix4(m.matrixWorld);
            const rx = v.x + 100, ry = v.y;
            if (rx >= 93 && rx <= 107 && ry < tubeMin) tubeMin = ry;
          }
        }
      }));
      const box = new THREE.Box3();
      window._tapeFold.flat.updateWorldMatrix(true, true);
      box.setFromObject(window._tapeFold.flat);
      return { tubeMin: Math.round(tubeMin * 100) / 100, ribbonTop: Math.round(box.max.y * 100) / 100 };
    });
    console.log('Placement:', JSON.stringify(place));
    check(Math.abs(place.tubeMin - 23.4) < 0.3, `pipe bottom world 23.4 (got ${place.tubeMin})`);
    check(Math.abs(place.ribbonTop - 13.4) < 0.1, `ribbon top world 13.4 (got ${place.ribbonTop})`);
    check(Math.abs(place.tubeMin - place.ribbonTop - 10) < 0.35, `live hover gap 10 (got ${Math.round((place.tubeMin - place.ribbonTop) * 100) / 100})`);

    // ENTRY proof from hopper GLB local coords (pipe axis x=0, export base z=0):
    // (a) bore ID7.6 straight section r==3.8, (b) exit flare to r4.4 at lip,
    // (c) throat flare to r4.6 at pipe top, (d) no lip step >0.3 in straight,
    // (e) throat axis centred x=0 (world 100, offset <0.5 via pivot).
    const entry = await page.evaluate(() => {
      const meshes = window._partMeshes.hopper || [];
      const pts = [];
      meshes.forEach(o => o.traverse(m => {
        if (m.isMesh && m.geometry && m.geometry.attributes.position) {
          const p = m.geometry.attributes.position;
          for (let i = 0; i < p.count; i++) pts.push([p.getX(i), p.getY(i), p.getZ(i)]);
        }
      }));
      const near = pts.filter(q => Math.hypot(q[0], q[1]) < 5.3);
      const band = (zc, hw) => near.filter(q => Math.abs(q[2] - zc) < hw);
      // cylinder side walls only carry verts at segment joint rings
      // (bore rings at z=0.6/9.2, flares at 0/0.6 and 9.2/10); r<4.8
      // excludes the outer tube wall (r5) so flare readings are pure.
      const innerR = (arr, cap) => {
        const r = arr.map(q => Math.hypot(q[0], q[1])).filter(r => r < cap);
        if (!r.length) return null;
        return { min: Math.min(...r), max: Math.max(...r), n: r.length };
      };
      const s1 = band(0.6, 0.12), s2 = band(9.2, 0.12);
      const straight = innerR(s1.concat(s2), 4.8);
      const lip = innerR(band(0.3, 0.32), 4.8);
      const throat = innerR(band(9.6, 0.35), 4.8);
      const coneBase = innerR(band(10.4, 0.3), 5.0);
      const pipeX = near.filter(q => Math.abs(q[2] - 5) < 3).map(q => q[0]);
      const meanX = pipeX.reduce((s, x) => s + x, 0) / Math.max(1, pipeX.length);
      // clear-cylinder: no solid verts with r < 3.5 inside straight bore band
      const intruders = near.filter(q => q[2] > 0.6 && q[2] < 9.2 && Math.hypot(q[0], q[1]) < 3.5);
      return { straight, lip, throat, coneBase, meanX: Math.round(meanX * 100) / 100, intruders: intruders.length, pivotX: window._pivots.hopper.position.x };
    });
    console.log('Entry:', JSON.stringify(entry));
    check(!!entry.straight, 'entry bore verts sampled');
    if (entry.straight) {
      check(Math.abs(entry.straight.min - 3.8) < 0.15, `bore ID7.6 straight r=3.8 (got ${entry.straight.min})`);
      check(entry.straight.max - entry.straight.min < 0.3, `no lip step >0.3 in straight (spread ${Math.round((entry.straight.max - entry.straight.min) * 100) / 100})`);
    }
    if (entry.lip) check(entry.lip.max > 3.9, `exit 45deg chamfer present (lip rmax ${entry.lip.max} > 3.9)`);
    else check(false, 'exit lip verts sampled');
    if (entry.throat) check(entry.throat.max > 3.9, `throat 45deg lead-in present (rmax ${entry.throat.max} > 3.9)`);
    else check(false, 'throat verts sampled');
    if (entry.coneBase) check(Math.abs(entry.coneBase.min - 4.6) < 0.3, `cone base r4.6 continuous (got ${entry.coneBase.min})`);
    check(Math.abs(entry.meanX) < 0.2, `throat axis centred local x=0 (got ${entry.meanX})`);
    check(entry.pivotX === 100, `hopper pivot at drum drop x=100 (got ${entry.pivotX}, offset <0.5)`);
    check(entry.intruders === 0, `drop path clear cylinder ID7.6 (intruders ${entry.intruders})`);

    // hopper low-ring outer +-5 (OD10), min_z=0
    const hop = await page.evaluate(() => {
      const meshes = window._partMeshes.hopper || [];
      let minZ = Infinity, loMinX = Infinity, loMaxX = -Infinity;
      meshes.forEach(o => o.traverse(m => {
        if (m.isMesh && m.geometry && m.geometry.attributes.position) {
          const p = m.geometry.attributes.position;
          for (let i = 0; i < p.count; i++) {
            const x = p.getX(i), z = p.getZ(i);
            if (z < minZ) minZ = z;
            if (z < 1.0) { if (x < loMinX) loMinX = x; if (x > loMaxX) loMaxX = x; }
          }
        }
      }));
      return { minZ: Math.round(minZ * 100) / 100, loMinX: Math.round(loMinX * 100) / 100, loMaxX: Math.round(loMaxX * 100) / 100 };
    });
    console.log('Hopper GLB:', JSON.stringify(hop));
    check(Math.abs(hop.minZ) < 0.01, `hopper min_z=0 (got ${hop.minZ})`);
    check(Math.abs(hop.loMinX + 5) < 0.15 && Math.abs(hop.loMaxX - 5) < 0.15, `pipe outer +-5 OD10 (got ${hop.loMinX}..${hop.loMaxX})`);

    // shroud roof 23 + slot 6.45 intact
    const shr = await page.evaluate(() => {
      const meshes = window._partMeshes.shroud || [];
      let maxZ = -Infinity, minAbsY = Infinity, n = 0;
      meshes.forEach(o => o.traverse(m => {
        if (m.isMesh && m.geometry && m.geometry.attributes.position) {
          const p = m.geometry.attributes.position;
          for (let i = 0; i < p.count; i++) {
            const y = p.getY(i), z = p.getZ(i);
            if (z > maxZ) maxZ = z;
            if (z > 20.9) { n++; const ay = Math.abs(y); if (ay < minAbsY) minAbsY = ay; }
          }
        }
      }));
      return { n, maxZ: Math.round(maxZ * 100) / 100, minAbsY: Math.round(minAbsY * 100) / 100 };
    });
    console.log('Shroud GLB:', JSON.stringify(shr));
    check(Math.abs(shr.maxZ - 23) < 0.15, `shroud roof 23 (got ${shr.maxZ})`);
    check(Math.abs(shr.minAbsY - 6.45) < 0.15, `top slot half 6.45 (got ${shr.minAbsY})`);

    // beauty shots: tight entry closeup, drop closeup, side section, end-on
    await page.evaluate(() => { window._setOnlyVisible(['hopper', 'cartridge', 'tape']); });
    await page.evaluate(() => {
      window._camera.position.set(18, 28, 55);
      window._controls.target.set(0, 22, 25);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v35_entry_closeup.png') });
    await page.evaluate(() => {
      window._camera.position.set(30, 35, 90);
      window._controls.target.set(0, 20, 25);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v35_drop_closeup.png') });
    await page.evaluate(() => {
      window._camera.position.set(0, 45, 175);
      window._controls.target.set(0, 35, 25);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v35_side.png') });
    await page.evaluate(() => {
      window._camera.position.set(-95, 30, 25);
      window._controls.target.set(5, 22, 25);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v35_endon.png') });
    await page.evaluate(() => { window._overrideAngle = null; });
    await page.waitForTimeout(500);
    await page.evaluate(() => { window._showAllParts(); });
    await page.screenshot({ path: path.join(SHOT_DIR, 'v35_anim.png') });

    // R->L order + crank back wall regression
    const order = await page.evaluate(() => ({
      drum: window._pivots.drum.position.x,
      shroud: window._pivots.shroud.position.x,
      lower: window._pivots.lower.position.x,
      crankZ: window._pivots.crankMount.position.z
    }));
    console.log('Order:', JSON.stringify(order));
    check(order.drum > order.shroud && order.shroud > order.lower, 'R->L order drum>shroud>roller');
    check(order.crankZ === 8, 'crank back wall (mount z=8 <=> Y=-8)');

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');

    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 22):', assetV);
    check(assetV === '22', 'ASSET_V 22 (GLBs rebuilt)');
    await page.close();

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
