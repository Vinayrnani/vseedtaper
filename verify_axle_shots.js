const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');
const SHOT_DIR = path.join(__dirname, 'screenshots');
fs.mkdirSync(SHOT_DIR, { recursive: true });
(function prune() {
  const files = fs.readdirSync(SHOT_DIR).filter(f => f.endsWith('.png'))
    .map(f => ({ f, m: fs.statSync(path.join(SHOT_DIR, f)).mtimeMs })).sort((a, b) => a.m - b.m);
  while (files.length > 23) {
    const o = files.shift();
    fs.unlinkSync(path.join(SHOT_DIR, o.f));
    console.log('Pruned:', o.f);
  }
})();
const V = Date.now();
(async () => {
  const bp = await pool.newPage({ width: 1600, height: 1000 });
  const browser = bp.browser, page = bp.page;
  try {
    const errors = [];
    page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
    page.on('pageerror', err => errors.push(err.message));
    await page.goto('http://localhost:9099/index.html?v=' + V);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 30000 });
    console.log('status=ready');
    await page.evaluate(() => { window._showAllParts(); });
    await page.waitForTimeout(300);
    const twisterX = 172;
    const camPos = [twisterX + 80, 17 + 30, -34 + 100];
    const target = [twisterX, 17, -34];
    await page.evaluate(([cam, tgt]) => {
      window._camera.position.set(cam[0], cam[1], cam[2]);
      window._controls.target.set(tgt[0], tgt[1], tgt[2]);
      window._controls.update();
    }, [camPos, target]);
    await page.waitForTimeout(450);
    await page.screenshot({ path: path.join(SHOT_DIR, 'axle_assembled.png') });
    console.log('Shot A: axle_assembled.png');
    await page.evaluate(() => { window._setPartVisible('twister', false); });
    await page.waitForTimeout(300);
    await page.screenshot({ path: path.join(SHOT_DIR, 'axle_bare.png') });
    console.log('Shot B: axle_bare.png');
    console.log('errors: ' + errors.length);
    errors.forEach(e => console.log('   ' + e));
    const a = fs.statSync(path.join(SHOT_DIR, 'axle_assembled.png'));
    const b = fs.statSync(path.join(SHOT_DIR, 'axle_bare.png'));
    console.log('axle_assembled.png: ' + a.size + ' bytes');
    console.log('axle_bare.png: ' + b.size + ' bytes');
    if (errors.length > 0) { console.error('FAILED: ' + errors.length + ' console errors'); process.exitCode = 1; }
    else console.log('PASSED');
  } finally {
    await pool.releaseBrowser(browser);
  }
})();
