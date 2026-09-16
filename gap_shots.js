const { chromium } = require('playwright');

// Gap-hunt closeups: hopper-only, camera framed from SCAD landmarks
// transformed by the live hopper mesh matrix. Shots: /tmp/gap_*.png
const V = Date.now();
(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
  try {
    const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
    const errors = [];
    page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
    page.on('pageerror', err => errors.push(err.message));
    await page.goto(`http://localhost:9099/index.html?v=${V}`);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 20000 });
    await page.waitForTimeout(500);
    await page.evaluate(() => { window._overrideAngle = 0; });
    // hopper only (+drum for mouth context where noted)
    async function showOnly(ids) {
      await page.evaluate((ids) => {
        Object.keys(window._toggleGroups).forEach(k => {
          window._toggleGroups[k].objects.forEach(o => { if (o) o.visible = ids.includes(k); });
        });
      }, ids);
      await page.waitForTimeout(300);
    }
    // frame SCAD point p (hopper-local = SCAD coords) with camera offset dir*dist
    async function frameShot(sx, sy, sz, dx, dy, dz, dist, path) {
      await page.evaluate(([sx, sy, sz, dx, dy, dz, dist]) => {
        const m = window._partMeshes.hopper[0];
        m.updateWorldMatrix(true, false);
        const t = new THREE.Vector3(sx, sy, sz).applyMatrix4(m.matrixWorld);
        const d = new THREE.Vector3(dx, dy, dz).normalize();
        window._camera.position.copy(t).addScaledVector(d, dist);
        window._controls.target.copy(t);
        window._controls.update();
      }, [sx, sy, sz, dx, dy, dz, dist]);
      await page.waitForTimeout(400);
      await page.screenshot({ path });
      console.log('Shot', path);
    }
    await showOnly(['hopper']);
    // GAP A: wedge slot mid (SCAD 60,9,61) from outside-right
    await frameShot(60, 9, 61, 0.3, 1, 0.35, 70, '/tmp/gap_A_slot_mid.png');
    // GAP A: near tip (SCAD 74,9,66) close
    await frameShot(74, 9, 66, 0.2, 1, 0.3, 50, '/tmp/gap_A_slot_tip.png');
    // GAP B: root top (SCAD 17,9,76) close
    await frameShot(17, 9, 76, -0.3, 1, 0.4, 50, '/tmp/gap_B_root_top.png');
    // Apex/nose junction (SCAD 80,0,67) from front-right-top
    await frameShot(80, 0, 67, 0.5, 0.8, 0.5, 70, '/tmp/gap_apex_nose.png');
    // Mouth + drum context
    await showOnly(['hopper', 'cartridge']);
    await frameShot(20, 0, 60, 0.1, 1, 0.5, 110, '/tmp/gap_mouth_ctx.png');
    // Full assembly
    await showOnly(['chassis', 'hopper', 'cartridge', 'cones_a', 'cones_b', 'plow', 'rollers_lower', 'rollers_upper', 'crank', 'tape']);
    await page.evaluate(() => {
      window._camera.position.set(300, 220, 300);
      window._controls.target.set(-20, 55, 40);
      window._controls.update();
    });
    await page.waitForTimeout(400);
    await page.screenshot({ path: '/tmp/gap_full.png' });
    console.log('Shot /tmp/gap_full.png');
    console.log('Console errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
  } finally {
    await browser.close();
  }
})();
