const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');

const SHOT_DIR = path.join(__dirname, 'screenshots');
const SHOTS = [
  {
    file: 'step4_takeup_leader_iso.png',
    visibleIds: ['takeup', 'tape'],
    frameIds: ['takeup'],
    includeLeader: true,
    direction: [0.35, 0.80, 1.40]
  },
  {
    file: 'step4_chassis_south_wall_iso.png',
    visibleIds: ['chassis', 'south_wall'],
    frameIds: ['chassis', 'south_wall'],
    direction: [1.20, 0.90, 1.10]
  },
  {
    file: 'step4_takeup_east_margin.png',
    visibleIds: ['takeup', 'chassis', 'south_wall'],
    frameIds: ['takeup', 'chassis', 'south_wall'],
    direction: [1.60, 0.55, 0.20]
  },
  {
    file: 'step4_takeup_leader_top.png',
    visibleIds: ['takeup', 'tape'],
    frameIds: ['takeup'],
    includeLeader: true,
    direction: [0.05, 1.80, 0.02]
  },
  {
    file: 'step4_full_assembly_iso.png',
    visibleIds: null,
    frameIds: null,
    direction: [1.20, 0.90, 1.10]
  }
];
const failures = [];

function check(condition, message) {
  console.log((condition ? 'PASS ' : 'FAIL ') + message);
  if (!condition) failures.push(message);
}

function closeTo(actual, expected, tolerance = 0.01) {
  return Math.abs(actual - expected) <= tolerance;
}

function pruneScreenshots() {
  fs.mkdirSync(SHOT_DIR, { recursive: true });
  const pngs = fs.readdirSync(SHOT_DIR)
    .filter(file => file.endsWith('.png'))
    .map(file => ({ file, modified: fs.statSync(path.join(SHOT_DIR, file)).mtimeMs }))
    .sort((a, b) => a.modified - b.modified);
  while (pngs.length > 20) {
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
    check(viewerState.assetVersion === '98', 'ASSET_V=98 got ' + viewerState.assetVersion);
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
          return {
            meshCount,
            minX: worldBounds.min.x - rootPosition.x,
            maxX: worldBounds.max.x - rootPosition.x
          };
        });
      });
      return state;
    }, ['chassis', 'south_wall', 'takeup']);
    ['chassis', 'south_wall', 'takeup'].forEach(id => {
      check(partState[id].length > 0 && partState[id].every(group => group.meshCount > 0),
        id + ' has loaded meshes');
    });
    ['chassis', 'south_wall'].forEach(id => {
      check(partState[id].length > 0 && partState[id].every(group =>
        closeTo(group.minX, -34, 0.05) && closeTo(group.maxX, 300, 0.05)),
        id + ' root-local X bounds are -34..300');
    });

    const hasTapePartDef = await page.evaluate(() => Boolean(window._partMeshes.tape));
    check(!hasTapePartDef, 'procedural tape has no loaded tape PART_DEF');

    const debugState = await page.evaluate(() => ({
      tape: {
        len: window._tapeDebug.len,
        cx: window._tapeDebug.cx,
        x0: window._tapeDebug.x0,
        flatEnd: window._tapeDebug.flatEnd
      },
      leader: {
        x0: window._windLeader.x0,
        x1: window._windLeader.x1,
        z1: window._windLeader.z1,
        packCx: window._windLeader.packCx,
        packCz: window._windLeader.packCz,
        packR: window._windLeader.packR
      },
      takeup: window._pivots.takeup.position.toArray()
    }));
    check(debugState.tape.len === 234 && debugState.tape.cx === 103
      && debugState.tape.x0 === -14 && debugState.tape.flatEnd === 220,
    'procedural tape debug is len234/cx103/x0-14/flatEnd220');
    check(debugState.leader.x0 === 218 && debugState.leader.x1 === 272.5
      && debugState.leader.z1 === 42.5 && debugState.leader.packCx === 274
      && debugState.leader.packCz === 50 && debugState.leader.packR === 8,
    'wind leader debug is 218..272.5/42.5 at pack 274/50 r8');
    check(debugState.takeup.every((value, index) =>
      closeTo(value, [274, 50, -34][index])),
    'takeup pivot is (274,50,-34), got ' + JSON.stringify(debugState.takeup));

    async function readRotations() {
      return page.evaluate(() => ({
        crank: window._crankSpinner.rotation.z,
        takeup: window._pivots.takeup.rotation.z
      }));
    }
    await page.evaluate(() => { window._overrideAngle = 0.35; });
    await page.waitForTimeout(150);
    const rotationsA = await readRotations();
    await page.evaluate(() => { window._overrideAngle = 1.25; });
    await page.waitForTimeout(150);
    const rotationsB = await readRotations();
    const takeupRatio = (rotationsB.takeup - rotationsA.takeup)
      / (rotationsB.crank - rotationsA.crank);
    check(Math.abs(takeupRatio - (-2)) <= 0.03,
      'takeup/crank rotation ratio is -2, got ' + takeupRatio.toFixed(4));
    await page.evaluate(() => { window._overrideAngle = null; });

    pruneScreenshots();
    await page.evaluate(() => {
      window._setPanelCollapsed(true);
      document.getElementById('panel').style.display = 'none';
      document.getElementById('panelToggle').style.display = 'none';
    });

    for (const shot of SHOTS) {
      await page.evaluate(({ filename, visibleIds, frameIds, includeLeader, direction }) => {
        const assemblyIds = Object.keys(window._toggleGroups).filter(id => id !== 'axes');
        const selectedVisibleIds = visibleIds === null ? assemblyIds : visibleIds;
        window._setOnlyVisible(selectedVisibleIds);

        const selectedFrameIds = frameIds === null ? assemblyIds : frameIds;
        const frameObjects = [];
        selectedFrameIds.forEach(id => {
          const group = window._toggleGroups[id];
          if (!group) throw new Error('Missing toggle group for ' + id);
          group.objects.forEach(object => {
            if (object) frameObjects.push(object);
          });
        });
        if (includeLeader) frameObjects.push(window._windLeader.mesh);

        window._root.updateMatrixWorld(true);
        const bounds = new THREE.Box3();
        frameObjects.forEach(object => bounds.union(new THREE.Box3().setFromObject(object)));
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
      }, {
        filename: shot.file,
        visibleIds: shot.visibleIds,
        frameIds: shot.frameIds,
        includeLeader: shot.includeLeader === true,
        direction: shot.direction
      });
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
