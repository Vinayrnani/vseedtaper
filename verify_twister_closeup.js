#!/usr/bin/env node
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

  if (errors.length > 0) {
    console.error('CONSOLE ERRORS during load:', JSON.stringify(errors));
    await pool.releaseBrowser(browser);
    process.exit(1);
  }

  async function captureCloseup(targetObjName, filename, visibilityFn) {
    if (visibilityFn) await visibilityFn(page);

    let distance, pixelSpread, tries = 0;
    const maxTries = 3;

    while (tries < maxTries) {
      tries++;
      const result = await page.evaluate(({ targetObjName, distance: d }) => {
        const tg = window._toggleGroups;
        const objGroup = tg[targetObjName];
        if (!objGroup) return { error: 'No group for ' + targetObjName };

        const obj = objGroup.objects.find(o => o && o.isObject3D);
        if (!obj) return { error: 'Object not loaded yet for ' + targetObjName };
        const box = new THREE.Box3().setFromObject(obj);
        const center = new THREE.Vector3();
        box.getCenter(center);
        const size = new THREE.Vector3();
        box.getSize(size);
        const diagonal = size.length();

        const dir = new THREE.Vector3(1, 0.35, 0.25).normalize();
        const camPos = center.clone().add(dir.multiplyScalar(d * diagonal));

        const cam = window._camera;
        const controls = window._controls;
        if (!cam || !controls) return { error: 'No camera/controls' };

        cam.position.copy(camPos);
        controls.target.copy(center);
        controls.update();

        const corners = [
          new THREE.Vector3(box.min.x, box.min.y, box.min.z),
          new THREE.Vector3(box.max.x, box.min.y, box.min.z),
          new THREE.Vector3(box.min.x, box.max.y, box.min.z),
          new THREE.Vector3(box.max.x, box.max.y, box.min.z),
          new THREE.Vector3(box.min.x, box.min.y, box.max.z),
          new THREE.Vector3(box.max.x, box.min.y, box.max.z),
          new THREE.Vector3(box.min.x, box.max.y, box.max.z),
          new THREE.Vector3(box.max.x, box.max.y, box.max.z),
        ];
        const proj = corners.map(c => {
          const v = c.clone().project(cam);
          return { x: (v.x + 1) / 2 * 1600, y: (1 - v.y) / 2 * 1000 };
        });
        const xs = proj.map(p => p.x);
        const ys = proj.map(p => p.y);
        const maxSpread = Math.max(Math.max(...xs) - Math.min(...xs), Math.max(...ys) - Math.min(...ys));

        return { center: [center.x, center.y, center.z], diagonal, distance: d, maxSpread };
      }, { targetObjName, distance: distance || 4 });

      if (result.error) { console.error(result.error); return false; }
      pixelSpread = result.maxSpread;
      distance = result.distance;
      if (pixelSpread >= 400) break;
      distance = distance / 2;
    }

    await page.evaluate(() => { window._controls.update(); });
    await page.waitForTimeout(200);

    const outPath = path.join('/home/ubuntu/projects/vseedtaper/screenshots', filename);
    await page.screenshot({ path: outPath, type: 'png' });
    const stat = fs.statSync(outPath);
    console.log(`${filename}: ${pixelSpread.toFixed(0)}px spread, ${tries} tries, ${(stat.size / 1024).toFixed(0)}KB`);
    return true;
  }

  await captureCloseup('twister_axle', 'axle_assembled.png', null);
  await captureCloseup('twister_axle', 'axle_bare.png', async (pg) => {
    await pg.evaluate(() => { window._setPartVisible('twister', false); });
  });

  await pool.releaseBrowser(browser);
  if (errors.length > 0) {
    console.error('POST-SHOOT ERRORS:', errors.join('; '));
    process.exit(1);
  }
  console.log('Done.');
})();
