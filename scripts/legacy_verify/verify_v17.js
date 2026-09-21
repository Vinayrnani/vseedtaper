const { chromium } = require('playwright');

// v17 verify: RED pads deleted (mouth open), BLUE arc side-closure fins,
// PINK watertight tip. Shots: /tmp/v17_*.png.
// Asserts: 0 console errors; hopper bounds; crank orbit r=45; drop x~=100.
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
    console.log('Page loaded, status=ready');
    await page.waitForTimeout(500);
    await page.evaluate(() => { window._overrideAngle = 0; });

    async function setView(px, py, pz, tx, ty, tz) {
      await page.evaluate(([px, py, pz, tx, ty, tz]) => {
        window._camera.position.set(px, py, pz);
        window._controls.target.set(tx, ty, tz);
        window._controls.update();
      }, [px, py, pz, tx, ty, tz]);
      await page.waitForTimeout(400);
    }
    async function showOnly(ids) {
      await page.evaluate((ids) => {
        Object.keys(window._toggleGroups).forEach(k => {
          window._toggleGroups[k].objects.forEach(o => { if (o) o.visible = ids.includes(k); });
        });
        window._toggleGroups.seeds.objects.forEach(o => { if (o) o.visible = true; });
      }, ids);
      await page.waitForTimeout(300);
    }
    // RED: mouth closeup — diagonal pads gone, gap open (hopper+drum only)
    await showOnly(['hopper', 'cartridge']);
    await setView(20, 64, 110, 20, 58, 25);
    await page.screenshot({ path: '/tmp/v17_mouth.png' });
    console.log('Shot /tmp/v17_mouth.png');
    // BLUE: side angle on mouth closure
    await setView(120, 60, 130, 20, 58, 25);
    await page.screenshot({ path: '/tmp/v17_side.png' });
    console.log('Shot /tmp/v17_side.png');
    // PINK: apex tip closeup
    await setView(90, 70, 120, 80, 62, 10);
    await page.screenshot({ path: '/tmp/v17_apex.png' });
    console.log('Shot /tmp/v17_apex.png');
    // Full assembly + anim frame
    await showOnly(['chassis', 'hopper', 'cartridge', 'cones_a', 'cones_b', 'plow', 'rollers_lower', 'rollers_upper', 'crank', 'tape']);
    await setView(300, 220, 300, -20, 55, 40);
    await page.screenshot({ path: '/tmp/v17_full.png' });
    console.log('Shot /tmp/v17_full.png');
    await page.evaluate(() => { window._overrideAngle = 0.9; });
    await page.waitForTimeout(400);
    await page.screenshot({ path: '/tmp/v17_anim.png' });
    await page.evaluate(() => { window._overrideAngle = null; });
    console.log('Shot /tmp/v17_anim.png');

    console.log('Console errors:', errors.length);
    errors.forEach(e => console.log('  ', e));

    const layout = await page.evaluate(() => {
      const out = {};
      const root = window._root;
      window._setRotations(0);
      root.updateWorldMatrix(true, true);
      const inv = root.matrixWorld.clone().invert();
      const bb = new THREE.Box3();
      window._partMeshes.hopper.forEach(o => bb.expandByObject(o));
      const loc = bb.clone().applyMatrix4(inv);
      out.hopperMinX = +loc.min.x.toFixed(2);
      out.hopperMaxX = +loc.max.x.toFixed(2);
      out.hopperMinY = +loc.min.y.toFixed(2);
      const cm = window._pivots.crankMount.position;
      out.crankMount = [cm.x, cm.y, cm.z];
      window._setRotations(0.7);
      root.updateWorldMatrix(true, true);
      const seeds = window._toggleGroups.seeds.objects;
      const drop = seeds[seeds.length - 1];
      const ds = new THREE.Vector3();
      drop.getWorldPosition(ds);
      ds.applyMatrix4(inv);
      out.dropSeed = [+ds.x.toFixed(2), +ds.y.toFixed(2), +ds.z.toFixed(2)];
      return out;
    });
    console.log('hopper x:', layout.hopperMinX, '..', layout.hopperMaxX,
      '| LEFT ok:', layout.hopperMinX > 69 && layout.hopperMinX < 75,
      '| RIGHT ok:', layout.hopperMaxX > 180 && layout.hopperMaxX < 186);
    console.log('hopper minY (~30.5):', layout.hopperMinY, Math.abs(layout.hopperMinY - 30.5) < 1.5);
    console.log('crankMount LEFT (x<100):', layout.crankMount, layout.crankMount[0] < 100);
    console.log('dropSeed x~=100:', layout.dropSeed, Math.abs(layout.dropSeed[0] - 100) < 2);

    const radii = [];
    for (let i = 0; i < 4; i++) {
      const angle = i * 0.25 * Math.PI * 2;
      const q = await page.evaluate((a) => {
        window._setRotations(a);
        const THREE = window.THREE;
        const spinner = window._crankSpinner;
        spinner.updateWorldMatrix(true, true);
        const pts = [];
        spinner.traverse((n) => {
          if (n.isMesh && n.geometry && n.geometry.attributes) {
            const pos = n.geometry.attributes.position;
            const v = new THREE.Vector3();
            for (let i = 0; i < pos.count; i += 3) {
              v.fromBufferAttribute(pos, i).applyMatrix4(n.matrixWorld);
              const local = spinner.worldToLocal(v.clone());
              if (local.x > 30 && local.z < -12) pts.push([v.x, v.y, v.z]);
            }
          }
        });
        if (!pts.length) return null;
        const c = [0, 0, 0];
        pts.forEach(p => { c[0] += p[0]; c[1] += p[1]; c[2] += p[2]; });
        c[0] /= pts.length; c[1] /= pts.length; c[2] /= pts.length;
        const rl = [c[0] + 100, c[1], c[2] - 55];
        return { x: rl[0], y: -rl[2], z: rl[1], n: pts.length };
      }, angle);
      if (q) {
        const r = Math.hypot(q.x - 77.5, q.z - 60);
        radii.push(r);
        console.log(`  a=${i * 90}deg: radius=${r.toFixed(3)}`);
      } else { console.log(`  a=${i * 90}deg: NO GRIP FOUND`); }
      await page.waitForTimeout(150);
    }
    if (radii.length) {
      const avg = radii.reduce((a, b) => a + b, 0) / radii.length;
      console.log(`  crank avg=${avg.toFixed(3)} ok:${Math.abs(avg - 45) <= 1}`);
    }
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
