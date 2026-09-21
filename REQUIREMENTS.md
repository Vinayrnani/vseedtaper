**Version: v83**

## v83 Twister redesign: static hollow axle + spinning twister, drive gears removed - 2026-09-21

1. **Why** (user: clean chassis, no gears; finalize twister shape first, gear chain later): replace the overhead drive with a static hollow axle the twister spins on. Tape passes through the axle bore; twister slides on from the east and push-locks. All overhead drive gears REMOVED from chassis. Twister keeps its current visual spin ratio; no drive source in CAD for now (documented gap, gear chain is a later version).
2. **Hollow axle (static)**: 10mm bore for tape, OD 15, tube x160..184 with funnel mouth (gap 0.5–2 from plow exit x159). Single west pedestal x162..166 from z0 (fuses with base). 3 snap-hook fingers at east end (4 wide / 1.6 thick / 6 long, 1.2 slots, 0.8 lip).
3. **Twister (spinning, ratio unchanged)**: hub bore 15.6 slip-fit on axle OD; disc r14 x167..171; back-face bevel-tooth BLANK — shape only, 24T M1.5 envelope reserved, real gear mesh in a later version. 2 spindle pins Ø6 (hole 6.6) at orbit R10, parallel-X, 180° apart. 2 real Class-15 bobbins (Ø20.7×11.1) with split-collet snap lips. 2 thread-guide eyelet posts (simple, tension by wrap angle).
4. **Base**: through-slot x166..183 y8..52 (contains disc dip + bobbin sweep with margin) + 4 corner feet 10×10 down to z=-8 (bobbin dip clears by ≥2). Chassis export lifts +8 for min_z=0; viewer chassis pivot compensates -8.
5. **Verify**: 0 render errors; viewer ready + 0 console errors + animation + tape-static + bore-open + axle-static checks, screenshots; reviewer PASS required; web/v83 snapshot (index.html + js/ + stl/*.glb only).
6. **Frozen**: fail-loud asserts for every stack-up; `$fn=60`, `tol=0.3` kept; never v1 / web-backup.
7. **Corrections (review round 2, all verified)**: (1) pedestal x161..165 (was 162..166) → 1.0 clearance to slot west edge (166), satisfies the ≥0.5 assert; disc-vs-pedestal rotating gap = 2 (165→167), with explicit assert. (2) new rotor lift: disc r14 → min_z=-14 → `tw_lift`=14 defined explicitly in params; replaces `twister_lift` (=12) usage in twister dispatch branch; viewer twister pos [0,-12,0]→[0,-14,0]; old `twister_ring_r`/`_tube` params deleted. (3) old cradle stubs (chassis.scad ~L173-175, `twister_post_h`-based) explicitly DELETED with the drive removal (they sit inside the new tube zone). (4) chassis viewer pivot: NO change (stays [0,0,0]) — the +8 CAD export lift already yields min_z=0 GLB; earlier "-8 pivot" note was wrong, withdrawn. (5) `twister_arms` param KEPT (=2, now counts bobbin spindles); both asserts kept. (6) bevel-blank envelope (dims): 24T M1.5 visual-only teeth on disc west face, annular zone r8..13.5, thickness 3 (x164..167). (7) eyelets (dims): 2 posts r1.5 h6 at orbit R6, angles 90°/270° (offset from spindles), x171..177, each with Ø2 through-hole across the top. (8) snap fingers x182..184 overhang slot east edge (183) by 1mm in X but live at z~17 vs slot z0..4 — no interference, no assert needed (documented).

## v82 SCAD modular split (behavior-preserving) - 2026-09-21

1. **Why**: `seed_tape_machine_v2.scad` (~2407 lines, 29 modules, zero include/use) split into 7 files with render output guaranteed identical (STL hash proof before/after). Overhead-drive identifiers renamed to plain words (old version-stamped labels removed from code). Twister redesign parked until split is proven unbroken.
2. **Layout**: `scad/params.scad` (vars+asserts), `scad/gears.scad`, `scad/chassis.scad`, `scad/feed.scad`, `scad/plow.scad`, `scad/stations.scad`; `seed_tape_machine_v2.scad` kept as master (part_to_render + assembly + dispatch + includes).
3. **Frozen**: no geometry change, no viewer change, no ASSET_V bump.

## v81 Step B (amended): Both gears on CRANK (front-wall) side — 2026-09-21

1. **Why** (user redirected: BOTH gears on the CRANK/front-wall side): drum 40T stays/moves to FRONT plane (+gear_off, world y≈47.95); crank real 20T sits NEAR THE HANDLE at front plane (world y≈45..51, local y≈-20, hub +Y toward arm) on SHORT hex shaft (hex_shaft_len back to 28, shaft stays centered at arm); NO long through-chassis shaft. Drum still counter-rotates (drum_angle=-360*$t vs crank +720*$t, external mesh, 0.5×). Twister/viewer signs from v81 stand (DRUM_RATIO -0.5, viewer twister -3×). Cartridge EXPORT branch must be aligned to the same front plane (it currently builds gear at bottom/back — move to match).
2. **Regen**: crank + cartridge ONLY (chassis holes at x=160 already exist).
3. **Verify**: NoError, mesh (dist 60, y-spans coincide ≈45..51, x-interleave ~4mm), gear-hub vs front-wall clearance check, pivots ±0.15, ratios ±3% with signs, 0 console errors, animating close-up screenshots of the front-side mesh.
4. **Out of scope**: v53-train removal still HOLD (note: back-plane counter now meshes air — accepted temporary state, forward ref); plow/shroud/split untouched.
5. **Viewer**: ASSET_V 43→44; header v79→v81.
6. **Fix (27cc865)**: cartridge export gear offset corrected +13.9mm
   (formula now drum_base+drum_len/2+gear_off, gear z 39.36, hub -Z);
   drum mesh phase +4.5° half-pitch in SCAD + viewer DRUM_PHASE;
   ASSET_V 44→45; mesh proven ΔX=60.0000/ΔY≈0/ΔZ≈-0.24,
   interleave 0.58mm, 0 console errors.

## v80 Step A: six_turner/plow restored verbatim from v66/v67/v68 - 2026-09-21

1. **Why** (user: restore the plow exactly as it was in v66/v67/v68): six_turner/plow restored verbatim from v66/v67/v68 (commit d1f2a09). Deleted HEAD parametric identifiers (st_x/st_R/st_W/st_H/n_st/fpx/fR/fW/fH/n_fp/plate_t/wall/hook_off/floor_local/curl_cz/curl_strip_pts). Restored scroll_sheet() (45×1.6, steps 35/35) and six_turner() (axis_z=13, mouth_x0=-12 → world 114, ears (132,6)/(153,54)). web/v66/stl/plow.glb proven faithful (4311 verts, bbox/volume identical to fresh d1f2a09 render). ASSET_V stays 43. Twister v53 overhead drive accepted-state (still present, meshing). Parked WIP: crank-20T + counter-rotation in /tmp/opencode/v80_gear_wip.patch.

## v79 Crank RIGHT / Hopper MIRRORED — seed box mouth faces LEFT - 2026-09-20

1. **Why** (user: move crank to right, flip hopper): user wanted the crank handle on the RIGHT (front) side and the seed box mouth facing LEFT (west). Move crank assembly from left wall (x=0) to front wall (x=100, drum-coaxial), mirror hopper 180° about Y so wedge swings west.
2. **CAD** (`seed_tape_machine_v2.scad` only):
   - **Crank mount moved**: `crank_mount_x` 0→`drum_axle_x`(100), `crank_mount_y` `chassis_width+8`(68), `crank_side` −1→+1; crank asserts updated.
   - **Hopper mirrored**: `mirror([1,0,0])` wrapping the `difference()` block in `hopper_body()`; mirrored wedge world x range [17..86]; collision asserts added (Z≥49 threshold vs obstacles below).
   - **Drum angle flipped**: `drum_angle = 360*$t` (was −360*$t) so animation direction matches new layout.
   - **Crank assembly in animated_assembly()**: position set to `(crank_mount_x, chassis_width/2, -crank_side*22)` with correct axis params.
   - **Sign convention comment** updated to reflect new crank_side.
3. **Viewer** (`web/index.html` only): `crankMount.position.set(100,60,-68)`; `_setRotations` updated (crankSpinner = crankAngle, twister = 3×crankAngle, takeup = −2×crankAngle); `ASSET_V` 41→42; legend updated with "v78: Crank handle RIGHT / seed box mouth LEFT".
4. **Collisions**: mirrored hopper wedge (world x 17..86) overlaps shroud/tape/pull in X but all obstacles are below Z=49 → no 3D collision. Two SCAD asserts enforce this.
5. **Visual check**: live animating preview + snapshots while animating, 0 console errors, tape-static, verify_v78.js PASSED (pivots ±0.15mm, ratios ±3% with signs, 0 console errors).
6. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`; drum/roller axles unchanged; port 9099 only.

## v77 Twister "Lift all up" + pinion TOP - 2026-09-20

1. **Why** (user: "Lift all up" + pinion "Top"): lift the downstream tape line so two REAL Class-15 sewing bobbins on a rotor clear the floor. Replace v76's v53 friction drive + 2 dummy spindles with a printable assembly: fixed hollow axle (Ø10 bore carries the tape pocket through the rotor centre along X), rotor disc spinning on it via slip-fit bore, crown teeth on the rotor's WEST face, pinion at the TOP (axis Y), driven by a compound spur chain from the seed drum gear. Ratio **15** (target inside user range 12-18; 6 seeds/rev × 2.5 turns/seed).
2. **CAD** (`seed_tape_machine_v2.scad` only):
   - **Tape line lifted**: carry z 13→**32**; tape climbs from ~17 (turner exit x≈159) to 32 at rotor x=176; pull station bridge raised (z≈49 at pull_x=194); `takeup_z` 34→32; corresponding seed_tape_bend()/six_turner-placement/tape_viewer constants updated.
   - **Rotor** (thread_twister() rewrite): disc centre **(176,30,32)**, disc r22, bore Ø14.2, rotates about X; carries 2× REAL Class-15 bobbins (Ø20.7 × 11.1) on split-collet snap-fit spindles at **orbit 19, 180° apart** (bottoms at z=13 — clear base top z=4 by ~9mm), with thread-guide handles.
   - **Crown** 24T M1.5 (pitch r18) on rotor WEST face; **pinion 12T M1.5 (pitch r9) at TOP of rotor "under-tape-side" up** — axis Y, centre ≈(176,30,59), mesh dist 18+9=27, clear of the tape bore; fail-loud mesh assert.
   - **Fixed hollow axle**: Ø10 bore / OD 14, cantilevered off back wall (y≈0), inserted from front, push-lock via snap ring in a groove at the front end; rotor disc rides the OD14 axle (Ø14.2 slip fit); tape pocket (outer ≈7.8) passes through the 10mm axle bore.
   - **Gear chain (target 15 = 4×3×2.5×0.5)**: drum 40T M2 at (100,60) → 10T M2 (×4) → compound 30T→10T M1.5 (×3; M2→M1.5 transition) → compound 25T→10T M1.5 (×2.5) → pinion 12T M1.5 → crown 24T (×0.5). All spur stages axis-Y on the back plane y≈12 (clear of tape lane y≥17.3); compound shaft X-Z stations solved in CAD with fail-loud centre-distance asserts; chain stays WEST of x=165 (clear of disc); M2 drum stage as-is.
   - **Low friction**: slip-fit shaft bores (tol 0.3), ring/bracket split-collar (tw_tol=0.35) + cradle posts; the drive train and ring ride on plain bores.
   - **v53 drive DELETED surgically**: v53 params, asserts, chassis geometry, wall holes removed (v76's drum-coaxial 50T→10T→bevel→pinion→friction-wheel chain). KEEP pull-pin / bore-slip asserts, update values to pass.
3. **Viewer** (`web/index.html` only): ASSET_V 41→**42**, `orbitsPerDrum` 6→**15**; `twisterPivot` (172,17,−30)→**(176,32,−30)**; pull/takeup pivots raised; tape mesh raised to z=32 + climb; PART_DEFs/exports for the new rotor (disc+crown+bobbins), ring axle/bracket, pinion, chain shafts; web/stl GLBs regenerated.
4. **Collisions**: chain gears west of x=165 clear of ring/disc; tape lane clear; bobbin bottom z=13 > base 4; pinion top z≈68 < chassis top 112; walls y 0..3/57..60 clear.
5. **Visual check**: live animating preview + snapshots while animating, 0 console errors, tape-static, verify_v77.js PASSED (pivots ±0.15mm, ratios ±3% with signs, 0 console errors).
6. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`; drum/roller axles unchanged; port 9099 only.

## v75 Step 4: full gear-driven chain (drum→5-stage spur→bevel→ring crown) - 2026-09-19 (final build: commits 56059a4 CAD, b1ed937 viewer/GLBs)

1. **Why** (user: replace the v72 animated twister with a proper chain-driven gear train from the drum): v72 twister was animated directly (NOT chain-driven). v75 implements the full gear-driven chain: drum 44T → 5-stage compound spur train → 1:1 bevel miter → ring crown 16T, final total ratio **17.2032× drum** (user range 12-18 ✓). The v53 friction/overhead drive is surgically removed. Chassis widened to 64, lengthened to 278, base pocket cut for the ring, feet added, pull_x moved 194→196.
2. **CAD** (`seed_tape_machine_v2.scad` only):
   - **Chassis**: width 60→64 (walls y=0-3 back, y=61-64 front); len 262→278 (x0=-14, spans -14..264); base pocket slot x=165-181, y=3.5-56.5, z=0-4 so the ring hangs below; ~14mm feet at corners so ring bottom (z=-10) clears table by ~4mm; pull_x 194→196 (clear of bobbin A rod ending ~x=192).
   - **Twister ring**: center (173,30,17), ring_r=18.5, tube=8→OD53, bore Ø21 (r10.5). X extent 165-181, Y 3.5-56.5, Z -10-44. Rotates about X axis.
   - **Crown gear**: 16T M1.5 on WEST face, disc r10.5 (draft spec r14 — deviation: disc is bore-limited to clear the tape tube r5.5 by 5mm), teeth FULL-HEIGHT via face_bevel_gear teeth_z=6/teeth_depth=12 (fix for CGAL: partial-depth teeth boxes vanished from the mesh; full-height boxes centered at z=pitch_r/2 with depth=pitch_r are the only verified pattern). Rotates about X with the ring.
   - **Bobbins**: 2× Class-15 (r10.35, length 11.1mm), at 90° apart, **orbit 16.25** (was 18), on EAST face (x=181), spinning about X with the ring.
   - **Pinion shaft** (axis X, y=49.4, z=25.04, x=145→149.5): 12T M1.5 bevel driven at **145** (meshes shaft E's 12T bevel, axis Y) and 12T bevel driving at **149.5** (meshes ring crown 16T; mesh dist from ring center (30,17): sqrt(19.4²+8.04²)=21.0 ✓), teeth_z=4.5/teeth_depth=9 (same full-height fix). ~1mm gap between the two bevels. Bearing blocks from base.
   - **Gear train** (ALL axis-Y spur gears on the back conduit plane; OpenSCAD coords (x,y,z) with shafts at z=32 plane):
     - Stage 1 (cd=55): drum 44T M2 (r44) at (100,14.05,60) → 11T M2 (r11), shaft A at (155,32,60) = **4×**.
     - Stage 2 (cd=19.5): 16T→10T, shaft B at (135.5,32,59.79) = **1.6×**.
     - Stage 3 (cd=19.5): 16T→10T, shaft C at (125.5,32,43.04) = **1.6×**.
     - Stage 4 (cd=19.5): 16T→10T, shaft D at (145,32,43.04) = **1.6×**.
     - Stage 5 (cd=19.5): **14T→10T**, shaft E at (145,32,25.04) = **1.4×**.
     - Bevel (1:1 miter): shaft E 12T (axis Y) at (145,49.4,25.04) → pinion shaft 12T (axis X) at (149.5,49.4,25.04); pinion → ring crown 16T, **12/16=0.75**.
     - **TOTAL RATIO: 4×(16/10)³×(14/10)×1.0×(12/16) = 17.2032× drum** (initial draft 12.288 used 16/10×4; final drops one stage to 14T→10T for the conduit geometry).
   - **New gears**: 44T M2 (r44), 11T M2 (r11), 16T/14T/10T M1.5 (r12/10.5/7.5), 12T bevel M1.5 (r9). All within spur_gear() teeth cap (60).
   - **V53 deletion** (surgical): remove v53 params, v53 asserts, v53 chassis geometry, v53 wall holes. KEEP v72 bobbin/bevel asserts, pull-pin asserts, bore-slip assert — update values to pass.
   - Shaft positions solved so each stage cd=19.5 exactly (drum stage cd=55), gear mounts [155,32,60]/[135.5,32,59.79]/[125.5,32,43.04]/[145,32,43.04]/[145,32,25.04], bevels [145,49.4,25.04]/[149.5,49.4,25.04], crown on ring at [173,30,17]; all gears stay WEST of x=165, clear of tape lane (tube at y=30,z=17), clear of chassis walls (y=3..61), clear of base pocket (x=165-181).
3. **Viewer** (`web/index.html` only): `ASSET_V` 54→**60**, `orbitsPerDrum` 12.29→**17.2032**. 8 per-shaft gear pivots (root-local M-frame): gearDrum [100,60,-14.05], gearA [155,60,-32], gearB [135.5,59.79,-32], gearC [125.5,43.04,-32], gearD [145,43.04,-32], gearE [145,25.04,-32], gearPinion [149.5,25.04,-49.4] (spin rot.x), gearRing [173,17,-30] (spin rot.x). applyGearRotations() per drumAngle: gearDrum 1:1 (44T rigid on drum — the user-requested +4.0 transmits to shaft A), A +4.0, B −6.4, C +10.24, D −16.384, E +22.94, pinion −22.94 (rot.x), ring +17.2032 (rot.x). PART_DEFs: replace twister/twister_bracket/twister_pinion/gear_train with 8 gear defs (gear_drum visible:false — cartridge already renders the 44T; avoid double-render; all others visible:true); gear_ring = ring+crown+bobbins. rollers_lower/rollers_upper now visible (rot Rz). GLB URLs bump ?v=60; **web/stl/gear_train.glb deleted** (stale, superseded by per-shaft GLBs).
4. **Collisions**: all gears west of x=165 (clear of ring); tape lane clear (tube y=30,z=17); chassis walls y=3..61 clear; base pocket x=165-181 clear; bobbin A clears front wall (y=61) and tape tube; bobbin B clears tube.
5. **Visual check**: live animating preview + snapshots while animating, 0 console errors, tape-static; verify_v75.js PASSED (ASSET_V=60, 8 pivots ±0.15mm, 7 ratios ±3% with signs +,-,+,-,+,-,+, 0 console errors, gear_ring bbox x≈171.6, crown cone present — 168 verts at local x[-22,-12]).
6. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`; drum/roller axles unchanged, port 9099 only.

## v74 — 2026-09-19

1. **Why** (user: extend twister diameter so bevel teeth mesh with mating bevel, room for 2 thread bobbins + 8mm folded tape through bore): ring_r 10->15, bore Ø18 (r9) for 8mm folded tape, tube=6 (wall>=2mm). Bevel teeth on west face via bevel_gear() with rotate([0,90,0]) so teeth go full 360 about X axis (previous bug was rotate([90,0,0])). 2x bobbin spindles 6mm dia x14mm on front face 180deg apart, orbit radius inside outer rim but outside bore + clearance; 2mm guide eyelets near bore. Mating bevel pinion M1.5 (12T vs 28T ring, ~2.3x) meshes at back plane y=12, axes intersect at (bind_x,30,17). twister_bracket() flat-on-base split-collar/slotted bracket coaxial with scroll_folder() exit, 0.35mm clearances, printable min_z=0; `twister_lift=23` (ring bottom z=11 + bevel OD margin ~2).
2. **CAD** (`seed_tape_machine_v2.scad` only): `twister_ring_r` 10->15, `twister_ring_tube` 2->6 (bore Ø18), `twister_lift` updated; `thread_twister()` gains bevel teeth (28T M1.5 west face, rotate([0,90,0])), 2x bobbin spindles (6mm dia x14mm, orbit r12, 180deg apart), 2mm guide eyelets near bore; new `twister_bracket()` split-collar/slotted bracket coaxial with six_turner() exit, 0.35mm clearances, min_z=0; new bevel pinion module (12T M1.5) positioned at back plane y=12, axes intersect (bind_x,30,17); fail-loud mesh assert dist=r1+r2 ±(tol+0.01); `twister_orbits_per_drum` updated to 18/7 (~2.57x drum via 28T/12T bevel); `part_to_render` "twister" keeps min_z=0; `animated_assembly()` keeps drum -360*$t, ring ratio matching new bevel; no frozen gears; tape clearance >=1.5mm everywhere; gears at y=12 back plane clear of tape (tape y 17.3-42.7).
3. **Viewer** (`web/index.html` only): `ASSET_V` 51->52, twister pivot pos updated for new twister_lift, `twisterRatio` updated to 18/7, PART_DEFS twister entry updated; new GLB: twister (+ chassis if bracket holes changed).
4. **Collisions**: tape clearance >=1.5mm everywhere; gears at y=12 back plane clear of tape (tape y 17.3-42.7); bore Ø18 clears 8mm folded tape + 2 bobbins; bracket coaxial with scroll exit.
5. **Visual check**: live animating preview + snapshots while animating, 0 console errors, tape-static.
6. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`; drum/roller axles unchanged, port 9099 only.

**Version: v71**

## v71 Step 2: 11T M2 intermediate pinion meshing the 44T drum - 2026-09-18

1. **Why** (user step-by-step twister redesign, STEP 2 ONLY, one
    piece at a time): ONE 11T M2 spur pinion (pitch r11, outer
    r13) at (155,12,60) — same Y plane as the drum+roller gears
    (y≈12, behind the tape path), right of the drum. Mesh:
    |155-100|=55 = (44+11)*2/2 exact. Spins 4x drum magnitude
    (44/11); EXTERNAL mesh so it counter-rotates vs the drum
    (same sense as crank/roller — brief's "same direction" line
    corrected to real spur-mesh physics).
2. **CAD** (`seed_tape_machine_v2.scad` only): `pinion2_teeth`
    11, `pinion2_x/y/z` 155/12/60, `pinion2_t` 6,
    `pinion2_phase` 360/11/2; new `twister_pinion_11t()`
    (spur_gear direct, bore axle_dia, flat print base min_z=0 +
    Y-axis assembly branch); fail-loud mesh assert (dist 55 =
    44+11); assembly placement in `animated_assembly()` only
    (chassis() untouched); `pinion2_angle` +1440*$t + phase
    (opposite drum, 4x). NO support shaft yet (layshaft-class
    part — deferred to a later step); NO further gears,
    countershaft, bevels, ring/bracket.
3. **Viewer** (`web/index.html` only): new `pinionPivot` at
    M(155,12,60)=(155,60,-12), `PINION_RATIO` 16/11 (4x drum in
    crank units, opposite drum sign) + `PINION_PHASE` PI/11,
    PART_DEFS `twister_pinion_11t` entry, `ASSET_V` 51->52, new
    GLB only (other GLBs untouched).
4. **Collisions**: hopper cheeks clear (pinion top y=15 vs
    cheek inner y=19.7, gap 4.7 — NO relief); tube z=17 far
    below (gap 30); chassis walls y 0..3/57..60 clear (NO
    notch); chassis top 112 clears gear top 73. FINDING (no
    fix this step): v53 counter 10T at (~151.58,12,44) +
    its Y countershaft (r4, top z=48) interpenetrate the new
    pinion envelope (centres 16.36 apart vs 25 outer-sum;
    tips graze the shaft) — v53 drive removal/rework is a
    later-step decision.
5. **Visual check**: live animating preview + snapshots while
    animating (1 close-up pinion/drum mesh + 1 wide vs tape
    path), 0 console errors, tape-static.
6. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`,
    `tol=0.3`; drum/roller axles unchanged, port 9099 only.

## v70 Step 1: bigger drum gear 44T / roller pinion 16T - 2026-09-18

1. **Why** (user step-by-step twister redesign, STEP 1 ONLY, one
    piece at a time — option B: resize the drum gear first):
    drum gear 40T→44T M2 (pitch r40→r44), roller pinion 20T→16T
    M2 (pitch r20→r16). Centre distance stays 44+16=60 exact
    (drum x=100 z=60, roller x=40 z=60 — positions UNCHANGED).
    Crank/roller speed becomes 44/16=2.75x drum (was 2x).
2. **CAD** (`seed_tape_machine_v2.scad` only): `roller_teeth`
    20→16, `drum_teeth` 40→44; `gear_mesh_phase` 9→11.25deg
    (16T half-pitch, formula-derived); `drum_rot_per_crank`
    0.5→16/44; `crank_angle` 720*$t→990*$t (2.75x drum
    magnitude, senses kept), idler −990*$t, takeup stays
    −1440*$t (2x crank, tape-tension); mesh assert stays 60;
    v53 step-up assert 6→6.6 ((44/10)*(12/10)*(15/12), counter
    shaft auto-shifts with the bigger drum gear). NO new
    twister/layshaft/countershaft/bevel gears added.
3. **Viewer** (`web/index.html` only): `DRUM_RATIO` 0.5→16/44,
    `GEAR_PHASE` PI/20→PI/16 (11.25deg), twister stays 6x
    drum-relative, labels 16/44T + 2.75:1, `ASSET_V` 50->51,
    affected GLBs (cartridge/rollers/rollers_lower/
    rollers_upper/chassis) rebuilt.
4. **Visual check**: live animating preview + snapshots while
    animating, 0 console errors, tape-static.
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`,
    `tol=0.3`; axle positions unchanged, back gears, crank
    back wall [40,-8,60], R->L order, port 9099 only.

## v69 Orbital Twister 24:1 Gear Train IMPLEMENTATION (v67/v68 spec built) - 2026-09-18

1. **Why** (implement v67/v68 spec for real): side-mounted 24:1
    compound spur train + final 1:1 bevel turn replaces the v53
    overhead drive; ring stays on X (centre x=172, axis y=30
    z=17). Green 72T M1.5 on drum shaft (y44..50) → layshaft 12T
    at (163,62) (6:1, −6x, cd 63.03 vs 63) → layshaft 48T →
    countershaft 12T at (163,17) (4:1, +24x, cd 45 exact) →
    20T/20T bevel (apex 163,30,17, Y→X turn) → ring (±24x = 4
    revs/seed, 8 cross-wraps).
2. **CAD** (`seed_tape_machine_v2.scad` only): M1.5 params +
    local `tw_tol=0.35`; `spur_gear()` module param + 72T cap;
    `twister_ring()` (bore 18, fused 20T bevel west, 2×6mm
    spindles + 2×2mm eyelets), `twister_bracket()` (split
    collar, 0.35 clear, bevel window), `layshaft_gears()` +
    countershaft gears; v53 overhead fully removed; orbits
    6→24; fail-loud asserts (cd ±0.35, ratio 24, bore ≥18,
    orbit clears bracket). Green top ~115.5 exposed above wall
    110 (accepted).
3. **Viewer** (`web/index.html` only): new PART_DEFS/pivots
    (twister_ring/    twister_bracket/layshaft_gears/countershaft_gears/green_gear), twister 24x
    drum (12x crank), `ASSET_V` 50->51, GLBs rebuilt, stale v53
    artefacts removed.
4. **Visual check**: live animating preview + snapshots while
    animating, 0 console errors, tape-static.
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`,
    `tol=0.3`; `center_distance` 60, `gear_mesh_phase` 9°,
    back gears, crank back wall [40,-8,60], R->L order, port
    9099 only.

**Version: v68**

## v68 Orbital Twister 24:1 Gear Train Build (v67 spec) - 2026-09-18

1. **Why** (v67 spec build): side-mounted 24:1 compound spur
    train + final 1:1 bevel turn replaces the v53 overhead
    drive; ring stays on X (vertical bobbin orbit, centre
    x=172, axis y=30 z=17). Green 72T M1.5 on drum shaft
    (y44..50) → layshaft 12T (6:1, −6x) → layshaft 48T →
    countershaft 12T (4:1, +24x) → 20T/20T bevel (Y→X turn)
    → ring (±24x = 4 revs/seed, 8 cross-wraps).
2. **CAD** (`seed_tape_machine_v2.scad` only): M1.5 params +
    local `tw_tol=0.35`; `spur_gear()` module param + 72T cap;
    `twister_ring()` (18 bore, fused 20T bevel west, 2×6mm
    spindles + 2×2mm eyelets), `twister_bracket()` (split
    collar, 0.35 clear), lay/countershaft gears; v53 overhead
    fully removed; orbits 6→24; fail-loud asserts (cd ±0.35,
    ratio 24, bore ≥18, orbit clears bracket). Green top
    ~115.5 exposed above wall 110 (accepted).
3. **Viewer** (`web/index.html` only): new PART_DEFS/pivots,
    twister 24x drum (12x crank), `ASSET_V` 50->51, GLBs rebuilt.
4. **Visual check**: live animating preview + snapshots while
    animating, 0 console errors, tape-static.
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`,
    `tol=0.3`; `center_distance` 60, `gear_mesh_phase` 9°,
    back gears, crank back wall [40,-8,60], R->L order, port
    9099 only.

**Version: v67**

## v67 Orbital Twister 24:1 Gear Train + 1:1 Bevel Turn (ring stays on X) - 2026-09-18

1. **Why** (user decision, binding): keep the twister ring rotating
    about the X axis (vertical bobbin orbit) and drive it 24:1 vs
    drum via spurs + a final bevel turn: Green 72T M1.5 on the drum
    shaft → layshaft 12T (6:1) → layshaft 48T → countershaft 12T
    (4:1) → 1:1 bevel 20T/20T M1.5 (Y→X turn) → ring. Ring spins
    24x drum = 4 revs/seed (6 cavities), 8 cross-wraps (2 bobbins).
    The 1:1 bevel stage is required: a 12T M1.5 pinion (pitch r9)
    cannot surround the 18mm bore (r9) — roots would break in.
2. **CAD** (`seed_tape_machine_v2.scad` only): new M1.5 params +
    `tw_tol=0.3`5 local; `spur_gear()` takes module + 72T cap;
    `twister_ring()` (18 bore, fused 20T bevel west, 2 spindles +
    2 eyelets), `twister_bracket()` (split collar, 0.35 clear),
    lay/countershaft gears; v53 overhead drive fully removed;
    chassis mounts new; orbits 6→24; fail-loud asserts (cd ±0.35,
    ratio 24, bore ≥18, orbit clears bracket). Green top ~115.5
    pokes above wall 110: accepted exposed gear.
3. **Viewer** (`web/index.html` only): new PART_DEFS/pivots,
    twister 24x drum (12x crank), `ASSET_V` 50->51, GLBs rebuilt.
4. **Visual check**: live animating preview + snapshots while
    animating, 0 console errors, tape-static.
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`,
    `tol=0.3`; `center_distance` 60, `gear_mesh_phase` 9°,
    back gears, crank back wall [40,-8,60], R->L order, port
    9099 only.

**Version: v66**

## v66 Twister-Aimed Mounts: axis 13 + chassis feet, exit dead-on the twister bore - 2026-09-18

1. **Why** (user: "hanging in air, no support to fix it to
    chassis and align it properly so that exit properly faces the
    twister"): sheet axis 21->13 so the exit bore lands DEAD on the
    twister ring bore (world (30,17) = ring centre; CAD-proved by
    `axis_z + base_thick == twister_axle_z`), and the part gets real
    feet: 2 floor pedestals fused ~0.4 into the sheet floor wall +
    ground straps + 2 small 6x6x1 ears on the chassis M3 holes
    (world 132/6, 153/54). Entry side-effect (accepted): mouth rims
    now at lane height, floor 0.2 above the base — tape threads the
    middle straight, drum still clears by 5+, cradle starts 12 east
    of the mouth (no steel clash).
2. **CAD** (`seed_tape_machine_v2.scad` only): `axis_z` 13,
    pedA/pedB/ear/strap params + pedestal-band, exit-aim, ear asserts;
    single watertight shell (3556); tape-flow path re-probed clear at
    the new lane; min_z=0. Nothing else touched.
3. **Viewer** (`web/index.html` only): `ASSET_V` 49->50, plow GLB
    rebuilt, label + `_sixTurner` hooks (`exitAim` [172,30,17]).
4. **Visual check**: new align shot straight down the twister bore —
    folder exit tube centred in the ring; exit closeup shows the tube
    cradled on its pedestal with straps/ears; mouth/top/bottom/sides
    re-shot clean; machine assembles + animates, 0 errors.
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`,
    `tol=0.3`; `center_distance` 60, `gear_mesh_phase` 9°,
    back gears, crank back wall [40,-8,60], R->L order, port
    9099 only.

**Version: v65**

## v65 Clear Tape Path: tape-blocking left tab deleted, flow probed end to end - 2026-09-18

1. **Why** (user: "u removed supports and kept some object in the
    middle which obstructs the tape flow"): the kept left tab lay
    straight across the trench opening (plate y20..35 at z19.4..21
    = exactly the tape-wall lane) — deleted with the rest. The plow
    is now the bare `scroll_sheet()` and nothing else.
2. **CAD** (`seed_tape_machine_v2.scad` only): `printable_folder()`
    module deleted, `six_turner()` places `scroll_sheet()` directly;
    asserts unchanged otherwise (exact-use, placement, threading);
    ONE watertight shell (3011mm³); ray-probed tape-flow path clear
    at 15 stations (bowl-deep line mouth->mid, axis line mid->exit,
    full bore cross at exit). Nothing else touched.
3. **Viewer** (`web/index.html` only): `ASSET_V` 48->49, plow GLB
    rebuilt, label + `_sixTurner` hooks (flow-path-clear wording).
4. **Visual check** (solo part): mouth = wide-open U, no plate
    across it; top = pure scroll. Machine still assembles and
    animates, 0 errors. OPEN POINT for user: the part now has no
    mount of any kind (floats at axis 21) — say how it should be
    held (tabs back in a new spot, cradle, straps) and it gets built.
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`,
    `tol=0.3`; `center_distance` 60, `gear_mesh_phase` 9°,
    back gears, crank back wall [40,-8,60], R->L order, port
    9099 only.

**Version: v64**

## v64 Bare Spiral Plow: decluttered to the single watertight shell, checked all 6 sides - 2026-09-18

1. **Why** (user: "unnecessary objects inside or around it,
    remove them", then "check visually as single object from all
    angles"): all v63 wrapper solids deleted (2 pedestals, 2
    straps, 2 ears, tab post, tray, nose). Trimesh shell probe then
    proved the part was still 2 shells: the user's right tab floats
    3+mm off the sheet in EVERY orientation (tube outer max 9.2 <
    tab inner edge 12 — a loose scrap island even in their own print
    orientation), so it is deleted too — the one documented exception
    to verbatim. Result: exactly ONE watertight shell (3210mm³).
2. **CAD** (`seed_tape_machine_v2.scad` only): `six_turner()` is now
    placement + `printable_folder()` and nothing else (params cy /
    axis_z / mouth_x0 kept); pedestal/post/ear/tray/nose params and
    asserts deleted; exact-use proofs (45/1.6/35/35/5.5/1.25),
    mouth-114/exit-159/axis-21/centre-20 and pocket-threading asserts
    kept; `$fn=60`, `tol=0.3` (user `$fn=6/20` exception kept),
    min_z≈8.3 (sheet floats — screws via its own left tab).
    Nothing else touched.
3. **Viewer** (`web/index.html` only): `ASSET_V` 47->48, plow GLB
    rebuilt (163KB->~120KB single shell), label + `_sixTurner`
    hooks (tray field gone).
4. **Visual check** (solo part, all 6 sides + iso, animating rig):
    mouth = clean U bowl + overlap curl; exit = textbook spiral-6
    with open bore; top = smooth scroll closing to tube; bottom =
    clean tapered underside, nothing hanging; near = open trench +
    holed tab; far = smooth outer shell. NOTED for user: their own
    left tab crosses the upper mouth opening (fused, intentional —
    say the word to cut it back).
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`,
    `tol=0.3`; `center_distance` 60, `gear_mesh_phase` 9°,
    back gears, crank back wall [40,-8,60], R->L order, port
    9099 only.

**Version: v63**

## v63 Exact Spiral Plow: user overlapping-spiral code replaces the folder verbatim - 2026-09-18

1. **Why** (user: v62 block "didn't work well", "use this code
    exactly", "this is replacement of the plow"): the v62 block/
    trench/wick code is deleted and the plow IS the user's
    overlapping spiral sheet (`scroll_sheet()` 0.5-turn R12 U entry
    -> 1.25-turn R5.5 overlap exit over 45, 1.6 wall, user tabs),
    embedded byte-identical (only its demo `rotate()` invocation is
    left out — a top-level render line would print into every part
    export). `length`/`thickness` globals are collision-free (only
    module-param names elsewhere); user `$fn=6/20` kept (1225 hulls:
    `$fn=60` spheres would not render — documented exception).
2. **Placement** (wrapper only, geometry untouched): roll -90 about
    the tube axis (mouth opens UP) + 90 about Y (axis -> +X, mouth
    west); mouth 12 west of the slot so the exact 45 ends precisely
    on the slot end 159 (mouth world 114, 14 after the drop — flat
    landing kept; telescopes over the transit end; twister gap kept);
    axis 21 (entry floor ~9.8 under the ribbon, exit tube ~15..27).
    Supports: 2 ground pedestals fused ~0.5 into the sheet floor
    wall + straps to the chassis ears (world 132/6, 153/54) + tray
    13.8x16x0.8 + nose shelf (both clear below the sheet) + a drop
    post catching the user's floating right tab (left tab welds to
    the shell). Mid-length sections are asymmetric by construction
    (wrap grows 0..259°+: one tall wall, one low) — the overlap seam
    side, verified live in entry/exit/top/34 views.
3. **CAD** (`seed_tape_machine_v2.scad` only): verbatim user block +
    placement wrapper in `six_turner()`; fail-loud exact-use proofs
    (45/1.6/35/35/5.5/1.25), mouth/exit/axis/centre, pedestal-band,
    post-band, pocket-threading, ear/tray asserts; `folding_plow()`
    alias kept; `$fn=60`, `tol=0.3` (user-code exception noted),
    watertight single solid, min_z=0. Nothing else touched.
4. **Viewer** (`web/index.html` only): `ASSET_V` 46->47, plow GLB
    rebuilt, label + `_sixTurner` hooks (mouth 114, entryBore 24,
    exitBore 11, wall 1.6).
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`,
    `tol=0.3`; `center_distance` 60, `gear_mesh_phase` 9°,
    back gears, crank back wall [40,-8,60], R->L order, port
    9099 only.

**Version: v62**

## v62 Tubular Scroll Folder: user scroll concept rebuilds the 6-folder as a solid former block - 2026-09-18

1. **Why rebuild** (user supplied the scroll-folder concept:
    solid block + hull-lofted morphing tunnel + wick port for
    25.4mm PVA tape -> 8mm overlapped tube): the v61 thin shell
    is deleted and `six_turner()` is rewritten around that
    concept, fixed for printability and fitted to the machine.
    Two defects in the supplied snippet are fixed: the channel
    (30 long) never broke the block faces (40 long) so the bore
    would have been capped solid at both ends (first/last void
    plates now poke 0.5 past the faces = clean open mouth +
    clean tube exit), and a pure chord roof would have blocked
    the tall seeded U walls at the mouth face (open sections now
    extend past the block top = open-sky entry trench).
2. **Concept**: SOLID former block 28x33x20 (flat gravity sit,
    min_z=0, wall 1.0) with the scroll tunnel subtracted as 4
    hull-chained void segments over 5 stages (local x -0.5..33.5,
    world 126..159 kept): open trench entry dia 25.4
    (= paper_width, full tape, 190deg bowl) -> shut tube exit
    dia 8 (= leader_w, finished roll, closed disks from stage 3);
    bore axis ramps 14->13 (entry floor keeps 1.3 printable wall,
    exit lands on the lane datum `turner_curl_cz`); blind wick
    bore d4 from the block top down into the shut tube at local
    (26,21) (world x152, floor never pierced) for water-welding
    the PVA overlap. Interface kept: flat entry tray
    13.8x16x0.8 west of the mouth (top 3.0, tip world 112),
    nose shelf fused to the block west face + tray mortise, 2
    small 6x6x1 ears to chassis M3 holes (world 132/6, 153/54)
    + ground straps.
3. **CAD** (`seed_tape_machine_v2.scad` only): new
    `scroll_sx/R/W/cz` stage tables + `scroll_void_pts` helper
    (arc+sky-extension pre-mapped so rotate+extrude lays plates
    across X) + fresh `six_turner()` (hull used ONLY on the void
    loft, never on shell); fail-loud entry/exit dia, shut-tube,
    wall/floor/roof, wick-band, pocket-threading, tray/nose/ear
    and per-station monotonic asserts; `folding_plow()` alias
    kept; `$fn=60`, `tol=0.3`, manifold single solid, min_z=0.
    Nothing else touched.
4. **Viewer** (`web/index.html` only): `ASSET_V` 45->46, plow GLB
    rebuilt, label + `_sixTurner` hooks relabelled scroll
    (entryBore 25.4, exitBore 8, wick [152,51,4]).
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`,
    `tol=0.3`; `center_distance` 60, `gear_mesh_phase` 9°,
    back gears, crank back wall [40,-8,60], R->L order, port
    9099 only.

**Version: v61**

## v61 Clean-Sheet 6-Folder Rebuild: parametric U-to-spiral-swirl plow, zero inherited loft code - 2026-09-17

1. **Why rebuild** (user order: DON'T tweak, rebuild ONLY this
    object from scratch): v55->v60 incrementally patched the same
    7-station/17-plate loft (wrap/hook tables, hook thresholds)
    and the part still reads wrong vs Front/Back/Top.jpg. All
    `six_turner()` internals are deleted (station tables, fine
    plate tables, plate/hook/rib loft loop, `curl_strip_pts`
    helper) and rewritten as fresh parametric code.
2. **Concept** (fresh photo read: Front.jpg = wide open U mouth;
    Back.jpg = tight spiral 6 with inner tail curling toward
    centre; Top.jpg = tapered cone + flat tray past the large
    end; "6 = U bent transforming to swirl, tape folded round"):
    smooth station FUNCTIONS (no tables) over local x0..33
    (world 126..159): R(s) 10.5->4.5 linear (dia 21->9); W(s)
    180->352 smoothstep (clean open U entry, near-closed swirl
    exit, wrap strictly <360 so no self-intersecting polygon,
    open top slit full length 180deg->8deg); H(s) 0 for s<0.25
    (clean hook-free U mouth first quarter) then 0->190;
    inner hook = separate SPIRAL-diving curl (root Rh=R-1.8 =
    1.0 daylight off shell ID, tip dives proportionally toward
    centre, tip inner edge >=1.4 off axis so the bore stays
    see-through) + root stitch rib fusing hook to shell (single
    solid, daylight everywhere else). 41 fresh plates
    (pitch 0.7925, t1.3, overlapped union, ZERO hull on
    shell/hook/rib). Interface kept, rewritten: tray 13.8x16x0.8
    (world 112..125.8, top 3.0), skid nose -2 tops 3.0->8.8,
    side blade, 2 small 6x6x1 ears world (132,6)/(153,54).
3. **CAD** (`seed_tape_machine_v2.scad` only): new
    `swirl_R/W/H` functions + `swirl_shell_pts` /
    `swirl_hook_pts` / `swirl_rib_pts` helpers + fresh
    `six_turner()` (loop asserts per station); fail-loud:
    entry U 170-190deg, exit swirl 345-359deg, hook 0->150-200,
    mono ramps, W<360 all stations, exit dia 9, gap 1.0,
    hook-tip-axis clearance (see-through), pocket-threads-bore,
    tray/skid/ears proofs; `$fn=60`, `tol=0.3`, wall 0.8,
    manifold single solid, min_z=0. Nothing else touched.
4. **Viewer** (`web/index.html` only): `ASSET_V` 44->45, plow GLB
    rebuilt, legend + `_sixTurner` hooks relabelled spiral-swirl.
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`,
    `tol=0.3`; `center_distance` 60, `gear_mesh_phase` 9°,
    back gears, crank back wall [40,-8,60], R->L order, port
    9099 only.

**Version: v60**

## v60 U-to-Swirl Forming Plow: open-U entry (180°) winding to tight 6-swirl exit, matched to Front/Back/Top.jpg - 2026-09-17

1. **Concept** (user clarification: "6 = U bent transforming to
    swirl, tape folded round"): `six_turner()` is a FORMING PLOW /
    folding funnel, not a pre-curled tube. Entry (world 126, LARGE
    dia 21) = open U-channel (~180° wrap, wide slit ~180° on top,
    NO hook) catching the flat seeded tape; walls rise and curl
    inward along the 33 length (wrap 180->210->240->270->300->
    320->330, hook 0->30->60->90->120->145->160); exit (world
    159, SMALL dia 9) = fully closed swirl / "6" overlap (outer
    330° + inner hook 160° with the 1.0 daylight gap, never
    touches, see-through bore). Matches photos: Top.jpg side =
    tapered cone + flat tongue entry (tray kept); Back.jpg end =
    6-swirl exit; Front.jpg = looking through the hollow bore
    with the overlap seam. Radius taper 10.5->4.5, wall 0.8,
    hollow bore see-through, open slit full length on top, skid
    + side blade + 2 small 6x6x1 ears kept.
2. **CAD** (`seed_tape_machine_v2.scad` only): station table
    rewritten (st_W entry 300->180 with 210/240/270/300/320
    ramp, st_H entry 20->0 with 30/60/90/120/145 ramp, R
    untouched); 17 fine plates re-interpolated (fW/fH, exit
    plate snapped exact); hook+rib loft skipped while H<25°
    (entry region stays a clean hook-free U mouth; hook grows in
    at >=21° like the proven v58 minimum, one watertight solid);
    asserts updated (entry U 170-190°, exit 325-335°, hook starts
    0, monotonic kept, exit dia 9 + 1.0 gap proofs kept); tray/
    skid/blade/ears/straps/bars untouched; `$fn=60`, `tol=0.3`,
    manifold single solid, min_z=0.
3. **Tape**: untouched.
4. **Viewer** (`web/index.html` only): `ASSET_V` 43->44, plow GLB
    rebuilt, legend + `_sixTurner` hooks relabelled U-to-swirl.
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`,
    `tol=0.3`; `center_distance` 60, `gear_mesh_phase` 9°,
    back gears, crank back wall [40,-8,60], R->L order, port
    9099 only.

**Version: v59**

## v59 Photo-Matched 6-Folder: flat entry tongue/tray per Top.jpg (tray extending beyond the large end) - 2026-09-17

1. **Concept** (photo re-read with Read tool: Front.jpg hollow
    see-through bore + overlap seam = v58 shell ✓; Back.jpg
    end-view 6-section + daylight gap = v58 hook ✓; Top.jpg side
    taper + flat inner tray extending beyond the LARGE end =
    MISSING in v58): `six_turner()` keeps the full v58 shell
    (entry BIG loose 6 dia 21 at world 126 -> exit SMALL tight
    curled 6 dia 9 at world 159, wrap 300->330, hook 20->160,
    1.0 daylight gap never-touch, wall 0.8, hollow bore
    see-through, open slit full length, tapered skid + side
    blade + 2 small 6x6x1 ears) and GAINS the flat entry
    tongue/tray from Top.jpg: 13.8-long x 16-wide x 0.8-thick
    flat plate (same minimum-printable wall) extending west
    from the large mouth (local x -14..-0.2 = world 112..125.8,
    centred on the bore axis y20), top flush with the skid top
    (z 2.2..3.0 = 0.3 below the bore inner bottom 3.3, bore
    stays hollow/see-through), mortised 1.8 into an extended
    skid nose (skid front x0 -> -2, single-solid fuse), 0.2 air
    gap to the seed-cradle west face (never touches), tray tip
    well inside the chassis (world 112 vs west edge -14).
2. **CAD** (`seed_tape_machine_v2.scad` only): `six_turner()`
    gains `tray_x0/x1/w/z` params + tray cube in the union +
    skid front cube extended to the nose; new fail-loud
    asserts (tray top below bore inner bottom, tray-skid
    volumetric fuse overlap, tray-cradle 0.2 clearance, tray
    tip on chassis, tray centred on bore axis); shell/hook/
    rib/blade/ears/straps/bars/table untouched; `$fn=60`,
    `tol=0.3`, manifold single solid, min_z=0.
3. **Tape**: untouched.
4. **Viewer** (`web/index.html` only): `ASSET_V` 42->43, plow GLB
    rebuilt, legend + `_sixTurner` tray hooks.
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`,
    `tol=0.3`; `center_distance` 60, `gear_mesh_phase` 9°,
    back gears, crank back wall [40,-8,60], R->L order, port
    9099 only.

**Version: v58**

## v58 Big-to-Small 6-Turner (user direction reversal: entry BIG loose 6 dia 21 at world 126, exit SMALL tight curled 6 dia 9 at world 159, 1.0mm daylight gap) - 2026-09-17

1. **Concept** (discuss-first agreed): entry (world x126) = BIG loose
    6, wide mouth (outer dia 21, R10.5) to catch the seeded U-tape
    (lane check: 7.8 pocket + transit top 21.15 thread the 19.4 entry
    bore with room; bore axis local y20/z13 kept); exit (world
    x159) = SMALL tight curled 6, outer dia 9 (R4.5) per user.
    6-gap: inner hook edge approaches the outer circle but NEVER
    touches — ~1.0mm daylight gap full length so the tape slides.
    Thin wall 0.8 minimum printable, hollow bore see-through, open
    slit full length (wrap 300->330, never a tube), taper
    big->small along +X, flat skid underside + lower side blade,
    2 small 6x6x1 screw ears to chassis holes (132/6, 153/54).
2. **CAD** (`seed_tape_machine_v2.scad` only): `six_turner()`
    stations rewritten (7 stations x0..33, R 10.5->4.5 decreasing,
    wrap 300->330, hook 20->160, `hook_off` 3.3->1.8 so
    hook-shell daylight = 1.0); 17 fine plates re-interpolated
    (exit plate R4.5 exact = dia 9 proof); skid re-tapered
    3.0->8.8 (fused to big-entry shell, clear of bore); side
    blade re-seated mid-height fused to shell, clear of bore;
    bore-blocking posts deleted, mounts re-routed as ground-level
    bars via the skid (single solid); fail-loud asserts incl.
    exit dia == 9, gap == 1.0 (never-touch), decreasing R.
    `$fn=60`, `tol=0.3`, manifold single solid, min_z=0.
3. **Tape**: untouched.
4. **Viewer** (`web/index.html` only): `ASSET_V` 41->42, plow GLB
    rebuilt, legend + `_sixTurner` hooks relabelled big->small.
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`,
    `tol=0.3`; `center_distance` 60, `gear_mesh_phase` 9°,
    back gears, crank back wall [40,-8,60], R->L order, port
    9099 only.

## v57 Hollow-Loft Fix: hull() Filled the Bore (user visual check: thin-wall six_turner looked SOLID BLOCK + flipped) - 2026-09-17

1. **Diagnosis** (Playwright solo-plow front/back/top + trimesh GLB
    ground truth): end-on views were solid discs (no bore, no slit,
    no hook), top was a capped cone; GLB volume ~8682 vs ~3000
    expected for a 0.8 shell. Root cause: v56 `hull()`-bridged the
    300° annular-sector plates — the convex hull of an open annular
    sector includes the bore centre, so every hull segment filled
    the bore + slit solid along the full length. Orientation
    VERIFIED correct, no swap: station R grows local x0->33 =
    world 126->159 (narrow entry east of drop, wide exit), assembly
    is a pure +X translate, viewer `rot [-PI/2,0,0]` is a rigid
    rotation (no mirror), STL->GLB preserves handedness; the
    "flip" was solid-cap perspective confusion (both ends capped
    discs, far exit disc reading larger).
2. **CAD** (`seed_tape_machine_v2.scad` only): `six_turner()` loft
    rebuilt as overlapping plates, ZERO hull on shell/hook/rib —
    `plate_t` 1.2->2.2 (> 1.925 pitch, 0.275 overlap, 17 plates
    re-interpolated x0..30.8+2.2=33) unioned directly so the bore
    stays hollow, the slit stays open full length, ends stay open;
    blade/skid/ears/straps/posts untouched; wall 0.8, station
    table, `turner_curl_cz` 13, footprint x0..33, ears world
    (132,6)/(153,54), min_z=0, `$fn=60`, `tol=0.3`, manifold
    single solid, fail-loud asserts kept.
3. **Tape**: untouched.
4. **Viewer** (`web/index.html` only): `ASSET_V` 40->41, plow GLB
    rebuilt; material stays FrontSide (0.8 walls are modelled
    solids with real inner faces + correct winding — no
    DoubleSide needed).
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`,
    `tol=0.3`; `center_distance` 60, `gear_mesh_phase` 9°,
    back gears, crank back wall [40,-8,60], R->L order, port
    9099 only.

**Version: v56**

## v56 Thin-Wall Tapered 6-Folder Matching Cardboard Prototype (user: isolated views NOT accurate vs Front.jpg Back.jpg Top.jpg, rebuild properly, wall = minimum printable) - 2026-09-17

1. **Concept**: `six_turner()` rebuilt as a THIN-WALL SHELL only
    (wall 0.8 = minimum printable single wall, no thick base
    plate): loft of 7 stations local x0..33 (world 126..159,
    machine-scale former length 33; photo ~60-80 scaled to lane):
    entry narrow pinched open-C (outer dia ~12) -> exit wide open
    flare (outer dia ~21) matching the Top.jpg taper; cross-section
    open-6 full length: outer wrap 300->315deg + inner hook
    20->160deg (120-180 at exit) riding 2.5 off the shell ID
    (open slit gap 2-3 full length = the dark slit in the photo);
    lower flat tail blade full length one side (photo lower half),
    upper rolled cone other side; tapered skid wedge underneath =
    flat underside gravity sit; bore hollow see-through; tape
    shoulders feed through the top opening (intended).
2. **CAD** (`seed_tape_machine_v2.scad` only): wall 0.8 asserted;
    station table x/R/wrap/hook (see code); bore axis local
    (y20,z13); two SMALL screw ears 6x6x1 with M3 clearance
    (diagonal pair: entry local (6,-4)->world (132,6), exit local
    (27,44)->world (153,54)) on thin straps + posts — minimal, not
    a full base; `turner_curl_cz` 12->13 (lane-centred bore);
    footprint x0..33, ears inside chassis; min_z=0, `$fn=60`,
    `tol=0.3`, manifold single solid, fail-loud asserts.
3. **Tape**: untouched.
4. **Viewer** (`web/index.html` only): relabel thin-wall tapered +
    `ASSET_V` 39->40, plow GLB rebuilt.
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`,
    `tol=0.3`; `center_distance` 60, `gear_mesh_phase` 9°,
    back gears, crank back wall [40,-8,60], R->L order, port
    9099 only.

**Version: v55**

## v55 Hollow 6, Center Fin Deleted per Front/Back/Top.jpg (user reviewed cardboard prototype photos at repo root: bore must be HOLLOW see-through, no center post) - 2026-09-17

1. **Concept**: cross-section is an open "6", NOT a closed O.
    Front = open C entry, Back = 6/9 spiral exit (outer tail
    360deg + inner free edge 120-180deg hook). Asymmetric: one
    side deep in-roll ~270deg, other shallow ~180deg, tips
    overlapped. Length taper: narrow flat/pinched entry ->
    wide rolled exit. Side walls only, paper self-supports
    around air. Center EMPTY, bore hollow see-through full
    length.
2. **CAD** (`seed_tape_machine_v2.scad` only): `six_turner()`
    DELETE center fin tongue hull (`fin_t0`/`fin_t1`), wedge
    nose top, root rails inside the bore (they stabbed into
    the bore and blocked tape). Keep low flat base + outer
    side curl wings only (7 stations, left 30->270deg, right
    20->180deg). No geometry above `floor_local` inside the
    center 60% width except the side wings (fail-loud
    asserted: center-60% probe columns above floor must be
    empty at entry/mid/exit + bore see-through ray assert).
    Keep: base plate + 4 screw tabs (bx 6,27 -> world
    132/153, by -4,44 -> world 6/54, M3 clearance), footprint
    world x126-159, `$fn=60`, `tol=0.3`.
3. **Tape**: untouched.
4. **Viewer** (`web/index.html` only): relabel hollow-6 +
    `ASSET_V` bump, plow GLB rebuilt.
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`,
    `tol=0.3`; `center_distance` 60, `gear_mesh_phase` 9°,
    back gears, crank back wall [40,-8,60], R->L order, port
    9099 only.

**Version: v54**

## v54 Asymmetric Inner-Curl 6-Folder (user REJECTS outer pipe/shell again; correct spec in their words: tape arrives already bent U, inside that U ONE side wall curls IN deep, OTHER side curls LESS, curls advance along length so paper edges roll together into overlapped roll) - 2026-09-17

1. **Concept**: DELETE the outer tube/pipe shell entirely. New part
    is a SEPARATE open object that sits INSIDE the tape U: an open
    base plate/blade + center fin tongue + two asymmetric curling
    wings. Left wing: small in-turned lip (r~4) at entry progressing
    to a ~270deg in-roll (r~2.5) at exit; right wing: flat/small lip
    at entry progressing to a ~180deg in-roll meeting the left roll
    at the exit so the paper edges roll together overlapped.
2. **CAD** (`seed_tape_machine_v2.scad` only): `six_turner()`
    rebuilt with 6-7 stations over local x0..33 (world 126..159)
    interpolating per-side curl angle + radius; thin walls 1.2-1.6,
    entry lead-in chamfers, base plate with 2x screw tabs to the
    chassis (M3 holes + clearance at the old plow holes, `tol=0.3`);
    no enclosing ring, no bore. `part_to_render` plow/turner prints
    it as a separate object. `$fn=60`, manifold, fail-loud asserts.
3. **Tape**: `seed_tape_bend()` visual update only if trivial to show
    edges rolling together through it, else untouched.
4. **Viewer** (`web/index.html` only): relabel + `ASSET_V` bump, plow
    GLB rebuilt.
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
    `center_distance` 60, `gear_mesh_phase` 9°, back gears, crank back
    wall [40,-8,60], R->L order, port 9099 only.

**Version: v53**

## v53 True 6-Profile Folder Rebuild, Take 2 (user REJECTS v50 as pipe-like closed tube; "6 folder.stl" at root is the shape reference) - 2026-09-17

1. **Sample forensics** (measured for real, `trimesh` + 5 Playwright
    views on port 9099): the STL ships in inches (raw extents
    1.10x0.93x1.26) -> x25.4 = **28.0 x 23.6 x 31.9mm** former;
    OPEN sheet wrap (never a tube): wide entry trough spanning the
    full ~23.6 width with ONE flank rising into a tall tongue that
    laps OVER the top (overlap seam), exit narrows to a curled
    ~7-10 roll; cross-slices collapse to one side at the exit =
    the lapping tongue tail. Committed `web/stl/folder6_sample.glb`
    is already mm-scaled (reference only, not a machine part).
2. **Why v50 reads as pipe**: the outer shell lofts full 360° rings
    (R7.0->5.35) with only a 2mm slot slit, and the tongue
    (root buried R-0.5, 1.1 proud, same union) melts into the crown
    — from outside it is a closed tube with a slit, the overlap
    seam is invisible. The rebuild keeps footprint/world
    x126-159, width 40, mounting tabs, bore axis at lane height
    (`tape_z`=13, 7.8 pocket threads through) but makes the 6-read
    structural: progressive eccentric tongue lift (entry fused
    shallow curl -> exit floating overlap with a 1-2mm VISIBLE
    radial seam gap), taller tongue-side entry ramp blade, bigger
    entry flare trumpet; shell slot stays OPEN full length ending
    2mm; exit is an overlapping roll, NOT a ring. New fail-loud
    asserts (exit seam gap 0.8-2.0, entry fused <=0, root burial
    >=0.3, edge stops +Y of slot, footprint, pocket threading);
    min_z=0, `$fn=60`, `tol=0.3`, manifold single solid.
3. **Tape**: `seed_tape_bend()`/`fold_section` untouched — the fold
    ends at the mouth (126), the 7.8 pocket threads the open entry
    and rolls under the floating tongue (documented, not modelled).
4. **Viewer** (`web/index.html` only): `_sixTurner` hooks rewritten
    (floating-overlap entry/exit, `seamGap` 1.1), plow legend
    relabelled true-6 floating overlap; pivots/animation ratios
    untouched; `ASSET_V` 36->37, plow GLB rebuilt.
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
    `center_distance` 60, `gear_mesh_phase` 9°, back gears, crank back
    wall [40,-8,60], R->L order, port 9099 only.

**Version: v52**

## v52 Smaller Vertical Pullers + 9.5mm Nip Gap - 2026-09-17

1. **CAD** (`seed_tape_machine_v2.scad` only): vertical pullers
    downsized (were big d20): `vpull_r` 10->7.5 (d20->d15),
    `vpull_sleeve_r` 10.15->7.65 (0.15 proud kept),
    `vpull_h` 24->20, `vpull_sleeve_h` 16->12, top cap + mid
    collar d22->d17 (r+1 rim kept: 8.5 = 7.5+1). Cushioned
    surface-to-surface nip gap enforced param-driven:
    `vpull_gap=9.5`, `vpull_off=vpull_sleeve_r+vpull_gap/2`
    = 12.4 (replaces the old r+2.0+1.5+0.4+tol = 14.2
    formula); Y = 30±12.4 = 17.6/42.4; cushioned gap
    2*12.4-2*7.65 = 9.5, steel gap 2*12.4-2*7.5 = 9.8.
    Pocket 7.8 threads the 9.5 nip with 0.85/side (soft
    sleeve kisses under load, no crush). Surface speed kept
    via `vpull_spin=roller_body_r/vpull_r` = 4/3:
    `pull_a/b_angle` = ±roller_angle*spin (replaces 1:1
    `vpull_r==roller_body_r` assert). Shorter stack (top
    27): bridge 32->28, cup 29->25, pins 33/31->27; X
    envelope 186.35..201.65 keeps gaps >=5 (twister 10.35,
    take-up 8.35). New fail-loud gap assert (==9.5±0.01);
    min_z=0, `$fn=60`, `tol=0.3` kept.
2. **Viewer** (`web/index.html` only): pullAPivot
    (194,4,-15.8)->(194,4,-17.6), pullBPivot
    (194,4,-44.2)->(194,4,-42.4); new `PULL_SPIN` 4/3 scales
    both pull rotations (all 4 sites); `ASSET_V` 33->34,
    pull_a/pull_b (+chassis bridge/cup/pins) GLBs rebuilt.
3. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`,
    `tol=0.3`; `center_distance` 60, `gear_mesh_phase` 9°,
    back gears, crank back wall [40,-8,60], R->L order,
    port 9099 only.

**Version: v51**

## v51 Hollow Twister: 2 Rod Bobbin Holders, Empty Middle, Side Friction Drive (user: twister must have nothing in the middle, 2 rod-like bobbin holders, hollow support so the tape passes through) - 2026-09-17

1. **Removed** (middle now completely empty): the solid hub
   cylinder r3 + the fused coaxial X-drive shaft stub
   (apex->172) + the mid-hanger post at the tape lane + the
   coaxial X-pinion. Nothing crosses the ring bore (r8 clears
   the 7.8 tape pocket).
2. **CAD** (`seed_tape_machine_v2.scad` only):
   `thread_twister()` = outer guide ring ONLY (r10 tube2,
   YZ-plane axis-X) + 2 rod-like bobbin holders 180° apart on
   the ring (rods r1.2 h10 parallel to X at orbit radius 9.5,
   each carrying a thread bobbin r2.5 h6 on the rod, orbiting
   with the rotor, clear of the centre bore); envelope kept
   (outer 12, `twister_lift` 12 = min_z 0, station 168..176,
   gaps >= 5, cradle posts + 2mm rolling gap untouched).
   Drive (NOT coaxial): side layshaft along X at (y=45.5,
   z=17, cx->175, r2.5) + friction wheel r3.5 touching the
   ring OD (dist 15.5 = 12+3.5, CAD-asserted) + bevel 12/10
   retargeted to the side apex (cx,45.5,17); hanger post moved
   beside the tape (clears it); geared stages still exactly
   6x at the layshaft ((50/10)*(12/10), friction slip after);
   new fail-loud asserts (OD contact, rod bore clearance,
   bobbin tape-corner clearance, interior, min_z);
   stations/gaps/viewer kinematic -3x/tape/6-turner untouched;
   min_z>=0, `$fn=60`, `tol=0.3`.
3. **Viewer** (`web/index.html` only): legend + `_gearTrain`
   rewritten (side friction drive, apex I50, no coaxial
   drive); pivots/animation ratios untouched; `ASSET_V`
   33->34, twister + chassis GLBs rebuilt.
4. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
    `center_distance` 60, `gear_mesh_phase` 9°, back gears, crank back
    wall [40,-8,60], R->L order, port 9099 only.

## v50 True 6-Profile Open Folder (user REJECTS v49 closed tube; "6 folder.stl" at root is the shape reference) - 2026-09-17

1. **Sample forensics** (measured for real, `trimesh` + 4 Playwright
    views on port 9099): the STL ships in inches (raw extents
    1.10x0.93x1.26) -> x25.4 = **28.0 long x 23.6 wide x ~15 tall**
    trough-to-crown; entry rim spans the full ~23.6 width (one flank
    rises higher = the tongue side), exit pinches to a ~7 tall roll;
    cross-sections show an OPEN wrap with one edge lapping OVER the
    top (overlap seam, never welded shut). Exported scaled at origin
    as `web/stl/folder6_sample.glb` (reference only, not a machine part).
2. **CAD** (`seed_tape_machine_v2.scad` only): `six_turner()`
    rebuilt as a true open 6-profile former in the same 126..159
    footprint (mounting tabs + base + side posts + mount kept, width
    40, bore axis at lane height so the tape at `tape_z`=13 threads
    through): U-trough + ONE side wall rising + tongue curling over
    the top with a 1-2mm overlap seam gap that stays OPEN full
    length — entry shallow curl (flare funnel guides the seeded
    7.8 pocket in) -> exit deep overlap curl (round-folded roll with
    visible seam, NOT a closed ring). Deleted: v49 shut-tube section
    (local x27.5..33), exit ring (R5.6/bore r3.2), blind slot wedge.
    New fail-loud asserts (seam gap open at every station, overlap
    > 0 at exit, exit NOT a closed ring, footprint, pocket
    threading); min_z=0, `$fn=60`, `tol=0.3`, manifold single solid.
3. **Tape**: `seed_tape_bend()`/`fold_section` untouched — the fold
    ends at the mouth (126), the 7.8 pocket threads the open entry
    and rolls under the tongue (documented, not modelled).
4. **Viewer** (`web/index.html` only): `_sixTurner` hooks rewritten
    (open-seam entry/exit, `seamGap` 2.0, no `shutX`), plow legend
    relabelled true-6 open folder; pivots/animation ratios
    untouched; `ASSET_V` 35->36 (shared tree with v51 twister +
    v52 pullers; v50 plow GLB rebuilt into it).
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
    `center_distance` 60, `gear_mesh_phase` 9°, back gears, crank back
    wall [40,-8,60], R->L order, port 9099 only.

## v49 Gradual-Curl 6-Folder (user: "6 folder.stl" at root is INSPIRATION ONLY, make something nicer) - 2026-09-17

1. **CAD** (`seed_tape_machine_v2.scad` only): `six_turner()`
    rebuilt as a progressive 7-station loft in the same 126..159
    footprint (mounting tabs + base + side posts + mount kept, width
    40, straight bore axis at bore_cz kept so the lane stays
    aligned): entry open-U (slot +-3.9 + small side curl, entry
    flare + lead walls kept) -> deeper U -> C-shape -> overlap ->
    fully closed tube from local x27 + exit ring (R5.6/bore r3.2,
    crown 1.2) with the "6" seam-overlap tail at the exit only.
    Outer shell = hull-loft between station rings (R 7.0->5.6);
    inner bore tapers r4.6->r3.2 (entry dia 9.2 clears the 7.8
    pocket, exit dia 6.4 passes the finished ~8-wide roll); tapered
    top slot void closes to a wedge (closed tube needs no slot);
    side curl rails ride the slot edges (the bore void trims them,
    so they can never block the tape); v42 horns/tongue/inner-roll
    deleted (no longer needed); new fail-loud asserts (slot
    monotonic to shut, exit crown >= 1.2, exit in footprint, entry
    clears pocket, pocket-threading window); min_z=0, `$fn=60`,
    `tol=0.3`; stations/gaps/ratios/signs untouched.
2. **Tape**: `seed_tape_bend()`/`fold_section` untouched — the fold
    ends at the mouth (126), the 7.8 pocket threads the 9.2 entry
    bore and curls inside hidden steel (documented, not modelled).
3. **Viewer** (`web/index.html` only): `_sixTurner` hooks rewritten
    (stations/entry/exit), plow legend relabelled gradual-curl;
    pivots/animation ratios untouched; `ASSET_V` 32->33, plow GLB
    rebuilt.
4. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
    `center_distance` 60, `gear_mesh_phase` 9°, back gears, crank back
    wall [40,-8,60], R->L order, port 9099 only.

## v48 Parallel-Spur + Perpendicular-Pinion Twister Drive (user clarification: floor-lying gear was wrong) - 2026-09-17

1. **Removed**: the full v47 floor arrangement — slim upright shaft
   at (100,30) + floor-lying/horizontal bevels (I_top/I_bot,
   vertical 2->44, twist shaft 100->172). No floor gears remain.
2. **CAD** (`seed_tape_machine_v2.scad` only): parallel spur speedup
   tucked beside the drum (same axis orientation Y-Y, same mesh
   plane y=45, high, NOT on the floor): drum-coaxial 50T (r50,
   fused, (100,60)) -> counter 10T (r10, (~141.85,17)):
   dist 60 = 50+10 = sqrt(dx^2+43^2) exact, 50/10 = 5x; then a
   small perpendicular bevel at the twister station: Y-bevel 12T
   (same countershaft) -> X-pinion 10T (coaxial with the rotor) at
   I48 = (~141.85,30,17) = Y ∩ X 90°: 12/10 = 1.2x; total
   (50/10)*(12/10) = 5*1.2 = 6.0 exactly = 1 bind/seed (6
   cavities). One high Y countershaft (cx,17, y 1..59,
   through-wall/bracket) + one clean X stub (cx->172 at y=30,z=17,
   fused into the hub, mid hanger post meeting the shaft bottom);
   module 2 single, teeth in [10,60], parallel dist=r1+r2 +
   bevel intersection/perp/contact/interior/min_z all fail-loud;
   smallest outer bottom 3 (no floor contact, shafts >= 14);
   pull/takeup tape-coupled (no gears, documented);
   stations/gaps/ratios/signs/tape/6-turner untouched; min_z>=0,
   `$fn=60`, `tol=0.3`. Twister -3x crank, drum +0.5x kept.
3. **Viewer** (`web/index.html` only): legend + `_gearTrain`
   rewritten (parallel + perpendicular table, apex I48, mounts
   spurCounter/apex); pivots/ratios/signs/animation untouched;
   `ASSET_V` 31->32, all GLBs rebuilt `--force`.
4. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   `center_distance` 60, `gear_mesh_phase` 9°, back gears, crank back
   wall [40,-8,60], R->L order, port 9099 only.

## v47 Bevel Twister Drive, Zero Exterior Gears (user: REMOVE outside gears, twister<->drum via perpendicular bevels + proper ratio) - 2026-09-17

1. **Removed** (chassis back wall clean solid): the full v46
   exterior spur farm — DRUM40 + C-14T/21T + TW-10T + P2-12T +
   PULL-20T + J-12T + TU-10T + idler stubs + boss rings + TW timing
   tongue + pull drive tube + bridge tube-hole. Kept: interior
   crank<->drum 40:20 2:1 (ONLY spur pair, inside) + dead axles +
   pull support pins + SOLID pull bridge (no hole).
2. **CAD** (`seed_tape_machine_v2.scad` only): new `bevel_gear()`
   module (pitch cone + teeth suggestion + slip bore, Z-built, $fn=60);
   TWO true 90° bevel pairs on interior shafts — drum-shaft 20T
   (fused, axis Y) -> vertical-top 10T (axis Z) = 2x at
   I_top=(100,30,60); vertical-bottom 30T (same jackshaft at
   (100,30), 2->44) -> twister-shaft 10T (axis X, shaft 100->172
   fused into the rotor hub) = 3x at I_bot=(100,30,17); total
   (20/10)*(30/10)=6.0 = 1 bind/seed (6 cavities). Module 2 single,
   teeth in [10,60], apices/intersection/perp/contact/interior/
   min_z all fail-loud asserted; pull/takeup tape-coupled (no
   gears, documented); stations/gaps/ratios/signs/tape/6-turner
   untouched; min_z>=0, `$fn=60`, `tol=0.3`.
3. **Viewer** (`web/index.html` only): train legend rewritten
   (bevel note, zero exterior gears), `_gearTrain` carries the
   bevel table + apices; pivots/ratios/signs/animation untouched;
   `ASSET_V` 30->31, all GLBs rebuilt `--force`.
4. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   `center_distance` 60, `gear_mesh_phase` 9°, back gears, crank back
   wall [40,-8,60], R->L order, port 9099 only.

## v46 Shaft-Mounted Gear Train (user: GEAR SETUP incorrect, tape/shafts v45 fine) - 2026-09-17

1. **Close-up audit** (port 9099 Playwright back-wall closeups
   `audit_train_wide/twister_end/pull_end/crank_drum.png` + CAD
   gear-plane math): meshes were numerically dist=r1+r2, but
   mechanically misplaced — TW-10T 7.3 off the rotor (170,24 vs
   172,17, bracket fiction, spur cannot reach the X-axle rotor);
   PP-20T 2.5 off the nip (196.46,28.79 vs 194) dead-ending with no
   transfer to the vertical rollers; C/P1/P2/PP/TW boss visuals with
   NO modeled axles (floating cantilevers, gears 5 off the wall);
   take-up hung off the shared PP layshaft. Coplanar per plane,
   sizes/ratios/directions were correct — placement + support were not.
2. **CAD** (`seed_tape_machine_v2.scad` only): shaft-mounted train,
   all module 2, every mesh dist=r1+r2 (fail-loud <= tol+0.01),
   half-pitch phasing, min_z>=0, `$fn=60`, `tol=0.3` — DRUM40
   (100,60, drum shaft) -> C-14T/21T compound (149.42,38.24, dist
   54) -> TW-10T at (bind_x,twister_axle_z)=(172,17) rotor-coaxial
   (dist 31, 6x drum, wall-fused timing tongue 1.5 off hub);
   C-14T -> P2-12T (173.50,28.43, dist 26) -> PULL-20T (194,53,
   dist 32, pull-A axle line, genuine drive: static pin base->55
   + tube ring fused cap<->gear spinning on pin + in bridge hole,
   1:1 crank); PULL -> J-12T (225.86,56.00, dist 32) -> TU-10T
   (226,34, reel-coaxial, dist 22, 2x crank, sense unchanged).
   8 pieces / 3 layshafts (P1/PP deleted); idlers bored on modeled
   stubs fused into solid bosses + wall (cantilever+boss); pins/
   slips/fuses/holes all fail-loud asserted; stations/gaps/ratios/
   signs/tape/6-turner untouched.
3. **Viewer** (`web/index.html` only): legend + `_gearTrain`
   (chain/mesh/mounts incl. coaxial proof points) rewritten;
   pivots/ratios/signs/animation untouched; `ASSET_V` 29->30, all
   GLBs rebuilt `--force`.
4. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   `center_distance` 60, `gear_mesh_phase` 9°, back gears, crank back
   wall [40,-8,60], R->L order, port 9099 only.

## v45 Forensic Tape-Path + Mount Integrity Fix (user: model still incorrect at all angles) - 2026-09-17

1. **Forensic method**: 19-angle Playwright capture (ISO/TOP/FRONT/SIDE/
   END-ON/BOTTOM + 8 station closeups, animating timestamps) + trimesh GLB
   ground truth + live vertex-sampling probes. Cleared as NOT defects:
   exterior gears (truly exterior, 5 off wall on bosses; dotted look =
   tooth lighting), hopper-drum interface, 6-turner, twister ring/threads,
   pull nip/bridge, take-up/clutch, R->L order. Found + fixed:
2. **D1 tape scroll-dangle (viewer)**: ribbon `100+mod(advance,62.83)`
   slid +/-63mm per rev — uncovered spool/nip/forming at high phase and
   dangled ~50 past the chassis east end (f_iso_t3 proof). FIX: ribbon
   STATIC at the CAD span (TAPE_LEN 270->222 = -14..208, centre 97);
   advance readout still counts mm. Regression test: tapeGroup.x equal
   across animating timestamps.
3. **D2 wind-up disconnect (CAD+viewer)**: flat ribbon ran UNDER the bare
   reel core (~13 gap) to 256, past reel/chassis, never engaging. FIX:
   `seed_tape_bend()` flat ends at `tape_flat_end`=208 (east of nip caps
   205, west of reel flange 210) + narrow leader strip (w8, folded-tube
   width) 206..224.5 climbing ribbon-top -> wound pack r8 (fused both
   ends, min_z=0, watertight); viewer mirrors 1:1 (+`_windLeader` hooks);
   fail-loud asserts (flat reach, leader overlap, flange clearance,
   leader-inside-pack, pack-radius match).
4. **D3 floating rotating parts (CAD)**: DRUM40/TU exterior gears + drum +
   reel + spool cones were held by NOTHING (bores/holes, no shafts —
   comments claimed through-shafts that did not exist). FIX: static dead
   axles in `chassis()` — drum hex (fused into solid DRUM40, slip in drum/
   gear hex bores + wall/block holes), take-up round r4 (fused into solid
   TU, slip in reel/wall/block bores), spool round r4 (slip in cone hex
   holes + bores, ends hidden in block bores); ends buried/hidden, never
   coplanar; fail-loud seat/slip asserts.
5. **D4 twister posts grazed the ring (CAD)**: cradle posts (full height
   17) intersected the swept ring tube by ~1 (analytic). FIX: posts to
   `twister_post_h`=13 (2 rolling gap, cradled not floating; through-axle
   impossible — product passes through the bore); assert 1.5..4 window.
6. **D5 pull mid-collar grazed the tape (CAD)**: r11 collar at z 12 (top
   13.5) clipped 0.5 into the ribbon over a ~9 strip. FIX: collar to
   `vpull_collar_z`=5.0 local (CAD top 10.5, clears ribbon 13 by 2.5, CAD-asserted).
   Sleeve/rib grip at the nip (0.15) is intended soft grip, kept.
7. **Viewer** (`web/index.html` only): static ribbon + leader mesh +
   `_windLeader` hooks + tape-path comment; pivots/ratios/signs/mounts
   story unchanged; `ASSET_V` 28->29; dirty GLBs rebuilt (chassis:
   shafts+posts; pull_a/b: collar; tape: flat+leader).
8. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   `center_distance` 60, `gear_mesh_phase` 9°, back gears, crank back
   wall [40,-8,60], R->L order, port 9099 only; module-2 meshes, two-stage
   6-turner logic, drum-driven 8-gear train, gaps>=5, min_z>=0 all kept.

## v44 Minimal Drum-Driven Gear Train (user: too many gears) - 2026-09-17

1. **Goal**: drive simply FROM THE DRUM. The crank<->drum 2:1
   (dist 60 = 20+40, module 2, phase 9°) is the only crank
   connection. The v43 long spine (E0..H3 8x chain + compounds
   across the wall + GT/GJ/GS far chain, 16 pieces) is removed.
2. **CAD** (`seed_tape_machine_v2.scad` only): exterior DRUM40 at
   (100,60) rigid on the drum shaft; twister DRUM->C20/C30
   compound (159.94,62.71, dist 60)->TW-10T (170,24, dist 40,
   6x drum, 7.3mm bracket to rotor); pull DRUM->P1-12T
   (141.07,28.10, 52)->P2-12T (164.77,24.34, 24)->PP-20T
   (196.46,28.79, 32, 1:1 crank); take-up PP(shared
   axle)->TU-10T (226,34 coaxial reel, 30, 2x crank, sense
   unchanged vs v43). 8 pieces / 5 layshafts; module 2, every
   mesh dist=r1+r2 (fail-loud <= tol+0.01), half-pitch phasing,
   bosses + through-holes, same-plane non-mesh clearance >=6
   (closest C-P2 6.67), min_z>=0, `$fn=60`, `tol=0.3`;
   animated angles unchanged; stations/gaps untouched (>=5),
   6-turner two-stage untouched.
3. **Viewer** (`web/index.html` only): gear comments/legend/
   `_gearTrain` rewritten minimal-drum-driven; pivots/ratios/
   signs unchanged; `ASSET_V` 27->28, all GLBs rebuilt.
4. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   `center_distance` 60, `gear_mesh_phase` 9°, back gears, crank back
   wall [40,-8,60], R->L order, port 9099 only.

## v43 True-Meshed Gear Train (decorative-idler audit fix) - 2026-09-17

1. **Audit (user-report confirmed)**: only crank20<->drum40 truly
   meshed (dist 60 = r20+r40, module 2, phase 9°). Idler1 20T at
   (110,60): 10 off drum (needs 60), 70 off crank (needs 40) —
   fused decoration. Idler2 12T at (183,17): >60 from any gear —
   decoration. Twister/pull/take-up had animation ratios but no
   gears, no mesh phase, no through-axles (modules were all 2, ok).
2. **CAD** (`seed_tape_machine_v2.scad` only): new exterior train,
   all module 2, every pair dist=r1+r2 (fail-loud <= tol+0.01),
   half-pitch tooth phasing, layshaft bosses + wall through-holes
   (no float): plane-A 12T chain E0(40,60)->H1->R0->80->104->128->
   152->H3->PC(190.22,30, pull layshaft 1:1, sign kept); drum
   takeoff D2-20T->L1a-12T/L1b-36T compound (130.91,51.72, dist
   32); plane-B L1b->L2-10T twister pinion (166.05,22.03, dist 46,
   6x drum, sign kept, 6mm transfer to rotor) + L1b->GT-15T
   (178.83,69.16, 51)->GJ-15T (205.94,56.31, 30)->GS-15T (226,34
   coaxial reel, 30) = 2x crank, sense reversed (takeup_angle
   +1440t->-1440t); same-plane non-mesh clearance >=6; min_z=0,
   `$fn=60`, `tol=0.3`; stations/gaps untouched (>=5), 6-turner
   geometry untouched.
3. **Viewer** (`web/index.html` only): take-up sign flipped
   (`-2*crankAngle`->`+2*crankAngle`, both call sites), gear-train
   comments/legend/`_gearTrain.mesh` rewritten meshed; pivots,
   twister/pull ratios unchanged; `ASSET_V` 26->27, all GLBs rebuilt.
4. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   `center_distance` 60, `gear_mesh_phase` 9°, back gears, crank back
   wall [40,-8,60], R->L order, port 9099 only.

## v42 True 6-Fold Second Stage (two-stage: U then fold edges inside to roll) - 2026-09-17

1. **Clarification (user)**: tape is ALREADY U-bent by the first
   stage (forming 37..70 + transit 70..126). The 6-turner is a SECOND
   bending piece: entry accepts the seeded U-section, then two
   symmetric curl channels roll the left/right U edges inward/down
   into an overlapping roll (6 cross-section), exit is a near-closed
   tube. The old impl wrongly treated the turner as a single
   U-forming tube (r6.5 bore r4.2 only).
2. **CAD** (`seed_tape_machine_v2.scad` only): `six_turner()` reworked
   into a true 6-profile second stage in the same 126..159 zone
   (mouth still 26 after drop 100, seed lands flat/open-U first):
   STAGE A entry U-accept channel (x 0..12 side walls, inner faces
   +-3.9 clear the 7.8 pocket) + low converging guides kept;
   STAGE B twin edge-curl horns (solid former noses r2.5 at cy+-4.2,
   x 6..20, bridge fins + foot posts fuse to tube/base) + inner
   tongue plate diving crown->bore ending in an inner roll (r2.2,
   x 12..26 inside the bore, post-cut union so the bore void cannot
   delete it) = the inner loop of the "6", folding edges INSIDE;
   STAGE C exit ring (r5.5/bore r3.2 necked near-closed) + top
   seam-overlap lip so the end-on cross-section reads as 6 (outer
   curl + inner tongue), not a plain round tube. Main bore r4.2
   offset +1.2 (dia 8.4 clears 7.8) kept; footprint/tabs/posts kept;
   5 new fail-loud asserts (horns fused, inner roll inside tube,
   exit in footprint, exit necked, horns clear base); min_z=0,
   `$fn=60`, `tol=0.3`, gear-only drive/positions unchanged;
   stations preserved (turner lip 160.35 -> twister 168 gap 7.65,
   gaps >= 5).
3. **Viewer** (`web/index.html` only): plow relabelled 6-turner
   2nd-stage edge fold, legend/tape-path comments rewritten two-stage
   (U then 6-fold edges inside to roll), `_sixTurner` gains
   stages/entry/exit hooks; pivots/animation ratios unchanged;
   `ASSET_V` 25->26, all GLBs rebuilt.
4. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   `center_distance` 60, `gear_mesh_phase` 9°, back gears, crank back
   wall [40,-8,60], R->L order, port 9099 only.

## v41 6-Turner + Gear-Only + Mounts + Clutch Build (v39/v40 spec) - 2026-09-17

1. **Goal**: build the v39+v40 spec onto the v38 respaced stations
   (positions frozen: turner 126..159 -> bind 172 -> pull 194 ->
   take-up 226/34, edge gaps 9/8/6 >= 5).
2. **CAD** (`seed_tape_machine_v2.scad` only): new `six_turner()`
   (6-curl tube r6.5/bore r4.2 offset +1.2 + entry flare + curl-over
   tongue + posts, same 33x40 footprint; `folding_plow()` kept as a
   compat wrapper, `part_to_render` "plow" alias + new "turner");
   turner mouth 126 sits 26 after drop 100 (flat landing first);
   `vpull_roller()` gains a cushioned rubber/silicone sleeve visual
   (r10.15, OD ~d20 => 1:1 kept); `takeup_reel()` gains a slip clutch
   on the axle (2 discs + spring + hex nut, stack 31..41, h_total 41,
   envelope 210..242 kept); chassis gains pull top bridge (side
   mount, X 192..196 inside nip), 2 idler spur visuals on back-wall
   bosses (20T drum drive 110/60, 12T twister layshaft 183/17,
   gear-only, no belts) + mounting comments (bottom: turner+wind-up;
   side: twister+pull+drum through walls; top: hopper+shroud+spools);
   8 new fail-loud asserts (turner aliases/position, 3 edge gaps on
   turner/sleeve names, sleeve OD, step-up, clutch stack/envelope);
   min_z=0 all, `$fn=60`, `tol=0.3` kept.
3. **Viewer** (`web/index.html` only): plow relabelled 6-turner,
   pull pair dark rubber (metalness 0.05/rough 0.9), take-up child
   15.5->20.5 (h 41 recenter), legend/tape-path/mounts/gear-only/slip
   comments, new `_sixTurner/_gearTrain/_slipClutch/_mounts` hooks;
   pivots/animation ratios unchanged (gear-only sync proof);
   `ASSET_V` 24->25, all GLBs rebuilt.
4. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   `center_distance` 60, `gear_mesh_phase` 9°, back gears, crank back
   wall [40,-8,60], R->L order, port 9099 only.

## v39 6-Turner + Gear-Only Drive + Cushioned Pull - 2026-09-17

- Replace U-plow with 6-shaped turner/roller former (tape with seed passes through 6 curl to roll edges over); twister/pull/wind all crank-driven via gears only (no belts) – crank→drum 2:1 → twister 6× per drum via idler spur → vertical pull 1:1 → wind-up step-up; vertical pull rollers cushioned (soft rubber/silicone) for firm grip without crushing
- v39 overrides plow to 6-turner (all prior "folding plow / U-plow / after plow" references now mean the 6-shaped turner/roller former).

## v40 Mounting + 6-Position + Slip Clutch - 2026-09-17

- **Mounting specs (all components)**:
  - Bottom mount: 6-turner + wind-up reel
  - Side mount: twister ring + pull rollers + drum (axles through chassis walls)
  - Top mount: hopper+shroud + tape input spools
- **6-turner position**: positioned a little after the drop point (not directly under it) so seed lands flat first, then rolls through the 6 curl to fold the tape
- **Wind-up reel**: slip clutch on axle to handle changing reel diameter (fast when empty, slips when full)
- v40 refines v39 MVP items 7 (6-turner position) and 10 (wind-up slip clutch) + adds mounting layout.

## v38 Downstream Respace (v37 overlap fix) - 2026-09-17

1. **Goal**: fix v37 steel overlap (twister 163..171 touched pull
   171..191 at X=171, take-up 170..202 interpenetrated both in X/Y/Z).
   Sequential eastward with >=5mm steel X gaps: plow end 159 ->
   twister 172 (168..176, gap 9) -> pull 194 (184..204, gap 8) ->
   take-up 226/34 (210..242, gap 6); centres 32 vs 26+0.3+5=31.3.
2. **CAD**: bind_x 167->172, pull_x 181->194, takeup 186/28->226/34,
   chassis_len 214->262 (east 248), tape 220->270, 3 fail-loud gap
   asserts; gearing/animation unchanged; min_z=0, $fn=60, tol=0.3 kept.
3. **Viewer**: pivots to 172/194/226-34, BIND_X 172 (HALF 7), TAPE_LEN
   270, tape-path comment, ASSET_V 24, GLBs rebuilt.
4. **Frozen**: v1 scad + web/backup/ untouched; port 9099 only.

## v37 Thread-Bind + Vertical Pull + Wind-Up Build (v36 spec) - 2026-09-17

1. **Goal**: build the v36 MVP tail: 2 threads orbit the tape after the
   folding plow (one bind per seed), vertical nip rollers pull the
   finished tape at constant speed (spacing driver), take-up spool winds
   it; all geared to the drum (6 cavities, 6 inch / 152.4mm intent).
   Process: hopper 9 o'clock -> 11-6 channel -> 6 o'clock drop onto the
   1in folded tape -> thread bind -> vertical pull -> wind-up.
2. **CAD** (`seed_tape_machine_v2.scad` only): new `thread_twister()`
   (ring r10 + hub + 2 arms/bobbins at bind_x=plow_end+8=167, axle
   z=tape_z+4=17), `vpull_roller()` x2 (vertical-axis d20 h24 at
   pull_x=181, y=30±14.2 flanking the 7.8 folded pocket, same dia as
   main roller = 1:1 surface speed), `takeup_reel()` (core d10 +
   r16 flanges + tape pack at takeup_x=186/takeup_z=28); chassis gains
   take-up bearing blocks + axle holes + twister posts; tape 214->220
   reaches the reel; `part_to_render` branches twister/pull_a/pull_b/
   takeup; animated_assembly gears twister -2160t / pull ±roller /
   takeup +1440t; fail-loud asserts (bind>plow, 2 arms, 6 orbits==6
   cav, pull dia==roller dia, takeup east + flange clear, tape reaches
   reel); min_z=0 all; `$fn=60`, `tol=0.3` kept.
3. **Viewer** (`web/index.html` only): twister/pullA/pullB/takeup pivots
   + PART_DEFS + PART_ORDER, animation synced (twister -3x crank about
   X, pull ±2x about Y, take-up -2x about Z), 2 procedural thread helix
   lines through the bind zone + `window._twister` proof hooks, tape
   path comment extended spool->nip->forming->transit->plow->bind->
   pull->wind; `ASSET_V` 23, all GLBs rebuilt.
4. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   `center_distance` 60, `gear_mesh_phase` 9°, back gears, crank back
   wall [40,-8,60], R->L order, port 9099 only.

## v36 Thread-Wrapping + Vertical Pull + Wind-Up to MVP (v15 spec backfill) - 2026-09-17

- Add thread-wrapping + vertical pull + wind-up to MVP: 2 threads orbit tape after folding plow to bind each seed, vertical nip rollers pull finished tape at constant speed (spacing driver), take-up spool winds finished tape; all geared to drum 6 cavities for 6 inch spacing
- Backfills the v15 (2026-09-16) MVP request: item 6 (tape 1 inch + thread bind), item 7 (spacing via vertical pull + gear ratio), new items 10 (thread unit + pull/wind) and 11 (process flow hopper 9 o'clock -> channel -> 6 o'clock -> bind -> pull -> wind-up). File history v16-v35 kept intact (v15 slot was already taken by the changes.jpg markups entry).
- MVP Update section renamed to "(v15 refinements)" with items 1-9 kept, 6/7 updated, 10/11 added per spec.

## v35 Thinnest-Wall Pipe (OD10/ID7.6/Wall1.2) + Entry Lead-In - 2026-09-17

1. **Goal (user-confirmed)**: thinnest printable wall on the OD10
   exit pipe: wall 2.0->1.2, so ID 6->7.6 (OD10 fixed). Lane
   geometry unchanged (`tape_z` 13, ribbon top 13.4, pipe world
   23.4..33.4, gap 10, flange-to-tape 20.1): only the bore +
   funnel throat + fold-fit note.
2. **CAD** (`seed_tape_machine_v2.scad` only): `drop_pipe_id`
   6->7.6 (assert `==7.6`, wall assert `==1.2` replaces `==2.0`;
   bore X +-3.8, tube X +-5, X wall 1.2); inner cone r3->r3.8
   (wide 16 -> 7.6 throat, half-angle ~8.6° from vertical —
   steep, no hang); outer cone r5->r10 kept (wall 1.2 at pipe,
   growing to 2.0 at funnel top); fold kept 4-wide R1.5 walls5.5
   (outer 7.8 < OD10; pocket mouth inner 7 < ID7.6 — seed lands
   INSIDE the pocket, good); L10 / gap10 / export -19.4 /
   min_z=0 kept; `$fn=60`, `tol=0.3`, drum/roller/crank/R->L/
   fold-before-drop intact.
3. **ENTRY INSPECTION (seed stops at pipe entry?)**: measured —
   trimesh probe of the hopper STL: the drum carve eats the whole
   funnel above ~1 over the pipe top, so the funnel is a short
   stub opening straight into the drum mouth (wide 16 design
   intent, actual mouth = carve opening, no shallow-angle hang);
   throat-to-bore profile is monotonic (no radial step, <=0.3 ✓);
   throat centre local x=0 = drum drop point world x=100,
   Y centred (offset 0.0 < 0.5 ✓); ONE real catcher found:
   sharp 90° circular inner rims at the bore ends (bottom exit
   lip + bore-to-cone edge — knife edges that shave/catch
   off-centre seeds). Drop path itself is a clear cylinder ID7.6
   from drum mouth to tape.
4. **FIX (lead-in, 45° break, leg>=0.6)**: throat entry flare
   (r3.8->r4.6 over h0.8, 45°, self-clearing) breaks the
   bore-to-cone edge; bore exit flare (r3.8->r4.4 over h0.6,
   45°, 0.6 flat land left) breaks the bottom inner edge; cone
   base follows at r4.6 (continuous profile, slope-only kinks,
   no radial step). Fail-loud asserts (throat_cx == drum_cx,
   flare legs >=0.6).
5. **SEED-FIT NOTE (fail-loud)**: ID7.6 still < 8mm seeds — OD10
   fits only <=6mm seeds (ID7.6 minus clearance). Revert to v33
   (ID10/OD14) if 8mm seeds must drop through the pipe.
6. **Viewer** (`web/index.html` only): `_dropSeal` bore 6->7.6
   (outer 10 kept); `ASSET_V` 21->22, all GLBs regenerated.
7. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`,
   `tol=0.3`; `center_distance` 60, `gear_mesh_phase` 9°, back
   gears, crank back wall [40,-8,60], R->L hopper > drum >
   shroud > roller+crank kept; port 9099 only.

## v34 OD10 Exit Pipe (ID6/Wall2.0 L10 + 10 Gap, Fold 4/R1.5) - 2026-09-17

1. **Goal (user-confirmed)**: exit pipe outer diameter 10mm
   including wall (was ID10/OD14). Lane geometry unchanged
   (`tape_z` 13, ribbon top 13.4, pipe world 23.4..33.4, gap 10,
   flange-to-tape 20.1): only diameters + fold shrink.
2. **CAD** (`seed_tape_machine_v2.scad` only): `drop_pipe_od`
   14->10, `drop_pipe_id` 10->6 (wall kept 2.0 per user, assert
   `==2.0` replaces `>=1.2`; bore X +-3, tube X +-5); outer cone
   r5->r10 + inner cone r3->r8 (wide 16 -> 6 throat, wall 2.0
   throughout); `fold_width` 6.0->4.0, `tape_bend_radius`
   1.75->1.5 (outer = 4+2*(1.5+0.4) = 7.8 < OD10, assert now
   outer-half <= 5.0; pocket mouth inner = 4+2*1.5 = 7 ~=
   ID6); transit top 21.4->21.15 (disc clearance 13.85, 2.25
   under the pipe mouth, no touch); walls 5.5 / L10 / gap10 /
   export -19.4 / min_z=0 kept; `$fn=60`, `tol=0.3`,
   drum/roller/crank/R->L/fold-before-drop intact.
3. **SEED-FIT WARNING (fail-loud, user accepted)**: ID6 < 8mm
   seeds AND < 6mm max wheel seeds — 8mm seeds CANNOT pass a
   printable OD10 pipe (even min wall 1.2 -> ID7.6 < 8). OD10
   fits only <=5mm seeds (ID6 minus clearance). Revert to
   v33 (ID10/OD14) if 8mm seeds must drop through the pipe.
4. **Viewer** (`web/index.html` only): `TAPE_BEND_R`
   1.75->1.5, `TAPE_FOLD_HW` 3.0->2.0 (arc centres y=1.9,
   former/collar/foot auto-follow), `_dropSeal` bore 10->6 /
   outer 14->10 (pipe bottom 23.4, ribbon 13.4, gap 10, drop
   x=100 kept); `ASSET_V` 20->21, all GLBs regenerated.
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`,
   `tol=0.3`; `center_distance` 60, `gear_mesh_phase` 9°, back
   gears, crank back wall [40,-8,60], R->L hopper > drum >
   shroud > roller+crank kept; port 9099 only.

## v33 Option B Drop-Tape-Lower (Hover Pipe ID10/OD14 L10 + 10 Gap) - 2026-09-17

1. **Goal (user-confirmed option B)**: fit a round ID10/OD14 L10 pipe
   plus a >=10mm air gap under the wheel. v32 clearance was tape top
   24.4, flange bottom 33.5, disc 35.0 = only 9.1mm. v33 lowers the
   tape lane ~11mm (`tape_z` 24->13, ribbon top 13.4) so
   flange-to-tape = 33.5-13.4 = 20.1 (>=20 = L10+gap10), disc-to-tape
   = 21.6, transit pocket top 21.4 clears the disc by 13.6.
2. **CAD** (`seed_tape_machine_v2.scad` only): `tape_z` 24->13
   (forming 37..70 + transit 70..126 geometry auto-follows; former
   shoe rides `tape_z+tape_thick`); `shroud_h` 34->23 (roof 21..23,
   ends open 0..21, slot half 6.45 + d10 ports kept, port_z 18 spans
   13..23); `hopper_body()` sealed rectangular tube REPLACED by a
   hover assembly — round pipe OD14 (r7) L10 from local 19.4 (world
   23.4 = ribbon top 13.4 + gap 10, hover, no seal/slots) to local
   29.4 (world 33.4) fused into a tapered outer cone (r7->r10) to
   local 52, inner void = ID10 bore (r5) + tapered groove (r5->r8,
   wide 16 -> 10 throat) to the drum mouth; drum carve trims the
   funnel top (mouth stays open); old drop-window box + E/W wing
   slots + U clearance deleted; export offset -19.9->-19.4 (min_z=0
   kept); fail-loud asserts (ID/OD/L10, wall 2.0>=1.2, bottom ==
   tape_top+10, gap>=10, flange-to-tape>=20); `$fn=60`, `tol=0.3`,
   drum/roller/crank/R->L/fold-before-drop intact.
3. **Viewer** (`web/index.html` only): `TAPE_Z` 24->13 (fold/ribbon/
   collar/drop path follow), hopper child `[0,19.9,0]`->`[0,19.4,0]`
   (re-seats drum centre for the new export drop), `_dropSeal`
   23.9/24.4->23.4/13.4 + pipeLen/hoverGap hooks, dropSeed falls
   30->14 through the bore into the pocket; `ASSET_V` 19->20, all
   GLBs regenerated.
4. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   `center_distance` 60, `gear_mesh_phase` 9°, back gears, crank back
   wall [40,-8,60], R->L hopper > drum > shroud > roller+crank kept;
   port 9099 only.

## v32 Viewer Displacement Audit Fix - 2026-09-17

1. **Displacements found** (Playwright world-box audit + trimesh GLB
   ground truth, v31 geometry itself correct): (D1) hopper assembly
   floated +6mm — viewer child still `[0,25.9,0]` (v29 export drop)
   while v31 CAD exports `-19.9`: tube bottom sat at world 29.9 vs
   intended 23.9 (5.7mm spill gap over the ribbon), cover ring ran
   6mm eccentric to the drum (mouth gap opened at top, clipped the
   wheel at the bottom lip), hopper top 94.5 vs 88.5. (D2) flat
   ribbon rode 0.2 low (procedural mesh centred on the lane: top
   24.2 vs seal reference 24.4, would have left only 0.3 overlap
   after D1). v31 verify passed because `_dropSeal` asserts constants,
   not mesh placement.
2. **Fix (viewer only, CAD untouched)**: hopper child
   `[0,25.9,0]`->`[0,19.9,0]` (re-seats drum centre, tube bottom
   23.9 = 0.5 into ribbon top 24.4, cover coaxial again, bore 10 /
   outer 14 kept); tape mesh `+0.2 Y` (ribbon 24.0..24.4, exact 0.5
   seal overlap); stale `y=25` ride-height comment corrected.
3. **Verified NOT displaced** (kept): drum [100,60] R25, roller 40,
   crank [40,-8,60] back wall, shroud 58..84 + slot 6.45, forming
   37..70 + transit 70..126 + collar 67, plow 126..159, spool -6,
   R->L order, back gears + 9° phase, $fn=60, tol=0.3, min_z=0 all
   GLBs (trimesh proof).
4. **Viewer**: `ASSET_V` 18->19, all GLBs regenerated (identical
   geometry, cache-busted); new `verify_v32.js` proves placement
   from live mesh bounds (tube bottom 23.9±0.15, ribbon top
   24.4±0.05, overlap 0.5±0.2, hopper centre on drum axle ±0.15),
   not constants.
5. **Frozen**: v1 scad + web/backup/ untouched; port 9099 only.

## v31 Fold-Under-Drum Regression Fix - 2026-09-17

1. **Regression**: v30 put the forming zone 67..100 exactly under the
   drum wheel (drum x=100 R25 spans 75..125, bottom z=35) while the
   full-U walls rise to world 38.1 — measured 3.1mm manifold merge of
   fold walls INTO the drum disc (Playwright end-on isolate shot
   v31_base_endon + analytic proof). The v30 shroud overlap (fold
   67..84 inside the 58..84 tunnel, walls 37.6 vs top plate 32..34)
   pierced the shroud top too. Requirement: U-bent tape is SUPPLIED TO
   the exit (drop) pipe through its side inlet, never merged with the
   wheel. Fix (a): forming station fully clear west of the drum face.
2. **Verified coords**: forming 37..70 (`fold_start`=37, `fold_len`=33
   kept, `fold_end`=70 <= 75-4 face-4); straight full-U transit
   70..126 (`transit_end`=`plow_start`, same R1.75/trough-6/wall-5.5
   section, no taper) runs through the shroud slot, under the drum
   with >=1.6 air gap, into the tube WEST side inlet (93), through the
   bore (seed drops at x=100 into the already-folded pocket), on to
   the plow mouth (126) which closes it. Lane `tape_z` 30->24:
   transit top world 32.6 vs drum bottom 35 = 2.4 (flange rings 1.6+);
   flat ribbon top 24.4; tube bottom world 23.9 = 0.5 seal overlap
   kept. Drop/seed feed still at drum 6-o'clock (x=100); gravity path
   untouched.
3. **CAD** (`seed_tape_machine_v2.scad` only): new `transit_end/
   transit_len` params; `fold_section(x0,dx,sc)` helper (forming taper
   loop + transit sc=1 loop, ~4mm chunks); `hopper_body()` tube_z0
   25.9->19.9, wing band 25.7->19.7, U slot 26.7..35.0->20.7..29.6
   (half-width 5.45->6.45 to pass the shoulder kinks), drop window
   29..42->19..42 (local), export offset -25.9->-19.9;
   `u_channel_shroud()` top plate gains central slot (half 6.45, full
   length, strips 8.55/side printable) for the transit walls+kinks; collar seat
   stays `fold_end-3` (67, clear of wheel); bore 10 / outer 14, R1.75,
   trough 6, walls 5.5, min_z=0, $fn=60, tol=0.3 untouched; fail-loud
   asserts (forming exit west of face, entry at nip 35..45, transit =
   plow mouth + fits ribbon, transit top+1 <= drum bottom).
4. **Viewer** (`web/index.html` only): forming 37..70 + transit to 126
   (`tapeFoldSection`, 8mm chunks), lane `TAPE_Z`=24, `_tapeFold`
   gains `transitEnd/laneZ`, `_dropSeal` 23.9/24.4, dropSeed path
   lowered; `ASSET_V` 17->18, hopper+shroud+tape GLBs rebuilt.
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   `center_distance` 60, `gear_mesh_phase` 9°, back gears, crank back
   wall [40,-8,60], R->L hopper > drum > shroud > roller+crank kept;
   port 9099 only.

## v30 Fold-Before-Drop Order Fix - 2026-09-17

1. **Goal**: the U-bend must form BEFORE the seed enters, not after. v29
   folded 126..159 EAST (downstream) of the drop at x=100, so the seed
   fell onto flat ribbon and folded later — wrong order. v30 moves the
   fold zone upstream: world x 67..100 (shallow entry in the shroud
   58..84, full-U exit at x=100 under the drop tube); the seed drops
   into the already-folded pocket; the east plow (126..159, v1
   precedent kept) now closes/seals the seeded pocket downstream.
2. **Verified coords**: drop at world x=100; fold zone 67..100
   (`fold_start`=67, `fold_len`=33, `fold_end`=100=`drum_axle_x`);
   fold exit x (100) >= drop x (100) - 3 and fold max x (100) <= 100+7
   (tube outer) — fold before/at drop, never after. Trough (6 wide,
   HW 3.0) centered under the bore (10 wide, +-5); fold outer half
   5.15 fits the tube interior (7.8).
3. **CAD** (`seed_tape_machine_v2.scad` only): new `fold_start/fold_len/
   fold_end` params decoupled from the east plow; `seed_tape_bend()`
   `fx0` 140->81 (`fold_start-tape_x0`), `dx` from `fold_len`, taper
   unchanged (W shallow -> E full-U at the drop); `tape_len` 180,
   `tape_z` 30, R1.75, trough 6, walls 5.5, S-shoulders kept;
   `former_collar()` assembly seat `plow_end-3` (156) -> `fold_end-3`
   (97, over the fold exit at the drop); drop-tube E/W notches gain a
   central U clearance (half-width 5.45 = hw+r+thick+tol, local z
   26.7..35.0, clears wall top ~34.4) while N/S walls + side stubs keep
   the v29 0.5 wing overlap seal (bottom 29.9 vs ribbon top 30.4);
   bore 10 / outer 14 untouched; fail-loud asserts (fold exit == drop,
   entry in shroud band 60..72, fold fits ribbon + tube interior);
   `min_z=0`, `$fn=60`, `tol=0.3`, R->L order, back gears/crank intact.
4. **Viewer** (`web/index.html` only): `tapeFoldGroup` seat 142.5->83.5
   (fold zone 67..100), collar local exit offset unchanged (len 33
   kept); new `window._tapeFold` order hooks (`foldStart/foldEnd/
   dropX`); `_dropSeal` unchanged (seal kept); `ASSET_V` 16->17, tape +
   hopper GLBs rebuilt (fold + notch geometry).
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   `center_distance` 60, `gear_mesh_phase` 9°, back gears, crank back
   wall [40,-8,60], R->L hopper > drum > shroud > roller+crank kept;
   port 9099 only.

## v29 Sealed Drop Tube (bore 10 / outer 14) - 2026-09-17

1. **Goal**: no seed spill at the hopper-to-tape handoff — the drop-tube
   walls must touch/seal with the tape (overlap, not a gap).
2. **Verified coords**: drop at world x=100 (hopper local x=0 = drum
   centre); tube old outer local x -9..9 (world 91..109, 18 wide), bore
   -4.5..4.5 (9), bottom local z0=26.5 (world 30.5, 0.1 above ribbon top
   30.4). Tape U-fold trough (6 wide, R1.75, walls 5.5 at tape_z=30)
   lives EAST in the plow zone (world 126..159) — at the drop (x=100)
   the tape is FLAT ribbon (base 30.0, top 30.4), so the tube seals
   directly onto the flat ribbon: ribbon threads E/W, N/S walls seal.
3. **CAD** (`seed_tape_machine_v2.scad` only): bore 9->10 (r=5,
   -5..5, fits 8mm seeds with clearance), outer 18->14 (r=7, -7..7,
   2.0 walls/side >= 1.2); tube_z0 26.5->25.9 (world bottom 29.9, 0.5
   below ribbon top 30.4 = 0.5 touch-overlap); bottom-open tape notches
   (band local 25.7..26.7 = ribbon +-0.3) through EAST+WEST walls so
   the ribbon threads through while NORTH/SOUTH walls run full-height
   to the sealed bottom (corner nibbles <0.3, sub-seed, no spill path);
   drop window widened to bore 10; hopper export `zoffset` -26.5->-25.9
   (min_z=0 kept, assembly branch untouched); fail-loud asserts
   (bore==10, outer==14, wall>=1.2, bottom<=ribbon top); `$fn=60`,
   `tol=0.3`, R->L order, back gears/crank intact.
4. **Viewer** (`web/index.html` only): hopper child pos [0,26.5,0]->
   [0,25.9,0] (re-seats drum centre for the new export drop); dropSeed
   falls inside the bore (31.5->30.4 pocket, was 30.5->30.0); new
   `window._dropSeal` proof hooks (bore/outer/bottom/ribbonTop/dropX);
   `ASSET_V` 15->16, all 13 GLBs rebuilt (hopper watertight, min_z=0,
   low-slice outer +-7.0 / inner +-5.0 proven via trimesh).
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   `center_distance` 60, `gear_mesh_phase` 9°, back gears, crank back
   wall [40,-8,60], R->L hopper > drum > shroud > roller+crank kept;
   port 9099 only.

## v28 Tape Bend True Mimic (tapeubend.png) - 2026-09-17

1. **Source of truth**: `tapeubend.png` (end-on view, now in repo):
   flat 25.4 sheet -> tight narrow U trough ~5-7 wide, inner R ~1.5-2,
   vertical walls ~5-6 deep pocket, small reverse S-kink at the shoulders,
   progressive flat-entry to full-U exit, seed drops in the center,
   stainless former collar transverse over the exit.
2. **CAD** (`seed_tape_machine_v2.scad` only): `seed_tape_bend()` retuned
   to `tape_bend_radius` 1.75, `fold_width` 6.0 (HW 3.0),
   `tape_fold_wall` 5.5, `tape_shoulder_r` 1.5 / `tape_shoulder_ang` 60,
   `tape_n_arc` 20, new `tape_n_x` 12 taper steps (depth scale 0.15->1.0
   W->E, chamfered entry); double-thickness bottom slab REMOVED
   (flat ribbon IS the single-layer floor); per-side reverse S-shoulder
   (wall-top kink outward+up, foot back down onto the wing, sheet reads
   continuous); new `seg_ribbon_taper()` (old `seg_ribbon()` kept as
   unused helper); new visual `former_collar()` shoe with U notch over
   the exit (assembly only, not a print export). Stale v25
   "tapeubend.png NOT found" comment replaced. `min_z=0`, `$fn=60`,
   `tol=0.3`, R->L order, back gears/crank untouched.
3. **Viewer** (`web/index.html` only): `TAPE_BEND_R` 1.75, `TAPE_FOLD_HW`
   3.0, `TAPE_FOLD_WALL` 5.5, `TAPE_N_ARC` 20, `TAPE_N_X` 12 +
   `TAPE_SH_R` 1.5 mirrored; double slab removed; tapered fold (per-X
   depth scale) + S-shoulder + former collar shoe visual; `TAPE_LEN`
   320->180 unified with CAD `tape_len`; collapsible panel kept;
   `ASSET_V` 14->15, tape GLB rebuilt (+ full regen via cache).
4. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   `center_distance` 60, `gear_mesh_phase` 9°, back gears, crank back
   wall [40,-8,60], R->L hopper > drum > shroud > roller+crank kept;
   port 9099 only.

## v27 Final Pass: Readily Printable Audit - 2026-09-16

1. **Goal**: every exported part prints flat (min_z=0), walls >=1.2mm,
   single watertight solid per printable (trimesh proof), stress
   fillets/chamfers kept, tol=0.3 + $fn=60 + 9° gear phase + back crank
   + R->L order untouched. Minimal CAD changes only.
2. **Fixes** (`seed_tape_machine_v2.scad` only): (a) chassis bearing
   blocks fused to BOTH walls — `bearing_block()` takes `y_off`, back
   pair at +60 (old code ignored side, back trio floated unfused);
   (b) shroud sole flanges gain 4× M3 (3.6 clear) mounting holes (were
   solid, no fasteners); (c) upper roller export `zoffset` 11->0
   (floated 11mm, min_z=11 -> 0; lower keeps 19.95 gear-down stack);
   (d) hopper export drops 26.5 to print base (tube bottom 26.5 -> 0,
   assembly branch untouched); (e) cover groove `groove_d` 0.8->0.7
   (wall remainder 1.175 -> ~1.275 >= 1.2, still clears 0.6 cavity
   nub). Tape 0.4 film exempt (consumable, not printed);
   cones/rollers multi-body files are print SETS (singles cone_a/b,
   rollers_lower/upper are the watertight printables).
3. **Viewer** (`web/index.html` only): collapsible panel kept;
   hopper child pos -> [0,26.5,0] re-seats drum centre (compensates
   -26.5 export drop); rollers_upper child -> [0,0,15] (body centre
   15, was 26); part toggles/labels unchanged; `ASSET_V` 13->14, all
   13 GLBs rebuilt, vendored js local, port 9099 only.
4. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   `center_distance` 60, `gear_mesh_phase` 9°, back gears, crank back
   wall [40,-8,60], R->L hopper > drum > shroud > roller+crank kept.

Authoritative record of requirements, standing rules, and current state.
If context is ever lost, read this file first.

## v26 Step 5 Collapsible Left Panel (mobile) - 2026-09-16

1. **Goal**: preview page left selection panel collapses altogether via a
   single toggle button (hamburger ☰ / close ✕); on mobile (<=768px)
   default collapsed so the canvas is full-width; desktop default open.
   Smooth CSS slide transition, no layout break (canvas is fixed inset-0
   under the overlay panel, so collapse just frees the view).
2. **Scope (viewer UX only)**: `web/index.html` CSS + inline JS only. No
   CAD change, no GLB regen (`ASSET_V` stays 13), vendored
   `js/three.min.js` / `GLTFLoader.js` / `OrbitControls.js` stay local
   (never CDN), their `?v=3` untouched. Inline JS ships with the HTML so
   no cache-bust bump needed.
3. **Behavior**: toggle flips `body.panel-collapsed` only — never touches
   pivots/animation loop; part checkboxes/solo + play/rpm state preserved
   while hidden. Choice persisted in localStorage (desktop); mobile
   (<=768px) starts collapsed. Exposes `window._panelCollapsed` +
   `window._setPanelCollapsed(c)` for automated proof.
4. **Design (frontend-philosophy)**: keep the established dark glass panel
   (committed theme, blur+shadow depth, existing type) — no redesign, no
   AI-slop restyle. One purposeful motion only: the panel slide
   (transform 0.28s ease). Toggle is a small square button reusing panel
   vars (accent border on hover).
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   port 9099 only. Printable polish NOT started.

## v25 Step 4 Tape U-Bend (mimic tapeubend.png) - 2026-09-16

1. **Image status**: `tapeubend.png` NOT FOUND — glob `**/tapeubend.png`
   empty in repo and /tmp (searched 2026-09-16). Bend inferred from the
   name + v14 MVP spec ("Tape: 1 inch wide, center-fold with seed in
   middle") + plow 25.4->12.7 convergence. Read: flat 25.4 ribbon runs
   under the drum at z=30 (drop tube exit 30.5), folds into a center U
   through the plow zone (world x 126..159, east of drum/shroud, clear
   of hopper floor ~62 and drum face 125): bottom = fold_width 12.7,
   sides = quarter arcs, walls rise to ~39. If the real image shows a
   different fold (over-edge / through-shroud), re-tune these params.
2. **Bend params (CAD + viewer, mirrored)**: `tape_thick` 0.4,
   `tape_bend_radius` 3.0, `tape_fold_angle` 90 (vertical walls = full
   U), `tape_fold_wall` 2.0, `tape_n_arc` 12 facets/side, `tape_len`
   180 (world -14..166, spool->plow end), `tape_z` 30. Guards: thick
   >= 0.3 (no zero-thickness), R in [1,6], angle in (0,180], fold
   half-width 9.55 fits shroud inner 13, fold segment 140+33 <= 180.
3. **CAD** (`seed_tape_machine_v2.scad` only): new `seed_tape_bend()`
   (flat ribbon min_z=0 + epsilon-fused fold slab/arcs/walls, allowed
   modules only) + `seg_ribbon()` helper; static instance in
   `animated_assembly` at `[tape_x0, chassis_width/2, tape_z]`; new
   `part_to_render == "tape"` export branch (min_z=0). `$fn=60`,
   `tol=0.3`, center 60, back gears, crank back wall, R->L order kept.
4. **Viewer**: flat ribbon scrolls per crank rev (62.83mm); U-fold
   channel static at plow (142.5,30,-30), tape slides through; both in
   `tape` toggle group; `window._tapeFold` exposes arc meshes + R/hw/cz
   for proof. `ASSET_V` 12->13; tape GLB added (13 parts rebuilt).
5. **Frozen**: v1 scad + web/backup/ untouched; port 9099 only. Step 5
   (mobile panel) NOT started.

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
4. **Viewer** (`web/index.html` only): `shroudPivot` (58,0,-30) +
   shroud PART_DEF (child [0,0,0]/Rx-90) in PART_ORDER after hopper;
   spoolGroup x 10->-6; `ASSET_V` 9->10; legend notes the R->L layout.
   All 12 GLBs rebuilt.
5. **Frozen**: v1 scad + web/backup/ untouched; `$fn=60`, `tol=0.3`;
   `center_distance` 60, `gear_mesh_phase` 9°, back gears; crank back wall
   `[40,-8,60]`; port 9099 only. Step 4 (tape bend) / Step 5 (mobile
   panel) NOT started.

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

## MVP Update - 2026-09-16 - Agreed with User (v15 refinements + v39 6-turner/gear-only/cushioned-pull + v40 mounting/position/clutch)

1. **Browser preview stays as is** (no UI change), but must be a logically working model: parts mounted in true fit positions (no floating), motions synced (crank -> seed wheel -> drop -> tape pull, no random spinning).
2. **Round cover/shroud**: open-top half-cut 16mm pipe channel running 11 o'clock to 6 o'clock along the drum undershot path, guides seed to the 6 o'clock drop onto tape. Top open so seed travel is visible from the hopper to 11 o'clock in top view, no internal blocking ribs (red removed). Bore fits 8mm seed, inner face has grooves matching drum for wheel-to-frame positioning. Joints to the hopper on both sides.
3. **Seed wheel/cartridge (drum)**: 6 cavities, fixed for MVP. Wheels still interchangeable by hand (no tools) to support 1mm to 6mm seed sizes (cavity size varies, count stays 6).
4. **Hopper/seed box**: closed container (seeds retained, no open gap). Keeps the horizontal top edge (z=73) but the open gap is filled with walls. Sits at 9 o'clock, max volume extended up to 10:30 around the seed wheel. Inner face has grooves matching drum for wheel-to-frame positioning.
5. **Hopper + shroud = single printed piece** (with 2 side joints, blue support joints on both sides retained).
6. **Tape**: 1 inch wide, same for all seed sizes, center-fold with seed in middle; 6-shaped turner/roller former (replaces U-plow) – tape with seed passes through 6 curl to get rolled; after former, 2 threads rotate around tape to bind each seed.
7. **Seed spacing**: fixed 6 inch in MVP. Spacing 6 inch driven by vertical pull rollers + gear ratio linked to 6 cavities and thread twister; vertical nip rollers pull at constant speed, take-up spool winds finished tape, all synced via gears. All crank-driven via gears only, no belts; crank→drum→twister→pull→wind. 6-turner positioned a little after the drop point so seed lands flat first then rolls through the curl. Future enhancement (post-MVP): swap-gears for adjustable spacing (e.g. 3/6/9 inch).
8. **Gear-ratio calculator/chart**: cavities count + roller + gears = spacing. Include as future helper.
9. **Pink gaps sealed – no leak gaps; Red blocking feature removed – seed path clear from 11 to 6**.
10. **Thread wrapping unit**: 2 threads orbit tape axis after folding, lock each seed; pull/wind subsystem: vertical rollers + wind-up reel with slip clutch on axle (handles changing reel diameter). All crank-driven via gears only, no belts; crank→drum→twister→pull→wind; vertical pull rollers cushioned (soft). **Mounting**: bottom mount = 6-turner + wind-up reel; side mount = twister ring + pull rollers + drum (axles through chassis walls); top mount = hopper+shroud + tape input spools.
11. **Process flow**: hopper drop (9 o'clock, 6 holes) -> 11-6 channel -> 6 o'clock onto 1 inch folded tape -> thread bind -> vertical pull -> wind-up.

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
- Hopper LEFT (9 o'clock, 135°→225° from +X). CLOCKWISE ⇒ cavities scoop seeds upward bottom-to-top. Inner wall = drum_radius + hopper_clearance(0.3). Side cheek plates hug drum faces (axial gap = tolerance).
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
- animate_assembly=true + part_to_render=="all": drum_angle=+360*$t (CLOCKWISE about +Y), lower roller + crank = −720*$t, upper idler = +720*$t. At $t=0 geometry = static layout. Sign convention comment.
- Kinematics: gear ratio 2:1 (roller_teeth=20, drum_teeth=40, gear_module=2 → pitch dias 40/80, mesh center distance exactly 60mm). roller_dia=20, drum_dia=50. tape_per_crank_rev=PI*roller_dia=62.83; drum_rot_per_crank=0.5; tape_per_drum_rev=125.66→(v2: 157.08 with drum_dia 50); num_divots=max(1,round(tape_per_drum_rev/seed_spacing)); echo diagnostics + NOTE when num_divots==1.
- v2 axle layout (verified): spool=[10,65], drum=[100,60], roller=[160,60], chassis_height=110, plow x 126→155 at base_thick, crank shaft axis at (160,30,60) outside wall (y=chassis_width+8). Gear mesh |160−100|=60mm exact.
- All holes nominal + 2*tolerance (except explicit 0.3 hopper clearance and shroud gap). Epsilon-overlap face unions (epsilon=0.05). All 9 export branches min_z=0.000.

## v2 Verification Results (already passed)
- All 9 part_to_render branches exit 0, min_z=0.000 (chassis 411KB, hopper 377KB, shroud 51KB, cartridge 3.4MB, roller 2.5MB, crank 401KB, all 7.4MB).
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
