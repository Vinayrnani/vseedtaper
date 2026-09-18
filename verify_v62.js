const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');

// v62 verify: TUBULAR SCROLL FOLDER (user scroll concept).
// six_turner() rebuilt as a solid former block 28x33x20 with a
// hull-lofted scroll tunnel (5 stages: open trench dia 25.4 ->
// shut tube dia 8, axis 14->13) + blind wick bore d4 from the top.
// Live proof: _sixTurner hooks, plow world box, animating +
// tape-static regression, entry/exit/top/wick closeups + iso, 0 errors.
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

    const st = await page.evaluate(() => window._sixTurner);
    console.log('sixTurner:', JSON.stringify(st));
    check(st.start === 126 && st.end === 159 && st.dropX === 100, 'folder footprint 126..159, drop 100 (flat landing first)');
    check(st.entryBore === 25.4 && st.exitBore === 8, 'scroll tapers 25.4 (full tape) -> 8 (finished tube)');
    check(!!st.wick && st.wick[0] === 152 && st.wick[2] === 4, 'blind wick bore d4 over the shut tube (world x152)');
    check(!!st.stages && st.stages.includes('shut tube'), '5-stage scroll stages hook');

    const plowBox = await page.evaluate(() => {
      const box = new THREE.Box3();
      (window._partMeshes.plow || []).forEach(g => g.traverse(m => {
        if (m.isMesh && m.geometry && m.geometry.attributes.position) {
          m.updateWorldMatrix(true, false);
          box.expandByObject(m);
        }
      }));
      if (box.isEmpty()) return null;
      const s = box.getSize(new THREE.Vector3()), c = box.getCenter(new THREE.Vector3());
      return { sx: s.x, sy: s.y, sz: s.z, cx: c.x, cy: c.y, cz: c.z };
    });
    console.log('plow world box:', JSON.stringify(plowBox));
    check(!!plowBox && plowBox.sx > 40 && plowBox.sx < 55, `plow spans block+tray 112..159 (got x ${plowBox && plowBox.sx})`);
    check(!!plowBox && plowBox.sy > 15 && plowBox.sy < 25, `plow block height 0..20 (got y ${plowBox && plowBox.sy})`);
    check(!!plowBox && plowBox.sz > 45, `plow width + ear tabs on world z (got z ${plowBox && plowBox.sz})`);

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
    const L = 42;
    const wx0 = plowBox.cx - plowBox.sx / 2; // box west (tray tip) in world frame
    const wx1 = plowBox.cx + plowBox.sx / 2; // box east (tube exit) in world frame
    await shot('v62_folder_entry.png', [wx0 - L, plowBox.cy + 8, plowBox.cz], [wx0 + 14, plowBox.cy - 2, plowBox.cz], ['plow'], 0.6);
    await shot('v62_folder_exit.png', [wx1 + L, plowBox.cy + 8, plowBox.cz], [wx1 - 4, plowBox.cy - 2, plowBox.cz], ['plow'], 0.6);
    await shot('v62_folder_top.png', [plowBox.cx + 6, plowBox.cy + 70, plowBox.cz + 6], [plowBox.cx + 6, plowBox.cy - 4, plowBox.cz], ['plow'], 0.6);
    await shot('v62_folder_wick.png', [wx0 + 18, plowBox.cy + 33, plowBox.cz + 23], [wx0 + 40, plowBox.cy + 3, plowBox.cz - 1], ['plow'], 0.6);
    await shot('v62_folder_side.png', [plowBox.cx, plowBox.cy + 12, plowBox.cz + 62], [plowBox.cx, plowBox.cy - 2, plowBox.cz], ['plow'], 0.6);
    await shot('v62_folder_34.png', [plowBox.cx - 40, plowBox.cy + 55, plowBox.cz + 70], [plowBox.cx, plowBox.cy - 2, plowBox.cz], ['plow'], 0.6);
    await shot('v62_iso.png', [185, 175, 235], [20, 35, 25], null, null);
    await page.evaluate(() => { window._showAllParts(); window._overrideAngle = null; window._setPanelCollapsed(false); });
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v62_anim_t0.png') });
    console.log('Shot: v62_anim_t0.png (animating)');
    await page.waitForTimeout(2500);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v62_anim_t1.png') });
    console.log('Shot: v62_anim_t1.png (animating, +2.5s)');

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 46):', assetV);
    check(assetV === '46', 'ASSET_V 46 (v62 scroll folder, plow GLB rebuilt)');
    await page.close();

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await pool.releaseBrowser(browser);
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
