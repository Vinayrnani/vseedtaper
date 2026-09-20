const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');

// v50 verify: TRUE-6 OPEN FOLDER (user REJECTED v49 closed tube).
// six_turner() rebuilt: 8-station loft, slot NEVER shuts (ends 1.0 =
// 2mm open seam), annular-sector tongue (root buried, 1.1 proud,
// edge +Y of slot); shut-tube section + R5.6 exit ring + blind wedge
// + curl ribs deleted. Tape untouched. ASSET_V 34->35, plow GLB rebuilt.
// Live proof: _sixTurner hooks (seamGap, no shutX), plow world
// placement/size, animating + tape-static regression, entry/exit/side
// closeups (seam visible) + iso, 0 errors.
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
    check(st.entryBore === 4.6 && st.exitBore === 3.2, 'bore tapers 4.6 -> 3.2 (entry clears 7.8 pocket)');
    check(st.seamGap === 2.0 && !('shutX' in st), 'exit seam OPEN 2mm, no shutX (not a pipe)');
    check(st.exit.includes('no ring'), 'exit keeps 6-overlap, no closed ring');
    check(!!st.stages && st.stages.includes('never shuts'), '8-station open-loft stages hook');

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
    check(!!plowBox && plowBox.sx > 30 && plowBox.sx < 45, `plow spans the 33 footprint + tabs (got x ${plowBox && plowBox.sx})`);
    check(!!plowBox && plowBox.sy > 18 && plowBox.sy < 22, `plow former height 0..20 (got y ${plowBox && plowBox.sy})`);
    check(!!plowBox && plowBox.sz > 50, `plow full width + tabs on world z (got z ${plowBox && plowBox.sz})`);

    // Tape-static regression (v45): ribbon stays centred while animating.
    await page.evaluate(() => { window._overrideAngle = 0.6; });
    await page.waitForTimeout(200);
    const tx0 = await page.evaluate(() => window._tapeFold.flat.position.x);
    await page.waitForTimeout(1200);
    const tx1 = await page.evaluate(() => window._tapeFold.flat.position.x);
    console.log(`tapeGroup.x frozen=${tx0} animating=${tx1}`);
    check(tx0 === tx1 && tx0 === 97, `tape ribbon STATIC, centred CAD span (got ${tx0}/${tx1})`);

    await page.evaluate(() => window._setPanelCollapsed(true));
    // Hide annotation lines (thread helices, drop path) for clean steel shots.
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
    // Cameras derived live from the plow world box (no hand-tuned mapping).
    // World Y is up: side view looks along Z (v49's below-floor Y cam was black).
    const cams = await page.evaluate((b) => {
      const L = 55; // standoff
      return {
        entry: [[b.cx - b.sx / 2 - L, b.cy, b.cz + 8], [b.cx - b.sx / 2 + 6, b.cy, b.cz]],
        exit: [[b.cx + b.sx / 2 + L, b.cy, b.cz + 8], [b.cx + b.sx / 2 - 6, b.cy, b.cz]],
        exit34: [[b.cx + b.sx / 2 + L * 0.7, b.cy + 28, b.cz + 38], [b.cx + b.sx / 2 - 6, b.cy, b.cz]],
        side: [[b.cx, b.cy + 14, b.cz + b.sz / 2 + L], [b.cx, b.cy, b.cz]],
      };
    }, plowBox);
    await shot('v50_folder_entry.png', cams.entry[0], cams.entry[1], ['plow'], 0.6);
    await shot('v50_folder_exit.png', cams.exit[0], cams.exit[1], ['plow'], 0.6);
    await shot('v50_folder_exit34.png', cams.exit34[0], cams.exit34[1], ['plow'], 0.6);
    await shot('v50_folder_side.png', cams.side[0], cams.side[1], ['plow'], 0.6);
    await shot('v50_iso.png', [185, 175, 235], [20, 35, 25], null, null);
    await page.evaluate(() => { window._showAllParts(); window._overrideAngle = null; window._setPanelCollapsed(false); });
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v50_anim_t0.png') });
    console.log('Shot: v50_anim_t0.png (animating)');
    await page.waitForTimeout(2500);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v50_anim_t1.png') });
    console.log('Shot: v50_anim_t1.png (animating, +2.5s)');

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 36):', assetV);
    check(assetV === '36', 'ASSET_V 36 (shared tree: v51 twister + v52 pullers + v50 plow GLB rebuilt)');
    await page.close();

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await pool.releaseBrowser(browser);
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
