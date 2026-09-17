const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');

// v54 verify: ASYMMETRIC INNER-CURL 6-FOLDER (outer shell REJECTED).
// CAD: six_turner rebuilt as open tool inside the tape U — base plate +
// center fin tongue + deep left wing (30->270deg) + shallow right wing
// (20->180deg), 7 stations x0..33, walls 1.4, M3 tabs at old plow holes
// (world 132/153 x 6/54), no ring/bore. Viewer: relabel + ASSET_V 38.
// Live proof: animating + plow world box + entry/exit/iso shots, 0 errors.
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
    console.log('ASSET_V (expect 38):', assetV);
    check(assetV === '38', 'ASSET_V 38 (inner-curl plow GLB rebuilt)');

    const six = await page.evaluate(() => window._sixTurner);
    console.log('_sixTurner:', JSON.stringify(six));
    check(!!six && six.start === 126 && six.end === 159, 'folder footprint 126..159 kept');
    check(!!six && /inner-curl/.test(six.stages), 'stages describe inner-curl (no shell)');
    check(!!six && /270/.test(six.exit) && /180/.test(six.exit), 'exit nests 270deg left + 180deg right');

    // Plow world box (loose: length ~33-36 along world X, tabs span Y, low profile).
    const box = await page.evaluate(() => {
      const grp = (window._partMeshes.plow || [])[0];
      if (!grp) return null;
      const box = new THREE.Box3();
      grp.traverse(m => {
        if (m.isMesh && m.geometry && m.geometry.attributes.position) {
          m.updateWorldMatrix(true, false);
          box.expandByObject(m);
        }
      });
      if (box.isEmpty()) return null;
      const s = box.getSize(new THREE.Vector3()), c = box.getCenter(new THREE.Vector3());
      const mn = box.min, mx = box.max;
      return { sx: s.x, sy: s.y, sz: s.z, cx: c.x, cy: c.y, cz: c.z,
        minx: mn.x, maxx: mx.x, miny: mn.y, maxy: mx.y, minz: mn.z, maxz: mx.z };
    });
    console.log('plow box:', JSON.stringify(box));
    check(!!box, 'plow GLB present');
    check(!!box && box.sx > 30 && box.sx < 40, `folder length ~33-36 along X (got ${box && box.sx})`);
    // Viewer maps CAD (X,Y,Z) -> world (X, up=Z, Y): up-height is sy (~15), tab span is sz (~56).
    check(!!box && box.sy < 25, `open tool, low profile up-height (got ${box && box.sy})`);

    await page.evaluate(() => window._setPanelCollapsed(true));
    async function shot(f, cam, tgt, only) {
      // NOTE: no _overrideAngle — shots stay animating. only isolates parts
      // (+ hides the procedural twister thread lines for clean portraits).
      await page.evaluate((o) => {
        if (o) { window._setOnlyVisible(o); window._twister.lines.forEach(l => l.visible = false); }
        else { window._showAllParts(); window._twister.lines.forEach(l => l.visible = true); }
      }, only || null);
      await page.evaluate(([c, t]) => {
        window._camera.position.set(c[0], c[1], c[2]);
        window._controls.target.set(t[0], t[1], t[2]);
        window._controls.update();
      }, [cam, tgt]);
      await page.waitForTimeout(450);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      console.log('Shot:', f);
    }
    // World: X = length, Y = up, Z = width. Folder box: x 25.5..60.4,
    // up 4..19.2, z -3..53. End-on down the X axis reads the curl profile.
    const ex = box.minx, xx = box.maxx, cy0 = box.cy, cz0 = box.cz;
    await shot('v54_entry.png', [ex - 30, cy0 + 2, cz0], [ex + 6, cy0 - 1, cz0], ['plow']);
    await shot('v54_exit.png', [xx + 30, cy0 + 2, cz0], [xx - 6, cy0 - 1, cz0], ['plow']);
    await shot('v54_exit34.png', [xx + 24, cy0 + 16, cz0 + 26], [xx - 6, cy0 - 1, cz0], ['plow', 'tape']);
    await shot('v54_iso.png', [185, 175, 235], [20, 35, 25], null);
    // Animation proof: two frames 2.5s apart differ.
    await page.evaluate(() => { window._showAllParts(); window._setPanelCollapsed(false); });
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v54_anim_t0.png') });
    console.log('Shot: v54_anim_t0.png (animating)');
    const b0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.waitForTimeout(2500);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v54_anim_t1.png') });
    console.log('Shot: v54_anim_t1.png (animating, +2.5s)');
    const b1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    check(b0 !== b1, 'still animating during screenshots');
    pruneShots();

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');

    if (fail) { console.log('VERIFY_V54_RESULT: FAIL - ' + fail); process.exitCode = 1; }
    else console.log('VERIFY_V54_RESULT: PASS');
  } finally {
    await pool.releaseBrowser(browser);
  }
})().catch(e => { console.error('VERIFY_V54_RESULT: ERROR', e); process.exit(1); });
