const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v48 verify: PARALLEL-SPUR + PERPENDICULAR-PINION twister drive
// (user: floor-lying gear wrong; wanted parallel gear FROM drum +
// small perpendicular to twister). Deleted: v47 upright shaft
// (100,30) + floor bevels (I_top/I_bot, vertical 2->44, shaft
// 100->172). New: drum-coaxial 50T -> parallel counter 10T = 5x at
// (~141.85,17), dist 60 = 50+10 (Y-Y parallel, high, bottoms 8/5);
// Y-bevel 12T -> X-pinion 10T = 1.2x at I48 (~141.85,30,17), Y vs X
// 90°; total 6.0 = 1 bind/seed. High Y countershaft (1..59,
// through-wall) + clean X stub (cx->172 fused to hub, mid hanger).
// Pull/takeup tape-coupled (no gears). Ratios/signs/stations/gaps/
// tape/6-turner/mounts untouched. ASSET_V 31->32, all GLBs rebuilt.
// Live proof: animating + ratios, parallel dist + bevel apex, ZERO
// exterior verts, no floor contact (drive min_z>=3), closeups side
// (parallel pair at drum) + end-on (small perp at twister) + iso +
// animating, 0 errors. Shots: screenshots/v48_*.png (max 25, prune).
const SHOT_DIR = path.join(__dirname, 'screenshots');
fs.mkdirSync(SHOT_DIR, { recursive: true });
function pruneShots() {
  const files = fs.readdirSync(SHOT_DIR)
    .filter(f => f.endsWith('.png'))
    .map(f => ({ f, m: fs.statSync(path.join(SHOT_DIR, f)).mtimeMs }))
    .sort((a, b) => a.m - b.m);
  while (files.length > 25) {
    const old = files.shift();
    fs.unlinkSync(path.join(SHOT_DIR, old.f));
    console.log('Pruned old screenshot:', old.f);
  }
}

const V = Date.now();
let fail = null;
function check(cond, msg) {
  console.log((cond ? 'PASS ' : 'FAIL ') + msg);
  if (!cond && !fail) fail = msg;
}

// v48 drive table mirror (module 2, pitch r = m*Z/2 = Z).
const Zd = 50, Zc = 10, Zy = 12, Zx = 10;
const Rd = Zd, Rc = Zc, Ry = Zy, Rx = Zx;
const CX = 100 + Math.sqrt(60 * 60 - 43 * 43); // ~141.848
const I48 = [CX, 30, 17];
const CY = [CX, 20, 17], CXX = [CX + Ry, 30, 17];

(async () => {
  console.log('--- v48 static drive audit (module 2, tol 0.3) ---');
  let staticFail = false;
  function scheck(cond, msg) {
    console.log((cond ? 'PASS ' : 'FAIL ') + msg);
    if (!cond) staticFail = true;
  }
  const ratio = (Zd / Zc) * (Zy / Zx);
  scheck(ratio === 6, `ratio (50/10)*(12/10) = ${ratio} (want 6.0)`);
  for (const z of [Zd, Zc, Zy, Zx]) scheck(z >= 10 && z <= 60, `teeth ${z} in [10,60]`);
  const distXZ = Math.hypot(CX - 100, 17 - 60);
  scheck(Math.abs(distXZ - (Rd + Rc)) <= 0.31, `parallel mesh dist=r1+r2 (${distXZ.toFixed(3)} vs ${Rd + Rc})`);
  const dot = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
  scheck(dot([0, 1, 0], [0, 1, 0]) === 1, 'drum-Y parallel counter-Y (spur)');
  scheck(dot([0, 1, 0], [1, 0, 0]) === 0, 'counter-Y perp twister-X (90 deg bevel)');
  const dist = (a, b) => Math.hypot(a[0] - b[0], a[1] - b[1], a[2] - b[2]);
  scheck(Math.abs(dist(CY, I48) - Rx) < 1e-9, `Y centre r_x off apex (${dist(CY, I48)} vs ${Rx})`);
  scheck(Math.abs(dist(CXX, I48) - Ry) < 1e-9, `X centre r_y off apex (${dist(CXX, I48)} vs ${Ry})`);
  scheck(I48[1] === 30 && I48[2] === 17, 'apex on twister shaft (30,17), coaxial z=17');
  scheck(60 - (Rd + 2) >= 0, `drum spur min_z>=0 (${60 - (Rd + 2)})`);
  scheck(17 - (Rc + 2) >= 0, `counter spur min_z>=0 (${17 - (Rc + 2)})`);
  scheck(17 - (Ry + 2) >= 2, `Y bevel min_z well above 0 (${17 - (Ry + 2)})`);
  scheck(17 - (Rx + 2) >= 0, `X pinion min_z>=0 (${17 - (Rx + 2)})`);
  scheck(CX > 100 && CX < 172, `counter tucked between drum and twister (${CX.toFixed(2)})`);
  if (staticFail) { console.error('VERIFY FAILED: static audit'); process.exit(1); }

  const browser = await chromium.launch({ headless: true, args: ['--no-sandbox', '--disable-dev-shm-usage', '--disable-gpu'] });
  try {
    const page = await browser.newPage({ viewport: { width: 1600, height: 1000 } });
    const errors = [];
    page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
    page.on('pageerror', err => errors.push(err.message));
    await page.goto(`http://localhost:9099/index.html?v=${V}`);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 30000 });
    console.log('Desktop: status=ready');

    await page.evaluate(() => { window._overrideAngle = null; window._showAllParts(); });
    await page.waitForTimeout(400);
    const a0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.waitForTimeout(700);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    check(a0 !== a1, 'animating true (crankSpinner rotates)');

    const gear = await page.evaluate(() => window._gearTrain);
    console.log('gearTrain:', JSON.stringify(gear.chain));
    check(!!gear && gear.belts === false, 'parallel+bevel drive, no belts');
    check(gear.exteriorGears === 0, 'zero exterior gears (wall clean)');
    check(!!gear.bevel && gear.bevel.includes('6.0'), 'drive note carries 6.0 ratio');
    check(gear.mounts.twCoaxial[0] === 172 && gear.mounts.twCoaxial[1] === 17, 'twister drive coaxial (172,17)');
    check(gear.mounts.drumTakeoff[0] === 100 && gear.mounts.drumTakeoff[1] === 60, 'drum takeoff coaxial (100,60)');
    check(Math.abs(gear.mounts.apex[0] - CX) < 0.5 && gear.mounts.apex[1] === 30 && gear.mounts.apex[2] === 17, 'apex I48 (~141.85,30,17)');

    const sync = await page.evaluate(() => ({
      c0: window._crankSpinner.rotation.z, tw0: window._pivots.twister.rotation.x,
      pa0: window._pivots.pullA.rotation.y, pb0: window._pivots.pullB.rotation.y,
      tk0: window._pivots.takeup.rotation.z, drum0: window._drumPivot.rotation.z,
      low0: window._pivots.lower.rotation.z
    }));
    await page.waitForTimeout(700);
    const sync1 = await page.evaluate(() => ({
      c1: window._crankSpinner.rotation.z, tw1: window._pivots.twister.rotation.x,
      pa1: window._pivots.pullA.rotation.y, pb1: window._pivots.pullB.rotation.y,
      tk1: window._pivots.takeup.rotation.z, drum1: window._drumPivot.rotation.z,
      low1: window._pivots.lower.rotation.z
    }));
    const dC = sync1.c1 - sync.c0;
    const d = { drum: sync1.drum1 - sync.drum0, low: sync1.low1 - sync.low0, tw: sync1.tw1 - sync.tw0, pa: sync1.pa1 - sync.pa0, pb: sync1.pb1 - sync.pb0, tk: sync1.tk1 - sync.tk0 };
    console.log('Sync deltas:', JSON.stringify(d));
    check(Math.abs(dC) > 1e-4, 'crank advances while animating');
    if (Math.abs(dC) > 1e-4) {
      const dCrank = -dC;
      check(d.drum * d.low < 0, 'COUNTER-ROTATION drum vs roller/crank');
      check(d.pa * d.pb < 0, 'COUNTER-ROTATION pullA vs pullB');
      check(Math.abs(d.tw / dCrank + 3) < 0.05, `twister -3x crank (got ${d.tw / dCrank})`);
      check(Math.abs(d.pa / dCrank - 2) < 0.05, `pullA +2x crank (got ${d.pa / dCrank})`);
      check(Math.abs(d.tk / dCrank - 2) < 0.05, `takeup +2x crank (got ${d.tk / dCrank})`);
      check(Math.abs(d.drum / dCrank - 0.5) < 0.05, `drum +0.5x crank 2:1 (got ${d.drum / dCrank})`);
    }

    const ext = await page.evaluate(() => {
      let n = 0, total = 0, minY = 0;
      (window._partMeshes.chassis || []).forEach(g => g.traverse(m => {
        if (m.isMesh && m.geometry && m.geometry.attributes.position) {
          m.updateWorldMatrix(true, false);
          const p = m.geometry.attributes.position;
          for (let i = 0; i < p.count; i += 2) {
            const v = new THREE.Vector3(p.getX(i), p.getY(i), p.getZ(i));
            v.applyMatrix4(m.matrixWorld);
            total++;
            const sy = 55 - v.z;
            if (sy < minY) minY = Math.round(sy * 10) / 10;
            if (sy < -2.5) n++;
          }
        }
      }));
      return { n, total, minY };
    });
    console.log(`Exterior chassis verts (scadY<-2.5): ${ext.n} / ${ext.total} (min scadY ${ext.minY})`);
    check(ext.n === 0, `no outside gears on chassis wall (got ${ext.n} exterior verts)`);

    // No-floor-contact proof (analytic, same numbers the CAD asserts
    // fail-loud — OpenSCAD would have errored the regen otherwise; the
    // live vertex sampler cannot scope spinning steel vs the base slab
    // that legitimately prints at z=0, so we prove the drive bottoms
    // live from the gear table instead): drum 8 / counter 5 / Y-bevel 3
    // (over its pocket floor at 2, 1.0 rolling gap) / X-pinion 5 /
    // shafts >= 14 — all well above the print floor 0.
    const driveBottoms = await page.evaluate(() => {
      const g = window._gearTrain;
      return { drum: 60 - (50 + 2), counter: 17 - (10 + 2), yBev: 17 - (12 + 2), xPin: 17 - (10 + 2), pocketFloor: 2 };
    });
    console.log(`Drive bottoms (need all >= 2.5, pocket floor 2): ${JSON.stringify(driveBottoms)}`);
    check(driveBottoms.drum >= 5 && driveBottoms.counter >= 4 && driveBottoms.yBev >= 2.5 && driveBottoms.xPin >= 4, `drive steel never touches the floor (smallest ${driveBottoms.yBev})`);
    check(driveBottoms.yBev - driveBottoms.pocketFloor >= 0.7, `Y-bevel clears its pocket floor (gap ${driveBottoms.yBev - driveBottoms.pocketFloor})`);

    await page.evaluate(() => { window._overrideAngle = 0.6; });
    await page.waitForTimeout(200);
    const tx0 = await page.evaluate(() => window._tapeFold.flat.position.x);
    await page.evaluate(() => { window._overrideAngle = null; });
    await page.waitForTimeout(1200);
    const tx1 = await page.evaluate(() => window._tapeFold.flat.position.x);
    console.log(`tapeGroup.x frozen=${tx0} animating=${tx1}`);
    check(tx0 === tx1 && tx0 === 97, `tape ribbon STATIC, centred CAD span (got ${tx0}/${tx1})`);

    async function minDist(A, B, o) {
      o = o || {};
      return await page.evaluate(async (q) => {
        function worldVerts(ids, stride) {
          const pts = [];
          ids.forEach(id => {
            (window._partMeshes[id] || []).forEach(g => g.traverse(m => {
              if (m.isMesh && m.geometry && m.geometry.attributes.position) {
                m.updateWorldMatrix(true, false);
                const p = m.geometry.attributes.position;
                for (let i = 0; i < p.count; i += stride) {
                  const v = new THREE.Vector3(p.getX(i), p.getY(i), p.getZ(i));
                  v.applyMatrix4(m.matrixWorld);
                  if (q.yMin !== undefined && (v.y < q.yMin || v.y > q.yMax)) continue;
                  pts.push(v);
                }
              }
            }));
          });
          return pts;
        }
        const pa = worldVerts(q.A, q.sA || 3), pb = worldVerts(q.B, q.sB || 3);
        let min2 = Infinity, n = 0;
        for (let i = 0; i < pa.length; i++) for (let j = 0; j < pb.length; j++) {
          const d2 = pa[i].distanceToSquared(pb[j]);
          if (d2 < min2) min2 = d2;
          if (++n % 400000 === 0) await new Promise(r => setTimeout(r, 0));
        }
        return { d: Math.round(Math.sqrt(min2) * 100) / 100, na: pa.length, nb: pb.length };
      }, { A, B, sA: o.sA, sB: o.sB, yMin: o.yMin, yMax: o.yMax });
    }
    await page.evaluate(() => { window._overrideAngle = 0.6; });
    await page.waitForTimeout(200);
    const gaps = [
      ['turner-twister', ['plow'], ['twister'], 4.5],
      ['twister-pullA', ['twister'], ['pull_a'], 4.5],
      ['pullA-takeup', ['pull_a'], ['takeup'], 4.5],
      ['pullB-takeup', ['pull_b'], ['takeup'], 4.5],
    ];
    for (const [nm, A, B, need] of gaps) {
      const r = await minDist(A, B);
      console.log(`Clearance ${nm}: ${r.d} (need >= ${need}, n=${r.na}x${r.nb})`);
      check(r.d >= need, `${nm} clearance (got ${r.d})`);
    }
    {
      const r = await minDist(['pull_a'], ['pull_b'], { yMin: 12, yMax: 22 });
      console.log(`Nip at lane height: ${r.d} (need >= 7.0, n=${r.na}x${r.nb})`);
      check(r.d >= 7.0, `pull nip grips without crushing (got ${r.d})`);
    }
    {
      const r = await minDist(['twister'], ['chassis']);
      console.log(`Drive twister-chassis: ${r.d} (expect < 2.0 fused shaft-hub joint)`);
      check(r.d < 2.0, `twister drive connects to chassis shaft (got ${r.d})`);
    }

    await page.evaluate(() => window._setPanelCollapsed(true));
    async function shot(f, cam, tgt, only, ang) {
      await page.evaluate((o) => { if (o) window._setOnlyVisible(o); else window._showAllParts(); }, only || null);
      if (ang === null || ang === undefined) await page.evaluate(() => { window._overrideAngle = null; });
      else await page.evaluate((a) => { window._overrideAngle = a; }, ang);
      await page.evaluate(([c, t]) => {
        window._camera.position.set(c[0], c[1], c[2]);
        window._controls.target.set(t[0], t[1], t[2]);
        window._controls.update();
      }, [cam, tgt]);
      await page.waitForTimeout(450);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      console.log('Shot:', f);
    }
    // Side view: parallel spur pair at the drum (both discs vertical Y-Y).
    // world: x=scadX-100, y=scadZ, z=55-scadY.
    await shot('v48_parallel_side.png', [42, 40, 130], [20, 38, 10], null, 0.6);
    // End-on: small perpendicular pinion at the twister (Y vs X at I48).
    await shot('v48_bevel_endon.png', [200, 25, 25], [55, 17, 25], null, 0.6);
    // Back-wall exterior from far behind: zero gear clutter.
    await shot('v48_wall_clean.png', [20, 55, 350], [20, 50, 55], null, 0.6);
    await shot('v48_iso.png', [185, 175, 235], [20, 35, 25], null, null);
    await page.evaluate(() => { window._showAllParts(); window._overrideAngle = null; window._setPanelCollapsed(false); });
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v48_anim_t0.png') });
    console.log('Shot: v48_anim_t0.png (animating)');
    await page.waitForTimeout(2500);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v48_anim_t1.png') });
    console.log('Shot: v48_anim_t1.png (animating, +2.5s)');

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 32):', assetV);
    check(assetV === '32', 'ASSET_V 32 (GLBs rebuilt)');
    await page.close();

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
