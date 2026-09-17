const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const SHOT_DIR = path.join(__dirname, 'screenshots');
const V = Date.now();
(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
  try {
    const page = await browser.newPage({ viewport: { width: 1600, height: 1000 } });
    const errors = [];
    page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
    page.on('pageerror', err => errors.push(err.message));
    await page.goto(`http://localhost:9099/index.html?v=${V}`);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 30000 });
    await page.evaluate(() => { window._overrideAngle = 0.6; });

    async function shot(f, cam, tgt, only) {
      await page.evaluate((o) => { if (o) window._setOnlyVisible(o); else window._showAllParts(); }, only || null);
      await page.evaluate(([c, t]) => {
        window._camera.position.set(c[0], c[1], c[2]);
        window._controls.target.set(t[0], t[1], t[2]);
        window._controls.update();
      }, [cam, tgt]);
      await page.waitForTimeout(400);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      console.log('Shot:', f);
    }
    // Isolated station shots (occluders hidden).
    await shot('f_turner_iso.png', [70, 90, 60], [42, 8, 25], ['plow', 'tape']);
    await shot('f_pull_iso.png', [94, 70, 60], [94, 10, 25], ['pull_a', 'pull_b', 'tape']);
    await shot('f_takeup_iso.png', [150, 80, 60], [122, 22, 25], ['takeup', 'tape', 'chassis']);
    await shot('f_nip_endon.png', [220, 16, 25], [94, 12, 25], ['pull_a', 'pull_b', 'tape']);

    // Per-mesh world boxes for oversize suspects.
    const per = await page.evaluate(() => {
      const out = {};
      ['cartridge', 'rollers_lower', 'pull_a', 'takeup', 'twister'].forEach(id => {
        out[id] = [];
        (window._partMeshes[id] || []).forEach(o => o.traverse(m => {
          if (m.isMesh && m.geometry && m.geometry.attributes.position) {
            m.updateWorldMatrix(true, false);
            const gb = new THREE.Box3().setFromBufferAttribute(m.geometry.attributes.position);
            gb.applyMatrix4(m.matrixWorld);
            out[id].push({
              min: [gb.min.x, gb.min.y, gb.min.z].map(v => Math.round(v * 10) / 10),
              max: [gb.max.x, gb.max.y, gb.max.z].map(v => Math.round(v * 10) / 10)
            });
          }
        }));
      });
      return out;
    });
    console.log('PER-MESH:');
    Object.keys(per).forEach(id => { console.log(' ' + id + ':'); per[id].forEach(b => console.log('   ' + JSON.stringify(b))); });

    // Edge-to-edge min distances (vertex sampling, stride 3).
    async function minDist(A, B) {
      return await page.evaluate(([a, b]) => {
        function verts(ids) {
          const pts = [];
          ids.forEach(id => {
            (window._partMeshes[id] || []).forEach(o => o.traverse(m => {
              if (m.isMesh && m.geometry && m.geometry.attributes.position) {
                m.updateWorldMatrix(true, false);
                const p = m.geometry.attributes.position;
                for (let i = 0; i < p.count; i += 3) {
                  const v = new THREE.Vector3(p.getX(i), p.getY(i), p.getZ(i));
                  v.applyMatrix4(m.matrixWorld);
                  pts.push(v);
                }
              }
            }));
          });
          return pts;
        }
        const pa = verts(A), pb = verts(B);
        let min2 = Infinity;
        for (let i = 0; i < pa.length; i++) for (let j = 0; j < pb.length; j++) {
          const d2 = pa[i].distanceToSquared(pb[j]);
          if (d2 < min2) min2 = d2;
        }
        return Math.round(Math.sqrt(min2) * 100) / 100;
      }, [A, B]);
    }
    const pairs = [
      [['pull_a'], ['pull_b']], [['pull_a'], ['takeup']], [['pull_b'], ['takeup']],
      [['twister'], ['pull_a']], [['plow'], ['twister']], [['takeup'], ['chassis']],
      [['pull_a'], ['chassis']], [['twister'], ['chassis']], [['plow'], ['chassis']]
    ];
    for (const [A, B] of pairs) {
      const d = await minDist(A, B);
      console.log(`DIST ${A}-${B}: ${d}`);
    }
    console.log('errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('FAILED:', e); process.exit(1); });
