const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');
const SHOT_DIR = path.join(__dirname, 'screenshots');
fs.mkdirSync(SHOT_DIR, { recursive: true });
(function prune() {
  const files = fs.readdirSync(SHOT_DIR).filter(f => f.endsWith('.png'))
    .map(f => ({ f, m: fs.statSync(path.join(SHOT_DIR, f)).mtimeMs })).sort((a, b) => a.m - b.m);
  while (files.length > 15) {
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
    check(a0 !== a1, 'animating crankSpinner ' + a0.toFixed(3) + ' -> ' + a1.toFixed(3));
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V:', assetV);
    check(assetV === '54', 'ASSET_V=54 got ' + assetV);
    const parts = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const out = {};
      ['twister', 'twister_pinion', 'twister_bracket', 'cartridge', 'chassis', 'cones_a', 'cones_b'].forEach(id => {
        const bb = new THREE.Box3();
        const arr = window._partMeshes[id] || [];
        let n = 0, v = 0;
        arr.forEach(s => s.traverse(o => { if (o.isMesh) { n++; v += o.geometry.attributes.position.count; bb.expandByObject(o); } }));
        const c = bb.getCenter(new THREE.Vector3());
        const sz = bb.getSize(new THREE.Vector3());
        out[id] = { scenes: arr.length, meshes: n, verts: v,
          world: [+c.x.toFixed(1), +c.y.toFixed(1), +c.z.toFixed(1)],
          size: [+sz.x.toFixed(1), +sz.y.toFixed(1), +sz.z.toFixed(1)] };
      });
      const pv = {};
      ['twister', 'twisterPinion', 'drum'].forEach(k => {
        const p = new THREE.Vector3(); window._pivots[k].getWorldPosition(p);
        pv[k] = [+p.x.toFixed(1), +p.y.toFixed(1), +p.z.toFixed(1)];
      });
      out.pivots = pv;
      const pin = (window._partMeshes.twister_pinion || [])[0];
      const br = (window._partMeshes.twister_bracket || [])[0];
      out.pinChildPos = pin ? [pin.position.x, pin.position.y, pin.position.z] : null;
      out.pinPivotName = (pin && pin.parent === window._pivots.twisterPinion) ? 'twisterPinionPivot' : 'OTHER';
      out.brParentRoot = br ? (br.parent === window._root) : null;
      return out;
    });
    console.log('PARTS ' + JSON.stringify(parts));
    check(parts.twister.scenes > 0 && parts.twister.verts > 500, 'twister renders verts=' + parts.twister.verts);
    check(parts.twister_pinion.scenes > 0 && parts.twister_pinion.verts > 100, 'pinion renders verts=' + parts.twister_pinion.verts);
    check(parts.twister_bracket.scenes > 0 && parts.twister_bracket.verts > 100, 'bracket renders verts=' + parts.twister_bracket.verts);
    const dPiv = Math.hypot(parts.pivots.twisterPinion[0] - parts.pivots.twister[0], parts.pivots.twisterPinion[1] - parts.pivots.twister[1], parts.pivots.twisterPinion[2] - parts.pivots.twister[2]);
    console.log('pinionPivot=' + JSON.stringify(parts.pivots.twisterPinion) + ' twisterPivot=' + JSON.stringify(parts.pivots.twister));
    check(dPiv < 1, 'pinion pivot AT mesh station d=' + dPiv.toFixed(2));
    check(parts.pinChildPos && parts.pinChildPos[0] === 0 && parts.pinChildPos[1] === -21 && parts.pinChildPos[2] === 0, 'pinion child pos [0,-21,0] got ' + JSON.stringify(parts.pinChildPos));
    check(parts.pinPivotName === 'twisterPinionPivot', 'pinion under own pivot got ' + parts.pinPivotName);
    check(parts.brParentRoot === true, 'bracket under root STATIC');
    const bore = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const bb = new THREE.Box3();
      const arr = window._partMeshes.twister || [];
      arr.forEach(s => s.traverse(o => { if (o.isMesh) bb.expandByObject(o); }));
      const c = bb.getCenter(new THREE.Vector3());
      const sz = bb.getSize(new THREE.Vector3());
      const rc = new THREE.Raycaster(new THREE.Vector3(c.x - 200, c.y, c.z), new THREE.Vector3(1, 0, 0), 0, 400);
      return { c: [+c.x.toFixed(1), +c.y.toFixed(1), +c.z.toFixed(1)], sz: [+sz.x.toFixed(1), +sz.y.toFixed(1), +sz.z.toFixed(1)], hits: rc.intersectObjects(arr, true).length };
    });
    console.log('BORE ' + JSON.stringify(bore));
    check(bore.hits === 0, 'bore OPEN hits=' + bore.hits);
    async function rots(ang) {
      await page.evaluate(a => { window._overrideAngle = a; }, ang);
      await page.waitForTimeout(350);
      return await page.evaluate(() => {
        window._root.updateMatrixWorld(true);
        const bp = new THREE.Vector3();
        (window._partMeshes.twister_bracket || [])[0].getWorldPosition(bp);
        return { drum: window._pivots.drum.rotation.z, ring: window._pivots.twister.rotation.x, pin: window._pivots.twisterPinion.rotation.y, br: [+bp.x.toFixed(2), +bp.y.toFixed(2), +bp.z.toFixed(2)] };
      });
    }
    const r0 = await rots(0), r1 = await rots(Math.PI);
    const dD = r1.drum - r0.drum, dR = r1.ring - r0.ring, dP = r1.pin - r0.pin;
    const rrDR = Math.abs(dR / dD), rrPR = Math.abs(dP / dR);
    console.log('DELTAS dDrum=' + dD.toFixed(4) + ' dRing=' + dR.toFixed(4) + ' dPin=' + dP.toFixed(4));
    console.log('ring/drum=' + rrDR.toFixed(4) + ' want 2.5714 pin/ring=' + rrPR.toFixed(4) + ' want 2.3333');
    check(Math.abs(rrDR - 18 / 7) / (18 / 7) < 0.03, 'ring 18/7 drum got ' + rrDR.toFixed(3));
    check(Math.abs(rrPR - 28 / 12) / (28 / 12) < 0.03, 'pinion 28/12 ring got ' + rrPR.toFixed(3));
    check(dP * dR < 0, 'pinion counter-rotates vs ring');
    const dBr = Math.hypot(r1.br[0] - r0.br[0], r1.br[1] - r0.br[1], r1.br[2] - r0.br[2]);
    console.log('bracket t0=' + JSON.stringify(r0.br) + ' t1=' + JSON.stringify(r1.br));
    check(dBr < 0.01, 'bracket STATIC moved ' + dBr.toFixed(3));
    const bobb = await page.evaluate(() => {
      const out = {};
      ['cones_a', 'cones_b'].forEach(id => {
        const bb = new THREE.Box3();
        (window._partMeshes[id] || []).forEach(s => s.traverse(o => { if (o.isMesh) bb.expandByObject(o); }));
        const c = bb.getCenter(new THREE.Vector3());
        out[id] = [+c.x.toFixed(1), +c.y.toFixed(1), +c.z.toFixed(1)];
      });
      return out;
    });
    console.log('BOBBINS ' + JSON.stringify(bobb));
    check(JSON.stringify(bobb.cones_a) !== JSON.stringify(bobb.cones_b), 'bobbins opposed A=' + bobb.cones_a + ' B=' + bobb.cones_b);
    await page.evaluate(() => { window._overrideAngle = null; });
    await page.waitForTimeout(200);
    const tx0 = await page.evaluate(() => window._tapeFold.flat.position.x);
    await page.waitForTimeout(800);
    const tx1 = await page.evaluate(() => window._tapeFold.flat.position.x);
    console.log('tapeFlat.x live ' + tx0 + ' -> ' + tx1);
    check(tx0 === tx1, 'tape STATIC x=' + tx0);
    await page.evaluate(() => window._setPanelCollapsed(true));
    const WP = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      function centre(id) {
        const bb = new THREE.Box3();
        (window._partMeshes[id] || []).forEach(s => s.traverse(o => { if (o.isMesh) bb.expandByObject(o); }));
        const c = bb.getCenter(new THREE.Vector3()); return [c.x, c.y, c.z];
      }
      return { tw: centre('twister'), pin: centre('twister_pinion'), br: centre('twister_bracket'), ch: centre('chassis'), bob: centre('cones_a') };
    });
    async function shot(f, cam, tgt, only, ang) {
      await page.evaluate(o => { if (o) window._setOnlyVisible(o); else window._showAllParts(); }, only || null);
      if (ang === null || ang === undefined) await page.evaluate(() => { window._overrideAngle = null; });
      else await page.evaluate(a => { window._overrideAngle = a; }, ang);
      await page.evaluate(ct => { window._camera.position.set(ct[0][0], ct[0][1], ct[0][2]); window._controls.target.set(ct[1][0], ct[1][1], ct[1][2]); window._controls.update(); }, [cam, tgt]);
      await page.waitForTimeout(450);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      console.log('Shot: ' + f);
    }
    const T = WP.tw, P = WP.pin, CH = WP.ch;
    const midTP = [(T[0] + P[0]) / 2, (T[1] + P[1]) / 2, (T[2] + P[2]) / 2];
    await shot('rv54_full.png', [CH[0] - 300, CH[1] + 170, CH[2] + 300], CH, null, null);
    await shot('rv54_top_down.png', [CH[0], CH[1] + 520, CH[2] + 5], CH, null, null);
    await shot('rv54_twister_east.png', [T[0] + 95, T[1] + 18, T[2] + 35], T, ['twister', 'twister_pinion'], 0.6);
    await shot('rv54_twister_west.png', [T[0] - 90, T[1] - 30, T[2] + 70], T, ['twister', 'twister_pinion'], 2.2);
    await shot('rv54_pinion_mesh.png', [midTP[0] + 60, midTP[1] - 30, midTP[2] + 110], midTP, ['twister', 'twister_pinion'], 0.6);
    await shot('rv54_bore.png', [T[0] + 80, T[1] + 6, T[2] + 6], T, ['twister'], 0.6);
    await shot('rv54_bracket.png', [WP.br[0] + 60, WP.br[1] + 40, WP.br[2] + 90], WP.br, ['twister_bracket', 'twister'], 0.6);
    await shot('rv54_bobbins.png', [WP.bob[0] + 120, WP.bob[1] + 80, WP.bob[2] + 160], WP.bob, ['cones_a', 'cones_b'], 0.6);
    await shot('rv54_anim_t0.png', [CH[0] - 300, CH[1] + 170, CH[2] + 300], CH, null, 0);
    await shot('rv54_anim_t1.png', [CH[0] - 300, CH[1] + 170, CH[2] + 300], CH, null, Math.PI);
    console.log('errors: ' + errors.length);
    errors.forEach(e => console.log('   ' + e));
    check(errors.length === 0, '0 console errors');
    await page.close();
    if (failures.length) { console.error('VERIFY FAILED(' + failures.length + '):'); failures.forEach(f => console.error(' - ' + f)); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await pool.releaseBrowser(browser);
  }
})();
