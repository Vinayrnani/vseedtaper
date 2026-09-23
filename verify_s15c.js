const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');
const SHOT_DIR = path.join(__dirname, 'screenshots');
fs.mkdirSync(SHOT_DIR, { recursive: true });
// Cap 25: prune oldest non-s15* first (4 shots; keep total <=25).
(function prune() {
  let files = fs.readdirSync(SHOT_DIR).filter(f => f.endsWith('.png'))
    .map(f => ({ f, m: fs.statSync(path.join(SHOT_DIR, f)).mtimeMs })).sort((a, b) => a.m - b.m);
  while (files.length > 23) {
    const idx = files.findIndex(o => !/^s15_/.test(o.f));
    const o = idx >= 0 ? files.splice(idx, 1)[0] : files.shift();
    try { fs.unlinkSync(path.join(SHOT_DIR, o.f)); } catch (e) {}
    console.log('Pruned:', o.f);
  }
})();
const V = Date.now();
const failures = [];
function check(cond, msg) {
  console.log((cond ? 'PASS ' : 'FAIL ') + msg);
  if (!cond) failures.push(msg);
}
const HELPERS = `
window.__c = window.__c || {};
window.__c.hideThreads = function () { (window._twister.lines || []).forEach(l => { l.visible = false; }); };
window.__c.removeMarker = function () {
  if (window.__c.marker) { var p = window.__c.marker.parent; if (p) p.remove(window.__c.marker);
    if (window.__c.marker.geometry) window.__c.marker.geometry.dispose();
    if (window.__c.marker.material) window.__c.marker.material.dispose(); window.__c.marker = null; }
};
window.__c.firstMeshRoot = function (id) {
  var arr = (window._toggleGroups && window._toggleGroups[id]) ? window._toggleGroups[id].objects : [];
  for (var i = 0; i < arr.length; i++) if (arr[i] && arr[i].traverse) return arr[i];
  return null;
};
window.__c.meshBox = function (root) {
  var bb = new window.THREE.Box3(); var n = 0;
  root.traverse(function (o) { if (o.isMesh && o.visible !== false) { bb.expandByObject(o); n++; } });
  return { box: bb, n: n };
};
window.__c.setGhost = function (id, opacity) {
  var root = window.__c.firstMeshRoot(id); if (!root) return 0;
  var n = 0;
  root.traverse(function (o) {
    if (!o.isMesh || !o.material || !('opacity' in o.material)) return;
    if (!o.userData._saved) o.userData._saved = { opacity: o.material.opacity, transparent: o.material.transparent, depthWrite: o.material.depthWrite };
    if (opacity === null) { var s = o.userData._saved; o.material.opacity = s.opacity; o.material.transparent = s.transparent; o.material.depthWrite = s.depthWrite; }
    else { o.material.transparent = true; o.material.opacity = opacity; o.material.depthWrite = false; }
    n++;
  });
  return n;
};
window.__c.tapeRange = function (x0, x1) {
  window._root.updateMatrixWorld(true);
  var kids = ((window._tapeFold && window._tapeFold.flat && window._tapeFold.flat.children) || []);
  var bb = new window.THREE.Box3(); var v = new window.THREE.Vector3();
  var n = 0, dip = null, topY = -1e9;
  var tmp = new window.THREE.Box3();
  kids.forEach(function (m) {
    m.getWorldPosition(v);
    if (v.x >= x0 && v.x <= x1) { tmp.setFromObject(m); bb.union(tmp); n++; if (v.y > topY) topY = v.y; if (!dip || v.y < dip.y) dip = { x: v.x, y: v.y, z: v.z }; }
  });
  return { n: n, box: bb.isEmpty() ? null : bb, dip: dip, topY: topY };
};
window.__c.rayDown = function (x, z, fromY) {
  window._root.updateMatrixWorld(true);
  var root = window.__c.firstMeshRoot('chassis'); if (!root) return null;
  var rc = new window.THREE.Raycaster(new window.THREE.Vector3(x, fromY, z), new window.THREE.Vector3(0, -1, 0), 0, 500);
  var hits = rc.intersectObject(root, true);
  for (var i = 0; i < hits.length; i++) if (hits[i].point.y < fromY - 0.01) return +hits[i].point.y.toFixed(2);
  return null;
};
window.__c.frameBox = function (minA, maxA, markerA, dirA) {
  window._root.updateMatrixWorld(true);
  var bb = new window.THREE.Box3(new window.THREE.Vector3(minA[0], minA[1], minA[2]), new window.THREE.Vector3(maxA[0], maxA[1], maxA[2]));
  var center = bb.getCenter(new window.THREE.Vector3());
  var sphere = bb.getBoundingSphere(new window.THREE.Sphere());
  var mkAt = new window.THREE.Vector3(markerA[0], markerA[1], markerA[2]);
  window.__c.removeMarker();
  var mk = new window.THREE.Mesh(new window.THREE.SphereGeometry(5, 20, 14),
    new window.THREE.MeshBasicMaterial({ color: 0xff00ff, depthTest: false, transparent: true, opacity: 0.95 }));
  mk.renderOrder = 9999; mk.position.copy(mkAt);
  var scene = (window._root && window._root.parent) ? window._root.parent : window._root;
  scene.add(mk); window.__c.marker = mk;
  var cam = window._camera, ctl = window._controls;
  var dir = new window.THREE.Vector3(dirA[0], dirA[1], dirA[2]).normalize();
  var fov = (cam.fov || 42) * Math.PI / 180;
  var W = window.innerWidth || 1600, H = window.innerHeight || 1000;
  function metrics(dist) {
    cam.position.copy(center).addScaledVector(dir, dist);
    ctl.target.copy(center); ctl.update(); cam.updateMatrixWorld(true);
    window._root.updateMatrixWorld(true);
    var p = mkAt.clone().project(cam);
    var mx = (p.x * 0.5 + 0.5) * W, my = (-p.y * 0.5 + 0.5) * H;
    var cs = [[bb.min.x,bb.min.y,bb.min.z],[bb.min.x,bb.min.y,bb.max.z],[bb.min.x,bb.min.y,bb.max.z],[bb.min.x,bb.max.y,bb.max.z],[bb.max.x,bb.min.y,bb.min.z],[bb.max.x,bb.min.y,bb.max.z],[bb.max.x,bb.max.y,bb.min.z],[bb.max.x,bb.max.y,bb.max.z]];
    var a = 1e18, b = 1e18, c = -1e18, d = -1e18;
    cs.forEach(function (q) { var qv = new window.THREE.Vector3(q[0], q[1], q[2]).project(cam);
      var sx = (qv.x * 0.5 + 0.5) * W, sy = (-qv.y * 0.5 + 0.5) * H;
      if (sx < a) a = sx; if (sx > c) c = sx; if (sy < b) b = sy; if (sy > d) d = sy; });
    var area = Math.max(0, c - a) * Math.max(0, d - b) / (W * H);
    return { dist: dist, mx: mx, my: my, area: area, central: (mx >= W * 0.25 && mx <= W * 0.75 && my >= H * 0.25 && my <= H * 0.75) };
  }
  var dist = Math.max(sphere.radius / Math.tan(fov / 2) * 1.05, sphere.radius * 1.05);
  var m = metrics(dist);
  for (var i = 0; i < 5 && m.area < 0.20; i++) { dist *= 0.75; if (dist < sphere.radius * 1.02) break; m = metrics(dist); }
  m.cx = +center.x.toFixed(2); m.cy = +center.y.toFixed(2); m.cz = +center.z.toFixed(2); m.r = +sphere.radius.toFixed(2);
  m.mx = +m.mx.toFixed(1); m.my = +m.my.toFixed(1); m.area = +m.area.toFixed(3); m.dist = +m.dist.toFixed(1);
  m.mkx = +mkAt.x.toFixed(2); m.mky = +mkAt.y.toFixed(2); m.mkz = +mkAt.z.toFixed(2);
  return m;
};
`;
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
    await page.evaluate(() => {
      (window._twister.lines || []).forEach(l => { l.visible = false; });
      window._showAllParts();
      window._overrideAngle = 0.7;
      window._setPanelCollapsed(true);
    });
    await page.evaluate(HELPERS);
    await page.waitForTimeout(400);

    async function tapeShot(f, dir, label3q) {
      const err0 = errors.length;
      await page.evaluate(() => {
        window.__c.hideThreads();
        window._setOnlyVisible(['tape', 'chassis', 'hopper']);
        window.__c.hideThreads();
        window._overrideAngle = 0.7; window._setPanelCollapsed(true);
        window.__c.setGhost('chassis', 0.15);
      });
      await page.waitForTimeout(250);
      const prep = await page.evaluate(() => {
        // Frame CAD x70..105 = world x -30..5 (world x = CAD x - 100, verified: tape spans -113.5..119.5 for CAD -14..220).
        var t = window.__c.tapeRange(-30, 5);
        var platTop = window.__c.rayDown(t.dip.x, t.dip.z, t.dip.y + 30);
        var ymin = (platTop !== null ? platTop : t.dip.y - 0.5) - 1.5;
        var mn = [t.box.min.x, ymin, t.box.min.z], mx = [t.box.max.x, t.topY + 4, t.box.max.z];
        return { n: t.n, dip: t.dip, platTop: platTop, boxMin: mn.map(v => +v.toFixed(2)), boxMax: mx.map(v => +v.toFixed(2)) };
      });
      const m = await page.evaluate((o) => window.__c.frameBox(o.mn, o.mx, [o.dip.x, o.dip.y, o.dip.z], o.dir),
        { mn: prep.boxMin, mx: prep.boxMax, dip: prep.dip, dir: dir });
      console.log('TapePrep ' + f + ' shingles=' + prep.n + ' dip=' + JSON.stringify(prep.dip) +
        ' platTop=' + prep.platTop + ' box=[' + prep.boxMin + ']/[' + prep.boxMax + ']');
      check(prep.n >= 30, f + ' shingles in x70..105 >= 30 got ' + prep.n);
      check(prep.platTop !== null, f + ' live platform-top raycast hit');
      check(m.central === true, f + ' marker central50% (' + m.mx + ',' + m.my + ')');
      check(m.area > 0.20, f + ' subject area>20% got ' + m.area);
      await page.evaluate(() => { if (window.__c.marker) window.__c.marker.visible = false; });
      await page.waitForTimeout(350);
      const st = await page.evaluate(() => document.getElementById('status').textContent);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      const sz = fs.statSync(path.join(SHOT_DIR, f)).size;
      const fresh = (Date.now() - fs.statSync(path.join(SHOT_DIR, f)).mtimeMs) < 60000;
      const errs = errors.length - err0;
      console.log('Shot: ' + f + ' bytes=' + sz + ' fresh=' + fresh + ' marker=(' + m.mx + ',' + m.my + ')@(' + m.mkx + ',' + m.mky + ',' + m.mkz + ')' +
        ' central=' + m.central + ' area=' + m.area + ' dist=' + m.dist + ' r=' + m.r + ' c=(' + m.cx + ',' + m.cy + ',' + m.cz + ')' +
        ' errs=' + errs + ' status=' + JSON.stringify(st.slice(0, 60)) + ' // ' + label3q);
      check(sz > 0, f + ' nonzero'); check(fresh, f + ' fresh');
      check(errs === 0, f + ' 0 console errors'); check(st.includes('ready'), f + ' status=ready'); check(st.includes('v89'), f + ' footer v89');
      await page.evaluate(() => { window.__c.removeMarker(); window.__c.setGhost('chassis', null); });
      return { bytes: sz, prep: prep, m: m };
    }

    async function partShot(f, ids, ghostId, ghostOp, dir, label3q, expandBase) {
      const err0 = errors.length;
      await page.evaluate((o) => {
        window.__c.hideThreads();
        window._setOnlyVisible(o.ids);
        window.__c.hideThreads();
        window._overrideAngle = 0.7; window._setPanelCollapsed(true);
        if (o.ghostId) window.__c.setGhost(o.ghostId, o.ghostOp);
      }, { ids: ids, ghostId: ghostId, ghostOp: ghostOp });
      await page.waitForTimeout(250);
      const prep = await page.evaluate((o) => {
        window._root.updateMatrixWorld(true);
        var bb = new window.THREE.Box3(); var meshInfo = [];
        o.ids.forEach(function (id) {
          if (id === 'chassis') return; // ghosted context only; frame from target meshes
          var root = window.__c.firstMeshRoot(id); if (!root) return;
          var mb = window.__c.meshBox(root);
          var s = mb.box.getSize(new window.THREE.Vector3()), c = mb.box.getCenter(new window.THREE.Vector3());
          meshInfo.push({ id: id, n: mb.n, size: [s.x, s.y, s.z].map(v => +v.toFixed(1)), c: [c.x, c.y, c.z].map(v => +v.toFixed(1)) });
          bb.union(mb.box);
        });
        var c0 = bb.getCenter(new window.THREE.Vector3());
        var baseTop = window.__c.rayDown(c0.x, c0.z, c0.y + 60);
        if (o.expandBase && baseTop !== null) bb.min.y = Math.min(bb.min.y, baseTop - 1);
        return { meshes: meshInfo, baseTop: baseTop,
          boxMin: [bb.min.x, bb.min.y, bb.min.z].map(v => +v.toFixed(2)),
          boxMax: [bb.max.x, bb.max.y, bb.max.z].map(v => +v.toFixed(2)),
          c: [c0.x, c0.y, c0.z].map(v => +v.toFixed(2)) };
      }, { ids: ids, expandBase: expandBase });
      const m = await page.evaluate((o) => window.__c.frameBox(o.mn, o.mx, o.c, o.dir),
        { mn: prep.boxMin, mx: prep.boxMax, c: prep.c, dir: dir });
      console.log('PartPrep ' + f + ' meshes=' + JSON.stringify(prep.meshes) + ' baseTop=' + prep.baseTop +
        ' box=[' + prep.boxMin + ']/[' + prep.boxMax + ']');
      check(prep.meshes.length > 0, f + ' target meshes found');
      check(m.central === true, f + ' marker central50% (' + m.mx + ',' + m.my + ')');
      check(m.area > 0.20, f + ' subject area>20% got ' + m.area);
      await page.evaluate(() => { if (window.__c.marker) window.__c.marker.visible = false; });
      await page.waitForTimeout(350);
      const st = await page.evaluate(() => document.getElementById('status').textContent);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      const sz = fs.statSync(path.join(SHOT_DIR, f)).size;
      const fresh = (Date.now() - fs.statSync(path.join(SHOT_DIR, f)).mtimeMs) < 60000;
      const errs = errors.length - err0;
      console.log('Shot: ' + f + ' bytes=' + sz + ' fresh=' + fresh + ' marker=(' + m.mx + ',' + m.my + ') central=' + m.central +
        ' area=' + m.area + ' dist=' + m.dist + ' r=' + m.r + ' c=(' + m.cx + ',' + m.cy + ',' + m.cz + ')' +
        ' errs=' + errs + ' status=' + JSON.stringify(st.slice(0, 60)) + ' // ' + label3q);
      check(sz > 0, f + ' nonzero'); check(fresh, f + ' fresh');
      check(errs === 0, f + ' 0 console errors'); check(st.includes('ready'), f + ' status=ready'); check(st.includes('v89'), f + ' footer v89');
      await page.evaluate((g) => { window.__c.removeMarker(); if (g) window.__c.setGhost(g, null); }, ghostId);
      return { bytes: sz, prep: prep, m: m };
    }

    await tapeShot('s15_tape_side.png', [0, 0.08, 1], 'U dip x78..94 + platform x70..90 top + dropper x95..105, green dip meets blue platform then rises');
    await tapeShot('s15_tape_iso.png', [1, 0.7, 1], 'same trio 3/4, central x78..103');
    await partShot('s15_plow_feet.png', ['plow', 'chassis', 'gear_B'], 'chassis', 0.18, [0.5, 0.55, 1], 'plow feet on base + M3 (132,6)/(153,62), gear_B in frame', true);
    await partShot('s15_axle_ribs.png', ['twister_axle', 'twister', 'chassis'], 'chassis', 0.18, [0.9, 0.5, 1], 'root skirt + tie-ribs + M3 heads/traps + rotor/toe daylight', true);

    console.log('total errors: ' + errors.length);
    errors.forEach(e => console.log('   ' + e));
    check(errors.length === 0, '0 console errors overall');
    await page.evaluate(() => { (window._twister.lines || []).forEach(l => { l.visible = true; }); window._showAllParts(); });
    await page.close();
    if (failures.length) { console.error('VERIFY FAILED(' + failures.length + '):'); failures.forEach(f => console.error(' - ' + f)); process.exitCode = 1; }
    else console.log('VERIFY PASSED');
  } finally {
    await pool.releaseBrowser(browser);
  }
})();
