const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');
const SHOT_DIR = path.join(__dirname, 'screenshots');
fs.mkdirSync(SHOT_DIR, { recursive: true });
(function prune() {
  const files = fs.readdirSync(SHOT_DIR).filter(f => f.endsWith('.png'))
    .map(f => ({ f, m: fs.statSync(path.join(SHOT_DIR, f)).mtimeMs })).sort((a, b) => a.m - b.m);
  while (files.length > 20) {
    const o = files.shift();
    fs.unlinkSync(path.join(SHOT_DIR, o.f));
    console.log('Pruned:', o.f);
  }
})();
const V = Date.now();
const failures = [];
function check(cond, msg) {
  console.log((cond ? 'PASS ' : 'FAIL ') + msg);
  if (!cond) failures.push(msg);
}
function dist(a, b) { return Math.hypot(a[0]-b[0], a[1]-b[1], a[2]-b[2]); }
(async () => {
  const bp = await pool.newPage({ width: 1600, height: 1000 });
  const browser = bp.browser, page = bp.page;
  try {
    const errors = [];
    page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
    page.on('pageerror', err => errors.push(err.message));
    await page.goto('http://localhost:9099/index.html?v=' + V);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 30000 });
    console.log('status=ready');
    await page.evaluate(() => { window._overrideAngle = null; window._showAllParts(); });
    await page.waitForTimeout(400);
    const a0 = await page.evaluate(() => window._crankSpinner.rotation.z);
    await page.waitForTimeout(700);
    const a1 = await page.evaluate(() => window._crankSpinner.rotation.z);
    check(a0 !== a1, 'animating (crankSpinner rotates)');
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V:', assetV);
    check(assetV === '59', 'ASSET_V=59 (got ' + assetV + ')');
    const geo = await page.evaluate(() => {
      function rl(v) { return [+(v.x + 100).toFixed(1), +(55 - v.z).toFixed(1), +v.y.toFixed(1)]; }
      window._root.updateMatrixWorld(true);
      const out = {};
      ['cartridge', 'intermediate_compound', 'drive_shaft', 'twister', 'chassis'].forEach(id => {
        const bb = new THREE.Box3();
        const arr = window._partMeshes[id] || [];
        let n = 0;
        arr.forEach(s => s.traverse(o => { if (o.isMesh) { n++; bb.expandByObject(o); } }));
        const c = bb.getCenter(new THREE.Vector3());
        const sz = bb.getSize(new THREE.Vector3());
        out[id] = { meshes: n, rootC: rl(c), worldSize: [+sz.x.toFixed(1), +sz.y.toFixed(1), +sz.z.toFixed(1)] };
      });
      ['drum', 'compound', 'shaft', 'twister'].forEach(k => {
        const p = new THREE.Vector3(); window._pivots[k].getWorldPosition(p);
        out['piv_' + k] = rl(p);
      });
      return out;
    });
    console.log('GEO ' + JSON.stringify(geo, null, 1));
    const compMax = Math.max(...geo.intermediate_compound.worldSize);
    console.log('compound maxDim=' + compMax.toFixed(1) + ' (want ~80 for 38T M2; stale 50T would be ~104)');
    check(compMax < 92, 'compound OD ~80mm not 106mm (maxDim ' + compMax.toFixed(1) + ')');
    check(compMax > 60, 'compound not tiny/missing (maxDim ' + compMax.toFixed(1) + ')');
    const dPivC = dist(geo.piv_compound, geo.intermediate_compound.rootC);
    const dPivS = dist(geo.piv_shaft, geo.drive_shaft.rootC);
    console.log('pivC-off=' + dPivC.toFixed(1) + ' pivS-off=' + dPivS.toFixed(1));
    check(dPivC < 15, 'compound pivot = gear centre (off ' + dPivC.toFixed(1) + 'mm)');
    check(dPivS < 20, 'shaft pivot = shaft centre (off ' + dPivS.toFixed(1) + 'mm)');
    const DRUM_GEAR_PT = [100, 60, -12];
    const dDC = dist(DRUM_GEAR_PT, geo.intermediate_compound.rootC);
    console.log('dDrumGear-Comp=' + dDC.toFixed(2) + ' (want 56.08)');
    check(Math.abs(dDC - 56.08) < 8, 'drum44->compound12 mesh dist (got ' + dDC.toFixed(1) + ')');
    async function pivRots(ang) {
      await page.evaluate(a => { window._overrideAngle = a; }, ang);
      await page.waitForTimeout(350);
      return await page.evaluate(() => ({
        drum: window._pivots.drum.rotation.z, comp: window._pivots.compound.rotation.z,
        shaft: window._pivots.shaft.rotation.z, ring: window._pivots.twister.rotation.x }));
    }
    const r0 = await pivRots(0), r1 = await pivRots(Math.PI);
    const dD = r1.drum - r0.drum, dC2 = r1.comp - r0.comp;
    const dS = r1.shaft - r0.shaft, dR = r1.ring - r0.ring;
    console.log('DELTAS dDrum=' + dD.toFixed(4) + ' dComp=' + dC2.toFixed(4) + ' dShaft=' + dS.toFixed(4) + ' dRing=' + dR.toFixed(4));
    function close(got, want, tag) {
      const ok = Math.abs(Math.abs(got) - Math.abs(want)) / Math.abs(want) < 0.03;
      check(ok, tag + ' |' + Math.abs(got).toFixed(3) + '| vs |' + Math.abs(want).toFixed(3) + '|');
    }
    close(dD, Math.PI * 16 / 44, 'drum rolls at 16/44');
    close(dC2, (16 / 12) * Math.PI, 'compound rolls at 16/12');
    close(dS, (16 / 12) * (38 / 12) * Math.PI, 'shaft rolls at 16/12*38/12');
    close(dR, (16 / 44) * (418 / 27) * Math.PI, 'ring rolls');
    check(dC2 * dD < 0, 'compound counter-rotates vs drum');
    check(dS * dC2 < 0, 'shaft counter-rotates vs compound');
    check(Math.abs(dC2) > 0.5 && Math.abs(dS) > 0.5, 'compound AND shaft move (not frozen)');
    const D = DRUM_GEAR_PT, C = geo.intermediate_compound.rootC;
    const S = geo.drive_shaft.rootC, R = geo.piv_twister;
    function ang3(a, b, c) {
      const v1 = [a[0]-b[0], a[1]-b[1], a[2]-b[2]], v2 = [c[0]-b[0], c[1]-b[1], c[2]-b[2]];
      const dot = v1[0]*v2[0] + v1[1]*v2[1] + v1[2]*v2[2];
      return Math.acos(Math.max(-1, Math.min(1, dot / (Math.hypot(...v1) * Math.hypot(...v2))))) * 180 / Math.PI;
    }
    const kC = ang3(D, C, S), kS = ang3(C, S, R);
    console.log('kinkAtC=' + kC.toFixed(1) + ' kinkAtS=' + kS.toFixed(1) + ' dCS=' + dist(C, S).toFixed(1) + ' (want dCS ~50 for 38+12 M2)');
    check(kC > 160, 'chain straight at compound (>160deg, got ' + kC.toFixed(1) + ')');
    const cY = C[2], sY = S[2], dY = D[2];
    console.log('planeZ drum=' + dY.toFixed(1) + ' comp=' + cY.toFixed(1) + ' shaft=' + sY.toFixed(1));
    await page.evaluate(() => window._setPanelCollapsed(true));
    const WP = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      function centre(id) {
        const bb = new THREE.Box3();
        (window._partMeshes[id] || []).forEach(s => s.traverse(o => { if (o.isMesh) bb.expandByObject(o); }));
        const c = bb.getCenter(new THREE.Vector3()); return [c.x, c.y, c.z];
      }
      const dp = new THREE.Vector3(); window._pivots.drum.getWorldPosition(dp);
      return { drum: [dp.x, dp.y, dp.z], comp: centre('intermediate_compound'),
        shaft: centre('drive_shaft'), twist: centre('twister'), ch: centre('chassis') };
    });
    console.log('WORLDC ' + JSON.stringify(WP));
    async function shot(f, cam, tgt, only, ang) {
      await page.evaluate(o => { if (o) window._setOnlyVisible(o); else window._showAllParts(); }, only || null);
      if (ang === null || ang === undefined) await page.evaluate(() => { window._overrideAngle = null; });
      else await page.evaluate(a => { window._overrideAngle = a; }, ang);
      await page.evaluate(ct => {
        window._camera.position.set(ct[0][0], ct[0][1], ct[0][2]);
        window._controls.target.set(ct[1][0], ct[1][1], ct[1][2]);
        window._controls.update();
      }, [cam, tgt]);
      await page.waitForTimeout(450);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      console.log('Shot: ' + f);
    }
    const DD = WP.drum, CC = WP.comp, SS = WP.shaft, TT = WP.twist, CH = WP.ch;
    const mid3 = [(CC[0]+SS[0]+TT[0])/3, (CC[1]+SS[1]+TT[1])/3, (CC[2]+SS[2]+TT[2])/3];
    const midDC = [(DD[0]+CC[0])/2, (DD[1]+CC[1])/2, (DD[2]+CC[2])/2];
    const midCS = [(CC[0]+SS[0])/2, (CC[1]+SS[1])/2, (CC[2]+SS[2])/2];
    const midST = [(SS[0]+TT[0])/2, (SS[1]+TT[1])/2, (SS[2]+TT[2])/2];
    const NAKED = ['cartridge', 'intermediate_compound', 'drive_shaft', 'twister'];
    await shot('f01_top_down.png', [CH[0], CH[1]+520, CH[2]+5], CH, null, null);
    await shot('f02_crank_side.png', [CH[0]-330, CH[1]+180, CH[2]+330], CH, null, null);
    await shot('f03_east_end.png', [TT[0]+260, TT[1]+40, TT[2]+20], midST, null, null);
    await shot('f04_side_heights.png', [mid3[0]+420, mid3[1]+30, mid3[2]+40], mid3, NAKED, 0.6);
    await shot('f05_naked_a.png', [mid3[0]+60, mid3[1]-90, mid3[2]+200], mid3, NAKED, 0.6);
    await shot('f06_naked_b.png', [mid3[0]-140, mid3[1]+120, mid3[2]+170], mid3, NAKED, 0.6);
    await shot('f07_compound_close.png', [CC[0]+50, CC[1]-55, CC[2]+95], CC, ['intermediate_compound'], 0.6);
    await shot('f08_drum_compound_mesh.png', [midDC[0]+30, midDC[1]-40, midDC[2]+150], midDC, ['cartridge','intermediate_compound'], 0.6);
    await shot('f09_compound_shaft_mesh.png', [midCS[0]+40, midCS[1]-50, midCS[2]+130], midCS, ['intermediate_compound','drive_shaft'], 0.6);
    await shot('f10_shaft_ring_mesh.png', [midST[0]+60, midST[1]-30, midST[2]+110], midST, ['drive_shaft','twister'], 0.6);
    await shot('f11_chain_t0.png', [mid3[0]+60, mid3[1]-90, mid3[2]+200], mid3, NAKED, 0);
    await shot('f12_chain_t1.png', [mid3[0]+60, mid3[1]-90, mid3[2]+200], mid3, NAKED, Math.PI);
    await shot('f13_ring_west.png', [TT[0]+95, TT[1]+18, TT[2]+35], TT, ['twister'], 0.6);
    await shot('f14_ring_rim2.png', [TT[0]-90, TT[1]-30, TT[2]+70], TT, ['twister'], 2.2);
    await shot('f15_compound_side.png', [CC[0]+160, CC[1]+10, CC[2]+10], CC, ['intermediate_compound'], 0.6);
    await shot('f16_beauty.png', [CH[0]-330, CH[1]+220, CH[2]+380], CH, null, null);
    console.log('errors: ' + errors.length);
    errors.forEach(e => console.log('   ' + e));
    check(errors.length === 0, '0 console errors');
    await page.close();
    if (failures.length) { console.error('REVIEW FAILED (' + failures.length + '):'); failures.forEach(f => console.error(' - ' + f)); process.exitCode = 1; }
    else console.log('REVIEW PASSED');
  } finally {
    await pool.releaseBrowser(browser);
  }
})();
