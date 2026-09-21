/*
    Modular Hand-Cranked Seed Tape Machine - v2 Authoritative Spec
    ===========================================================
    v81: crank at x=160 (20T FRONT-plane gear meshes drum 40T, 2:1),
         28mm hex shaft at front, spur_gear in crank,
         rollers removed (upper deleted, lower replaced by crank axle),
         shroud east (116..124) moves with hopper as one unit.
    Parametric OpenSCAD 2021.01 - zero-error, manifold, flat-base parts.
    Allowed: diff/union/hull/cube/cylinder/sphere/rotate_extrude + transforms/for/if/echo/assert.
    NO minkowski/intersection/polygon/linear_extrude of text.
*/

// ============================================================
// Global variables (v2 spec)
// ============================================================
tolerance     = 0.3;
paper_width   = 25.4;
seed_dia      = 3.0;
seed_depth    = 2.0;
seed_spacing  = 152.4;   // v14 MVP fixed: 6 inch (152.4mm), driven by pull roller + gear ratio, 6 cavities
drum_radius   = 25;
drum_dia      = 2 * drum_radius;   // 50
drum_width    = 15;
shroud_id     = 8;
$fn            = 60;

// ============================================================
// Kinematics / derived parameters (v2)
// ============================================================
gear_module   = 2;
roller_teeth  = 20;
drum_teeth    = 40;
center_distance = (roller_teeth + drum_teeth) * gear_module / 2; // 60

// Gear tooth proportions (20 PA trapezoidal)
addendum   = 1.0 * gear_module;   // 2.0
dedendum   = 1.25 * gear_module;  // 2.5
tooth_arc_frac = 0.47;            // ~47% tooth thickness at pitch circle

// Derived gear dimensions
roller_pitch_dia = gear_module * roller_teeth;   // 40
drum_pitch_dia   = gear_module * drum_teeth;     // 80
roller_outer_dia = roller_pitch_dia + 2*addendum; // 44
roller_root_dia  = roller_pitch_dia - 2*dedendum; // 35
drum_outer_dia   = drum_pitch_dia + 2*addendum;   // 84
drum_root_dia    = drum_pitch_dia - 2*dedendum;   // 75
roller_outer_r = roller_outer_dia/2;
roller_root_r  = roller_root_dia/2;
drum_outer_r   = drum_outer_dia/2;
drum_root_r    = drum_root_dia/2;

// Roller body diameter (spec: roller_dia=20)
roller_dia = 20;
roller_body_r = roller_dia/2;

// Gear mesh phase (v21): half-pitch of the 20T roller pinion (360/20/2 = 9°).
// The drum (40T) has a tooth centered on the line of centers at $t=0, so the
// roller needs a half-pitch offset for tooth-into-gap mesh. Applied to the
// roller shaft rotation (lower roller + crank, one rigid shaft) in
// animated_assembly; mirrored in the viewer as GEAR_PHASE.
gear_mesh_phase = 360/roller_teeth/2;   // 9

// Circumference for tooth angular spacing
roller_circ_pitch = PI * gear_module;
drum_circ_pitch   = PI * gear_module;
tooth_arc_roller = tooth_arc_frac * roller_circ_pitch;
tooth_arc_drum   = tooth_arc_frac * drum_circ_pitch;

// Kinematics (v14 MVP: 6 cavities fixed, spacing 6 inch = 152.4 fixed;
// tape driven by pull roller via 40:20 mesh, drum geared slower vs roller)
tape_per_crank_rev = PI * roller_dia;         // ~62.83 (roller 1 rev)
drum_rot_per_crank = 0.5;
tape_per_drum_rev  = PI * drum_dia;           // ~157.08 (drum circumference, reference only)
tape_per_drum_rev_roller = PI * roller_dia * (drum_teeth / roller_teeth); // 125.66 actual tape/drum rev via pull roller
num_divots         = 6;                       // v14 MVP fixed: 6 cavities (wheels interchangeable by hand 1-6mm, count stays 6)
achieved_spacing   = tape_per_drum_rev_roller / num_divots; // ~20.94 with stock 20/40 gears; target 152.4 via future swap-gears (see GEAR_RATIO.md)
target_spacing     = 152.4;                   // v14 MVP: fixed 6 inch spacing

// ============================================================
// Axle layout (X,Z in OpenSCAD coords: X=tape travel, Z=up)
// v79 R->L order: crank (160, front) > six_turner (126..159) >
//   shroud tunnel (116-124, east of drum) > drum (100) >
//   spool (-6, far west).
// Gear mesh: crank(160) 20T -> drum(100) 40T, dist=60=center_distance,
//   crank rotates 2:1 vs drum (crank_angle = 2*drum_angle).
//   Drum gear on FRONT plane (y≈47.95) for crank mesh.
// Plow stays EAST of drum (126->159, v1 precedent); tape scroll unchanged.
// v79: rollers REMOVED; crank carries the 20T pinion at x=160, front wall.
// ============================================================
drum_axle_x  = 100;
drum_axle_z  = 60;   // ≥ drum_radius + base_thick + clearance = 29.3 ✓
crank_axle_x = 160;  // v79: crank (20T) meshes drum (40T), dist=60=center_distance
crank_axle_z = 60;  // same Z as drum for gear mesh
roller_axle_x = crank_axle_x;  // v79: alias (old roller position, now crank axle)
roller_axle_z = crank_axle_z;  // v79: alias
spool_axle_x  = -6;  // v22: 10->-6, clears roller back gear (box-level X gap 1.5)
spool_axle_z  = 65;  // 120mm max roll OD, height 65mm above base

// ============================================================
// Chassis
// ============================================================
chassis_x0    = -14; // v22: west edge (was 0); east edge stays chassis_x0+chassis_len=248 (v38: 200->248 seats take-up 226+16=242 + 6 margin)
chassis_len   = 262; // v38: 214->262, east extension seats the wind-up reel clear of the pull nip (X gap 6)
chassis_width = 60;
chassis_height = 110;  // > max(spool top=90, drum top=102) + 5 = 107 ✓
base_thick    = 4;
wall_thick    = 3;

// ============================================================
// Plow (downstream closer, v1 precedent: stays EAST of drum) +
// Fold zone (v31: forming station fully WEST of the drum face so the
// tall U walls never meet the wheel; shallow entry at the roller nip,
// full-U forming exit at x=70, then a straight full-U transit (same
// cross-section, no taper) runs EAST through the shroud slot, UNDER
// the drum with air gap, INTO the drop-tube west side inlet at x=93,
// through the bore (seed drops into the moving pocket at x=100) and
// on to the plow mouth at 126 which closes/seals it downstream)
// ============================================================
plow_start    = drum_axle_x + drum_radius + 1; // 126 (east of drum, unchanged)
plow_len      = 33; // v79 FIXED: decoupled from old roller_axle_x.
                     // Plow stays east (v1 precedent).
plow_end      = plow_start + plow_len; // 159
fold_len      = 33;   // forming length kept (same taper count as v30)
fold_end      = 70;   // v31: forming exit 5 clear of the drum west face (75)
fold_start    = fold_end - fold_len; // 37: shallow entry at the roller nip (40)
transit_end   = plow_start; // 126: straight full-U transit ends at the plow mouth
transit_len   = transit_end - fold_end; // 56: forming exit -> plow mouth via pipe
fold_width    = 4.0;   // v34 OD10 pipe (was 6.0): narrow U trough 3-5 so outer=fold+2*(R+thick)=7.8<10 (v35: mouth 7 < ID7.6, lands inside); plow plan_ang derives from it
track_depth   = 3;

// ============================================================
// Rollers
// ============================================================
roller_len    = 30;
axle_dia      = shroud_id; // 8
hex_axle_flat = 8;
hex_axle_r    = hex_axle_flat / sqrt(3);
axle_clearance_dia = axle_dia + 2*tolerance; // 8.6
hex_clearance_r  = (hex_axle_flat + 2*tolerance) / sqrt(3);
// v45 DEAD AXLES (forensic fix: drum + reel + spool cones were held
// by NOTHING — bores + wall/block holes with no shaft modelled;
// parts spun on viewer pivots but the steel read as floating).
// Static bars in chassis(): slip-fit through bores/holes (tol gap
// all around, spinning parts stay free); the drum shaft fuses into
// the solid v47 drum bevel (no bore). Back ends stop INSIDE the back
// wall/block bores (y=1 in wall 0..3 — hidden, never exterior, never
// coplanar; v47: no exterior gears means nothing to bury into, so the
// wall itself hides them — zero exterior clutter).
drum_shaft_y0 = 1;    // hidden in the back wall/block bore (wall 0..3)
drum_shaft_y1 = 59;   // hidden in the front drum-block bore
takeup_shaft_y0 = 1;  // hidden in the back wall/block bore (wall 0..3)
takeup_shaft_y1 = 59; // hidden in the front take-up block bore
spool_shaft_y0 = 1;    // hidden in the back spool-block bore
spool_shaft_y1 = 59;   // hidden in the front spool-block bore
bolt_dia        = 3;
bolt_head_across = 5.5;
nut_trap_depth  = 2.5;

// Bearing block dimensions
bb_len = 14;
bb_wall = 4;
bb_height_roller = 13;
bb_height_drum   = 13;
bb_height_spool  = 10;

// ============================================================
// Hopper (v14 MVP: closed seed box at 9 o'clock, max volume to 10:30;
// single printed piece with shroud via 2 side joints; horizontal top z=73)
// ============================================================
hopper_wall     = 2.5;
hopper_flange_thick = 3;
hopper_clearance = 0.3;
hopper_inner_r  = drum_radius + hopper_clearance; // 25.3
hopper_outer_r  = hopper_inner_r + seed_dia + 3;  // 30.8
hopper_axis_z   = drum_axle_z - base_thick;       // 56
wiper_slot      = 1.2;
// v14 shroud/half-pipe + groove params (cover merged into hopper_body)
shroud_pipe_od  = 16;    // open-top half-cut 16mm pipe channel, 11 o'clock (120) -> 6 o'clock (270)
shroud_bore     = 8;     // bore fits 8mm seed (drop bore 10 = 8 + clearance, v29 was 9)
shroud_wall     = 2;     // preserved v12 wall
shroud_gap      = 1.5;   // preserved v12 gap (within 1.5-2 smooth channel, no ribs/steps)
groove_w        = 7;     // inner-face groove width, matches drum cavity track (fits 6mm cavities d6.6)
groove_d        = 0.7;   // v27 printable: 0.8 left only 1.175 wall (<1.2); 0.7 leaves ~1.275, still clears cavity protrusion 0.6
// v79 tape-cover shroud segment EAST of drum (drum exit -> six_turner).
// World x shroud_x0..shroud_x1 = 116..124 (centroid 120): drum(100) <
// shroud(120) < six_turner(126) R->L. Moves with hopper as one unit.
// Top (23) stays below the drum bottom (60-25=35).
// v33: roof lowered 34->23 for the 13 lane (transit top 21.4 + 1.6
// cover clearance, ends open 0..21, tape at ~13).
shroud_x0  = drum_axle_x + 16;  // 116: tucks to drum tangent on east
shroud_x1  = drum_axle_x + 24;  // 124: ends before six_turner at 126
shroud_len = shroud_x1 - shroud_x0; // 8
shroud_h   = 23;                  // v33 enclosed tunnel height (tape slot 0..21, tape at ~13; was 34)

// ============================================================
// Crank (v79: at x=160, 20T gear meshes drum 40T at dist=60)
// Crank carries a 20T spur gear at the FRONT plane that meshes
// the drum's 40T gear. 28mm hex shaft at front near handle.
// Handle at front y=68, near twist gears.
// grip orbit r=crank_throw=45, $fn=60, tol=0.3 all kept.
// ============================================================
crank_throw     = 45;
crank_mount_x   = crank_axle_x; // v79: 160: meshes drum 40T at dist 60 (was drum_axle_x=100)
crank_mount_y   = chassis_width + 8; // v79: 68: outside FRONT wall
crank_side      = +1; // v79: grip/arm extend +Y outward front
crank_arm_t     = 4;
crank_arm_w     = 10;
grip_len        = 30;
grip_dia        = 16;
crank_pivot_x   = crank_arm_w / 2; // 5
crank_pivot_z   = crank_arm_t + hex_axle_r - 0.15; // ~8.47
hex_shaft_len   = 28;

// ============================================================
// Seed cradle
// ============================================================
cradle_u_depth  = 3;
cradle_u_radius = 4;

// ============================================================
// Seed tape with center U-fold bend (v28 true mimic of tapeubend.png,
// v31 drum-clear: forming station 37..70 fully west of the drum face).
// End-on photo (now in repo): flat 25.4 sheet -> tight narrow U trough
// 5-7 wide, inner R 1.5-2, vertical walls 5-6 deep pocket, small reverse
// S-kink at the shoulders flaring back to the flat wings, progressive
// flat-entry (shallow, at the roller nip) to full-U forming exit (deep,
// x=70); a straight full-U transit (same section, no taper) runs
// 70..126 under the drum (13.6 air gap to the disc) UNDER the hover
// pipe (10 gap), the seed drops at x=100 from the bore into the
// ALREADY-FOLDED pocket, on to the plow mouth (126) which closes it;
// stainless former collar (transverse shoe with U notch) rides over the
// forming exit (world x ~67) as a visual.
// Single-layer bottom (flat ribbon IS the trough floor, no double slab).
// Tape lane (v34 OD10 pipe: lowered lane 13 kept from v33; flat ribbon
// top 13.4, pipe bottom 23.4 (hover 10, no seal/slots), pipe top 33.4,
// flange bottom 33.5 -> flange-to-tape 20.1, disc bottom 35 -> 21.6;
// full-U transit top 21.15 clears the disc by 13.85, passes 2.25 under
// the pipe mouth with no touch).
// Single-layer bottom (flat ribbon IS the trough floor, no double slab).
// tape_bend_radius = inner arc R (1.5), fold_width = trough bottom width
// (4.0, HW 2.0), tape_fold_wall = vertical wall length (5.5),
// tape_shoulder_r/ang = reverse S-kink at shoulders (1.5/60), tape_n_arc
// = 20 facets/side, tape_n_x = 12 taper steps (depth 0.15->1.0 W->E).
// Full-U tape-local top = 0.4 + (1.5+5.5)*1.0 + 1.5*0.5 = 8.15
// (shoulder apex); world top = tape_z + 8.15 = 21.15.
// Fold outer = 4.0 + 2*(1.5+0.4) = 7.8 < OD10; pocket mouth inner
// = 4.0 + 2*1.5 = 7.0 < ID7.6 (seed falls from the 7.6-bore into the
// already-folded 7-mouth pocket, lands inside).
// Assembly: static tape (viewer scrolls it); export standalone min_z=0.
// ============================================================
tape_thick       = 0.4;
tape_bend_radius = 1.5;   // v34 OD10 (was 1.75): outer=4+2*(1.5+0.4)=7.8<10, mouth inner=4+2*1.5=7<7.6 (v35 ID)
tape_fold_angle  = 90;
tape_fold_wall   = 5.5;
tape_shoulder_r  = 1.5;
tape_shoulder_ang = 60;
tape_x0          = chassis_x0;   // -14: spans spool(-6)..leader start (flat ribbon no longer dangles under/past the reel)
// v45 WIND-UP LEADER (forensic fix: the flat ribbon used to run UNDER the
// bare reel core with a ~13 gap and dangle 14 past the reel to 256 while
// the viewer scroll slid it +/-63 per rev). Now the flat ribbon ENDS at
// tape_flat_end (208: east of the nip caps 205, west of the reel flange 210)
// and a narrow leader strip (finished folded-tube width 8) climbs from
// the ribbon top onto the wound pack (pack r8 on core r5 at (226,34)),
// ending fused inside the pack silhouette.
tape_flat_end    = 208;
tape_len         = tape_flat_end - tape_x0;   // 222 (was 270: -14..256 dangled past reel 242/chassis 248)
leader_x0        = 206;   // leader start (2 overlap onto the flat ribbon)
leader_x1        = 224.5; // leader end (inside the pack silhouette)
leader_z1        = 26.5;  // leader end height (pack bottom 26 + 0.5 bite)
leader_w         = 8;     // leader width (finished folded tube, not full 25.4)
tape_z           = 13;           // v33 lane (was 24): transit top 21.4 clears disc 35 by 13.6, ribbon top 13.4
tape_n_arc       = 20;           // arc facets per side (smooth like $fn=60 curves)
tape_n_x         = 12;           // taper steps along X (progressive entry->exit)

// ============================================================
// v37 Thread-bind + vertical pull + wind-up (v36 MVP backfill:
// hopper 9 o'clock -> 11-6 channel -> 6 o'clock drop onto the
// 1in folded tape -> thread bind -> vertical pull -> wind-up).
// All geared to the drum (6 cavities, 6in/152.4mm spacing intent):
// pull nip runs 4/3 vs the main roller (v52 d15 => same surface
// speed, spacing preserved); twister orbits once per cavity (6 per
// drum rev, one bind per seed); take-up winds the same linear tape
// (core d10 => 4 rev per $t, i.e. 2x crank). Bind sits just after
// the plow (bind_x = plow_end+8); pull nip stacks vertically over
// the finished tape at pull_x; reel sits east at takeup_x.
// v38 RESPACED (v37 overlapped: twister 163..171 touched pull 171..191
// at X=171, take-up 170..202 interpenetrated both in X/Y/Z).
// Sequential eastward with >=5mm steel-to-steel X gaps:
// plow end 159 -> twister 168..176 (gap 9) -> pull 186.35..201.65 (gap 10.35) ->
// take-up 210..242 (gap 8.35). Centres 32 apart for pull->take-up vs
// radii sum 7.65+16=23.65 (gap 8.35, margin kept).
// $fn=60, tol=0.3 kept.
// ============================================================
bind_x   = plow_end + 13;   // 172: thread orbit station east of the plow (rotor X half 4 -> 168..176, gap 9)
pull_x   = plow_end + 35;   // 194: vertical-nip pull station (sleeve r7.65 -> 186.35..201.65, gap 10.35 to twister east)
takeup_x = 226;             // wind-up reel east (flange r16 -> 210..242, gap 6 to pull east; chassis east 248)
takeup_z = 34;              // reel axle height (flange 18..50: bottom >= 0, top < 110)
twister_axle_z = tape_z + 4;      // 17: ring centre over the folded pocket (pocket top ~21)
twister_ring_r = 10;              // guide ring radius (tape pocket 7.8 passes through)
twister_ring_tube = 2;
twister_lift = twister_ring_r + twister_ring_tube; // 12: export lift for min_z=0
twister_arms = 2;                 // 2 threads orbit the tape
twister_orbits_per_drum = 6;      // one bind per cavity per drum rev (== num_divots)
twister_post_h = 13;              // v45 cradle-stub height (2 rolling gap under the ring-OD tube: 17-2-13=2)
vpull_r = 7.5;                     // vertical-axis nip roller radius (v52 d15; surface speed kept via vpull_spin 4/3)
vpull_h = 20;                     // roller height (covers lane 13..21 + caps, base at 0; assembly top 4+20+3=27)
vpull_sleeve_r = 7.65;            // v52 cushioned sleeve outer (d15 core proud 0.15, under the r8.5 caps: envelope kept)
vpull_sleeve_h = 12;              // v52 shorter cushion band (was 16)
vpull_gap = 9.5;                  // v52 cushioned surface-to-surface nip gap (param-driven, fail-loud asserted 9.5+-0.01)
vpull_off = vpull_sleeve_r + vpull_gap/2; // 12.4: sleeve r + half gap (replaces r+2.0+1.5+0.4+tol = 14.2); Y = 30+-12.4 = 17.6/42.4
vpull_spin = roller_body_r/vpull_r; // 4/3: spin compensation (smaller dia, same surface speed => spacing preserved)
takeup_core_d = 10;               // wind-up core dia (rev = tape / (PI*core_d))
takeup_core_r = takeup_core_d/2;
takeup_flange_r = 16;
takeup_flange_t = 3;
takeup_core_h = 28;
// v40 slip clutch on the take-up axle (handles changing reel diameter:
// fast when empty, slips when full). Stack rides ABOVE the top flange
// in the export frame (print base stays min_z=0): pressure disc +
// friction disc (the slip interface) + spring + hex nut. Disc r8 <
// flange r16 so the station X envelope (210..242) is unchanged.
clutch_disc_r = 8;
clutch_disc_t = 2;
clutch_spring_h = 3;
clutch_nut_h = 3;
clutch_stack = clutch_disc_t + clutch_disc_t + clutch_spring_h + clutch_nut_h; // 10
takeup_h_total = takeup_core_h + takeup_flange_t + clutch_stack; // 41: bottom flange 0..3 + core 0..31 + top 28..31 + clutch 31..41
// v45 leader pack radius (must equal the takeup_reel() wound-pack visual:
// core r5 + 3 = r8 at (takeup_x, takeup_z); the leader ends inside it).
tape_pack_r = takeup_core_r + 3;

// ============================================================
// v39 6-turner (replaces the U-plow closing geometry) + v40 position.
// The tape with seed passes through a 6-shaped curl that rolls the
// tape edges over the seed (edge roller/roller former). Aliases keep
// the v1-precedent footprint: turner_start/end == plow_start/end
// (126..159, len 33, w 40) so part_to_render "plow" stays a valid
// export name (compat) and "turner" is accepted too.
// v40 POSITION: the turner sits a little AFTER the drop point
// (drop_x=100, turner mouth 126: 26mm of flat landing zone) so the
// seed lands flat first, then rolls through the 6 curl to fold.
// ============================================================
drop_x = drum_axle_x;             // 100: seed drop point (hopper bore centre)
turner_start = plow_start;        // 126: folder mouth (flat landing 100..126 first)
turner_len = plow_len;            // 33
turner_end = plow_end;            // 159
// v56: turner_curl_cz is the live datum: the thin-shell bore-axis height
// (local y20, z13: lane-centred so the 7.8 seeded pocket threads the
// entry bore; was 12 pre-v56).
turner_curl_r = 6.5;              // v54 reference only (no shell)
turner_curl_bore = 4.2;           // v54 reference only (no bore)
turner_curl_off = 1.2;            // v54 reference only (no bore offset)
turner_curl_cz = 13;              // v56 bore-axis height (lane-centred; was 12)

// ============================================================
// OVERHEAD twister drive (user: duplicate drum gear + bottom
// bevels blocking the tape): the v48/v51 drum-coaxial 50T takeoff
// is DELETED; takeoff reuses the EXISTING drum40 gear (back plane
// y 9..15, no new drum parts). One HIGH countershaft at (cx,44)
// carries a 10T counter (same back plane y=12, dist 50 = 40+10
// from (100,60), 4x) + a 12T Y-bevel; 90deg bevel to a 10T
// X-pinion (1.2x) on a HIGH side layshaft (y=45.5,z=44, cx->183,
// overhead, clears the tape by >=5); a thin 15T/12T spur drop at
// x=181 (dz=27=15+12, 1.25x) feeds the LOW side layshaft
// (y=45.5,z=17, 165..183) + the kept r3.5 friction wheel on the
// ring OD (slip after, hollow middle). Total
// (40/10)*(12/10)*(15/12) = 4*1.2*1.25 = 6.0 at the low shaft.
// Lowest overhead steel 27 (drop-high bottom) clears tape top 22
// by 5; only the small 12T drop-low (bottom 3) stays low in a
// 2-floor pocket (1.0 rolling clearance, v51 precedent).
// v47 floor arrangement stays DELETED. No exterior gears, no
// floor gears, no belts.
// Centres: C_Y = apex - r_x*Y = (cx,35.5,44);
// C_X = apex + r_y*X = (cx+12,45.5,44).
// Pull/takeup stay tape-coupled (no gears, documented, zero
// exterior clutter). Stations/gaps untouched (turner lip 160.35 ->
// twister gap 7.65, gaps >= 5). Speeds (rev per crank rev):
// crank +1, drum -0.5, counter +2.0 (about Y), twister -3 (about X),
// pull +4/3 (about Z, tape-coupled), takeup +2 (about Y, tape/clutch).
// vpull cushioned (v39): soft rubber/silicone sleeve visual over the
// steel core (v52 OD stays ~d15 => 4/3 spin keeps surface speed), firm grip without crushing.
// ============================================================
// OVERHEAD take-off (duplicate 50T DELETED; takeoff reuses the
// EXISTING drum40 gear, y 9..15 back plane). Module 2 single,
// teeth all in [10,60]. Ratio (40/10)*(12/10)*(15/12) = 6.0.
overhead_mod = 2;
// Stage 1 (parallel spur Y-Y): drum40 (r40 at (100,60)) -> overhead
// counter 10T (r10) at (cx,44): dist = 50 = 40+10, same Y plane.
overhead_counter_teeth = 10;
overhead_counter_drum_r = gear_module*drum_teeth/2;   // 40 (existing drum40, reused)
overhead_counter_r = overhead_mod*overhead_counter_teeth/2;     // 10
overhead_counter_z = 44;   // overhead: bottom 44-12=32 clears tape top 22 by 10
overhead_counter_x = drum_axle_x + sqrt(pow(overhead_counter_drum_r + overhead_counter_r, 2) - pow(drum_axle_z - overhead_counter_z, 2)); // ~147.37
overhead_counter_y = 12;    // mesh plane = drum40 gear plane (back, y 9..15)
overhead_counter_y0 = 1; overhead_counter_y1 = 59;  // hidden in wall/block bores, never exterior
overhead_spur_t = 6;
// Stage 2 (90deg bevel, overhead): Y 12T (r12, countershaft) ->
// X 10T (r10, high layshaft) at apex = (cx,45.5,44): 12/10 = 1.2x.
overhead_bevel_y_teeth = 12; overhead_bevel_x_teeth = 10;
overhead_bevel_y_r = overhead_mod*overhead_bevel_y_teeth/2;   // 12
overhead_bevel_x_r = overhead_mod*overhead_bevel_x_teeth/2;   // 10
overhead_apex_x = overhead_counter_x; overhead_apex_y = 45.5; overhead_apex_z = 44;
overhead_bevel_y_center_y = overhead_apex_y - overhead_bevel_x_r;   // (cx,35.5,44), body toward -Y
overhead_bevel_x_center_x = overhead_apex_x + overhead_bevel_y_r;   // (cx+12,45.5,44), body toward +X
overhead_bevel_t = 6;
// High side layshaft (spinner X at y=45.5,z=44: apex -> drop).
overhead_high_y = 45.5; overhead_high_z = 44;
overhead_high_x0 = overhead_counter_x; overhead_high_x1 = 183;
overhead_high_r = 2.5;
// Stage 3 (spur drop X-X at x=181, thin pair t=4): high 15T (r15)
// -> low 12T (r12): dz = 27 = 15+12, 15/12 = 1.25x.
drop_pair_x = 181; drop_pair_t = 4;
drop_pair_high_teeth = 15; drop_pair_low_teeth = 12;
drop_pair_high_r = overhead_mod*drop_pair_high_teeth/2;   // 15
drop_pair_low_r = overhead_mod*drop_pair_low_teeth/2;   // 12
// Low side layshaft (spinner X at y=45.5,z=17: 165..183, carries
// the drop-low gear + the v51 friction wheel at x=175).
overhead_low_y = 45.5; overhead_low_z = 17;
overhead_low_x0 = 165; overhead_low_x1 = 183;
overhead_low_r = 2.5;
friction_wheel_r = 3.5; friction_wheel_t = 4;
friction_wheel_x = 175; // wheel centre (face beside the ring east face, kept)
// Hanger posts (static brackets, base-fused, tops meet shaft
// bottoms, no pierce; Y-beside the tape like v51).
overhead_high_post_x = 163; overhead_high_post_top = overhead_high_z - overhead_high_r; // 41.5
overhead_low_post_x = 167; overhead_low_post_top = overhead_low_z - overhead_low_r; // 14.5
// v51 hollow-rotor rods: 2 rod-like bobbin holders 180 apart on the ring
// (rods parallel X at orbit radius 9.5, bobbins ride the rods).
rod51_orbit = 9.5; rod51_r = 1.2; rod51_h = 10;
bob51_r = 2.5; bob51_h = 6;
// Drop pocket under the low drop gear (spinning 12T outer bottom
// 17-14=3 dips below the base top 4; pocket floor at 2 leaves 1.0
// rolling clearance, base keeps a 2mm print floor, v51 precedent).
drop_pair_pocket_z0 = 2; // pocket floor (base keeps 0..2 solid, still prints flat)
// Tape-top reference for the >=5 overhead-clearance asserts.
tape_top = 22; // transit/pocket top ~21.2 + margin
// Pull support pins (static bars: base-fused, slip-fit in roller
// bores + cup-B bore; the tape-coupled rotors spin on them).
pull_pin_r = axle_dia/2;             // 4: static pin radius (slip in bores)
pull_pinA_z0 = 2; pull_pinA_z1 = 27; // base-fused .. hidden in roller top cap (v52 shorter stack top 27)
pull_pinB_z0 = 2; pull_pinB_z1 = 27; // base-fused .. hidden in cup-B bore (v52 cup 25..28)
// cup B kept (bored) for the static pin B (no tube hole v48).
vpull_collar_z = 5.0;              // v45 mid-collar centre LOCAL (assembly lifts +base_thick: CAD top 4+5+1.5=10.5 clears ribbon base 13 by 2.5; was 12 grazing the tape)

// ============================================================
// Spool cones
// ============================================================
cone_h = 25;
cone_r_big = 22.5;  // 45mm OD
cone_r_small = 7.5; // 15mm OD

// ============================================================
// Epsilon
// ============================================================
epsilon = 0.05;

// ============================================================
// Guard / fail-loud checks (5 Laws: Fail Loud)
// ============================================================
assert(tolerance >= 0 && tolerance < 1, "tolerance must be in [0,1)");
assert(paper_width > 0, "paper_width must be >0");
assert(seed_dia > 0 && seed_dia <= 6.0, "seed_dia must be (0,6.0] (v14: interchangeable wheels 1-6mm)");
assert(seed_depth > 0 && seed_depth < drum_radius, "seed_depth must be >0 and < drum_radius");
assert(seed_spacing == 152.4, "v14 MVP: seed_spacing fixed at 6 inch (152.4mm)");
assert(gear_module > 0, "gear_module must be >0");
assert(center_distance == (roller_teeth + drum_teeth) * gear_module / 2,
       str("center_distance must be 60 for 20T/40T module=2, got ", center_distance));
assert(num_divots == 6, "v14 MVP: num_divots fixed at 6 cavities");
assert(crank_axle_z >= roller_outer_dia/2 + 1, str("crank_axle_z must clear base: need >= ", roller_outer_dia/2+1, " got ", crank_axle_z));
assert(drum_axle_z >= drum_radius + base_thick + tolerance, str("drum_axle_z must clear cradle+tape: need >= ", drum_radius+base_thick+tolerance, " got ", drum_axle_z));
assert(abs(sqrt(pow(crank_axle_x - drum_axle_x,2)+pow(crank_axle_z - drum_axle_z,2)) - center_distance) < 0.5,
       str("gear center distance must be ~60mm, got ", sqrt(pow(crank_axle_x-drum_axle_x,2)+pow(crank_axle_z-drum_axle_z,2))));
// OVERHEAD drive (drum40 takeoff, no duplicate, no low bevels):
// single module 2 + exact 6.0 at the low shaft + parallel mesh
// dist=r1+r2 + true 90deg bevel + spur drop + side friction on
// the ring OD (nothing coaxial). Zero exterior, zero floor gears.
assert(overhead_mod == 2 && gear_module == 2, "overhead-drive: drive must stay single module 2");
assert(overhead_counter_teeth >= 10 && overhead_counter_teeth <= 60 && overhead_bevel_y_teeth >= 10 && overhead_bevel_y_teeth <= 60
    && overhead_bevel_x_teeth >= 10 && overhead_bevel_x_teeth <= 60 && drop_pair_high_teeth >= 10 && drop_pair_high_teeth <= 60
    && drop_pair_low_teeth >= 10 && drop_pair_low_teeth <= 60, "overhead-drive: drive teeth must stay in [10,60]");
assert((drum_teeth/overhead_counter_teeth)*(overhead_bevel_y_teeth/overhead_bevel_x_teeth)*(drop_pair_high_teeth/drop_pair_low_teeth) == 6, "overhead-drive: step-up must be exactly 6x ((40/10)*(12/10)*(15/12))");
// Stage-1 mesh: centre distance = r_drum40 + r_counter (same Y plane).
assert(abs(sqrt(pow(overhead_counter_x - drum_axle_x, 2) + pow(overhead_counter_z - drum_axle_z, 2)) - (overhead_counter_drum_r + overhead_counter_r)) <= tolerance + 0.01, "overhead-drive: drum40->counter mesh must satisfy dist=r1+r2 (50)");
assert(overhead_counter_y == 12, "overhead-drive: counter must share the drum40 gear plane (back, y 9..15)");
// v79: crank gear world y = crank_mount_y + gear_local_y = 68 + (-20) = 48 (front plane).
assert(crank_mount_y - 20 >= 44 && crank_mount_y - 20 <= 52, "crank gear world y must be ~48 (front plane, gear spans y 45..51)");
// v81: drum gear world y = chassis_width/2 + gear_off = 30 + 17.95 ≈ 47.95 (front plane, matches crank gear within 0.05).
assert(chassis_width/2 + roller_len/2 + 3 - epsilon >= 44 && chassis_width/2 + roller_len/2 + 3 - epsilon <= 52, "drum gear world y must be ~48 (front plane, gear spans y 45..51)");
// Bevel axes intersect at the overhead apex + perpendicular (Y vs X).
assert(overhead_apex_x == overhead_counter_x && overhead_apex_z == overhead_counter_z, "overhead-drive: apex must sit on the Y countershaft (cx,44)");
assert(overhead_apex_y == overhead_high_y && overhead_apex_z == overhead_high_z, "overhead-drive: apex must sit on the high layshaft (45.5,44)");
assert(overhead_bevel_y_center_y == overhead_apex_y - overhead_bevel_x_r && overhead_apex_x == overhead_counter_x, "overhead-drive: Y bevel centre must be r_x off apex (cx,35.5,44)");
assert(overhead_bevel_x_center_x == overhead_apex_x + overhead_bevel_y_r && overhead_apex_y == overhead_high_y, "overhead-drive: X pinion centre must be r_y off apex (cx+12,45.5,44)");
assert(sqrt(pow(overhead_bevel_y_center_y-overhead_apex_y,2)) == overhead_bevel_x_r, "overhead-drive: Y pitch cone must touch apex");
assert(sqrt(pow(overhead_bevel_x_center_x-overhead_apex_x,2)) == overhead_bevel_y_r, "overhead-drive: X pitch cone must touch apex");
// Drop mesh: vertical centre distance = rh+rl (parallel X-X shafts).
assert(overhead_high_z - overhead_low_z == drop_pair_high_r + drop_pair_low_r, "overhead-drive: drop mesh must satisfy dz=rh+rl (27=15+12)");
assert(overhead_high_y == overhead_low_y, "overhead-drive: drop shafts must share Y (45.5)");
assert(overhead_high_x0 <= drop_pair_x && drop_pair_x + drop_pair_t/2 <= overhead_high_x1, "overhead-drive: drop-high must ride the high shaft");
assert(overhead_low_x0 <= drop_pair_x - drop_pair_t/2 && drop_pair_x <= overhead_low_x1, "overhead-drive: drop-low must ride the low shaft");
// Overhead clearance: every bevel/counter/drop-high bottom >= tape top + 5.
assert(overhead_counter_z - (overhead_counter_r + 2) - tape_top >= 5, "overhead-drive: counter bottom must clear the tape by >=5 (32 vs 22)");
assert(overhead_apex_z - (overhead_bevel_y_r + 2) - tape_top >= 5, "overhead-drive: Y bevel bottom must clear the tape by >=5 (30 vs 22)");
assert(overhead_apex_z - (overhead_bevel_x_r + 2) - tape_top >= 5, "overhead-drive: X pinion bottom must clear the tape by >=5 (32 vs 22)");
assert(overhead_high_z - (drop_pair_high_r + 2) - tape_top >= 5, "overhead-drive: drop-high bottom must clear the tape by >=5 (27 vs 22)");
// v51 hollow rotor: rods clear the bore, bobbins clear the tape
// corners (pocket half 3.9 x half-height 4 -> corner r 5.59), bobbins
// stay inside the ring OD envelope (export lift/min_z kept).
assert(rod51_orbit - rod51_r >= 8, "v51: holder rods must clear the ring bore (middle stays empty)");
assert(rod51_orbit - bob51_r > 5.6, "v51: bobbins must clear the tape corners on every orbit");
assert(rod51_orbit + bob51_r <= twister_ring_r + twister_ring_tube, "v51: bobbins must stay inside the ring OD envelope");
// friction drive (kept v51 geometry): wheel touches the ring OD
// (tangent), rides the low shaft mid-span, stays interior, clears
// the cradle post top.
assert(sqrt(pow(overhead_low_y-30,2) + pow(overhead_low_z-twister_axle_z,2)) == (twister_ring_r + twister_ring_tube) + friction_wheel_r, "overhead-drive: friction wheel must touch the ring OD (15.5 = 12+3.5)");
assert(overhead_low_x0 <= friction_wheel_x && friction_wheel_x <= overhead_low_x1, "overhead-drive: friction wheel must ride the low shaft span");
assert(overhead_low_y - friction_wheel_r >= 0 && overhead_low_y + friction_wheel_r <= 60, "overhead-drive: friction wheel must stay interior (y 42..49)");
assert(overhead_low_z - friction_wheel_r > twister_post_h, "overhead-drive: friction wheel must clear the cradle post top (13.5 vs 13)");
assert(friction_wheel_x - friction_wheel_t/2 >= bind_x && friction_wheel_x - friction_wheel_t/2 <= bind_x + 2, "overhead-drive: friction wheel face must meet the ring east face");
// Interior (zero exterior gears) + min_z.
assert(overhead_counter_y >= 0 && overhead_counter_y <= 60 && overhead_apex_y >= 0, "overhead-drive: drive must be interior (zero exterior gears)");
assert(drop_pair_x - drop_pair_t/2 >= 0 && drop_pair_x + drop_pair_t/2 <= 248, "overhead-drive: drop pair must stay inside the chassis");
assert(overhead_low_z - (drop_pair_low_r + 2) >= 0, "overhead-drive: drop-low must keep min_z>=0 (17-14=3)");
assert(overhead_low_z - overhead_low_r >= 0, "overhead-drive: low shaft must keep min_z above 0 (14.5)");
assert(overhead_high_z - overhead_high_r >= 0, "overhead-drive: high shaft must keep min_z above 0 (41.5)");
assert(overhead_counter_z - axle_dia/2 >= 0, "overhead-drive: countershaft must keep min_z above 0 (40)");
// Shafts supported: countershaft hidden in wall bores; layshafts ride posts.
assert(overhead_counter_y0 >= 0 && overhead_counter_y0 <= 2, "overhead-drive: countershaft must start hidden in the back wall bore (0..2)");
assert(overhead_counter_y1 >= 58 && overhead_counter_y1 <= 60, "overhead-drive: countershaft must end hidden in the front block bore");
assert(overhead_high_x0 == overhead_apex_x && overhead_high_x1 == drop_pair_x + drop_pair_t/2, "overhead-drive: high shaft must run apex->drop east face");
assert(overhead_low_x0 <= overhead_low_post_x && overhead_low_post_x <= overhead_low_x1, "overhead-drive: low post must stand under the low shaft");
assert(overhead_high_x0 <= overhead_high_post_x && overhead_high_post_x <= overhead_high_x1, "overhead-drive: high post must stand under the high shaft");
assert(overhead_high_post_top == overhead_high_z - overhead_high_r, "overhead-drive: high post top must meet the shaft bottom");
assert(overhead_low_post_top == overhead_low_z - overhead_low_r, "overhead-drive: low post top must meet the shaft bottom");
assert(overhead_high_post_top >= 0 && overhead_low_post_top >= 0, "overhead-drive: posts must stand on the base");
assert(overhead_high_y - 2 > 34 && overhead_low_y - 2 > 34, "overhead-drive: posts stay beside the tape (never over it)");
assert(overhead_low_z - (drop_pair_low_r + 2) > drop_pair_pocket_z0 + tolerance, "overhead-drive: drop-low bottom must clear the pocket floor (3 vs 2, rolling clearance)");
assert(axle_clearance_dia/2 > axle_dia/2, "v48: bores must slip on shafts (free spin, no fuse)");
// Drop-gear air gaps to neighbours (thin spinning pair, fail-loud;
// station envelopes + edge gaps >=5 untouched).
assert(drop_pair_x - drop_pair_t/2 - (bind_x + 5) >= 1, "overhead-drive: drop gears must clear the rod sweep (179 vs 177)");
assert((pull_x - vpull_sleeve_r) - (drop_pair_x + drop_pair_t/2) >= 2, "overhead-drive: drop gears must clear the pull station (183 vs 186.35)");
// v48 pull support: static pins base-fused, tops hidden in caps
// (no drive tube, no gear — tape-coupled nip, zero exterior gears).
assert(drop_pair_x - drop_pair_t/2 - (bind_x + 5) >= 1, "overhead-drive: drop gears must clear the rod sweep (179 vs 177)");
assert((pull_x - vpull_sleeve_r) - (drop_pair_x + drop_pair_t/2) >= 2, "overhead-drive: drop gears must clear the pull station (183 vs 186.35)");
assert(pull_pinA_z0 >= 0 && pull_pinA_z0 <= base_thick, "v48: pull pin A must start fused in the base");
assert(pull_pinA_z1 >= base_thick + vpull_h && pull_pinA_z1 <= base_thick + vpull_h + 3, str("v52: pull pin A top (27) must hide inside the roller top cap (24..27): ", pull_pinA_z1));
assert(pull_pinB_z1 > 25 && pull_pinB_z1 <= 28, str("v52: pull pin B top (27) must hide inside cup-B bore (25..28): ", pull_pinB_z1));
assert(spool_axle_z == 65, "spool_axle_z must be 65");
assert(chassis_height > max(spool_axle_z + cone_h + bb_height_spool, drum_axle_z + drum_outer_r) + 5,
       str("chassis_height must hold tallest axle + clearance: need > ", max(spool_axle_z+cone_h+bb_height_spool, drum_axle_z+drum_outer_r)+5, " got ", chassis_height));
assert(hopper_inner_r > drum_radius, "hopper_inner_r must exceed drum_radius (clearance >0)");
assert(plow_len > 15, str("plow_len must exceed 15, got ", plow_len));
assert(tape_thick >= 0.3, str("tape_thick must stay printable (>=0.3, no zero-thickness), got ", tape_thick));
assert(tape_bend_radius >= 1 && tape_bend_radius <= 6,
       str("tape_bend_radius out of envelope [1,6]: ", tape_bend_radius));
assert(tape_fold_angle > 0 && tape_fold_angle <= 180,
       str("tape_fold_angle out of envelope (0,180]: ", tape_fold_angle));
assert(fold_width/2 + tape_bend_radius + tape_thick <= (paper_width + 2*tolerance)/2,
       str("tape fold must fit the shroud inner half-width 13: ", fold_width/2 + tape_bend_radius + tape_thick));
assert((fold_start - tape_x0) + fold_len <= tape_len,
       str("tape fold segment must fit on the ribbon: need ", (fold_start - tape_x0) + fold_len, " <= ", tape_len));
assert(tape_x0 + tape_len >= fold_end, str("tape ribbon must reach the fold exit: ", tape_x0 + tape_len));
assert(fold_end <= drum_axle_x - drum_radius - 4,
       str("forming exit must sit fully west of the drum face (<=71): ", fold_end));
assert(fold_start >= 35 && fold_start <= 45,
       str("fold entry must sit at the roller nip (35-45): ", fold_start));
assert(transit_end == plow_start,
       str("transit must reach the plow mouth: ", transit_end));
assert((transit_end - tape_x0) <= tape_len,
       str("transit must fit on the ribbon: need ", (transit_end - tape_x0), " <= ", tape_len));
assert(tape_z + tape_thick + tape_bend_radius + tape_fold_wall + tape_shoulder_r*0.5 + 1.0 <= drum_axle_z - drum_radius,
       str("full-U transit top + 1 must clear the drum bottom (35): ", tape_z + tape_thick + tape_bend_radius + tape_fold_wall + tape_shoulder_r*0.5 + 1.0));
assert(fold_width/2 + tape_bend_radius + tape_thick <= 5.0,
       str("fold outer half-width must fit under the OD10 pipe footprint (5.0): ", fold_width/2 + tape_bend_radius + tape_thick));
assert(tape_x0 + tape_len >= plow_end, str("tape ribbon must reach the plow end: ", tape_x0 + tape_len));
assert(bind_x > plow_end, str("bind station must sit east of the plow end: ", bind_x));
assert(twister_arms == 2, "thread twister must carry exactly 2 thread arms");
assert(twister_orbits_per_drum == num_divots, "twister must orbit once per cavity (6 per drum rev, one bind per seed)");
assert(twister_axle_z + twister_ring_r + twister_ring_tube <= 40, str("twister ring top must clear the hover pipe/drum: ", twister_axle_z + twister_ring_r + twister_ring_tube));
assert(pull_x > bind_x, str("pull nip must sit east of the bind station: ", pull_x));
assert(abs(vpull_spin - 4/3) < 0.001, str("v52: spin compensation must be roller_body_r/vpull_r = 10/7.5 = 4/3 (same surface speed, spacing preserved): ", vpull_spin));
assert(abs(vpull_gap - 9.5) < 0.01, str("v52: cushioned nip gap must be 9.5+-0.01: ", vpull_gap));
assert(abs(2*vpull_off - 2*vpull_sleeve_r - vpull_gap) < 0.01, str("v52: nip offset must satisfy 2*off - 2*sleeve_r == gap (12.4/7.65/9.5): ", 2*vpull_off - 2*vpull_sleeve_r));
assert(takeup_x > pull_x, str("wind-up reel must sit east of the pull nip: ", takeup_x));
assert(takeup_x + takeup_flange_r <= chassis_x0 + chassis_len + 4, str("take-up flange must stay ~inside the chassis east edge: ", takeup_x + takeup_flange_r));
assert(takeup_z - takeup_flange_r >= 0, str("take-up flange bottom must stay >= 0: ", takeup_z - takeup_flange_r));
assert(takeup_z + takeup_flange_r <= chassis_height, str("take-up flange top must fit below wall top: ", takeup_z + takeup_flange_r));
assert(tape_x0 + tape_len >= tape_flat_end, str("v45: flat ribbon must reach the leader start: ", tape_x0 + tape_len));
assert(leader_x0 < tape_flat_end, str("v45: leader must overlap the flat ribbon: ", leader_x0));
assert(tape_flat_end <= takeup_x - takeup_flange_r, str("v45: flat ribbon must end before the reel flange (no dangle under/past reel): ", tape_flat_end));
assert(sqrt(pow(leader_x1 - takeup_x, 2) + pow(leader_z1 - takeup_z, 2)) <= tape_pack_r, str("v45: leader end must fuse inside the wound pack: ", sqrt(pow(leader_x1 - takeup_x, 2) + pow(leader_z1 - takeup_z, 2))));
assert(tape_pack_r == takeup_core_r + 3, str("v45: leader pack radius must match the takeup_reel() pack visual: ", tape_pack_r));
assert(bind_x - 4 - plow_end >= 5, str("v38: twister west face (bind_x-4) must clear plow end by >=5: ", bind_x - 4 - plow_end));
assert((pull_x - vpull_r) - (bind_x + 4) >= 5, str("v38: pull west face must clear twister east face by >=5: ", (pull_x - vpull_r) - (bind_x + 4)));
assert((takeup_x - takeup_flange_r) - (pull_x + vpull_r) >= 5, str("v38: take-up west face must clear pull east face by >=5: ", (takeup_x - takeup_flange_r) - (pull_x + vpull_r)));
// v39/v40 edge-to-edge station gaps (6-turner replaces the plow closer,
// same footprint so the v38 numbers hold; restated on turner_* names):
// turner_end 159 -> twister 168..176 (gap 9) -> pull 186.35..201.65 (gap 10.35)
// -> take-up 210..242 (gap 8.35). Fail loud, never silent.
assert(turner_start == plow_start && turner_end == plow_end && turner_len == plow_len,
       "v39: 6-turner footprint must equal the plow footprint (compat + clearance inheritance)");
assert(turner_start - drop_x >= 8,
       str("v40: 6-turner mouth must sit a little AFTER the drop point (flat landing first): ", turner_start - drop_x));
assert(bind_x - 4 - turner_end >= 5, str("v39: twister west face must clear 6-turner end by >=5: ", bind_x - 4 - turner_end));
assert((pull_x - vpull_sleeve_r) - (bind_x + 4) >= 5, str("v39: cushioned pull west face must clear twister east face by >=5: ", (pull_x - vpull_sleeve_r) - (bind_x + 4)));
assert((takeup_x - takeup_flange_r) - (pull_x + vpull_sleeve_r) >= 5, str("v39: take-up west face must clear cushioned pull east face by >=5: ", (takeup_x - takeup_flange_r) - (pull_x + vpull_sleeve_r)));
assert(vpull_sleeve_r <= 7.8, str("v52: cushion sleeve must stay ~d15 (spin-compensated 4/3 surface speed): ", vpull_sleeve_r));
assert(takeup_core_d < roller_dia, "v39: wind-up must step UP vs the roller (core d10 < d20)");
assert(clutch_stack == 10, str("v40: slip-clutch stack must be 10: ", clutch_stack));
assert(clutch_disc_r < takeup_flange_r, "v40: clutch discs must stay inside the flange envelope (X gap kept)");
assert(takeup_h_total == takeup_core_h + takeup_flange_t + clutch_stack,
       str("v40: take-up export height must include the clutch stack: ", takeup_h_total));
// v45 MOUNT INTEGRITY (forensic fix: floating gears/rotors/reels):
// dead-axle shafts seat every bore (slip fits, spinning parts stay free;
// gears fused); twister cradle keeps a rolling gap (no touch, no float);
// pull mid-collar clears the tape.
assert(drum_shaft_y0 >= 0 && drum_shaft_y0 <= 2, str("v48: drum shaft must start hidden in the back wall bore (0..2, zero exterior clutter): ", drum_shaft_y0));
assert(drum_shaft_y1 >= 58 && drum_shaft_y1 <= 60, str("v45: drum shaft must end hidden in the front block bore: ", drum_shaft_y1));
assert(hex_clearance_r > hex_axle_r, "v45: drum hex bore must slip on the shaft (free spin, no fuse)");
assert(takeup_shaft_y0 >= 0 && takeup_shaft_y0 <= 2, str("v48: take-up shaft must start hidden in the back wall bore (0..2, zero exterior clutter): ", takeup_shaft_y0));
assert(takeup_shaft_y1 >= 58 && takeup_shaft_y1 <= 60, str("v45: take-up shaft must end hidden in the front block bore: ", takeup_shaft_y1));
assert(axle_clearance_dia/2 > axle_dia/2, "v45: reel/wall/block bores must slip on the take-up shaft");
assert(spool_shaft_y0 >= 0 && spool_shaft_y0 <= 2, str("v45: spool shaft must start hidden in the back block bore: ", spool_shaft_y0));
assert(spool_shaft_y1 >= 58 && spool_shaft_y1 <= 60, str("v45: spool shaft must end hidden in the front block bore: ", spool_shaft_y1));
assert((twister_axle_z - twister_ring_tube) - twister_post_h >= 1.5, str("v45: twister cradle must keep a rolling gap (no touch): ", (twister_axle_z - twister_ring_tube) - twister_post_h));
assert((twister_axle_z - twister_ring_tube) - twister_post_h <= 4, str("v45: twister cradle must not float the rotor (gap <= 4): ", (twister_axle_z - twister_ring_tube) - twister_post_h));
assert(tape_z - (base_thick + vpull_collar_z + 1.5) >= 2, str("v45: pull mid-collar top must clear the ribbon base by >=2 (assembly lifts +base_thick): ", tape_z - (base_thick + vpull_collar_z + 1.5)));
assert(base_thick + vpull_h + 3 > 25 && base_thick + vpull_h + 3 <= 28, str("v52: pull roller B top (27) must engage cup B (cup 25..28, bridge 28): ", base_thick + vpull_h + 3));
assert(base_thick + vpull_h + 3 >= pull_pinA_z0 && base_thick + vpull_h + 3 <= pull_pinA_z1 + 3, str("v52: pull roller A top cap (27) must ride on the static pin (pin 2..27): ", base_thick + vpull_h + 3));
assert(crank_throw > 20 && crank_throw < 60, str("crank_throw out of envelope (20,60): ", crank_throw));
assert(crank_mount_x == crank_axle_x, str("crank_mount_x must equal crank_axle_x (160): ", crank_mount_x));
assert(crank_mount_y == chassis_width + 8, str("crank_mount_y must sit outside the front wall (68): ", crank_mount_y));
assert(crank_side == +1, "crank_side must be +1 (grip extends +Y outward front)");
assert(crank_axle_z + bb_height_roller <= chassis_height, "crank bearing block must fit below wall top");
assert(drum_axle_z + bb_height_drum <= chassis_height, "drum bearing block must fit below wall top");
assert(spool_axle_z + bb_height_spool <= chassis_height, "spool bearing block must fit below wall top");
assert(bolt_dia + 2*tolerance < 5, "M3 clearance holes must stay <5mm");
assert(8 + (bolt_head_across + 2*tolerance)/sqrt(3) < 13, "bearing-block bolts must clear block edges");

// ============================================================
// Helpers
// ============================================================
