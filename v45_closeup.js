const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// v45 closeup retake: corrected sight lines (no wall crossings).
// Interior stations via open top (cam z~=25 plane, high y).
// Exterior train from back-top (world z > 75, outside gear faces).
const SHOT_DIR = path.join(__dirname, 'screenshots');
fs.mkdirSync(SHOT_DIR, { recursive: true });
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
    await page.evaluate(() => { window._overrideAngle = 0.6; window._showAllParts(); });

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

    // Interior stations via open top (world z=25 mid-interior sight plane).
    await shot('f_hopper_drum.png', [38, 175, 25], [0, 65, 25]);
    await shot('f_drop.png', [48, 115, 25], [0, 20, 25]);
    await shot('f_turner.png', [72, 105, 25], [42, 8, 25]);
    await shot('f_twister.png', [106, 105, 25], [72, 15, 25]);
    await shot('f_pull.png', [126, 95, 25], [94, 12, 25]);
    await shot('f_takeup.png', [162, 115, 25], [126, 28, 25]);
    // Exterior train from back-top (outside gear faces z>74).
    await shot('f_crankmesh.png', [-30, 100, 195], [-30, 55, 62]);
    await shot('f_idlers.png', [62, 85, 195], [60, 48, 65]);
    await shot('f_train_full.png', [30, 95, 265], [30, 40, 60]);
    // Tape path end-on from east (open end, down the tape axis).
    await shot('f_endon_east.png', [300, 45, 25], [20, 25, 25]);
    await shot('f_endon_west.png', [-260, 45, 25], [20, 25, 25]);

    // ---- numeric forensic probes ----
    const boxes = await page.evaluate(() => {
      const out = {};
      Object.keys(window._partMeshes).forEach(id => {
        const box = new THREE.Box3();
        let n = 0;
        (window._partMeshes[id] || []).forEach(o => o.traverse(m => {
          if (m.isMesh && m.geometry && m.geometry.attributes.position) {
            m.updateWorldMatrix(true, false);
            const gb = new THREE.Box3().setFromBufferAttribute(m.geometry.attributes.position);
            gb.applyMatrix4(m.matrixWorld);
            box.union(gb); n++;
          }
        }));
        if (n) out[id] = {
          min: [box.min.x, box.min.y, box.min.z].map(v => Math.round(v * 10) / 10),
          max: [box.max.x, box.max.y, box.max.z].map(v => Math.round(v * 10) / 10)
        };
      });
      return out;
    });
    console.log('PART BOXES:');
    Object.keys(boxes).forEach(id => console.log(' ', id, JSON.stringify(boxes[id])));

    // Tape procedural mesh extent (root-local x 165..179 thread zone check).
    const tape = await page.evaluate(() => {
      const g = window._tapeFold;
      const box = new THREE.Box3();
      [g.group, g.flat].forEach(gr => gr.traverse(m => {
        if (m.isMesh && m.geometry.attributes.position) {
          m.updateWorldMatrix(true, false);
          const gb = new THREE.Box3().setFromBufferAttribute(m.geometry.attributes.position);
          gb.applyMatrix4(m.matrixWorld);
          box.union(gb);
        }
      }));
      const tl = g.group === undefined ? null : null;
      return {
        min: [box.min.x, box.min.y, box.min.z].map(v => Math.round(v * 10) / 10),
        max: [box.max.x, box.max.y, box.max.z].map(v => Math.round(v * 10) / 10)
      };
    });
    console.log('TAPE BOX:', JSON.stringify(tape));
    const threads = await page.evaluate(() => {
      return window._twister.lines.map(l => {
        const p = l.geometry.attributes.position;
        let mn = [1e9, 1e9, 1e9], mx = [-1e9, -1e9, -1e9];
        for (let i = 0; i < p.count; i++) {
          const v = [p.getX(i), p.getY(i), p.getZ(i)];
          for (let k = 0; k < 3; k++) { if (v[k] < mn[k]) mn[k] = v[k]; if (v[k] > mx[k]) mx[k] = v[k]; }
        }
        return { min: mn.map(v => Math.round(v * 10) / 10), max: mx.map(v => Math.round(v * 10) / 10) };
      });
    });
    console.log('THREADS:', JSON.stringify(threads));

    console.log('errors:', errors.length);
    errors.forEach(e => console.log('  ', e));
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
})().catch(e => { console.error('FAILED:', e); process.exit(1); });
