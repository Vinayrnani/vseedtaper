const pool = require('./playwright_pool');
const fails = [];
function check(c, m) { console.log((c ? 'PASS ' : 'FAIL ') + m); if (!c) fails.push(m); }
(async () => {
  const bp = await pool.newPage({ width: 1600, height: 1000 });
  const browser = bp.browser, page = bp.page;
  try {
    await page.goto('http://localhost:9099/index.html?v=' + Date.now());
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 30000 });
    await page.evaluate(() => { window._overrideAngle = 0.6; window._showAllParts(); });
    await page.waitForTimeout(500);
    const p = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const pp = window._pivots.twisterPinion, pt = window._pivots.twister;
      const wp = new THREE.Vector3(), wt = new THREE.Vector3();
      pp.getWorldPosition(wp); pt.getWorldPosition(wt);
      const arr = window._partMeshes.twister_pinion || [];
      const bb = new THREE.Box3();
      arr.forEach(s => s.traverse(o => { if (o.isMesh) bb.expandByObject(o); }));
      const c = bb.getCenter(new THREE.Vector3());
      // bore hits with x positions, ring-zone only
      const bt = new THREE.Box3();
      (window._partMeshes.twister || []).forEach(s => s.traverse(o => { if (o.isMesh) bt.expandByObject(o); }));
      const bc = bt.getCenter(new THREE.Vector3());
      const rc = new THREE.Raycaster(new THREE.Vector3(bc.x - 200, bc.y, bc.z), new THREE.Vector3(1, 0, 0), 0, 400);
      const hits = rc.intersectObjects(window._partMeshes.twister || [], true).map(h => +h.point.x.toFixed(1));
      // bevel bins about TRUE pivot axis (through wt along X)
      const bins = new Array(12).fill(0);
      (window._partMeshes.twister || []).forEach(s => s.traverse(o => {
        if (o.isMesh && o.geometry && o.geometry.attributes.position) {
          o.updateWorldMatrix(true, false);
          const pa = o.geometry.attributes.position, v = new THREE.Vector3();
          for (let i = 0; i < pa.count; i += 5) { v.fromBufferAttribute(pa, i).applyMatrix4(o.matrixWorld);
            const rad = Math.hypot(v.y - wt.y, v.z - wt.z);
            if (rad > 16 && rad < 26) { let a = Math.atan2(v.z - wt.z, v.y - wt.y); if (a < 0) a += Math.PI * 2; bins[Math.min(11, Math.floor(a / (Math.PI * 2) * 12))]++; }
          }
        }
      }));
      // 180-sym about pivot axis point (wt.x? use bc.x for x, wt.y/z for axis)
      const ax = { x: bc.x, y: wt.y, z: wt.z };
      const pts = [];
      (window._partMeshes.twister || []).forEach(s => s.traverse(o => {
        if (o.isMesh && o.geometry && o.geometry.attributes.position) {
          o.updateWorldMatrix(true, false);
          const pa = o.geometry.attributes.position, v = new THREE.Vector3();
          for (let i = 0; i < pa.count; i += 13) { v.fromBufferAttribute(pa, i).applyMatrix4(o.matrixWorld); pts.push([v.x, v.y, v.z]); }
        }
      }));
      let hit = 0, tot = 0;
      for (let i = 0; i < pts.length; i += 2) { tot++;
        const q = pts[i], qx = 2 * ax.x - q[0], qy = 2 * ax.y - q[1], qz = 2 * ax.z - q[2];
        for (let j = 0; j < pts.length; j += 3) { const r = pts[j];
          if (Math.abs(r[0]-qx) < 3 && Math.abs(r[1]-qy) < 3 && Math.abs(r[2]-qz) < 3) { hit++; break; } }
      }
      return { pinLocal: [pp.position.x, pp.position.y, pp.position.z],
        pivPW: [+wp.x.toFixed(1), +wp.y.toFixed(1), +wp.z.toFixed(1)],
        pivTW: [+wt.x.toFixed(1), +wt.y.toFixed(1), +wt.z.toFixed(1)],
        pinMesh: [+c.x.toFixed(1), +c.y.toFixed(1), +c.z.toFixed(1)],
        boreC: [+bc.x.toFixed(1), +bc.y.toFixed(1), +bc.z.toFixed(1)], hitX: hits,
        bins: bins, symFrac: +(hit / tot).toFixed(3), symN: tot };
    });
    console.log('PROBE ' + JSON.stringify(p));
    check(p.pinLocal[0] === 172 && p.pinLocal[1] === 17 && p.pinLocal[2] === -30, 'FAIL-3b-corr pinion pivot root-local [172,17,-30] (got ' + JSON.stringify(p.pinLocal) + ')');
    const inRingZone = p.hitX.filter(x => Math.abs(x - p.boreC[0]) < 10);
    console.log('hits in ring zone (|x-cx|<10): ' + JSON.stringify(inRingZone));
    check(inRingZone.length === 0, 'FAIL-2a-corr bore open in ring zone (hits ' + JSON.stringify(inRingZone) + ' vs centre ' + p.boreC[0] + ')');
    const bmin = Math.min.apply(null, p.bins), bmax = Math.max.apply(null, p.bins);
    check(bmin > 0 && bmax / bmin < 4, 'bevel-corr full 360 about pivot axis (min=' + bmin + ' max=' + bmax + ')');
    check(p.symFrac > 0.5, 'sym-corr 180deg about pivot axis (frac=' + p.symFrac + ' n=' + p.symN + ')');
    const dy = p.pinMesh[1] - p.pivPW[1];
    console.log('pinion mesh-pivot dy=' + dy.toFixed(1) + ' (uncompensated +21 lift predicts ~+18..21)');
    await page.close();
    if (fails.length) { console.error('FOLLOWUP FAILED:'); fails.forEach(f => console.error(' - ' + f)); process.exitCode = 1; }
    else console.log('FOLLOWUP PASSED');
  } finally { await pool.releaseBrowser(browser); }
})().catch(e => { console.error('FOLLOWUP FAILED:', e); process.exit(1); });
