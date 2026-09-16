# Seed Tape Machine — Project Requirements & Context Record

**Version: v24**

Authoritative record of requirements, standing rules, and current state.
If context is ever lost, read this file first.

## v24 Step 3 R->L Order Proof (hopper > drum > shroud > roller) - 2026-09-16

1. **Goal**: R->L (+X=right tape dir): hopper wedge (right, world
   ~71-185, mouth ~183) > drum (100) > shroud tunnel (58-84, centroid
   ~71) > roller+crank (40). Spool stays far west (-6, outside the
   4-part proof); plow stays east of drum (126->159, v1 precedent).
2. **Shroud verified printable solid** (v22 `u_channel_shroud()` as built,
   not a stub): enclosed channel/cover tunnel, wall 2.0 >= 1.2, top plate
   2.0, sole flanges 4x3 on the base, parts fused (no floating), export
   `part_to_render == "shroud"` standalone with min_z=0, ends open 0..32
   (tape at ~30), top 34 below roller-gear bottom 38 and hopper lip
   ~36.4, d10 side view-ports; `$fn=60`, `tol=0.3`. Only change vs v23 is
   a comment line (geometry untouched).
3. **Spool vs roller-gear graze verified clear, no move**: spool cone A
   at x=-6 (r_big 22.5 -> east face 16.5) vs roller back gear at x=40
   r22 (west face 18, Y 9-15): box-level X gap 1.5, real tapered gap
   ~4.5. Minimal-move rule: keep -6.
4. **Viewer**: shroud PART_DEF + `shroudPivot` (58,0,-30) unchanged and
   correct; `ASSET_V` 11->12; all 12 GLBs rebuilt. Order proof asserts
   hopper_x > drum_x > shroud_x > roller_x in `verify_v24.js`.
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   `center_distance` 60, `gear_mesh_phase` 9°, back gears; crank back wall
   `[40,-8,60]`; port 9099 only. Step 4 (tape bend) / Step 5 (mobile
   panel) NOT started.

Authoritative record of requirements, standing rules, and current state.
If context is ever lost, read this file first.

## v23 Crank to Back Wall (Step 2 miss fix) - 2026-09-16

1. **Miss**: v21 put the crank outside the FRONT wall
   (`[40, chassis_width+8=68, 60]`, grip +Y 78..108); user moved it to the
   OTHER side of the chassis -> outside the BACK wall (`[40,-8,60]`,
   grip mirrored -Y to -18..-48 outward). Coaxial kept
   (`crank_mount_x` = `roller_axle_x` = 40, axle z = 60, orbit r = 45).
2. **CAD** (`seed_tape_machine_v2.scad` only): new `crank_mount_y` = -8 +
   `crank_side` = -1 with fail-loud asserts; `crank_assembly()` mirrors
   arm/grip/counterweight/hub/riser Y by `crank_side` (fusing preserved);
   lower-roller hex shaft moved FRONT (+Y) -> BACK outboard of the pinion
   (tip -34.95 meets the gear outer face through the hex bore, mirrors the
   vertical print stack); gear stays BACK (world Y~12, 9° mesh phase kept).
3. **Viewer**: `crankMount` (40,60,-68) -> (40,60,8) [M(40,-8,60)];
   crank child pos unchanged ([-5,-8.47,0] stays symmetric); rotation signs
   + `GEAR_PHASE` untouched (rigid with lower); `ASSET_V` 10->11.
   Crank + rollers_lower + rollers_upper GLBs rebuilt.
4. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   `center_distance` 60, `gear_mesh_phase` 9°, back gears; port 9099 only.
   Step 4 (tape bend) / Step 5 (mobile panel) NOT started.

Authoritative record of requirements, standing rules, and current state.
If context is ever lost, read this file first.

## v22 R-to-L Order: Shroud Tunnel + Spool West (step 3 of 3) - 2026-09-16

1. **R->L order** (+X=right tape dir): hopper wedge (right, mouth
   ~100-183) > drum (100) > shroud tunnel (58-84, centroid ~71) >
   roller+crank (40) > spool (-6, far west). Plow stays east of drum
   (126->159, v1 precedent); center_distance 60, gear_mesh_phase 9°,
   back-side gears all unchanged from v21.
2. **Shroud is a real part again**: `u_channel_shroud()` rewritten from
   the legacy annular stub into a parametric enclosed tape-cover tunnel
   WEST of the drum (roller nip -> drum exit): local x 0..26 (= world
   58..84), inner width paper+2*tol, walls + top plate + sole flanges on
   the base (flat print base min_z=0), ends open 0..32 (tape at ~30),
   top 34 (below roller gear bottom 38 and hopper cover lip ~36.4),
   round d10 side view-ports; `$fn=60`, `tol=0.3`. Assembly mounts it at
   `[shroud_x0, chassis_width/2, 0]`; export standalone.
3. **Spool graze FIXED (was v21 known graze)**: `spool_axle_x` 10->-6 —
   cone A (tapered ~r19.5 at the gear plane) now sits 46 off the roller
   gear centre in X = ~4.5 real mesh gap, and even the conservative
   full-envelope boxes clear by 1.5 in X, fixing the v21 graze with the
   r22 back gear (Y 9..15). Chassis extended west (`chassis_x0`=-14,
   `chassis_len` 200->214, east edge stays 200) so the spool bearing
   block (-13..1) seats on the base; small cone overhang past the west
   edge matches the v4-accepted precedent. `spool_axle_z`=65 kept.
4. **Viewer**: new `shroudPivot` (58,0,-30) + shroud PART_DEF (child
   [0,0,0]/Rx-90) in PART_ORDER after hopper; spoolGroup x 10->-6;
   `ASSET_V` 9->10; legend notes the R->L layout. All 12 GLBs rebuilt.
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   port 9099 only. Step 4 (tape bend) / Step 5 (mobile panel) NOT started.

Authoritative record of requirements, standing rules, and current state.
If context is ever lost, read this file first.

## v21 Crank + Roller to West Side, Gears Meshed (step 2 of 3) - 2026-09-16

1. **Change**: `roller_axle_x` 160->40 (west of drum, |100-40|=60 exact);
   crank coaxial with roller axle (`crank_mount_x` = 40, outside front wall,
   drives roller not drum). Roller pinion flipped to BACK (-Y, world Y~12,
   same plane as v20 drum gear) in both branches: horizontal assembly
   (mirrored rotation, hub still fuses away from body, shaft stays front
   toward crank) and vertical STL export (gear-down mirror, hub down,
   shaft bottom at min_z=0, taller lift 19.95). Mesh phase
   `gear_mesh_phase` = 9° (20T half-pitch, tooth-into-gap: drum has a tooth
   centered on the line of centers at $t=0) applied to the roller shaft
   (lower + crank) in `animated_assembly`; viewer mirrors it as GEAR_PHASE.
   Signs kept: drum -360*$t, lower +720*$t, upper -720*$t.
2. **Plow fix (was fail-loud broken)**: old `plow_end` = roller-1 went
   39-126 negative and tripped the `plow_len>15` assert, so plow is now a
   fixed 33 long east of the drum (126->159, v1 precedent); cradle/chassis
   holes follow `plow_len` unchanged. Bearing blocks follow `roller_axle_x`
   parametrically. `crank_mount_x` assert is now == roller_axle_x.
3. **Viewer**: lowerPivot/upperPivot x 160->40, crankMount (40,60,-68),
   rollers_lower child pos [0,0,34.95] (gear-down export recenter),
   crankSpinner rigid with lower (`-crankAngle-GEAR_PHASE`), readouts crank
   = roller revs, `ASSET_V` 8->9. No shroud (#3 not started).
4. **Known graze (NOT fixed, later layout pass)**: roller back gear
   (Y 9..15, r22 at x40) vs spool cone A (Y 4..29) overlap in XYZ — check
   closeups; moving the spool is out of scope for #2.
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   port 9099 only.

Authoritative record of requirements, standing rules, and current state.
If context is ever lost, read this file first.

## v20 Drum Gear to Back Side (step 1 of 3) - 2026-09-16

1. **Change**: seed drum gear moved FRONT (+18, world Y~48) -> BACK
   (-18, world Y~12) in `seed_cartridge()`, both branches: assembly
   (offset sign flip + gear rotation re-mirrored so hub still fuses into
   drum face) and vertical STL export (gear web on print base hub-up,
   drum raised, min_z=0 kept). `roller_axle_x`, `crank_mount_x`, hopper
   untouched; `$fn=60`, `tol=0.3`.
2. **Expected**: gear temporarily unmeshed from roller pinion until step 2
   (roller-side move). Viewer: cartridge mount recentered on raised drum,
   `ASSET_V` 7->8.
3. **Frozen**: v1 scad + web/backup/ untouched; port 9099 only.

## v19 Hopper Triangular-Gap Seal - 2026-09-16

1. **Gaps found** (trimesh wall-march probes + OpenSCAD intersection
   markers + Playwright closeups, pre-fix STL): GAP-A — cheek-bottom edge
   (~18deg hull slope) diverged from 8deg floor top, leaving a triangular
   through-slot both sides x45-78, 0-6mm tall (light shone through under
   the nose in viewer); GAP-B — 1mm sliver x14-21 between drum-carve upper
   edge and BLUE fin underside above the cheek-root top (z73); coplanar
   nose/cheek outer faces (y=+-10.3) z-fighting as false seam.
2. **Fix (hopper_body only)**: cheeks deepened (root bottom 53->49, tip
   70.5->59, nub to x84.5) so plates swallow floor sides with 4-6mm
   overlap; floor widened (+-8.3->+-8.8) and lengthened (to x84.5);
   nose enlarged (x78-85, y+-(y_out+0.6), z58-73.5) capping all; new
   root-top gussets (x13-25, z70-79, proud/sunk faces) fusing cheek roots
   to fin band (carve trims r<26, mouth gap 1.0 kept).
3. **Sealed spec**: hopper = ONE solid, open ONLY at top fill + drum mouth
   (gap 1.0) + drop bore. Proof: 24 OpenSCAD intersection markers
   (19 wall + 5 gusset all solid; mouth/void/bore markers all air).
4. **Frozen**: top edge horizontal z73, void ends x70, cover 120-270deg,
   tube/window/bore unchanged; `$fn=60`, `tol=0.3`; port 9099 only.

## v18 Regen speedups + OpenSCAD upgrade - 2026-09-16

1. **Speedups (output-identical)**: persistent Xvfb :99 + plain `openscad`
   in workers (no per-part `xvfb-run`); `--export-format binstl -q` on STL
   exports; single persistent Python (trimesh once, concurrent.futures)
   for STL→GLB; temp .scad files only for DIRTY/FILTER subset.
2. **Upgrade**: try OBS `openscad-nightly` (home:t-paul xUbuntu_24.04,
   has arm64) for manifold backend (`--backend=manifold`, EGL headless
   no-X); fallback `--backend=cgal`; fail fast loud + fallback to 2021.01
   path if nightly missing. Document upgrade command.
3. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   port 9099 only; vendored web/js; `?v=` bump on regen; Playwright
   screenshots/ max 25 + kill chromium after.

## v17 Hopper Mouth Fixes - 2026-09-16 (RED/BLUE/PINK from changes.jpg)

1. **Source of truth**: user mapping spec 2026-09-16 for
   `/home/ubuntu/projects/vseedtaper/changes.jpg` (overrides v15/v16 joint
   approach): RED/BLUE/PINK loops on the hopper pickup mouth + wedge tip.
2. **RED (remove)**: the 2 diagonal side-joint pads (cheek root x14-22 up to
   the 11-o'clock cover lip) are DELETED — their hull chord crossed the
   cavity sweep annulus (r 25-26.5 at the cheek Y strips) and stopped/sheared
   seeds. Nothing spans the mouth middle.
3. **BLUE (extend/connect)**: wedge cheek roots widened x14-20 -> x14-24 and
   new arc side-closure fins per side (r 26.5-28.5, sweep 30->122deg, cheek
   Y strip) saddle-fuse root to cover lip (2deg overlap, same radii).
   Mouth lateral sides closed (seeds hopper->mouth enclosed, can't fall out
   sideways); middle stays open with radial gap 1.0 so 6 cavities + 3mm seeds
   sweep freely; drum OD clears fins by 1.5 (cover-channel spec).
   Structural strength now via BLUE fins + drop-tube saddle fuse (single
   fused hopper object preserved).
4. **PINK (seal)**: apex tip watertight — floor slab runs x16->84 into a
   6-thick nose (x78-84, foot z60, top flush z73); trough void shortened to
   end x70 (8mm solid nose dam); 1mm tip pillar -> 2-wide tip blocks
   overlapping nose. One closed bowl, top open for fill only.
5. **Kept**: top edge horizontal z=73, cover 120->270deg (11->6 o'clock),
   bottom-center drop tube bore 7mm at x=100, CCW drum, left crank r=45,
   open-top trough, single fused hopper.

## Actual changes.jpg Markups Fix - 2026-09-16 (OVERRIDES v14 doc guess)

1. **Source of truth**: `/home/ubuntu/projects/vseedtaper/changes.jpg` read
   directly (photo of slicer preview: green gear/drum left, tan V-wedge arm
   right). Prior v14 doc interpretation was wrong — no red/yellow/pink/blue
   fixes were visible in preview. Verified visually: NO yellow markup present.
2. **What each markup asks (best functional interpretation)**:
   - BLUE (2 strokes along drum<->tan-bracket junction, one over the cover
     lip crown, one diagonal across the drum face) = interface fit: bracket
     stands off the drum -> mouth radial gap tightened 1.0->0.7 (still
     within 0.5-1.0 spec), step tab widened x16-20->x14-22 + side-joint
     hulls widened to seat flush on the 11-o'clock cover lip.
   - RED (small tight loop where the tan support tab lands on the drum) =
     tab interference/pivot: tab sat ON the drum surface -> tab slimmed
     (foot lifted z66->68, top z77->76) so the drum carve fully clears it.
   - PINK/magenta (big loop around far-right V tip + lower wall) = tip
     geometry/wall: apex read blunt/squared, lower wall thin -> apex
     sharpened to top-biased knife edge (end wall 2.0->1.5 wide, foot
     z63->66), lower floor slab thickened 2.5->3.5, folding-plow outlet top
     edge chamfered 30° so tape exits cleanly.
3. **Scope kept**: cover arc 120..270°, bottom-center drop tube, left crank,
   drum, rollers, gears untouched. Only wedge root/tip/tab interface +
   plow outlet tip changed (`seed_tape_machine_v2.scad` only).
4. **Layman summary**: the photo's hand-drawn loops asked for three small
   fit-and-finish fixes where the tan seed-trough arm meets the green seed
   wheel — close the visible gap so the arm hugs the wheel, lift the little
   tab so it can't rub the spinning wheel, and sharpen the far tip while
   making the trough floor sturdier.

## Bottom-Center Drop / 11-to-6 Cover Rebuild - 2026-09-16 - Agreed with User (OVERRIDES v11 tube/cover clocking)

1. **Source of truth**: user feedback spec 2026-09-16 (authoritative, overrides
   v11 tube side + cover arc + wedge top tilt).
2. **WEDGE TOP EDGE EXACTLY HORIZONTAL**: cheek top line level (mouth z=73 to
   apex z=73, 2.5 thick tip) — not tilted. Lower floor keeps +8° tilt about
   the 3-o'clock point to sharp apex (local x=83 / world 183); open-top
   trough between cheeks elongated for volume.
3. **RETENTION COVER 11 o'clock -> 6 o'clock**: annular arc 120..270° (sweep
   150°) about drum axle, wall 2, radial gap 1.5 (within 1.5-2mm smooth
   annular seed channel, no internal ribs/steps from pickup mouth all along
   rotation path to 6-o'clock drop). Top lip free at 11 o'clock (120°);
   bottom lip at 6 o'clock (270°) where drop tube starts. Pickup mouth =
   opening between 11-o'clock lip and 1:30 step tab, right 1:30-3 o'clock,
   radial gap 1.0 (carve r26 vs R25), full inner width.
4. **DROP BOTTOM-CENTER**: vertical 4-wall tube at drum bottom center (local
   x=0 / world x=100, outer x -9..9, bore -3.5..3.5 = 7mm for 3mm seeds,
   full inner width in Y), straight down from 6 o'clock to 0.5 above tape
   (local z0=26.5 / world 30.5; tape ribbon lowered world 35->30 under drum
   for 5mm guided drop). Drum carve auto-trims tube top into smooth
   drum-conforming funnel mouth (rounded seed travel, no ledges); bore void
   pierces cover bottom = drop port; thick walls saddle-fuse to cover lips —
   still ONE single wrap-around hopper object, part_to_render="hopper".
5. **UNCHANGED**: drum CCW (right pickup → top → left → bottom drop at 6),
   left crank direct-drive r=45 (x=77.5, locked to drum), drum axle [100,60]
   R25 W15, tape/rollers/plow/chassis geometry, viewer rotation signs.
   Viewer: dropSeed path at tube exit (100, 30.5→30); tape ribbon y=30;
   legend "drops bottom-center".

Authoritative record of requirements, standing rules, and current state.
If context is ever lost, read this file first.

## Right-Pickup / Left-Drop / Left-Crank Rebuild - 2026-09-16 - Agreed with User (OVERRIDES v10 tube/crank sides)

1. **Source of truth**: user rebuild spec 2026-09-16 (authoritative, overrides
   prior): RIGHT = hopper pickup, LEFT = seed drop, CRANK on LEFT.
2. **PICKUP (RIGHT, unchanged v10)**: sharp-point wedge trough on +X (1:30 step
   tab to 3-o'clock mouth, floor +8° to apex local x=83 / world 183). Mouth
   radial gap 1.0 (carve r26 vs R25), full inner width — cavities scoop freely.
3. **DROP (LEFT, moved from right corner)**: vertical drop tube on LEFT of drum
   (~9 o'clock side, x < drum centre: outer local x −39..−27, bore
   −36.5..−29.5, centre local −33 / world x=67), 4 box walls straight down,
   bore 7 (X) x 15.6 (Y) for 3mm seeds, bottom local z=34 (world 38, just
   above tape at 35). Fed by cavities (not by trough void): drop window cut
   (local x −36..−22, z 48..60, full inner width) connects drum surface
   through the cover arc into the bore top. Old right bore slot removed.
4. **HOPPER still ONE single wrap-around object**: left retention cover arc
   45..240° (wall 2, gap 1.5, fused at 1:30 step tab) + right wedge + left
   drop tube all fused in hopper_body() (tube intersects cover arc
   ~180-200°, union-fused; part_to_render="hopper" unchanged).
5. **CRANK on LEFT (moved from roller axle x=160)**: direct-drive handle on
   drum axle left end: scad crank_mount_x = drum_axle_x − drum_width/2 − 15
   (= 77.5), same Y (chassis_width+8, outside wall) and Z (60) as before;
   rotates WITH the drum (drum_angle, CCW). L-grip, orbit r=45 preserved
   (crank_assembly module untouched; only the assembly mount moved).
   Viewer: crankMount root-local (77.5, 60, −68); crankSpinner.rotation.z =
   +angle*0.5 (CCW, locked to drum); drum/lower/upper unchanged
   (+angle*0.5 / −angle / +angle). Readouts: crank rev = drum rev (direct),
   tape per crank rev = 2·π·20 = 125.66 (drum 1 rev → roller 2 rev).
6. **DRUM rotation unchanged**: CCW (−360*$t, top moves −X/left): picks up on
   the right, carries covered over the top, drops on the left. Viewer keeps
   drumPivot.rotation.z = +angle*0.5.
7. **Preserved**: part_to_render names, drum axle [100,60] R25 W15,
   tape/rollers/plow/chassis geometry, hopper viewer mount (geometry still
   symmetric about drum centre; mount unchanged).

Authoritative record of requirements, standing rules, and current state.
If context is ever lost, read this file first.

## Single Wrap-Around Hopper (No Separate Shroud) - 2026-09-16 - Agreed with User (OVERRIDES v9 hopper/shroud split)

1. **Source of truth**: user rebuild spec 2026-09-16 + `hopper2.jpg` side-view
   outline (drum = center circle, CCW, top moves left). NO separate grey
   shroud part — shroud GLB / viewer toggle removed.
2. **HOPPER = ONE single object** wrapping all around the drum (local frame:
   drum centre [0,0,56], axle along Y):
   a. LEFT retention cover (merged shroud function): annular arc spanning
      45..240° (covers 11→7 o'clock over top/left), wall 2, radial gap 1.5,
      full width 15.6. Top squared end at 1:30 fuses into the step tab;
      bottom end free near 7-8 o'clock. Cavities exit cover into pool, scoop,
      carry covered over top/left.
   b. RIGHT sharp-point wedge trough (unchanged v9): upper wall ~horizontal
      from 1:30 step tab, lower floor +8° about the 3-o'clock point to sharp
      apex (local x=83 / world 183, toward crank side +X). Open-top trough
      between triangular cheeks (width 15.6) for seed fill.
   c. Corner DROP TUBE (unchanged v9): 90° L-step at 3-o'clock mouth corner
      (offset right of centre, ~4-5 o'clock L-corner, tube centre local x=33 /
      world 133), 4 box walls straight down, bore 7 (X) x 15.6 (Y) for 3mm
      seeds, bottom local z=34 (world 38, just above tape at 35).
3. **MOUTH**: radial gap 1.0 (carve r26 vs R25), full inner width — cavities
   scoop freely. Pool retained by floor + chin (gap 1.0 < 3mm seeds).
4. **MIRROR CHECK (user: "thinking in reverse")**: wedge apex extends toward
   +X (crank/roller side, world x 100→183); crank stays RIGHT at x=160 with
   L-handle, grip orbit r=45. Root-local M-frame preserves X, so viewer shows
   wedge on crank side. Verified with side-elevation screenshots from BOTH
   sides (+Z and −Z): wedge+crank coincide on one side, mirrored on the
   other as expected — viewer is NOT mirrored vs sketch.
5. **DRIVE unchanged**: drum CCW (−360*$t, top moves −X/left), crank/lower
   CW (+720*$t), upper idler CCW (−720*$t). Crank right, L-handle, r=45.
6. **Interfaces**: part_to_render="hopper" exports the whole wrap-around part;
   "shroud" branch kept as legacy stub (module untouched, GLB stale on disk,
   NOT loaded by viewer). Drum axle [100,60] R25 W15, tape/rollers/plow/
   chassis geometry untouched, hopper viewer mount unchanged.

Authoritative record of requirements, standing rules, and current state.
If context is ever lost, read this file first.

## Hopper2 Wedge + Corner Drop Tube + Left-C Shroud - 2026-09-16 - Agreed with User (OVERRIDES v8 hopper/shroud/drop)

1. **Source of truth**: `hopper2.jpg` (authoritative): drum CCW (top moves left),
   side view, drum = center circle. Sharp-point wedge hopper on RIGHT, corner
   drop tube, left-only C shroud, all reading as one continuous outline.
2. **HOPPER**: sharp-point wedge/triangle in side view on RIGHT: UPPER wall
   ~horizontal from 1:30 o'clock junction (small squared vertical step/notch
   where it meets the shroud lip) extending right; LOWER wall (floor) from the
   3-o'clock mouth corner angling LITTLE UPWARD (+8° about the 3-o'clock point)
   to meet the upper wall at a sharp point far right (apex x=83 local, world
   183). Open-top trough (no cover slab; side profile carried by triangular
   cheek plates, trough width = drum width 15.6). Elongated horizontally
   (~66 long) for volume.
3. **DROP**: narrow vertical double-wall tube hanging from the 3-o'clock mouth
   corner (offset RIGHT of drum centre, tube centre local x=33 / world x=133):
   lower hopper wall makes a 90° L-step (floor runs horizontal-ish over the
   bore, then 4 box walls drop straight down). Bore 7mm (X) x 15.6 (Y) for 3mm
   seeds. Tube bottom local z=34 (world 38), just above tape (35). NOT at
   6 o'clock. Fused into hopper_body() (feeds from hopper pool) — part_to_render
   names unchanged (hopper/shroud), hopper.glb + shroud.glb stay separate for
   viewer toggles. Viewer dropSeed animation moved to tube exit (133, 38→35).
4. **SHROUD**: left-only C shell spanning +45°..+240° (195° sweep): top squared
   (radial) face at 1:30 where the hopper step tab mates, wrapping over
   top/left down to ~7 o'clock bottom. Thin (wall 2, gap 1.75, width 15.6),
   constant small gap. Print frame axle-Z min_z=0 unchanged; viewer
   shroudPivot/child transform unchanged.
5. **MOUTH**: cavities scoop freely at mouth (drum carve r26 vs R25 = gap 1.0,
   full inner width, no throat/wiper). Pool retained by floor + cheek chin
   (gap 1.0 < 3mm seeds). No shroud-trim boolean needed (wedge approaches drum
   only through the 0..45° mouth window; shroud covers 45..240°).
6. **DRIVE (assumption, noted per user)**: crank stays on RIGHT with gear mesh +
   L-handle (crank.jpg kinematics preserved: drum -360*$t CCW, crank/lower
   +720*$t CW, idler -720*$t). hopper2's left dashed crank circle is schematic
   (behind-shroud direct-drive suggestion) — NOT adopted; moving the crank to
   the spool side would break the roller gear drive.
7. **Preserved**: part_to_render names, drum axle [100,60] R25 W15, crank
   L-handle (orbit r=45), tape/rollers/plow/chassis geometry, hopper/shroud
   viewer mounts (new geometry still symmetric about drum centre; mounts
   unchanged).

## CCW Drum + Right Hopper Rebuild - 2026-09-16 - Agreed with User (OVERRIDES v7 hopper/shroud/direction)

1. **Source of truth**: `crank.jpg` (drum CCW / crank CW external mesh, drum gear
   large ~1.5x, lower small gear + L-handle = radial arm + 90° grip) and
   `hopper.jpg` (right-side open wedge hopper, left shroud, bottom seed drop).
2. **DIRECTION**: drum ANTI-CLOCKWISE (top surface moves -X/left). Crank + lower
   roller CLOCKWISE (opposite via external gear mesh). Upper idler CCW (opposite
   crank via tape contact). scad: drum_angle=-360*$t, crank=+720*$t,
   idler=-720*$t. Viewer rotation.z signs flipped to match (+drum*0.5 CCW,
   -crank/lower CW, +upper CCW). Gear ratio 2:1 unchanged (20T/40T module 2).
3. **HOPPER position/shape**: open V/wedge box trough on RIGHT side (+X, crank
   side), elongated horizontally for volume (~66 long x 15.6 wide x 46 tall,
   open top, no lid/cone). Upper wall meets drum at ~1:30 (45°), lower wall at
   ~3 o'clock (0°) tilted slightly UPWARD to the right (rigid -7° tilt about the
   3-o'clock mouth point, far end rises ~6mm). Mouth WIDE OPEN tangent to drum
   (radial gap 1.0, full inner width 15.6, no throat/wiper) so cavities scoop
   freely. Lower chin retains pool (gap 1.0 < 3mm seeds).
4. **SHROUD**: SAME plain thin 180° shell (gap 1.75, wall 2, width 15.6, no
   tabs/feet/bore/bolts) MIRRORED to the LEFT: spans +60..+240° (2 o'clock lip
   near hopper pool, over top/left, to lower-left near drop). Print frame
   axle-Z min_z=0 unchanged; viewer shroudPivot/child transform unchanged.
5. **SEED DROP**: vertical fall at 6 o'clock (drum bottom x=100) through open
   shroud exit onto tape centerline (cradle + dropSeed animation unchanged).
6. **Preserved**: part_to_render names, drum axle [100,60] R25 W15, crank
   L-handle (radial tapered arm + Y-parallel grip, orbit r=45), tape/rollers/
   plow/chassis geometry, hopper/shroud viewer mounts (mirror bakes into GLB,
   mounts symmetric about drum centre).
7. **Viewer mount fix (found during v8 verify, iteration 1)**: cartridge
   PART_DEFS was [0,-25,0]/[-PI/2,0,0], standing the axle-Z drum GLB vertical
   with centre 17.5 off the drum axle (hop11 screenshots show floating gear +
   hopper gap — pre-existing, v7 "verified" claim was wrong). Restored
   [0,0,7.5]/[PI,0,0] (Rx(180) lays axle onto root-local -Z, drum coaxial with
   drumPivot, bottom at y=35 = tape height, gear plane ≈ roller pinion plane).
   Viewer-only change, no geometry touched.

## Hopper 10:30-11 Rebuild - 2026-09-16 - Agreed with User (OVERRIDES v6 hopper/shroud)

1. **HOPPER position**: sits at 10:30-11 o'clock on drum (top-left, away from
   crank at X=160). Height like Hoppershroud.jpg sketch (~46mm Z extent).
2. **HOPPER shape**: simple elongated BOX TROUGH, stretched horizontally (-X)
   for seed volume (~66 long x 15.6 wide x 46 tall, inner ~61x15.6x38 ≈ 38cm³),
   OPEN TOP (no lid). NO cone/funnel outward protrusion, no tapered chute, no
   lid/knob, no legs, no joint flange, no hex holes (axle at x=0 sits outside
   trough, xMax=-8).
3. **HOPPER mouth**: WIDE OPEN mouth tangent to drum surface (contact zone
   ~114-157°, centre ~135° = 10:30), full inner width 15.6mm, NO narrow throat,
   NO wiper, NO constriction. Radial gap 1.0mm (carve r26 vs drum R25) clears
   cavity chamfer protrusion 0.6mm; cavities (d3.6 = seed_dia+2*tol, depth 2mm)
   scoop seeds directly from pool. Lower chin auto-formed by carve retains pool
   (min gap 1.0 < 3mm seeds).
4. **SHROUD**: SAME plain thin 180° shell (gap 1.75, wall 2, width 15.6, no
   feet/bore) MINUS flange tabs + M3 holes (removed per "cover only"), clocked
   -60° about axle to span -60..+120° (5 o'clock over top to 11 o'clock lip).
   Lip at 120° meets hopper pool; cavities exit shroud into pool, scoop, carry
   covered over top/right, exit at -60° dropping toward tape. No viewer
   PART_DEFS change (rotation baked about module axle, min_z=0 kept).
5. **Preserved**: drum clockwise (top moves +X), part_to_render names,
   drum axle [100,60] R25 W15, hopper local frame (drum centre [0,0,56]).
6. Viewer verified: drum+hopper+shroud isolated, mouth at 10:30-11, no cone,
   0 console errors, screenshots /tmp/hop11_*.png.

## Hopper/Shroud Rebuild (Sketch) - 2026-09-16 - Agreed with User

1. **Source of truth**: user's hand sketch `Hoppershroud.jpg` (drum circle, top
   curved shroud, right-side hopper-shroud connection joint, tapered bottom hopper
   chute). Sketch photo is rotated; text below is authoritative.
2. **SHROUD**: plain thin curved cover hugging drum over ~180 deg top, constant
   small gap 1.75mm, wall 2, width = drum_width + 2*tolerance. No feet, no bore,
   no bolts in shell. Flange tabs with M3 holes at both shell ends (joint side
   mates hopper flange). Print orientation = axle-Z (as before); viewer
   Rx(-90) maps the 180-360 deg sweep onto the drum top.
3. **HOPPER** (one part, drum center local [0,0,hopper_axis_z], axle Y):
   a. Top = OPEN funnel, no lid/knob: wide inlet (top) tapering to narrow outlet
      right of drum (9mm+ mouth passes 8mm seeds) + thin left guide wall feeding
      the drum tangent point at ~0-15 deg under the shroud start.
   b. Bottom = tapered box chute tangent to drum bottom (top face at drum
      bottom tangent plane), wide inlet narrowing to mouth over tape centerline
      (world z ~4-10, under drum bottom world z=35). Mouth >=9mm for 8mm seeds.
   c. Slim cheek plates hug drum faces (axial gap = tolerance) with hex axle
      clearance; funnel outlet + chute pass between cheeks.
4. **CONNECTION JOINT**: hopper funnel-right tab + shroud end tabs, all with M3
   (3.6 clearance) vertical holes, meeting at drum 3-o-clock region.
5. **Removed**: legs, foot pads + bolts, rim flange, lid + knob, square
   drop-tube + bore, wiper slot. Hex axle clearance kept (axle passes through).
6. **Interfaces intact**: part_to_render names (hopper/shroud), drum axle
   [100,60], drum R25 W15, tape under drum bottom (world z~35->track).
   Hopper local drum center still maps onto drumPivot in viewer (pos [0,0,0] /
   rot [-PI/2,0,0] unchanged); shroud child pos [0,18.7,0] unchanged.

## Parts Panel (Isolation) - 2026-09-16 - Agreed with User

1. **Parts panel** in web/index.html with per-part checkbox + solo button for:
   chassis, hopper, shroud, cartridge/drum, cones_a, cones_b, plow,
   rollers lower, rollers upper, crank (+ tape/seeds extras).
2. **All on / All off** buttons; **solo** isolates one part (click again restores all).
3. **Visibility only**: toggles set `.visible`, never touch pivots/animation;
   crank grip orbit radius 45 and rotation signs preserved.
4. **Styling** matches existing dark panel (same buttons, swatches, rows).

## Fit-fix Update - 2026-09-16 - Agreed with User

1. **All parts must sit inside the blue chassis interior** (root-local X[0,200], Y[0,110], Z[−60,0]) in live preview — no parts dangling below ground or outside walls; chassis must not render empty.
2. **Fix derived from measurement, not hand-tweaking**: read animated_assembly() transforms + each GLB bounding box, then set PART_DEFS pos/rot.
3. **Preserve proven crank orbit**: crank grip orbits radius 45 about the shaft axis (pos vector re-derived as [−5,−8.47,0]; old [0,45,0] measured only the crank node origin, true grip was at r=86).

## Fit-fix Results - 2026-09-16 (v4, verified)

- **Root cause**: mixed frames. GLBs are raw OpenSCAD coords; pivots used M-mapped
  coords (x,z,−y) while root still applied rotation.x=−π/2 (double rotation ⇒ whole
  machine rendered upside-down under the floor, chassis looking empty). Previous
  PART_DEFS were centroid-centering hacks (part [−center] offsets), v3 "radius 45"
  measured a node origin, not the grip. Fix (SCHEME M): root.rotation.x=0,
  M baked into every part (rule: pivot at M(A), child rot=M_R·Q, pos=M_R·(B+d)).
- **New PART_DEFS pos/rot**: chassis [0,0,0]/[−π/2,0,0]; hopper [0,0,0]/[−π/2,0,0]
  (pivot→(100,4,−30)); shroud [0,18.7,0]/[−π/2,0,0]; cartridge [0,−25,0]/[−π/2,0,0];
  cone_a [0,0,26]/[π,0,0]; cone_b [−50,0,−26]/[0,0,0] (cancels baked +50 print offset);
  plow [0,0,0]/[−π/2,0,0]; rollers_lower/upper [0,0,26]/[π,0,0];
  crank [−5,−8.47,0]/[−π/2,0,0] (mount→(160,60,−68)). Rotation signs unchanged.
- **GLB findings**: cartridge.glb == horizontal assembly-branch geometry (exact bounds
  match, no regen needed); rollers_lower.glb contained BOTH rollers + rollers_upper.glb
  was unidentifiable → regenerated both as single vertical rollers from current .scad.
- **scad fix**: knurled_roller vertical collars double-counted zoffset (upper collar
  floated 8 mm in air) → removed inner zoffset; regenerate_glbs.sh now emits the
  roller singles; seed_tape_machine_v2.scad newly tracked in git.
- **Verification (Playwright, node verify_fix.js)**: ready, 0 console errors; grip
  surface-centroid orbit r=44.964 at t=0/0.25/0.5/0.75 (spread 0, n=109 verts);
  all axles horizontal (y=0.000000); pinion gear plane y=47.95 = drum gear plane.
  Fit (root-local): hopper/shroud/cartridge/plow inside=true, belowGround=false
  everywhere. Known by-design exceptions: crank outside (external handle), spool cones
  X overhang −12.5 (axle x=10 < cone r 22.5, open end), lower shaft tip Z −64.95
  (through-wall axle to crank), chassis envelope itself (gussets x→210).
  Screenshots: /tmp/fit_t0.png, /tmp/fit_top.png, /tmp/fit_side.png.

## MVP Update - 2026-09-16 - Agreed with User (v14 refinements)

1. **Browser preview stays as is** (no UI change), but must be a logically working model: parts mounted in true fit positions (no floating), motions synced (crank -> seed wheel -> drop -> tape pull, no random spinning).
2. **Round cover/shroud**: open-top half-cut 16mm pipe channel running 11 o'clock to 6 o'clock along the drum undershot path, guides seed to the 6 o'clock drop onto tape. Top open so seed travel is visible from the hopper to 11 o'clock in top view, no internal blocking ribs (red removed). Bore fits 8mm seed, inner face has grooves matching drum for wheel-to-frame positioning. Joints to the hopper on both sides.
3. **Seed wheel/cartridge (drum)**: 6 cavities, fixed for MVP. Wheels still interchangeable by hand (no tools) to support 1mm to 6mm seed sizes (cavity size varies, count stays 6).
4. **Hopper/seed box**: closed container (seeds retained, no open gap). Keeps the horizontal top edge (z=73) but the open gap is filled with walls. Sits at 9 o'clock, max volume extended up to 10:30 around the seed wheel. Inner face has grooves matching drum for wheel-to-frame positioning.
5. **Hopper + shroud = single printed piece** (with 2 side joints, blue support joints on both sides retained).
6. **Tape**: 1 inch wide, same for all seed sizes, center-fold with seed in middle.
7. **Seed spacing**: fixed 6 inch in MVP. Spacing driven by pull roller + gear ratio linked to 6 cavities (drum geared slower vs roller to keep 6 inch). Future enhancement (post-MVP): swap-gears for adjustable spacing (e.g. 3/6/9 inch).
8. **Gear-ratio calculator/chart**: cavities count + roller + gears = spacing. Include as future helper.
9. **Pink gaps sealed – no leak gaps; Red blocking feature removed – seed path clear from 11 to 6**.

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
