# Twister Gear-Drive Requirements — Understanding Draft (for multi-model flaw review)

## User requirements (verbatim, lightly cleaned)
"The twister will have bobbin holding rods. Consider the usual sewing machine bobbin size — its length and diameter — then arrange it. Have bevel teeth on the outer side of it. Then a perpendicular bevel placed on the chassis side-wise; the axis of it should be under the tape with some space. From the chassis bevel, have another gear on the same axis. Let a chain with necessary gears come from the seed drum gear. There would be gears with bigger and smaller on the same axis or shaft which can multiply or reduce the rotation. So upon rotating the crank, all should turn with very little friction."

## My understanding (to be critiqued)
1. Twister ring rotates about X-axis (tape travel) at (172, 30, 17), hollow bore Ø18 for 8mm folded tape. Bevel teeth on its OUTER side (ambiguous: outer face vs outer rim).
2. Two bobbin holding rods sized for a standard sewing machine bobbin (typical Class 15: Ø20.7mm × 11.1mm) — length and diameter considered.
3. Perpendicular bevel pinion mounted on chassis "side-wise" = axis along Y (across width), mounted to side walls. Its axis sits UNDER the tape with some space (ambiguous: below flat ribbon z=13? below tube z=17? how much?).
4. On the same Y-axis as the chassis bevel: another spur gear (compound).
5. Gear chain from the seed drum gear (44T M2 at (100,12,60)) to that spur gear, using compound gears (bigger+smaller on same shaft) to multiply/reduce rotation.
6. Low friction: rotating the crank turns everything with very little resistance.

## Machine context (facts)
- X = travel (west→east), Y = width 0-60mm, Z = up. Chassis x0=-14, len=262, width=60, height=112, base_thick=4, wall_thick=3.
- Seed drum gear 44T M2 at (100,12,60) about Y; roller pinion 16T at (40,12,60); crank 2.75x drum.
- Tape: flat ribbon z=13, y 17.3-42.7 (center y=30); folds to tube x≈114-159; tube through ring bore at (172,30,17); pull x=194; takeup x=226.
- Current twister: ring_r=15, tube=6, bore Ø18, 2 bobbin rods 6mm dia x14mm at orbit 12, 180° apart, 28T M1.5 bevel on west face + 12T pinion.
- Gears at y=12 back plane clear tape by ~11mm. $fn=60, tol=0.3. Never edit v1 scad or web/backup/.

## Open questions (flaws to resolve)
A. "Outer side" of ring — face (crown/face gear) or rim (circumference)?
B. Standard bobbin — which class/size exactly?
C. "Under the tape" — which z, how much space?
D. Target ratio ring:drum? (previous: 6/drum rev, then 18/7)
E. Drum gear at z=60 to pinion at z<13 — ~47mm drop; how many compound stages?
F. Low friction — bearing/mounting design for ring + shafts?
G. Pinion X position — at ring west face plane? Clearance to scroll exit x≈159?
H. Does pinion mesh from below the ring (face gear offset) — tape clearance?

## Real current code facts (verified 2026-09-19)

- Twister params (seed_tape_machine_v2.scad L299-318): twister_axle_z=17 (tape_z+4), twister_ring_r=15, twister_ring_tube=6, twister_lift=21, twister_arms=2, twister_orbits_per_drum=18/7 (~2.57), ring_bevel_teeth=28 M1.5, pinion_teeth=12 M1.5, ring_bevel_ratio=28/12, rod51_orbit=12, rod51_r=3 (6mm dia), rod51_h=14, bob51_r=2.5, bob51_h=6, eyelet_r=1, twister_post_h=9.
- thread_twister() L2076-2115: outer guide ring (rotate_extrude, tube*2 at ring_r, axis tilted to X), ring bevel 28T M1.5 on WEST FACE (rotate([0,90,0]), bore_dia=19), 2 guide eyelets, 2 bobbin spindles r3 h14 + bobbins r2.5 h6 at orbit 12, 180° apart, parallel X. Bore empty by construction (no hub/arms).
- twister_bracket() L2126-2152: tw_tol=0.35, bracket_r=21.35 (ring_r+tube+0.35), bracket_len=14, bracket_wall=2.5, slot_w=8, M3 mount holes.
- twister_pinion() L2157-2163: origin-centred rotate([90,0,0]) bevel_gear(12T M1.5, thickness 4, bore_dia=8). Comment: back plane y=12, axes intersect (bind_x,30,17), mesh 21+9=30.
- animated_assembly() L2343-2351: drum_angle=-360*$t; crank_angle=990*$t; idler_angle=-990*$t; roller_angle=crank+phase; twister_angle=-360*$t*18/7; pull_a/b=±roller*4/3; takeup=-1440*$t. NO pinion_angle in CAD — pinion placed L2440-2442 translate([bind_x,30,17]) rotate([twister_angle,0,0]) twister_pinion().
- Dispatch: "twister"→translate([0,0,21]) thread_twister(); "twister_bracket"→translate([-7,-21.35,0]) twister_bracket(); "twister_pinion"→translate([0,0,21]) rotate([90,0,0]) twister_pinion().
- Drum/roller: gear_module=2, roller_teeth=16, drum_teeth=44, center_distance=60, gear_mesh_phase=11.25°.
- Chassis: x0=-14, len=262, width=60, height=112, base_thick=4, wall_thick=3.
- Stations: tape_z=13; bind_x=172 (plow_end+13); pull_x=194; takeup_x=226, takeup_z=34; scroll six_turner exit axis_z=13 (world 17 = twister bore), exit lands x=159, tube R5.5/Ø11.
- v53 leftovers STILL LIVE in chassis() L927-986: counter spur, Y-bevel, X-pinion, shafts, drop pair, friction wheel at [fric53_x, lo53_y, lo53_z], posts. Params L406-453, asserts L496-570.
- Viewer (web/index.html): ASSET_V=54; twisterPivot (172,17,-30); twisterPinionPivot (172,17,-30); twister_bracket PART_DEF parent:root pos [159,17,-30] rot [-PI/2,PI/2,0]; twister PART_DEF parent:twisterPivot pos [0,-21,0] rot [-PI/2,0,0]; pinion PART_DEF parent:twisterPinionPivot pos [0,-21,0] rot [-PI/2,0,0]; twister ratio -(18/7)*DRUM_RATIO*crankAngle; pinion ratio -(28/12)*twAngle.

## Resolved decisions (user confirmed 2026-09-19, round 1)

| Decision | Answer | Rationale |
|----------|--------|-----------|
| A. "Outer side" teeth | **Flat face (west side)** — face/crown gear | Ring has bevel teeth on its west annular face, perpendicular to ring axis. Proven geometry. |
| B. Bobbin size | **Enlarge ring to fit 2× real Class-15 bobbins** (Ø20.7mm × 11.1mm) | Ring grows to carry real bobbins at orbit ≥19mm, 180° apart. Bracket, chassis base cutout, viewer all adapt. |
| C. Pinion height | **Axis Y at z=17 (tube height), shaft cantilevered from back wall to y≈17 (just before tape at y=17.3)** | Pinion gear at back plane y≈9-12, meshes with ring west face teeth. Shaft never crosses tape (stops at y=17, tape starts y=17.3). Standard face-gear mesh. |
| D. Target ratio | **12-18 ring turns per drum rev** (6 seeds × 2-3 turns each). Design target: 15 (6×2.5). | User confirmed: "drum once rotates drops 6 seeds, each seed needs at least 2-3 turns of threads". |
| E. Gear chain routing | **From drum (z=60) down to pinion spur (z≈17) via compound shafts at y=12 back plane** | ~47mm drop, 2-3 compound stages, all gears at y≈9-12 clear of tape (tape y≥17.3). |
| F. v53 friction drive | **DELETED entirely** — counter/bevel/drop/friction-wheel chain removed from chassis() | Old drive would fight new gear teeth. Clean slate. |
| G. Module transition | **M2 (drum stage) → M1.5 (ring/pinion stage) at compound shaft** | Drum gear is 44T M2; ring/pinion are M1.5. Compound carries both modules. |
| H. Low friction | **Slip-fit bores for shaft; ring rides on split-collar bracket + cradle posts** | Shaft supports: plain bores with tolerance 0.3mm. Ring: bracket (tw_tol=0.35) + 2 cradle posts. |

## Questions still open (to resolve in round 2 review)

1. Exact pinion center coordinate: (x, y, z) with face-gear mesh math (ring pitch r21, pinion pitch r9).
2. Exact shaft stations for compound chain from drum z=60 to pinion z≈17.
3. New ring_r and ring_tube to fit Class-15 bobbins (orbit, bore, OD, chassis clearance).
4. Whether gear tooth width at y=12 leaves enough clearance from tape edge (2.3mm gap per reviewer calc).
5. Cradle post and bracket modifications for enlarged ring.