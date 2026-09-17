const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');

// v51 verify: HOLLOW twister (no hub, no coaxial shaft, empty middle).
// thread_twister() = guide ring r10/tube2 + 2 rod holders (r1.2 h10,
// orbit 9.5) + 2 bobbins (r2.5 h6); side layshaft (y=45.5) + friction
// wheel r3.5 tangent to ring OD; bevel retargeted to side apex I51.
// Live proof: _gearTrain hooks, twister world box (hollow bore check),
// animating + tape-static regression, twister closeups + iso, 0 errors.
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
    const t0 = await page.evaluate(() => window._twister.pivot.rotation.x);
    await page.waitForTimeout(700);
    const t1 = await page.evaluate(() => window._twister.pivot.rotation.x);
    check(t0 !== t1, 'twister pivot spins about X while animating');

    const gt = await page.evaluate(() => window._gearTrain);
    console.log('gearTrain:', JSON.stringify(gt.mounts), '|', gt.bevel);
    check(!!gt.mounts.apex && gt.mounts.apex[1] === 45.5 && gt.mounts.apex[2] === 17, 'side apex I51 (141.85,45.5,17), nothing coaxial');
    check(!gt.mounts.twCoaxial && !!gt.mounts.twFriction, 'friction OD drive hook, no coaxial hook');
    check(gt.chain.includes('friction wheel') && gt.chain.includes('hollow middle'), 'chain legend documents hollow middle');
    const tw = await page.evaluate(() => ({ arms: window._twister.arms, orbits: window._twister.orbitsPerDrum }));
    check(tw.arms === 2 && tw.orbits === 6, 'twister still 2 holders, 6 orbits/drum (kinematic)');

    // Twister world box (world frame = CAD + root offset (-100,0,55)):
    // ring OD 24 in Y/Z (+orbiting rods, diagonal up to ~34); thin in
    // X (rods h10); centre must equal the pivot world position.
    const twBox = await page.evaluate(() => {
      const box = new THREE.Box3();
      (window._partMeshes.twister || []).forEach(g => g.traverse(m => {
        if (m.isMesh && m.geometry && m.geometry.attributes.position) {
          m.updateWorldMatrix(true, false);
          box.expandByObject(m);
        }
      }));
      if (box.isEmpty()) return null;
      const s = box.getSize(new THREE.Vector3()), c = box.getCenter(new THREE.Vector3());
      const p = new THREE.Vector3(); window._twister.pivot.getWorldPosition(p);
      return { sx: s.x, sy: s.y, sz: s.z, cx: c.x, cy: c.y, cz: c.z, px: p.x, py: p.y, pz: p.z };
    });
    console.log('twister world box:', JSON.stringify(twBox));
    check(!!twBox, 'twister GLB present');
    check(!!twBox && twBox.sx <= 13, `twister thin in x (rods h10 + ring, got ${twBox && twBox.sx})`);
    check(!!twBox && twBox.sy <= 35 && twBox.sz <= 35, `twister envelope <= ring OD + rod diagonal (got ${twBox && twBox.sy}/${twBox && twBox.sz})`);
    check(!!twBox && Math.abs(twBox.cx - twBox.px) < 1 && Math.abs(twBox.cy - twBox.py) < 1 && Math.abs(twBox.cz - twBox.pz) < 1,
      `twister centred on its pivot (got ${twBox && twBox.cx},${twBox && twBox.cy},${twBox && twBox.cz} vs ${twBox && twBox.px},${twBox && twBox.py},${twBox && twBox.pz})`);

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
    // Cameras derived live from the twister world box (world frame).
    // Ring axis = X: through-bore looks down +X; side looks down -Y.
    const c = [twBox.cx, twBox.cy, twBox.cz];
    await shot('v51_twister_bore.png', [c[0] + 55, c[1], c[2]], c, ['twister'], 0);
    await shot('v51_twister_side.png', [c[0], c[1] - 70, c[2] + 25], c, ['twister'], 0);
    await shot('v51_twister_station.png', [c[0] + 55, c[1] + 40, c[2] + 55], c, null, 0.6);
    await shot('v51_iso.png', [185, 175, 235], [20, 35, 25], null, null);
    await page.evaluate(() => { window._showAllParts(); window._overrideAngle = null; window._setPanelCollapsed(false); });
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v51_anim_t0.png') });
    console.log('Shot: v51_anim_t0.png (animating)');
    await page.waitForTimeout(2500);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v51_anim_t1.png') });
    console.log('Shot: v51_anim_t1.png (animating, +2.5s)');

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 34):', assetV);
    check(assetV === '34', 'ASSET_V 34 (twister + chassis GLBs rebuilt)');
    await page.close();

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await pool.releaseBrowser(browser);
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
