const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');

// v52 verify: SMALLER VERTICAL PULLERS + 9.5mm NIP GAP.
// CAD: vpull_r 10->7.5 (d15), sleeve 10.15->7.65, h 24->20, sleeve_h
// 16->12, caps/collar d22->d17; vpull_gap=9.5, off=12.4, Y=17.6/42.4;
// spin 4/3; bridge 28, cup 25, pins ->27; fail-loud gap assert.
// Viewer: pivots (194,4,-17.6)/(194,4,-42.4), PULL_SPIN 4/3 (4 sites),
// ASSET_V 36, pull_a/pull_b + chassis GLBs rebuilt.
// Live proof: animating + pull world boxes (d17/h23, z-sep 24.8) +
// nip closeup + iso, 0 errors.
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
  const { browser, page } = await pool.newPage({ width: 1600, height: 1000 });
  try {
    const errors = [];
    page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
    page.on('pageerror', err => errors.push(err.message));
    await page.goto(`http://localhost:9099/index.html?v=${V}`);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 30000 });
    console.log('Desktop: status=ready');

    await page.evaluate(() => { window._overrideAngle = null; window._showAllParts(); });
    await page.waitForTimeout(400);
    const a0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.waitForTimeout(700);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    check(a0 !== a1, 'animating true (crankSpinner rotates)');

    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 36):', assetV);
    check(assetV === '36', 'ASSET_V 36 (pull_a/pull_b + chassis GLBs rebuilt)');

    const spinSrc = await page.evaluate(() => ({
      def: (document.documentElement.innerHTML.match(/var PULL_SPIN = ([^;]+);/) || [])[1],
      uses: (window._setRotations.toString().match(/PULL_SPIN/g) || []).length
        + (document.documentElement.innerHTML.match(/pullAPivot\.rotation\.y = PULL_SPIN/g) || []).length
        + (document.documentElement.innerHTML.match(/pullBPivot\.rotation\.y = -PULL_SPIN/g) || []).length
    }));
    console.log('PULL_SPIN:', JSON.stringify(spinSrc));
    check(spinSrc.def && spinSrc.def.trim() === '4 / 3', 'PULL_SPIN defined as 4/3');
    check(spinSrc.uses >= 4, `PULL_SPIN scales pull rotations at 4 sites (got ${spinSrc.uses})`);

    // Pull world boxes (world = CAD M_R + root offset (-100,0,55)):
    // A CAD [194,17.6,4] -> world (94,4,37.4); B CAD [194,42.4,4] -> (94,4,12.6).
    // NOTE: parts spin live; Box3 of a rotated box inflates the AABB, so
    // zero the pivot Y-rotation during measurement, then restore.
    const pulls = await page.evaluate(() => {
      const out = {};
      for (const id of ['pull_a', 'pull_b']) {
        const grp = (window._partMeshes[id] || [])[0];
        if (!grp) { out[id] = null; continue; }
        const pivot = grp.parent;
        const saved = pivot.rotation.y;
        pivot.rotation.y = 0;
        const box = new THREE.Box3();
        grp.traverse(m => {
          if (m.isMesh && m.geometry && m.geometry.attributes.position) {
            m.updateWorldMatrix(true, false);
            box.expandByObject(m);
          }
        });
        pivot.rotation.y = saved;
        if (box.isEmpty()) { out[id] = null; continue; }
        const s = box.getSize(new THREE.Vector3()), c = box.getCenter(new THREE.Vector3());
        out[id] = { sx: s.x, sy: s.y, sz: s.z, cx: c.x, cy: c.y, cz: c.z };
      }
      return out;
    });
    console.log('pull boxes:', JSON.stringify(pulls));
    check(!!pulls.pull_a && !!pulls.pull_b, 'both pull GLBs present');
    for (const id of ['pull_a', 'pull_b']) {
      const b = pulls[id];
      check(!!b && Math.abs(b.sx - 17) < 0.6 && Math.abs(b.sy - 17) < 0.6, `${id} OD ~d17 caps (got ${b && b.sx}/${b && b.sy})`);
      check(!!b && Math.abs(b.sz - 23) < 0.6, `${id} height ~23 (h20 + cap 3, got ${b && b.sz})`);
    }
    check(!!pulls.pull_a && Math.abs(pulls.pull_a.cx - 94) < 1 && Math.abs(pulls.pull_a.cz - 37.4) < 1,
      `pull A at world (94,37.4) = CAD Y17.6 (got ${pulls.pull_a && pulls.pull_a.cx},${pulls.pull_a && pulls.pull_a.cz})`);
    check(!!pulls.pull_b && Math.abs(pulls.pull_b.cx - 94) < 1 && Math.abs(pulls.pull_b.cz - 12.6) < 1,
      `pull B at world (94,12.6) = CAD Y42.4 (got ${pulls.pull_b && pulls.pull_b.cx},${pulls.pull_b && pulls.pull_b.cz})`);
    const zsep = !!pulls.pull_a && !!pulls.pull_b && Math.abs(pulls.pull_a.cz - pulls.pull_b.cz);
    check(zsep && Math.abs(zsep - 24.8) < 0.3, `nip pair z-separation 24.8 (2x12.4, gap 9.5, got ${zsep})`);

    // Tape-static regression (v45): ribbon stays centred while animating.
    await page.evaluate(() => { window._overrideAngle = 0.6; });
    await page.waitForTimeout(200);
    const tx0 = await page.evaluate(() => window._tapeFold.flat.position.x);
    await page.evaluate(() => { window._overrideAngle = null; });
    await page.waitForTimeout(1200);
    const tx1 = await page.evaluate(() => window._tapeFold.flat.position.x);
    console.log(`tapeGroup.x frozen=${tx0} animating=${tx1}`);
    check(tx0 === tx1 && tx0 === 97, `tape ribbon STATIC, centred CAD span (got ${tx0}/${tx1})`);

    await page.evaluate(() => window._setPanelCollapsed(true));
    async function shot(f, cam, tgt, only, ang) {
      await page.evaluate((o) => { if (o) window._setOnlyVisible(o); else window._showAllParts(); }, only || null);
      if (ang === null || ang === undefined) await page.evaluate(() => { window._overrideAngle = null; });
      else await page.evaluate((a) => { window._overrideAngle = a; }, ang);
      await page.evaluate(([c, t]) => {
        window._camera.position.set(c[0], c[1], c[2]);
        window._controls.target.set(t[0], t[1], t[2]);
        window._controls.update();
      }, [cam, tgt]);
      await page.waitForTimeout(450);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      console.log('Shot:', f);
    }
    const nip = [94, 4, 25];
    await shot('v52_nip_closeup.png', [94 + 45, 4 - 45, 25 + 30], nip, ['pull_a', 'pull_b'], 0.6);
    await shot('v52_pull_station.png', [94 + 55, 4 + 40, 25 + 55], nip, null, 0.6);
    await shot('v52_iso.png', [185, 175, 235], [20, 35, 25], null, null);
    await page.evaluate(() => { window._showAllParts(); window._overrideAngle = null; window._setPanelCollapsed(false); });
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v52_anim_t0.png') });
    console.log('Shot: v52_anim_t0.png (animating)');
    await page.waitForTimeout(2500);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v52_anim_t1.png') });
    console.log('Shot: v52_anim_t1.png (animating, +2.5s)');
    pruneShots();

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');

    if (fail) { console.log('VERIFY_V52_RESULT: FAIL - ' + fail); process.exitCode = 1; }
    else console.log('VERIFY_V52_RESULT: PASS');
  } finally {
    await pool.releaseBrowser(browser);
  }
})().catch(e => { console.error('VERIFY_V52_RESULT: ERROR', e); process.exit(1); });
