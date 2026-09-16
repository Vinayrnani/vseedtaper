const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v27 verify: final printable pass (after v26 collapsible panel).
// Shots: screenshots/v27_*.png (max 25, prune oldest).
// Asserts: ready, 0 errors, animating, collapsible panel desktop+mobile,
// part toggles/labels, R->L order, crank back wall, ASSET_V 14, vendored js.
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

    // collapsible panel: open by default, toggle collapse + expand
    const dflt = await page.evaluate(() => document.body.classList.contains('panel-collapsed'));
    check(dflt === false, 'desktop panel open by default');
    await page.click('#panelToggle');
    await page.waitForTimeout(450);
    const col = await page.evaluate(() => ({
      c: document.body.classList.contains('panel-collapsed'),
      btn: document.getElementById('panelToggle').textContent
    }));
    check(col.c === true && col.btn === '☰', 'toggle collapses panel');
    const b0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.waitForTimeout(600);
    const b1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    check(b0 !== b1, 'animating while collapsed');
    await page.screenshot({ path: path.join(SHOT_DIR, 'v27_desktop_collapsed.png') });
    await page.click('#panelToggle');
    await page.waitForTimeout(450);
    const re = await page.evaluate(() => document.body.classList.contains('panel-collapsed'));
    check(re === false, 'toggle re-expands panel');

    // part toggles + labels
    const parts = await page.evaluate(() => ({
      rows: document.querySelectorAll('.part-row').length,
      labels: Array.from(document.querySelectorAll('.part-row .nm')).map(e => e.textContent),
      groups: Object.keys(window._toggleGroups || {}).sort()
    }));
    console.log('Part rows:', parts.rows, '| groups:', parts.groups.join(','));
    check(parts.rows >= 12, 'part toggles >=12 rows (incl tape/seeds)');
    check(parts.labels.some(l => /hopper/i.test(l)) && parts.labels.some(l => /crank/i.test(l)), 'labels clear (hopper, crank present)');

    // solo / visibility hooks
    const soloOk = await page.evaluate(() => {
      window._isolatePart('hopper');
      const vis = window._toggleGroups.hopper.objects.some(o => o && o.visible);
      const othersHidden = window._toggleGroups.chassis.objects.every(o => !o || !o.visible);
      window._showAllParts();
      const restored = window._toggleGroups.chassis.objects.some(o => o && o.visible);
      return vis && othersHidden && restored;
    });
    check(soloOk === true, 'solo/isolate + restore works');

    // R->L order + crank back wall + pivots (hopper is wrap-around: its
    // pivot sits at the drum centre by design, so order uses the hopper
    // wedge extent = GLB world max-X vs drum/shroud/roller pivots)
    const order = await page.evaluate(() => {
      const box = new THREE.Box3();
      window._partMeshes.hopper.forEach(o => o.updateWorldMatrix(true, true));
      box.setFromObject(window._partMeshes.hopper[0]);
      const rootPos = new THREE.Vector3(-100, 0, 55);
      const toRoot = v => v.clone().sub(rootPos);
      const mx = toRoot(box.max).x, mn = toRoot(box.min).x;
      return {
        hopperMaxX: Math.round(mx * 10) / 10, hopperMinX: Math.round(mn * 10) / 10,
        drum: window._pivots.drum.position.x,
        shroud: window._pivots.shroud.position.x,
        lower: window._pivots.lower.position.x,
        spool: window._pivots.spool.position.x,
        crankZ: window._pivots.crankMount.position.z // root-local z=8 <=> OpenSCAD Y=-8 back wall
      };
    });
    console.log('Order:', JSON.stringify(order));
    check(order.hopperMaxX > order.drum && order.drum > order.shroud && order.shroud > order.lower, 'R->L order hopper(wedge maxX)>drum>shroud>roller');
    check(order.crankZ === 8, 'crank back wall (mount z=8 <=> Y=-8)');
    check(order.spool < order.lower, 'spool west of roller');

    // rotation signs: crank/lower rigid (-angle-phase), upper +angle, drum +angle*0.5
    const signs = await page.evaluate(() => {
      window._setRotations(1.0);
      return {
        crank: window._crankSpinner.rotation.z,
        lower: window._lowerPivot.rotation.z,
        upper: window._upperPivot.rotation.z,
        drum: window._drumPivot.rotation.z
      };
    });
    console.log('Signs:', JSON.stringify(signs));
    const GEAR = Math.PI / 20;
    check(Math.abs(signs.crank - (-1 - GEAR)) < 1e-9 && Math.abs(signs.lower - (-1 - GEAR)) < 1e-9, 'crank+lower rigid -angle-phase');
    check(Math.abs(signs.upper - 1.0) < 1e-9 && Math.abs(signs.drum - 0.5) < 1e-9, 'upper +angle, drum +angle*0.5');
    await page.evaluate(() => { window._overrideAngle = null; });

    await page.screenshot({ path: path.join(SHOT_DIR, 'v27_desktop_open.png') });
    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');

    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 14):', assetV);
    check(assetV === '14', 'ASSET_V 14 (GLBs rebuilt)');
    const srcs = await page.evaluate(() => Array.from(document.querySelectorAll('script[src]')).map(x => x.getAttribute('src')).join(','));
    check(/js\/three\.min\.js/.test(srcs) && !/cdn/i.test(srcs), 'vendored three.js local, never CDN');
    await page.close();

    // mobile: collapsed by default, toggle opens
    const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true });
    const m = await ctx.newPage();
    const merrors = [];
    m.on('console', msg => { if (msg.type() === 'error') merrors.push(msg.text()); });
    m.on('pageerror', err => merrors.push(err.message));
    await m.goto(`http://localhost:9099/index.html?v=${V}`);
    await m.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 25000 });
    const mInit = await m.evaluate(() => ({
      c: document.body.classList.contains('panel-collapsed'),
      right: Math.round(document.getElementById('panel').getBoundingClientRect().right),
      w: Math.round(document.getElementById('view').getBoundingClientRect().width)
    }));
    check(mInit.c === true && mInit.right <= 0 && mInit.w >= 380, 'mobile collapsed by default, canvas full-width');
    await m.screenshot({ path: path.join(SHOT_DIR, 'v27_mobile_collapsed.png') });
    await m.tap('#panelToggle');
    await m.waitForTimeout(450);
    const mOpen = await m.evaluate(() => ({
      c: document.body.classList.contains('panel-collapsed'),
      rows: document.querySelectorAll('.part-row').length
    }));
    check(mOpen.c === false && mOpen.rows > 0, 'mobile toggle expands with part rows');
    await m.screenshot({ path: path.join(SHOT_DIR, 'v27_mobile_open.png') });
    console.log('Mobile errors:', merrors.length);
    merrors.forEach(e => console.log('  ', e));
    check(merrors.length === 0, 'mobile 0 console errors');

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
