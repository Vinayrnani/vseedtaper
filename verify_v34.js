const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v34 verify: v33 checks adapted to OD10 exit pipe (ID6/wall2.0 L10,
// gap 10 kept, fold 4/R1.5 outer 7.8<10, transit top 21.15). CAD:
// drop_pipe_od 14->10, drop_pipe_id 10->6, fold_width 6->4,
// tape_bend_radius 1.75->1.5, funnel wide 16->6 throat. Viewer:
// TAPE_BEND_R 1.5, TAPE_FOLD_HW 2.0, _dropSeal 23.4/13.4 bore6/outer10,
// ASSET_V 21.
// Shots: screenshots/v34_*.png (max 25, prune oldest).
// Asserts: ready, 0 errors, animating, FORM (forming 37..70 west of
// face, transit 70..126 under pipe to plow mouth), HOVER (ID6/OD10/
// L10, gap 10, flange-to-tape >=20, fold outer<OD, no wheel clash),
// LIVE placement (pipe bottom 23.4, ribbon 13.4), GLB min_z=0 +
// watertight implied, shroud slot 6.45 + roof 23, bend intact, R->L,
// crank back, ASSET_V 21.
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
    await page.evaluate(() => { window._overrideAngle = 0; });
    await page.waitForTimeout(300);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v34_anim_t0.png') });
    await page.evaluate(() => { window._overrideAngle = Math.PI / 2; });
    await page.waitForTimeout(300);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v34_anim_t1.png') });
    await page.evaluate(() => { window._overrideAngle = 0.6; });

    // FORM proof: fold-before-drop intact at the lowered lane
    const fold = await page.evaluate(() => {
      const f = window._tapeFold;
      if (!f) return null;
      return {
        foldStart: f.foldStart, foldEnd: f.foldEnd, transitEnd: f.transitEnd,
        dropX: f.dropX, laneZ: f.laneZ,
        groupCentreX: Math.round(f.group.position.x * 10) / 10,
        R: f.R, trough: 2 * f.hw, wall: f.wall, tapeLen: f.tapeLen
      };
    });
    console.log('Fold:', JSON.stringify(fold));
    check(!!fold, 'form proof hooks present (_tapeFold)');
    if (fold) {
      check(fold.foldStart < fold.dropX, `forming starts upstream (${fold.foldStart} < drop ${fold.dropX})`);
      check(fold.foldStart >= 35 && fold.foldStart <= 45, `forming entry at nip 35..45 (got ${fold.foldStart})`);
      check(fold.foldEnd <= 75 - 4, `forming exit fully west of drum face (${fold.foldEnd} <= 71)`);
      check(fold.transitEnd === 126, `transit reaches plow mouth 126 (got ${fold.transitEnd})`);
      check(fold.foldEnd < 93 && fold.transitEnd > 107,
        `transit spans pipe inlet+outer (${fold.foldEnd} < 93, ${fold.transitEnd} > 107)`);
      check(fold.laneZ === 13, `lane 13 (got ${fold.laneZ})`);
    }

    // full-U at pipe inlet proof: transit verts at x 92..94 reach full height (13+8.15=21.15)
    const inlet = await page.evaluate(() => {
      const g = window._tapeFold.group;
      g.updateWorldMatrix(true, true);
      const v = new THREE.Vector3();
      let n = 0, top = -Infinity;
      g.traverse(m => {
        if (m.isMesh && m.geometry && m.geometry.attributes.position) {
          const p = m.geometry.attributes.position;
          for (let i = 0; i < p.count; i++) {
            v.set(p.getX(i), p.getY(i), p.getZ(i)).applyMatrix4(m.matrixWorld);
            const wx = v.x + 100;
            if (wx >= 92 && wx <= 94) { n++; if (v.y > top) top = v.y; }
          }
        }
      });
      return { n, top: Math.round(top * 100) / 100 };
    });
    console.log('Inlet:', JSON.stringify(inlet));
    check(inlet.n > 0, 'transit verts sampled at pipe inlet (92..94)');
    check(inlet.top >= 13 + 7.65, `full-U under pipe (top ${inlet.top} >= 20.65, expect ~21.15)`);

    // CLEARANCE proof: tape -> drum disc (R25) + flange rings (R26.5), must be >>1 (no wheel clash)
    const clear = await page.evaluate(() => {
      const dp = new THREE.Vector3();
      window._drumPivot.getWorldPosition(dp);
      const meshes = [];
      window._tapeFold.group.traverse(m => { if (m.isMesh) meshes.push(m); });
      window._tapeFold.flat.traverse(m => { if (m.isMesh) meshes.push(m); });
      const v = new THREE.Vector3();
      let min = Infinity, at = null;
      meshes.forEach(m => {
        m.updateWorldMatrix(true, false);
        const p = m.geometry.attributes.position;
        for (let i = 0; i < p.count; i++) {
          v.set(p.getX(i), p.getY(i), p.getZ(i)).applyMatrix4(m.matrixWorld);
          const dx = v.x - dp.x, dy = v.y - dp.y, dz = Math.abs(v.z - dp.z);
          if (dz <= 7.5) {
            const d = Math.sqrt(dx * dx + dy * dy) - 25;
            if (d < min) { min = d; at = [v.x, v.y, v.z].map(n => Math.round(n * 100) / 100); }
          }
          if (dz >= 4.25 && dz <= 5.75) {
            const d = Math.sqrt(dx * dx + dy * dy) - 26.5;
            if (d < min) { min = d; at = [v.x, v.y, v.z].map(n => Math.round(n * 100) / 100); }
          }
        }
      });
      return { min: Math.round(min * 100) / 100, at, drum: dp.toArray().map(n => Math.round(n * 10) / 10) };
    });
    console.log('Clearance:', JSON.stringify(clear));
    check(isFinite(clear.min), 'clearance sampled (tape verts vs drum envelope)');
    check(clear.min > 10, `fold-to-drum min distance >>1, no clash (got ${clear.min} at ${JSON.stringify(clear.at)})`);

    // HOVER proof (replaces v32 seal): ID6/OD10/L10, gap 10, flange-to-tape >=20
    const seal = await page.evaluate(() => window._dropSeal || null);
    console.log('Hover:', JSON.stringify(seal));
    check(!!seal, 'hover proof hooks present (_dropSeal)');
    if (seal) {
      check(seal.bore === 6, `ID=6 (got ${seal.bore})`);
      check(seal.outer === 10, `OD=10 (got ${seal.outer})`);
      check(seal.pipeLen === 10, `L=10 (got ${seal.pipeLen})`);
      check(seal.hoverGap === 10, `gap=10 (got ${seal.hoverGap})`);
      const gap = seal.tubeBottomWorld - seal.ribbonTop;
      check(Math.abs(seal.tubeBottomWorld - 23.4) < 0.01, `pipe bottom 23.4 (got ${seal.tubeBottomWorld})`);
      check(Math.abs(seal.ribbonTop - 13.4) < 0.01, `ribbon top 13.4 (got ${seal.ribbonTop})`);
      check(Math.abs(gap - 10) < 0.01, `hover gap 10 (got ${gap})`);
      check(gap >= 10 - 0.01, `gap>=10 (got ${gap})`);
      check(33.5 - seal.ribbonTop >= 20, `flange-to-tape>=20 (got ${33.5 - seal.ribbonTop})`);
      check(seal.dropX === 100, `drop at x=100 (got ${seal.dropX})`);
    }

    // v34 LIVE placement proof: pipe bottom near x 93..107 at 23.4 (child +19.4);
    // ribbon top (flat mesh world max Y) at 13.4; live gap 10.
    const place = await page.evaluate(() => {
      const v = new THREE.Vector3();
      let tubeMin = Infinity, tubeMax = -Infinity;
      (window._partMeshes.hopper || []).forEach(o => o.traverse(m => {
        if (m.isMesh && m.geometry && m.geometry.attributes.position) {
          m.updateWorldMatrix(true, false);
          const p = m.geometry.attributes.position;
          for (let i = 0; i < p.count; i++) {
            v.set(p.getX(i), p.getY(i), p.getZ(i)).applyMatrix4(m.matrixWorld);
            const rx = v.x + 100, ry = v.y;
            if (rx >= 93 && rx <= 107) {
              if (ry < tubeMin) tubeMin = ry;
              if (ry > tubeMax && ry < 40) tubeMax = ry;
            }
          }
        }
      }));
      const box = new THREE.Box3();
      window._tapeFold.flat.updateWorldMatrix(true, true);
      box.setFromObject(window._tapeFold.flat);
      const ribbonTop = box.max.y;
      const childOffset = tubeMin - 4; // pivot Y=4, GLB minZ=0
      // pocket top under the pipe (transit group max Y near x 93..107)
      const g = window._tapeFold.group;
      g.updateWorldMatrix(true, true);
      let pocketTop = -Infinity;
      const w = new THREE.Vector3();
      g.traverse(m => {
        if (m.isMesh && m.geometry && m.geometry.attributes.position) {
          const p = m.geometry.attributes.position;
          for (let i = 0; i < p.count; i++) {
            w.set(p.getX(i), p.getY(i), p.getZ(i)).applyMatrix4(m.matrixWorld);
            if (w.x + 100 >= 93 && w.x + 100 <= 107 && w.y > pocketTop) pocketTop = w.y;
          }
        }
      });
      return {
        tubeMin: Math.round(tubeMin * 100) / 100,
        tubeMax: Math.round(tubeMax * 100) / 100,
        ribbonTop: Math.round(ribbonTop * 100) / 100,
        pocketTop: Math.round(pocketTop * 100) / 100,
        childOffset: Math.round(childOffset * 100) / 100
      };
    });
    console.log('Placement:', JSON.stringify(place));
    check(Math.abs(place.tubeMin - 23.4) < 0.3, `pipe bottom world 23.4 (got ${place.tubeMin})`);
    check(Math.abs(place.ribbonTop - 13.4) < 0.1, `ribbon top world 13.4 (got ${place.ribbonTop})`);
    check(Math.abs(place.childOffset - 19.4) < 0.3, `hopper child re-seat +19.4 (got ${place.childOffset})`);
    const liveGap = place.tubeMin - place.ribbonTop;
    check(Math.abs(liveGap - 10) < 0.35, `live hover gap 10 (got ${Math.round(liveGap * 100) / 100})`);
    check(liveGap >= 10 - 0.35, `live gap>=10 (got ${Math.round(liveGap * 100) / 100})`);
    check(place.pocketTop < place.tubeMin, `no touch: pocket ${place.pocketTop} < pipe ${place.tubeMin}`);
    check(33.5 - place.ribbonTop >= 20, `live flange-to-tape>=20 (got ${Math.round((33.5 - place.ribbonTop) * 100) / 100})`);

    // hopper GLB: low-ring outer +-5 (OD10), min_z=0
    const hop = await page.evaluate(() => {
      const meshes = window._partMeshes.hopper || [];
      let minZ = Infinity, loMinX = Infinity, loMaxX = -Infinity, n = 0;
      meshes.forEach(o => o.traverse(m => {
        if (m.isMesh && m.geometry && m.geometry.attributes.position) {
          const p = m.geometry.attributes.position;
          for (let i = 0; i < p.count; i++) {
            const x = p.getX(i), z = p.getZ(i);
            if (z < minZ) minZ = z;
            if (z < 1.0) { if (x < loMinX) loMinX = x; if (x > loMaxX) loMaxX = x; n++; }
          }
        }
      }));
      return {
        minZ: Math.round(minZ * 100) / 100,
        loMinX: Math.round(loMinX * 100) / 100,
        loMaxX: Math.round(loMaxX * 100) / 100, n,
        pivotX: window._pivots.hopper.position.x
      };
    });
    console.log('Hopper GLB:', JSON.stringify(hop));
    check(hop.n > 0, 'hopper low-ring verts sampled');
    check(Math.abs(hop.minZ) < 0.01, `hopper min_z=0 (got ${hop.minZ})`);
    check(Math.abs(hop.loMinX + 5) < 0.15 && Math.abs(hop.loMaxX - 5) < 0.15,
      `pipe outer +-5 OD10 (got ${hop.loMinX}..${hop.loMaxX})`);
    check(hop.pivotX === 100, `hopper pivot at drum centre x=100 (got ${hop.pivotX})`);

    // shroud GLB: roof 23 + top slot half 6.45, strips remain
    const shr = await page.evaluate(() => {
      const meshes = window._partMeshes.shroud || [];
      let maxZ = -Infinity, minAbsY = Infinity, strip = 0, n = 0;
      meshes.forEach(o => o.traverse(m => {
        if (m.isMesh && m.geometry && m.geometry.attributes.position) {
          const p = m.geometry.attributes.position;
          for (let i = 0; i < p.count; i++) {
            const y = p.getY(i), z = p.getZ(i);
            if (z > maxZ) maxZ = z;
            if (z > 20.9) {
              n++;
              const ay = Math.abs(y);
              if (ay < minAbsY) minAbsY = ay;
              if (ay >= 6.3) strip++;
            }
          }
        }
      }));
      return { n, maxZ: Math.round(maxZ * 100) / 100, minAbsY: Math.round(minAbsY * 100) / 100, strip };
    });
    console.log('Shroud GLB:', JSON.stringify(shr));
    check(Math.abs(shr.maxZ - 23) < 0.15, `shroud roof 23 (got ${shr.maxZ})`);
    check(shr.n > 0, 'shroud top-plate verts sampled');
    check(Math.abs(shr.minAbsY - 6.45) < 0.15, `top slot half 6.45 (got ${shr.minAbsY})`);
    check(shr.strip > 0, 'cover strips remain over wings');

    // beauty shots: drop closeup (pipe+tape at x=100), side, endon
    await page.evaluate(() => { window._setOnlyVisible(['hopper', 'cartridge', 'tape']); });
    await page.evaluate(() => {
      window._camera.position.set(30, 35, 90);
      window._controls.target.set(0, 20, 25);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v34_drop_closeup.png') });
    await page.evaluate(() => {
      window._camera.position.set(0, 45, 175);
      window._controls.target.set(0, 35, 25);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v34_side.png') });
    await page.evaluate(() => {
      window._camera.position.set(-95, 30, 25);
      window._controls.target.set(5, 22, 25);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v34_endon.png') });
    await page.evaluate(() => {
      window._showAllParts();
      window._camera.position.set(300, 220, 300);
      window._controls.target.set(-20, 55, 40);
      window._controls.update();
    });
    await page.waitForTimeout(400);

    // bend params v34 + fold-outer proof (outer=trough+2*(R+0.4)=7.8<OD10, mouth inner=trough+2R=7~=ID6)
    check(!!fold && fold.R === 1.5 && fold.trough === 4.0 && fold.wall === 5.5, 'v34 bend params (R1.5/trough4/wall5.5)');
    if (fold) {
      const outer = fold.trough + 2 * (fold.R + 0.4);
      check(Math.abs(outer - 7.8) < 0.01 && outer < 10, `fold outer ${outer} < OD10`);
      check(Math.abs(fold.trough + 2 * fold.R - 7) < 0.01, `pocket mouth inner 7 ~= ID6`);
    }
    check(fold && fold.tapeLen === 180, 'TAPE_LEN 180 intact');

    // R->L order + crank back wall regression
    const order = await page.evaluate(() => {
      const box = new THREE.Box3();
      window._partMeshes.hopper.forEach(o => o.updateWorldMatrix(true, true));
      box.setFromObject(window._partMeshes.hopper[0]);
      const rootPos = new THREE.Vector3(-100, 0, 55);
      const toRoot = v => v.clone().sub(rootPos);
      const mx = toRoot(box.max).x;
      return {
        hopperMaxX: Math.round(mx * 10) / 10,
        drum: window._pivots.drum.position.x,
        shroud: window._pivots.shroud.position.x,
        lower: window._pivots.lower.position.x,
        spool: window._pivots.spool.position.x,
        crankZ: window._pivots.crankMount.position.z
      };
    });
    console.log('Order:', JSON.stringify(order));
    check(order.hopperMaxX > order.drum && order.drum > order.shroud && order.shroud > order.lower, 'R->L order hopper>drum>shroud>roller');
    check(order.crankZ === 8, 'crank back wall (mount z=8 <=> Y=-8)');

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');

    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 21):', assetV);
    check(assetV === '21', 'ASSET_V 21 (GLBs rebuilt)');
    const srcs = await page.evaluate(() => Array.from(document.querySelectorAll('script[src]')).map(x => x.getAttribute('src')).join(','));
    check(/js\/three\.min\.js/.test(srcs) && !/cdn/i.test(srcs), 'vendored three.js local, never CDN');
    await page.close();

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
