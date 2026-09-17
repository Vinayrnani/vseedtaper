const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v41 verify: 6-turner + gear-only + mounts + slip-clutch build (v39/v40 spec).
// Stations frozen: turner 126..159 -> bind 172 (168..176) -> pull 194
// (183..205 incl. caps) -> take-up 226/34 (210..242); edge gaps 7.65/7/5.
// Checks: animating + gear-only sync (twister -3x crank X, pull +/-2x Y,
// takeup -2x Z, drum +0.5, twister 6/drum rev), _sixTurner/_gearTrain/
// _slipClutch/_mounts hooks, cushioned pull rubber material, take-up h41,
// GLB min_z=0, vertex-level 3D clearance turner/bind/pull/wind (>=4.5),
// tape 270, ASSET_V 25. Shots: screenshots/v41_*.png (max 25, prune oldest).
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
      check(Math.abs((sync1.tw1 - sync.tw0) / dCrank + 3) < 0.05, `twister -3x crank = 6x/drum via idler spur (got ${(sync1.tw1 - sync.tw0) / dCrank})`);
      check(Math.abs((sync1.pa1 - sync.pa0) / dCrank - 2) < 0.05, `pullA +2x crank 1:1 (got ${(sync1.pa1 - sync.pa0) / dCrank})`);
      check(Math.abs((sync1.pb1 - sync.pb0) / dCrank + 2) < 0.05, `pullB -2x crank (got ${(sync1.pb1 - sync.pb0) / dCrank})`);
      check(Math.abs((sync1.tk1 - sync.tk0) / dCrank + 2) < 0.05, `takeup -2x crank step-up (got ${(sync1.tk1 - sync.tk0) / dCrank})`);
      check(Math.abs((sync1.drum1 - sync.drum0) / dCrank - 0.5) < 0.05, `drum +0.5x crank kept (got ${(sync1.drum1 - sync.drum0) / dCrank})`);
      check(Math.abs(Math.abs((sync1.tw1 - sync.tw0) / (sync1.drum1 - sync.drum0)) - 6) < 0.1, 'twister 6 orbits per drum rev (one bind per seed)');
    }
    await page.evaluate(() => { window._overrideAngle = 0.6; });

    // v39/v40 hooks: 6-turner after drop, gear-only, slip clutch, mounts
    const hooks = await page.evaluate(() => ({
      six: window._sixTurner || null,
      gear: window._gearTrain || null,
      slip: window._slipClutch ? { discs: window._slipClutch.discs, behaviour: window._slipClutch.behaviour, baseRatio: window._slipClutch.baseRatio } : null,
      mounts: window._mounts || null,
      tw: window._twister ? { bindX: window._twister.bindX, arms: window._twister.arms, orbitsPerDrum: window._twister.orbitsPerDrum, pullX: window._twister.pullX, takeupX: window._twister.takeupX, nLines: window._twister.lines.length } : null
    }));
    console.log('Hooks:', JSON.stringify(hooks));
    check(!!hooks.six, '_sixTurner hooks present');
    if (hooks.six) {
      check(hooks.six.start === 126 && hooks.six.end === 159, `6-turner 126..159 (got ${hooks.six.start}..${hooks.six.end})`);
      check(hooks.six.dropX === 100 && hooks.six.start - hooks.six.dropX >= 8, `turner a little AFTER drop (mouth-drop=${hooks.six.start - hooks.six.dropX} >= 8, flat landing first)`);
    }
    check(!!hooks.gear && hooks.gear.belts === false, 'gear-only drive, no belts');
    check(!!hooks.slip && hooks.slip.discs === 2 && /slips when full/.test(hooks.slip.behaviour), `slip clutch: 2 discs, fast-empty/slips-full (got ${JSON.stringify(hooks.slip)})`);
    check(!!hooks.mounts && hooks.mounts.bottom.join('+').includes('wind-up') && hooks.mounts.side.includes('drum') && hooks.mounts.top.join('+').includes('spool'), `mounts bottom/side/top (got ${JSON.stringify(hooks.mounts)})`);
    check(!!hooks.tw && hooks.tw.bindX === 172 && hooks.tw.arms === 2 && hooks.tw.orbitsPerDrum === 6 && hooks.tw.pullX === 194 && hooks.tw.takeupX === 226, 'bind 172 / 2 arms / 6 orbits / pull 194 / wind-up 226');

    // Cushioned pull: dark rubber material (not steel)
    const rubber = await page.evaluate(() => {
      const out = {};
      ['pull_a', 'pull_b'].forEach(id => {
        (window._partMeshes[id] || []).forEach(o => o.traverse(m => {
          if (m.isMesh && m.material && m.material.color && !out[id]) {
            out[id] = { color: m.material.color.getHex(), rough: m.material.roughness, metal: m.material.metalness };
          }
        }));
      });
      return out;
    });
    console.log('Pull materials:', JSON.stringify(rubber));
    ['pull_a', 'pull_b'].forEach(id => {
      check(rubber[id] && rubber[id].color === 0x3f434a, `${id} cushioned rubber color (got ${rubber[id] ? rubber[id].color.toString(16) : 'none'})`);
      check(rubber[id] && rubber[id].rough >= 0.8 && rubber[id].metal <= 0.1, `${id} rubber finish (rough=${rubber[id] ? rubber[id].rough : '?'}, metal=${rubber[id] ? rubber[id].metal : '?'})`);
    });

    const piv = await page.evaluate(() => ({
      plx: window._pivots.plow.position.x,
      twx: window._pivots.twister.position.x, twy: window._pivots.twister.position.y,
      pax: window._pivots.pullA.position.x,
      pbx: window._pivots.pullB.position.x,
      tkx: window._pivots.takeup.position.x, tky: window._pivots.takeup.position.y,
      thrPts: window._twister.lines[0].geometry.attributes.position.count
    }));
    console.log('Pivots:', JSON.stringify(piv));
    check(piv.plx === 126, `turner pivot x=126 (got ${piv.plx})`);
    check(piv.twx === 172 && piv.twy === 17, `twister pivot (172,17) (got ${piv.twx},${piv.twy})`);
    check(piv.pax === 194 && piv.pbx === 194, `pull pivots x=194 (got ${piv.pax}/${piv.pbx})`);
    check(piv.tkx === 226 && piv.tky === 34, `takeup pivot (226,34) (got ${piv.tkx},${piv.tky})`);
    check(piv.thrPts === 42, 'thread helix has 42 points');

    // Edge-to-edge steel clearance: min vertex-vertex 3D distance at
    // 3 crank angles (covers twister orbit + all spins). Design X gaps:
    // turner-twister 7.65, twister-pull 7, pull-takeup 5. Threshold 4.5
    // proves the 5.0 design gap (facet sag at $fn=60 is ~0.01).
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
      ['turner-pullA', ['plow'], ['pull_a']],
      ['twister-pullA', ['twister'], ['pull_a']],
      ['twister-pullB', ['twister'], ['pull_b']],
      ['pullA-takeup', ['pull_a'], ['takeup']],
      ['pullB-takeup', ['pull_b'], ['takeup']],
      ['twister-takeup', ['twister'], ['takeup']],
      ['turner-takeup', ['plow'], ['takeup']]
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
      ['plow', 'twister', 'pull_a', 'pull_b', 'takeup', 'chassis'].forEach(id => {
        let n = 0, minZ = Infinity, maxZ = -Infinity;
        (window._partMeshes[id] || []).forEach(o => o.traverse(m => {
          if (m.isMesh && m.geometry && m.geometry.attributes.position) {
            const p = m.geometry.attributes.position;
            n += p.count;
            for (let i = 0; i < p.count; i++) { const z = p.getZ(i); if (z < minZ) minZ = z; if (z > maxZ) maxZ = z; }
          }
        }));
        out[id] = { verts: n, minZ: n ? Math.round(minZ * 100) / 100 : null, maxZ: n ? Math.round(maxZ * 100) / 100 : null };
      });
      return out;
    });
    console.log('GLBs:', JSON.stringify(glbs));
    ['plow', 'twister', 'pull_a', 'pull_b', 'takeup', 'chassis'].forEach(id => {
      check(glbs[id] && glbs[id].verts > 100, `${id}.glb loaded (${glbs[id] ? glbs[id].verts : 0} verts)`);
      if (glbs[id] && glbs[id].verts) check(Math.abs(glbs[id].minZ) < 0.01, `${id} min_z=0 (got ${glbs[id].minZ})`);
    });
    check(glbs.takeup && glbs.takeup.maxZ >= 40.9 && glbs.takeup.maxZ <= 41.1, `take-up h41 with clutch stack (got ${glbs.takeup ? glbs.takeup.maxZ : '?'})`);

    const fold = await page.evaluate(() => ({ laneZ: window._tapeFold.laneZ, tapeLen: window._tapeFold.tapeLen }));
    check(fold.laneZ === 13 && fold.tapeLen === 270, `lane 13 + tape 270 (got ${fold.laneZ}/${fold.tapeLen})`);
    const seal = await page.evaluate(() => window._dropSeal || null);
    check(seal && seal.bore === 7.6 && seal.hoverGap === 10, 'hover seal intact (ID7.6, gap 10)');

    // Multi-angle animating snapshots (no-overlap proof from every side).
    // NOTE: world coords = root(-100,0,55) + root-local; machine spans
    // world x -114..148 (centre 17), y 0..110 (centre 45), z -5..63.
    const shots = [
      { f: 'v41_turner_closeup.png', only: ['plow', 'twister', 'tape', 'seeds'], cam: [0, 30, 100], tgt: [42, 14, 45], ang: 0.6 },
      { f: 'v41_bind_closeup.png', only: ['plow', 'twister', 'pull_a', 'pull_b', 'tape', 'seeds'], cam: [60, 30, 60], tgt: [72, 17, 25], ang: 0.6 },
      { f: 'v41_pull_wind.png', only: ['pull_a', 'pull_b', 'takeup', 'twister', 'tape', 'seeds'], cam: [40, 70, 110], tgt: [105, 22, 25], ang: 2.4 },
      { f: 'v41_side.png', only: null, cam: [17, 45, 430], tgt: [17, 45, 27], ang: 0 },
      { f: 'v41_endon.png', only: null, cam: [430, 55, 27], tgt: [17, 45, 27], ang: 0 },
      { f: 'v41_top.png', only: null, cam: [17, 430, 27], tgt: [17, 45, 27], ang: 0 }
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
    await page.evaluate(() => {
      window._camera.position.set(300, 220, 300);
      window._controls.target.set(-20, 55, 40);
      window._controls.update();
    });
    await page.evaluate(() => { window._overrideAngle = null; });
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v41_anim_t0.png') });
    console.log('Shot: v41_anim_t0.png (animating)');
    await page.waitForTimeout(1200);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v41_anim_t1.png') });
    console.log('Shot: v41_anim_t1.png (animating, later timestamp)');

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
    console.log('ASSET_V (expect 25):', assetV);
    check(assetV === '25', 'ASSET_V 25 (GLBs rebuilt)');
    await page.close();

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
