// Step 6 verifier: the u_former die, the ruled U-fold tape and the guide seed
// cap, on top of every Step 5 (and Step 4) regression that still applies.
// Structure mirrors verify_step5_u_bracket.js: pool.newPage / pool.releaseBrowser,
// --no-sandbox, PASS/FAIL lines, screenshots/ only.
const path = require('path');
const fs = require('fs');
const { execFileSync } = require('child_process');
const pool = require('./playwright_pool');

const SHOT_DIR = path.join(__dirname, 'screenshots');
const SHOTS = [
  {
    file: 'step6_former_guide_iso.png',
    ids: ['hopper', 'u_guide', 'u_former', 'bracket_right', 'bracket_left'],
    direction: [0.5, -0.9, 1.3]
  },
  {
    // RE-AIMED. This used to be a direction of [0.2, -1.6, 0.15] with NO fixed
    // target: -1.6 in Y aims the camera almost straight DOWN and the auto-fit
    // then framed the whole 234mm ribbon - a top-down PLAN view with the die a
    // few pixels wide. It is now a genuine END-ON view, looking along -X at the
    // die's west mouth from the flat-ribbon side, at the CHANNEL's own height
    // (root-local Y 30.2, inside the 28..35.9 band the channel occupies), with a
    // fixed target on the die's mid-span and a 21mm standoff so the die fills the
    // frame. +X is the packet, so the camera must sit WEST or it ends up inside
    // the 7.9mm packet tube.
    //
    // One honest limitation, measured: the channel is an ENCLOSED tunnel (1.2mm
    // of floor under the paper, 5.8mm of wall each side of a 10.4mm U, 3.2mm of
    // roof over a 7.9mm U), so it has no opening on the top or the sides, and
    // the 25.4mm of paper is wider than the 22mm die - the paper itself hides
    // the west mouth. The SHAPE of the channel is proved by
    // step6_u_cross_section.png, which shows the U it cuts; this shot proves
    // WHERE the channel sits relative to the paper.
    file: 'step6_former_channel_front.png',
    ids: ['u_former', 'tape'],
    direction: [-1, 0.06, 0.05],
    target: [87, 30.2, -34],
    distance: 21
  },
  {
    // THE decisive shot: tape only, looking straight DOWN the tape axis, so the
    // U cross-section is seen END-ON - a trough with two upstanding walls. The
    // earlier iso/front shots never showed the U, so the review read the tape as
    // flat. Fixed root-local target (the auto-framing below would fit the whole
    // 234mm ribbon) and a tight 20mm standoff.
    // Roll consequence: the +X side is now the PACKET (114..220), so a camera
    // sitting 20mm east of x=95.5 would be INSIDE the packet tube looking at its
    // inner wall. The end-on view is therefore taken from the -X (ribbon) side,
    // where only the 0.4mm flat ribbon is below the sight line.
    file: 'step6_u_cross_section.png',
    ids: ['tape'],
    direction: [-1, 0, 0],
    target: [95.5, 32, -34],
    distance: 20
  },
  {
    // THE ROLL, zone 3: tape only, close on the closed packet just past the
    // turner mouth (x 114..130). Framing recovered from the throwaway
    // step6_roll_packet.png by a downsampled-MSE camera search.
    file: 'step6_roll_packet.png',
    ids: ['tape'],
    direction: [0.6, -0.5, 1],
    target: [120, 32, -34],
    distance: 20
  },
  {
    // THE ROLL, zone 2: tape only, the 14mm morph (x 100..114) where the open U
    // closes into the tube - the seam between the two other shots.
    file: 'step6_roll_morph.png',
    ids: ['tape'],
    direction: [0.6, 0.5, 1],
    target: [107, 32, -34],
    distance: 26
  },
  {
    // THE TAIL, station by station. A visual review saw a flat sheet sticking
    // out of the rolled packet and could not tell the legitimate un-wrapped tail
    // from stray geometry, so these four look STRAIGHT DOWN THE ROLL AXIS at one
    // station each, in the same framing discipline as the working
    // step6_u_cross_section.png: tape only, the subject centred, a 20mm standoff
    // so nothing is clipped, the camera west of the section (+X is the packet,
    // so a camera east of it would be inside the 7.9mm tube).
    // SINGLE-STATION ISOLATION is what makes them readable: looking down the
    // axis superimposes every station, and the sections SHRINK with x, so
    // without it each shot would show the widest section in front and hide the
    // subject. So only this station's own mesh is left visible - the flat run,
    // the U prism, the fold, the packet, the other 23 stations and the leader
    // are all switched off for the shot and switched back on afterwards.
    // A tab that SHRINKS and RETREATS into the roll from u25 to u90 is the tail,
    // expected, and the numeric proof is in the envelope table above.
    file: 'step6_roll_tail_u25.png',
    ids: ['tape'],
    direction: [-1, 0, 0],
    station: 6,                     // u = 6/24 = 0.2500
    distance: 20
  },
  {
    file: 'step6_roll_tail_u50.png',
    ids: ['tape'],
    direction: [-1, 0, 0],
    station: 12,                    // u = 12/24 = 0.5000
    distance: 20
  },
  {
    file: 'step6_roll_tail_u75.png',
    ids: ['tape'],
    direction: [-1, 0, 0],
    station: 18,                    // u = 18/24 = 0.7500
    distance: 20
  },
  {
    // u = 0.9 is not a station (the grid is i/24), so this is the nearest one:
    // station 22, u = 0.91667.
    file: 'step6_roll_tail_u90.png',
    ids: ['tape'],
    direction: [-1, 0, 0],
    station: 22,                    // u = 22/24 = 0.9167 (nearest to 0.9)
    distance: 20
  },
  {
    file: 'step6_fold_to_turner_iso.png',
    ids: ['tape', 'plow'],
    direction: [0.35, 0.75, 1.5]
  },
  {
    // THE MOUNTING LOAD PATH, in one frame: chassis + hopper + BOTH grey
    // brackets + the violet die + the tape, seen from the machine's right side
    // and slightly above. Every earlier die shot hid the chassis, so "the die is
    // bolted to the hopper, the hopper sits on the chassis" was unprovable from
    // any image - the die appeared to float in a void. This shot keeps every
    // link of the chain in one frame, which is the whole point of it: a fixed
    // target over the die/hopper junction and a standoff wide enough to hold the
    // chassis plate under it.
    file: 'step6_die_mount_load_path.png',
    // Aimed from the machine's WEST END, level with the tape, because every side
    // view is blocked: the chassis is 125 tall and reaches z = +2 and south_wall
    // is 125 tall at z -70..-47, so the die (z -45..-23) is only visible down
    // the length of the machine.
    ids: ['chassis', 'south_wall', 'hopper', 'u_guide', 'bracket_right', 'bracket_left',
      'u_former', 'tape'],
    direction: [-1, 0.14, 0.1],
    target: [96, 31, -34],
    distance: 130
  },
  {
    // THE SEED CAP, close and side-on, with the guide toggle ON and the tape ON.
    // Root-local Y: the U's outer top is 28 + 7.9 = 35.9, the cap's bottom and
    // top planes are 36.8 and 38.0, the drop pipe's lower OD is 38.4. The camera
    // looks from BELOW the cap (Y -0.55) so the cap's own 10 x 15.8mm roof is
    // seen edge-on and lit, and the U beneath it is in the same frame - the one
    // thing a review could not confirm from any earlier shot, because the cap is
    // FUSED into the u_guide GLB (deliberately, so it cannot float free of the
    // part it caps) and therefore has no toggle, no parts-list row and no
    // silhouette of its own. It is the guide, seen up close, that is the proof.
    // Aimed from the west and ABOVE, not from the side: the near bracket sits at
    // z -26.6..-19 and hides the guide from any pure side view, and the cap is
    // only exposed from above (it sits ON the rails, Y 36.8..38.0, with the
    // rails' top at 36.7). 0.42 up puts the cap's 10 x 15.8mm roof in the upper
    // half of the frame and the U it closes in the lower half.
    file: 'step6_guide_cap_side.png',
    ids: ['hopper', 'u_guide', 'bracket_right', 'bracket_left', 'tape'],
    direction: [-1, 0.42, 0.62],
    target: [101, 33.5, -34],
    distance: 38
  },
  {
    file: 'step6_full_assembly_iso.png',
    ids: null,
    direction: [1.2, 0.9, -1.1]
  }
];
const failures = [];

// STEP 6 (B4): the PRINT artifact, not the viewer GLB, carries the 90-deg
// rotation (regenerate_glbs.sh's print_rot table: "u_former": RX90), because the
// die is a tunnel that cannot be printed in the hopper frame. Nothing else in
// the repo checks a print artifact, so check it here with trimesh: watertight,
// one body, sitting on the bed, and actually rotated - after RX90 the die's
// 12.25mm Z height becomes the print HEIGHT (Y span) and its 22mm Y width
// becomes the print DEPTH (Z span). Unrotated it is the other way round.
function readPrintFormer() {
  const probe = [
    'import json, trimesh',
    "m = trimesh.load('print/u_former.stl')",
    'b = m.bounds',
    'print(json.dumps({',
    "  'watertight': bool(m.is_watertight),",
    "  'winding': bool(m.is_winding_consistent),",
    "  'bodies': int(m.body_count),",
    "  'volume': round(float(m.volume), 3),",
    "  'size': [round(float(v), 3) for v in (b[1] - b[0])],",
    "  'min_z': round(float(b[0][2]), 4)",
    '}))'
  ].join('\n');
  const out = execFileSync('python3', ['-c', probe], { cwd: __dirname, encoding: 'utf8' });
  return JSON.parse(out.trim().split('\n').pop());
}

// THE TAPE, on print/tape.stl. This check was MISSING, and its absence is how a
// non-watertight tape shipped through "81 PASS, 0 FAIL": the file this script
// exists to verify - the U fold and the roll that Step 6 moved under the
// dropper - was never looked at by it. The die was checked; the paper it cuts
// was not.
//
// The four things a boolean chain like seed_tape_bend() can get wrong, each of
// which the CAD's own comments records having actually happened:
//   * watertight - a coplanar abutment instead of a bite leaves an open shell,
//     and OpenSCAD still says "manifold / NoError", so the STL is the only
//     honest witness;
//   * edge multiplicity - the SAME two boundaries are counted per triangle, so
//     a boundary with 2 faces is solid and 4+ is non-manifold. The equal-x
//     station grid alone used to put 32 of them on the y -4.8/-5.2 wall planes
//     at mesh x 114.0..115.2;
//   * zero-area faces - the coplanar overlap OpenSCAD's triangulation cannot
//     resolve emits a zero-area triangle (packet_cap_stagger exists to kill it);
//   * one body - a shell that splits is a shell that prints in pieces.
function readPrintTape() {
  const probe = [
    'import json, trimesh, collections',
    "m = trimesh.load('print/tape.stl')",
    'counts = collections.Counter()',
    'for e in m.edges_sorted: counts[tuple(e)] += 1',
    'hist = collections.Counter(counts.values())',
    'areas = m.area_faces',
    'b = m.bounds',
    'print(json.dumps({',
    "  'watertight': bool(m.is_watertight),",
    "  'winding': bool(m.is_winding_consistent),",
    "  'bodies': int(m.body_count),",
    "  'volume': round(float(m.volume), 3),",
    "  'size': [round(float(v), 3) for v in (b[1] - b[0])],",
    "  'faces': int(len(m.faces)),",
    '  "edges_lt2": int(hist.get(1, 0)),',
    '  "edges_2": int(hist.get(2, 0)),',
    '  "edges_ge3": int(sum(v for k, v in hist.items() if k >= 3)),',
    '  "edges_ge4": int(sum(v for k, v in hist.items() if k >= 4)),',
    "  'zero_area_faces': int((areas <= 0).sum()),",
    "  'min_face_area': float(areas.min()),",
    '}))'
  ].join('\n');
  const out = execFileSync('python3', ['-c', probe], { cwd: __dirname, encoding: 'utf8' });
  return JSON.parse(out.trim().split('\n').pop());
}


function check(condition, message) {
  console.log((condition ? 'PASS ' : 'FAIL ') + message);
  if (!condition) failures.push(message);
}

function closeTo(actual, expected, tolerance = 0.01) {
  return Math.abs(actual - expected) <= tolerance;
}

function pruneScreenshots(max = 20) {
  fs.mkdirSync(SHOT_DIR, { recursive: true });
  const pngs = fs.readdirSync(SHOT_DIR)
    .filter(file => file.endsWith('.png'))
    .map(file => ({ file, modified: fs.statSync(path.join(SHOT_DIR, file)).mtimeMs }))
    .sort((a, b) => a.modified - b.modified);
  while (pngs.length > max) {
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
    const netFailures = [];
    page.on('console', message => {
      if (message.type() === 'error') runtimeErrors.push(message.text());
    });
    page.on('pageerror', error => runtimeErrors.push(error.message));
    page.on('requestfailed', request =>
      netFailures.push(request.url() + ' ' + (request.failure() || {}).errorText));
    page.on('response', response => {
      if (response.status() >= 400) netFailures.push(response.url() + ' HTTP ' + response.status());
    });

    await page.goto('http://localhost:9099/index.html?v=' + Date.now());
    await page.waitForFunction(
      () => document.getElementById('status').textContent.includes('ready'),
      { timeout: 30000 }
    );
    await page.evaluate(() => window._showAllParts());

    // ---------- viewer header (Step 6 asset bump) ----------
    const viewerState = await page.evaluate(() => {
      const assetMatch = document.documentElement.innerHTML.match(/ASSET_V = (\d+)/);
      const errorsElement = document.getElementById('errors');
      return {
        assetVersion: assetMatch ? assetMatch[1] : null,
        status: document.getElementById('status').textContent,
        failures: errorsElement ? errorsElement.textContent.trim() : null,
        hasTapeFoldGlobals: /TAPE_FOLD_/.test(document.documentElement.innerHTML)
      };
    });
    check(viewerState.assetVersion === '100', 'ASSET_V=100 got ' + viewerState.assetVersion);
    check(viewerState.failures === '', 'viewer load failures are empty');
    check(viewerState.status.includes('ready') && !viewerState.status.includes('failed'),
      'viewer status is ready without load failures');
    // Step 6: the old near-roller TAPE_FOLD_* constants are gone from the source.
    check(viewerState.hasTapeFoldGlobals === false,
      'old TAPE_FOLD_* constants are absent from the viewer source');

    // ---------- one big read of the model + the two proof hooks ----------
    const modelState = await page.evaluate(() => {
      window._root.updateMatrixWorld(true);
      const rootPosition = new THREE.Vector3();
      window._root.getWorldPosition(rootPosition);
      const root = window._root;

      function groupStats(id) {
        return (window._partMeshes[id] || []).map(group => {
          let meshCount = 0;
          group.traverse(object => { if (object.isMesh) meshCount++; });
          const bounds = new THREE.Box3().setFromObject(group);
          const min = bounds.min.clone().sub(rootPosition);
          const max = bounds.max.clone().sub(rootPosition);
          return {
            meshCount,
            min: min.toArray(),
            max: max.toArray(),
            center: [(min.x + max.x) / 2, (min.y + max.y) / 2, (min.z + max.z) / 2],
            size: [max.x - min.x, max.y - min.y, max.z - min.z],
            scale: group.scale.toArray(),
            parentIsRoot: group.parent === root,
            hopsToHopperPivot: (() => {
              let node = group.parent, hops = 0;
              while (node && hops < 12) {
                if (node === window._pivots.hopper) return hops;
                node = node.parent; hops++;
              }
              return -1;
            })()
          };
        });
      }

      // ---- u_guide vertex probes (root-local; the guide sits on the hopper) ----
      const guideGroups = window._partMeshes.u_guide || [];
      const guideProbe = { railInnerHalf: null, capHits: [], capX: null, capWalls: null };
      guideGroups.forEach(group => {
        group.updateMatrixWorld(true);
        group.traverse(object => {
          if (!object.isMesh) return;
          const position = object.geometry.attributes.position;
          const v = new THREE.Vector3();
          for (let i = 0; i < position.count; i++) {
            v.fromBufferAttribute(position, i).applyMatrix4(object.matrixWorld);
            const x = v.x - rootPosition.x, y = v.y - rootPosition.y, z = v.z - rootPosition.z;
            // rails + bridge only (hopper-local CAD z 10.5..17.7 -> Y 29.5..36.7),
            // so the seed cap (17.8..19.0) and the floor are excluded.
            if (y > 29.6 && y < 36.7) {
              const half = Math.abs(z + 34);
              if (guideProbe.railInnerHalf === null || half < guideProbe.railInnerHalf) {
                guideProbe.railInnerHalf = half;
              }
            }
            void x; void z; void y;
          }
        });
      });

      // ---- guide seed cap, measured by ray casts ----
      // The cap box spans CAD y +-7.9 but the rails occupy 7.7..9.7, so the cap's
      // own outer faces are fused inside the rails: what the pocket actually
      // shows is its two planes (CAD z 17.8/19.0 -> Y 36.8/38.0), its X walls
      // (guide_x0/x1 -> 95/105) and its side walls, which are the rail inner
      // faces at +-7.7. Probe off the 4.6 seed hole (|CAD y| = 6.0).
      if (guideGroups.length) {
        const rc = new THREE.Raycaster();
        rc.near = 0; rc.far = 300;
        const guideObject = guideGroups[0];
        guideObject.updateMatrixWorld(true);
        // The GLB is FrontSide, so a ray travelling up through the cap pocket only
        // registers the pocket FLOOR: the cap roof and the rail inner walls are
        // back faces for it. Probe with DoubleSide, then restore.
        const sideBackup = [];
        guideObject.traverse(child => {
          if (!child.isMesh) return;
          sideBackup.push([child.material, child.material.side]);
          child.material.side = THREE.DoubleSide;
        });
        // Raycaster works in WORLD space; every probe below is root-local, so it
        // is lifted by the root position and every hit is pushed back.
        function cast(rootLocalOrigin, direction) {
          rc.set(new THREE.Vector3(rootLocalOrigin[0] + rootPosition.x,
              rootLocalOrigin[1] + rootPosition.y, rootLocalOrigin[2] + rootPosition.z),
            new THREE.Vector3(direction[0], direction[1], direction[2]).normalize());
          return rc.intersectObject(guideObject, true);
        }
        const upZ = [-34 - 6.0, -34 + 6.0];
        guideProbe.capHits = upZ.map(z => cast([100, 35, z], [0, 1, 0])
          .map(hit => +(hit.point.y - rootPosition.y).toFixed(4)));
        const west = cast([94, 37.4, -40], [1, 0, 0]);
        const east = cast([106, 37.4, -40], [-1, 0, 0]);
        guideProbe.capX = west.length && east.length
          ? [+(west[0].point.x - rootPosition.x).toFixed(4), +(east[0].point.x - rootPosition.x).toFixed(4)]
          : null;
        // Probe the pocket side walls just BELOW the cap (Y 36.35, i.e. between
        // the U top 35.9 and the cap bottom 36.8): at cap height the guide pad
        // (CAD y 7.7..11, z 11.3..18.7) fills the outer side instead of a wall.
        const nearWall = cast([100, 36.35, -34 - 5], [0, 0, -1]);
        const farWall = cast([100, 36.35, -34 + 5], [0, 0, 1]);
        guideProbe.capWalls = nearWall.length && farWall.length
          ? [+(nearWall[0].point.z - rootPosition.z).toFixed(4),
             +(farWall[0].point.z - rootPosition.z).toFixed(4)]
          : null;
        sideBackup.forEach(entry => { entry[0].side = entry[1]; });
      }

      // ---- hopper drop-pipe lower OD, measured in the |Z+34| <= 5.05 band ----
      let pipeBottomY = null;
      (window._partMeshes.hopper || []).forEach(group => {
        group.updateMatrixWorld(true);
        group.traverse(object => {
          if (!object.isMesh) return;
          const position = object.geometry.attributes.position;
          const v = new THREE.Vector3();
          for (let i = 0; i < position.count; i++) {
            v.fromBufferAttribute(position, i).applyMatrix4(object.matrixWorld);
            const y = v.y - rootPosition.y, z = v.z - rootPosition.z;
            if (Math.abs(z + 34) <= 5.05 && (pipeBottomY === null || y < pipeBottomY)) pipeBottomY = y;
          }
        });
      });

      // ---- fold mesh x-ranges + the u=1 section, measured ----
      const fold = window._tapeFold;
      const foldMeshes = fold.foldMeshes;
      function meshXRange(mesh) {
        const position = mesh.geometry.attributes.position;
        let lo = Infinity, hi = -Infinity;
        for (let i = 0; i < position.count; i++) {
          const x = position.getX(i);
          if (x < lo) lo = x;
          if (x > hi) hi = x;
        }
        return [lo, hi];
      }
      const ranges = foldMeshes.map(meshXRange);
      const foldOnlyEnds = ranges.filter(r => r[1] < 100).map(r => r[1]);
      const segEndX = foldOnlyEnds.length ? Math.max.apply(null, foldOnlyEnds) : null;
      const foldMinX = Math.min.apply(null, ranges.map(r => r[0]));
      const fullU = ranges.find(r => closeToLocal(r[0], fold.foldX1)) || null;
      // u = 1 section: every fold vertex sitting on the last fold segment's far plane
      let sectionZMin = null, sectionZMax = null, sectionYMin = null, sectionYMax = null, sectionVerts = 0;
      if (segEndX !== null) {
        foldMeshes.forEach(mesh => {
          const position = mesh.geometry.attributes.position;
          for (let i = 0; i < position.count; i++) {
            const x = position.getX(i);
            if (Math.abs(x - segEndX) > 1e-4) continue;
            const y = position.getY(i), z = position.getZ(i);
            sectionVerts++;
            if (sectionZMin === null || z < sectionZMin) sectionZMin = z;
            if (sectionZMax === null || z > sectionZMax) sectionZMax = z;
            if (sectionYMin === null || y < sectionYMin) sectionYMin = y;
            if (sectionYMax === null || y > sectionYMax) sectionYMax = y;
          }
        });
      }
      function closeToLocal(a, b) { return Math.abs(a - b) < 0.001; }

      // ---- flat ribbon (paper width + where the flat ends) ----
      // The flat ribbon segments are centred BoxGeometry placed in a group that
      // sits at (TAPE_CX, TAPE_Z, -34), so world matrices are the only honest
      // way to read their X (the fold frusta are absolute and unplaced).
      function rootLocalBounds(object) {
        const box = new THREE.Box3();
        const v = new THREE.Vector3();
        object.updateMatrixWorld(true);
        object.traverse(child => {
          if (!child.isMesh) return;
          const position = child.geometry.attributes.position;
          for (let i = 0; i < position.count; i++) {
            v.fromBufferAttribute(position, i).applyMatrix4(child.matrixWorld);
            box.expandByPoint(v.sub(rootPosition));
          }
        });
        return box;
      }
      const flatBox = rootLocalBounds(fold.flat);
      const flatPaperW = flatBox.max.z - flatBox.min.z;
      const flatGroupXMax = flatBox.max.x;
      const flatSegXMax = rootLocalBounds(fold.flat.children[fold.flat.children.length - 1]).max.x;

      // ---- U top (outer), for the cap clearance ----
      let foldTopY = null;
      foldMeshes.forEach(mesh => {
        const p = mesh.geometry.attributes.position;
        for (let i = 0; i < p.count; i++) {
          const worldY = 28 + p.getY(i);
          if (foldTopY === null || worldY > foldTopY) foldTopY = worldY;
        }
      });

      // ---- Step 6 (B1): the former's M2 pad must be REAL material in the
      // bracket GLB, not a params-only datum. pusher_pad_* = CAD x -14.5..-7.9,
      // y 11..14, z 11.2..17.8. Root-local: X = 100 + CAD x, Y = 19 + CAD z,
      // Z = -34 - CAD y (CAD +Y is the right-hand side of the machine).
      const padProbe = (() => {
        const groups = window._partMeshes.bracket_right || [];
        const box = new THREE.Box3(
          new THREE.Vector3(100 - 14.5 - 0.05, 19 + 11.2 - 0.05, -34 - 14 - 0.05),
          new THREE.Vector3(100 - 7.9 + 0.05, 19 + 17.8 + 0.05, -34 - 11 + 0.05));
        let count = 0;
        groups.forEach(group => {
          group.updateMatrixWorld(true);
          group.traverse(object => {
            if (!object.isMesh) return;
            const position = object.geometry.attributes.position;
            const v = new THREE.Vector3();
            for (let i = 0; i < position.count; i++) {
              v.fromBufferAttribute(position, i).applyMatrix4(object.matrixWorld)
                .sub(rootPosition);
              if (box.containsPoint(v)) count++;
            }
          });
        });
        return count;
      })();

      // ---- THE ROLL, measured off the meshes it BUILT (never off the constants)
      // The roll/packet geometry is written in absolute x and in CAD section
      // coordinates, exactly like the fold frusta below: geometry Y is "up from
      // the tape floor" and geometry Z is "across", so the world Z of a vertex is
      // geometry z + tapeFoldGroup.position.z (-34) - the packet is centred on
      // the tape axis Z=-34, and its across-extent is packet_outer_d 7.9.
      const roll = window._tapeRoll;
      function meshBounds(meshes) {
        let lo = null;
        meshes.forEach(mesh => {
          const p = mesh.geometry.attributes.position;
          for (let i = 0; i < p.count; i++) {
            const v = [p.getX(i), p.getY(i), p.getZ(i)];
            if (!lo) { lo = v.map(() => [Infinity, -Infinity]); }
            for (let a = 0; a < 3; a++) {
              if (v[a] < lo[a][0]) lo[a][0] = v[a];
              if (v[a] > lo[a][1]) lo[a][1] = v[a];
            }
          }
        });
        if (!lo) return null;
        return { count: meshes.length,
          min: lo.map(pair => pair[0]), max: lo.map(pair => pair[1]),
          size: lo.map(pair => pair[1] - pair[0]),
          center: lo.map(pair => (pair[0] + pair[1]) / 2) };
      }
      const foldGroupZ = window._tapeFold.group.position.z;         // -34, the tape axis
      const packetBounds = meshBounds(roll.packetMeshes);
      const morphBounds = meshBounds(roll.rollMeshes);

      return {
        padProbe,
        parts: {
          hopper: groupStats('hopper'),
          u_guide: groupStats('u_guide'),
          u_former: groupStats('u_former'),
          bracket_right: groupStats('bracket_right'),
          bracket_left: groupStats('bracket_left'),
          chassis: groupStats('chassis'),
          south_wall: groupStats('south_wall')
        },
        toggles: ['hopper', 'u_guide', 'u_former', 'bracket_right', 'bracket_left'].map(id => ({
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
        formerHook: {
          part: window._step6Former.part,
          parent: window._step6Former.parent,
          localPos: window._step6Former.localPos,
          scale: window._step6Former.scale,
          glb: window._step6Former.glb,
          worldX: window._step6Former.worldX,
          mirrored: window._step6Former.mirrored
        },
        tape: {
          len: window._tapeDebug.len,
          cx: window._tapeDebug.cx,
          x0: window._tapeDebug.x0,
          flatEnd: window._tapeDebug.flatEnd,
          foldStartX: window._tapeDebug.foldStartX,
          foldEndX: window._tapeDebug.foldEndX,
          stableEndX: window._tapeDebug.stableEndX
        },
        foldHook: {
          flatEndX: fold.flatEndX,
          fullX: fold.fullX,
          stableEndX: fold.stableEndX,
          uSideH: fold.uSideH,
          uFlatZ: fold.uFlatZ,
          tapeThick: fold.tapeThick,
          uOuterW: fold.uOuterW,
          uInnerW: fold.uInnerW,
          topCenterZ: fold.topCenterZ,
          topOuterZ: fold.topOuterZ,
          segments: fold.segments,
          sectionOuterW: fold.sectionOuterW,
          sectionInnerW: fold.sectionInnerW,
          sectionOuterHW: fold.sectionOuterHW,
          surface: fold.surface,
          foldX0: fold.foldX0,
          foldX1: fold.foldX1,
          overlap: fold.overlap,
          ribbonEndX: fold.ribbonEndX,
          transitEndX: fold.transitEndX,
          foldMeshCount: foldMeshes.length,
          groupHasNoParentOffset: fold.group.position.x === 0
        },
        sixTurner: { start: window._sixTurner.start, end: window._sixTurner.end, dropX: window._sixTurner.dropX },
        rollHook: {
          zones: roll.zones,
          uZoneX0: roll.uZoneX0, uZoneX1: roll.uZoneX1,
          morphX0: roll.morphX0, morphX1: roll.morphX1,
          packetX0: roll.packetX0, packetX1: roll.packetX1,
          rollX0: roll.rollX0, rollX1: roll.rollX1,
          packetBoreD: roll.packetBoreD, packetOuterD: roll.packetOuterD,
          packetBoreR: roll.packetBoreR, packetOuterR: roll.packetOuterR,
          packetMeanR: roll.packetMeanR, packetCentreZ: roll.packetCentreZ,
          sampledBoreD: roll.sampledBoreD, sampledOuterD: roll.sampledOuterD,
          packetWrapRad: roll.packetWrapRad, packetWrapDeg: roll.packetWrapDeg,
          packetWrapOverlapDeg: roll.packetWrapOverlapDeg, packetLips: roll.packetLips,
          turnerExitClearR: roll.turnerExitClearR, turnerExitClearD: roll.turnerExitClearD,
          exitClearanceR: roll.exitClearanceR,
          polySeg: roll.polySeg, rollStations: roll.rollStations,
          rollXBite: roll.rollXBite, rollTailDu: roll.rollTailDu,
          segBite: roll.segBite, xBite: roll.xBite, capStagger: roll.capStagger,
          construction: roll.construction
        },
        rollMeshCount: roll.rollMeshes.length,
        // ---- the flat run, the roll's station grid, the material that had to
        // stop being translucent, and the printed parts' metalness - all read
        // off the page, not off this file.
        flatRunHook: fold.flatRun,
        flatRunMeshCount: fold.flat.children.length,
        rollGrid: roll.rollGrid,
        rollGridText: roll.grid,
        lengthGuards: {
          tolerance: roll.tolerance,
          seedDiaMax: roll.seedDiaMax,
          samples: roll.packetLenSamples,
          table: roll.packetLenTable,
          min: roll.packetLenMin,
          tailBackstep: roll.packetLenTailBackstep,
          centrelineU0: roll.packetCentrelineLenU0
        },
        materials: (() => {
          function firstMaterial(id) {
            const group = (window._partMeshes[id] || [])[0];
            if (!group) return null;
            let found = null;
            group.traverse(child => { if (!found && child.isMesh) found = child.material; });
            return found;
          }
          const tape = window._tapeFold.group.children[0].material;
          function entry(id) {
            const m = firstMaterial(id);
            return m ? { metalness: m.metalness, roughness: m.roughness,
              transparent: m.transparent, opacity: m.opacity } : null;
          }
          return {
            tape: { transparent: tape.transparent, opacity: tape.opacity,
              metalness: tape.metalness, depthWrite: tape.depthWrite },
            u_guide: entry('u_guide'), u_former: entry('u_former'),
            bracket_right: entry('bracket_right')
          };
        })(),
        leaderAttach: {
          startX: window._windLeader.startX, startY: window._windLeader.startY,
          attached: window._windLeader.attachedToPacket,
          thickness: window._windLeader.thickness, length: window._windLeader.length
        },
        leader: {
          x0: window._windLeader.x0, x1: window._windLeader.x1, z1: window._windLeader.z1,
          packCx: window._windLeader.packCx, packCz: window._windLeader.packCz, packR: window._windLeader.packR
        },
        hopperLocalZ: window._pivots.hopper.position.z,
        takeup: window._pivots.takeup.position.toArray(),
        hasTapePartDef: Boolean(window._partMeshes.tape),
        guideProbe,
        pipeBottomY,
        measured: {
          segEndX, foldMinX,
          fullUX0: fullU ? fullU[0] : null,
          fullUX1: fullU ? fullU[1] : null,
          sectionOuterW: sectionZMax === null ? null : sectionZMax - sectionZMin,
          sectionHeight: sectionYMax === null ? null : sectionYMax - sectionYMin,
          sectionVerts,
          flatPaperW,
          flatSegXMax,
          flatGroupXMax,
          foldTopY,
          // the roll, measured: packet x-range, packet across-extent and its
          // centre in tape-axis Z, morph x-range. foldGroupZ is the tape axis.
          foldGroupZ,
          packetBounds,
          morphBounds
        }
      };
    });

    // ---------- THE ROLL'S SECTION ENVELOPE, MEASURED OFF THE BUILT MESHES ----
    // A visual review saw a flat sheet sticking out of the rolled packet and
    // could not tell the legitimate UN-WRAPPED TAIL from stray geometry. The
    // roll's section is NOT a solid: tapePolyStStation() draws the 48-segment
    // CENTRELINE polyline lerped from the U to the packet wrap, swept as boxes
    // one paper thick. So the shape of the section at progress u is whatever
    // that polyline is at u - and mid-roll some of the 25.4mm of strip really is
    // still straight and still sticking out. This measures it instead of
    // guessing: every one of the 24 stations' own vertices, in the cross-section
    // plane (geometry y = up from the tape floor, z = across, which is the same
    // (y, z) the CAD's u_poly_point/packet_poly_point produce).
    const tailProbe = await page.evaluate(() => {
      const roll = window._tapeRoll;
      const groupZ = window._tapeFold.group.position.z;   // -34, the tape axis
      const groupY = window._tapeFold.group.position.y;   // 28, the tape floor
      function sectionOf(mesh) {
        const p = mesh.geometry.attributes.position;
        const pts = [];
        for (let i = 0; i < p.count; i++) pts.push([p.getY(i), p.getZ(i)]);
        let minY = Infinity, maxY = -Infinity, minZ = Infinity, maxZ = -Infinity;
        let cy = 0, cz = 0;
        for (const q of pts) {
          if (q[0] < minY) minY = q[0];
          if (q[0] > maxY) maxY = q[0];
          if (q[1] < minZ) minZ = q[1];
          if (q[1] > maxZ) maxZ = q[1];
          cy += q[0]; cz += q[1];
        }
        cy /= pts.length; cz /= pts.length;
        let maxCentroid = 0, maxAxis = 0;
        for (const q of pts) {
          maxCentroid = Math.max(maxCentroid, Math.hypot(q[0] - cy, q[1] - cz));
          // q = [up, across]; the roll axis is packet_centre_z up from the
          // floor, on the tape axis across
          maxAxis = Math.max(maxAxis, Math.hypot(q[1], q[0] - roll.packetCentreZ));
        }
        return { n: pts.length, minY, maxY, minZ, maxZ, centroid: [cy, cz],
          maxCentroid, maxAxis };
      }
      // The U is the WIDEST state the strip is ever in, so it is the envelope
      // every station must sit inside. Read it off zone 1's own built prism (the
      // fold meshes lying in x 91..100), not off a constant.
      let uMinY = Infinity, uMaxY = -Infinity, uMinZ = Infinity, uMaxZ = -Infinity;
      let uPrisms = 0;
      window._tapeFold.foldMeshes.forEach(mesh => {
        const p = mesh.geometry.attributes.position;
        let lo = Infinity, hi = -Infinity;
        for (let i = 0; i < p.count; i++) {
          const x = p.getX(i);
          if (x < lo) lo = x;
          if (x > hi) hi = x;
        }
        // zone 1 is the only fold mesh that REACHES past 99: the 24 fold
        // sections are 0.4167 long and all end by 90.98, and the roll stations
        // are not in foldMeshes at all.
        if (lo > 91.0 || hi < 99.0) return;
        uPrisms++;
        for (let i = 0; i < p.count; i++) {
          const y = p.getY(i), z = p.getZ(i);
          if (y < uMinY) uMinY = y;
          if (y > uMaxY) uMaxY = y;
          if (z < uMinZ) uMinZ = z;
          if (z > uMaxZ) uMaxZ = z;
        }
      });
      return {
        groupY, groupZ, packetCentreZ: roll.packetCentreZ,
        uEnvelope: { minY: uMinY, maxY: uMaxY, minZ: uMinZ, maxZ: uMaxZ, prisms: uPrisms },
        stations: roll.rollMeshes.map((mesh, i) =>
          Object.assign({ i, u: roll.rollGrid[i].u, xa: roll.rollGrid[i].xa },
            sectionOf(mesh)))
      };
    });

    // ---------- THE TAIL: legitimate un-wrapped paper, or stray geometry? -----
    // The roll's section is a 0.4mm RIBBON following the morphed centreline, not
    // a solid, so at fold progress u part of the 25.4mm strip is still straight
    // and still protrudes. That is the CAD's accepted bend-pattern
    // simplification, not stray geometry - and this is the proof, measured off
    // the built meshes rather than argued from the formula. Three things have to
    // be true, and each is checked fail-loud:
    const tp = tailProbe;
    const stations = tp.stations;
    console.log('--- roll section envelope, measured off the built meshes '
      + '(geometry y = up from the tape floor, z = across) ---');
    // minY/maxY are the section's HEIGHT (up from the tape floor); minZ/maxZ are
    // its WIDTH (across the tape). maxR_centroid is reported because the task
    // asks for it, but it is NOT an envelope metric: on a shape closing into a
    // ring the centroid drifts off the axis, so it can RISE while the shape
    // shrinks (it does, at the tail station - see the table). maxR_axis is the
    // envelope.
    console.log('  i     u        maxR_centroid  maxR_axis   up_min   up_max'
      + '   acr_min  acr_max');
    stations.forEach(st => {
      console.log('  ' + String(st.i).padStart(2) + '  ' + st.u.toFixed(4)
        + '   ' + st.maxCentroid.toFixed(4).padStart(12)
        + '  ' + st.maxAxis.toFixed(4).padStart(8)
        + '  ' + st.minY.toFixed(3).padStart(7) + ' ' + st.maxY.toFixed(3).padStart(7)
        + '  ' + st.minZ.toFixed(3).padStart(7) + ' ' + st.maxZ.toFixed(3).padStart(7));
    });

    check(stations.length === 24, 'the tail probe measured all 24 roll stations, got '
      + stations.length);
    const uEnv = tp.uEnvelope;
    // In the geometry frame Y is UP from the tape floor and Z is ACROSS, so the
    // finished U is 0..7.9 up and +-5.2 across (tape_u_w(1) = 5.2 outer half
    // width, u_side_h + tape_thick = 7.9 tall).
    check(uEnv.prisms === 3
      && closeTo(uEnv.maxY - uEnv.minY, 7.9, 0.01)
      && closeTo(uEnv.maxZ - uEnv.minZ, 10.4, 0.01),
      'the U envelope the roll must stay inside is read off zone 1\'s own built '
      + 'prism (' + uEnv.prisms + ' meshes), not off a constant: up '
      + uEnv.minY.toFixed(3) + '..' + uEnv.maxY.toFixed(3) + ', across '
      + uEnv.minZ.toFixed(3) + '..' + uEnv.maxZ.toFixed(3));

    // (1) THE ENVELOPE MUST SHRINK MONOTONICALLY with u. Measured as the max
    // radius of any vertex from the ROLL AXIS, which is the envelope of a shape
    // that closes onto that axis.
    // The tolerance is float32 noise and nothing else. Each box is CENTRED on
    // its polyline segment and is seg_len + packet_seg_bite long, so it reaches
    // packet_seg_bite/2 = 0.05 past each endpoint and half a paper (0.2) across
    // its own normal. BOTH offsets are constant in u: the chord length does not
    // enter, because the box is measured from its segment\'s midpoint and always
    // overshoots the endpoint by the same 0.05. So the built envelope is the
    // polyline\'s, inflated by a fixed 0.05/0.2, and monotonicity can be asserted
    // hard - 0.01 is 10x the float32 noise and an order of magnitude below the
    // tightest real step in the table below.
    const ENVELOPE_TOL = 0.01;
    let envelopeMonotonic = true;
    const envelopeSteps = [];
    for (let i = 1; i < stations.length; i++) {
      const drop = stations[i - 1].maxAxis - stations[i].maxAxis;
      envelopeSteps.push(stations[i].maxAxis.toFixed(4) + ' (' + (-drop).toFixed(4) + ')');
      if (stations[i].maxAxis > stations[i - 1].maxAxis + ENVELOPE_TOL) {
        envelopeMonotonic = false;
      }
    }
    const drops = stations.map((st, i) => i ? stations[i - 1].maxAxis - st.maxAxis : 0)
      .slice(1);
    const tightestStep = Math.min.apply(null, drops);
    const loosestStep = Math.max.apply(null, drops);
    check(envelopeMonotonic,
      'the roll section\'s envelope SHRINKS MONOTONICALLY with u: max radius from the '
      + 'roll axis ' + stations[0].maxAxis.toFixed(4) + ' (u=0, the U) -> '
      + stations[stations.length - 1].maxAxis.toFixed(4) + ' (u=1, the packet), no step '
      + 'up by more than ' + ENVELOPE_TOL + '; the 23 real steps run '
      + tightestStep.toFixed(4) + '..' + loosestStep.toFixed(4)
      + ' mm, i.e. the envelope retreats by very nearly the same amount at every '
      + 'station, which is what a wrapping strip does and a stray tab cannot');
    // (2) ACROSS THE STRIP (minZ/maxZ) the extent is NOT monotonic, and must not
    // be: it narrows to a minimum mid-roll and comes back out to the packet's own
    // 7.9, exactly as the height does. What must hold is that it never necks in
    // past the seed bore - the narrowest the roll ever gets across is the number
    // that says a seed can still fall down the middle of it. minZ/maxZ are the
    // ACROSS extents here; minY/maxY are the height (see the table header).
    const across = stations.map(st => st.maxZ - st.minZ);
    const acrossMin = Math.min.apply(null, across);
    const acrossMinIdx = across.indexOf(acrossMin);
    const seedBoreD = 7.1;                 // seed_bore_d, the packet's own bore
    check(acrossMin > seedBoreD
      && across[0] > across[across.length - 1]
      && closeTo(across[across.length - 1], 2 * modelState.rollHook.packetOuterR, 0.01),
      'the section never necks shut across: it runs '
      + across[0].toFixed(3) + ' (the U) -> ' + acrossMin.toFixed(3) + ' at u='
      + stations[acrossMinIdx].u.toFixed(4) + ' (its tightest, mid-wrap) -> '
      + across[across.length - 1].toFixed(3)
      + ' at u=1 (the packet\'s own 2*packet_outer_r), and stays '
      + ((acrossMin - seedBoreD) / 2).toFixed(3)
      + ' mm of paper either side of the seed bore at its narrowest');

    // (3) NO SECTION POINT MAY SIT OUTSIDE THE U - the U is the widest state the
    // strip is ever in, so anything past it is stray geometry by definition.
    let worstExcursion = 0, worstAt = null;
    stations.forEach(st => {
      const over = Math.max(uEnv.minY - st.minY, st.maxY - uEnv.maxY,
        uEnv.minZ - st.minZ, st.maxZ - uEnv.maxZ);
      if (over > worstExcursion) { worstExcursion = over; worstAt = st.i; }
    });
    // 0.001 is float32 noise on a 7.9mm coordinate (~1e-7 relative), not slack:
    // every box floor sits on z = 0 and round-trips through a
    // Float32BufferAttribute. A stray tab past this box is a real millimetre.
    check(worstExcursion <= 0.001,
      'NO roll section point sits outside the U envelope (the widest state the strip '
      + 'is ever in): worst excursion ' + worstExcursion.toExponential(2) + ' mm'
      + (worstAt === null ? '' : ' at station ' + worstAt));

    // (4) The tail must actually CLOSE - a stub that never wraps would keep the
    // U's envelope. The last station\'s radius must be well inside the U's, and
    // the closure must be a real closure, not a rounding.
    const firstR = stations[0].maxAxis, lastR = stations[stations.length - 1].maxAxis;
    check(lastR < firstR - 2,
      'the tail genuinely closes: the last station\'s envelope radius is ' + lastR.toFixed(4)
      + ' against the U\'s ' + firstR.toFixed(4) + ' - a closure of '
      + (firstR - lastR).toFixed(4) + ' mm, and the packet itself is only r '
      + modelState.rollHook.packetOuterR.toFixed(2) + ' + half a paper');

    // (5) maxZ IS NOT monotonic, and that is the wrap working, not stray geometry:
    // the U\'s two wall tops curl inward and DOWN as the strip rolls (7.700 ->
    // 6.368 at u=0.75) and only then does the completed wrap\'s own top rise back
    // over the tube. Recorded as a fact with its numbers so a later reader does
    // not "fix" it. The dip must stay inside the U\'s height, which check (3)
    // already covers; here the shape of the dip is asserted.
    const top = stations.map(st => st.maxY);
    const topMinIdx = top.indexOf(Math.min.apply(null, top));
    const zDip = top[0] - top[topMinIdx];
    const zRecovered = top[stations.length - 1] - top[topMinIdx];
    check(zDip > 0.5 && zRecovered > 0.5
      && topMinIdx > 0 && topMinIdx < stations.length - 1,
      'the section TOP DIPS and recovers exactly as a wrap should (not stray '
      + 'geometry): ' + top[0].toFixed(3) + ' at u=0 (the U\'s two wall tops) -> '
      + top[topMinIdx].toFixed(3) + ' at u=' + stations[topMinIdx].u.toFixed(4)
      + ' (a ' + zDip.toFixed(3) + ' dip, the wall tops curling in and DOWN as the '
      + 'strip rolls) -> ' + top[stations.length - 1].toFixed(3)
      + ' at u=1 (a ' + zRecovered.toFixed(3) + ' recovery, the completed wrap\'s '
      + 'own top rising back OVER the tube) - so the top is NOT monotonic by '
      + 'design, and the envelope radius in check (1) is the metric that is');

    // ---------- Step 4/5 regressions ----------
    const parts = modelState.parts;
    ['hopper', 'u_guide', 'u_former', 'bracket_right', 'bracket_left'].forEach(id => {
      const loadedGroups = parts[id];
      const toggle = modelState.toggles.find(entry => entry.id === id);
      check(loadedGroups.length === 1 && loadedGroups[0].meshCount > 0,
        id + ' has one loaded mesh group');
      check(toggle.exists && toggle.objectCount === 1,
        id + ' has its own one-object toggle group');
    });
    ['chassis', 'south_wall'].forEach(id => {
      const group = parts[id][0];
      check(Boolean(group) && closeTo(group.min[0], -34, 0.05) && closeTo(group.max[0], 300, 0.05),
        id + ' root-local X bounds are -34..300');
    });
    check(!modelState.hasTapePartDef, 'procedural tape has no loaded tape PART_DEF');

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

    const right = parts.bracket_right[0];
    const left = parts.bracket_left[0];
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
      // Step 6 (B1/B2): pusher_pad_x0/x1 -13.7..-8.7 -> -14.5..-7.9 (6.6 square,
      // widened for the 4.4 AF nut trap) and pusher_pad_y1 16.0 -> 14.0 so that
      // trap is open at the pad face. The pad is now a REAL solid in the bracket
      // (u_guide_bracket fuses it into the arm), so what the GLB must prove is
      // (a) vertices actually sit in the pad volume, and (b) the arm still
      // encloses the pad X span (hopper-local -14.5..-7.9 -> root-local
      // 85.5..92.1).
      check(modelState.padProbe >= 8,
        'former M2 pad is real material in the bracket GLB (' + modelState.padProbe
        + ' vertices inside pusher_pad x -14.5..-7.9 / y 11..14 / z 11.2..17.8)');
      check(right.min[0] <= 85.5 + 0.001 && right.max[0] >= 92.1 - 0.001,
        'bracket arm encloses the Step 6 pad X -14.5..-7.9 (root-local 85.5..92.1), got '
        + right.min[0] + '..' + right.max[0]);
    }

    check(modelState.tape.len === 234 && modelState.tape.cx === 103
      && modelState.tape.x0 === -14 && modelState.tape.flatEnd === 220,
    'tape debug regression is len234/cx103/x0-14/flatEnd220');
    check(modelState.tape.foldStartX === 81 && modelState.tape.foldEndX === 91
      && modelState.tape.stableEndX === 114,
    'tape debug Step 6 stations are foldStart81/foldEnd91/stableEnd114');
    check(modelState.takeup.every((value, index) =>
      closeTo(value, [274, 50, -34][index])),
    'takeup pivot regression is (274,50,-34)');
    const leader = modelState.leader;
    check(leader.x0 === 218 && leader.x1 === 272.5 && leader.z1 === 42.5
      && leader.packCx === 274 && leader.packCz === 50 && leader.packR === 8,
    'wind leader regression is 218..272.5/42.5 at pack 274/50 r8');

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

    // ---------- Step 6: fold stations, developed width, both widths ----------
    const fold = modelState.foldHook;
    check(fold.flatEndX === 81 && fold.fullX === 91 && fold.stableEndX === 114,
      'Step 6 tape stations are flatEndX81/fullX91/stableEndX114');
    check(fold.segments === 24 && fold.foldMeshCount === 24 * 3 + 3,
      'Step 6 fold is 24 ruled segments (75 floor+wall meshes), got ' + fold.foldMeshCount);
    check(closeTo(fold.foldX0, 81 - fold.overlap, 1e-6) && closeTo(fold.foldX1, 91 - fold.overlap, 1e-6),
      'fold sweep runs 80.98..90.98 with the 0.02 overlap');
    check(String(fold.surface).indexOf('no convex hull') !== -1,
      'fold surface hook states ruled frusta, no convex hull');

    // BOTH widths, on purpose, each labelled - do not "fix" either number.
    // (a) the params the hook carries, and (b) what the section really builds.
    check(closeTo(fold.uOuterW, 10.8) && closeTo(fold.uInnerW, 10.0),
      'hook PARAMS widths uOuterW/uInnerW = 10.8/10.0 (nominal, unchanged by Step 6), got '
      + fold.uOuterW + '/' + fold.uInnerW);
    check(closeTo(fold.sectionOuterW, 10.4) && closeTo(fold.sectionInnerW, 9.6)
      && closeTo(fold.sectionOuterHW, 5.2),
    'hook BUILT section widths sectionOuterW/sectionInnerW = 10.4/9.6 (outerHW 5.2), got '
      + fold.sectionOuterW + '/' + fold.sectionInnerW + '/' + fold.sectionOuterHW);

    const m = modelState.measured;
    check(closeTo(m.flatPaperW, 25.4, 0.01),
      'MEASURED flat paper width is 25.4, got ' + m.flatPaperW);
    // Developed width: uCenterlineBottomW + 2*u_side_h == paper_width.
    // uCenterlineBottomW is the U floor's outer centreline width (== sectionOuterW).
    check(closeTo(m.sectionOuterW + 2 * fold.uSideH, m.flatPaperW, 0.01),
      'developed width: uCenterlineBottomW ' + m.sectionOuterW + ' + 2*uSideH '
      + (2 * fold.uSideH) + ' == paperWidth ' + m.flatPaperW);
    check(closeTo(fold.sectionOuterW + 2 * fold.uSideH, 25.4, 0.01),
      'developed width identity holds on the hook numbers too (10.4 + 15 = 25.4)');

    // ---------- Step 6: old near-roller fold is gone ----------
    // The flat ribbon is drawn as ONE slab ending at 81, and the fold's first
    // section starts at 80.98 - so the run OVERLAPS the fold by 0.02, exactly as
    // the CAD does: scad/plow.scad sets fold_x0 = flat_end - ovl, and a zero-
    // overlap butt would leave the two solids sharing a whole face, the coplanar
    // abutment the CAD never allows. The CAD's 190 shingles reached 81.05, but
    // only because each shingle overlapped its neighbour by 2*epsilon SO THE
    // BOOLEAN WOULD FUSE; at u=0 the first fold section IS the flat ribbon, so
    // overlapping rather than overshooting loses nothing.
    // BOUND CORRECTED 80.98 -> 81.0 for the overlap above; it is the same
    // assertion, not a new or looser one. Joined by the one-mesh check, because
    // "one slab" IS the banding fix: 95 separate shingles are 95 sets of
    // interior end-caps, and drawn translucent they banded across the flat tape.
    check(closeTo(m.flatGroupXMax, 81, 0.01) && closeTo(m.flatSegXMax, 81, 0.01),
      'flat ribbon ends at X 81, overlapping the fold (which starts at 80.98), got '
      + m.flatGroupXMax + '/' + m.flatSegXMax);
    check(modelState.flatRunMeshCount === 1
      && closeTo(modelState.flatRunHook.x0, -14, 1e-6)
      && closeTo(modelState.flatRunHook.x1, 81, 1e-6)
      && closeTo(modelState.flatRunHook.width, 25.4, 1e-6),
      'the flat run is ONE slab, -14..81 x 25.4 wide, overlapping the fold by 0.02, '
      + 'not N overlapping shingles (got ' + modelState.flatRunMeshCount + ' mesh, hook '
      + JSON.stringify(modelState.flatRunHook) + ')');
    check(m.foldMinX > 80.9,
      'no fold geometry west of X 80.9 (old 37..70 fold is gone), foldMinX=' + m.foldMinX);

    // ---------- Step 6: the U ends at the seed drop, the packet carries on ----------
    // The roll changed the world: the full U now runs 91..100 and stops at
    // roll_x0 = 100, the seed drop, because that is where the paper starts
    // closing. The U prism therefore ENDS at 100 (it used to run unbroken to 114
    // and on past the six-turner), and what passes the six-turner is the closed
    // packet. Both checks below were re-pointed at that, not weakened.
    check(m.fullUX0 !== null && closeTo(m.fullUX0, 90.98, 0.01),
      'full-U prism starts at X 90.98, got ' + m.fullUX0);
    check(m.fullUX1 !== null && closeTo(m.fullUX1, 100, 0.01),
      'the U zone spans exactly 91..100: the full U ends at the seed drop '
      + '(roll_x0 = 100), got xmax ' + m.fullUX1);
    const turner = modelState.sixTurner;
    check(m.packetBounds !== null && m.packetBounds.min[0] <= 114
      && closeTo(m.packetBounds.max[0], 220, 0.11)
      && m.packetBounds.min[0] <= turner.start && m.packetBounds.max[0] >= turner.end
      && turner.start === 126,
    'the PACKET, not the full U, passes the six-turner: it starts at the turner '
      + 'mouth (roll_x1 114) and runs to the ribbon end (220), covering the whole '
      + 'turner ' + turner.start + '..' + turner.end
      + ', measured x ' + (m.packetBounds ? m.packetBounds.min[0].toFixed(3)
        + '..' + m.packetBounds.max[0].toFixed(3) : 'no mesh'));
    // Station 0 now starts roll_x_bite (0.3) BEFORE the drop, so its u is exactly
    // 0 and its section is congruent with the full-U prism instead of grazing it;
    // the tail station finishes exactly on 114. The morph therefore measures
    // 99.7..114, not 100..114 - the same zone, on the new grid.
    check(m.morphBounds !== null && closeTo(m.morphBounds.min[0], 99.7, 0.01)
      && closeTo(m.morphBounds.max[0], 114, 0.01),
    'the morph bridges the U to the packet (measured x '
      + (m.morphBounds ? m.morphBounds.min[0].toFixed(3) + '..'
        + m.morphBounds.max[0].toFixed(3) : 'no mesh') + ')');
    check(closeTo(m.foldTopY, 19 + fold.topOuterZ, 0.01),
      'measured U outer top is the hopper-local u_outer_top_z ' + fold.topOuterZ
      + ' (root-local Y ' + (19 + fold.topOuterZ) + '), got ' + m.foldTopY);

    // ---------- Step 6: THE ROLL, read from window._tapeRoll ----------
    const roll = modelState.rollHook;
    check(Boolean(roll), 'window._tapeRoll proof hook is present');
    // The three zones, exactly as seed_tape_bend() builds them. Every one is
    // fail-loud: a zone boundary moved and the packet no longer meets either the
    // U or the turner, which is silent geometry-wise and obvious in print.
    const zone = (name, x0, x1) => Array.isArray(roll.zones[name])
      && closeTo(roll.zones[name][0], x0, 1e-6) && closeTo(roll.zones[name][1], x1, 1e-6);
    check(zone('u', 91, 100) && zone('morph', 100, 114) && zone('packet', 114, 220),
      'roll zones are exactly u [91,100], morph [100,114], packet [114,220], got '
      + JSON.stringify(roll.zones));
    check(roll.rollX0 === 100 && roll.rollX1 === 114
      && roll.uZoneX0 === 91 && roll.uZoneX1 === 100
      && roll.morphX0 === 100 && roll.morphX1 === 114
      && roll.packetX0 === 114 && roll.packetX1 === 220,
    'roll stations agree with the zones: drop roll_x0 100 / turner mouth roll_x1 114, '
      + 'u ' + roll.uZoneX0 + '..' + roll.uZoneX1 + ', morph ' + roll.morphX0 + '..'
      + roll.morphX1 + ', packet ' + roll.packetX0 + '..' + roll.packetX1);

    // The packet envelope. The CONSTANTS say 7.1/7.9; the SAMPLED values are read
    // back off the wrap polyline's own 49 points, so they are the proof that the
    // POLYLINE is right - a bare constant would still read 7.1/7.9 if the wrap
    // radius, the wrap angle or the centring were wrong. Every sample sits on the
    // mean circle, so the near side (bore) is the centreline radius less half a
    // paper and the far side (outer) is it plus half a paper: one 0.4mm sheet
    // exactly between them. The 0.05 window is for float noise, not slack.
    check(closeTo(roll.packetBoreD, 7.1) && closeTo(roll.packetOuterD, 7.9),
      'packet PARAMS bore/outer diameters are 7.1/7.9, got '
      + roll.packetBoreD + '/' + roll.packetOuterD);
    check(closeTo(roll.sampledBoreD, 7.1, 0.05) && closeTo(roll.sampledOuterD, 7.9, 0.05)
      && closeTo(roll.sampledOuterD - roll.sampledBoreD, 0.8, 0.05),
      'SAMPLED wrap polyline measures the same 7.1/7.9 envelope (one 0.4 paper '
      + 'between them), got bore ' + roll.sampledBoreD.toFixed(4) + ' / outer '
      + roll.sampledOuterD.toFixed(4) + ' over ' + (roll.polySeg + 1) + ' samples');

    // The wrap is DERIVED from the paper, never a hardcoded 360: 25.4 of strip
    // about the mean radius laps 28deg over its own start. A bare 360 would close
    // the tube on a single plane and leave a slit down the packet.
    const derivedWrapDeg = 180 / Math.PI * 25.4 / roll.packetMeanR;
    check(roll.packetWrapDeg > 360 && roll.packetLips === true
      && closeTo(roll.packetWrapDeg, derivedWrapDeg, 1e-6)
      && closeTo(roll.packetWrapOverlapDeg, roll.packetWrapDeg - 360, 1e-6),
    'packet wraps ' + roll.packetWrapDeg.toFixed(2) + ' deg > 360 (derived '
      + derivedWrapDeg.toFixed(2) + ' from paperW/meanR, overlap '
      + roll.packetWrapOverlapDeg.toFixed(2) + ' deg) - it laps over itself, so there '
      + 'is no slit');

    // The handoff the packet has to make: the six-turner's exit bore against the
    // 7.9 packet. turner_exit_clear_r is 4.30 (Ø8.6) in the CAD - the viewer
    // used to carry a stale 4.25 (Ø8.5), which is a desync, and the port fixed
    // it. The CAD measures the real fit from the TURNER's axis, which sits
    // packet_exit_ecc 0.05 above the packet's own, so the governing number is
    // 4.30 - 0.3 = 4.0 against packet_outer_r + 0.05 = 4.0. The nominal gap here
    // is 0.35, and the guard is that it never drops below one tolerance.
    const TOL = 0.3;
    check(closeTo(roll.turnerExitClearR, 4.30) && closeTo(roll.turnerExitClearD, 8.6)
      && closeTo(roll.exitClearanceR, 0.35, 1e-6) && roll.exitClearanceR >= TOL - 1e-6
      && closeTo(roll.turnerExitClearR - roll.packetOuterR, roll.exitClearanceR, 1e-6),
    'six-turner exit clearance is turner_exit_clear_r 4.30 - packet 3.95 = 0.35 '
      + '(>= tol ' + TOL + '), got clearR ' + roll.turnerExitClearR + ' / clearance '
      + roll.exitClearanceR);

    // The roll's construction, so a future hull()/offset() regression is loud.
    check(roll.polySeg === 48 && roll.rollStations === 24
      && roll.segBite > 0 && roll.xBite > 0 && roll.capStagger > 0
      && String(roll.construction).indexOf('no convex hull') !== -1,
    'roll is 48 section segments x 24 x-stations bitten ' + roll.segBite + '/'
      + roll.xBite + ' with caps staggered ' + roll.capStagger
      + ', and the hook states no convex hull');

    // ---------- THE ROLL'S OWN LENGTH GUARDS (packet_len_* in scad/plow.scad) --
    // The bend pattern really is ~30% short at mid-roll: a point-for-point lerp
    // between the 25.0 U centreline and the 25.38 packet wrap does not conserve
    // arc length, and no resample can fix it (resampling only moves samples
    // along the SAME curve, so the length is invariant). The CAD accepts that as
    // a simplification of the fold's PATH only and stands two fail-loud guards in
    // its place. Both are now measurable in the viewer, so they are measurable
    // here - the numbers below are the CAD's own, from its packet_morph_len()
    // block: 25.000 / 20.259 / 17.783 / 20.497 / 25.379.
    const lg = modelState.lengthGuards;
    check(lg && lg.samples === 21 && Array.isArray(lg.table) && lg.table.length === 21,
      'the roll exposes its 21 centreline-length samples (u = 0, 0.05, ... 1.0), got '
      + (lg ? lg.samples : 'nothing'));
    if (lg && Array.isArray(lg.table) && lg.table.length === 21) {
      const at = u => lg.table[Math.round(u * 20)];
      check(closeTo(lg.table[0], 25.0, 0.01) && closeTo(at(0.25), 20.259, 0.01)
        && closeTo(at(0.5), 17.783, 0.01) && closeTo(at(0.75), 20.497, 0.01)
        && closeTo(lg.table[20], 25.379, 0.01),
        'the centreline length table matches the CAD (25.000 / 20.259 / 17.783 / 20.497 '
        + '/ 25.379 against a 25.4 strip), got '
        + [0, 5, 10, 15, 20].map(k => lg.table[k].toFixed(3)).join(' / '));
      check(closeTo(lg.centrelineU0, 25.0, 0.01),
        'u=0 is the full U centreline u_centreline_len 25.0, so the morph starts from '
        + 'the same section zone 1 is built as, got ' + lg.centrelineU0.toFixed(4));
      // GUARD 1: never pinch a seed. seed_dia_max + tolerance = 3.3.
      const seedFloor = lg.seedDiaMax + lg.tolerance;
      check(lg.min > seedFloor,
        'GUARD 1 - the roll never pinches a seed: shortest centreline '
        + lg.min.toFixed(3) + ' > seed_dia_max ' + lg.seedDiaMax + ' + tol '
        + lg.tolerance + ' = ' + seedFloor.toFixed(1) + ' ('
        + (lg.min / seedFloor).toFixed(1) + 'x)');
      // GUARD 2: once the strip starts growing it never shortens again.
      check(lg.tailBackstep <= 0,
        'GUARD 2 - the centreline never shortens over the second half of the roll: '
        + 'worst backstep ' + lg.tailBackstep.toFixed(4) + ' (must be <= 0)');
    }

    // ---------- Step 6: THE ROLL, measured off the meshes it built ----------
    const pb = m.packetBounds;
    check(pb !== null && pb.count === 1 && closeTo(pb.size[2], 7.9, 0.01)
      && closeTo(pb.center[2] + m.foldGroupZ, m.foldGroupZ, 0.01),
    'MEASURED packet mesh is 7.9 across and centred on the tape axis '
      + 'Z=' + m.foldGroupZ + ', got size ' + (pb ? pb.size[2].toFixed(3) : 'n/a')
      + ' centred at Z ' + (pb ? (pb.center[2] + m.foldGroupZ).toFixed(3) : 'n/a'));
    check(pb !== null && closeTo(pb.size[1], 7.9, 0.01)
      && closeTo(pb.min[0], 113.8, 0.06),
    'MEASURED packet mesh is 7.9 tall, riding the U floor datum (packet_centre_z '
      + roll.packetCentreZ + ' above it), and starts a FULL x-bite early at '
      + (114 - roll.xBite) + ' so it bites the last roll station: got y '
      + (pb ? pb.min[1].toFixed(3) + '..' + pb.max[1].toFixed(3) : 'n/a')
      + ', x0 ' + (pb ? pb.min[0].toFixed(3) : 'n/a'));
    const mb = m.morphBounds;
    // The morph starts 0.3 BEFORE the drop (roll_x_bite, so station 0's u is
    // exactly 0 and its section is congruent with zone 1's full U) and ends
    // EXACTLY on 114: the tail station runs on to roll_x1 itself, where
    // u_shape2 is exactly 1.0 and the turner mouth is. It used to overrun to
    // 114 + x_bite, because the old equal-x grid's last station simply ran one
    // more m_dx + bite.
    check(mb !== null && mb.count === 24 && closeTo(mb.min[0], 99.7, 0.01)
      && closeTo(mb.max[0], 114, 0.01),
    'MEASURED morph mesh is ' + mb.count + ' stations spanning 99.7 (= roll_x0 - '
      + roll.rollXBite + ') .. 114 exactly, the tail station finishing on the turner '
      + 'mouth, got ' + (mb ? mb.min[0].toFixed(3) + '..'
        + mb.max[0].toFixed(3) : 'n/a'));

    // ---------- THE ROLL'S STATION GRID: equal FOLD PROGRESS, not equal x ----
    // This is the desync the port fixed. The CAD places its 24 stations at
    // x = roll_x0 + 14*smootherstep_inv(u_i) and the tail at 1 - roll_tail_du.
    // Equal x is NOT a legal fallback: u_shape2 is a smootherstep, so its slope
    // is zero at both ends, and the equal-x grid put the first three stations
    // 0.0046 of the fold apart - sections 0.005mm apart, i.e. coplanar faces
    // grazing past each other, which is the one boundary that turns into
    // zero-area flakes and 4-face edges (the CAD measured 32 of them at mesh x
    // 114.0..115.2). Everything below is compared against the grid the CAD
    // itself would produce, station for station.
    const rollG = modelState.rollHook;        // the same object `roll` names below
    const grid = modelState.rollGrid;
    check(Array.isArray(grid) && grid.length === 24,
      'the viewer exposes its 24 roll stations as built, got '
      + (Array.isArray(grid) ? grid.length : 'nothing'));
    if (Array.isArray(grid) && grid.length === 24) {
      function smootherstepAt(s) { return s * s * s * (s * (s * 6 - 15) + 10); }
      function smootherstepInv(u, lo, hi, n) {
        if (n <= 0) return (lo + hi) / 2;
        return smootherstepAt((lo + hi) / 2) < u
          ? smootherstepInv(u, (lo + hi) / 2, hi, n - 1)
          : smootherstepInv(u, lo, (lo + hi) / 2, n - 1);
      }
      let worstXa = 0, worstU = 0, monotonic = true, contiguous = true;
      let worstLen = 0;
      for (let i = 0; i < 24; i++) {
        const wantU = i < 23 ? i / 24 : 1 - rollG.rollTailDu;
        const wantXa = i <= 0 ? 100 - rollG.rollXBite
          : 100 + 14 * smootherstepInv(wantU, 0, 1, 20);
        const wantXaNext = i + 1 < 23
          ? 100 + 14 * smootherstepInv((i + 1) / 24, 0, 1, 20)
          : 100 + 14 * smootherstepInv(1 - rollG.rollTailDu, 0, 1, 20);
        const wantLen = i < 23 ? wantXaNext - wantXa + rollG.xBite : 114 - wantXa;
        worstXa = Math.max(worstXa, Math.abs(grid[i].xa - wantXa));
        worstLen = Math.max(worstLen, Math.abs(grid[i].len - wantLen));
        worstU = Math.max(worstU, Math.abs(grid[i].u - wantU));
        if (i > 0) {
          if (grid[i].u < grid[i - 1].u - 1e-12) monotonic = false;
          // The section each station BUILDS is the one at its OWN start x. The
          // slack is the bisection's, not a fudge: 20 halvings = 1e-6 in s, and
          // smootherstep's steepest slope is 1.875, so the round trip through
          // smootherstep_inv can differ by at most 1.9e-6 in u.
          if (Math.abs(grid[i].uBuilt - grid[i].u) > 5e-6) contiguous = false;
        }
      }
      // an equal-x grid would put a constant 0.5833 between EVERY pair
      const uniform = grid.slice(1).every((station, k) =>
        Math.abs((station.xa - grid[k].xa) - 14 / 24) < 1e-6);
      check(worstXa < 1e-9 && worstU < 1e-12 && worstLen < 1e-9,
        'every roll station sits on the CAD grid: max |xa - roll_station_xa| '
        + worstXa.toExponential(2) + ', max |u - roll_station_u| ' + worstU.toExponential(2)
        + ', max |len - roll_station_len| ' + worstLen.toExponential(2));
      check(uniform === false,
        'the grid is NOT equal-x any more (that is the whole point: the stations '
        + 'are equal FOLD PROGRESS, so u_shape2\'s zero slope at both ends cannot '
        + 'put two sections 0.005mm apart)');
      check(closeTo(grid[0].xa, 99.7, 1e-9) && closeTo(grid[0].u, 0, 1e-12),
        'station 0 is pinned at roll_x0 - roll_x_bite = 99.7 with u exactly 0, so it '
        + 'is congruent with the full-U prism instead of grazing it, got '
        + grid[0].xa + ' / u ' + grid[0].u);
      const tail = grid[23];
      check(closeTo(tail.u, 1 - rollG.rollTailDu, 1e-12)
        && closeTo(tail.xa + tail.len, 114, 1e-9)
        && rollG.rollTailDu > 0 && rollG.rollTailDu < 0.02,
        'the TAIL station is at u = 1 - roll_tail_du = ' + (1 - rollG.rollTailDu).toFixed(4)
        + ' and finishes exactly on 114, got u ' + tail.u.toFixed(6) + ' ending '
        + (tail.xa + tail.len).toFixed(4));
      check(monotonic && contiguous,
        'the morph is monotonic in x and every station takes its section at its OWN '
        + 'start x (u_shape2 there), as tape_poly_station(xa, len, u_shape2(xa)) does');
      // The bites, on the built grid: consecutive stations overlap by a full
      // packet_x_bite, which is what keeps the chain off a coplanar abutment.
      let minOverlap = Infinity;
      for (let i = 0; i < 23; i++) {
        minOverlap = Math.min(minOverlap, grid[i].xa + grid[i].len - grid[i + 1].xa);
      }
      check(minOverlap > rollG.xBite - 1e-9,
        'consecutive stations overlap by the full x_bite ' + rollG.xBite
        + ' on the built grid, worst ' + minOverlap.toFixed(4));
      check(String(modelState.rollGridText).indexOf('equal fold progress') !== -1,
        'the hook states the grid is equal fold progress');
    }

    // ---------- Step 6: u_former placement, one instance, hopper-supported ----------
    const fh = modelState.formerHook;
    const former = parts.u_former[0];
    check(fh.part === 'u_former' && fh.glb === 'stl/u_former.glb'
      && fh.worldX[0] === 81 && fh.worldX[1] === 91,
    '_step6Former hook is u_former / stl/u_former.glb / worldX 81..91');
    check(fh.parent === 'hopperPivot' && closeTo(fh.localPos[1], 7.85)
      && fh.scale.every(value => value === 1) && fh.mirrored === false,
    '_step6Former is parented to hopperPivot at local Y +7.85, scale 1,1,1, not mirrored');
    check(former.hopsToHopperPivot >= 0 && former.parentIsRoot === false,
      'u_former hangs off hopperPivot (hops=' + former.hopsToHopperPivot
      + '), it is not a free scene object');
    check(former.scale.every(value => value === 1),
      'u_former mesh group scale is 1,1,1 (symmetric: one instance, no mirror)');
    check(closeTo(former.min[0], 81, 0.05) && closeTo(former.max[0], 91.7, 0.05),
      'u_former world X span is 81..91.7, got ' + former.min[0] + '..' + former.max[0]);

    // ---------- Step 6: the guide seed cap + rail move ----------
    const gp = modelState.guideProbe;
    // Step 6 changed the rail/bridge inner face: guide_rail_y0 7.0 -> 7.7 (it now
    // follows the wider 10mm drop-pipe OD with a 2mm gap). Step 5 expected 7.0.
    check(gp.railInnerHalf !== null && closeTo(gp.railInnerHalf, 7.7, 0.02),
      'Step 6: u_guide rail/bridge inner face is 7.7 (Step 5 was 7.0), got ' + gp.railInnerHalf);
    const capBottom = gp.capHits.map(hits => (hits.length === 2 ? hits[0] : null));
    const capTop = gp.capHits.map(hits => (hits.length === 2 ? hits[1] : null));
    check(capBottom.every(value => value !== null && closeTo(value, 36.8, 0.02))
      && capTop.every(value => value !== null && closeTo(value, 38.0, 0.02)),
      'Step 6: guide seed cap planes are hopper-local Z 17.8/19.0 (root-local Y 36.8/38.0) on both '
      + 'sides of the seed hole, ray hits ' + JSON.stringify(gp.capHits));
    check(gp.capX && closeTo(gp.capX[0], 95, 0.02) && closeTo(gp.capX[1], 105, 0.02),
      'seed cap X span is world 95..105 (guide_x0..guide_x1), got '
      + (gp.capX ? gp.capX.join('..') : 'no hit'));
    check(gp.capWalls && closeTo(gp.capWalls[0], -34 - 7.7, 0.02) && closeTo(gp.capWalls[1], -34 + 7.7, 0.02),
      'seed pocket side walls are the rail inner faces at +-7.7 about the hopper plane Z=-34 '
      + '(probed just below the cap) '
      + '(the cap box +-7.9 is fused 0.2 inside the rails 7.7..9.7), got '
      + (gp.capWalls ? gp.capWalls.join('..') : 'no hit'));
    check(closeTo(capBottom[0] - m.foldTopY, 0.9, 0.02),
      'cap bottom clears the U top (u_outer_top_z) by 0.9, got ' + (capBottom[0] - m.foldTopY));
    check(modelState.pipeBottomY !== null && closeTo(capTop[0], modelState.pipeBottomY - 0.4, 0.02),
      'cap top stops 0.4 below the drop-pipe lower OD, got gap '
      + (modelState.pipeBottomY === null ? 'n/a' : (modelState.pipeBottomY - capTop[0])));
    check(parts.u_guide[0].hopsToHopperPivot >= 0,
      'cap geometry lives in the u_guide group, itself under hopperPivot (supported)');

    // ---------- Step 6: ruled-surface regression guard (the hull() bug) ----------
    check(m.sectionVerts > 0 && closeTo(m.sectionOuterW, 10.4, 0.001),
      'MEASURED fold section width at u=1 is 10.4, got ' + m.sectionOuterW);
    check(m.sectionVerts > 0 && !closeTo(m.sectionOuterW, 10.8, 0.001),
      'MEASURED fold section width is NOT the 10.8 a convex hull would produce');
    check(closeTo(m.sectionHeight, fold.uSideH + fold.tapeThick, 0.001),
      'MEASURED fold section height is 7.9 (u_side_h 7.5 + tape_thick 0.4), got ' + m.sectionHeight);

    // ---------- Step 6 (B4): the PRINT artifact (trimesh) ----------
    let printFormer = null;
    try {
      printFormer = readPrintFormer();
      check(printFormer.watertight === true, 'print/u_former.stl is watertight');
      check(printFormer.winding === true, 'print/u_former.stl has consistent winding');
      check(printFormer.bodies === 1,
        'print/u_former.stl is one body, got ' + printFormer.bodies);
      check(printFormer.min_z === 0,
        'print/u_former.stl sits on the print bed (min Z 0), got ' + printFormer.min_z);
      // Rotated: print height = the die's former 12.25 Z height; print depth =
      // its 22 Y width. Unrotated these two swap, which is the whole point of B4.
      check(closeTo(printFormer.size[1], 12.25, 0.01) && closeTo(printFormer.size[2], 22, 0.01),
        'print/u_former.stl is in the printable orientation (height 12.25 = the die Z '
        + 'height, depth 22 = its Y width), got size ' + JSON.stringify(printFormer.size));
    } catch (error) {
      check(false, 'trimesh check of print/u_former.stl ran: ' + error.message);
    }

    // ---------- the wind-up leader: real CAD geometry, and it is attached ----
    // A review read a "thin detached sliver trailing off the tape end". It is the
    // CAD's v45 wind-up leader (seed_tape_bend() step 2): 8mm wide, one paper
    // thick, climbing from the packet at x 218 to the take-up pack at 272.5. It
    // was never degenerate - the packet runs to x 220 and the leader's start face
    // lands at 217.76, INSIDE it, so the two fuse. What made it read as a faint
    // ghost was the old 55%-translucent tape material. Now it is a number.
    const la = modelState.leaderAttach;
    check(la.attached === true && la.startX < 220 && la.startX > 217
      && la.startY > 28 && la.startY < 28 + 7.9
      && closeTo(la.thickness, 0.4, 1e-9) && closeTo(la.length, 56.29, 0.02),
      'the wind-up leader is the CAD v45 leader, attached: its start face sits at ('
      + la.startX.toFixed(2) + ', ' + la.startY.toFixed(2) + ') - inside the closed '
      + 'packet (x < 220, band 28..35.9) - and it is ' + la.length.toFixed(2)
      + ' long x 8 wide x ' + la.thickness + ' thick, not a degenerate sliver');

    // ---------- the tape is OPAQUE, and the printed parts are not polished --
    // Two rendering defects a review found, both with a single root cause each.
    const mats = modelState.materials;
    check(mats.tape.transparent === false && mats.tape.opacity === 1
      && mats.tape.depthWrite === true,
      'the tape material is OPAQUE and depth-writing (was transparent 0.55, which '
      + 'drew every internal face of the overlapping box chain: the 0.1mm shingle '
      + 'end-caps as banding on the flat run, the 48 roll end-cap quads as broad '
      + 'dark planes in the fold), got transparent=' + mats.tape.transparent
      + ' opacity=' + mats.tape.opacity + ' depthWrite=' + mats.tape.depthWrite);
    // There is no scene.environment in this viewer, so a PBR metal has no diffuse
    // term at all and a large flat face renders as a pure black slab. That is
    // what happened to the seed cap (fused into the u_guide GLB) at metalness
    // 0.85. The guide, the die and the brackets are 3D-PRINTED parts, so the
    // truthful material is printed plastic - and every face now has a diffuse
    // term for the key light to shade.
    check(mats.u_guide && mats.u_guide.metalness <= 0.2
      && mats.u_former && mats.u_former.metalness <= 0.2
      && mats.bracket_right && mats.bracket_right.metalness <= 0.2,
      'the printed guide/cap, die and brackets are not polished metal (guide '
      + mats.u_guide.metalness + ', die ' + mats.u_former.metalness + ', bracket '
      + mats.bracket_right.metalness + ' - at 0.85 with no IBL the cap roof rendered '
      + 'as a pure black unlit slab)');

    // ---------- Step 6: the PRINT tape (trimesh) - the check that was MISSING --
    // The die was checked; the paper it cuts was not, and that is how a
    // non-watertight print/tape.stl shipped through a full green run. Five hard
    // checks, all of which a boolean chain of ~1250 overlapping convex solids can
    // genuinely fail, and each of which the CAD's comments records having
    // actually happened at some point.
    let printTape = null;
    try {
      printTape = readPrintTape();
      check(printTape.watertight === true, 'print/tape.stl is watertight');
      check(printTape.winding === true, 'print/tape.stl has consistent winding');
      check(printTape.edges_ge3 === 0,
        'print/tape.stl has no non-manifold boundary: ' + printTape.edges_lt2
        + ' edge(s) seen once, ' + printTape.edges_2 + ' seen twice, '
        + printTape.edges_ge3 + ' seen 3+ times (the equal-x station grid alone once '
        + 'put 32 four-face edges on the y -4.8/-5.2 wall planes at mesh x 114.0..115.2)');
      check(printTape.edges_ge4 === 0,
        'print/tape.stl has no edge shared by 4+ faces, got ' + printTape.edges_ge4);
      check(printTape.zero_area_faces === 0,
        'print/tape.stl has no zero-area faces (a coplanar overlap that OpenSCAD '
        + 'cannot triangulate emits one, and trimesh then calls the whole tape '
        + '"not watertight" even though OpenSCAD said manifold), got '
        + printTape.zero_area_faces + ' over ' + printTape.faces + ' faces, smallest '
        + printTape.min_face_area.toExponential(3));
      check(printTape.bodies === 1,
        'print/tape.stl is ONE body - a shell that splits prints in pieces (the old '
        + 'inverted-shell bug split it into 7), got ' + printTape.bodies);
      check(printTape.volume > 0,
        'print/tape.stl has positive volume ' + printTape.volume + ' mm^3, size '
        + JSON.stringify(printTape.size));
    } catch (error) {
      check(false, 'trimesh check of print/tape.stl ran: ' + error.message);
    }

    // ---------- errors ----------
    check(runtimeErrors.length === 0,
      'zero console/page errors' + (runtimeErrors.length ? ': ' + runtimeErrors.join(' | ') : ''));
    check(netFailures.length === 0,
      'zero failed network requests' + (netFailures.length ? ': ' + netFailures.join(' | ') : ''));

    pruneScreenshots();
    await page.evaluate(() => {
      window._setPanelCollapsed(true);
      document.getElementById('panel').style.display = 'none';
      document.getElementById('panelToggle').style.display = 'none';
    });

    for (const shot of SHOTS) {
      await page.evaluate(({ filename, ids, direction, target, distance, station }) => {
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

        // Single-object isolation for the tail shots: leave ONLY the subject
        // station's cross-section on screen.
        let subject = null;
        if (station !== null && station !== undefined) {
          window._tapeFold.flat.children.forEach(m => { m.visible = false; });
          window._tapeFold.foldMeshes.forEach(m => { m.visible = false; });
          window._tapeRoll.packetMeshes.forEach(m => { m.visible = false; });
          window._tapeRoll.rollMeshes.forEach((m, i) => { m.visible = (i === station); });
          window._windLeader.mesh.visible = false;
          // The two thread-bind LINES belong to no toggle group, so
          // _setOnlyVisible() cannot hide them: a helix of r4.5 at x 176..190
          // seen end-on from 190mm away draws a ~49px white ring right in the
          // middle of these shots. Not tape, but in a shot whose whole question
          // is "is that stray geometry?" it must not be there.
          window._twister.lines.forEach(l => { l.visible = false; });
          subject = window._tapeRoll.rollMeshes[station];
        }

        window._root.updateMatrixWorld(true);
        const offset = new THREE.Vector3(direction[0], direction[1], direction[2]).normalize();
        // WHY THE LIFT: a shot's `target` is written in ROOT-LOCAL coordinates
        // (the same frame every measurement in this file is reported in), but
        // window._camera is NOT a child of root - it hangs off the scene (it has
        // no parent at all), so its position/target are in WORLD space. root
        // itself is translated (root.position = (-100, 0, 55) puts root-local
        // x=0 at world x=-100, z=0 at world z=55), so a target handed straight to
        // window._controls was aimed 100mm west and 55mm short of the part - which
        // is exactly why every fixed-target shot, including
        // step6_u_cross_section.png, framed empty background. The root's WORLD
        // position is read from the page (never hardcoded) and the parent world
        // matrix inverted, so the target lands in whatever space the camera's
        // parent is in. The inverse is the identity for the scene, i.e. the lift
        // by rootWorld, but it stays correct if the camera is ever re-parented.
        const rootWorld = new THREE.Vector3();
        window._root.getWorldPosition(rootWorld);
        window._camera.updateWorldMatrix(true, false);
        const parentInverse = new THREE.Matrix4();
        if (window._camera.parent) {
          parentInverse.copy(window._camera.parent.matrixWorld).invert();
        } else {
          parentInverse.identity();          // a parentless camera is in world space
        }
        const rootOffsetLog = rootWorld.toArray().map(value => +value.toFixed(3));
        let lookTarget, standoff;
        if (subject) {
          // The subject is ONE station's cross-section: centre the shot on that
          // section's own centroid (geometry y = up from the tape floor, z =
          // across, lifted by the fold group's own position) and hold the same
          // 20mm standoff the working step6_u_cross_section.png uses, so the
          // four tail shots are directly comparable to it and to each other.
          const p = subject.geometry.attributes.position;
          let cy = 0, cz = 0;
          for (let i = 0; i < p.count; i++) { cy += p.getY(i); cz += p.getZ(i); }
          cy /= p.count; cz /= p.count;
          const foldGroup = window._tapeFold.group;
          const sx = window._tapeRoll.rollGrid[station].xa;
          lookTarget = new THREE.Vector3(sx, foldGroup.position.y + cy,
            foldGroup.position.z + cz).add(rootWorld).applyMatrix4(parentInverse);
          standoff = distance;
        } else if (target) {
          // Fixed framing: the auto-fit below would swallow the whole 234mm
          // ribbon, which is exactly why the U was invisible in every other
          // shot. Used for the end-on cross-section of the fold and the two roll
          // close-ups.
          lookTarget = new THREE.Vector3(target[0], target[1], target[2])
            .add(rootWorld).applyMatrix4(parentInverse);
          standoff = distance;
        } else {
          const bounds = new THREE.Box3();
          frameObjects.forEach(object => bounds.union(new THREE.Box3().setFromObject(object)));
          if (bounds.isEmpty()) throw new Error('Cannot frame an empty Box3 for ' + filename);
          lookTarget = bounds.getCenter(new THREE.Vector3());
          const radius = bounds.getBoundingSphere(new THREE.Sphere()).radius;
          const verticalHalfFov = THREE.MathUtils.degToRad(window._camera.fov / 2);
          const horizontalHalfFov = Math.atan(Math.tan(verticalHalfFov) * window._camera.aspect);
          const limitingHalfFov = Math.min(verticalHalfFov, horizontalHalfFov);
          standoff = radius / Math.sin(limitingHalfFov) * 1.1;
        }
        // The animate loop calls controls.update() every frame, which re-clamps
        // the orbit radius into [controls.minDistance, controls.maxDistance] -
        // minDistance is 40, so every authored standoff under 40mm (all three
        // close-ups here) was silently stretched. Lift the floor for the shot
        // loop so `distance` means what the shot list says it means, and put it
        // back afterwards.
        const minDistanceBackup = window._controls.minDistance;
        window._controls.minDistance = 1;
        window._camera.position.copy(lookTarget).addScaledVector(offset, standoff);
        window._controls.target.copy(lookTarget);
        window._controls.update();
        window._controls.minDistance = minDistanceBackup;
        window.__shotDebug = { file: filename, rootOffset: rootOffsetLog,
          station: station === null ? null : station,
          stationU: station === null ? null : window._tapeRoll.rollGrid[station].u,
          camera: window._camera.position.toArray().map(v => +v.toFixed(2)),
          target: window._controls.target.toArray().map(v => +v.toFixed(2)),
          standoff: +standoff.toFixed(2) };
      }, {
        filename: shot.file, ids: shot.ids, direction: shot.direction,
        target: shot.target || null, distance: shot.distance || 0,
        station: shot.station === undefined ? null : shot.station
      });
      await page.waitForTimeout(250);
      await page.screenshot({ path: path.join(SHOT_DIR, shot.file) });
      if (shot.station !== undefined) {
        // _setOnlyVisible() only toggles GROUPS, so the per-mesh isolation above
        // has to be undone explicitly or it would leak into every later shot.
        await page.evaluate(() => {
          window._tapeFold.flat.children.forEach(m => { m.visible = true; });
          window._tapeFold.foldMeshes.forEach(m => { m.visible = true; });
          window._tapeRoll.packetMeshes.forEach(m => { m.visible = true; });
          window._tapeRoll.rollMeshes.forEach(m => { m.visible = true; });
          window._windLeader.mesh.visible = true;
          window._twister.lines.forEach(l => { l.visible = true; });
        });
      }
      const shotDebug = await page.evaluate(() => window.__shotDebug);
      console.log('Shot:', shot.file, '| station', shotDebug.station,
        shotDebug.station === null ? '' : ('u=' + shotDebug.stationU.toFixed(4)),
        '| rootOffset', JSON.stringify(shotDebug.rootOffset),
        '| camera', JSON.stringify(shotDebug.camera), '| target', JSON.stringify(shotDebug.target),
        '| standoff', shotDebug.standoff);
    }
    // The shot list grew, so the pre-shot prune (20) is no longer the cap that
    // matters: prune again to the 25-file ceiling with this run's 8 shots in.
    pruneScreenshots(25);

    if (failures.length) {
      console.error('VERIFY FAILED(' + failures.length + '):');
      failures.forEach(failure => console.error(' - ' + failure));
      process.exitCode = 1;
      console.log('RESULT: FAIL');
    } else {
      console.log('VERIFY PASSED');
      console.log('RESULT: PASS');
    }
  } finally {
    await pool.releaseBrowser(browser);
  }
}

run().catch(error => {
  console.error('VERIFY ERROR:', error);
  process.exitCode = 1;
});
