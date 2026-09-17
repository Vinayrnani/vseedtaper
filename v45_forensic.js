const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v45 FORENSIC multi-angle inspection (read-only capture, no fixes).
// Angles: ISO, ISO-back, TOP, SIDE-train(+z), SIDE-front(-z), END-ON(+x tape axis),
// BOTTOM + closeups: hopper->drum, drop x=100, 6-turner, twister, pull,
// takeup, crank-drum mesh, drum-driven idlers. Animating at 2-3 timestamps.
const SHOT_DIR = path.join(__dirname, 'screenshots');
fs.mkdirSync(SHOT_DIR, { recursive: true });

const V = Date.now();
let fail = null;
function check(cond, msg) {
  console.log((cond ? 'PASS ' : 'FAIL ') + msg);
  if (!cond && !fail) fail = msg;
}

(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
  try {
    const page = await browser.newPage({ viewport: { width: 1600, height: 1000 } });
    const errors = [];
    page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
    page.on('pageerror', err => errors.push(err.message));
    await page.goto(`http://localhost:9099/index.html?v=${V}`);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 30000 });
    console.log('status=ready');

    // Ensure animating (free-run, no override).
    await page.evaluate(() => { window._overrideAngle = null; window._showAllParts(); });
    await page.waitForTimeout(400);
    const a0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.waitForTimeout(700);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    check(a0 !== a1, 'animating (crankSpinner rotates)');

    async function shot(f, cam, tgt, waitMs) {
      await page.evaluate(([c, t]) => {
        window._camera.position.set(c[0], c[1], c[2]);
        window._controls.target.set(t[0], t[1], t[2]);
        window._controls.update();
      }, [cam, tgt]);
      await page.waitForTimeout(waitMs || 350);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      console.log('Shot:', f);
    }

    // ---- 7 full angles, animating timestamps spread over time ----
    await shot('f_iso.png', [185, 175, 235], [20, 35, 25]);
    await shot('f_iso_b.png', [-170, 150, 250], [20, 35, 25]);
    await shot('f_top.png', [20, 460, 27], [20, 0, 25]);
    await shot('f_side_train.png', [20, 45, 430], [20, 40, 27]);
    await shot('f_side_front.png', [20, 45, -380], [20, 40, 27]);
    await shot('f_endon.png', [440, 55, 27], [20, 40, 27]);
    await shot('f_bottom.png', [20, -360, 27], [20, 40, 27]);

    // ---- 8 station closeups ----
    await shot('f_hopper_drum.png', [42, 88, 98], [0, 58, 25]);
    await shot('f_drop.png', [36, 32, 92], [0, 20, 25]);
    await shot('f_turner.png', [42, 32, 96], [42, 10, 25]);
    await shot('f_twister.png', [72, 36, 92], [72, 17, 25]);
    await shot('f_pull.png', [94, 26, 92], [94, 6, 25]);
    await shot('f_takeup.png', [126, 52, 96], [126, 30, 25]);
    await shot('f_crankmesh.png', [-28, 82, 152], [-30, 58, 55]);
    await shot('f_idlers.png', [30, 62, 225], [30, 44, 66]);

    // ---- motion timestamps: 2 more per key angle while animating ----
    await page.waitForTimeout(500);
    await shot('f_iso_t2.png', [185, 175, 235], [20, 35, 25]);
    await shot('f_side_train_t2.png', [20, 45, 430], [20, 40, 27]);
    await page.waitForTimeout(900);
    await shot('f_iso_t3.png', [185, 175, 235], [20, 35, 25]);
    await shot('f_side_train_t3.png', [20, 45, 430], [20, 40, 27]);

    console.log('errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, '0 console errors');

    // Prune to <=25 (oldest first).
    const files = fs.readdirSync(SHOT_DIR).filter(f => f.endsWith('.png'))
      .map(f => ({ f, m: fs.statSync(path.join(SHOT_DIR, f)).mtimeMs }))
      .sort((a, b) => a.m - b.m);
    while (files.length > 25) {
      const old = files.shift();
      fs.unlinkSync(path.join(SHOT_DIR, old.f));
      console.log('Pruned:', old.f);
    }
    if (fail) { console.error('FORENSIC FAILED:', fail); process.exitCode = 1; }
    else console.log('FORENSIC CAPTURE DONE');
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('FORENSIC FAILED:', e); process.exit(1); });
