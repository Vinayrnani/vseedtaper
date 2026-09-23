const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');
const SHOT_DIR = path.join(__dirname, 'screenshots');
fs.mkdirSync(SHOT_DIR, { recursive: true });
// Cap 25: 9 shots -> keep <=16 before capture, prune oldest non-s15* first.
(function prune() {
  let files = fs.readdirSync(SHOT_DIR).filter(f => f.endsWith('.png'))
    .map(f => ({ f, m: fs.statSync(path.join(SHOT_DIR, f)).mtimeMs })).sort((a, b) => a.m - b.m);
  while (files.length > 16) {
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
const PAGE_HELPERS = `
window.__shot = window.__shot || {};
window.__shot.hideThreads = function () {
  (window._twister.lines || []).forEach(l => { l.visible = false; });
};
window.__shot.removeMarker = function () {
  if (window.__shot.marker) {
    var p = window.__shot.marker.parent;
    if (p) p.remove(window.__shot.marker);
    if (window.__shot.marker.geometry) window.__shot.marker.geometry.dispose();
    if (window.__shot.marker.material) window.__shot.marker.material.dispose();
    window.__shot.marker = null;
  }
};
window.__shot.setChassisTransparent = function (on) {
  var grp = (window._partMeshes && window._partMeshes['chassis']) || [];
  var tmpB = new window.THREE.Box3(); var tmpV = new window.THREE.Vector3();
  grp.forEach(function (root) {
    root.traverse(function (o) {
      if (!o.isMesh) return;
      var m = o.material;
      if (!m || !('opacity' in m)) return;
      if (!o.userData._saved) o.userData._saved = { opacity: m.opacity, transparent: m.transparent, depthWrite: m.depthWrite };
      if (on) {
        tmpB.setFromObject(o);
        var isWall = tmpB.max.y > 10; // base/feet (<=10) stay opaque; walls go 0.2
        if (isWall) { m.transparent = true; m.opacity = 0.2; m.depthWrite = false; }
      } else if (o.userData._saved) {
        m.opacity = o.userData._saved.opacity; m.transparent = o.userData._saved.transparent; m.depthWrite = o.userData._saved.depthWrite;
      }
    });
  });
  if (!on) { /* keep _saved for next use */ }
};
window.__shot.boxOf = function (ids) {
  window._root.updateMatrixWorld(true);
  var bb = new window.THREE.Box3(); var has = false; var tmp = new window.THREE.Box3();
  ids.forEach(function (id) {
    var arr = [];
    if (window._toggleGroups && window._toggleGroups[id]) arr = window._toggleGroups[id].objects || [];
    else if (window._partMeshes && window._partMeshes[id]) arr = window._partMeshes[id] || [];
    arr.forEach(function (o) { if (!o) return; tmp.setFromObject(o); if (!tmp.isEmpty()) { bb.union(tmp); has = true; } });
  });
  return has ? bb : null;
};
window.__shot.dipBottom = function () {
  // Data-driven: lowest tape-shingle world position (the U dip bottom).
  window._root.updateMatrixWorld(true);
  var kids = ((window._tapeFold && window._tapeFold.flat && window._tapeFold.flat.children) || []);
  var v = new window.THREE.Vector3(); var best = null;
  kids.forEach(function (m) { m.getWorldPosition(v); if (!best || v.y < best.y) best = { x: v.x, y: v.y, z: v.z }; });
  return best;
};
window.__shot.frame = function (ids, dirArr, opts) {
  opts = opts || {};
  window._root.updateMatrixWorld(true);
  var bb = window.__shot.boxOf(ids);
  if (!bb) return { error: 'empty-bbox' };
  var center = bb.getCenter(new window.THREE.Vector3());
  var sphere = bb.getBoundingSphere(new window.THREE.Sphere());
  if (opts.useDip) { var d = window.__shot.dipBottom(); if (d) center.set(d.x, d.y, d.z); }
  // Marker: 5mm sphere at intended target (scene-level, world coords).
  window.__shot.removeMarker();
  var mk = new window.THREE.Mesh(
    new window.THREE.SphereGeometry(5, 20, 14),
    new window.THREE.MeshBasicMaterial({ color: 0xff00ff, depthTest: false, transparent: true, opacity: 0.95 }));
  mk.renderOrder = 9999;
  mk.position.copy(center);
  var scene = (window._root && window._root.parent) ? window._root.parent : window._root;
  scene.add(mk);
  window.__shot.marker = mk;
  var cam = window._camera, ctl = window._controls;
  var dir = new window.THREE.Vector3(dirArr[0], dirArr[1], dirArr[2]).normalize();
  var fov = (cam.fov || 45) * Math.PI / 180;
  var fit = sphere.radius / Math.tan(fov / 2) * 1.12;
  var W = window.innerWidth || 1600, H = window.innerHeight || 1000;
  function metrics(dist) {
    cam.position.copy(center).addScaledVector(dir, dist);
    ctl.target.copy(center); ctl.update(); cam.updateMatrixWorld(true);
    window._root.updateMatrixWorld(true);
    var p = center.clone().project(cam);
    var mx = (p.x * 0.5 + 0.5) * W, my = (-p.y * 0.5 + 0.5) * H;
    var bb2 = window.__shot.boxOf(ids);
    var minX = 1e18, minY = 1e18, maxX = -1e18, maxY = -1e18;
    [[bb2.min.x,bb2.min.y,bb2.min.z],[bb2.min.x,bb2.min.y,bb2.max.z],[bb2.min.x,bb2.max.y,bb2.min.z],[bb2.min.x,bb2.max.y,bb2.max.z],[bb2.max.x,bb2.min.y,bb2.min.z],[bb2.max.x,bb2.min.y,bb2.max.z],[bb2.max.x,bb2.max.y,bb2.min.z],[bb2.max.x,bb2.max.y,bb2.max.z]].forEach(function (c) {
      var q = new window.THREE.Vector3(c[0], c[1], c[2]).project(cam);
      var sx = (q.x * 0.5 + 0.5) * W, sy = (-q.y * 0.5 + 0.5) * H;
      if (sx < minX) minX = sx; if (sx > maxX) maxX = sx;
      if (sy < minY) minY = sy; if (sy > maxY) maxY = sy;
    });
    var area = Math.max(0, maxX - minX) * Math.max(0, maxY - minY) / (W * H);
    var central = (mx >= W * 0.25 && mx <= W * 0.75 && my >= H * 0.25 && my <= H * 0.75);
    return { dist: dist, mx: mx, my: my, area: area, central: central };
  }
  var dist = Math.max(fit, sphere.radius * 1.2);
  var m = metrics(dist);
  for (var i = 0; i < 4 && m.area < 0.20; i++) { dist *= 0.72; if (dist < sphere.radius * 1.05) break; m = metrics(dist); }
  m.cx = +center.x.toFixed(2); m.cy = +center.y.toFixed(2); m.cz = +center.z.toFixed(2);
  m.r = +sphere.radius.toFixed(2);
  m.mx = +m.mx.toFixed(1); m.my = +m.my.toFixed(1); m.area = +m.area.toFixed(3); m.dist = +m.dist.toFixed(1);
  return m;
};
`;
const SHOTS = [
  { f: 's15_gearb_back.png', ids: ['gear_B'], dir: [0, 0.12, -1], label: 'closed solid frustum, shaft, teeth', trans: false, dip: false },
  { f: 's15_gearb_iso.png', ids: ['gear_B'], dir: [1, 0.7, -1], label: 'Gear B 3/4', trans: false, dip: false },
  { f: 's15_hopper_top.png', ids: ['hopper'], dir: [0.05, 1, -0.08], label: 'both cheeks + center slot + register grooves', trans: false, dip: false },
  { f: 's15_hopper_side.png', ids: ['hopper'], dir: [0.1, 0.15, -1], label: '+Y full-height uniform wall', trans: false, dip: false },
  { f: 's15_tape_side.png', ids: ['tape', 'chassis', 'hopper'], dir: [0, 0.12, 1], label: 'U dip x78..94, platform x70..90 top 19.5, dropper x95..105 centered', trans: false, dip: true },
  { f: 's15_tape_iso.png', ids: ['tape', 'chassis', 'hopper'], dir: [1, 0.75, 1], label: 'same U/platform/dropper 3/4', trans: false, dip: true },
  { f: 's15_plow_machine.png', ids: ['plow', 'gear_B', 'chassis'], dir: [0.9, 0.6, -1], label: 'plow + Gear B + transparent-wall chassis', trans: true, dip: false },
  { f: 's15_axle_assembly.png', ids: ['twister_axle', 'twister', 'chassis'], dir: [0.9, 0.55, 1], label: 'axle + twister + transparent-wall chassis', trans: true, dip: false },
  { f: 's15_assembly.png', ids: null, dir: [-0.9, 0.6, 1.1], label: 'full machine west/east extension + overall clipping', trans: true, dip: false },
];
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
    await page.evaluate(PAGE_HELPERS);
    await page.waitForTimeout(400);
    for (const s of SHOTS) {
      const err0 = errors.length;
      await page.evaluate((ids) => {
        window.__shot.hideThreads();
        if (ids) window._setOnlyVisible(ids); else window._showAllParts();
        window.__shot.hideThreads();
        window._overrideAngle = 0.7;
        window._setPanelCollapsed(true);
      }, s.ids);
      await page.waitForTimeout(250);
      const m = await page.evaluate((o) => {
        window.__shot.setChassisTransparent(!!o.trans);
        var ids = o.ids || Object.keys(window._toggleGroups || {});
        return window.__shot.frame(ids, o.dir, { useDip: !!o.dip });
      }, { ids: s.ids, dir: s.dir, trans: s.trans, dip: s.dip });
      await page.waitForTimeout(350);
      const st = await page.evaluate(() => document.getElementById('status').textContent);
      await page.screenshot({ path: path.join(SHOT_DIR, s.f) });
      const fp = path.join(SHOT_DIR, s.f);
      const sz = fs.statSync(fp).size;
      const fresh = (Date.now() - fs.statSync(fp).mtimeMs) < 60000;
      const errs = errors.length - err0;
      console.log('Shot: ' + s.f + ' bytes=' + sz + ' fresh=' + fresh +
        ' marker=(' + m.mx + ',' + m.my + ') central=' + m.central +
        ' area=' + m.area + ' dist=' + m.dist + ' r=' + m.r +
        ' c=(' + m.cx + ',' + m.cy + ',' + m.cz + ')' +
        ' errs=' + errs + ' status=' + JSON.stringify(st.slice(0, 60)) + ' // ' + s.label);
      check(sz > 0, s.f + ' nonzero');
      check(fresh, s.f + ' fresh');
      check(m.central === true, s.f + ' marker central50% (' + m.mx + ',' + m.my + ')');
      check(m.area > 0.20, s.f + ' subject area>20% got ' + m.area);
      check(errs === 0, s.f + ' 0 console errors');
      check(st.includes('ready'), s.f + ' status=ready');
      await page.evaluate(() => { window.__shot.removeMarker(); window.__shot.setChassisTransparent(false); });
    }
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
