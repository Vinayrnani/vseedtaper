const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');

// v63 verify: EXACT SPIRAL SCROLL PLOW (user code verbatim).
// six_turner() = scroll_sheet()/printable_folder() untouched +
// placement wrapper (mouth world 114, exit 159, axis 21) + tray/nose/
// ears/pedestals/tab-post. Live proof: _sixTurner hooks, plow world
// box, animating + tape-static regression, entry/exit/top/34 closeups
// + iso, 0 errors.
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
    check(st.start === 114 && st.end === 159 && st.dropX === 100, 'folder spans mouth 114..exit 159, drop 100 (flat landing first)');
    check(st.entryBore === 24 && st.exitBore === 11, 'exact spiral: R12 U entry (24) -> R5.5 overlap exit (11)');
    check(st.wall === 1.6, 'sheet wall exactly 1.6 (user code)');
    check(!!st.stages && st.stages.includes('1.25'), '1.25-turn overlap stages hook');

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
    check(!!plowBox && plowBox.sx > 40 && plowBox.sx < 55, `plow spans tray..exit 112..159 (got x ${plowBox && plowBox.sx})`);
    check(!!plowBox && plowBox.sy > 25 && plowBox.sy < 36, `plow sheet height 0..31 (got y ${plowBox && plowBox.sy})`);
    check(!!plowBox && plowBox.sz > 45, `plow width + tabs/ears on world z (got z ${plowBox && plowBox.sz})`);

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
    const wx0 = plowBox.cx - plowBox.sx / 2; // tray tip (world frame)
    const wx1 = plowBox.cx + plowBox.sx / 2; // tube exit (world frame)
    await shot('v63_folder_entry.png', [wx0 - L, plowBox.cy + 10, plowBox.cz], [wx0 + 8, plowBox.cy - 2, plowBox.cz], ['plow'], 0.6);
    await shot('v63_folder_exit.png', [wx1 + L, plowBox.cy + 10, plowBox.cz], [wx1 - 4, plowBox.cy - 2, plowBox.cz], ['plow'], 0.6);
    await shot('v63_folder_top.png', [plowBox.cx + 6, plowBox.cy + 72, plowBox.cz + 6], [plowBox.cx + 6, plowBox.cy - 4, plowBox.cz], ['plow'], 0.6);
    await shot('v63_folder_34.png', [plowBox.cx - 42, plowBox.cy + 55, plowBox.cz + 72], [plowBox.cx, plowBox.cy - 2, plowBox.cz], ['plow'], 0.6);
    await shot('v63_folder_side.png', [plowBox.cx, plowBox.cy + 12, plowBox.cz + 64], [plowBox.cx, plowBox.cy - 2, plowBox.cz], ['plow'], 0.6);
    await shot('v63_iso.png', [185, 175, 235], [20, 35, 25], null, null);
    await page.evaluate(() => { window._showAllParts(); window._overrideAngle = null; window._setPanelCollapsed(false); });
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v63_anim_t0.png') });
    console.log('Shot: v63_anim_t0.png (animating)');
    await page.waitForTimeout(2500);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v63_anim_t1.png') });
    console.log('Shot: v63_anim_t1.png (animating, +2.5s)');

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 47):', assetV);
    check(assetV === '47', 'ASSET_V 47 (v63 exact spiral, plow GLB rebuilt)');
    await page.close();

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await pool.releaseBrowser(browser);
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
