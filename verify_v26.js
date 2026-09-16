const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v26 verify: Step 5 collapsible left panel (mobile).
// Shots: screenshots/v26_*.png (repo rule: screenshots/ only, max 25).
// Asserts desktop 1280x800: ready, 0 console errors, animating true,
//   panel open by default, toggle collapses + expands, part toggles intact.
// Asserts mobile 390x844: panel collapsed by default, canvas full-width &
//   visible, toggle expands panel, 0 console errors, animating true.
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
    // ---------- desktop ----------
    const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
    const errors = [];
    page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
    page.on('pageerror', err => errors.push(err.message));
    await page.goto(`http://localhost:9099/index.html?v=${V}`);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 20000 });
    console.log('Desktop: status=ready');

    const dflt = await page.evaluate(() => ({
      collapsed: document.body.classList.contains('panel-collapsed'),
      flag: window._panelCollapsed,
      btn: document.getElementById('panelToggle').textContent,
      aria: document.getElementById('panelToggle').getAttribute('aria-expanded')
    }));
    console.log('Desktop default:', JSON.stringify(dflt));
    check(dflt.collapsed === false, 'desktop panel open by default');

    await page.evaluate(() => { window._overrideAngle = null; });
    await page.waitForTimeout(500);
    const a0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.waitForTimeout(800);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    check(a0 !== a1, 'desktop animating true');
    await page.screenshot({ path: path.join(SHOT_DIR, 'v26_desktop_open.png') });

    // collapse via toggle button
    await page.click('#panelToggle');
    await page.waitForTimeout(450);
    const col = await page.evaluate(() => ({
      collapsed: document.body.classList.contains('panel-collapsed'),
      flag: window._panelCollapsed,
      btn: document.getElementById('panelToggle').textContent,
      panelVisible: (function () { const r = document.getElementById('panel').getBoundingClientRect(); return r.right > 0 && r.width > 0; })(),
      toggleVisible: (function () { const r = document.getElementById('panelToggle').getBoundingClientRect(); return r.width > 0 && r.height > 0; })()
    }));
    console.log('Desktop collapsed:', JSON.stringify(col));
    check(col.collapsed === true && col.btn === '☰', 'desktop toggle collapses panel');
    await page.screenshot({ path: path.join(SHOT_DIR, 'v26_desktop_collapsed.png') });

    // animation + part state survive while collapsed
    const b0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.waitForTimeout(700);
    const b1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    check(b0 !== b1, 'desktop animating while collapsed');
    const partsOk = await page.evaluate(() => {
      const g = window._toggleGroups;
      return g && g.chassis && g.tape && typeof window._setPartVisible === 'function';
    });
    check(partsOk === true, 'desktop part toggle groups intact');

    // expand again
    await page.click('#panelToggle');
    await page.waitForTimeout(450);
    const re = await page.evaluate(() => ({
      collapsed: document.body.classList.contains('panel-collapsed'),
      checked: document.querySelector('.part-row input') !== null
    }));
    check(re.collapsed === false && re.checked === true, 'desktop toggle re-expands, checkboxes kept');
    console.log('Desktop console errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');
    await page.close();

    // ---------- mobile 390x844 ----------
    const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true });
    const m = await ctx.newPage();
    const merrors = [];
    m.on('console', msg => { if (msg.type() === 'error') merrors.push(msg.text()); });
    m.on('pageerror', err => merrors.push(err.message));
    await m.goto(`http://localhost:9099/index.html?v=${V}`);
    await m.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 20000 });
    console.log('Mobile: status=ready');

    const mInit = await m.evaluate(() => ({
      collapsed: document.body.classList.contains('panel-collapsed'),
      flag: window._panelCollapsed,
      panelBox: (function () { const r = document.getElementById('panel').getBoundingClientRect(); return { right: Math.round(r.right), width: Math.round(r.width) }; })(),
      canvasBox: (function () { const r = document.getElementById('view').getBoundingClientRect(); return { w: Math.round(r.width), h: Math.round(r.height) }; })()
    }));
    console.log('Mobile default:', JSON.stringify(mInit));
    check(mInit.collapsed === true, 'mobile panel collapsed by default');
    check(mInit.panelBox.right <= 0, 'mobile panel off-canvas (canvas full-width)');
    check(mInit.canvasBox.w >= 380 && mInit.canvasBox.h >= 800, 'mobile canvas visible full viewport');
    await m.screenshot({ path: path.join(SHOT_DIR, 'v26_mobile_collapsed.png') });
    console.log('Shot screenshots/v26_mobile_collapsed.png');

    await m.evaluate(() => { window._overrideAngle = null; });
    await m.waitForTimeout(500);
    const ma0 = await m.evaluate(() => window._crankSpinner.rotation.z);
    await m.waitForTimeout(800);
    const ma1 = await m.evaluate(() => window._crankSpinner.rotation.z);
    check(ma0 !== ma1, 'mobile animating true');

    // toggle opens panel on mobile
    await m.tap('#panelToggle');
    await m.waitForTimeout(450);
    const mOpen = await m.evaluate(() => ({
      collapsed: document.body.classList.contains('panel-collapsed'),
      panelLeft: Math.round(document.getElementById('panel').getBoundingClientRect().left),
      rows: document.querySelectorAll('.part-row').length
    }));
    console.log('Mobile after toggle:', JSON.stringify(mOpen));
    check(mOpen.collapsed === false && mOpen.rows > 0, 'mobile toggle expands panel with part rows');
    await m.screenshot({ path: path.join(SHOT_DIR, 'v26_mobile_open.png') });
    console.log('Shot screenshots/v26_mobile_open.png');

    console.log('Mobile console errors:', merrors.length);
    merrors.forEach(e => console.log('  ', e));
    check(merrors.length === 0, 'mobile 0 console errors');

    const assetV = await m.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 13):', assetV);
    check(assetV === '13', 'ASSET_V stays 13 (no GLB regen)');
    const vendored = await m.evaluate(() => {
      const s = Array.from(document.querySelectorAll('script[src]')).map(x => x.getAttribute('src')).join(',');
      return s;
    });
    console.log('Script srcs:', vendored);
    check(/js\/three\.min\.js/.test(vendored) && !/cdn/i.test(vendored), 'vendored three.js local, never CDN');

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
