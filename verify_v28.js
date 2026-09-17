const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v28 verify: tape bend true mimic (tapeubend.png) + v27 printable/panel regression.
// Shots: screenshots/v28_*.png (max 25, prune oldest).
// Asserts: ready, 0 errors, animating, collapsible panel, R->L order,
// crank back wall, ASSET_V 15, bend proof (R 1.5-2, trough 5-7, wall 5-6,
// TAPE_LEN 180, taper W->E, S-shoulder feet, collar visual).
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
    await page.screenshot({ path: path.join(SHOT_DIR, 'v28_anim_t0.png') });
    await page.evaluate(() => { window._overrideAngle = Math.PI / 2; });
    await page.waitForTimeout(300);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v28_anim_t1.png') });
    await page.evaluate(() => { window._overrideAngle = null; });

    // bend proof: params mirror CAD true-mimic values
    const bend = await page.evaluate(() => {
      const f = window._tapeFold;
      if (!f) return null;
      return {
        R: f.R, hw: f.hw, trough: 2 * f.hw, cz: f.cz,
        wall: f.wall, nArc: f.nArc, tapeLen: f.tapeLen,
        arcMeshes: f.arcMeshes.length,
        groupChildren: f.group.children.length,
        groupX: f.group.position.x, groupY: f.group.position.y
      };
    });
    console.log('Bend:', JSON.stringify(bend));
    check(!!bend, 'bend proof hooks present (_tapeFold)');
    if (bend) {
      check(bend.R >= 1.5 && bend.R <= 2.0, `inner R ~1.5-2 (got ${bend.R})`);
      check(bend.trough >= 5 && bend.trough <= 7, `trough width 5-7 (got ${bend.trough})`);
      check(bend.wall >= 5 && bend.wall <= 6, `wall 5-6 deep (got ${bend.wall})`);
      check(bend.nArc >= 20, `N_ARC up for smoothness (got ${bend.nArc})`);
      check(bend.tapeLen === 180, `TAPE_LEN unified with CAD 180 (got ${bend.tapeLen})`);
      check(bend.arcMeshes >= 2 * 12 * (20 + 3), `tapered+shoulder mesh count (got ${bend.arcMeshes})`);
      check(bend.groupChildren > 2 * 12 * 20, 'collar + fold children present');
    }

    // taper proof: exit-end (east) fold walls stand taller than entry-end (west)
    const taper = await page.evaluate(() => {
      const g = window._tapeFold.group;
      g.updateWorldMatrix(true, true);
      const box = new THREE.Box3();
      // sample arc mesh world Y at west third vs east third
      const ws = [], es = [];
      window._tapeFold.arcMeshes.forEach(m => {
        const p = new THREE.Vector3();
        m.getWorldPosition(p);
        const rootPos = new THREE.Vector3(-100, 0, 55);
        const lx = p.clone().sub(rootPos).x;
        if (lx < 137) ws.push(p.y);
        else if (lx > 148) es.push(p.y);
      });
      const max = a => Math.max.apply(null, a);
      return { wMax: Math.round(max(ws) * 10) / 10, eMax: Math.round(max(es) * 10) / 10, wn: ws.length, en: es.length };
    });
    console.log('Taper:', JSON.stringify(taper));
    check(taper.eMax > taper.wMax, `progressive entry->exit (west max ${taper.wMax} < east max ${taper.eMax})`);

    // end-on bend closeup (camera on +X looking -X at the fold exit = tapeubend.png view)
    await page.evaluate(() => {
      window._camera.position.set(260, 36, -30);
      window._controls.target.set(142, 32, -30);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v28_bend_endon.png') });
    // restore default view + full shot
    await page.evaluate(() => {
      window._camera.position.set(300, 220, 300);
      window._controls.target.set(-20, 55, 40);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v28_full.png') });

    // collapsible panel regression (desktop)
    const dflt = await page.evaluate(() => document.body.classList.contains('panel-collapsed'));
    check(dflt === false, 'desktop panel open by default');
    await page.click('#panelToggle');
    await page.waitForTimeout(450);
    const col = await page.evaluate(() => ({
      c: document.body.classList.contains('panel-collapsed'),
      btn: document.getElementById('panelToggle').textContent
    }));
    check(col.c === true && col.btn === '☰', 'toggle collapses panel');
    await page.screenshot({ path: path.join(SHOT_DIR, 'v28_desktop_collapsed.png') });
    await page.click('#panelToggle');
    await page.waitForTimeout(450);
    const re = await page.evaluate(() => document.body.classList.contains('panel-collapsed'));
    check(re === false, 'toggle re-expands panel');

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
    check(order.hopperMaxX > order.drum && order.drum > order.shroud && order.shroud > order.lower, 'R->L order hopper(wedge maxX)>drum>shroud>roller');
    check(order.crankZ === 8, 'crank back wall (mount z=8 <=> Y=-8)');
    check(order.spool < order.lower, 'spool west of roller');

    await page.screenshot({ path: path.join(SHOT_DIR, 'v28_desktop_open.png') });
    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');

    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 15):', assetV);
    check(assetV === '15', 'ASSET_V 15 (GLBs rebuilt)');
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
