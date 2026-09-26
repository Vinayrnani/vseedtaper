const path = require('path');
const fs = require('fs');
const pool = require('./playwright_pool');

const SHOT_DIR = path.join(__dirname, 'screenshots');
const SHOTS = [
  {
    file: 'step5_hopper_bosses_iso.png',
    ids: ['hopper', 'bracket_right', 'bracket_left'],
    direction: [0.8, 0.5, 1.2]
  },
  {
    file: 'step5_u_guide_iso.png',
    ids: ['hopper', 'u_guide'],
    direction: [0.4, -0.8, 1.2]
  },
  {
    file: 'step5_bracket_pair_iso.png',
    ids: ['bracket_right', 'bracket_left'],
    direction: [1.6, 0.55, 0.2]
  },
  {
    file: 'step5_m2_interface_side.png',
    ids: ['hopper', 'u_guide', 'bracket_right', 'bracket_left'],
    direction: [0.4, -1.4, 0.5]
  },
  {
    file: 'step5_full_assembly_iso.png',
    ids: null,
    direction: [1.2, 0.9, -1.1]
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
    check(viewerState.assetVersion === '99', 'ASSET_V=99 got ' + viewerState.assetVersion);
    check(viewerState.failures === '', 'viewer load failures are empty');
    check(viewerState.status.includes('ready') && !viewerState.status.includes('failed'),
      'viewer status is ready without load failures');

    const modelState = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const rootPosition = new THREE.Vector3();
      window._root.getWorldPosition(rootPosition);
      const ids = ['hopper', 'u_guide', 'bracket_right', 'bracket_left'];
      const parts = {};
      ids.forEach(id => {
        const groups = window._partMeshes[id] || [];
        parts[id] = groups.map(group => {
          let meshCount = 0;
          group.traverse(object => {
            if (object.isMesh) meshCount++;
          });
          const bounds = new THREE.Box3().setFromObject(group);
          const min = bounds.min.clone().sub(rootPosition);
          const max = bounds.max.clone().sub(rootPosition);
          return {
            meshCount,
            center: [(min.x + max.x) / 2, (min.y + max.y) / 2, (min.z + max.z) / 2],
            size: [max.x - min.x, max.y - min.y, max.z - min.z]
          };
        });
      });
      return {
        parts,
        toggles: ids.map(id => ({
          id,
          exists: Boolean(window._toggleGroups[id]),
          objectCount: (window._toggleGroups[id].objects || []).filter(Boolean).length
        })),
        hook: {
          rebases: window._step5UBracket.rebases,
          mirrorScale: window._step5UBracket.bracketLeftMirrorScale,
          ids: window._step5UBracket.ids,
          files: window._step5UBracket.files,
          noProceduralGuide: window._step5UBracket.noProceduralGuide,
          oldHookPresent: Boolean(window._uBendGuide)
        },
        tape: {
          len: window._tapeDebug.len,
          cx: window._tapeDebug.cx,
          x0: window._tapeDebug.x0,
          flatEnd: window._tapeDebug.flatEnd
        },
        hopperLocalZ: window._pivots.hopper.position.z,
        takeup: window._pivots.takeup.position.toArray()
      };
    });

    ['hopper', 'u_guide', 'bracket_right', 'bracket_left'].forEach(id => {
      const loadedGroups = modelState.parts[id];
      const toggle = modelState.toggles.find(entry => entry.id === id);
      check(loadedGroups.length === 1 && loadedGroups[0].meshCount > 0,
        id + ' has one loaded mesh group');
      check(toggle.exists && toggle.objectCount === 1,
        id + ' has its own one-object toggle group');
    });

    const hook = modelState.hook;
    check(hook.rebases.guide === 7 && hook.rebases.bracket === 10.5
      && hook.rebases.hopper === 10.5, 'Step 5 rebase debug is guide7/bracket10.5/hopper10.5');
    check(hook.mirrorScale[0] === 1 && hook.mirrorScale[1] === 1 && hook.mirrorScale[2] === -1,
      'left bracket mirror scale is [1,1,-1]');
    check(JSON.stringify(hook.ids) === JSON.stringify(['u_guide', 'bracket_right', 'bracket_left'])
      && hook.files.guide === 'stl/u_guide.glb'
      && hook.files.bracketRight === 'stl/u_guide_bracket.glb'
      && hook.files.bracketLeft === 'stl/u_guide_bracket.glb',
    'Step 5 ids and files debug is exact');
    check(hook.noProceduralGuide === true && hook.oldHookPresent === false,
      'procedural U-bend guide is absent');

    const right = modelState.parts.bracket_right[0];
    const left = modelState.parts.bracket_left[0];
    check(Boolean(right && left), 'both bracket groups have bounds');
    if (right && left) {
      check(closeTo(right.center[0], left.center[0], 0.05)
        && closeTo(right.center[1], left.center[1], 0.05),
      'right/left bracket root-local centers share X/Y');
      check(closeTo(modelState.hopperLocalZ, -34, 0.01)
        && closeTo(right.center[2] + left.center[2], 2 * modelState.hopperLocalZ, 0.05),
      'right/left bracket centers mirror about hopper plane Z=-34');
      check(right.size.every((value, index) => closeTo(value, left.size[index], 0.05)),
        'right/left bracket root-local extents match');
    }

    check(modelState.tape.len === 234 && modelState.tape.cx === 103
      && modelState.tape.x0 === -14 && modelState.tape.flatEnd === 220,
    'tape debug regression is len234/cx103/x0-14/flatEnd220');
    check(modelState.takeup.every((value, index) =>
      closeTo(value, [274, 50, -34][index])),
    'takeup pivot regression is (274,50,-34)');

    pruneScreenshots();
    await page.evaluate(() => {
      window._setPanelCollapsed(true);
      document.getElementById('panel').style.display = 'none';
      document.getElementById('panelToggle').style.display = 'none';
    });

    for (const shot of SHOTS) {
      await page.evaluate(({ filename, ids, direction }) => {
        const assemblyIds = Object.keys(window._toggleGroups).filter(id => id !== 'axes');
        const selectedIds = ids === null ? assemblyIds : ids;
        window._setOnlyVisible(selectedIds);

        const frameObjects = [];
        selectedIds.forEach(id => {
          const group = window._toggleGroups[id];
          if (!group) throw new Error('Missing toggle group for ' + id);
          group.objects.forEach(object => {
            if (object) frameObjects.push(object);
          });
        });

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
