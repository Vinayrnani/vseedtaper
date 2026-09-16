const { chromium } = require('playwright');

const BOX = { x: [0, 200], y: [0, 110], z: [-60, 0] };
// Parts allowed outside the box by design (with reasons asserted in output)
const KNOWN_OUTSIDE = {
  chassis: 'reference envelope itself: corner gussets reach x=210, bearing blocks reach z=+2',
  crank: 'external hand crank: handle + shaft outside wall by design',
  cones: 'spool cones overhang open chassis end (axle x=10 < cone r 22.5)',
  rollers: 'lower roller shaft tip passes through wall bearing to crank',
};
const EPS = 1e-6;

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

  // ---- screenshots: default orbit, true top (plan), true front (elevation) ----
  async function setView(px, py, pz, tx, ty, tz) {
    await page.evaluate(([px, py, pz, tx, ty, tz]) => {
      window._camera.position.set(px, py, pz);
      window._controls.target.set(tx, ty, tz);
      window._controls.update();
    }, [px, py, pz, tx, ty, tz]);
    await page.waitForTimeout(400);
  }
  await page.evaluate(() => { window._overrideAngle = 0; });
  await setView(300, 220, 300, -20, 55, 40);
  await page.screenshot({ path: '/tmp/fit_t0.png' });
  console.log('Screenshot /tmp/fit_t0.png taken');

  await setView(5, 520, 26, 5, 0, 26);
  await page.screenshot({ path: '/tmp/fit_top.png' });
  console.log('Screenshot /tmp/fit_top.png taken');

  await setView(5, 60, 460, 5, 55, 26);
  await page.screenshot({ path: '/tmp/fit_side.png' });
  console.log('Screenshot /tmp/fit_side.png taken');
  await setView(300, 220, 300, -20, 55, 40);
  await page.evaluate(() => { window._overrideAngle = null; });

  console.log('Console errors:', errors.length);
  errors.forEach(e => console.log('  ', e));

  // ---- crank grip orbit: centroid of grip-region meshes, radius about scad shaft (160, z=60) ----
  console.log('\n--- Crank orbit check (grip centroid, expect r=45.00) ---');
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
            // grip surface in SPINNER frame ≈ centroid (45, 0, -25);
            // arm plate lives near z≈0, hub/shaft near x<30 -> cut both away
            if (local.x > 30 && local.z < -12) pts.push([v.x, v.y, v.z]);
          }
        }
      });
      if (!pts.length) return null;
      const c = [0, 0, 0];
      pts.forEach(p => { c[0] += p[0]; c[1] += p[1]; c[2] += p[2]; });
      c[0] /= pts.length; c[1] /= pts.length; c[2] /= pts.length;
      // world -> root-local: root offset (-100,0,55), identity rotation
      const rl = [c[0] + 100, c[1], c[2] - 55];
      // root-local (M-frame) -> scad: (x, y, z) -> (x, -z, y)
      return { x: rl[0], y: -rl[2], z: rl[1], n: pts.length };
    }, angle);
    if (q) {
      const r = Math.hypot(q.x - 160, q.z - 60);
      radii.push(r);
      console.log(`  t=${i * 0.25}: grip=(${q.x.toFixed(2)}, ${q.y.toFixed(2)}, ${q.z.toFixed(2)}) n=${q.n} radius=${r.toFixed(3)}`);
    } else { console.log(`  t=${i * 0.25}: NO GRIP MESHES FOUND`); }
    await page.waitForTimeout(150);
  }
  if (radii.length) {
    const avg = radii.reduce((a, b) => a + b, 0) / radii.length;
    const spread = Math.max(...radii) - Math.min(...radii);
    console.log(`Average radius: ${avg.toFixed(3)} (expect 45, |avg-45|<=1: ${Math.abs(avg - 45) <= 1}, spread<=0.5: ${spread <= 0.5})`);
  }

  // ---- axle horizontal ----
  console.log('\n--- Axle horizontal check (probe (0,0,1), expect y~=0) ---');
  const data = await page.evaluate(() => window._getPivotData());
  for (const k of ['lowerAxle', 'upperAxle', 'drumAxle']) {
    if (data[k]) console.log(`  ${k} y=${data[k].y.toFixed(6)} horizontal=${Math.abs(data[k].y) < 0.01}`);
  }

  // ---- per-part fit in root-local box (frozen at angle 0) ----
  console.log('\n--- Per-part fit vs root-local X[0,200] Y[0,110] Z[-60,0] ---');
  const fit = await page.evaluate((box) => {
    const out = {};
    const root = window._root;
    window._setRotations(0);
    root.updateWorldMatrix(true, true);
    const inv = root.matrixWorld.clone().invert();
    const EPS = 1e-6;
    for (const id of Object.keys(window._partMeshes)) {
      const bb = new THREE.Box3();
      window._partMeshes[id].forEach(o => bb.expandByObject(o));
      const loc = bb.clone().applyMatrix4(inv);
      const mn = loc.min, mx = loc.max;
      const inside =
        mn.x >= box.x[0] - EPS && mx.x <= box.x[1] + EPS &&
        mn.y >= box.y[0] - EPS && mx.y <= box.y[1] + EPS &&
        mn.z >= box.z[0] - EPS && mx.z <= box.z[1] + EPS;
      const belowGround = mn.y < -EPS;
      out[id] = {
        min: [mn.x, mn.y, mn.z].map(v => +v.toFixed(2)),
        max: [mx.x, mx.y, mx.z].map(v => +v.toFixed(2)),
        inside, belowGround,
      };
    }
    return out;
  }, BOX);
  for (const [id, f] of Object.entries(fit)) {
    const tag = f.inside ? 'inside=true' : `inside=false (${KNOWN_OUTSIDE[id] || 'UNEXPECTED'})`;
    console.log(`  ${id}: min=[${f.min}] max=[${f.max}] ${tag} belowGround=${f.belowGround}`);
  }

  console.log('\nScreenshots: /tmp/fit_t0.png, /tmp/fit_top.png, /tmp/fit_side.png');
  await browser.close();
  console.log('Browser closed');
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
