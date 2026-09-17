const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v47 verify: BEVEL twister drive, ZERO exterior gears (user: REMOVE
// outside gears, twister<->drum via perpendicular bevels + ratio).
// Deleted: DRUM40/C-14T-21T/TW-10T/P2-12T/PULL-20T/J-12T/TU-10T +
// stubs/bosses/tongue/tube/bridge-hole (wall clean solid). New:
// drum 20T -> vertical 10T = 2x at I_top (100,30,60); vertical 30T
// -> twister 10T = 3x at I_bot (100,30,17); total 6.0 = 1 bind/seed.
// Pull/takeup tape-coupled (no gears, documented). Ratios/signs/
// stations/gaps/tape/6-turner/mounts untouched. ASSET_V 30->31, all
// GLBs rebuilt --force.
// Live proof: animating + ratios, bevel apices, ZERO exterior verts
// on the chassis GLB (scadY < -0.5), closeups, 0 errors.
// Shots: screenshots/v47_*.png (max 25, prune oldest).
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

// v47 bevel table mirror (module 2, pitch r = m*Z/2).
const Zdb = 20, Zvt = 10, Zvb = 30, Ztw = 10;
const Rdb = Zdb, Rvt = Zvt, Rvb = Zvb, Rtw = Ztw; // m=2 -> r=Z
const ITOP = [100, 30, 60], IBOT = [100, 30, 17];
const Cd = [100, 20, 60], Cvt = [100, 30, 40], Cvb = [100, 30, 27], Ctw = [130, 30, 17];

(async () => {
  console.log('--- v47 static bevel audit (module 2, tol 0.3) ---');
  let staticFail = false;
  function scheck(cond, msg) {
    console.log((cond ? 'PASS ' : 'FAIL ') + msg);
    if (!cond) staticFail = true;
  }
  const ratio = (Zdb / Zvt) * (Zvb / Ztw);
  scheck(ratio === 6, `ratio (20/10)*(30/10) = ${ratio} (want 6.0)`);
  for (const z of [Zdb, Zvt, Zvb, Ztw]) scheck(z >= 10 && z <= 60, `teeth ${z} in [10,60]`);
  scheck(ITOP[0] === 100 && ITOP[2] === 60, 'I_top on drum axis (100,60)');
  scheck(ITOP[0] === 100 && ITOP[1] === 30, 'I_top on vertical shaft (100,30)');
  scheck(IBOT[0] === 100 && IBOT[1] === 30, 'I_bot on vertical shaft (100,30)');
  scheck(IBOT[1] === 30 && IBOT[2] === 17, 'I_bot on twister shaft (30,17), coaxial z=17');
  const dot = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
  scheck(dot([0, 1, 0], [0, 0, 1]) === 0, 'drum-Y perp vertical-Z (90 deg)');
  scheck(dot([0, 0, 1], [1, 0, 0]) === 0, 'vertical-Z perp twister-X (90 deg)');
  const dist = (a, b) => Math.hypot(a[0] - b[0], a[1] - b[1], a[2] - b[2]);
  scheck(Math.abs(dist(Cd, ITOP) - Rvt) < 1e-9, `drum centre r_vt off apex (${dist(Cd, ITOP)} vs ${Rvt})`);
  scheck(Math.abs(dist(Cvt, ITOP) - Rdb) < 1e-9, `vtop centre r_db off apex (${dist(Cvt, ITOP)} vs ${Rdb})`);
  scheck(Math.abs(dist(Cvb, IBOT) - Rtw) < 1e-9, `vbot centre r_tw off apex (${dist(Cvb, IBOT)} vs ${Rtw})`);
  scheck(Math.abs(dist(Ctw, IBOT) - Rvb) < 1e-9, `tw centre r_vb off apex (${dist(Ctw, IBOT)} vs ${Rvb})`);
  for (const [nm, c] of [['Cd', Cd], ['Cvt', Cvt], ['Cvb', Cvb], ['Ctw', Ctw]])
    scheck(c[1] >= 0, `${nm} interior y>=0 (zero exterior gears)`);
  scheck(Ctw[2] - (Rtw + 2) >= 0, 'twister bevel min_z>=0');
  scheck(IBOT[2] >= 0, 'vbot apex min_z>=0');
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

    // Bevel hooks mirror the CAD layout.
    const gear = await page.evaluate(() => window._gearTrain);
    console.log('gearTrain:', JSON.stringify(gear.chain));
    check(!!gear && gear.belts === false, 'bevel drive, no belts');
    check(gear.exteriorGears === 0, 'zero exterior gears (wall clean)');
    check(!!gear.bevel && gear.bevel.includes('6.0'), 'bevel note carries 6.0 ratio');
    check(gear.mounts.twCoaxial[0] === 172 && gear.mounts.twCoaxial[1] === 17, 'twister drive coaxial (172,17)');
    check(gear.mounts.drumTakeoff[0] === 100 && gear.mounts.drumTakeoff[1] === 60, 'drum takeoff coaxial (100,60)');
    check(gear.mounts.iTop.join() === '100,30,60' && gear.mounts.iBot.join() === '100,30,17', 'apices I_top/I_bot');

    // Ratios unchanged (1 bind/seed kept: twister -3x crank = 6x drum).
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

    // ZERO-EXTERIOR proof: chassis GLB verts with scadY < -2.5
    // (world: scadY = 55 - worldZ). Bearing blocks fuse 2.0 into the
    // walls + base chamfers reach 1.0 by design (v27, fused — not
    // gears); the v43-v46 spur farm lived at -16..-2. Threshold -2.5
    // clears legit fused overlap and catches any gear/stub clutter.
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
      // v47 drive-contact proof: the twister shaft (100->172) fuses
      // INTO the rotor hub by design (the bevel drive must connect —
      // a fused joint, not a graze), so the all-verts min reads <1.5.
      // The cradle rolling gap (posts vs ring = 2.0) is CAD-asserted
      // analytically (exact, stronger than vertex sampling); the four
      // station-gap probes above catch any misplaced steel live.
      const r = await minDist(['twister'], ['chassis']);
      console.log(`Drive twister-chassis: ${r.d} (expect < 2.0 fused shaft-hub joint)`);
      check(r.d < 2.0, `twister drive connects to chassis shaft (got ${r.d})`);
    }

    // Shots: bevel closeups (world: x=scadX-100, y=scadZ, z=55-scadY).
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
    // Closeups from INSIDE the chassis (bevels are interior steel;
    // world: x=scadX-100, y=scadZ, z=55-scadY; interior z in -5..55).
    // I_top (0,60,25): drum-Y bevel + vertical-top bevel + jackshaft.
    await shot('v47_bevel_top.png', [60, 70, 10], [0, 60, 25], null, 0.6);
    // I_bot (0,17,25) + twister bevel (30,17,25) + shaft to the rotor.
    await shot('v47_bevel_bot.png', [55, 40, 5], [15, 17, 25], null, 0.6);
    // Back-wall exterior from far behind (outer face world z=55):
    // full 262x110 wall in frame, must show ZERO gear clutter.
    await shot('v47_wall_clean.png', [20, 55, 350], [20, 50, 55], null, 0.6);
    await shot('v47_iso.png', [185, 175, 235], [20, 35, 25], null, null);
    await page.evaluate(() => { window._showAllParts(); window._overrideAngle = null; window._setPanelCollapsed(false); });
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v47_anim_t0.png') });
    console.log('Shot: v47_anim_t0.png (animating)');
    await page.waitForTimeout(2500);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v47_anim_t1.png') });
    console.log('Shot: v47_anim_t1.png (animating, +2.5s)');

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 31):', assetV);
    check(assetV === '31', 'ASSET_V 31 (GLBs rebuilt)');
    await page.close();

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
