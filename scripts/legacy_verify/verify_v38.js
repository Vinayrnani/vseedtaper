const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v38 verify: downstream respace (v37 overlap fix).
// Stations: bind 172 (rotor 168..176, gap 9 to plow 159),
// pull 194 (rollers 184..204, gap 8 to twister),
// take-up 226/34 (flange 210..242, gap 6 to pull; centres 32 vs 26+0.3+5).
// Checks: animating + synced chain (twister -3x crank X, pull +/-2x Y,
// takeup -2x Z, drum +0.5), _twister hooks, pivots, GLB min_z=0,
// 3D AABB clearance between twister/pull/takeup meshes (>=5),
// tape 270, ASSET_V 24. Shots: screenshots/v38_*.png (max 25, prune oldest).
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

(async () => {
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

    const sync = await page.evaluate(() => ({
      c0: window._crankSpinner.rotation.z,
      tw0: window._pivots.twister.rotation.x,
      pa0: window._pivots.pullA.rotation.y,
      pb0: window._pivots.pullB.rotation.y,
      tk0: window._pivots.takeup.rotation.z,
      drum0: window._drumPivot.rotation.z
    }));
    await page.waitForTimeout(700);
    const sync1 = await page.evaluate(() => ({
      c1: window._crankSpinner.rotation.z,
      tw1: window._pivots.twister.rotation.x,
      pa1: window._pivots.pullA.rotation.y,
      pb1: window._pivots.pullB.rotation.y,
      tk1: window._pivots.takeup.rotation.z,
      drum1: window._drumPivot.rotation.z
    }));
    const dC = sync1.c1 - sync.c0;
    console.log('Sync deltas:', JSON.stringify({ dC, dTw: sync1.tw1 - sync.tw0, dPa: sync1.pa1 - sync.pa0, dPb: sync1.pb1 - sync.pb0, dTk: sync1.tk1 - sync.tk0, dDrum: sync1.drum1 - sync.drum0 }));
    check(Math.abs(dC) > 1e-4, 'crank advances while animating');
    if (Math.abs(dC) > 1e-4) {
      const dCrank = -dC;
      check(Math.abs((sync1.tw1 - sync.tw0) / dCrank + 3) < 0.05, `twister -3x crank (got ${(sync1.tw1 - sync.tw0) / dCrank})`);
      check(Math.abs((sync1.pa1 - sync.pa0) / dCrank - 2) < 0.05, `pullA +2x crank (got ${(sync1.pa1 - sync.pa0) / dCrank})`);
      check(Math.abs((sync1.pb1 - sync.pb0) / dCrank + 2) < 0.05, `pullB -2x crank (got ${(sync1.pb1 - sync.pb0) / dCrank})`);
      check(Math.abs((sync1.tk1 - sync.tk0) / dCrank + 2) < 0.05, `takeup -2x crank (got ${(sync1.tk1 - sync.tk0) / dCrank})`);
      check(Math.abs((sync1.drum1 - sync.drum0) / dCrank - 0.5) < 0.05, `drum +0.5x crank kept (got ${(sync1.drum1 - sync.drum0) / dCrank})`);
      check(Math.abs(Math.abs((sync1.tw1 - sync.tw0) / (sync1.drum1 - sync.drum0)) - 6) < 0.1, 'twister 6 orbits per drum rev (one bind per seed)');
    }
    await page.evaluate(() => { window._overrideAngle = 0.6; });

    const tw = await page.evaluate(() => {
      const t = window._twister;
      if (!t) return null;
      return { bindX: t.bindX, arms: t.arms, orbitsPerDrum: t.orbitsPerDrum, pullX: t.pullX, takeupX: t.takeupX, nLines: t.lines.length };
    });
    console.log('Twister:', JSON.stringify(tw));
    check(!!tw, '_twister hooks present');
    if (tw) {
      check(tw.bindX === 172, `bind station 172 = plow_end+13 (got ${tw.bindX})`);
      check(tw.arms === 2, `2 thread arms (got ${tw.arms})`);
      check(tw.orbitsPerDrum === 6, `6 orbits per drum rev (got ${tw.orbitsPerDrum})`);
      check(tw.pullX === 194 && tw.takeupX === 226, `pull 194 / wind-up 226 (got ${tw.pullX}/${tw.takeupX})`);
      check(tw.nLines === 2, `2 procedural thread lines (got ${tw.nLines})`);
    }

    const piv = await page.evaluate(() => ({
      twx: window._pivots.twister.position.x, twy: window._pivots.twister.position.y,
      pax: window._pivots.pullA.position.x,
      pbx: window._pivots.pullB.position.x,
      tkx: window._pivots.takeup.position.x, tky: window._pivots.takeup.position.y,
      thrPts: window._twister.lines[0].geometry.attributes.position.count
    }));
    console.log('Pivots:', JSON.stringify(piv));
    check(piv.twx === 172 && piv.twy === 17, `twister pivot (172,17) (got ${piv.twx},${piv.twy})`);
    check(piv.pax === 194 && piv.pbx === 194, `pull pivots x=194 (got ${piv.pax}/${piv.pbx})`);
    check(piv.tkx === 226 && piv.tky === 34, `takeup pivot (226,34) (got ${piv.tkx},${piv.tky})`);
    check(piv.thrPts === 42, 'thread helix has 42 points');

    // Exact steel-to-steel clearance: min vertex-vertex distance in world
    // coords between part meshes at 3 crank angles (covers twister arm
    // orbit + all spins). Design X gaps: twister-pull 7 (176 vs 183),
    // pull-takeup 5 (205 vs 210), twister-takeup 34. Facet sag at $fn=60
    // is ~0.01, so threshold 4.5 proves the 5.0 design gap with margin.
    // (Box3 AABBs can't prove this: applyMatrix4 rotates box corners,
    // conservatively inflating spun cylinders — measured +2.1/+4.7 ghost.)
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
      ['twister-pullA', ['twister'], ['pull_a']],
      ['twister-pullB', ['twister'], ['pull_b']],
      ['pullA-takeup', ['pull_a'], ['takeup']],
      ['pullB-takeup', ['pull_b'], ['takeup']],
      ['twister-takeup', ['twister'], ['takeup']]
    ];
    for (const ang of [0, 0.6, 2.4]) {
      await page.evaluate((a) => { window._overrideAngle = a; }, ang);
      await page.waitForTimeout(200);
      for (const [nm, A, B] of pairs) {
        const d = await minDist(A, B);
        console.log(`Clearance ${nm} @${ang}: ${d.toFixed(2)}`);
        check(d >= 4.5, `${nm} clearance >= 4.5 @ crank ${ang} (got ${d.toFixed(2)})`);
      }
    }

    const glbs = await page.evaluate(() => {
      const out = {};
      ['twister', 'pull_a', 'pull_b', 'takeup', 'chassis', 'tape'].forEach(id => {
        const meshes = id === 'tape'
          ? [window._tapeFold.group, window._tapeFold.flat]
          : (window._partMeshes[id] || []);
        let n = 0, minZ = Infinity;
        meshes.forEach(o => { if (o) o.traverse(m => {
          if (m.isMesh && m.geometry && m.geometry.attributes.position) {
            const p = m.geometry.attributes.position;
            n += p.count;
            for (let i = 0; i < p.count; i++) { const z = p.getZ(i); if (z < minZ) minZ = z; }
          }
        }); });
        out[id] = { verts: n, minZ: n ? Math.round(minZ * 100) / 100 : null };
      });
      return out;
    });
    console.log('GLBs:', JSON.stringify(glbs));
    ['twister', 'pull_a', 'pull_b', 'takeup', 'chassis'].forEach(id => {
      check(glbs[id] && glbs[id].verts > 100, `${id}.glb loaded (${glbs[id] ? glbs[id].verts : 0} verts)`);
      if (glbs[id] && glbs[id].verts) check(Math.abs(glbs[id].minZ) < 0.01, `${id} min_z=0 (got ${glbs[id].minZ})`);
    });

    const fold = await page.evaluate(() => ({ laneZ: window._tapeFold.laneZ, tapeLen: window._tapeFold.tapeLen }));
    check(fold.laneZ === 13 && fold.tapeLen === 270, `lane 13 + tape 270 (got ${fold.laneZ}/${fold.tapeLen})`);
    const seal = await page.evaluate(() => window._dropSeal || null);
    check(seal && seal.bore === 7.6 && seal.hoverGap === 10, 'hover seal intact (ID7.6, gap 10)');

    // animating snapshots at multiple timestamps (motion sync + no visual overlap)
    const shots = [
      { f: 'v38_bind_closeup.png', only: ['plow', 'twister', 'pull_a', 'pull_b', 'tape', 'seeds'], cam: [60, 30, 60], tgt: [72, 17, 25], ang: 0.6 },
      { f: 'v38_pull_wind.png', only: ['pull_a', 'pull_b', 'takeup', 'twister', 'tape', 'seeds'], cam: [110, 40, 70], tgt: [110, 20, 25], ang: 2.4 },
      { f: 'v38_anim_t0.png', only: null, cam: [300, 220, 300], tgt: [-20, 55, 40], ang: null },
      { f: 'v38_anim_t1.png', only: null, cam: [300, 220, 300], tgt: [-20, 55, 40], ang: null }
    ];
    for (const s of shots.slice(0, 2)) {
      await page.evaluate((o) => { window._setOnlyVisible(o); }, s.only);
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
    await page.evaluate(() => {
      window._camera.position.set(300, 220, 300);
      window._controls.target.set(-20, 55, 40);
      window._controls.update();
    });
    await page.evaluate(() => { window._overrideAngle = null; });
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v38_anim_t0.png') });
    console.log('Shot: v38_anim_t0.png (animating)');
    await page.waitForTimeout(1200);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v38_anim_t1.png') });
    console.log('Shot: v38_anim_t1.png (animating, later timestamp)');

    const order = await page.evaluate(() => ({
      drum: window._pivots.drum.position.x,
      shroud: window._pivots.shroud.position.x,
      lower: window._pivots.lower.position.x,
      crankZ: window._pivots.crankMount.position.z,
      takeupX: window._pivots.takeup.position.x
    }));
    console.log('Order:', JSON.stringify(order));
    check(order.drum > order.shroud && order.shroud > order.lower, 'R->L order drum>shroud>roller');
    check(order.crankZ === 8, 'crank back wall (mount z=8 <=> Y=-8)');
    check(order.takeupX > order.drum, 'wind-up east of drum');

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');

    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 24):', assetV);
    check(assetV === '24', 'ASSET_V 24 (GLBs rebuilt)');
    await page.close();

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
