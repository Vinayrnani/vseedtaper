// v49 drive audit: isolate drum + drive gears + twister rotor, multi-angle.
// Chassis carries the v48 drive gears fused in its GLB, so true PART
// isolation would hide the gears too. Instead: ghost the chassis walls
// (transparent) + show cartridge(drum+drum40) + twister + tape lane.
// Proves (a) duplicate drum-coaxial 50T vs existing drum40, (b) bevels
// under the tape lane blocking flow.
const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');
const SHOT_DIR = path.join(__dirname, 'screenshots');
fs.mkdirSync(SHOT_DIR, { recursive: true });
const V = Date.now();

(async () => {
  const { browser, page } = await pool.newPage({ width: 1600, height: 1000 });
  try {
    const errors = [];
    page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
    page.on('pageerror', e => errors.push(e.message));
    await page.goto(`http://localhost:9099/index.html?v=${V}`);
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 30000 });
    await page.evaluate(() => window._setPanelCollapsed(true));

    // Isolate: ghost chassis, show drum + twister + tape; hide everything else.
    await page.evaluate(() => {
      window._setOnlyVisible(['chassis', 'cartridge', 'twister', 'tape']);
      // Ghost chassis walls so interior drive gears show through.
      (window._partMeshes.chassis || []).forEach(g => g.traverse(n => {
        if (n.isMesh) {
          n.material.transparent = true;
          n.material.opacity = 0.13;
          n.material.depthWrite = false;
        }
      }));
      window._overrideAngle = 0.6;
    });
    await page.waitForTimeout(500);

    const boxes = await page.evaluate(() => {
      function boxOf(ids) {
        const box = new THREE.Box3();
        ids.forEach(id => (window._partMeshes[id] || []).forEach(g => g.traverse(m => {
          if (m.isMesh && m.geometry && m.geometry.attributes.position) {
            m.updateWorldMatrix(true, false);
            box.expandByObject(m);
          }
        })));
        if (box.isEmpty()) return null;
        const s = box.getSize(new THREE.Vector3()), c = box.getCenter(new THREE.Vector3());
        return { sx: s.x, sy: s.y, sz: s.z, cx: c.x, cy: c.y, cz: c.z,
                 min: box.min.toArray(), max: box.max.toArray() };
      }
      return {
        drum: boxOf(['cartridge']),
        drive: boxOf(['chassis', 'cartridge']),
        twist: boxOf(['twister']),
      };
    });
    console.log('boxes:', JSON.stringify(boxes));

    async function shot(f, cam, tgt) {
      await page.evaluate(([c, t]) => {
        window._camera.position.set(c[0], c[1], c[2]);
        window._controls.target.set(t[0], t[1], t[2]);
        window._controls.update();
      }, [cam, tgt]);
      await page.waitForTimeout(450);
      await page.screenshot({ path: path.join(SHOT_DIR, f) });
      console.log('Shot:', f);
    }

    // Drum centre world ≈ root(-100,0,55) + local(100,60,-30) = (0,60,25).
    // Twister world ≈ (-100+172, 17, 55-30) = (72,17,25). Tape lane y≈13.
    const D = [0, 60, 25], T = [72, 17, 25], MID = [36, 38, 25];
    await shot('v49_audit_iso.png', [170, 150, 190], MID);
    // SIDE = gear-plane view (look along Z at the drum shaft + duplicate 50T).
    await shot('v49_audit_side.png', [0, 60, 240], D);
    // TOP (look down at tape lane + bevels underneath).
    await shot('v49_audit_top.png', [36, 320, 25], MID);
    // END-ON = along tape axis X (bevels under lane blocking flow).
    await shot('v49_audit_endon.png', [330, 30, 25], [40, 25, 25]);
    // FRONT (from -Z, back-wall side where drum40 lives).
    await shot('v49_audit_front.png', [0, 60, -190], D);
    // Tape-lane closeup: low end-on through the transit showing bevel stack under ribbon.
    await shot('v49_audit_tapelane.png', [250, 32, 60], [45, 18, 25]);

    // Duplicate-gear proof: world positions of drum40 (cartridge gear, back)
    // vs chassis 50T (front-interior) — both coaxial on the drum shaft.
    const dup = await page.evaluate(() => {
      function boxOf(id) {
        const box = new THREE.Box3();
        (window._partMeshes[id] || []).forEach(g => g.traverse(m => {
          if (m.isMesh && m.geometry && m.geometry.attributes.position) {
            m.updateWorldMatrix(true, false);
            box.expandByObject(m);
          }
        }));
        const s = box.getSize(new THREE.Vector3()), c = box.getCenter(new THREE.Vector3());
        return { c: c.toArray(), s: s.toArray() };
      }
      return { cart: boxOf('cartridge'), chas: boxOf('chassis') };
    });
    console.log('dup-proof:', JSON.stringify(dup));
    console.log('errors:', errors.length, errors);
    await page.close();
  } finally {
    await pool.releaseBrowser(browser);
  }
})().catch(e => { console.error('AUDIT FAILED:', e); process.exit(1); });
