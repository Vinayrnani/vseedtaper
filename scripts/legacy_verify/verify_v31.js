const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v31 verify: fold-under-drum regression fix + v30 order + v29 seal + v28/v27.
// Shots: screenshots/v31_*.png (max 25, prune oldest).
// Asserts: ready, 0 errors, animating, FORM proof (forming 37..70 west of
// drum face 75-4, transit 70..126 covers pipe inlet 93 + bore 95..105 to
// plow mouth 126, full-U at inlet), CLEARANCE proof (mesh min distance
// fold-to-drum-disc/flanges >1mm), SEAL proof (bore=10, outer=14,
// overlap 0..1, drop x=100), hopper GLB low-ring +-7 + min_z=0, shroud
// top slot (half 6.45), bend params intact, R->L order, crank back wall,
// ASSET_V 18.
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
    await page.screenshot({ path: path.join(SHOT_DIR, 'v31_anim_t0.png') });
    await page.evaluate(() => { window._overrideAngle = Math.PI / 2; });
    await page.waitForTimeout(300);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v31_anim_t1.png') });
    await page.evaluate(() => { window._overrideAngle = 0.6; });

    // FORM proof: forming west of drum, transit supplies the pipe
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
      check(Math.abs(fold.groupCentreX - 53.5) < 0.01, `forming group centred 53.5 (got ${fold.groupCentreX})`);
      check(fold.laneZ === 24, `lane 24 (got ${fold.laneZ})`);
    }

    // full-U at pipe inlet proof: transit verts at x 92..94 reach full height
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
            const wx = v.x + 100; // world->scad x (world x = scad-100 near drum)
            if (wx >= 92 && wx <= 94) { n++; if (v.y > top) top = v.y; }
          }
        }
      });
      return { n, top: Math.round(top * 100) / 100 };
    });
    console.log('Inlet:', JSON.stringify(inlet));
    check(inlet.n > 0, 'transit verts sampled at pipe inlet (92..94)');
    check(inlet.top >= 24 + 7.5, `full-U at side inlet (top ${inlet.top} >= 31.5)`);

    // CLEARANCE proof: mesh min distance tape -> drum disc (R25) + flange rings (R26.5)
    const clear = await page.evaluate(() => {
      const dp = new THREE.Vector3();
      window._drumPivot.getWorldPosition(dp); // (0,60,25)
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
          if (dz <= 7.5) { // drum disc slab (width 15)
            const d = Math.sqrt(dx * dx + dy * dy) - 25;
            if (d < min) { min = d; at = [v.x, v.y, v.z].map(n => Math.round(n * 100) / 100); }
          }
          if (dz >= 4.25 && dz <= 5.75) { // flange ring slabs (R26.5)
            const d = Math.sqrt(dx * dx + dy * dy) - 26.5;
            if (d < min) { min = d; at = [v.x, v.y, v.z].map(n => Math.round(n * 100) / 100); }
          }
        }
      });
      return { min: Math.round(min * 100) / 100, at, drum: dp.toArray().map(n => Math.round(n * 10) / 10) };
    });
    console.log('Clearance:', JSON.stringify(clear));
    check(isFinite(clear.min), 'clearance sampled (tape verts vs drum envelope)');
    check(clear.min > 1, `fold-to-drum min distance >1mm (got ${clear.min} at ${JSON.stringify(clear.at)})`);

    // seal proof
    const seal = await page.evaluate(() => window._dropSeal || null);
    console.log('Seal:', JSON.stringify(seal));
    check(!!seal, 'seal proof hooks present (_dropSeal)');
    if (seal) {
      check(seal.bore === 10, `bore=10 (got ${seal.bore})`);
      check(seal.outer === 14, `outer=14 (got ${seal.outer})`);
      check(seal.tubeBottomWorld <= seal.ribbonTop,
        `tube bottom ${seal.tubeBottomWorld} <= ribbon top ${seal.ribbonTop} (touch, no gap)`);
      const overlap = seal.ribbonTop - seal.tubeBottomWorld;
      check(overlap >= 0 && overlap <= 1, `overlap 0..1 (got ${overlap})`);
      check(seal.dropX === 100, `drop at x=100 (got ${seal.dropX})`);
    }

    // hopper GLB: low-ring outer +-7, min_z=0
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
    check(Math.abs(hop.loMinX + 7) < 0.15 && Math.abs(hop.loMaxX - 7) < 0.15,
      `tube outer +-7 (got ${hop.loMinX}..${hop.loMaxX})`);
    check(hop.pivotX === 100, `hopper pivot at drum centre x=100 (got ${hop.pivotX})`);

    // shroud GLB: top slot half 6.45 (no plate verts |y|<6.3 above z=31.9), strips remain
    const shr = await page.evaluate(() => {
      const meshes = window._partMeshes.shroud || [];
      let minAbsY = Infinity, strip = 0, n = 0;
      meshes.forEach(o => o.traverse(m => {
        if (m.isMesh && m.geometry && m.geometry.attributes.position) {
          const p = m.geometry.attributes.position;
          for (let i = 0; i < p.count; i++) {
            const y = p.getY(i), z = p.getZ(i);
            if (z > 31.9) {
              n++;
              const ay = Math.abs(y);
              if (ay < minAbsY) minAbsY = ay;
              if (ay >= 6.3) strip++;
            }
          }
        }
      }));
      return { n, minAbsY: Math.round(minAbsY * 100) / 100, strip };
    });
    console.log('Shroud GLB:', JSON.stringify(shr));
    check(shr.n > 0, 'shroud top-plate verts sampled');
    check(Math.abs(shr.minAbsY - 6.45) < 0.15, `top slot half 6.45 (got ${shr.minAbsY})`);
    check(shr.strip > 0, 'cover strips remain over wings');

    // isolated beauty shots: drum+tape only (endon at drop, side, top)
    await page.evaluate(() => { window._setOnlyVisible(['cartridge', 'tape']); });
    await page.evaluate(() => {
      window._camera.position.set(-95, 30, 25);
      window._controls.target.set(5, 27, 25);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v31_endon_drop.png') });
    await page.evaluate(() => {
      window._camera.position.set(0, 45, 175);
      window._controls.target.set(0, 40, 25);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v31_side.png') });
    await page.evaluate(() => {
      window._camera.position.set(0, 230, 25);
      window._controls.target.set(-10, 24, 25);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v31_top.png') });
    await page.evaluate(() => {
      window._showAllParts();
      window._camera.position.set(300, 220, 300);
      window._controls.target.set(-20, 55, 40);
      window._controls.update();
    });
    await page.waitForTimeout(400);

    // bend params intact (v28 regression)
    check(!!fold && fold.R === 1.75 && fold.trough === 6.0 && fold.wall === 5.5, 'v28 bend params intact (R1.75/trough6/wall5.5)');
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
    console.log('ASSET_V (expect 18):', assetV);
    check(assetV === '18', 'ASSET_V 18 (GLBs rebuilt)');
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
