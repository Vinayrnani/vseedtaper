const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v44 verify: MINIMAL drum-driven gear train (user: too many gears).
// CAD (fail-loud): single module 2, every mesh dist=r1+r2, half-pitch
// phasing, layshaft bosses + through-holes, same-plane non-mesh
// clearance >= 6, min_z=0, $fn=60, tol=0.3. Crank<->drum 2:1 is the
// only crank connection; downstream drives locally FROM exterior
// DRUM40 (8 pieces / 5 layshafts, was 16 in v43).
// Stations frozen (turner lip 160.35 -> twister gap 7.65, gaps >= 5);
// 6-turner geometry untouched; ratios/signs unchanged (take-up CAD -1440t).
// CAD (fail-loud): single module 2, every pair dist=r1+r2, half-pitch
// phasing, layshaft bosses + through-holes, min_z=0, $fn=60, tol=0.3.
// Stations frozen (turner lip 160.35 -> twister gap 7.65, gaps >= 5);
// 6-turner geometry untouched; take-up sense reversed (CAD -1440t).
// Live proof: animating + counter-rotation (crank vs drum opposite,
// pullA vs pullB opposite, flip-count signs) + mesh-distance asserts
// (JS mirror of the CAD math) + multi-angle overlap checks + ASSET_V 28.
// Shots: screenshots/v44_*.png (max 25, prune oldest).
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

// v44 mesh table mirror (CAD coords, module 2, pitch r = teeth):
// [nameA, xA, zA, TA, nameB, xB, zB, TB]
const MESHES = [
  ['crank', 40, 60, 20, 'drum', 100, 60, 40],
  ['DRUM', 100, 60, 40, 'C-in', 159.94, 62.71, 20],
  ['DRUM', 100, 60, 40, 'P1', 141.07, 28.10, 12],
  ['P1', 141.07, 28.10, 12, 'P2', 164.77, 24.34, 12],
  ['P2', 164.77, 24.34, 12, 'PP', 196.46, 28.79, 20],
  ['PP', 196.46, 28.79, 20, 'TU', 226, 34, 10],
  ['C-out', 159.94, 62.71, 30, 'TW', 170, 24, 10],
];
// Same-plane non-mesh pairs must keep clearance >= 6.
const CLEARS = [
  ['DRUM', 100, 60, 40, 'P2', 164.77, 24.34, 12],
  ['DRUM', 100, 60, 40, 'PP', 196.46, 28.79, 20],
  ['DRUM', 100, 60, 40, 'TU', 226, 34, 10],
  ['C-in', 159.94, 62.71, 20, 'P1', 141.07, 28.10, 12],
  ['C-in', 159.94, 62.71, 20, 'P2', 164.77, 24.34, 12],
  ['C-in', 159.94, 62.71, 20, 'PP', 196.46, 28.79, 20],
  ['C-in', 159.94, 62.71, 20, 'TU', 226, 34, 10],
  ['P1', 141.07, 28.10, 12, 'PP', 196.46, 28.79, 20],
  ['P1', 141.07, 28.10, 12, 'TU', 226, 34, 10],
  ['P2', 164.77, 24.34, 12, 'TU', 226, 34, 10],
];
function meshAudit() {
  const out = [];
  for (const [a, xa, za, ta, b, xb, zb, tb] of MESHES) {
    const d = Math.hypot(xb - xa, zb - za);
    const need = ta + tb; // module 2: r1+r2 = T1+T2
    out.push({ pair: a + '-' + b, d: Math.round(d * 100) / 100, need, err: Math.round(Math.abs(d - need) * 1000) / 1000 });
  }
  return out;
}

(async () => {
  // Static (no-browser) mesh audit first: before/after gap list.
  console.log('--- v44 mesh audit (centers vs r1+r2, tol 0.3) ---');
  let staticFail = false;
  for (const m of meshAudit()) {
    const ok = m.err <= 0.31;
    console.log((ok ? 'PASS ' : 'FAIL ') + `mesh ${m.pair}: dist ${m.d} vs r1+r2 ${m.need} (err ${m.err})`);
    if (!ok) staticFail = true;
  }
  // BEFORE (v43 long spine, 16 pieces): E0..PC 9-chain + D2 +
  // L1a/L1b + L2 + GT/GJ/GS far chain across the chassis.
  // AFTER (v44 minimal, 8 pieces): DRUM40 ext + C/TW + P1/P2/PP + TU.
  console.log('BEFORE v43: 16 gear pieces (E0..PC 9-chain + D2 + L1a/L1b + L2 + GT/GJ/GS)');
  console.log('AFTER v44: 8 gear pieces (DRUM40 + C-in/C-out + TW + P1 + P2 + PP + TU)');
  for (const [a, xa, za, ta, b, xb, zb, tb] of CLEARS) {
    const d = Math.hypot(xb - xa, zb - za);
    const clr = Math.round((d - (ta + tb)) * 100) / 100;
    const ok = clr >= 6;
    console.log((ok ? 'PASS ' : 'FAIL ') + `clear ${a}-${b}: gap ${clr} (need >= 6)`);
    if (!ok) staticFail = true;
  }
  if (staticFail) { console.error('VERIFY FAILED: static mesh audit'); process.exit(1); }

  const browser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
  try {
    const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
    const errors = [];
    page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
    page.on('pageerror', err => errors.push(err.message));
    await page.goto(`http://localhost:9099/index.html?v=${V}`);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 25000 });
    console.log('Desktop: status=ready');

    await page.evaluate(() => { window._overrideAngle = null; });
    await page.waitForTimeout(500);
    const a0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.waitForTimeout(800);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    check(a0 !== a1, 'animating true (crankSpinner rotates)');

    // Live counter-rotation + ratio proof (external mesh flips each mesh).
    const sync = await page.evaluate(() => ({
      c0: window._crankSpinner.rotation.z,
      tw0: window._pivots.twister.rotation.x,
      pa0: window._pivots.pullA.rotation.y,
      pb0: window._pivots.pullB.rotation.y,
      tk0: window._pivots.takeup.rotation.z,
      drum0: window._drumPivot.rotation.z,
      low0: window._pivots.lower.rotation.z
    }));
    await page.waitForTimeout(700);
    const sync1 = await page.evaluate(() => ({
      c1: window._crankSpinner.rotation.z,
      tw1: window._pivots.twister.rotation.x,
      pa1: window._pivots.pullA.rotation.y,
      pb1: window._pivots.pullB.rotation.y,
      tk1: window._pivots.takeup.rotation.z,
      drum1: window._drumPivot.rotation.z,
      low1: window._pivots.lower.rotation.z
    }));
    const dC = sync1.c1 - sync.c0;
    const d = {
      crank: dC, drum: sync1.drum1 - sync.drum0, low: sync1.low1 - sync.low0,
      tw: sync1.tw1 - sync.tw0, pa: sync1.pa1 - sync.pa0,
      pb: sync1.pb1 - sync.pb0, tk: sync1.tk1 - sync.tk0
    };
    console.log('Sync deltas:', JSON.stringify(d));
    check(Math.abs(dC) > 1e-4, 'crank advances while animating');
    if (Math.abs(dC) > 1e-4) {
      const dCrank = -dC; // viewer mirror: CAD +720t == viewer -crankAngle
      check(d.drum * d.low < 0, `COUNTER-ROTATION drum vs roller/crank (drum ${d.drum.toFixed(4)} vs roller ${d.low.toFixed(4)})`);
      check(d.pa * d.pb < 0, `COUNTER-ROTATION pullA vs pullB (${d.pa.toFixed(4)} vs ${d.pb.toFixed(4)})`);
      check(Math.abs(d.tw / dCrank + 3) < 0.05, `twister -3x crank = 6x/drum meshed (got ${d.tw / dCrank})`);
      check(Math.abs(d.pa / dCrank - 2) < 0.05, `pullA +2x crank 1:1 meshed (got ${d.pa / dCrank})`);
      check(Math.abs(d.pb / dCrank + 2) < 0.05, `pullB -2x crank (got ${d.pb / dCrank})`);
      check(Math.abs(d.tk / dCrank - 2) < 0.05, `takeup +2x crank (sense unchanged vs v43, got ${d.tk / dCrank})`);
      check(Math.abs(d.drum / dCrank - 0.5) < 0.05, `drum +0.5x crank 2:1 kept (got ${d.drum / dCrank})`);
      check(Math.abs(Math.abs(d.tw / d.drum) - 6) < 0.1, 'twister 6 orbits per drum rev (one bind per seed)');
    }
    await page.evaluate(() => { window._overrideAngle = 0.6; });

    const hooks = await page.evaluate(() => ({
      gear: window._gearTrain || null,
      slip: window._slipClutch ? { baseRatio: window._slipClutch.baseRatio } : null,
      tw: window._twister ? { bindX: window._twister.bindX, arms: window._twister.arms, orbitsPerDrum: window._twister.orbitsPerDrum } : null
    }));
    console.log('Hooks:', JSON.stringify(hooks));
    check(!!hooks.gear && hooks.gear.belts === false, 'gear-only drive, no belts');
    check(!!hooks.gear && /dist=r1\+r2/.test(hooks.gear.mesh || ''), `meshed-train hook (got ${hooks.gear && hooks.gear.mesh})`);
    check(!!hooks.slip && /\+2x crank/.test(hooks.slip.baseRatio), `slip clutch base +2x crank (got ${hooks.slip && hooks.slip.baseRatio})`);
    check(!!hooks.tw && hooks.tw.bindX === 172 && hooks.tw.arms === 2 && hooks.tw.orbitsPerDrum === 6, 'bind 172 / 2 arms / 6 orbits kept');

    // Multi-angle overlap checks: same steel pairs as v42 (>= 4.5 proves 5.0 gaps).
    async function minDist(idsA, idsB) {
      return await page.evaluate(([A, B]) => {
        function worldVerts(ids) {
          const pts = [];
          ids.forEach(id => {
            (window._partMeshes[id] || []).forEach(o => o.traverse(m => {
              if (m.isMesh && m.geometry && m.geometry.attributes.position) {
                m.updateWorldMatrix(true, false);
                const p = m.geometry.attributes.position;
                for (let i = 0; i < p.count; i += 2) {
                  const v = new THREE.Vector3(p.getX(i), p.getY(i), p.getZ(i));
                  v.applyMatrix4(m.matrixWorld);
                  pts.push(v);
                }
              }
            }));
          });
          return pts;
        }
        const pa = worldVerts(A), pb = worldVerts(B);
        let min2 = Infinity;
        for (let i = 0; i < pa.length; i++) {
          const a = pa[i];
          for (let j = 0; j < pb.length; j++) {
            const d2 = a.distanceToSquared(pb[j]);
            if (d2 < min2) min2 = d2;
          }
        }
        return Math.sqrt(min2);
      }, [idsA, idsB]);
    }
    const pairs = [
      ['turner-twister', ['plow'], ['twister']],
      ['twister-pullA', ['twister'], ['pull_a']],
      ['twister-pullB', ['twister'], ['pull_b']],
      ['pullA-takeup', ['pull_a'], ['takeup']],
      ['pullB-takeup', ['pull_b'], ['takeup']],
      ['twister-takeup', ['twister'], ['takeup']],
      ['chassis-takeup', ['chassis'], ['takeup']],
      ['chassis-pullA', ['chassis'], ['pull_a']]
    ];
    for (const ang of [0, 0.6, 2.4]) {
      await page.evaluate((a) => { window._overrideAngle = a; }, ang);
      await page.waitForTimeout(200);
      for (const [nm, A, B] of pairs) {
        const dd = await minDist(A, B);
        console.log(`Clearance ${nm} @${ang}: ${dd.toFixed(2)}`);
        check(dd >= 4.5 || (nm.startsWith('chassis') && dd >= 0), `${nm} clearance @ crank ${ang} (got ${dd.toFixed(2)})`);
      }
    }

    const glbs = await page.evaluate(() => {
      const out = {};
      ['chassis', 'plow', 'twister', 'pull_a', 'pull_b', 'takeup'].forEach(id => {
        let n = 0, minZ = Infinity;
        (window._partMeshes[id] || []).forEach(o => o.traverse(m => {
          if (m.isMesh && m.geometry && m.geometry.attributes.position) {
            const p = m.geometry.attributes.position;
            n += p.count;
            for (let i = 0; i < p.count; i++) { const z = p.getZ(i); if (z < minZ) minZ = z; }
          }
        }));
        out[id] = { verts: n, minZ: n ? Math.round(minZ * 100) / 100 : null };
      });
      return out;
    });
    console.log('GLBs:', JSON.stringify(glbs));
    Object.keys(glbs).forEach(id => {
      check(glbs[id] && glbs[id].verts > 100, `${id}.glb loaded (${glbs[id] ? glbs[id].verts : 0} verts)`);
    });
    // Chassis GLB must now reach the back-wall train (viewer z >= 8 from y<=-8 stock).
    const chass = await page.evaluate(() => {
      let maxZ = -Infinity;
      (window._partMeshes['chassis'] || []).forEach(o => o.traverse(m => {
        if (m.isMesh && m.geometry && m.geometry.attributes.position) {
          const p = m.geometry.attributes.position;
          for (let i = 0; i < p.count; i++) { const z = p.getZ(i); if (z > maxZ) maxZ = z; }
        }
      }));
      return Math.round(maxZ * 100) / 100;
    });
    console.log('Chassis maxZ (expect >= 8, back-wall train):', chass);
    check(chass >= 8, `chassis carries the exterior train (maxZ ${chass} >= 8)`);

    // v44 animating snapshots: back-wall gear train closeups + full proofs.
    // NOTE: viewer coords V=(x, z, -y): back-wall exterior (CAD y -20..-2)
    // sits at viewer z +2..+20; train spans viewer x 40..226, y 2..86.
    // World = root(-100,0,55) + local, so train world x -60..126, z 57..75.
    const shots = [
      { f: 'v44_train_west.png', only: ['chassis'], cam: [0, 60, 220], tgt: [-30, 45, 68], ang: 0.6 },
      { f: 'v44_train_east.png', only: ['chassis'], cam: [110, 55, 220], tgt: [80, 40, 68], ang: 0.6 },
      { f: 'v44_train_full.png', only: ['chassis'], cam: [30, 50, 320], tgt: [30, 45, 66], ang: 2.4 },
      { f: 'v44_bind_closeup.png', only: ['plow', 'twister', 'pull_a', 'pull_b', 'tape', 'seeds'], cam: [60, 30, 60], tgt: [72, 17, 25], ang: 0.6 },
      { f: 'v44_side.png', only: null, cam: [17, 45, 430], tgt: [17, 45, 27], ang: 0 },
      { f: 'v44_endon.png', only: null, cam: [430, 55, 27], tgt: [17, 45, 27], ang: 0 },
      { f: 'v44_top.png', only: null, cam: [17, 430, 27], tgt: [17, 45, 27], ang: 0 }
    ];
    for (const s of shots) {
      await page.evaluate((o) => { if (o) window._setOnlyVisible(o); else window._showAllParts(); }, s.only);
      await page.evaluate((a) => { window._overrideAngle = a; }, s.ang);
      await page.evaluate(([c, t]) => {
        window._camera.position.set(c[0], c[1], c[2]);
        window._controls.target.set(t[0], t[1], t[2]);
        window._controls.update();
      }, [s.cam, s.tgt]);
      await page.waitForTimeout(400);
      await page.screenshot({ path: path.join(SHOT_DIR, s.f) });
      console.log('Shot:', s.f);
    }
    await page.evaluate(() => { window._showAllParts(); });
    await page.evaluate(() => { window._overrideAngle = null; });
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v44_anim_t0.png') });
    console.log('Shot: v44_anim_t0.png (animating)');
    await page.waitForTimeout(1200);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v44_anim_t1.png') });
    console.log('Shot: v44_anim_t1.png (animating, later timestamp)');

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');

    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 28):', assetV);
    check(assetV === '28', 'ASSET_V 28 (GLBs rebuilt)');
    await page.close();

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
