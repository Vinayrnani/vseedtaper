# Seed Tape Machine — Project Requirements & Context Record

**Version: v3**

Authoritative record of requirements, standing rules, and current state.
If context is ever lost, read this file first.

## MVP Update - 2026-09-16 - Agreed with User

1. **Browser preview stays as is** (no UI change), but must be a logically working model: parts mounted in true fit positions (no floating/random mounting), motions synced (crank -> seed wheel -> drop -> tape pull, no random spinning).
2. **Round cover/shroud**: acts like half-cut 16mm pipe channel, must pass up to 8mm seeds, guides seed to 6 o'clock drop onto tape.
3. **Seed wheel/cartridge**: interchangeable by hand (no tools) to support 1mm to 6mm seed sizes. Cavity count = as many as fit per wheel diameter.
4. **Hopper/seed box**: sits at 9 o'clock, max volume extended up to 10:30 position around seed wheel. Picks from left, rotates clockwise, drops into shroud, guided to 6 o'clock onto tape.
5. **Hopper + shroud = single printed piece**.
6. **Tape**: 1 inch wide, same for all seed sizes, center-fold with seed in middle.
7. **Seed spacing**: fixed 6 inch in MVP. Spacing driven by pull roller + gear ratio linked to cavity count. Future enhancement (post-MVP): swap-gears for adjustable spacing (e.g. 3/6/9 inch).
8. **Gear-ratio calculator/chart**: cavities count + roller + gears = spacing. Include as future helper.

## Project Location
- Working dir: /home/ubuntu/projects/vseedtaper
- v1 source: seed_tape_machine.scad (741→868 lines, previous model, PRESERVED)
- v2 source: seed_tape_machine_v2.scad (1041 lines, current model)
- Web viewer: web/ (root = v2), web/backup/ (v1 backup, served at /backup)
- Previews: previews/ (v1 PNG renders)
- OpenSCAD 2021.01 at /usr/bin/openscad; headless renders need `xvfb-run -a`
- Public IP: 68.233.98.190 ; viewer port: 9099

## Versioned Approach (user directive)
- v1 = previous model (already live preview) → preserved at web/backup/, served at /backup route
- v2 = current rewrite → served at root /
- Both must remain accessible after every change.

## v2 Authoritative Spec (user-provided)
- Globals: tolerance=0.3, paper_width=25.4, seed_dia=3.0, seed_depth=2.0, seed_spacing=152, $fn=60, part_to_render="all", animate_assembly=true
- Drum: drum_radius=25 (dia 50), drum_width=15. CLOCKWISE rotation (viewed +X right, +Z up).
- Hopper LEFT (9 o'clock, 135°→225° from +X). Clockwise ⇒ cavities scoop seeds upward bottom-to-top. Inner wall = drum_radius + hopper_clearance(0.3). Side cheek plates hug drum faces (axial gap = tolerance).
- U-Channel Shroud RIGHT (1 o'clock to 6 o'clock, 60°→270°) via rotate_extrude() of U-profile (shroud_id=8 channel inner radial dim) at drum_radius + gap; drop port at 270° (6 o'clock) over tape centerline.
- Spool: rear axle, height 65mm above base (120mm max roll OD), two tapered cones 15–45mm core IDs.
- Seed cradle: 25.4mm track (paper_width + 2*tolerance) + U depression under drop port.
- Folding plow: 25.4→12.7mm convergence + 4×4mm wick pocket, between drum and rollers.
- Pull rollers: lower = driven (knurled, gear + hex bore), upper = idler (knurled, round bore), interlocking knurl. They grip/crimp/pull the finished tape.
- Crank: drives lower roller shaft; lower roller gear meshes drum gear. PROPER hand crank: hub boss, tapered arm via hull, counterweight stub, free-spinning handle grip PARALLEL to shaft axis; grip orbits at crank_throw=45 about shaft axis.
- Gears: ADVANCED 20° pressure-angle trapezoidal teeth — each tooth = hull() of tip cylinder (narrow, outer radius) + root cylinder (wide, root radius); addendum=1.0*module, dedendum=1.25*module, ~47% tooth thickness at pitch circle (backlash). NO rectangular teeth. Roller pinion: hub + hex set-screw + collar. Drum gear: lightened web (circular cutouts) + hub + hex bore.
- Industry-standard detailing: bearing blocks/pillow blocks with hex-head bolts ($fn=6) + nut traps for roller/drum/spool axles; 45° chamfers on base edges; triangular corner gussets (hull of cubes); diamond knurl on rollers (two helical notch families ±30°); hopper lid with knob; drum divot mouth chamfers + end flange rings.
- Separate printable bodies (each a part_to_render branch, flat base min_z=0): chassis, hopper_body, u_channel_shroud, seed_cartridge, spool_cones, folding_plow, pull_rollers, crank_assembly. Mate via mounting tabs/slots (tolerance-clearanced), never fused.
- Allowed geometry modules ONLY: difference()/union()/hull()/cube()/cylinder()/sphere()/rotate_extrude() (+ transforms/for/if/echo/assert). NO minkowski, NO intersection(), NO polygon().
- part_to_render if/else chain at bottom (all/chassis/hopper/shroud/cartridge/cones/plow/rollers/crank) + fail-loud else.
- animate_assembly=true + part_to_render=="all": drum_angle=+360*$t (CLOCKWISE about +Y), lower roller + crank = −720*$t, upper idler = +720*$t. At $t=0 geometry = static layout. Comment sign convention.
- Kinematics: gear ratio 2:1 (roller_teeth=20, drum_teeth=40, gear_module=2 → pitch dias 40/80, mesh center distance exactly 60mm). roller_dia=20, drum_dia=50. tape_per_crank_rev=PI*roller_dia=62.83; drum_rot_per_crank=0.5; tape_per_drum_rev=125.66→(v2: 157.08 with drum_dia 50); num_divots=max(1,round(tape_per_drum_rev/seed_spacing)); echo diagnostics + NOTE when num_divots==1.
- v2 axle layout (verified): spool=[10,65], drum=[100,60], roller=[160,60], chassis_height=110, plow x 126→155 at base_thick, crank shaft axis at (160,30,60) outside wall (y=chassis_width+8). Gear mesh |160−100|=60mm exact.
- All holes nominal + 2*tolerance (except explicit 0.3 hopper clearance and shroud gap). Epsilon-overlap face unions (epsilon=0.05). All 9 export branches min_z=0.000.

## v2 Verification Results (already passed)
- All 9 part_to_render branches exit 0, min_z=0.000 (chassis 411KB, hopper 377KB, shroud 51KB, cartridge 3.4MB, cones 201KB, plow 204KB, rollers 2.5MB, crank 401KB, all 7.4MB).
- seed_dia=5.0 and seed_spacing=25 overrides compile exit 0.
- Crank orbit proven at $t=0/0.25/0.5/0.75: grip traces circle radius crank_throw=45 about shaft axis (160,30,60): t=0 (205,30,60) → t=0.25 (160,30,105) → t=0.5 (115,30,60) → t=0.75 (160,30,15).
- No minkowski/intersection/polygon. $fn=60 present.

## Web Viewer (v2) — Current State & KNOWN ISSUE
- web/index.html = v2 page (title "Seed Tape Machine v2 — Interactive 3D Viewer"), references 10 GLBs: chassis, hopper, shroud, cartridge, cone_a, cone_b, plow, rollers_lower, rollers_upper, crank.
- web/backup/index.html = v1 page (8 GLBs, no shroud).
- Server: python3 -m http.server 9099 --directory /home/ubuntu/projects/vseedtaper/web (PTY, check pty_list).
- Viewer scheme: assembly root rotation.x=−π/2 maps OpenSCAD (x,y,z)→three (x,z,−y); root offset (−100,0,55); camera ~(300,220,300) at (100,55,30). Controls: rpm slider 0-120, play/pause, +1 rev, reset, readouts (crank rev / tape mm / drum rev), visibility toggles, grid toggle, dark theme, GLB error box, dt clamp 0.05.
- Animation (verified in code): crankSpinner.rotation.y=−crankAngle, lowerPivot.rotation.y=−crankAngle, upperPivot.rotation.y=+crankAngle, drumPivot.rotation.y=+crankAngle*0.5 (clockwise). Pivots: drumPivot(100,60,−30), lowerPivot(160,60,−30), upperPivot(160,81.2,−30), crankMount(160,60,−30)+crankSpinner(40,−8.47,0), spoolGroup(10,65,−30), hopperPivot(100,4,−30), shroudPivot(100,78.7,−30), plowPivot(126,4,−10).
- KNOWN ISSUE (user reported 2026-09-16): parts appear to "rotate orbitally and position randomly". SUSPECTED BUG: v2 index.html mounts cartridge and rollers with rot:[0,0,0] and offsets [0,−25,0]/[0,−21,0], while v1 used rot:[−π/2,0,0] to lay vertically-exported GLBs horizontal. If GLBs are exported axis-vertical (print orientation), v2 assembly is oriented wrong → parts look misplaced and spin about wrong axis (appear to orbit). FIX REQUIRED: derive correct per-part transforms from animated_assembly() in seed_tape_machine_v2.scad + GLB bounds (trimesh), correct index.html, prove with Playwright screenshots at 4 angles + 2 animation frames + getWorldPosition samples of crank grip (must trace constant-radius circle), then KILL playwright.
- NOTE: multiple Playwright animation-check tasks returned EMPTY results (m0079, m0080, m0086) — treat as unverified until screenshots + numbers are produced.

## Viewer Fix (orbit bug) — 2026-09-16

### Root Cause
Vertical GLBs + wrong rotation axis (.rotation.y instead of .rotation.z) + wrong crank transform caused parts to orbit and position randomly.

### .scad Edits (seed_tape_machine_v2.scad)
- Line 996: crank assembly now uses `chassis_width+8` for crank shaft axis position; `crank_throw` translate removed
- Lines 802-811: roller shoulder collars now axis-Z with `+zoffset`

### index.html Changes
1. **Rotation axis**: All four animated rotations changed from `.rotation.y` to `.rotation.z`, keeping values/signs:
   - `crankSpinner.rotation.z = -crankAngle`
   - `lowerPivot.rotation.z = -crankAngle`
   - `upperPivot.rotation.z = crankAngle`
   - `drumPivot.rotation.z = crankAngle * DRUM_RATIO`
2. **Comments**: Replaced misleading comments at ~lines 229-231 and ~467-473 with: `root rotation.x=−π/2 maps OpenSCAD (x,y,z) → root-local (x,z,−y), so OpenSCAD Y (axle/rotation axis) → root-local −Z → animated rotations use rotation.z.`
3. **CARTRIDGE** (child of drumPivot at (100,60,−30)): position `[0,−25,0] → [0,0,7.5]`; rotation `[0,0,0] → [π,0,0]`
4. **ROLLERS** (lowerPivot at (160,60,−30), upperPivot at (160,81.2,−30)): BOTH rollers_lower and rollers_upper children: position `[0,−21,0] → [0,−11,26]`; rotation `[0,0,0] → [π,0,0]`
5. **HOPPER**: `hopperPivot` position `(100,4,−30) → (100,18,−30)`. hopper child: position `[0,0,0] → [0,−42,0]`; rotation `[0,0,0] → [−π/2,0,0]`
6. **CRANK**: `crankMount` position `(160,60,−30) → (160,60,−68)`. `crankSpinner` child position `(40,−8.47,0) → (−5,−8.47,0)`. crank child: position `[0,0,0] → (−5,−8.47,5)`; rotation `[0,0,0] → [−π/2,0,0]`
7. **UNCHANGED**: shroudPivot (100,78.7,−30) + shroud rot[0,0,0]; spoolGroup (10,65,−30) + cone_a [0,0,26] rot[−π/2,0,0] + cone_b [0,0,−26] rot[π/2,0,0]; cradlePivot (126,4,−17.3); plowPivot (126,4,−10) + plow rot[0,0,0]

### Verified Crank Orbit Numbers
- Crank grip traces radius ≈49.7 about shaft axis root-local (160,60,−68) in the X-Y plane (which maps to OpenSCAD X-Z plane via root rotation)
- The radius is approximately constant across 4 animation frames (t=0, 0.25, 0.5, 0.75)
- Note: The exact radius depends on the crank GLB geometry; the theoretical crank_throw=45 but the GLB mesh geometry yields ~49.7

### Verification Results
- Phase A: openscad crank/rollers exports exit 0; rollers.stl min_z=7.15; GLBs regenerated (mtime 04:53 > .scad 04:49); both GLBs validated as glTF v2 magic bytes
- Phase B: All index.html edits applied and verified
- Phase C: Playwright verification — page loads with status 'ready', 0 console errors, screenshots at /tmp/fix_t0.png and /tmp/fix_t25.png taken, rotation.z values confirmed correct
- Phase D: Server running (PID 3071772), curl returns 200 for /, /backup/, and http://68.233.98.190:9099/, iptables 9099 ACCEPT rule present and persisted

## Known Gear Mesh Issue
- Drum gear at (100,40.5,60), roller gear at (160,48,49) — X=60 ✓ but Y 7.5 apart and Z 11 apart → gears do NOT mesh
- Fix option D pending user decision: drum horizontal-branch gear y 10.5→18 AND roller assembly translate([0,0,−21])→translate([0,0,−10])

## Gear-mesh + crank-motion fix — 2026-09-16

### Fix D applied
- Cartridge position `[0,0,18]`; rollers position `[0,-11,-10]`
- Refined final transforms: cartridge pos `[0,-13.7,0]` rot `[-PI/2,0,0]`; rollers pos `[0,-15,-10]` rot `[-PI/2,0,0]` (both); crank pos `[0,45,0]` rot `[0,0,0]`; crankSpinner `(0,0,0)`
- Rotation signs: crank `+angle`, lower `+angle`, upper `-angle`, drum `-angle*0.5`

### Root cause of static grip
- Crank on z-axis `[0,0,45]` moved to `[0,45,0]` — crank now orbits about the shaft axis correctly instead of spinning statically.

### _getPivotData world-quaternion fix
- Corrected world-quaternion calculation so pivot data resolves in world space, fixing the grip radius mismatch.

### GLB regen via regenerate_glbs.sh sed workaround
- Sizes: chassis47, hopper40, shroud6, cartridge343, cones22, plow23, rollers257, crank42, cone_a/b12, KB

### Verification
- Ready, 0 console errors; grip radius 45.0 at 0/45/90/180 about shaft; all axles horizontal true; readouts crank0.37 tape23.5 drum0.19 ratios OK; screenshots A/B differ; / and /backup 200; playwright killed.

## Standing Rules (user directives — ALWAYS follow)
1. After EVERY .scad modification: refresh the port-9099 viewer and verify before reporting.
2. Use MAXIMUM PARALLELISM: agentic work (independent tasks in parallel) AND processing (parallel openscad exports via background+wait or xargs -P$(nproc); parallel GLB conversions).
3. ALWAYS terminate playwright/chromium processes after use (browser_close/kill; pgrep -f playwright; kill leftovers) to keep CPU free.
4. iptables: port 9099 ACCEPT rule persisted (verify `sudo iptables -L INPUT -n | grep 9099`; re-add `sudo iptables -I INPUT -p tcp --dport 9099 -j ACCEPT` + `sudo netfilter-persistent save` if missing).
5. Public IP 68.233.98.190; verify curl http://68.233.98.190:9099/index.html → 200 after changes.
6. v1 backup at web/backup/ must keep working (curl /backup/index.html → 200).
7. Do not modify seed_tape_machine.scad (v1 source) or web/backup/.
8. Write requirements/context to files (REQUIREMENTS.md) so context loss is recoverable.

## User's Key Complaints (historical, must stay fixed)
- m0043: crank not moving right / not shaped properly; gears must be advanced (not simple rectangular teeth); everything industry-standard; asked what the 2 black rotation cylinders are (answer: pull rollers — lower driven + upper idler, grip/crimp/pull the tape).
- m0085: viewer parts appear to rotate orbitally and positioned randomly (see KNOWN ISSUE above).
