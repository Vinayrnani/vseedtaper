# Seed Tape Machine — Project Requirements & Context Record

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
