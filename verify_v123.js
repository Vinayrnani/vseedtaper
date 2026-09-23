#!/usr/bin/env node
// verify_v123: Step-6 mesh tooth-into-gap audit — one closeup per mesh.
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

  async function meshShot(groups, file, dir, dist) {
    await page.evaluate(g => { window._setOnlyVisible(g); }, groups);
    await page.waitForTimeout(400);
    await page.evaluate(({ groups, dir, dist }) => {
      const box = new THREE.Box3();
      groups.forEach(t => {
        const obj = window._toggleGroups[t].objects.find(o => o && o.isObject3D);
        if (obj) box.expandByObject(obj);
      });
      const a = new THREE.Box3(), b = new THREE.Box3();
      const oa = window._toggleGroups[groups[0]].objects.find(o => o && o.isObject3D);
      const ob = window._toggleGroups[groups[1]].objects.find(o => o && o.isObject3D);
      if (oa) a.setFromObject(oa);
      if (ob) b.setFromObject(ob);
      const ca = new THREE.Vector3(); a.getCenter(ca);
      const cb = new THREE.Vector3(); b.getCenter(cb);
      const mid = ca.clone().add(cb).multiplyScalar(0.5);
      const d = new THREE.Vector3(...dir).normalize();
      window._camera.position.copy(mid.clone().add(d.multiplyScalar(dist)));
      window._camera.lookAt(mid);
      if (window._controls) { window._controls.target.copy(mid); window._controls.update(); }
    }, { groups, dir, dist });
    await page.waitForTimeout(300);
    await page.screenshot({ path: '/home/ubuntu/projects/vseedtaper/screenshots/' + file });
  }

  await meshShot(['crank', 'gear_A'], 'v123_mesh_crank_A10.png', [0.5, 0.5, 0.9], 70);
  await meshShot(['gear_A', 'gear_I'], 'v123_mesh_A30_I.png', [0.7, 0.45, 0.7], 70);
  await meshShot(['gear_I', 'gear_B'], 'v123_mesh_I_B10.png', [0.7, 0.45, 0.7], 70);
  await meshShot(['gear_B', 'twister'], 'v123_mesh_B_tw.png', [-0.8, 0.45, 0.6], 55);

  if (errors.length > 0) {
    console.error('CONSOLE ERRORS:', JSON.stringify(errors));
    await pool.releaseBrowser(browser);
    process.exit(1);
  }
  console.log('verify_v123 PASSED, 0 console errors');
  await pool.releaseBrowser(browser);
})().catch(async e => { console.error('FAIL:', e.message); process.exit(1); });
