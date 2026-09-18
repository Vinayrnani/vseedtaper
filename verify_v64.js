const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');

// v64 verify: BARE EXACT SPIRAL PLOW, single shell, all 6 sides.
// six_turner() = user scroll_sheet() minus the floating right tab,
// oriented + placed (mouth world 114, exit 159, axis 21). Live proof:
// _sixTurner hooks, plow world box (single object), animating +
// tape-static regression, mouth/exit/top/bottom/near/far + iso, 0 errors.
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
    check(!('tray' in st), 'no tray (decluttered)');

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
    check(!!plowBox && plowBox.sx > 40 && plowBox.sx < 55, `bare sheet spans mouth..exit (got x ${plowBox && plowBox.sx})`);
    check(!!plowBox && plowBox.sy > 18 && plowBox.sy < 28, `sheet height 8..31 (got y ${plowBox && plowBox.sy})`);
    check(!!plowBox && plowBox.sz > 20 && plowBox.sz < 35, `sheet width only, no ears/tabs farm (got z ${plowBox && plowBox.sz})`);

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
    const b = plowBox, L = 42;
    const c = [b.cx, b.cy - 2, b.cz];
    await shot('v64_mouth.png', [b.cx - b.sx / 2 - L, b.cy + 8, b.cz], [b.cx - b.sx / 2 + 6, c[1], c[2]], ['plow'], 0.6);
    await shot('v64_exit.png', [b.cx + b.sx / 2 + L, b.cy + 8, b.cz], [b.cx + b.sx / 2 - 4, c[1], c[2]], ['plow'], 0.6);
    await shot('v64_top.png', [b.cx, b.cy + 72, b.cz + 4], c, ['plow'], 0.6);
    await shot('v64_bottom.png', [b.cx, b.cy - 60, b.cz + 4], c, ['plow'], 0.6);
    await shot('v64_near.png', [b.cx, b.cy + 10, b.cz + 62], c, ['plow'], 0.6);
    await shot('v64_far.png', [b.cx, b.cy + 10, b.cz - 62], c, ['plow'], 0.6);
    await shot('v64_iso.png', [b.cx - 40, b.cy + 55, b.cz + 70], c, ['plow'], 0.6);
    await shot('v64_machine.png', [185, 175, 235], [20, 35, 25], null, null);
    await page.evaluate(() => { window._showAllParts(); window._overrideAngle = null; window._setPanelCollapsed(false); });
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v64_anim_t0.png') });
    console.log('Shot: v64_anim_t0.png (animating)');
    await page.waitForTimeout(2500);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v64_anim_t1.png') });
    console.log('Shot: v64_anim_t1.png (animating, +2.5s)');

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 48):', assetV);
    check(assetV === '48', 'ASSET_V 48 (v64 bare spiral, plow GLB rebuilt)');
    await page.close();

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await pool.releaseBrowser(browser);
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
