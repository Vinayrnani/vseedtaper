#!/usr/bin/env node
// verify_v116: B->twister mitre mate preview (apex 167,34,32).
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

  const assetV = await page.evaluate(() => {
    const m = document.documentElement.innerHTML.match(/ASSET_V = (\d+)/);
    return m ? +m[1] : null;
  });
  console.log('ASSET_V:', assetV);

  // Pivots: B must sit at the mitre apex station (167, 32)
  const piv = await page.evaluate(() => {
    window._root.updateMatrixWorld(true);
    const rp = new THREE.Vector3(); window._root.getWorldPosition(rp);
    const out = {};
    ['A', 'B'].forEach(k => {
      const p = new THREE.Vector3();
      window._drive.pivots[k].getWorldPosition(p).sub(rp);
      out[k] = [+p.x.toFixed(2), +p.y.toFixed(2)];
    });
    return out;
  });
  console.log('PIVOTS ' + JSON.stringify(piv));

  // Idler mesh closeup: A + idler + B visible, camera on the idler from front-east
  await page.evaluate(() => { window._setOnlyVisible(['gear_A', 'gear_I', 'gear_B']); });
  await page.waitForTimeout(400);
  await page.evaluate(() => {
    const cI = new THREE.Vector3();
    new THREE.Box3().setFromObject(window._toggleGroups['gear_I'].objects.find(o => o && o.isObject3D)).getCenter(cI);
    const dir = new THREE.Vector3(0.7, 0.5, 0.75).normalize();
    const dist = 95;
    window._camera.position.copy(cI.clone().add(dir.multiplyScalar(dist)));
    window._camera.lookAt(cI);
    if (window._controls) { window._controls.target.copy(cI); window._controls.update(); }
  });
  await page.waitForTimeout(300);
  await page.screenshot({ path: '/home/ubuntu/projects/vseedtaper/screenshots/v116_train.png' });

  // Twister solo (bevel ring detail)
  await page.evaluate(() => { window._setOnlyVisible(['gear_A', 'gear_I', 'gear_B']); });
  await page.waitForTimeout(400);
  await page.screenshot({ path: '/home/ubuntu/projects/vseedtaper/screenshots/v116_idler_mesh.png' });

  // Full machine
  await page.evaluate(() => { window._showAllParts(); });
  await page.waitForTimeout(400);
  await page.screenshot({ path: '/home/ubuntu/projects/vseedtaper/screenshots/v116_machine.png' });

  if (errors.length > 0) {
    console.error('CONSOLE ERRORS:', JSON.stringify(errors));
    await pool.releaseBrowser(browser);
    process.exit(1);
  }
  console.log('verify_v116 PASSED, 0 console errors');
  await pool.releaseBrowser(browser);
})().catch(async e => { console.error('FAIL:', e.message); process.exit(1); });
