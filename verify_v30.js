const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v30 verify: fold-before-drop order + v29 seal + v28/v27 regression.
// Shots: screenshots/v30_*.png (max 25, prune oldest).
// Asserts: ready, 0 errors, animating, ORDER proof (fold zone 67..100:
// foldStart < dropX, foldEnd at drop (dropX-3 <= foldEnd <= dropX+0.5),
// fold max x <= dropX+7 tube outer => fold before/at drop, never after),
// seal proof (bore=10, outer=14, 0..1 overlap, drop x=100), hopper GLB
// low-ring outer +-7 + min_z=0, bend params intact, R->L order, crank
// back wall, ASSET_V 17.
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
    await page.screenshot({ path: path.join(SHOT_DIR, 'v30_anim_t0.png') });
    await page.evaluate(() => { window._overrideAngle = Math.PI / 2; });
    await page.waitForTimeout(300);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v30_anim_t1.png') });
    await page.evaluate(() => { window._overrideAngle = null; });

    // ORDER proof: fold must sit before/at the drop, never after
    const fold = await page.evaluate(() => {
      const f = window._tapeFold;
      if (!f) return null;
      const gx = f.group.position.x; // world centre of the fold group
      const half = 33 / 2;
      return {
        foldStart: f.foldStart, foldEnd: f.foldEnd, dropX: f.dropX,
        groupCentreX: Math.round(gx * 10) / 10,
        worldMinX: Math.round((gx - half) * 10) / 10,
        worldMaxX: Math.round((gx + half) * 10) / 10,
        R: f.R, trough: 2 * f.hw, wall: f.wall, tapeLen: f.tapeLen
      };
    });
    console.log('Fold:', JSON.stringify(fold));
    check(!!fold, 'order proof hooks present (_tapeFold.foldStart/foldEnd/dropX)');
    if (fold) {
      check(fold.foldStart < fold.dropX, `fold starts upstream (${fold.foldStart} < drop ${fold.dropX})`);
      check(fold.foldEnd >= fold.dropX - 3, `fold exit at drop (${fold.foldEnd} >= ${fold.dropX}-3)`);
      check(fold.foldEnd <= fold.dropX + 0.5, `fold ends before/at drop, not after (${fold.foldEnd} <= ${fold.dropX}+0.5)`);
      check(fold.worldMaxX <= 100 + 7, `fold zone max x <= 100+7 tube outer (got ${fold.worldMaxX})`);
      check(fold.worldMinX >= 58 && fold.worldMinX <= 72, `fold entry in shroud zone (got ${fold.worldMinX})`);
      check(Math.abs(fold.groupCentreX - 83.5) < 0.01, `fold group centred 83.5 (got ${fold.groupCentreX})`);
    }

    // seal proof: constants mirror hopper_body()
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

    // hopper GLB geometry: low-ring (z<1 local) outer x +-7, min_z=0
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

    // end-on shot at the drop: camera looks down -X at the U pocket (x=100)
    await page.evaluate(() => {
      window._camera.position.set(170, 42, -30);
      window._controls.target.set(100, 33, -30);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v30_endon_drop.png') });
    // restore default view + full shot
    await page.evaluate(() => {
      window._camera.position.set(300, 220, 300);
      window._controls.target.set(-20, 55, 40);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v30_full.png') });

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
    console.log('ASSET_V (expect 17):', assetV);
    check(assetV === '17', 'ASSET_V 17 (GLBs rebuilt)');
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
