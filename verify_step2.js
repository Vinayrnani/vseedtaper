const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');

// v71 verify (STEP 2 ONLY): ONE 11T M2 intermediate pinion at (155,12,60)
// meshing the 44T drum gear. Checks: status=ready, animating, pinion
// kinematics (-PINION_RATIO*crank - PINION_PHASE, PINION_RATIO=16/11),
// pinion pivot at M(155,12,60), pinion geometry outer ~26, tape-static
// regression, 0 console errors, ASSET_V 52.
// Shots: 1 close-up of the pinion/drum mesh + 1 wide vs tape path.
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

    // Step-2 kinematics: pinion = -PINION_RATIO * crank - PINION_PHASE.
    const kin = await page.evaluate(() => {
      window._setRotations(Math.PI * 2);
      const p = window._pivots.pinion.rotation.z;
      const d = window._pivots.drum.rotation.z;
      window._overrideAngle = null;
      return { p, d };
    });
    const expP = -(16 / 11) * Math.PI * 2 - Math.PI / 11;
    const expD = Math.PI * 2 * (16 / 44);
    console.log('pinion/drum at 1 crank rev:', JSON.stringify(kin));
    check(Math.abs(kin.p - expP) < 1e-6, `pinion = -(16/11)*crank - PI/11 (got ${kin.p}, exp ${expP})`);
    check(Math.abs(kin.d - expD) < 1e-6, `drum unchanged = crank*16/44 (got ${kin.d})`);
    check(Math.abs((kin.p + Math.PI / 11) / kin.d + 4) < 1e-6, `pinion = -4x drum, opposite sense (got ratio ${(kin.p + Math.PI / 11) / kin.d})`);

    // Pinion pivot world position: M(155,12,60)=(155,60,-12) + root(-100,0,55) = (55,60,43).
    const pinW = await page.evaluate(() => {
      const v = new THREE.Vector3();
      window._pivots.pinion.getWorldPosition(v);
      return [v.x, v.y, v.z];
    });
    console.log('pinion world:', JSON.stringify(pinW));
    check(Math.abs(pinW[0] - 55) < 1 && Math.abs(pinW[1] - 60) < 1 && Math.abs(pinW[2] - 43) < 1,
      `pinion pivot at world (55,60,43) = M(155,12,60) (got ${pinW})`);

    // Pinion geometry size proof: 11T M2 -> outer dia 26.
    const pinBox = await page.evaluate(() => {
      let gx = 0, gy = 0, gz = 0, n = 0;
      (window._partMeshes.twister_pinion_11t || []).forEach(g => g.traverse(m => {
        if (m.isMesh && m.geometry && m.geometry.attributes.position) {
          m.geometry.computeBoundingBox();
          const s = new THREE.Vector3(); m.geometry.boundingBox.getSize(s);
          gx = Math.max(gx, s.x); gy = Math.max(gy, s.y); gz = Math.max(gz, s.z); n++;
        }
      }));
      return { gx, gy, gz, n };
    });
    console.log('pinion geometry box:', JSON.stringify(pinBox));
    check(!!pinBox && pinBox.n > 0, 'pinion GLB loaded with meshes');
    const pmax = Math.max(pinBox.gx, pinBox.gy);
    check(pmax > 24 && pmax < 28, `pinion 11T outer ~26 (got ${pinBox.gx}/${pinBox.gy})`);

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
    const drumW = await page.evaluate(() => {
      const v = new THREE.Vector3();
      window._pivots.drum.getWorldPosition(v);
      return [v.x, v.y, v.z];
    });
    console.log('drum world:', JSON.stringify(drumW), 'pinion world:', JSON.stringify(pinW));
    // 1) close-up of the new pinion meshing the drum (mesh midpoint target).
    const mesh = [(drumW[0] + pinW[0]) / 2, (drumW[1] + pinW[1]) / 2, (drumW[2] + pinW[2]) / 2];
    await shot('v71_pinion_mesh_closeup.png',
      [mesh[0] + 20, mesh[1] + 15, mesh[2] + 70],
      [mesh[0], mesh[1], mesh[2] + 5],
      ['cartridge', 'twister_pinion_11t'], 0.6);
    // 2) wider shot showing pinion position relative to the tape path
    // (chassis hidden — its front wall would block the back-gear view).
    await shot('v71_pinion_wide.png',
      [mesh[0] + 60, mesh[1] + 70, mesh[2] + 200],
      [mesh[0] - 20, mesh[1] - 20, mesh[2] - 10],
      ['hopper', 'shroud', 'cartridge', 'cones_a', 'cones_b', 'plow',
       'rollers_lower', 'rollers_upper', 'crank', 'twister', 'pull_a',
       'pull_b', 'takeup', 'twister_pinion_11t'], null);

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 52):', assetV);
    check(assetV === '52', 'ASSET_V 52 (v71 step-2 pinion GLB)');
    await page.close();

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await pool.releaseBrowser(browser);
  }
})();
