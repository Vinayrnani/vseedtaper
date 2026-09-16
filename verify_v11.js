const { chromium } = require('playwright');

// v11 verify: right-pickup / left-drop / left-crank rebuild.
// Asserts: 0 console errors, hopper tube LEFT (min.x<75) + wedge RIGHT (max.x>170),
// crank mount LEFT of drum (x=77.5), dropSeed x=67, crank grip orbit r~=45 about
// (77.5,60), drum seed path right->top->left->bottom (CCW, top moves left).
(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  const errors = [];
  page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
  page.on('pageerror', err => errors.push(err.message));

  await page.goto('http://localhost:9099/web/index.html');
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
  // World = root-local + (-100, 0, 55). Drum root-local (100,60,-30) -> world (0,60,25).
  // Right mouth world x 14..83; left tube world x -33; crank world x -22.5, z -13.
  await setView(45, 65, 190, 45, 58, 25);
  await page.screenshot({ path: '/tmp/lr_pickup.png' });
  console.log('Screenshot /tmp/lr_pickup.png (right pickup mouth)');
  await setView(-33, 50, 190, -33, 47, 25);
  await page.screenshot({ path: '/tmp/lr_drop.png' });
  console.log('Screenshot /tmp/lr_drop.png (left drop tube)');
  await setView(-22, 65, -190, -22, 60, -13);
  await page.screenshot({ path: '/tmp/lr_crank.png' });
  console.log('Screenshot /tmp/lr_crank.png (left crank)');
  await setView(300, 220, 300, -20, 55, 40);
  await page.screenshot({ path: '/tmp/lr_full.png' });
  console.log('Screenshot /tmp/lr_full.png (full assembly)');
  await page.evaluate(() => { window._overrideAngle = null; });

  console.log('Console errors:', errors.length);
  errors.forEach(e => console.log('  ', e));

  // ---- layout asserts (root-local frame) ----
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
    const cm = window._pivots.crankMount.position;
    out.crankMount = [cm.x, cm.y, cm.z];
    window._setRotations(0.7);
    root.updateWorldMatrix(true, true);
    const ds = new THREE.Vector3();
    window._root.children.forEach(() => {});
    // dropSeed is added to root; find via seeds toggle group
    const seeds = window._toggleGroups.seeds.objects;
    const drop = seeds[seeds.length - 1];
    drop.getWorldPosition(ds);
    ds.applyMatrix4(inv);
    out.dropSeed = [+ds.x.toFixed(2), +ds.y.toFixed(2), +ds.z.toFixed(2)];
    return out;
  });
  console.log('\n--- layout (root-local) ---');
  console.log('  hopper x-range:', layout.hopperMinX, '..', layout.hopperMaxX,
    '| tube LEFT (min<75):', layout.hopperMinX < 75, '| wedge RIGHT (max>170):', layout.hopperMaxX > 170);
  console.log('  crankMount:', layout.crankMount, '| LEFT of drum (x<100):', layout.crankMount[0] < 100);
  console.log('  dropSeed:', layout.dropSeed, '| x~=67:', Math.abs(layout.dropSeed[0] - 67) < 2);

  // ---- crank grip orbit about drum-left shaft (77.5, 60) ----
  console.log('\n--- crank orbit (expect r=45.00 about x=77.5, z=60) ---');
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
      console.log(`  a=${i * 90}deg: grip=(${q.x.toFixed(2)}, ${q.y.toFixed(2)}, ${q.z.toFixed(2)}) n=${q.n} radius=${r.toFixed(3)}`);
    } else { console.log(`  a=${i * 90}deg: NO GRIP MESHES FOUND`); }
    await page.waitForTimeout(150);
  }
  if (radii.length) {
    const avg = radii.reduce((a, b) => a + b, 0) / radii.length;
    const spread = Math.max(...radii) - Math.min(...radii);
    console.log(`  avg=${avg.toFixed(3)} |avg-45|<=1: ${Math.abs(avg - 45) <= 1} spread<=0.5: ${spread <= 0.5}`);
  }

  // ---- drum seed path: 3-o'clock -> top -> 9-o'clock -> bottom (CCW) ----
  console.log('\n--- drum seed path (expect right->top->left->bottom) ---');
  const path = await page.evaluate(() => {
    const pts = [];
    const root = window._root;
    const inv = root.matrixWorld.clone().invert();
    for (let i = 0; i < 4; i++) {
      window._setRotations(i * Math.PI); // drum = angle*0.5 -> 0,90,180,270 deg
      root.updateWorldMatrix(true, true);
      const seed = window._pivots.drum.children.find(c => c.type === 'Group' && c.children.length === 5).children[0];
      const v = new THREE.Vector3();
      seed.getWorldPosition(v);
      v.applyMatrix4(inv);
      pts.push([+v.x.toFixed(1), +v.y.toFixed(1)]);
    }
    return pts;
  });
  const names = ['3-oclock(right)', 'top', '9-oclock(left)', 'bottom'];
  path.forEach((p, i) => console.log(`  drum=${i * 90}deg: seed=(${p[0]}, ${p[1]}) expect ${names[i]}`));
  const okPath = path[0][0] > 110 && Math.abs(path[1][1] - 85) < 3 && path[2][0] < 90 && Math.abs(path[3][1] - 35) < 3;
  console.log('  path right->top->left CONFIRMED:', okPath);

  await browser.close();
  console.log('\nBrowser closed. Shots: /tmp/lr_pickup.png /tmp/lr_drop.png /tmp/lr_crank.png /tmp/lr_full.png');
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
