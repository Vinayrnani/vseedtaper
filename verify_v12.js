const { chromium } = require('playwright');

// v12 verify: bottom-center drop / 11-to-6 cover / level wedge top.
// Shots: side elevation, mouth closeup, drop closeup, full assembly.
// Asserts: 0 console errors; hopper x-range ~71.5..183 (cover left, apex right);
// dropSeed x~=100 y~=30.5->30 over tape centerline (z=-30); crank orbit r=45
// about (77.5,60); drum CCW path right->top->left->bottom (drop at bottom 6).
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
  async function showOnly(ids) {
    await page.evaluate((ids) => {
      Object.keys(window._toggleGroups).forEach(k => {
        window._toggleGroups[k].objects.forEach(o => { if (o) o.visible = ids.includes(k); });
      });
      window._toggleGroups.seeds.objects.forEach(o => { if (o) o.visible = true; });
    }, ids);
    await page.waitForTimeout(300);
  }
  // SCENE coords = root-local + (-100, 0, 55).
  // drum scene (0,60,25); mouth scene (20,60,25); tube exit scene (0,30.5,25).
  // Chassis wall blocks the axle-on view: isolate hopper+drum for profiles.
  await showOnly(['hopper', 'cartridge']);
  await setView(0, 60, 255, 0, 55, 25);
  await page.screenshot({ path: '/tmp/v12_side.png' });
  console.log('Screenshot /tmp/v12_side.png (side elevation)');
  await setView(20, 64, 110, 20, 58, 25);
  await page.screenshot({ path: '/tmp/v12_mouth.png' });
  console.log('Screenshot /tmp/v12_mouth.png (mouth closeup)');
  await showOnly(['hopper', 'cartridge', 'tape']);
  await setView(0, 38, 110, 0, 30, 25);
  await page.screenshot({ path: '/tmp/v12_drop.png' });
  console.log('Screenshot /tmp/v12_drop.png (drop closeup)');
  await showOnly(['chassis', 'hopper', 'cartridge', 'cones_a', 'cones_b', 'plow', 'rollers_lower', 'rollers_upper', 'crank', 'tape']);
  await setView(300, 220, 300, -20, 55, 40);
  await page.screenshot({ path: '/tmp/v12_full.png' });
  console.log('Screenshot /tmp/v12_full.png (full assembly)');
  await page.evaluate(() => { window._overrideAngle = null; });

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
    out.hopperMaxY = +loc.max.y.toFixed(2);
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
    // tape ribbon world pos
    const tp = new THREE.Vector3();
    window._toggleGroups.tape.objects[0].getWorldPosition(tp);
    tp.applyMatrix4(inv);
    out.tape = [+tp.x.toFixed(2), +tp.y.toFixed(2), +tp.z.toFixed(2)];
    return out;
  });
  console.log('\n--- layout (root-local) ---');
  console.log('  hopper x:', layout.hopperMinX, '..', layout.hopperMaxX,
    '| cover-LEFT (min 70..74):', layout.hopperMinX > 69 && layout.hopperMinX < 75,
    '| wedge-RIGHT (max 181..185):', layout.hopperMaxX > 180 && layout.hopperMaxX < 186);
  console.log('  hopper y:', layout.hopperMinY, '..', layout.hopperMaxY,
    '| tube bottom ~30.5:', Math.abs(layout.hopperMinY - 30.5) < 1.5);
  console.log('  crankMount:', layout.crankMount, '| LEFT of drum (x<100):', layout.crankMount[0] < 100);
  console.log('  dropSeed:', layout.dropSeed, '| x~=100:', Math.abs(layout.dropSeed[0] - 100) < 2,
    '| y 30..30.5:', layout.dropSeed[1] >= 29.9 && layout.dropSeed[1] <= 30.6);
  console.log('  tape:', layout.tape, '| y~=30:', Math.abs(layout.tape[1] - 30) < 1,
    '| tube over tape (drop z ~= tape z):', Math.abs(layout.dropSeed[2] - layout.tape[2]) < 1);

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

  console.log('\n--- drum seed path (expect right->top->left->bottom, CCW) ---');
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
  const names = ['3-oclock(right)', 'top', '9-oclock(left)', 'bottom(6 drop)'];
  path.forEach((p, i) => console.log(`  drum=${i * 90}deg: seed=(${p[0]}, ${p[1]}) expect ${names[i]}`));
  const okPath = path[0][0] > 110 && Math.abs(path[1][1] - 85) < 3 && path[2][0] < 90 && Math.abs(path[3][1] - 35) < 3 && Math.abs(path[3][0] - 100) < 3;
  console.log('  path right->top->left->bottom CONFIRMED:', okPath);

  await browser.close();
  console.log('\nBrowser closed. Shots: /tmp/v12_side.png /tmp/v12_mouth.png /tmp/v12_drop.png /tmp/v12_full.png');
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
