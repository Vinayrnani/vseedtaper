const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');
// Reviewer re-verify @6a4069e: 3 prior FAILs + full pass. ASSET_V expect 53.
// FAIL-1 (b6729c6): pinion double-transform -> ~179mm off mesh. Fix: origin-centred.
// FAIL-2a (4a511a0): ring bevel bore blocked (bore_dia=0). Fix: bore_dia=19.
// FAIL-2b (4a511a0): bracket spun with twister_angle. Fix: frozen in CAD assembly.
// FAIL-3 (6a4069e): pinion no pivot/frozen/invisible. Fix: own pivot + counter-rot + visible.
const SHOT_DIR = path.join(__dirname, 'screenshots');
fs.mkdirSync(SHOT_DIR, { recursive: true });
(function prune() {
  const files = fs.readdirSync(SHOT_DIR).filter(f => f.endsWith('.png'))
    .map(f => ({ f, m: fs.statSync(path.join(SHOT_DIR, f)).mtimeMs })).sort((a, b) => a.m - b.m);
  while (files.length > 16) { const o = files.shift(); fs.unlinkSync(path.join(SHOT_DIR, o.f)); console.log('Pruned:', o.f); }
})();
const V = Date.now();
const fails = [];
function check(cond, msg) { console.log((cond ? 'PASS ' : 'FAIL ') + msg); if (!cond) fails.push(msg); }
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
    check(a0 !== a1, 'animating (crankSpinner ' + a0.toFixed(3) + ' -> ' + a1.toFixed(3) + ')');
    const assetV = await page.evaluate(() => document.documentElement.innerHTML.match(/ASSET_V = (\d+)/)[1]);
    console.log('ASSET_V:', assetV);
    check(assetV === '53', 'ASSET_V=53 (got ' + assetV + ')');
    // ---- FAIL-1: pinion station ----
    const st = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      function info(id) {
        const arr = window._partMeshes[id] || [];
        const bb = new THREE.Box3();
        arr.forEach(s => s.traverse(o => { if (o.isMesh) bb.expandByObject(o); }));
        if (bb.isEmpty() || !arr.length) return null;
        const c = bb.getCenter(new THREE.Vector3()), sz = bb.getSize(new THREE.Vector3());
        const sp = new THREE.Vector3(); arr[0].getWorldPosition(sp);
        return { world: [+c.x.toFixed(1), +c.y.toFixed(1), +c.z.toFixed(1)],
          size: [+sz.x.toFixed(1), +sz.y.toFixed(1), +sz.z.toFixed(1)],
          localOff: +c.clone().sub(sp).length().toFixed(2), scenes: arr.length };
      }
      const pt = new THREE.Vector3(), pp = new THREE.Vector3();
      window._pivots.twister.getWorldPosition(pt); window._pivots.twisterPinion.getWorldPosition(pp);
      return { tw: info('twister'), pin: info('twister_pinion'),
        pivT: [+pt.x.toFixed(1), +pt.y.toFixed(1), +pt.z.toFixed(1)],
        pivP: [+pp.x.toFixed(1), +pp.y.toFixed(1), +pp.z.toFixed(1)] };
    });
    console.log('STATION ' + JSON.stringify(st));
    check(st.pin && st.pin.localOff < 25, 'FAIL-1a pinion GLB origin-centred localOff=' + (st.pin && st.pin.localOff) + ' (was ~179)');
    check(st.pin && dist(st.pin.world, st.pivP) < 15, 'FAIL-1b pinion mesh on-station, mesh-to-pivot=' + (st.pin && dist(st.pin.world, st.pivP).toFixed(1)) + 'mm (not 179 off)');
    check(dist(st.pivP, st.pivT) < 5, 'FAIL-1c pinion/ring pivots coincide (bevel apex intersect), d=' + dist(st.pivP, st.pivT).toFixed(1));
    const pinMax = Math.max.apply(null, st.pin.size);
    check(pinMax > 15 && pinMax < 32, 'pinion OD sane 12T M1.5 (~21mm), maxDim=' + pinMax.toFixed(1));
    // ---- FAIL-2a: bore open ----
    const bore = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const bb = new THREE.Box3();
      (window._partMeshes.twister || []).forEach(s => s.traverse(o => { if (o.isMesh) bb.expandByObject(o); }));
      const c = bb.getCenter(new THREE.Vector3()), sz = bb.getSize(new THREE.Vector3());
      const rc = new THREE.Raycaster(new THREE.Vector3(c.x - 200, c.y, c.z), new THREE.Vector3(1, 0, 0), 0, 400);
      const hits = rc.intersectObjects(window._partMeshes.twister || [], true);
      let minR = 1e9;
      (window._partMeshes.twister || []).forEach(s => s.traverse(o => {
        if (o.isMesh && o.geometry && o.geometry.attributes.position) {
          o.updateWorldMatrix(true, false);
          const p = o.geometry.attributes.position, v = new THREE.Vector3();
          for (let i = 0; i < p.count; i += 7) { v.fromBufferAttribute(p, i).applyMatrix4(o.matrixWorld);
            minR = Math.min(minR, Math.hypot(v.y - c.y, v.z - c.z)); }
        }
      }));
      return { c: [+c.x.toFixed(1), +c.y.toFixed(1), +c.z.toFixed(1)], hits: hits.length, minR: +minR.toFixed(2) };
    });
    console.log('BORE ' + JSON.stringify(bore));
    check(bore.hits === 0, 'FAIL-2a bore raycast 0 hits (got ' + bore.hits + ')');
    check(bore.minR > 7, 'FAIL-2a bore wall min radius ' + bore.minR + ' (stale web would be ~0)');
    // ---- FAIL-2b: bracket frozen? (CAD froze assembly; viewer bakes bracket in twister.glb?) ----
    const br = await page.evaluate(() => {
      const arr = window._partMeshes.twister || [];
      return { scenes: arr.length, parentIsPivot: arr.length ? (arr[0].parent === window._pivots.twister) : null };
    });
    console.log('BRACKET ' + JSON.stringify(br));
    check(br.parentIsPivot === false, 'FAIL-2b bracket static in viewer (parentIsPivot=' + br.parentIsPivot + ', scenes=' + br.scenes + ')');
    // ---- FAIL-3: pinion pivot/visible/counter-rotation ----
    const pv = await page.evaluate(() => {
      const p = window._pivots.twisterPinion;
      if (!p) return null;
      const v = new THREE.Vector3(); p.getWorldPosition(v);
      const arr = window._partMeshes.twister_pinion || [];
      let vis = 0, tot = 0;
      arr.forEach(s => s.traverse(o => { if (o.isMesh) { tot++; if (o.visible) vis++; } }));
      return { world: [v.x, v.y, v.z], rl: [+(v.x + 100).toFixed(1), +(55 - v.z).toFixed(1), +v.y.toFixed(1)], visMeshes: vis, totMeshes: tot, sceneVis: arr.length ? arr[0].visible : null };
    });
    console.log('PINPIVOT ' + JSON.stringify(pv));
    check(!!pv, 'FAIL-3a twisterPinion pivot exists');
    check(pv && Math.abs(pv.rl[0] - 172) < 3 && Math.abs(pv.rl[1] - 17) < 3 && Math.abs(pv.rl[2] + 30) < 3, 'FAIL-3b pinion pivot at mesh station rl=' + (pv && JSON.stringify(pv.rl)) + ' (want [172,17,-30])');
    check(pv && pv.visMeshes > 0 && pv.sceneVis === true, 'FAIL-3c pinion visible (meshes ' + (pv && pv.visMeshes) + '/' + (pv && pv.totMeshes) + ')');
    async function rots(ang) {
      await page.evaluate(a => { window._overrideAngle = a; }, ang);
      await page.waitForTimeout(350);
      return await page.evaluate(() => ({ drum: window._pivots.drum.rotation.z, ring: window._pivots.twister.rotation.x, pin: window._pivots.twisterPinion.rotation.y }));
    }
    const r0 = await rots(0), r1 = await rots(Math.PI);
    const dD = r1.drum - r0.drum, dR = r1.ring - r0.ring, dP = r1.pin - r0.pin;
    console.log('DELTAS dDrum=' + dD.toFixed(4) + ' dRing=' + dR.toFixed(4) + ' dPin=' + dP.toFixed(4));
    const rr = Math.abs(dR / dD), pr = Math.abs(dP / dR);
    console.log('ring/drum=' + rr.toFixed(4) + ' (want 18/7=' + (18/7).toFixed(4) + ') pin/ring=' + pr.toFixed(4) + ' (want 28/12=' + (28/12).toFixed(4) + ')');
    check(Math.abs(rr - 18/7) / (18/7) < 0.03, 'ring spins 18/7 drum (got ' + rr.toFixed(3) + ')');
    check(Math.abs(pr - 28/12) / (28/12) < 0.03, 'FAIL-3d pinion spins (28/12) ring (got ' + pr.toFixed(3) + ')');
    check(dP * dR < 0, 'FAIL-3e pinion counter-rotates vs ring');
    check(Math.abs(dP) > 0.5, 'FAIL-3f pinion not frozen (|dP|=' + Math.abs(dP).toFixed(2) + ')');
    // ---- bevel full 360: angular uniformity of ring-zone verts about X ----
    const bev = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const bb = new THREE.Box3();
      (window._partMeshes.twister || []).forEach(s => s.traverse(o => { if (o.isMesh) bb.expandByObject(o); }));
      const c = bb.getCenter(new THREE.Vector3());
      const bins = new Array(12).fill(0);
      (window._partMeshes.twister || []).forEach(s => s.traverse(o => {
        if (o.isMesh && o.geometry && o.geometry.attributes.position) {
          o.updateWorldMatrix(true, false);
          const p = o.geometry.attributes.position, v = new THREE.Vector3();
          for (let i = 0; i < p.count; i += 11) { v.fromBufferAttribute(p, i).applyMatrix4(o.matrixWorld);
            const rad = Math.hypot(v.y - c.y, v.z - c.z);
            if (rad > 16 && rad < 26) { let a = Math.atan2(v.z - c.z, v.y - c.y); if (a < 0) a += Math.PI * 2; bins[Math.floor(a / (Math.PI * 2) * 12)]++; }
          }
        }
      }));
      return bins;
    });
    console.log('BEVBINS ' + JSON.stringify(bev));
    const bmin = Math.min.apply(null, bev), bmax = Math.max.apply(null, bev);
    check(bmin > 0 && bmax / bmin < 4, 'bevel ring-zone full 360 (bins min=' + bmin + ' max=' + bmax + ')');
    // ---- bobbins 180deg: X-axis 180-rot symmetry fraction ----
    const sym = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const bb = new THREE.Box3();
      (window._partMeshes.twister || []).forEach(s => s.traverse(o => { if (o.isMesh) bb.expandByObject(o); }));
      const c = bb.getCenter(new THREE.Vector3());
      const pts = [];
      (window._partMeshes.twister || []).forEach(s => s.traverse(o => {
        if (o.isMesh && o.geometry && o.geometry.attributes.position) {
          o.updateWorldMatrix(true, false);
          const p = o.geometry.attributes.position, v = new THREE.Vector3();
          for (let i = 0; i < p.count; i += 23) { v.fromBufferAttribute(p, i).applyMatrix4(o.matrixWorld); pts.push([v.x, v.y, v.z]); }
        }
      }));
      let hit = 0;
      for (let i = 0; i < pts.length; i += 3) {
        const q = pts[i], qx = 2 * c.x - q[0], qy = 2 * c.y - q[1], qz = 2 * c.z - q[2];
        for (let j = 0; j < pts.length; j += 7) { const r = pts[j];
          if (Math.abs(r[0]-qx) < 2 && Math.abs(r[1]-qy) < 2 && Math.abs(r[2]-qz) < 2) { hit++; break; } }
      }
      return { n: Math.ceil(pts.length / 3), hitFrac: +(hit / Math.ceil(pts.length / 3)).toFixed(3) };
    });
    console.log('SYM180 ' + JSON.stringify(sym));
    check(sym.hitFrac > 0.5, 'bobbins 180deg symmetric (frac=' + sym.hitFrac + ')');
    // ---- tape static through bore ----
    await page.evaluate(() => { window._overrideAngle = 0.6; });
    await page.waitForTimeout(200);
    const tx0 = await page.evaluate(() => window._tapeFold.flat.position.x);
    await page.waitForTimeout(900);
    const tx1 = await page.evaluate(() => window._tapeFold.flat.position.x);
    console.log('tape x: ' + tx0 + ' -> ' + tx1);
    check(tx0 === tx1 && tx0 === 97, 'tape ribbon STATIC at 97 (got ' + tx0 + '/' + tx1 + ')');
    const tb = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const bt = new THREE.Box3(), bp2 = new THREE.Box3();
      (window._partMeshes.twister || []).forEach(s => s.traverse(o => { if (o.isMesh) bt.expandByObject(o); }));
      const tg = window._tapeFold.flat;
      tg.updateWorldMatrix(true, false); bp2.expandByObject(tg);
      const ct = bt.getCenter(new THREE.Vector3()), cp = bp2.getCenter(new THREE.Vector3());
      return { ring: [+ct.x.toFixed(1), +ct.y.toFixed(1), +ct.z.toFixed(1)],
        tapeMinX: +bp2.min.x.toFixed(1), tapeMaxX: +bp2.max.x.toFixed(1),
        tapeC: [+cp.x.toFixed(1), +cp.y.toFixed(1), +cp.z.toFixed(1)] };
    });
    console.log('TAPEBORE ' + JSON.stringify(tb));
    check(tb.tapeMinX < tb.ring[0] && tb.ring[0] < tb.tapeMaxX, 'tape spans through ring plane x=' + tb.ring[0] + ' in [' + tb.tapeMinX + ',' + tb.tapeMaxX + ']');
    check(Math.hypot(tb.tapeC[1] - tb.ring[1], tb.tapeC[2] - tb.ring[2]) < 25, 'tape centred near bore (dyz=' + Math.hypot(tb.tapeC[1]-tb.ring[1], tb.tapeC[2]-tb.ring[2]).toFixed(1) + ')');
    // ---- screenshots ----
    await page.evaluate(() => window._setPanelCollapsed(true));
    await page.evaluate(() => { const top = window._root.parent || window._root; top.traverse(o => { if (o.isLine) o.visible = false; }); });
    const WP = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      function centre(id) { const bb = new THREE.Box3();
        (window._partMeshes[id] || []).forEach(s => s.traverse(o => { if (o.isMesh) bb.expandByObject(o); }));
        const c = bb.getCenter(new THREE.Vector3()); return [c.x, c.y, c.z]; }
      return { tw: centre('twister'), pin: centre('twister_pinion'), ch: centre('chassis') };
    });
    console.log('WP ' + JSON.stringify(WP));
    async function shot(f, cam, tgt, only, ang) {
      await page.evaluate(o => { if (o) window._setOnlyVisible(o); else window._showAllParts(); }, only || null);
      if (ang === null || ang === undefined) await page.evaluate(() => { window._overrideAngle = null; });
      else await page.evaluate(a => { window._overrideAngle = a; }, ang);
      await page.evaluate(ct => { window._camera.position.set(ct[0][0], ct[0][1], ct[0][2]); window._controls.target.set(ct[1][0], ct[1][1], ct[1][2]); window._controls.update(); }, [cam, tgt]);
      await page.waitForTimeout(450);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      console.log('Shot:', f);
    }
    const T = WP.tw, P = WP.pin, CH = WP.ch;
    const midTP = [(T[0]+P[0])/2, (T[1]+P[1])/2, (T[2]+P[2])/2];
    await shot('rv53_full_crankside.png', [CH[0]-300, CH[1]+170, CH[2]+300], CH, null, null);
    await shot('rv53_top_down.png', [CH[0], CH[1]+520, CH[2]+5], CH, null, null);
    await shot('rv53_twister_east.png', [T[0]+130, T[1]+15, T[2]+12], T, ['twister','twister_pinion'], 0.6);
    await shot('rv53_twister_west.png', [T[0]-130, T[1]+15, T[2]+25], T, ['twister','twister_pinion'], 0.6);
    await shot('rv53_pinion_mesh.png', [midTP[0]+45, midTP[1]-55, midTP[2]+80], midTP, ['twister','twister_pinion'], 0.6);
    await shot('rv53_bobbins.png', [T[0]+40, T[1]-70, T[2]+100], T, ['twister'], 0.6);
    await shot('rv53_tape_bore.png', [T[0]+10, T[1]+10, T[2]+170], T, ['twister','tape'], 0.6);
    await shot('rv53_anim_t0.png', [CH[0]-300, CH[1]+170, CH[2]+300], CH, null, 0);
    await shot('rv53_anim_t05.png', [CH[0]-300, CH[1]+170, CH[2]+300], CH, null, Math.PI);
    console.log('errors: ' + errors.length); errors.forEach(e => console.log('   ' + e));
    check(errors.length === 0, '0 console errors');
    await page.close();
    if (fails.length) { console.error('REVIEW FAILED (' + fails.length + '):'); fails.forEach(f => console.error(' - ' + f)); process.exitCode = 1; }
    else console.log('REVIEW PASSED');
  } finally { await pool.releaseBrowser(browser); }
})().catch(e => { console.error('REVIEW FAILED:', e); process.exit(1); });
