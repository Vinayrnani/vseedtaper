const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');

const SHOT_DIR = path.join(__dirname, 'screenshots');
const SHOTS = [
  { file: 'step3_chassis_iso.png', ids: null, direction: [1.2, 0.9, 1.1] },
  { file: 'step3_chassis_east_end.png', ids: ['chassis', 'south_wall'], direction: [1.8, 0.35, 0.15] },
  { file: 'step3_chassis_top.png', ids: ['chassis', 'south_wall'], direction: [0.05, 1.8, 0.02] },
  { file: 'step3_south_wall_takeup_side.png', ids: ['south_wall', 'takeup'], direction: [0.25, 0.65, 1.4] }
];
const failures = [];

function check(condition, message) {
  console.log((condition ? 'PASS ' : 'FAIL ') + message);
  if (!condition) failures.push(message);
}

function pruneScreenshots() {
  fs.mkdirSync(SHOT_DIR, { recursive: true });
  const pngs = fs.readdirSync(SHOT_DIR)
    .filter(file => file.endsWith('.png'))
    .map(file => ({ file, modified: fs.statSync(path.join(SHOT_DIR, file)).mtimeMs }))
    .sort((a, b) => a.modified - b.modified);
  while (pngs.length > 21) {
    const oldest = pngs.shift();
    fs.unlinkSync(path.join(SHOT_DIR, oldest.file));
    console.log('Pruned:', oldest.file);
  }
}

async function run() {
  const bp = await pool.newPage({ width: 1600, height: 1000 });
  const browser = bp.browser;
  const page = bp.page;

  try {
    const runtimeErrors = [];
    page.on('console', message => {
      if (message.type() === 'error') runtimeErrors.push(message.text());
    });
    page.on('pageerror', error => runtimeErrors.push(error.message));

    await page.goto('http://localhost:9099/index.html?v=' + Date.now());
    await page.waitForFunction(
      () => document.getElementById('status').textContent.includes('ready'),
      { timeout: 30000 }
    );
    await page.evaluate(() => window._showAllParts());

    const viewerState = await page.evaluate(() => {
      const assetMatch = document.documentElement.innerHTML.match(/ASSET_V = (\d+)/);
      const errorsElement = document.getElementById('errors');
      return {
        assetVersion: assetMatch ? assetMatch[1] : null,
        status: document.getElementById('status').textContent,
        failures: errorsElement ? errorsElement.textContent.trim() : null
      };
    });
    check(viewerState.assetVersion === '97', 'ASSET_V=97 got ' + viewerState.assetVersion);
    check(viewerState.failures === '', 'viewer load failures are empty');
    check(viewerState.status.includes('ready') && !viewerState.status.includes('failed'),
      'viewer status is ready without load failures');

    const partState = await page.evaluate(ids => {
      window._root.updateMatrixWorld(true);
      const rootPosition = new THREE.Vector3();
      window._root.getWorldPosition(rootPosition);
      const state = {};
      ids.forEach(id => {
        const groups = window._partMeshes[id] || [];
        state[id] = groups.map(group => {
          let meshCount = 0;
          group.traverse(object => {
            if (object.isMesh) meshCount++;
          });
          const worldBounds = new THREE.Box3().setFromObject(group);
          const localMinX = worldBounds.min.x - rootPosition.x;
          const localMaxX = worldBounds.max.x - rootPosition.x;
          return {
            meshCount,
            minX: localMinX,
            maxX: localMaxX
          };
        });
      });
      return state;
    }, ['chassis', 'south_wall']);
    ['chassis', 'south_wall'].forEach(id => {
      check(partState[id].length > 0 && partState[id].every(group => group.meshCount > 0),
        id + ' has loaded meshes');
      check(partState[id].length > 0 && partState[id].every(group =>
        Math.abs(group.minX + 34) <= 0.05 && Math.abs(group.maxX - 300) <= 0.05),
        id + ' root-local X bounds are -34..300');
    });

    const takeupPosition = await page.evaluate(() => window._pivots.takeup.position.toArray());
    check(takeupPosition.every((value, index) =>
      Math.abs(value - [238, 49, -34][index]) <= 0.01),
      'takeup pivot is (238,49,-34), got ' + JSON.stringify(takeupPosition));

    pruneScreenshots();
    await page.evaluate(() => {
      window._setPanelCollapsed(true);
      document.getElementById('panel').style.display = 'none';
      document.getElementById('panelToggle').style.display = 'none';
    });

    for (const shot of SHOTS) {
      await page.evaluate(({ filename, ids, direction }) => {
        if (ids === null) window._showAllParts();
        else window._setOnlyVisible(ids);

        window._root.updateMatrixWorld(true);
        const selectedIds = ids === null ? Object.keys(window._partMeshes) : ids;
        const bounds = new THREE.Box3();
        selectedIds.forEach(id => {
          (window._partMeshes[id] || []).forEach(group => {
            bounds.union(new THREE.Box3().setFromObject(group));
          });
        });
        if (bounds.isEmpty()) throw new Error('Cannot frame an empty Box3 for ' + filename);

        const target = bounds.getCenter(new THREE.Vector3());
        const radius = bounds.getBoundingSphere(new THREE.Sphere()).radius;
        const verticalHalfFov = THREE.MathUtils.degToRad(window._camera.fov / 2);
        const horizontalHalfFov = Math.atan(Math.tan(verticalHalfFov) * window._camera.aspect);
        const limitingHalfFov = Math.min(verticalHalfFov, horizontalHalfFov);
        const distance = radius / Math.sin(limitingHalfFov) * 1.1;
        const offset = new THREE.Vector3(direction[0], direction[1], direction[2]).normalize();

        window._camera.position.copy(target).addScaledVector(offset, distance);
        window._controls.target.copy(target);
        window._controls.update();
      }, { filename: shot.file, ids: shot.ids, direction: shot.direction });
      await page.waitForTimeout(250);
      await page.screenshot({ path: path.join(SHOT_DIR, shot.file) });
      console.log('Shot:', shot.file);
    }

    check(runtimeErrors.length === 0,
      'zero console/page errors' + (runtimeErrors.length ? ': ' + runtimeErrors.join(' | ') : ''));

    if (failures.length) {
      console.error('VERIFY FAILED(' + failures.length + '):');
      failures.forEach(failure => console.error(' - ' + failure));
      process.exitCode = 1;
    } else {
      console.log('VERIFY PASSED');
    }
  } finally {
    await pool.releaseBrowser(browser);
  }
}

run().catch(error => {
  console.error('VERIFY ERROR:', error);
  process.exitCode = 1;
});
