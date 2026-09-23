#!/usr/bin/env node
// verify_v118: Step-3 snap-arrow nose closeups (axle solo + assembled).
// Pool pattern: never browser.close(), use pool.releaseBrowser(browser).
const pool = require('./playwright_pool');

(async () => {
  const { browser, page } = await pool.newPage({ width: 1600, height: 1000 });
  const errors = [];
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', e => errors.push(e.message));

  await page.goto('http://localhost:9099/index.html', { waitUntil: 'networkidle' });
  await page.waitForFunction(() => {
    const el = document.getElementById('status');
    return el && el.textContent.includes('ready');
  }, { timeout: 30000 });
  await page.waitForTimeout(500);

  async function frameOn(groups, eastBias, dist, shot) {
    await page.evaluate(g => { window._setOnlyVisible(g); }, groups);
    await page.waitForTimeout(400);
    await page.evaluate(({ groups, eastBias, dist }) => {
      const box = new THREE.Box3();
      groups.forEach(t => {
        const obj = window._toggleGroups[t].objects.find(o => o && o.isObject3D);
        if (obj) box.expandByObject(obj);
      });
      const c = new THREE.Vector3(); box.getCenter(c);
      c.x += eastBias; // nose lives at the east end
      const dir = new THREE.Vector3(0.85, 0.45, 0.6).normalize();
      window._camera.position.copy(c.clone().add(dir.multiplyScalar(dist)));
      window._camera.lookAt(c);
      if (window._controls) { window._controls.target.copy(c); window._controls.update(); }
    }, { groups, eastBias, dist });
    await page.waitForTimeout(300);
    await page.screenshot({ path: '/home/ubuntu/projects/vseedtaper/screenshots/' + shot });
  }

  await frameOn(['twister_axle'], 10, 60, 'v118_axle_nose.png');
  await frameOn(['twister', 'twister_axle'], 6, 70, 'v118_snap_fit.png');

  await page.evaluate(() => { window._showAllParts(); });
  await page.waitForTimeout(400);
  await page.screenshot({ path: '/home/ubuntu/projects/vseedtaper/screenshots/v118_machine.png' });

  if (errors.length > 0) {
    console.error('CONSOLE ERRORS:', JSON.stringify(errors));
    await pool.releaseBrowser(browser);
    process.exit(1);
  }
  console.log('verify_v118 PASSED, 0 console errors');
  await pool.releaseBrowser(browser);
})().catch(async e => { console.error('FAIL:', e.message); process.exit(1); });
