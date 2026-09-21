const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v46 verify: SHAFT-MOUNTED gear train (user: GEAR SETUP incorrect,
// tape/shafts v45 fine). Audit faults fixed: TW 7.3 off rotor ->
// coaxial (172,17); PP 2.5 off nip + dead-end -> PULL-20T on the
// pull-A axle (194,53) with pin+tube+bridge-hole drive; idlers get
// modeled stubs+bosses (were floating); take-up takes off PULL via
// J-12T (shared PP layshaft deleted, P1 deleted, C-14T/21T doubles
// as pull idler). Ratios/signs/stations/gaps/tape/6-turner/mounts
// untouched. ASSET_V 29->30, all GLBs rebuilt --force.
// Live proof: animating + counter-rotation + ratios, clearances,
// gear-plane closeups, 0 errors.
// Shots: screenshots/v46_*.png (+ audit_*.png kept as was-wrong proof;
// max 25, prune oldest).
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

// v46 mesh table mirror (module 2, pitch r = T; err <= tol+0.01).
const MESHES = [
  ['crank', 40, 60, 20, 'drum', 100, 60, 40],
  ['DRUM', 100, 60, 40, 'C-in', 149.42, 38.24, 14],
  ['C-out', 149.42, 38.24, 21, 'TW', 172, 17, 10],
  ['C-in', 149.42, 38.24, 14, 'P2', 173.50, 28.43, 12],
  ['P2', 173.50, 28.43, 12, 'PULL', 194, 53, 20],
  ['PULL', 194, 53, 20, 'J', 225.86, 56.00, 12],
  ['J', 225.86, 56.00, 12, 'TU', 226, 34, 10],
];
// Shaft-coaxial proof points (must equal driven-shaft stations).
const COAX = [
  ['TW', 172, 17, 'bind_x/twister_axle_z'],
  ['PULL', 194, 53, 'pull_x axle line'],
  ['TU', 226, 34, 'takeup_x/takeup_z'],
];

(async () => {
  console.log('--- v46 static mesh audit (module 2, tol 0.3) ---');
  let staticFail = false;
  for (const [a, xa, za, ta, b, xb, zb, tb] of MESHES) {
    const d = Math.hypot(xb - xa, zb - za);
    const err = Math.abs(d - (ta + tb));
    const ok = err <= 0.31;
    console.log((ok ? 'PASS ' : 'FAIL ') + `mesh ${a}-${b}: dist ${Math.round(d * 100) / 100} vs r1+r2 ${ta + tb} (err ${Math.round(err * 10000) / 10000})`);
    if (!ok) staticFail = true;
  }
  const teeth = { tw: [(40 / 14) * (21 / 10), 6], pull: [(40 / 14) * (14 / 12) * (12 / 20), 2], tu: [(40 / 14) * (14 / 12) * (12 / 20) * (20 / 12) * (12 / 10), 4] };
  for (const [k, [got, want]] of Object.entries(teeth)) {
    const ok = Math.abs(got - want) < 1e-9;
    console.log((ok ? 'PASS ' : 'FAIL ') + `teeth ${k}: ${got} (want ${want}x drum)`);
    if (!ok) staticFail = true;
  }
  if (staticFail) { console.error('VERIFY FAILED: static audit'); process.exit(1); }

  const browser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
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

    // Gear-train hooks mirror the CAD shaft-mounted layout.
    const gear = await page.evaluate(() => window._gearTrain);
    console.log('gearTrain:', JSON.stringify(gear.chain));
    check(!!gear && gear.belts === false, 'gear-only drive, no belts');
    check(gear.mounts.twCoaxial[0] === 172 && gear.mounts.twCoaxial[1] === 17, 'TW rotor-coaxial mount (172,17)');
    check(gear.mounts.pullAxle[0] === 194 && gear.mounts.pullAxle[1] === 53, 'PULL on pull axle (194,53)');
    check(gear.mounts.tuCoaxial[0] === 226 && gear.mounts.tuCoaxial[1] === 34, 'TU reel-coaxial mount (226,34)');

    // Ratios unchanged (counter-rotation + flip-count signs).
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

    // Tape regression (v45 D1/D2 intact): static ribbon + pack span.
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
      console.log(`Cradle twister-chassis: ${r.d} (expect 1.5..4 rolling gap)`);
      check(r.d >= 1.5 && r.d <= 4.0, `twister cradled, no touch/no float (got ${r.d})`);
    }

    // Shots: gear-plane closeups (world: x=scadX-100, y=scadZ, z=55-scadY).
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
    await shot('v46_train_wide.png', [60, 45, 200], [60, 40, 40], null, 0.6);
    await shot('v46_twister_end.png', [62, 40, 140], [60, 38, 66], null, 0.6);
    await shot('v46_pull_end.png', [100, 42, 135], [100, 42, 65], null, 0.6);
    await shot('v46_iso.png', [185, 175, 235], [20, 35, 25], null, null);
    await page.evaluate(() => { window._showAllParts(); window._overrideAngle = null; window._setPanelCollapsed(false); });
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v46_anim_t0.png') });
    console.log('Shot: v46_anim_t0.png (animating)');
    await page.waitForTimeout(2500);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v46_anim_t1.png') });
    console.log('Shot: v46_anim_t1.png (animating, +2.5s)');

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 30):', assetV);
    check(assetV === '30', 'ASSET_V 30 (GLBs rebuilt)');
    await page.close();

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
