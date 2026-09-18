'use strict';
// verify_v69.js — 24:1 twister gear train implementation proof.
// CAD: Green72 M1.5 (drum shaft y46..52) -> layshaft 12T (163,62, 6:1)
//   -> 48T -> countershaft 12T (163,17, 4:1) -> 20T/20T bevel
//   (apex 163,30,17) -> twister_ring (24x drum, bore 18).
// Live proof: status=ready, animating, 24x kinematics exact at a frozen
// angle, new PART_DEFS loaded (ring/bracket/shafts/green), old twister
// gone, tape static, 0 console errors, ASSET_V 51.
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
  if (!cond && !fail) fail = msg;
}

(async () => {
  const { browser, page } = await pool.newPage({ width: 1600, height: 1000 });
  try {
    const errors = [];
    page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
    page.on('pageerror', err => errors.push(err.message));
    await page.goto(`http://localhost:9099/index.html?v=${V}`);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 45000 });
    console.log('Desktop: status=ready');

    await page.evaluate(() => { window._overrideAngle = null; window._showAllParts(); });
    await page.waitForTimeout(400);
    const a0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.waitForTimeout(700);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    check(a0 !== a1, 'animating true (crankSpinner rotates)');

    const tw = await page.evaluate(() => ({
      orbits: window._twister.orbitsPerDrum, arms: window._twister.arms,
      hasLay: !!window._twister.layPivot, hasCnt: !!window._twister.cntPivot,
    }));
    console.log('twister hooks:', JSON.stringify(tw));
    check(tw.orbits === 24 && tw.arms === 2, 'ring 24x drum, 2 bobbin arms (4 revs/seed, 8 wraps)');
    check(tw.hasLay && tw.hasCnt, 'lay/countershaft pivots exposed');

    const gt = await page.evaluate(() => window._gearTrain.chain);
    console.log('gearTrain:', gt);
    check(/72T/.test(gt) && /24x/.test(gt) && /163,30,17/.test(gt), 'gear-train legend carries 72T/24x/apex');

    // Kinematics exact at a frozen crank angle (a = 0.7 rad).
    const kin = await page.evaluate(() => {
      window._setRotations(0.7);
      return {
        tw: window._pivots.twister.rotation.x,
        lay: window._pivots.layshaft.rotation.z,
        cnt: window._pivots.countershaft.rotation.z,
        drum: window._pivots.drum.rotation.z,
      };
    });
    console.log('kinematics@0.7:', JSON.stringify(kin));
    check(Math.abs(kin.tw - (-12 * 0.7)) < 1e-9, 'ring -12x crank about X (24x drum)');
    check(Math.abs(kin.lay - (-3 * 0.7)) < 1e-9, 'layshaft -3x crank about Y (-6x drum)');
    check(Math.abs(kin.cnt - (12 * 0.7)) < 1e-9, 'countershaft +12x crank about Y (+24x drum)');
    check(Math.abs(kin.drum - (0.5 * 0.7)) < 1e-9, 'drum still 0.5x crank');

    // New parts loaded, old twister GLB gone.
    const parts = await page.evaluate(() => ({
      ids: Object.keys(window._partMeshes).sort(),
      n: Object.keys(window._partMeshes).length,
    }));
    console.log('part ids:', JSON.stringify(parts.ids));
    for (const id of ['twister_ring', 'twister_bracket', 'layshaft_gears', 'countershaft_gears', 'green_gear'])
      check(parts.ids.includes(id), 'part loaded: ' + id);
    check(!parts.ids.includes('twister'), 'stale v53 twister GLB gone');

    // Ring world box: centre near (172,17,-30), bore axis along X.
    const ringBox = await page.evaluate(() => {
      const box = new THREE.Box3();
      (window._partMeshes.twister_ring || []).forEach(g => g.traverse(m => {
        if (m.isMesh && m.geometry && m.geometry.attributes.position) {
          m.updateWorldMatrix(true, false);
          box.expandByObject(m);
        }
      }));
      if (box.isEmpty()) return null;
      const s = box.getSize(new THREE.Vector3()), c = box.getCenter(new THREE.Vector3());
      return { sx: s.x, sy: s.y, sz: s.z, cx: c.x, cy: c.y, cz: c.z };
    });
    console.log('ring world box:', JSON.stringify(ringBox));
    // NOTE: world box includes the root offset (-100,0,55): pivot CAD
    // (172,30,17) -> root-local (172,17,-30) -> world (72,17,25); the
    // bevel(-9)/spindle(+18) skew puts the steel centre at +4.5 (76.5).
    check(!!ringBox && Math.abs((ringBox.cx + 100) - 176.5) < 3, 'ring centred x=172 CAD (world 76.5 with root offset + skew)');
    check(!!ringBox && Math.abs(ringBox.cz - 25) < 3, 'ring at CAD y=30 lane (world z=25)');
    check(!!ringBox && ringBox.sx > 20 && ringBox.sx < 32, 'ring + bevel + spindles span x (22..28)');

    // Tape-static regression (v45): ribbon stays centred while animating.
    await page.evaluate(() => { window._overrideAngle = 0.6; });
    await page.waitForTimeout(200);
    const tx0 = await page.evaluate(() => window._tapeFold.flat.position.x);
    await page.waitForTimeout(1200);
    const tx1 = await page.evaluate(() => window._tapeFold.flat.position.x);
    console.log(`tapeGroup.x frozen=${tx0} animating=${tx1}`);
    check(tx0 === tx1 && tx0 === 97, `tape ribbon STATIC, centred CAD span (got ${tx0}/${tx1})`);

    await page.evaluate(() => window._setPanelCollapsed(true));
    await page.evaluate(() => {
      const top = window._root.parent || window._root;
      top.traverse(o => { if (o.isLine) o.visible = false; });
    });
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
    const r = ringBox;
    const rc = [r.cx, r.cy, r.cz];
    await shot('v69_ring.png', [r.cx - 42, r.cy + 10, r.cz + 6], [r.cx - 2, rc[1], rc[2]], ['twister_ring'], 0.6);
    await shot('v69_bracket.png', [r.cx + 40, r.cy + 26, r.cz + 30], rc, ['twister_bracket', 'twister_ring'], 0.6);
    await shot('v69_train.png', [265, 125, -95], [130, 50, -30], ['layshaft_gears', 'countershaft_gears', 'green_gear'], 0.6);
    await shot('v69_machine.png', [185, 175, 235], [20, 35, 25], null, null);
    await page.evaluate(() => { window._showAllParts(); window._overrideAngle = null; window._setPanelCollapsed(false); });
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v69_anim_t0.png') });
    console.log('Shot: v69_anim_t0.png (animating)');
    await page.waitForTimeout(2500);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v69_anim_t1.png') });
    console.log('Shot: v69_anim_t1.png (animating, +2.5s)');

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 51):', assetV);
    check(assetV === '51', 'ASSET_V 51 (v69 train GLBs rebuilt)');
    await page.close();

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await pool.releaseBrowser(browser);
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
