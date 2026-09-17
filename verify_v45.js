const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v45 verify: FORENSIC tape-path fix (user: model still incorrect at all angles).
// D1: viewer tape scroll (100+mod(advance,62.83)) slid the ribbon +/-63mm per
//   rev: uncovered spool/nip/forming at high phase, dangled ~50 past the
//   chassis east end (f_iso_t3 proof). FIX: static ribbon at the CAD span
//   (-14..208, centre 99... now -14..208 centre 97, TAPE_LEN 222).
// D2: flat ribbon ran UNDER the bare reel core (~13 gap) to 256, past the
//   reel/chassis with no wind-up engagement (f_endon_east/f_takeup proof).
//   FIX: CAD seed_tape_bend() flat ends 208 + narrow leader strip 206..224.5
//   climbing ribbon-top -> wound pack (fused, fail-loud asserts); viewer
//   mirrors it 1:1 (+ _windLeader hooks). Ratios/signs/gears/stations/gaps,
//   6-turner, mounts untouched. ASSET_V 28->29, all GLBs rebuilt --force.
// Live proof: animating + ratios + STATIC tape (pos.x equal across timestamps)
// + leader-into-pack math + clearances + multi-angle overlap + 0 errors.
// Shots: screenshots/v45_*.png (max 25, prune oldest).
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

// v44 mesh table mirror (unchanged in v45 — gears/stations untouched).
const MESHES = [
  ['crank', 40, 60, 20, 'drum', 100, 60, 40],
  ['DRUM', 100, 60, 40, 'C-in', 159.94, 62.71, 20],
  ['DRUM', 100, 60, 40, 'P1', 141.07, 28.10, 12],
  ['P1', 141.07, 28.10, 12, 'P2', 164.77, 24.34, 12],
  ['P2', 164.77, 24.34, 12, 'PP', 196.46, 28.79, 20],
  ['PP', 196.46, 28.79, 20, 'TU', 226, 34, 10],
  ['C-out', 159.94, 62.71, 30, 'TW', 170, 24, 10],
];

(async () => {
  console.log('--- v45 static mesh audit (unchanged train, tol 0.3) ---');
  let staticFail = false;
  for (const [a, xa, za, ta, b, xb, zb, tb] of MESHES) {
    const d = Math.hypot(xb - xa, zb - za);
    const err = Math.abs(d - (ta + tb));
    const ok = err <= 0.31;
    console.log((ok ? 'PASS ' : 'FAIL ') + `mesh ${a}-${b}: dist ${Math.round(d * 100) / 100} vs r1+r2 ${ta + tb} (err ${Math.round(err * 1000) / 1000})`);
    if (!ok) staticFail = true;
  }
  // v45 leader-into-pack math mirror (CAD coords).
  const leadEndD = Math.hypot(224.5 - 226, 26.5 - 34);
  console.log(`leader end dist to pack centre: ${Math.round(leadEndD * 100) / 100} (pack r8)`);
  if (leadEndD > 8) { console.log('FAIL leader-into-pack'); staticFail = true; }
  else console.log('PASS leader end fuses inside pack (dist <= 8)');
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

    // D1 REGRESSION: tape ribbon must be STATIC while animating.
    const tx0 = await page.evaluate(() => window._tapeFold.flat.position.x);
    const adv0 = await page.evaluate(() => parseFloat(document.getElementById('stTape').textContent));
    await page.waitForTimeout(1500);
    const tx1 = await page.evaluate(() => window._tapeFold.flat.position.x);
    const adv1 = await page.evaluate(() => parseFloat(document.getElementById('stTape').textContent));
    console.log(`tapeGroup.x t0=${tx0} t1=${tx1} (advance ${adv0} -> ${adv1} mm)`);
    check(tx0 === tx1, `D1 tape ribbon STATIC while animating (x ${tx0} == ${tx1}, advance kept counting ${adv0}->${adv1})`);
    check(tx0 === 97, `D1 ribbon centred on CAD span (x 97 = -14+222/2, got ${tx0})`);

    // D2: leader hooks + placement.
    const lead = await page.evaluate(() => ({
      x0: window._windLeader.x0, x1: window._windLeader.x1, z1: window._windLeader.z1,
      px: window._windLeader.mesh.position.x, py: window._windLeader.mesh.position.y,
      rot: window._windLeader.mesh.rotation.z
    }));
    console.log('Leader:', JSON.stringify(lead));
    check(lead.x0 === 206 && lead.x1 === 224.5 && lead.z1 === 26.5, 'D2 leader endpoints 206..224.5 z 26.5 (CAD match)');
    check(Math.abs(lead.px - 215.35) < 0.3 && Math.abs(lead.py - 20.1) < 0.3, `D2 leader mesh centred on the climb (got ${lead.px}, ${lead.py})`);

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

    // Edge-to-edge clearances. NOTE: vertex sampling must be DENSE on thin
    // features (dead-axle shafts r4, 0.3 slip gaps): stride-3 sampling
    // misses them entirely (false 6+ readings). Mounts use stride 1 on
    // the small part / 12 on the chassis; the nip is band-limited to the
    // lane height (world y 12..22) where the pocket actually runs.
    async function minDist(A, B, o) {
      o = o || {};
      return await page.evaluate((q) => {
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
        let min2 = Infinity;
        for (let i = 0; i < pa.length; i++) for (let j = 0; j < pb.length; j++) {
          const d2 = pa[i].distanceToSquared(pb[j]);
          if (d2 < min2) min2 = d2;
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
    // Functional nip at lane height (world y 12..22): sleeve faces pinch
    // 8.1 over the 7.8 pocket, shallow ribs touch ~7.5 = soft grip.
    {
      const r = await minDist(['pull_a'], ['pull_b'], { yMin: 12, yMax: 22 });
      console.log(`Nip at lane height: ${r.d} (need >= 7.0, n=${r.na}x${r.nb})`);
      check(r.d >= 7.0, `pull nip grips without crushing (got ${r.d})`);
    }
    // Mounts D3: dead-axle shafts live INSIDE chassis.glb (raw OpenSCAD
    // coords, z-up local). Bulk part-to-chassis vertex distance is the
    // WRONG probe for shaft-mounted rotors (the shaft bridges the gap —
    // drum/takeup/spool read 6..11 bulk yet seat on steel). Direct probe:
    // chassis steel within slip-fit of each shaft axis, at BOTH ends
    // (proves full-span shafts, not stubs). CAD asserts already tie bores
    // to the same axis constants.
    async function shaftSeat(ax, z, y0, y1, r) {
      return await page.evaluate((o) => {
        let back = Infinity, front = Infinity;
        const ym = (o.y0 + o.y1) / 2;
        (window._partMeshes['chassis'] || []).forEach(g => g.traverse(m => {
          if (m.isMesh && m.geometry && m.geometry.attributes.position) {
            const p = m.geometry.attributes.position;
            for (let i = 0; i < p.count; i += 3) {
              const y = p.getY(i);
              if (y < o.y0 - 1 || y > o.y1 + 1) continue;
              const dx = p.getX(i) - o.ax, dz = p.getZ(i) - o.z;
              const d = Math.sqrt(dx * dx + dz * dz) - o.r;
              if (y < ym) { if (d < back) back = d; } else { if (d < front) front = d; }
            }
          }
        }));
        const r2 = (v) => Math.round(v * 100) / 100;
        return { back: r2(back), front: r2(front) };
      }, { ax, z, y0, y1, r });
    }
    for (const [nm, ax, z, y0, y1, r] of [
      ['drum hex shaft x=100 z=60', 100, 60, -10, 59, 4.62],
      ['takeup shaft x=226 z=34', 226, 34, -10, 59, 4],
      ['spool shaft x=-6 z=65', -6, 65, 1, 59, 4],
    ]) {
      const s = await shaftSeat(ax, z, y0, y1, r);
      console.log(`Shaft ${nm}: back gap ${s.back}, front gap ${s.front} (expect < 2 seated)`);
      check(s.back < 2 && s.front < 2, `${nm} full-span dead axle in chassis (got ${s.back}/${s.front})`);
    }
    for (const [nm, A] of [['turner-chassis', ['plow']], ['pull-chassis', ['pull_a']]]) {
      const r = await minDist(A, ['chassis'], { sA: 1, sB: 12 });
      // pull stands on the base + cups meet the bridge (true 0, CAD-asserted);
      // 2.5 absorbs vertex-sampling sparsity on the huge chassis mesh.
      const need = nm.startsWith('pull') ? 2.5 : 1.5;
      console.log(`Mount ${nm}: ${r.d} (expect < ${need} seated, n=${r.na}x${r.nb})`);
      check(r.d < need, `${nm} seated on dead axle/mount (got ${r.d})`);
    }
    {
      const r = await minDist(['twister'], ['chassis']);
      console.log(`Cradle twister-chassis: ${r.d} (expect 1.5..4 rolling gap)`);
      check(r.d >= 1.5 && r.d <= 4.0, `twister cradled, no touch/no float (got ${r.d})`);
    }

    // Tape span: flat -14..208 + leader to ~225 (world = root-local - 100).
    const tape = await page.evaluate(() => {
      const box = new THREE.Box3();
      [window._tapeFold.group, window._tapeFold.flat, window._windLeader.mesh].forEach(gr => gr.traverse
        ? gr.traverse(m => {
          if (m.isMesh && m.geometry.attributes.position) {
            m.updateWorldMatrix(true, false);
            const gb = new THREE.Box3().setFromBufferAttribute(m.geometry.attributes.position);
            gb.applyMatrix4(m.matrixWorld);
            box.union(gb);
          }
        })
        : null);
      return { min: Math.round(box.min.x * 10) / 10, max: Math.round(box.max.x * 10) / 10 };
    });
    console.log('TAPE span (world x):', JSON.stringify(tape));
    check(tape.min <= -113 && tape.min >= -116, `D1 ribbon west end at spool (got ${tape.min}, expect ~-114)`);
    check(tape.max <= 130 && tape.max >= 120, `D2 tape ends at the pack, NOT past chassis (got ${tape.max}, expect ~125)`);

    // Shots: wind-up + tape path proof, animating timestamps.
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
    await shot('v45_iso.png', [185, 175, 235], [20, 35, 25], null, null);
    await shot('v45_side_train.png', [20, 45, 430], [20, 40, 27], null, null);
    await shot('v45_endon_east.png', [300, 45, 25], [20, 25, 25], null, 0.6);
    await shot('v45_windup.png', [162, 100, 70], [115, 22, 25], ['takeup', 'tape', 'chassis'], 0.6);
    await shot('v45_tapepath.png', [20, 120, 120], [20, 15, 25], null, 0.6);
    await shot('v45_top.png', [20, 460, 27], [20, 0, 25], null, null);
    await page.evaluate(() => { window._showAllParts(); window._overrideAngle = null; });
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v45_anim_t0.png') });
    console.log('Shot: v45_anim_t0.png (animating)');
    await page.waitForTimeout(2500);
    await page.screenshot({ path: path.join(SHOT_DIR, 'v45_anim_t1.png') });
    console.log('Shot: v45_anim_t1.png (animating, +2.5s: ribbon must not have slid)');

    console.log('Desktop errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
    check(errors.length === 0, 'desktop 0 console errors');
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V (expect 29):', assetV);
    check(assetV === '29', 'ASSET_V 29 (GLBs rebuilt)');
    await page.close();

    pruneShots();
    if (fail) { console.error('VERIFY FAILED:', fail); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('VERIFY FAILED:', e); process.exit(1); });
