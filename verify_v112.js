#!/usr/bin/env node
// verify_v112: Step1 standard-form twister spur teeth preview.
// Pool pattern: never browser.close(), use pool.releaseBrowser(browser).
const pool = require('./playwright_pool');
const fs = require('fs');
const path = require('path');

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

  // Solo twister, teeth closeup from front-east (teeth face -X/west, disc east)
  await page.evaluate(() => { window._setOnlyVisible(['twister']); });
  await page.waitForTimeout(400);
  const r = await page.evaluate(() => {
    const tg = window._toggleGroups;
    const obj = tg['twister'].objects.find(o => o && o.isObject3D);
    const box = new THREE.Box3().setFromObject(obj);
    const center = new THREE.Vector3(); box.getCenter(center);
    const size = new THREE.Vector3(); box.getSize(size);
    const dir = new THREE.Vector3(-1, 0.35, 0.3).normalize();
    const camPos = center.clone().add(dir.multiplyScalar(2.2 * size.length()));
    window._camera.position.copy(camPos);
    window._camera.lookAt(center);
    if (window._controls) { window._controls.target.copy(center); window._controls.update(); }
    return { cx: center.x.toFixed(1), size: size.toArray().map(v => +v.toFixed(1)) };
  });
  console.log('twister center/size:', JSON.stringify(r));
  await page.waitForTimeout(300);
  await page.screenshot({ path: '/home/ubuntu/projects/vseedtaper/screenshots/v112_twister_teeth.png' });

  // Iso with axle for context
  await page.evaluate(() => { window._showAllParts(); });
  await page.waitForTimeout(400);
  await page.screenshot({ path: '/home/ubuntu/projects/vseedtaper/screenshots/v112_machine.png' });

  if (errors.length > 0) {
    console.error('CONSOLE ERRORS:', JSON.stringify(errors));
    await pool.releaseBrowser(browser);
    process.exit(1);
  }
  console.log('verify_v112 PASSED, 0 console errors');
  await pool.releaseBrowser(browser);
})().catch(async e => { console.error('FAIL:', e.message); process.exit(1); });
