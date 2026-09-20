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
      const wt = new THREE.Vector3(); window._pivots.twister.getWorldPosition(wt);
      const arr = window._partMeshes.twister || [];
      // bore raycast through PIVOT axis (the true bore line), along X
      const rc = new THREE.Raycaster(new THREE.Vector3(wt.x - 200, wt.y, wt.z), new THREE.Vector3(1, 0, 0), 0, 400);
      const hits = rc.intersectObjects(arr, true).map(h => +h.point.x.toFixed(1));
      // min radius from pivot axis over ring-zone x only (|x-wt.x|<8, excludes bracket at -13)
      let minR = 1e9;
      arr.forEach(s => s.traverse(o => {
        if (o.isMesh && o.geometry && o.geometry.attributes.position) {
          o.updateWorldMatrix(true, false);
          const pa = o.geometry.attributes.position, v = new THREE.Vector3();
          for (let i = 0; i < pa.count; i += 5) { v.fromBufferAttribute(pa, i).applyMatrix4(o.matrixWorld);
            if (Math.abs(v.x - wt.x) < 8) minR = Math.min(minR, Math.hypot(v.y - wt.y, v.z - wt.z)); }
        }
      }));
      // rod-zone 180-about-X symmetry: radius 8..14 from axis, |x-wt.x|<12, x UNCHANGED by the map
      const pts = [];
      arr.forEach(s => s.traverse(o => {
        if (o.isMesh && o.geometry && o.geometry.attributes.position) {
          o.updateWorldMatrix(true, false);
          const pa = o.geometry.attributes.position, v = new THREE.Vector3();
          for (let i = 0; i < pa.count; i += 7) { v.fromBufferAttribute(pa, i).applyMatrix4(o.matrixWorld);
            const r = Math.hypot(v.y - wt.y, v.z - wt.z);
            if (r > 8 && r < 14 && Math.abs(v.x - wt.x) < 12) pts.push([v.x, v.y, v.z]); }
        }
      }));
      let hit = 0;
      for (let i = 0; i < pts.length; i += 2) {
        const q = pts[i], qy = 2 * wt.y - q[1], qz = 2 * wt.z - q[2];
        for (let j = 0; j < pts.length; j += 3) { const r = pts[j];
          if (Math.abs(r[0]-q[0]) < 3 && Math.abs(r[1]-qy) < 3 && Math.abs(r[2]-qz) < 3) { hit++; break; } }
      }
      return { pivT: [+wt.x.toFixed(1), +wt.y.toFixed(1), +wt.z.toFixed(1)], hitX: hits,
        minR: +minR.toFixed(2), rodN: Math.ceil(pts.length / 2), rodSym: pts.length ? +(hit / Math.ceil(pts.length / 2)).toFixed(3) : -1 };
    });
    console.log('PROBE ' + JSON.stringify(p));
    check(p.hitX.length === 0, 'FAIL-2a-true bore-axis raycast 0 hits (got ' + JSON.stringify(p.hitX) + ')');
    check(p.minR > 7, 'FAIL-2a-true ring-zone bore wall minR=' + p.minR);
    check(p.rodSym > 0.5, 'bobbins-true rod-zone 180-about-X sym frac=' + p.rodSym + ' (n=' + p.rodN + ')');
    await page.close();
    if (fails.length) { console.error('FOLLOWUP2 FAILED:'); fails.forEach(f => console.error(' - ' + f)); process.exitCode = 1; }
    else console.log('FOLLOWUP2 PASSED');
  } finally { await pool.releaseBrowser(browser); }
})().catch(e => { console.error('FOLLOWUP2 FAILED:', e); process.exit(1); });
