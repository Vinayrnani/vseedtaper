/*
    Modular Hand-Cranked Seed Tape Machine - v2 Authoritative Spec
    ===========================================================
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
part_to_render = "all";
animate_assembly = true;

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
// v22 R->L order: hopper wedge (mouth ~100-183) > drum (100) >
//   shroud tunnel (58-84, centroid ~71) > roller/crank (40) >
//   spool (-6, far west, clear of the roller back gear).
// Gear mesh: |100-40|=60 = center_distance exact, same Z, same back-side plane.
// Plow stays EAST of drum (126->159, v1 precedent); tape scroll unchanged.
// v22 spool: x 10->-6 moves cone A (tapered r~19.5 at the gear plane)
//   46 off the roller gear centre in X -> real mesh gap ~4.5, and even
//   the conservative full-envelope boxes clear by 1.5 in X, fixing the
//   v21 graze with the r22 back gear (Y 9-15); chassis extends west to
//   seat the bearing block (-13..1 on the -14 edge).
// ============================================================
drum_axle_x  = 100;
drum_axle_z  = 60;   // ≥ drum_radius + base_thick + clearance = 29.3 ✓
roller_axle_x = 40;  // v21: 100-60, WEST of drum, coaxial mesh with drum gear
roller_axle_z = 60;  // same Z as drum for gear mesh; ≥ roller_outer_dia/2+1=23 ✓
// Gear mesh: drum(100,60) to roller(40,60) → distance=60mm ✓
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
plow_len      = 33; // v21 FIXED: decoupled from roller_axle_x (roller moved west
                     // of drum, so the old roller-based end 39-126 went negative
                     // and tripped the plow_len assert). Plow stays east (v1 precedent).
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
// v22 tape-cover shroud segment WEST of drum (roller nip -> drum exit).
// World x shroud_x0..shroud_x1 = 58..84 (centroid ~71): drum(100) >
// shroud(~71) > roller(40) R->L. Top (23) stays below the roller gear
// bottom (60-22=38) and the hopper cover bottom lip (~36.4 at x=84).
// v33: roof lowered 34->23 for the 13 lane (transit top 21.4 + 1.6
// cover clearance, ends open 0..21, tape at ~13).
shroud_x0  = roller_axle_x + 18;  // 58: gear-X overlap <=4, z-separated (top 23 < 38)
shroud_x1  = drum_axle_x - 16;    // 84: tucks to drum tangent, clears cover lip + drop tube (91+)
shroud_len = shroud_x1 - shroud_x0; // 26
shroud_h   = 23;                  // v33 enclosed tunnel height (tape slot 0..21, tape at ~13; was 34)

// ============================================================
// Crank (v23: drives the ROLLER shaft, coaxial at roller_axle_x, outside BACK wall)
// v23 side fix: crank was outside the FRONT wall (Y=chassis_width+8=68, grip +Y);
// user moved it to the OTHER side -> outside the BACK wall (Y=-8, grip mirrored -Y).
// Coaxial kept: [roller_axle_x=40, axle z=60], grip orbit r=crank_throw=45.
// Back gears (drum Y~12 + roller pinion Y~12) untouched; center_distance 60,
// gear_mesh_phase 9deg, $fn=60, tol=0.3 all kept.
// ============================================================
crank_throw     = 45;
crank_mount_x   = roller_axle_x; // 40: coaxial with roller axle (was 77.5 drum-left)
crank_mount_y   = -8; // v23: outside BACK wall (0-8); was chassis_width+8=68 front
crank_side      = -1; // v23: grip/arm mirror sign (-1 = extends -Y outward back; was +1 front)
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
tape_len         = 270;
tape_x0          = chassis_x0;   // -14: spans spool(-6)..take-up reel(226)+flange (v38: 220->270 reaches respaced bind/pull/wind)
tape_z           = 13;           // v33 lane (was 24): transit top 21.4 clears disc 35 by 13.6, ribbon top 13.4
tape_n_arc       = 20;           // arc facets per side (smooth like $fn=60 curves)
tape_n_x         = 12;           // taper steps along X (progressive entry->exit)

// ============================================================
// v37 Thread-bind + vertical pull + wind-up (v36 MVP backfill:
// hopper 9 o'clock -> 11-6 channel -> 6 o'clock drop onto the
// 1in folded tape -> thread bind -> vertical pull -> wind-up).
// All geared to the drum (6 cavities, 6in/152.4mm spacing intent):
// pull nip runs 1:1 with the main roller (same dia => same surface
// speed, spacing preserved); twister orbits once per cavity (6 per
// drum rev, one bind per seed); take-up winds the same linear tape
// (core d10 => 4 rev per $t, i.e. 2x crank). Bind sits just after
// the plow (bind_x = plow_end+8); pull nip stacks vertically over
// the finished tape at pull_x; reel sits east at takeup_x.
// v38 RESPACED (v37 overlapped: twister 163..171 touched pull 171..191
// at X=171, take-up 170..202 interpenetrated both in X/Y/Z).
// Sequential eastward with >=5mm steel-to-steel X gaps:
// plow end 159 -> twister 168..176 (gap 9) -> pull 184..204 (gap 8) ->
// take-up 210..242 (gap 6). Centres 32 apart for pull->take-up vs
// radii sum 10+16=26 + tol 0.3 + margin 5 = 31.3 (margin 5.7).
// $fn=60, tol=0.3 kept.
// ============================================================
bind_x   = plow_end + 13;   // 172: thread orbit station east of the plow (rotor X half 4 -> 168..176, gap 9)
pull_x   = plow_end + 35;   // 194: vertical-nip pull station (rollers r10 -> 184..204, gap 8 to twister east)
takeup_x = 226;             // wind-up reel east (flange r16 -> 210..242, gap 6 to pull east; chassis east 248)
takeup_z = 34;              // reel axle height (flange 18..50: bottom >= 0, top < 110)
twister_axle_z = tape_z + 4;      // 17: ring centre over the folded pocket (pocket top ~21)
twister_ring_r = 10;              // guide ring radius (tape pocket 7.8 passes through)
twister_ring_tube = 2;
twister_lift = twister_ring_r + twister_ring_tube; // 12: export lift for min_z=0
twister_arms = 2;                 // 2 threads orbit the tape
twister_orbits_per_drum = 6;      // one bind per cavity per drum rev (== num_divots)
vpull_r = 10;                     // vertical-axis nip roller radius (= roller_body_r: surface speed 1:1)
vpull_h = 24;                     // roller height (covers lane 13..21 + caps, base at 0)
vpull_off = vpull_r + 2.0 + 1.5 + 0.4 + tolerance; // 14.2: r + fold HW + bend R + thick + tol
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
turner_start = plow_start;        // 126: 6-curl mouth (flat landing 100..126 first)
turner_len = plow_len;            // 33
turner_end = plow_end;            // 159
turner_curl_r = 6.5;              // 6-curl outer radius (tape pocket 7.8 threads the bore)
turner_curl_bore = 4.2;           // 6-curl bore radius (dia 8.4 clears the 7.8 pocket)
turner_curl_off = 1.2;            // bore offset upward (thin top curl-over reads as "6")
turner_curl_cz = 12;              // curl axis height above the turner base

// ============================================================
// v43 TRUE-MESHED exterior gear train (NO belts anywhere, NO
// decorative idlers): crank -> drum 2:1 via the interior 40:20
// mesh (dist 60 = r20+r40, mesh-phased 9°) -> drum through-shaft
// takeoff D2-20T -> L1a-12T/L1b-36T compound -> L2-10T twister
// layshaft (6x drum: (20/12)*(36/10) = 6, even flips keep drum
// sign) -> rigid transfer to the twister rotor; crank through-shaft
// takeoff E0-12T -> 8x 12T idler chain east at z=16 -> PC-12T pull
// layshaft (equal teeth => 1:1, even flips keep crank sign); L1b-36T
// -> GT-15T -> GJ-15T -> GS-15T take-up layshaft coaxial with the
// reel axle (step-up 2x crank: (20/12)*(36/15) = 4x drum = 2x crank,
// odd flips reverse the winding sense vs v42).
// ALL module 2 (single module), every pair dist = r1+r2 (asserted
// fail-loud <= tol+0.01), teeth phased half-pitch tooth-into-gap,
// each layshaft on its own through-axle (boss + wall hole + block,
// no float), min_z >= 0 kept. Plane A = back-wall outer (y -8..-2),
// plane B = back-wall inner (y -16..-10); coaxial compounds share
// centre across planes. Stations/gaps untouched (turner lip 160.35
// -> twister gap 7.65, gaps >= 5).
// Speeds (rev per crank rev, sign about +Y): crank/E0 +1, drum/D2
// -0.5, L1 +0.833, L2/twister -3, chain -1..+1 alternating, PC/pull
// +1, GT -2, GJ +2, GS/takeup -2.
// vpull cushioned (v39): soft rubber/silicone sleeve visual over the
// steel core (OD stays ~d20 => 1:1 kept), firm grip without crushing.
// ============================================================
// Plane-A 12T pull chain (E0 takeoff rigid on the crank/roller
// through-shaft; PC layshaft adjacent to the pull nip at x=194).
extA_x = [40, 52.97, 56, 80, 104, 128, 152, 166.73, 190.22];
extA_z = [60, 39.81, 16, 16, 16, 16, 16, 34.94, 30];
extA_T = [12, 12, 12, 12, 12, 12, 12, 12, 12];
extA_names = ["E0", "H1", "R0", "C80", "C104", "C128", "C152", "H3", "PC"];
// Drum takeoff (rigid on the drum through-shaft) + twister compound:
// L1a-12T (plane A) + L1b-36T (plane B) rigid compound at L1.
extD2_x = 100; extD2_z = 60; extD2_T = 20;
extL1_x = 130.91; extL1_z = 51.72; extL1a_T = 12; extL1b_T = 36;
// Plane-B take-up branch: L2 twister pinion, GT/GJ idlers, GS reel gear.
extL2_x = 166.05; extL2_z = 22.03; extL2_T = 10;
extGT_x = 178.83; extGT_z = 69.16; extGT_T = 15;
extGJ_x = 205.94; extGJ_z = 56.31; extGJ_T = 15;
extGS_x = 226; extGS_z = 34; extGS_T = 15;
vpull_sleeve_r = 10.15;           // cushioned sleeve outer (proud 0.15, under the r11 caps: envelope kept)
vpull_sleeve_h = 16;

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
assert(roller_axle_z >= roller_outer_dia/2 + 1, str("roller_axle_z must clear base: need >= ", roller_outer_dia/2+1, " got ", roller_axle_z));
assert(drum_axle_z >= drum_radius + base_thick + tolerance, str("drum_axle_z must clear cradle+tape: need >= ", drum_radius+base_thick+tolerance, " got ", drum_axle_z));
assert(abs(sqrt(pow(roller_axle_x - drum_axle_x,2)+pow(roller_axle_z - drum_axle_z,2)) - center_distance) < 0.5,
       str("gear center distance must be ~60mm, got ", sqrt(pow(roller_axle_x-drum_axle_x,2)+pow(roller_axle_z-drum_axle_z,2))));
// v43 exterior train: single module 2 + every mesh dist = r1+r2
// (fail-loud <= tol+0.01; coordinates rounded to 0.01 so err < 0.05).
assert(gear_module == 2, "v43: exterior train must stay single module 2");
assert(len(extA_x) == 9 && len(extA_z) == 9 && len(extA_T) == 9, "v43: plane-A chain arrays must hold 9 stations");
for (i=[0:7])
    assert(abs(sqrt(pow(extA_x[i+1]-extA_x[i],2)+pow(extA_z[i+1]-extA_z[i],2)) - gear_module*(extA_T[i+1]+extA_T[i])/2) <= tolerance+0.01,
        str("v43: plane-A mesh ", extA_names[i], "-", extA_names[i+1], " must satisfy dist=r1+r2"));
assert(abs(sqrt(pow(extL1_x-extD2_x,2)+pow(extL1_z-extD2_z,2)) - gear_module*(extD2_T+extL1a_T)/2) <= tolerance+0.01, "v43: D2-L1a mesh must satisfy dist=r1+r2 (32)");
assert(abs(sqrt(pow(extL2_x-extL1_x,2)+pow(extL2_z-extL1_z,2)) - gear_module*(extL1b_T+extL2_T)/2) <= tolerance+0.01, "v43: L1b-L2 mesh must satisfy dist=r1+r2 (46)");
assert(abs(sqrt(pow(extGT_x-extL1_x,2)+pow(extGT_z-extL1_z,2)) - gear_module*(extL1b_T+extGT_T)/2) <= tolerance+0.01, "v43: L1b-GT mesh must satisfy dist=r1+r2 (51)");
assert(abs(sqrt(pow(extGJ_x-extGT_x,2)+pow(extGJ_z-extGT_z,2)) - gear_module*(extGT_T+extGJ_T)/2) <= tolerance+0.01, "v43: GT-GJ mesh must satisfy dist=r1+r2 (30)");
assert(abs(sqrt(pow(extGS_x-extGJ_x,2)+pow(extGS_z-extGJ_z,2)) - gear_module*(extGJ_T+extGS_T)/2) <= tolerance+0.01, "v43: GJ-GS mesh must satisfy dist=r1+r2 (30)");
assert((20/extL1a_T)*(extL1b_T/extL2_T) == 6, "v43: twister step-up must be 6x drum");
assert((20/extL1a_T)*(extL1b_T/extGT_T)*(extGT_T/extGJ_T)*(extGJ_T/extGS_T) == 4, "v43: take-up step-up must be 4x drum (2x crank)");
assert(min(extA_z) - (gear_module*12/2+2) >= 0, "v43: lowest plane-A gear must keep min_z>=0");
assert(extL2_z - (gear_module*extL2_T/2+2) >= 0, "v43: twister pinion must keep min_z>=0");
assert(extGT_z + (gear_module*extGT_T/2+2) <= chassis_height, "v43: GT must fit below wall top");
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
assert(vpull_r == roller_body_r, "vertical-pull dia must equal main roller dia (1:1 surface speed, spacing preserved)");
assert(takeup_x > pull_x, str("wind-up reel must sit east of the pull nip: ", takeup_x));
assert(takeup_x + takeup_flange_r <= chassis_x0 + chassis_len + 4, str("take-up flange must stay ~inside the chassis east edge: ", takeup_x + takeup_flange_r));
assert(takeup_z - takeup_flange_r >= 0, str("take-up flange bottom must stay >= 0: ", takeup_z - takeup_flange_r));
assert(takeup_z + takeup_flange_r <= chassis_height, str("take-up flange top must fit below wall top: ", takeup_z + takeup_flange_r));
assert(tape_x0 + tape_len >= takeup_x + takeup_flange_r, str("tape ribbon must reach the wind-up reel: ", tape_x0 + tape_len));
assert(bind_x - 4 - plow_end >= 5, str("v38: twister west face (bind_x-4) must clear plow end by >=5: ", bind_x - 4 - plow_end));
assert((pull_x - vpull_r) - (bind_x + 4) >= 5, str("v38: pull west face must clear twister east face by >=5: ", (pull_x - vpull_r) - (bind_x + 4)));
assert((takeup_x - takeup_flange_r) - (pull_x + vpull_r) >= 5, str("v38: take-up west face must clear pull east face by >=5: ", (takeup_x - takeup_flange_r) - (pull_x + vpull_r)));
// v39/v40 edge-to-edge station gaps (6-turner replaces the plow closer,
// same footprint so the v38 numbers hold; restated on turner_* names):
// turner_end 159 -> twister 168..176 (gap 9) -> pull 184..204 (gap 8)
// -> take-up 210..242 (gap 6). Fail loud, never silent.
assert(turner_start == plow_start && turner_end == plow_end && turner_len == plow_len,
       "v39: 6-turner footprint must equal the plow footprint (compat + clearance inheritance)");
assert(turner_start - drop_x >= 8,
       str("v40: 6-turner mouth must sit a little AFTER the drop point (flat landing first): ", turner_start - drop_x));
assert(bind_x - 4 - turner_end >= 5, str("v39: twister west face must clear 6-turner end by >=5: ", bind_x - 4 - turner_end));
assert((pull_x - vpull_sleeve_r) - (bind_x + 4) >= 5, str("v39: cushioned pull west face must clear twister east face by >=5: ", (pull_x - vpull_sleeve_r) - (bind_x + 4)));
assert((takeup_x - takeup_flange_r) - (pull_x + vpull_sleeve_r) >= 5, str("v39: take-up west face must clear cushioned pull east face by >=5: ", (takeup_x - takeup_flange_r) - (pull_x + vpull_sleeve_r)));
assert(vpull_sleeve_r <= 10.3, str("v39: cushion sleeve must stay ~d20 (1:1 surface speed): ", vpull_sleeve_r));
assert(takeup_core_d < roller_dia, "v39: wind-up must step UP vs the roller (core d10 < d20)");
assert(clutch_stack == 10, str("v40: slip-clutch stack must be 10: ", clutch_stack));
assert(clutch_disc_r < takeup_flange_r, "v40: clutch discs must stay inside the flange envelope (X gap kept)");
assert(takeup_h_total == takeup_core_h + takeup_flange_t + clutch_stack,
       str("v40: take-up export height must include the clutch stack: ", takeup_h_total));
assert(crank_throw > 20 && crank_throw < 60, str("crank_throw out of envelope (20,60): ", crank_throw));
assert(crank_mount_x == roller_axle_x, str("crank_mount_x must be coaxial with roller axle: ", crank_mount_x));
assert(crank_mount_y == -8, str("crank_mount_y must sit outside the back wall (-8): ", crank_mount_y));
assert(crank_side == -1, "crank_side must be -1 (grip extends -Y outward back)");
assert(roller_axle_z + bb_height_roller <= chassis_height, "roller bearing block must fit below wall top");
assert(drum_axle_z + bb_height_drum <= chassis_height, "drum bearing block must fit below wall top");
assert(spool_axle_z + bb_height_spool <= chassis_height, "spool bearing block must fit below wall top");
assert(bolt_dia + 2*tolerance < 5, "M3 clearance holes must stay <5mm");
assert(8 + (bolt_head_across + 2*tolerance)/sqrt(3) < 13, "bearing-block bolts must clear block edges");

// ============================================================
// Helpers
// ============================================================
module hex_hole(length, flat_across, clearance=0) {
    r = (flat_across + 2*clearance) / sqrt(3);
    cylinder(h=length + 2*epsilon, r=r, $fn=6, center=true);
}

module round_axle_hole(length, dia, clearance=0) {
    cylinder(h=length + 2*epsilon, d=dia + 2*clearance, center=true);
}

// ============================================================
// 20° PA Trapezoidal Spur Gear (advanced)
// Each tooth = hull(tip_cylinder, root_cylinder) for tapered flanks.
// ============================================================
module spur_gear(teeth, module_mm, thickness, bore_flat=0, bore_dia=0, is_hex=false,
                 hub_dia=0, hub_len=0, lightened=false, collar_dia=0, collar_len=0) {
    assert(teeth >= 10 && teeth <= 60, "spur_gear: teeth out of range [10,60]");
    assert(module_mm > 0, "spur_gear: module_mm must be >0");
    assert(thickness > 0, "spur_gear: thickness must be >0");
    pitch_dia = module_mm * teeth;
    outer_dia = pitch_dia + 2*addendum;
    root_dia  = pitch_dia - 2*dedendum;
    pitch_r = pitch_dia/2;
    outer_r = outer_dia/2;
    root_r  = root_dia/2;
    circ_pitch = PI * module_mm;
    tip_arc = tooth_arc_frac * circ_pitch;
    tip_d  = tip_arc;
    rootd  = 0.72 * circ_pitch;
    tip_ctr_r  = outer_r - tip_d/2;
    root_ctr_r = root_r - 0.3;
    pitch_ang = 360/teeth;
    has_hub = hub_dia > 0 && hub_len > 0;
    has_collar = collar_dia > 0 && collar_len > 0;
    hub_mid_z = thickness/2 + hub_len/2;
    stack_bot = -thickness/2 - (has_collar ? collar_len : 0);
    stack_top  = thickness/2 + (has_hub ? hub_len : 0);
    bore_len = stack_top - stack_bot + 2*epsilon;
    bore_mid_z = (stack_top + stack_bot)/2;
    web_n = 5;
    web_mid_r = has_hub ? (hub_dia/4 + root_dia/4) : root_dia/4;
    web_hole_d = has_hub ? min(14, min((root_dia - hub_dia)/2 - 4, 2*PI*web_mid_r/web_n - 6)) : 0;

    difference() {
        union() {
            cylinder(h=thickness, d=root_dia, center=true);
            for (i=[0:teeth-1]) {
                rotate([0,0,i*pitch_ang]) {
                    // Trapezoidal tooth: hull of tip (small) + root (wider) cylinders
                    hull() {
                        translate([root_ctr_r, 0, 0])
                            cylinder(h=thickness + 2*epsilon, d=rootd, $fn=12, center=true);
                        translate([tip_ctr_r, 0, 0])
                            cylinder(h=thickness + 2*epsilon, d=tip_d, $fn=12, center=true);
                    }
                    // Tip chamfer (r1≠r2)
                    translate([tip_ctr_r, 0,  thickness/2])
                        cylinder(h=1.2, r1=tip_d/2 + 0.15, r2=tip_d/2 - 0.55, $fn=12, center=true);
                    translate([tip_ctr_r, 0, -thickness/2])
                        cylinder(h=1.2, r1=tip_d/2 - 0.55, r2=tip_d/2 + 0.15, $fn=12, center=true);
                    // Root fillet (small cylinder at root corners, hull)
                    for (s=[-1,1])
                        rotate([0,0,s*0.28*pitch_ang])
                            translate([root_r + 0.2, 0, 0])
                                cylinder(h=thickness + 2*epsilon, r=0.9, $fn=12, center=true);
                }
            }
            if (has_hub)
                translate([0, 0, thickness/2 - epsilon])
                    cylinder(h=hub_len + epsilon, d=hub_dia, center=false);
            if (has_collar)
                translate([0, 0, -thickness/2 - collar_len])
                    cylinder(h=collar_len + epsilon, d=collar_dia, center=false);
        }
        // Bore
        if (is_hex) {
            translate([0, 0, bore_mid_z])
                hex_hole(length=bore_len, flat_across=bore_flat, clearance=tolerance);
        } else if (bore_dia > 0) {
            translate([0, 0, bore_mid_z])
                cylinder(h=bore_len, d=bore_dia + 2*tolerance, center=true);
        }
        // Hub hex bore
        if (has_hub)
            translate([0, 0, hub_mid_z])
                rotate([0,90,0])
                    hex_hole(length=hub_dia + 2*epsilon, flat_across=3, clearance=tolerance);
        // Lightening cutouts (4-5 circular)
        if (lightened && has_hub)
            for (k=[0:web_n-1])
                rotate([0,0,k*360/web_n + 36])
                    translate([web_mid_r, 0, 0])
                        cylinder(h=thickness + 2*epsilon, d=web_hole_d, center=true);
    }
}

// M3 hex-head bolt visual
module hex_bolt(shank_len) {
    head_r = bolt_head_across / sqrt(3);
    union() {
        cylinder(h=2.5, r=head_r, $fn=6, center=false);
        translate([0, 0, -shank_len + epsilon])
            cylinder(h=shank_len, d=bolt_dia, center=false);
    }
}

// ============================================================
// Bearing block (pillow-block style): base + cap + 2× hex bolts + nut traps
// ============================================================
module bearing_block(spec_x, spec_z, spec_height, is_drum=false, y_off=0) {
    bore_r = is_drum ? hex_clearance_r : axle_clearance_dia/2;
    difference() {
        union() {
            translate([spec_x - bb_len/2, y_off - bb_wall/2, spec_z - spec_height])
                cube([bb_len, bb_wall, spec_height]);
            translate([spec_x - bb_len/2, y_off - bb_wall/2, spec_z])
                cube([bb_len, bb_wall, 2]);
            for (sx=[-1,1])
                translate([spec_x + sx*4, y_off - bb_wall/2 - 0.1, spec_z + 1])
                    cylinder(h=2+epsilon, d=bolt_dia+2*tolerance, center=false);
        }
        // Axle bore
        translate([spec_x, y_off - bb_wall/2, spec_z])
            rotate([90,0,0])
                cylinder(h=bb_len+2*epsilon, r=bore_r, center=true);
        // Nut traps
        for (sx=[-1,1])
            translate([spec_x + sx*4, y_off - bb_wall/2 - 1, spec_z + 1])
                cylinder(h=2+epsilon, r=(bolt_head_across+2*tolerance)/sqrt(3), $fn=6, center=false);
    }
}

// ============================================================
// 1. Chassis - with bearing blocks, gussets, chamfers, lightening
// ============================================================
module chassis() {
    difference() {
        union() {
            translate([chassis_x0, 0, 0])
                cube([chassis_len, chassis_width, base_thick]);
            translate([chassis_x0, 0, 0])
                cube([chassis_len, wall_thick, chassis_height]);
            translate([chassis_x0, chassis_width - wall_thick, 0])
                cube([chassis_len, wall_thick, chassis_height]);
            // Track rails
            rail_thick = 2;
            rail_len = 200;
            rail_x0 = 10;
            translate([rail_x0, (chassis_width - paper_width)/2 - rail_thick, base_thick - 0.15])
                cube([rail_len, rail_thick, track_depth + 0.15]);
            translate([rail_x0, (chassis_width + paper_width)/2, base_thick - 0.15])
                cube([rail_len, rail_thick, track_depth + 0.15]);
            // Hopper slide rails
            translate([drum_axle_x - 22, 7, base_thick - 0.15])
                cube([44, 8, 6 + 0.15]);
            translate([drum_axle_x - 22, chassis_width - 15, base_thick - 0.15])
                cube([44, 8, 6 + 0.15]);
            // Bearing blocks (pillow-block style)
            for (spec=[[roller_axle_x, roller_axle_z, bb_height_roller, 0],
                       [drum_axle_x,   drum_axle_z,   bb_height_drum,   1],
                       [spool_axle_x,  spool_axle_z,  bb_height_spool,  0]])
                for (side=[0,1]) {
                    // v27 printable: fuse blocks to BOTH walls (front y_off=0
                    // -> Y -2..2 overlaps wall 0..3; back y_off=60 -> 58..62
                    // overlaps wall 57..60). Old code ignored side (all at
                    // front, back blocks floated unfused).
                    bearing_block(spec[0], spec[1], spec[2], spec[3]==1,
                                  side == 0 ? 0 : chassis_width);
                }
            // v37 wind-up reel bearing blocks (axle along Y at takeup_x/takeup_z)
            for (side=[0,1])
                bearing_block(takeup_x, takeup_z, bb_height_spool, false,
                              side == 0 ? 0 : chassis_width);
            // v40 MOUNTING LAYOUT (parametric on the station X positions):
            // BOTTOM mount: 6-turner (M3 holes below) + wind-up reel
            //   (take-up bearing blocks above ride the base).
            // SIDE mount: twister ring + pull rollers + drum (axles pass
            //   through the chassis walls: axle holes + blocks below).
            // TOP mount: hopper+shroud (slide rails + sole-flange M3) +
            //   tape input spools (spool blocks feed from above).
            // v40 pull top bridge (side-mount story for the vertical nip):
            // cross bar fused wall-to-wall over the nip at pull_x with a
            // top bearing cup over each roller axle (X 192..196 stays
            // inside the pull envelope 184..204: no clearance change).
            translate([pull_x - 2, 0, 32])
                cube([4, chassis_width, 3]);
            for (s=[-1,1])
                translate([pull_x, chassis_width/2 + s*vpull_off, 29])
                    cylinder(h=3 + epsilon, r=6, center=false);
            // v43 TRUE-MESHED exterior train (gear-only, NO belts, NO
            // decorative idlers): plane-A 12T chain E0..PC (mesh dist 24
            // exact, alternating half-pitch phase tooth-into-gap) driven
            // by the crank through-shaft (E0 rigid) to the pull layshaft
            // PC (+1 = crank speed, 1:1); drum takeoff D2-20T (rigid on
            // the drum through-shaft) drives the L1a-12T/L1b-36T compound
            // (dist 32) whose plane-B 36T drives the L2-10T twister pinion
            // (dist 46, -3 = 6x drum) + the GT/GJ/GS 15T take-up branch
            // (51/30/30, -2 = 2x crank, sense reversed vs v42). Each
            // layshaft: exterior boss ring + axle stub passing through
            // the back wall into a bearing block (side-mount, no float).
            // GS sits coaxial with the take-up reel axle (direct drive);
            // L2 couples to the twister rotor via a short rigid layshaft
            // bracket (6mm offset, documented in GEAR_RATIO.md).
            for (i=[0:len(extA_x)-1])
                translate([extA_x[i], -8, extA_z[i]])
                    rotate([90, 0, 0])
                        rotate([0, 0, (i%2)*180/extA_T[i]])
                            spur_gear(teeth=extA_T[i], module_mm=gear_module, thickness=6);
            // Drum takeoff D2 (plane A, phase 0 = rigid with drum).
            translate([extD2_x, -8, extD2_z])
                rotate([90, 0, 0])
                    spur_gear(teeth=extD2_T, module_mm=gear_module, thickness=6);
            // Twister compound L1: L1a plane A (half-pitch 15°) + L1b
            // plane B (phase 0, rigid mate) on one through-axle.
            translate([extL1_x, -8, extL1_z])
                rotate([90, 0, 0])
                    rotate([0, 0, 180/extL1a_T])
                        spur_gear(teeth=extL1a_T, module_mm=gear_module, thickness=6);
            translate([extL1_x, -16, extL1_z])
                rotate([90, 0, 0])
                    spur_gear(teeth=extL1b_T, module_mm=gear_module, thickness=6);
            // Plane-B branch gears (half-pitch phased tooth-into-gap).
            translate([extL2_x, -16, extL2_z])
                rotate([90, 0, 0])
                    rotate([0, 0, 180/extL2_T])
                        spur_gear(teeth=extL2_T, module_mm=gear_module, thickness=6);
            translate([extGT_x, -16, extGT_z])
                rotate([90, 0, 0])
                    rotate([0, 0, 180/extGT_T])
                        spur_gear(teeth=extGT_T, module_mm=gear_module, thickness=6);
            translate([extGJ_x, -16, extGJ_z])
                rotate([90, 0, 0])
                    spur_gear(teeth=extGJ_T, module_mm=gear_module, thickness=6);
            translate([extGS_x, -16, extGS_z])
                rotate([90, 0, 0])
                    rotate([0, 0, 180/extGS_T])
                        spur_gear(teeth=extGS_T, module_mm=gear_module, thickness=6);
            // Layshaft bosses (exterior boss rings on the back wall;
            // E0/D2 ride the existing crank/drum through-shafts, GS
            // rides the take-up axle with its bearing blocks below).
            for (i=[1:len(extA_x)-1])
                translate([extA_x[i], -5, extA_z[i]])
                    rotate([90, 0, 0])
                        cylinder(h=12, r=6, center=true);
            for (px=[[extL1_x, extL1_z], [extL2_x, extL2_z], [extGT_x, extGT_z], [extGJ_x, extGJ_z]])
                translate([px[0], -9, px[1]])
                    rotate([90, 0, 0])
                        cylinder(h=20, r=6, center=true);
            // v37 twister guide posts (static frame for the orbiting ring:
            // two posts flanking the tape at bind_x hold the ring axle
            // height; the rotor GLB stays a pure symmetric rotor so the
            // viewer can spin it about X without orbiting the frame)
            for (s=[-1,1])
                translate([bind_x - 2, chassis_width/2 + s*12 - 1.5, 0])
                    cube([4, 3, twister_axle_z]);
            // Corner gussets via hull() of cubes
            for (gy=[0, chassis_width - 6]) {
                translate([chassis_x0 + 4, gy, base_thick - 0.15])
                    hull() {
                        cube([12, 6, 1.15]);
                        translate([0, 0, 12]) cube([1.5, 6, 1]);
                    }
                translate([chassis_x0 + chassis_len - 16, gy, base_thick - 0.15])
                    hull() {
                        cube([12, 6, 1.15]);
                        translate([10.5, 0, 12]) cube([1.5, 6, 1]);
                    }
            }
        }
        // Axle holes (nominal + 2*tolerance)
        for (side=[0,1]) {
            translate([spool_axle_x, side*(chassis_width-wall_thick)+wall_thick/2, spool_axle_z])
                rotate([90,0,0])
                    cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        }
        for (side=[0,1]) {
            translate([takeup_x, side*(chassis_width-wall_thick)+wall_thick/2, takeup_z])
                rotate([90,0,0])
                    cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        }
        for (side=[0,1]) {
            translate([roller_axle_x, side*(chassis_width-wall_thick)+wall_thick/2, roller_axle_z])
                rotate([90,0,0])
                    cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        }
        for (side=[0,1]) {
            translate([drum_axle_x, side*(chassis_width-wall_thick)+wall_thick/2, drum_axle_z])
                rotate([90,0,0])
                    cylinder(h=wall_thick+2*epsilon, r=hex_clearance_r, $fn=6, center=true);
        }
        // v43 exterior-train layshaft through-holes (back wall only:
        // each layshaft axle passes through the wall into its boss).
        for (i=[1:len(extA_x)-1]) {
            translate([extA_x[i], -wall_thick/2, extA_z[i]])
                rotate([90,0,0])
                    cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        }
        for (px=[[extL1_x, extL1_z], [extL2_x, extL2_z], [extGT_x, extGT_z], [extGJ_x, extGJ_z]]) {
            translate([px[0], -wall_thick/2, px[1]])
                rotate([90,0,0])
                    cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        }
        // 45° chamfers on base edges
        translate([chassis_x0, chassis_width/2, base_thick])
            rotate([0,45,0])
                cube([2.5, chassis_width + 2*epsilon, 2.5], center=true);
        translate([chassis_x0 + chassis_len, chassis_width/2, base_thick])
            rotate([0,45,0])
                cube([2.5, chassis_width + 2*epsilon, 2.5], center=true);
        // Plow mounting holes
        for (px=[plow_start + 6, plow_start + plow_len - 6])
            for (py=[6, 54]) {
                translate([px, py, base_thick/2])
                    cylinder(h=base_thick + 2*epsilon, d=bolt_dia + 2*tolerance, center=true);
                translate([px, py, -epsilon])
                    cylinder(h=nut_trap_depth + epsilon,
                             r=(bolt_head_across + 2*tolerance)/sqrt(3), $fn=6, center=false);
            }
        // Hopper rail slots
        translate([drum_axle_x - 20.2, 7 + (8-6.4)/2, base_thick - epsilon])
            cube([40.4, 6.4, 6 + 2*epsilon]);
        translate([drum_axle_x - 20.2, chassis_width - 15 + (8-6.4)/2, base_thick - epsilon])
            cube([40.4, 6.4, 6 + 2*epsilon]);
        // Lightening cutouts in walls (v43: back cutout moved 90->56
        // + up 18->64 so the exterior gear chain (C80/C104 bosses at
        // z 2..30) keeps solid wall to fuse to; front cutout kept).
        translate([56, -epsilon, 64])
            cube([24, wall_thick+2*epsilon, 22]);
        translate([90, chassis_width - wall_thick - epsilon, 18])
            cube([30, wall_thick+2*epsilon, 22]);
    }
}

// ============================================================
// 2. Spool cones (tapered, 15-45mm OD) - flat base at Z=0
// ============================================================
module single_cone() {
    difference() {
        cylinder(h=cone_h, r1=cone_r_big, r2=cone_r_small, center=false);
        translate([0,0,cone_h])
            hex_hole(length=cone_h+2, flat_across=hex_axle_flat, clearance=tolerance);
        translate([0,0,cone_h-1])
            cylinder(h=2, r1=cone_r_small-1, r2=cone_r_small, center=false);
    }
}

module spool_cones() {
    single_cone();
    translate([50, 0, 0]) single_cone();
}

// ============================================================
// 3. Hopper (v17: SINGLE printed piece — cover + trough joined at SIDES).
//    v17 changes.jpg fixes (2026-09-16): RED = diagonal side pads DELETED
//    (they crossed the cavity sweep annulus); BLUE = arc side-closure fins
//    r[26.5,28.5] 30..122deg saddle-fuse wedge root to cover lip, mouth
//    sides closed, middle open (gap 1.0); PINK = tip sealed watertight
//    (floor runs into 6-thick nose, void ends x70, 2-wide tip blocks).
//    Local frame: drum center at [0,0,hopper_axis_z], axle along Y.
//    (a) Retention cover = open-top half-cut 16mm pipe channel
//    120..270deg (11 o'clock top lip -> 6 o'clock bottom lip at drop),
//    wall 2, gap 1.5 (smooth 1.5-2 channel, no ribs/steps), bore fits
//    8mm seed, inner-face groove (w7 x d0.8) matching drum cavity track.
//    Top open: seed travel visible hopper->11 o'clock in top view.
//    (b) RIGHT sharp-point wedge trough: UPPER edge EXACTLY HORIZONTAL
//    (cheek tops level, mouth z=73 to apex z=73); LOWER floor +8 deg
//    about the 3-o'clock point to sharp apex (x=83, +X). Closed seed
//    box (seeds retained, no open gap): apex end wall + 2 side joints
//    close the mouth sides, top stays open for fill/visibility.
//    Volume sits at 9 o'clock, max around wheel up to 10:30.
//    Inner-face floor groove (w7 x d0.8) matches drum.
//    (c) BOTTOM-CENTER DROP TUBE at 6 o'clock (x=0): 4 box walls
//    straight down, bore 10 x 15.6 (v29: 10 fits 8mm seeds with
//    clearance, was 9), bottom local z=25.9 (world 29.9, 0.5 below
//    the tape ribbon top 30.4 so the walls touch/seal with 0.5
//    overlap, no seed-spill gap). Drum carve trims tube
//    top into smooth drum-conforming funnel mouth (no ledges); bore
//    void pierces cover bottom = drop port; thick walls saddle-fuse
//    to cover lips (single object). Pickup mouth (right 1:30-3
    //    o'clock) = opening between 11-o'clock lip and wedge root (NO tab
    //    across drum); gap 1.0 so cavities scoop freely.
// ============================================================
module hopper_body() {
    assert(hopper_axis_z > drum_radius, "hopper_body: hopper_axis_z must clear drum radius");
    assert(hopper_wall > 0, "hopper_body: hopper_wall must be >0");
    wall = hopper_wall;                    // 2.5
    floor_thick = wall + 1;                // v16: keep solid floor 3.5 (holds seeds as one bowl)
    cheek_in = drum_width/2 + tolerance;   // 7.8: axial half-gap hugging drum faces
    mouth_gap = 1.0;                       // v16: revert 0.7->1.0 nominal — drum spins free
    assert(mouth_gap >= 0.5 && mouth_gap <= 1.0, "hopper_body: mouth gap must be 0.5-1mm");
    assert(2*cheek_in >= 9, "hopper_body: mouth must pass 8mm seeds");
    drum_c = [0, 0, hopper_axis_z];
    y_out = cheek_in + wall;               // 10.3 outer half-width

    // Wedge side profile (v12: top edge EXACTLY horizontal at z=73).
    x0 = 14; x_tip = 83;
    cheek_top0 = 73;                       // cheek top edge at mouth (upper wall line)
    cheek_bot_root = 49;                   // v19 SEAL (was 53): skirt below floor top
    apex_top = 73; cheek_bot_tip = 59;     // v19 SEAL (was 70.5): tip skirt below floor
    LOW_TILT = 8;                          // lower floor rises a little to the right
    tilt_pivot = [25, 0, 56];              // 3-o'clock mouth point on drum
    floor_half = cheek_in + 1.0;           // v19 SEAL (was +0.5): floor sides bury into cheeks
    floor_lx1 = (84.5 - tilt_pivot[0])/cos(LOW_TILT);  // v19 SEAL: floor local-x end = world x84.5
    // BOTTOM-CENTER hover pipe (v35 thinnest printable wall: 6-o'clock,
    // x=0 = drum centre; round pipe OD10/ID7.6 (wall 1.2) L10 hangs from
    // the hopper floor, bottom hovers drop_gap=10 above the ribbon top --
    // NO seal, NO slots).
    // Tapered groove (inner wide 16 -> 7.6 throat) funnels seeds into the
    // pipe bore; drum carve trims the funnel stub into a smooth
    // drum-conforming mouth (no ledges); bore void pierces cover bottom
    // = drop port; thick funnel walls saddle-fuse to cover lips (single
    // object). Drop x=100 world; the full-U transit (world 70..126) runs
    // UNDER the pipe with a 10 air gap (pipe bottom 23.4 vs pocket top
    // ~21.15 at the drop: seed falls from the bore into the moving pocket).
    // Verified coords (world): ribbon top 13.4, pipe 23.4..33.4, flange
    // bottom 33.5 (flange-to-tape 20.1), disc bottom 35 (gap 21.6/11.6).
    // ENTRY (v35 inspection): throat centre local x=0 == drum drop point
    // world x=100, Y centred (offset 0.0 < 0.5); funnel half-angle ~8.6deg
    // from vertical (steep, no hang); sharp 90deg circular inner rims at
    // the bore ends are broken by 45deg lead-in flares (legs 0.6/0.8>=0.6).
    drop_pipe_id = 7.6; drop_pipe_od = 10; drop_pipe_len = 10; drop_gap = 10;
    throat_cx = 0;                       // v35: funnel throat centre (local X)
    entry_flare_leg = 0.6;               // v35: bore exit 45deg break leg (>=0.6)
    mouth_flare_leg = 0.8;               // v35: throat entry 45deg break leg (>=0.6)
    pipe_bot_local = tape_z + tape_thick + drop_gap - (drum_axle_z - hopper_axis_z); // 19.4
    pipe_top_local = pipe_bot_local + drop_pipe_len; // 29.4
    tube_x0 = -5; tube_x1 = 5;
    bore_x0 = -3.8; bore_x1 = 3.8;
    tube_z0 = pipe_bot_local; tube_z1 = 52;
    assert(abs(drop_pipe_id - 7.6) < 0.001, "hopper_body: hover pipe ID must be 7.6 (thinnest wall)");
    assert(drop_pipe_od == 10, "hopper_body: hover pipe OD must be 10");
    assert(drop_pipe_len == 10, "hopper_body: hover pipe length must be 10");
    assert(abs((drop_pipe_od - drop_pipe_id)/2 - 1.2) < 0.001, "hopper_body: hover pipe wall must be 1.2 (thinnest printable)");
    assert(abs((bore_x1 - bore_x0) - 7.6) < 0.001, "hopper_body: drop bore must be 7.6");
    assert(tube_x1 - tube_x0 == 10, "hopper_body: drop tube outer must be 10");
    assert(abs((bore_x0 - tube_x0) - 1.2) < 0.001, "hopper_body: drop tube X wall must be 1.2");
    assert(throat_cx == drum_c[0], "hopper_body: funnel throat centre must equal drum drop point x (local 0 = world 100)");
    assert(entry_flare_leg >= 0.6, "hopper_body: bore exit lead-in leg must be >=0.6");
    assert(mouth_flare_leg >= 0.6, "hopper_body: funnel-mouth lead-in leg must be >=0.6");
    assert(tube_z0 + (drum_axle_z - hopper_axis_z) == tape_z + tape_thick + drop_gap,
           "hopper_body: hover pipe bottom must sit tape_top+10 (no seal)");
    assert(drop_gap >= 10, "hopper_body: hover gap must be >=10");
    assert((drum_axle_z - 26.5) - (tape_z + tape_thick) >= 20,
           "hopper_body: flange-to-tape clearance must be >=20");
    // v16: NO full-width step tab (it sat ON the drum and rubbed). Joint is
    // SIDES ONLY (see 2 SIDE JOINTS below): middle stays open for drum.

    difference() {
        union() {
            // Triangular cheek plates (v19 SEAL: bottom edge deepened to
            // overlap the floor top along the whole wedge — root 49, tip
            // 59: bottom slope ~0.17 tracks the 8deg floor so the plates
            // swallow the floor sides x16..83 with 4-6mm vertical overlap;
            // drum carve trims the mouth reach. Tip nub 3.5-long ending
            // x84.5, buried in the nose).
            for (s = [-1, 1])
                hull() {
                    translate([x0, s > 0 ? cheek_in : -y_out, cheek_bot_root])
                        cube([10, wall, cheek_top0 - cheek_bot_root]);
                    translate([x_tip - 6, s > 0 ? cheek_in : -y_out, cheek_bot_tip])
                        cube([5, wall, apex_top - cheek_bot_tip]);
                    translate([x_tip - 2, s > 0 ? cheek_in : -y_out, (apex_top + cheek_bot_tip)/2 - 1])
                        cube([3.5, wall, 2]);
                }
            // Lower floor slab (v19 SEAL: runs to x84.5 deep into the nose,
            // half-width floor_half buries 1.0 into the cheek band).
            translate(tilt_pivot)
                rotate([0, -LOW_TILT, 0])
                    translate([-9, -floor_half, -floor_thick])
                        cube([floor_lx1 + 9, 2*floor_half, floor_thick]);
            // v17 BLUE side-closure fins (the ONLY cover<->trough joint):
            // arc band r[26.5,28.5] sweeping 30..122deg at each cheek strip,
            // saddle-fusing wedge root (x14..24) to the 11-o'clock cover lip
            // (overlap 120..122 same radii). Mouth sides closed (seeds can't
            // fall out sideways); middle stays open, drum OD clears 1.5,
            // cavities sweep centrally — seed path unblocked.
            // (v17 RED: old diagonal side pads DELETED — they crossed the
            // cavity sweep annulus and stopped/sheared seeds.)
            for (s = [-1, 1])
                translate(drum_c)
                    rotate([90, 0, 0])
                        rotate([0, 0, 30])
                            rotate_extrude(angle=92, convexity=10)
                                translate([27.5, -s*(cheek_in + wall/2), 0])
                                    square([2, wall], center=true);
            // Closed nose (v19 SEAL: 7 thick x78..85, half-width y_out+0.6
            // swallowing cheek ends + floor sides (kills coplanar outer
            // faces), foot 58 below floor bottom, cap 73.5 above cheek tops
            // — overlaps floor (to x84.5), cheeks (tip nub to x84.5) and fin
            // band into one sealed bowl. Fill via open top, mouth via drum).
            translate([78, -(y_out + 0.6), 58])
                cube([7, 2*(y_out + 0.6), 15.5]);
            // Root-top gussets (v19 SEAL: fill the carve-edge/fin-underside
            // triangle x13..25 z70..79 each side; drum carve trims r<26 so
            // the mouth stays open with 1.0 gap, remainder fuses cheek root
            // tops to the BLUE fin band; outer face proud +0.3, inner sunk
            // -0.5 to avoid coplanar faces).
            for (s = [-1, 1])
                translate([13, s > 0 ? cheek_in - 0.5 : -(y_out + 0.3), 70])
                    cube([12, (y_out + 0.3) - (cheek_in - 0.5), 9]);
            // Retention cover (v12: smooth annular channel, NO ribs).
            // v14 RED: blocking rib removed — seed path clear from pickup
            // mouth (120deg) all along rotation to 6-o'clock drop (270deg).
            // Annular arc 120..270deg about the drum axle (Y): top lip at
            // 11 o'clock, wrapping over top/left down to the 6-o'clock
            // bottom lip where the drop tube starts. rotate_extrude rings
            // about Z; Rx(90) maps its axis onto the drum axle (Y) and its
            // sweep plane onto side-view XZ (start +X, CCW toward +Z/up).
            // Gap 1.5 (spec 1.5-2), wall 2, full width. The bore void
            // pierces the arc bottom = drop port; thick tube walls below
            // saddle-fuse to the arc lips (single object).
            translate(drum_c)
                rotate([90, 0, 0])
                    rotate([0, 0, 120])
                        rotate_extrude(angle=150, convexity=10)
                            translate([drum_radius + 1.5 + 1, 0, 0])
                                square([2, 2*y_out], center=true);
            // v35 thinnest-wall hover pipe + tapered funnel (single manifold solid):
            // round tube OD10 (r5) from the hover bottom up L10, fused into
            // a tapered outer cone (r5 -> r10) running up into the hopper
            // (wall 1.2 at the pipe growing to 2.0 at the funnel top vs
            // the inner void: 5-3.8 = 1.2, 10-8 = 2.0; drum carve trims
            // the top into the mouth, remainder fuses to cover lips).
            translate([0, 0, pipe_bot_local])
                cylinder(h=drop_pipe_len, r=drop_pipe_od/2, center=false);
            translate([0, 0, pipe_top_local - epsilon])
                cylinder(h=tube_z1 - pipe_top_local + epsilon, r1=drop_pipe_od/2, r2=10, center=false);
        }
        // Drum clearance: wide open mouth tangent to drum, mouth_gap radial gap.
        // Lower chin auto-formed by carve retains the seed pool (gap 1.0 < 3mm).
        translate(drum_c)
            rotate([90,0,0])
                cylinder(h=2*y_out + 2*epsilon, r=drum_radius + mouth_gap, center=true);
        // Open-top trough void (v17 PINK: ends x70, stops 8 short of the
        // nose inner face so the tip stays a solid watertight bowl).
        translate(tilt_pivot)
            rotate([0, -LOW_TILT, 0])
                translate([-3, -(cheek_in + 0.5), -0.5])
                    cube([48, 2*(cheek_in + 0.5), 30.5]);
        // v35 drop bore + tapered groove + 45deg lead-ins (no window box, no tape slots):
        // cylindrical ID7.6 bore through the hover pipe + tapered inner
        // cone (r4.6 -> r8, wide 16 -> 7.6 throat, ~8.6deg from vertical)
        // up through the funnel to the drum mouth (fed by the 6 cavities
        // over the top, not by the trough void). Drum carve trims the
        // funnel stub into a smooth drum-conforming mouth (only ~1 survives
        // above the pipe top; the rest is open mouth air by design).
        // Profile is monotonic (no radial step >0.3 anywhere, no overhang
        // in the seed travel direction). Two 45deg breaks: bore-exit flare
        // (r3.8->r4.4 over h0.6, 0.6 flat land left) kills the bottom sharp
        // inner rim; throat entry flare (r3.8->r4.6 over h0.8, leg 0.8>=0.6)
        // breaks the bore-to-cone edge into a self-clearing 45deg lead-in.
        // Pipe hovers 10 above the tape: no notches, no seal overlap.
        // Trough (HW 2.0, outer 7.8 < OD10) stays centred under the bore
        // (bore +-3.8, mouth 7 < ID7.6: seed lands INSIDE the
        // already-folded transit pocket below).
        translate([0, 0, pipe_bot_local - epsilon])
            cylinder(h=drop_pipe_len + 2*epsilon, r=drop_pipe_id/2, center=false);
        translate([0, 0, pipe_top_local - epsilon])
            cylinder(h=(tube_z1 - pipe_top_local) + epsilon, r1=drop_pipe_id/2 + mouth_flare_leg, r2=8, center=false);
        // v35 bore-exit lead-in: 45deg break of the bottom sharp inner rim
        // (unioned into the bore void; top r == bore r, no step above).
        translate([throat_cx, 0, pipe_bot_local - epsilon])
            cylinder(h=entry_flare_leg + epsilon, r1=drop_pipe_id/2 + entry_flare_leg, r2=drop_pipe_id/2, center=false);
        // v35 throat entry lead-in: 45deg flare straddling the pipe top
        // (base r == bore r sits inside the bore wall, top r == cone base
        // r; continuous profile, slope-only kinks, no radial step).
        translate([throat_cx, 0, pipe_top_local - mouth_flare_leg])
            cylinder(h=mouth_flare_leg + epsilon, r1=drop_pipe_id/2, r2=drop_pipe_id/2 + mouth_flare_leg, center=false);
        // Cover inner-face groove (v14 YELLOW: w7 x d0.8 along 120..270 arc,
        // matches drum 6-cavity track for wheel-to-frame positioning ONLY
        // (NOT seed drive); shallow guide, channel stays smooth).
        translate(drum_c)
            rotate([90, 0, 0])
                rotate([0, 0, 120])
                    rotate_extrude(angle=150, convexity=10)
                        translate([drum_radius + shroud_gap + groove_d/2, 0, 0])
                            square([groove_d + epsilon, groove_w], center=true);
        // Floor inner-face groove (v14 YELLOW: central longitudinal guide
        // w7 x d0.8 along tilted floor, matches drum cavity track for
        // wheel-to-frame positioning ONLY, NOT seed drive).
        translate(tilt_pivot)
            rotate([0, -LOW_TILT, 0])
                translate([-9, -groove_w/2, -groove_d])
                    cube([(x_tip + 1) - 16, groove_w, groove_d + epsilon]);
    }
}

// ============================================================
// 4. Shroud — v22 REAL PART (was v14 legacy annular stub): enclosed tape
//    cover tunnel WEST of the drum, roller nip -> drum exit (local x
//    0..shroud_len = world 58..84, centroid ~71, Y centred on the track).
//    Side walls stand on the base (flat print base min_z=0) + sole
//    flanges; top plate clears the tape (v33 ends open 0..21, tape at ~13);
//    top (23) stays below the roller gear bottom (38) and the hopper
//    cover bottom lip (~36.4 at x=84). Round side view-ports (d10) show
//    the tape. Inner width = paper_width + 2*tol; curves use $fn=60.
//    Local frame: x 0..len, y centred 0, z 0..shroud_h. Assembly places
//    it at [shroud_x0, chassis_width/2, 0]; export is standalone min_z=0.
// ============================================================
module u_channel_shroud() {
    assert(shroud_len > 15, str("u_channel_shroud: shroud_len must exceed 15, got ", shroud_len));
    assert(shroud_x1 <= drum_axle_x - 16,
           str("u_channel_shroud: east end must stay clear of the hopper cover lip, got ", shroud_x1));
    assert(shroud_x0 >= roller_axle_x + roller_outer_r - 4,
           str("u_channel_shroud: west end must stay near the roller nip, got ", shroud_x0));
    assert(shroud_h < roller_axle_z - roller_outer_r,
           str("u_channel_shroud: top must stay below the roller gear bottom (38), got ", shroud_h));
    wall = shroud_wall;                          // 2
    inner_hw = (paper_width + 2*tolerance)/2;    // 13
    outer_hw = inner_hw + wall;                  // 15
    top_t = 2;                                   // v33 top plate 21..23 (was 32..34)
    slot_hw = 6.45;                              // v33: central top slot passes
                                                 // the transit walls (5.35)
                                                 // + shoulder kinks (6.3)
    assert(outer_hw - slot_hw >= 6,
           str("u_channel_shroud: top strips must stay printable (>=6): ", outer_hw - slot_hw));
    port_d = 10;
    port_z = 18; // v33: spans 13..23 = lane base 13 to roof 23, tape stays visible
    difference() {
        union() {
            // Side walls (stand on base, full length/height)
            for (s=[-1,1])
                translate([0, s > 0 ? inner_hw : -outer_hw, 0])
                    cube([shroud_len, wall, shroud_h]);
            // Top plate (ends stay open 0..21 for the tape; v33 central
            // slot full length passes the transit walls, strips cover
            // the wings on both sides)
            for (s=[-1,1])
                translate([0, s > 0 ? slot_hw : -outer_hw, shroud_h - top_t])
                    cube([shroud_len, outer_hw - slot_hw, top_t]);
            // Sole flanges (mounting feet, solid, min_z=0)
            for (s=[-1,1])
                translate([0, s > 0 ? outer_hw : -outer_hw - 4, 0])
                    cube([shroud_len, 4, 3]);
        }
        // Round side view-ports (d10) down each wall — tape stays visible
        for (s=[-1,1])
            for (px=[shroud_len/4, 3*shroud_len/4])
                translate([px, s*(inner_hw + wall/2), port_z])
                    rotate([90,0,0])
                        cylinder(h=wall + 2*epsilon, d=port_d, center=true);
        // v27 printable: M3 mounting holes in sole flanges (were solid with
        // no fasteners). Flange centre Y = s*(outer_hw+2), 2 holes per side.
        for (s=[-1,1])
            for (px=[6, shroud_len - 6])
                translate([px, s*(outer_hw + 2), -epsilon])
                    cylinder(h=3 + 2*epsilon, d=bolt_dia + 2*tolerance, center=false);
    }
}

// ============================================================
// 5. Seed cartridge (drum) with chamfered divot mouths + end flange rings
//    v14 MVP: 6 cavities FIXED (num_divots=6). Wheels interchangeable BY
//    HAND (no tools): slip-fit hex bore (tolerance clearance, no set
//    screw) slides off the drum hex shaft; cavity size varies via sdia
//    (1-6mm seeds), count stays 6.
// ============================================================
module seed_cartridge(sdia = seed_dia, sdepth = seed_depth) {
    assert(sdia > 0 && sdia <= 6.0, "seed_cartridge: seed_dia out of range (0,6] (v14: 1-6mm wheels)");
    assert(sdepth > 0 && sdepth < drum_radius, "seed_cartridge: seed_depth invalid");
    drum_len = drum_width;
    gear_thick = 6;
    // v20: drum gear sits on BACK side of drum (-gear_off, world Y~12).
    // gear_off shared by both branches so export matches assembly.
    gear_off = roller_len/2 + gear_thick/2 - epsilon;  // 17.95
    gear_z = gear_thick/2 + 0.6;  // 3.6: web center (tip chamfer dips 0.6 below web, base keeps min_z=0)
    drum_base = gear_z + gear_off - drum_len/2;  // 14.05: export drum lift

    if (part_to_render == "cartridge" || part_to_render == "drum") {
        // VERTICAL orientation for STL export (base at Z=0)
        // v20: gear web on print base hub-up, drum raised (fused via hub).
        union() {
            translate([0, 0, drum_base])
            difference() {
                cylinder(h=drum_len, d=drum_dia, center=false);
                translate([0,0,-epsilon])
                    cylinder(h=drum_len+2*epsilon, r=hex_clearance_r, $fn=6, center=false);
                for (i=[0:num_divots-1]) {
                    ang = i*360/num_divots;
                    rotate([0,0,ang])
                    translate([drum_dia/2, 0, drum_len/2]) {
                        sphere(d=sdia + 2*tolerance, $fn=24);
                        translate([-sdepth/2, 0, 0])
                            rotate([0,90,0])
                                cylinder(h=sdepth+epsilon, d=sdia+2*tolerance, center=true);
                        // Chamfered divot mouth
                        translate([-0.3, 0, 0])
                            rotate([0,90,0])
                                cylinder(h=1.2 + 2*epsilon, r1=(sdia + 2*tolerance)/2,
                                         r2=(sdia + 2*tolerance)/2 + 1.2, center=true);
                    }
                }
                translate([0,0,drum_len-1])
                    cylinder(h=1+epsilon, d1=drum_dia-1, d2=drum_dia+1, center=false);
            }
            // End flange rings
            for (fz=[drum_base+0.15, drum_base+drum_len - 3.25])
                translate([0, 0, fz])
                    difference() {
                        cylinder(h=1.5, d=drum_dia + 3, center=false);
                        translate([0, 0, -epsilon])
                            cylinder(h=1.5 + 2*epsilon, d=drum_dia - 6, center=false);
                    }
            // Drum gear (lightened, 40T) — v20 BACK/BOTTOM side, chamfer-aware base
            translate([0,0, gear_z])
                spur_gear(teeth=drum_teeth, module_mm=gear_module, thickness=gear_thick,
                          bore_flat=hex_axle_flat, is_hex=true,
                          hub_dia=20, hub_len=8, lightened=true);
        }
    } else {
        // HORIZONTAL for assembly preview
        translate([0, 0, drum_dia/2]) {
            union() {
                difference() {
                    rotate([90,0,0])
                        cylinder(h=drum_len, d=drum_dia, center=true);
                    rotate([90,0,0])
                        cylinder(h=drum_len+2*epsilon, r=hex_clearance_r, $fn=6, center=true);
                    for (i=[0:num_divots-1]) {
                        ang = i*360/num_divots;
                        rotate([0, ang, 0]) {
                            translate([0, 0, drum_dia/2]) {
                                sphere(d=sdia + 2*tolerance, $fn=24);
                                translate([0,0, -sdepth/2])
                                    cylinder(h=sdepth+epsilon, d=sdia+2*tolerance, center=true);
                                translate([0, 0, -0.3])
                                    cylinder(h=1.2 + 2*epsilon, r1=(sdia + 2*tolerance)/2,
                                             r2=(sdia + 2*tolerance)/2 + 1.2, center=true);
                            }
                        }
                    }
                    for (side=[-1,1])
                        translate([0, side*(drum_len/2 - 0.5), 0])
                        rotate([90,0,0])
                            cylinder(h=1+epsilon, d1=drum_dia-1, d2=drum_dia+1, center=false);
                }
                for (s=[-1,1])
                    translate([0, s*(drum_len/2 - 2.5), 0])
                        rotate([90,0,0])
                            difference() {
                                cylinder(h=1.5, d=drum_dia + 3, center=true);
                                cylinder(h=1.5 + 2*epsilon, d=drum_dia - 6, center=true);
                            }
                // v20: gear on BACK side (-gear_off); mirrored rotation so hub
                // still points AT the drum (else gear floats un-fused).
                translate([0, -gear_off, 0])
                    rotate([-90,0,0])
                        spur_gear(teeth=drum_teeth, module_mm=gear_module, thickness=gear_thick,
                                  bore_flat=hex_axle_flat, is_hex=true,
                                  hub_dia=20, hub_len=8, lightened=true);
            }
        }
    }
}

// ============================================================
// 6. Seed cradle - 25.4mm-wide track + U depression under drop port (270°)
// ============================================================
module seed_cradle() {
    track_w = paper_width + 2*tolerance; // 26.0
    cradle_len = plow_len;
    difference() {
        union() {
            // Flat base (min_z=0)
            cube([cradle_len, track_w, base_thick]);
            // U-channel walls
            translate([0, 0, base_thick])
                cube([cradle_len, track_w/2 - cradle_u_radius, cradle_u_depth]);
            translate([0, track_w/2 + cradle_u_radius, base_thick])
                cube([cradle_len, track_w/2 - cradle_u_radius, cradle_u_depth]);
            // U depression directly under drop port (270° = bottom)
            translate([-epsilon, track_w/2 - cradle_u_radius, base_thick + cradle_u_depth - cradle_u_radius])
                rotate([0,90,0])
                    cylinder(h=cradle_len+2*epsilon, r=cradle_u_radius, center=false);
        }
        // Through-holes for mounting
        for (px=[plow_start+6, plow_start+cradle_len-6])
            for (py=[track_w/2 - 5, track_w/2 + 5]) {
                translate([px, py, -epsilon])
                    cylinder(h=base_thick+2*epsilon, d=bolt_dia+2*tolerance, center=false);
            }
    }
}

// ============================================================
// 7. 6-turner SECOND STAGE (v42 TRUE 6-fold: tape is ALREADY U-bent
// by the first stage forming 37..70 + transit 70..126; this piece
// only folds the 2 U edges INSIDE into an overlapping roll).
// Local frame like the old plow: x 0..turner_len (33, world
// 126..159), y 0..40 (tape centre y=20), z 0..curl top, min_z=0.
// STAGE A (entry x 0..10): open U-accept channel — two side walls
// hold the incoming U-section (mouth inner 7 from the first stage)
// + low converging guides (25.4 -> ~8 funnel, first-stage wings).
// STAGE B (x 8..24): two SYMMETRIC edge-curl horns (solid former
// noses r2.5 at y=cy+-4.2) roll the left/right U edges inward/down;
// an inner tongue plate dives from the crown into the bore and ends
// in an inner roll (r2.2 solid along X inside the bore) — the tongue
// + inner roll IS the inner loop of the "6", folding edges INSIDE.
// STAGE C (exit x 24..33): near-closed tube — exit ring (outer r5.5,
// bore r3.2 < main bore 4.2) necks the roll shut; top seam lip
// overlaps the joint so the end-on cross-section reads as "6"
// (outer curl + inner tongue), NOT a plain round tube.
// Main bore (r4.2 offset +1.2, dia 8.4) still clears the 7.8 pocket;
// footprint/tabs/posts/positions unchanged (turner 126..159 ->
// twister 168..176 gap 9 kept). part_to_render "plow" (compat) and
// "turner" both render this.
// ============================================================
module six_turner() {
    assert(turner_len > 15, str("six_turner: turner_len must exceed 15, got ", turner_len));
    assert(turner_curl_bore * 2 > 7.8, str("six_turner: bore dia must clear the 7.8 pocket: ", turner_curl_bore * 2));
    tw = 40;                        // v1-precedent width kept (old plow_w)
    cy = tw/2;                      // 20: tape centre
    curl_x0 = 8; curl_len = 22;     // main tube x 8..30 (inside 0..33)
    curl_cz = turner_curl_cz;       // 12
    curl_r = turner_curl_r;         // 6.5
    bore_r = turner_curl_bore;      // 4.2
    bore_cz = curl_cz + turner_curl_off; // 13.2: bore 9..17.4
    // Second-stage fold members (all inside the 0..33 footprint):
    horn_r = 2.5;                   // edge-curl horn nose radius
    horn_y = 4.2;                   // horns at cy+-4.2 (U edges at +-3.9)
    horn_cz = curl_cz + 1.5;        // 13.5: horn centre over the U walls
    horn_x0 = 6; horn_len = 14;     // horns x 6..20 (stage B)
    tongue_len = 12;                // tongue x 6..18 dives crown->bore
    inner_roll_r = 2.2;             // inner roll of the "6" (folded edges)
    inner_roll_len = 14;            // x 12..26 inside the bore
    exit_len = 4;                   // exit ring x 29..33 (stage C)
    exit_r = 5.5; exit_bore = 3.2;  // necked near-closed exit
    assert(horn_x0 + horn_len <= curl_x0 + curl_len, "six_turner: horns must overlap the main tube (fused, no float)");
    assert(12 + inner_roll_len <= curl_x0 + curl_len, "six_turner: inner roll must sit inside the main tube");
    assert(curl_x0 + curl_len + exit_len - 1 <= turner_len, "six_turner: exit ring must stay in footprint");
    assert(exit_bore < bore_r, "six_turner: exit must neck down vs main bore (near-closed roll)");
    assert(horn_cz - horn_r >= base_thick, "six_turner: horns must clear the base top");
    plan_ang = atan(((paper_width - 8)/2)/turner_len);
    // Outer shell is cut by the bores; the inner fold members (tongue
    // tip + inner roll) are added AFTER the cut so the bore void cannot
    // delete them — they stay fused to the crown/exit and read as the
    // inner loop of the "6" in end-on cross-section.
    union() {
        difference() {
            union() {
                // Base plate (bottom mount, min_z=0)
                cube([turner_len, tw, base_thick]);
                // Low converging entry guides (funnel 25.4 -> ~8, first-stage wings)
                translate([0, cy - paper_width/2 - 1, base_thick])
                    rotate([0, 0, plan_ang])
                        cube([turner_len + 2, 2, 6]);
                translate([0, cy + paper_width/2 + 1 - 2, base_thick])
                    rotate([0, 0, -plan_ang])
                        cube([turner_len + 2, 2, 6]);
                // STAGE A: open U-accept channel walls (entry x 0..12 hold the
                // incoming U-section: inner faces at cy+-3.9 clear the 7.8 pocket)
                for (s=[-1,1])
                    translate([0, cy + s*5.9 - (s > 0 ? 0 : 2), base_thick - epsilon])
                        cube([12, 2, 6]);
                // STAGE B+C outer: 6-curl outer tube along X
                translate([curl_x0, cy, curl_cz])
                    rotate([0, 90, 0])
                        cylinder(h=curl_len, r=curl_r, center=false);
                // Entry flare funnel (mouth r8 -> tube, guides the seeded U-pocket in)
                translate([curl_x0 - 3, cy, curl_cz])
                    rotate([0, 90, 0])
                        cylinder(h=3 + epsilon, r1=curl_r + 1.5, r2=curl_r, center=false);
                // STAGE B: two SYMMETRIC edge-curl horns (solid former noses
                // rolling the left/right U edges inward/down into the bore)
                for (s=[-1,1])
                    translate([horn_x0, cy + s*horn_y, horn_cz])
                        rotate([0, 90, 0])
                            cylinder(h=horn_len, r=horn_r, center=false);
                // Horn bridge fins fuse horns to the outer tube (no float)
                for (s=[-1,1])
                    translate([horn_x0 + 4, cy + s*horn_y - 1, horn_cz - 3])
                        cube([6, 2, 3 + epsilon]);
                // Horn foot posts fuse horns down to the base (no float)
                for (s=[-1,1])
                    translate([horn_x0 + 2, cy + s*horn_y - 1, base_thick - epsilon])
                        cube([4, 2, horn_cz - horn_r - base_thick + epsilon]);
                // Tongue ROOT (outside the bore: fused into the crown/flare,
                // survives the bore cut; the tip continues below post-cut)
                translate([curl_x0 - 2, cy - 3, bore_cz + 2.8])
                    rotate([0, -18, 0])
                        cube([6, 6, 1.5]);
                // STAGE C: exit ring (near-closed tube: necks the roll shut)
                translate([curl_x0 + curl_len - 1, cy, curl_cz])
                    rotate([0, 90, 0])
                        cylinder(h=exit_len, r=exit_r, center=false);
                // Top seam-overlap lip (the "6" tail overlapping the joint)
                translate([curl_x0 + curl_len - 2, cy - 1.5, curl_cz + exit_r - 1.5])
                    rotate([0, -8, 0])
                        cube([6, 3, 1.5]);
                // Side posts fuse the tube to the base (both flanks)
                for (s=[-1,1])
                    translate([curl_x0 + 4, cy + s*5 - 1, base_thick - epsilon])
                        cube([6, 2, curl_cz - base_thick - 0.5]);
                for (s=[-1,1])
                    translate([curl_x0 + 14, cy + s*5 - 1, base_thick - epsilon])
                        cube([6, 2, curl_cz - base_thick - 0.5]);
                // Mounting tabs (same pattern as the old plow: chassis M3 holes line up)
                for (tx=[2, turner_len - 10]) {
                    translate([tx, -8, 0]) cube([8, 8.15, 3]);
                    translate([tx, tw - 0.15, 0]) cube([8, 8.15, 3]);
                }
                // Tab bolts visual
                for (bx=[6, turner_len - 6])
                    for (by=[-4, tw + 4]) {
                        translate([bx, by, 0]) cylinder(h=3, d=bolt_dia, center=false);
                        translate([bx, by, 3 - epsilon]) cylinder(h=2.5, r=bolt_head_across/sqrt(3), $fn=6, center=false);
                    }
            }
            // 6 bore (offset up: thin crown = the curl-over of the "6")
            translate([curl_x0 - epsilon, cy, bore_cz])
                rotate([0, 90, 0])
                    cylinder(h=curl_len + 3 + 2*epsilon, r=bore_r, center=false);
            // Entry flare void (funnel into the bore)
            translate([curl_x0 - 3 - epsilon, cy, bore_cz])
                rotate([0, 90, 0])
                    cylinder(h=3 + 2*epsilon, r1=bore_r + 1.8, r2=bore_r, center=false);
            // Exit bore (necked: near-closed roll exit, still passes the roll)
            translate([curl_x0 + curl_len - 1 - epsilon, cy, bore_cz])
                rotate([0, 90, 0])
                    cylinder(h=exit_len + 2*epsilon, r=exit_bore, center=false);
            // Tab bolt clearance holes
            for (bx=[6, turner_len - 6])
                for (by=[-4, tw + 4])
                    translate([bx, by, -epsilon])
                        cylinder(h=3 + 2*epsilon, d=bolt_dia + 2*tolerance, center=false);
        }
        // POST-CUT inner fold members (survive the bore void):
        // tongue tip dives crown->bore folding edges INSIDE + inner roll
        // along X inside the bore (overlapped folded edges). Both overlap
        // the tongue root / exit ring so nothing floats.
        translate([curl_x0 + 1.5, cy - 3, bore_cz + 0.6])
            rotate([0, -18, 0])
                cube([tongue_len, 6, 1.5]);
        translate([12, cy + 0.5, bore_cz - 0.5])
            rotate([0, 90, 0])
                cylinder(h=inner_roll_len, r=inner_roll_r, center=false);
    }
}

// Legacy alias (compat): the old U-plow export name now builds the 6-turner.
module folding_plow() {
    six_turner();
}

// ============================================================
// 7b. Seed tape with center U-fold bend (v28 true mimic, v31 west,
// v33 lane 13). Local frame: x 0..tape_len, y centred 0, z 0..fold-top,
// min_z=0. Flat paper_width ribbon full length (single-layer trough
// floor) + U-fold channel fused on top: FORMING taper over local x
// fold_start-tape_x0 = 51 (world 37..70, W-shallow->E-full) then a
// STRAIGHT full-U transit (same section, no taper) local 84..140
// (world 70..126, through the shroud slot, under the drum with air
// gap, UNDER the hover pipe with a 10 gap to the plow mouth): bottom edges at
// +-hw rise via quarter-arc sides R=tape_bend_radius sweeping
// tape_fold_angle, then straight vertical walls tape_fold_wall, then a
// reverse S-shoulder per side (outward kink + foot landing back on the
// ribbon wings so the sheet reads continuous, no floating free edge).
// Fold depth tapers along X in forming (tape_n_x steps, scale
// 0.15->1.0 W->E: shallow flat-entry, full-U exit = chamfered entry);
// transit holds sc=1. Ribbon boxes centered ON the fold
// path (thickness +-0.2) with epsilon overlap so the union stays
// manifold, never zero-thickness.
// Allowed modules only: union/cube/for/if/translate/rotate.
// ============================================================
module seed_tape_bend() {
    fx0 = fold_start - tape_x0;        // 51: forming segment local x (world 37..70)
    dx = fold_len/tape_n_x;
    tx0 = fold_end - tape_x0;          // 84: transit local x (world 70..126)
    n_t = ceil(transit_len/4);         // ~4mm straight chunks
    dx_t = transit_len/n_t;
    union() {
        // Flat ribbon full length (base min_z=0, single-layer floor)
        translate([0, -paper_width/2, 0])
            cube([tape_len, paper_width, tape_thick]);
        // Forming taper: W shallow -> E full-U exit
        for (xi=[0:tape_n_x-1])
            fold_section(fx0 + xi*dx, dx, 0.15 + 0.85*(xi + 0.5)/tape_n_x);
        // Straight full-U transit (forming exit -> plow mouth via pipe)
        for (ti=[0:n_t-1])
            fold_section(tx0 + ti*dx_t, dx_t, 1);
    }
}

// Full-U cross-section sweep over X-span [x0, x0+dx+eps] at depth
// scale sc (sc=1 full-U, sc<1 shallow forming). Per side s: arc
// (n facets) from the ribbon top at [s*hw, base_top] sweeping
// outward-up, vertical wall, shoulder kink (outward+slightly up) then
// foot back down onto the ribbon wing at [s*(hw+r+2.5), base_top].
module fold_section(x0, dx, sc) {
    hw = fold_width/2;                 // 2.0 trough bottom half-width
    r = tape_bend_radius;              // 1.5
    a = tape_fold_angle;               // 90 = vertical walls (full U)
    sh_r = tape_shoulder_r;            // 1.5 reverse S-kink radius
    base_top = tape_thick;             // 0.4: ribbon top (trough floor, single layer)
    for (s=[-1,1]) {
        // arc facets
        for (i=[0:tape_n_arc-1]) {
            t0 = -90 + i*a/tape_n_arc;
            t1 = -90 + (i+1)*a/tape_n_arc;
            p0 = [s*(hw + r*cos(t0)), base_top + (r + r*sin(t0))*sc];
            p1 = [s*(hw + r*cos(t1)), base_top + (r + r*sin(t1))*sc];
            seg_ribbon_taper(x0, dx, p0, p1);
        }
        te = a - 90;  // arc end angle (0 = vertical tangent)
        pa = [s*(hw + r*cos(te)), base_top + (r + r*sin(te))*sc];
        wd = [-s*sin(te), cos(te)];  // tangent dir at arc end
        pb = [pa[0] + wd[0]*tape_fold_wall*sc, pa[1] + wd[1]*tape_fold_wall*sc];
        seg_ribbon_taper(x0, dx, pa, pb);
        // reverse S-shoulder: kink outward+up, then foot down to wing
        pk = [pb[0] + s*sh_r*0.9, pb[1] + sh_r*0.5*sc];
        pf = [s*(hw + r + 2.5), base_top];
        seg_ribbon_taper(x0, dx, pb, pk);
        seg_ribbon_taper(x0, dx, pk, pf);
    }
}

// Tapered ribbon segment between 2D path points p0/p1 ([y,z]), X-span
// [x0, x0+dx+eps overlap], centered on the path (thickness tape_thick).
module seg_ribbon_taper(x0, dx, p0, p1) {
    dy = p1[0] - p0[0];
    dz = p1[1] - p0[1];
    seg = sqrt(dy*dy + dz*dz);
    if (seg > 0) {
        translate([x0 + dx/2, (p0[0]+p1[0])/2, (p0[1]+p1[1])/2])
            rotate([atan2(dz, dy), 0, 0])
                cube([dx + 2*epsilon, seg + 2*epsilon, tape_thick], center=true);
    }
}

// Legacy fixed-length ribbon segment (kept: allowed-module helper,
// unused by the tapered bend but harmless).
module seg_ribbon(fx0, p0, p1) {
    dy = p1[0] - p0[0];
    dz = p1[1] - p0[1];
    seg = sqrt(dy*dy + dz*dz);
    if (seg > 0) {
        translate([fx0 + plow_len/2, (p0[0]+p1[0])/2, (p0[1]+p1[1])/2])
            rotate([atan2(dz, dy), 0, 0])
                cube([plow_len, seg + 2*epsilon, tape_thick], center=true);
    }
}

// Stainless former collar (v28 visual, v31 at the forming exit):
// transverse shoe with a U notch straddling the full-U section at the
// forming exit (world x ~67, 5+ clear of the drum face). Two feet ride
// the flat wings + top bridge clears the pocket; the notch (inner width
// fold_width+2*tol, depth wall+r) forms the paper around the trough.
// Visual in assembly only (not a separate print export).
module former_collar() {
    shoe_w = 30;          // across-tape (covers 25.4 wings)
    shoe_t = 3;           // along-tape thickness
    foot_w = (shoe_w - (fold_width + 2*tolerance))/2;
    notch_d = tape_fold_wall + tape_bend_radius + 1.0;
    bridge_t = 2.0;
    difference() {
        union() {
            // feet on the wings
            translate([-shoe_t/2, -shoe_w/2, 0]) cube([shoe_t, foot_w, notch_d]);
            translate([-shoe_t/2, shoe_w/2 - foot_w, 0]) cube([shoe_t, foot_w, notch_d]);
            // top bridge
            translate([-shoe_t/2, -shoe_w/2, notch_d]) cube([shoe_t, shoe_w, bridge_t]);
        }
        // U notch (open bottom): trough pocket clearance
        translate([-shoe_t/2 - epsilon, -(fold_width + 2*tolerance)/2, -epsilon])
            cube([shoe_t + 2*epsilon, fold_width + 2*tolerance, notch_d + epsilon]);
    }
}

// ============================================================
// 8. Diamond-knurled pull roller (two helical notch families ±30°)
// ============================================================
module knurled_roller(is_lower=true) {
    len = roller_len;
    dia = roller_dia;
    gear_thick = 6;
    // v21: lower roller prints gear-DOWN (hub points down, away from body) so
    // the viewer mount ([0,0,34.95]/Rx180) lands the gear on the BACK plane
    // (world Y~12, same as the v20 drum gear). Shaft bottom sits at Z=0, so
    // the lower stack needs a taller lift (19.95 vs 11).
    zoffset = is_lower ? 19.95 : 0; // v27 printable: upper was 11 (floated 11mm, min_z=11); 0 puts body/caps/collars on base min_z=0. Lower keeps 19.95 (gear-down stack bottoms at 0).

    if (part_to_render == "rollers") {
        // VERTICAL orientation for STL export (base at Z=0)
        translate([0,0,zoffset])
        union() {
            difference() {
                cylinder(h=len, d=dia, center=false);
                // Diamond knurl: two families of helical notches, left+right rotated ±30°
                for (dir=[-1,1])
                    for (k=[0:15]) {
                        t = k/15;
                        zpos = 3 + t*24;
                        ang = dir * k * 18.75;
                        rotate([0,0,ang])
                            translate([dia/2 - 0.6, 0, zpos])
                                rotate([dir*30, 0, 0])
                                    cube([1.4, 2.2, 3.2], center=true);
                    }
                if (is_lower) {
                    cylinder(h=len+2*epsilon, r=hex_clearance_r, $fn=6, center=false);
                } else {
                    cylinder(h=len+2*epsilon, d=axle_clearance_dia, center=false);
                }
            }
            if (is_lower) {
                // Lower: driven gear BELOW body (exact mirror of the old
                // gear-up stack about the body mid-plane z=len/2): hub points
                // down/away, collar fuses up into the body, shaft hangs below.
                translate([0,0, -(gear_thick/2 - epsilon)])
                    rotate([180,0,0])
                        spur_gear(teeth=roller_teeth, module_mm=gear_module, thickness=gear_thick,
                                  bore_flat=hex_axle_flat, is_hex=true,
                                  hub_dia=16, hub_len=10, collar_dia=14, collar_len=3);
                translate([0,0, len - (len + gear_thick - epsilon) - 14])
                    cylinder(h=14, r=hex_axle_r, $fn=6, center=false);
                translate([0,0, len - (len + gear_thick - epsilon - 1) - 1.2])
                    cylinder(h=1.2, r=6, center=false);
                translate([0,0, len - (len + gear_thick + 4) - 3])
                    difference() {
                        cylinder(h=3, d=12, center=false);
                        cylinder(h=3 + 2*epsilon, r=hex_clearance_r, $fn=6, center=false);
                    }
            } else {
                // Upper: idler, simple end caps
                for (cz=[0.15, len - 3.15])
                    translate([0,0, cz])
                        difference() {
                            cylinder(h=3, d=22, center=false);
                            cylinder(h=3 + 2*epsilon, d=axle_clearance_dia, center=false);
                        }
            }
            // Lower end cap mirrored to the TOP (gear now occupies the bottom).
            if (is_lower)
                translate([0,0, len - 3.15])
                    difference() {
                        cylinder(h=3, d=22, center=false);
                        cylinder(h=3 + 2*epsilon, r=hex_clearance_r, $fn=6, center=false);
                    }
            // Shaft shoulder collars (centered on body mid-height; outer
            // translate([0,0,zoffset]) adds the print-base lift, so no zoffset here)
            for (ce=[-1,1])
                translate([0, 0, len/2 + ce*(len/2 - 1.65)])
                    difference() {
                            cylinder(h=3, d=22, center=true);
                            if (is_lower)
                                cylinder(h=3 + 2*epsilon, r=hex_clearance_r, $fn=6, center=true);
                            else
                                cylinder(h=3 + 2*epsilon, d=axle_clearance_dia, center=true);
                        }
        }
    } else {
        // HORIZONTAL for assembly preview
        translate([0, 0, dia/2]) {
            difference() {
                rotate([90,0,0])
                    cylinder(h=len, d=dia, center=true);
                // Diamond knurl (horizontal)
                for (dir=[-1,1])
                    for (k=[0:15]) {
                        t = k/15;
                        ypos = -12 + t*24;
                        ang = dir * k * 18.75;
                        rotate([0, ang, 0])
                            translate([0, ypos, dia/2 - 0.6])
                                rotate([0, 0, dir*30])
                                    cube([2.2, 3.2, 1.4], center=true);
                    }
                if (is_lower) {
                    rotate([90,0,0])
                        cylinder(h=len+2*epsilon, r=hex_clearance_r, $fn=6, center=true);
                } else {
                    rotate([90,0,0])
                        cylinder(h=len+2*epsilon, d=axle_clearance_dia, center=true);
                }
            }
            if (is_lower) {
                // v23: gear stays on BACK side (-Y, world Y~12, same plane as
                // drum gear). Shaft moved to the BACK too (outboard of the gear,
                // toward the crank now outside the back wall at Y=-8): hex shaft
                // tip at -(len/2+gear_thick-epsilon)-14 meets the gear outer face,
                // passing through the gear hex bore into the body. Mirrors the
                // vertical export stack (shaft below gear). Front (+Y) has no shaft.
                translate([0, -(len/2 + gear_thick/2 - epsilon), 0])
                    rotate([-90,0,0])
                        spur_gear(teeth=roller_teeth, module_mm=gear_module, thickness=gear_thick,
                                  bore_flat=hex_axle_flat, is_hex=true,
                                  hub_dia=16, hub_len=10, collar_dia=14, collar_len=3);
                translate([0, -(len/2 + gear_thick - epsilon) - 14, 0])
                    rotate([-90,0,0])
                        cylinder(h=14, r=hex_axle_r, $fn=6, center=false);
                translate([0, -(len/2 + gear_thick - epsilon) - 1.2, 0])
                    rotate([-90,0,0])
                        cylinder(h=1.2, r=6, center=false);
                translate([0, -(len/2 + gear_thick + 4) - 3, 0])
                    rotate([-90,0,0])
                        difference() {
                            cylinder(h=3, d=12, center=false);
                            cylinder(h=3 + 2*epsilon, r=hex_clearance_r, $fn=6, center=false);
                        }
            }
            collar_ends = is_lower ? [-1] : [-1, 1];
            for (ce=collar_ends)
                translate([0, ce*(len/2 - 1.65), 0])
                    rotate([90,0,0])
                        difference() {
                            cylinder(h=3, d=22, center=true);
                            if (is_lower)
                                cylinder(h=3 + 2*epsilon, r=hex_clearance_r, $fn=6, center=true);
                            else
                                cylinder(h=3 + 2*epsilon, d=axle_clearance_dia, center=true);
                        }
        }
    }
}

module pull_rollers() {
    knurled_roller(is_lower=true);
    translate([40, 0, 0]) knurled_roller(is_lower=false);
}

// ============================================================
// v37 Thread-bind + vertical pull + wind-up (v36 MVP backfill).
// Allowed modules only; $fn=60 inherited; tol=0.3 clearances.
// - thread_twister(): rotor CENTRED at origin, axis along X: outer
//   guide ring (axisymmetric, so viewer spin about X looks right) +
//   hub + exactly 2 arms (180 apart) + thread bobbins at the tips.
//   Folded tape (outer 7.8) threads the ring bore (r 10-2=8).
//   Export branch lifts +twister_lift for min_z=0; assembly spins
//   it about X at [bind_x, 30, twister_axle_z] by twister_angle.
// - vpull_roller(): ONE vertical-axis nip roller, base at z=0
//   (body d20 h24 + caps/collar, min_z=0 in export AND assembly):
//   pair stands on the base flanking the finished folded tape at
//   [pull_x, 30 +/- vpull_off], spins about Z (1:1 with main
//   roller, same dia => same surface speed => spacing preserved).
// - takeup_reel(): wind-up reel built along Z for flat printing
//   (bottom flange 0..3 + core r5 0..31 + top flange 28..31,
//   min_z=0); assembly recentres, tilts to axle-Y, spins about
//   the axle by takeup_angle (4 rev per $t = same linear tape).
// ============================================================
module thread_twister() {
    assert(twister_arms == 2, "thread_twister: must carry exactly 2 arms");
    union() {
        // Outer guide ring in the YZ plane (axis X): rotate_extrude
        // ring about Z then tilt so its axis lies along X.
        rotate([0, 90, 0])
            rotate_extrude(convexity=10)
                translate([twister_ring_r, 0, 0])
                    square([twister_ring_tube*2, twister_ring_tube*2], center=true);
        // Hub along X
        rotate([0, 90, 0])
            cylinder(h=8, r=3, center=true);
        // 2 arms + thread bobbins (180 apart, fused hub->ring)
        for (k=[0:twister_arms-1])
            rotate([k*180, 0, 0]) {
                translate([0, (twister_ring_r+3)/2, 0])
                    cube([4, twister_ring_r - 1, 3], center=true);
                translate([0, twister_ring_r - 1, 0])
                    rotate([0, 90, 0])
                        cylinder(h=6, r=3, center=true);
            }
    }
}

module vpull_roller() {
    assert(vpull_sleeve_r <= 10.3, "vpull_roller: cushion sleeve must stay ~d20 (1:1)");
    difference() {
      union() {
        cylinder(h=vpull_h, r=vpull_r, center=false);
        // v39 CUSHIONED nip (soft rubber/silicone sleeve visual over the
        // steel core: firm grip without crushing the seed pocket; viewer
        // paints it dark rubber). OD stays ~d20 (sleeve proud 0.15, caps
        // r11 still dominate the envelope) => 1:1 surface speed kept.
        translate([0, 0, (vpull_h - vpull_sleeve_h)/2])
            cylinder(h=vpull_sleeve_h, r=vpull_sleeve_r, center=false);
        // Cushion grip ribs (shallow visual rings on the sleeve)
        for (k=[0:5])
            translate([0, 0, (vpull_h - vpull_sleeve_h)/2 + 2 + k*(vpull_sleeve_h - 4)/5])
                difference() {
                    cylinder(h=0.8, r=vpull_sleeve_r + 0.3, center=false);
                    translate([0, 0, -epsilon])
                        cylinder(h=0.8 + 2*epsilon, r=vpull_sleeve_r - 0.2, center=false);
                }
        // Diamond knurl band (visual grip, shallow so OD stays ~20)
        for (k=[0:11]) {
            t = k/11;
            zpos = 4 + t*(vpull_h - 8);
            rotate([0, 0, k*30])
                translate([vpull_r - 0.5, 0, zpos])
                    cube([1.2, 2.0, 2.6], center=true);
        }
        translate([0, 0, vpull_h])
            difference() {
                cylinder(h=3, d=22, center=false);
                translate([0, 0, -epsilon])
                    cylinder(h=3 + 2*epsilon, d=axle_clearance_dia, center=false);
            }
        translate([0, 0, vpull_h/2])
            difference() {
                cylinder(h=3, d=22, center=true);
                translate([0, 0, 0])
                    cylinder(h=3 + 2*epsilon, d=axle_clearance_dia, center=true);
            }
      }
      // Axle bore through body + caps
      translate([0, 0, -epsilon])
          cylinder(h=vpull_h + 3 + 2*epsilon, d=axle_clearance_dia, center=false);
    }
}

module takeup_reel() {
    assert(clutch_disc_r < takeup_flange_r, "takeup_reel: clutch must stay inside flange envelope");
    difference() {
        union() {
            cylinder(h=takeup_flange_t, r=takeup_flange_r, center=false);
            cylinder(h=takeup_core_h + takeup_flange_t, r=takeup_core_r, center=false);
            translate([0, 0, takeup_core_h])
                cylinder(h=takeup_flange_t, r=takeup_flange_r, center=false);
            // Wound-tape pack visual (finished tape coils on the core)
            translate([0, 0, takeup_flange_t])
                cylinder(h=takeup_core_h - takeup_flange_t, r=takeup_core_r + 3, center=false);
            // v40 SLIP CLUTCH on the axle (visual clutch discs 31..41):
            // pressure disc + friction disc (the slip interface: fast when
            // the reel is empty, slips when full as the pack diameter
            // grows) + spring + hex nut. Discs r8 < flange r16 so the
            // station X envelope (210..242) is unchanged; the geared base
            // ratio stays takeup_angle = -1440*$t (2x crank, sense reversed), the clutch
            // absorbs the diameter change mechanically (see viewer comment
            // + GEAR_RATIO.md; animation keeps the geared base speed).
            translate([0, 0, takeup_core_h + takeup_flange_t])
                cylinder(h=clutch_disc_t, r=clutch_disc_r, center=false);
            translate([0, 0, takeup_core_h + takeup_flange_t + clutch_disc_t])
                cylinder(h=clutch_disc_t, r=clutch_disc_r, center=false);
            translate([0, 0, takeup_core_h + takeup_flange_t + 2*clutch_disc_t])
                cylinder(h=clutch_spring_h, r=4.5, center=false);
            translate([0, 0, takeup_core_h + takeup_flange_t + 2*clutch_disc_t + clutch_spring_h])
                cylinder(h=clutch_nut_h, r=5, $fn=6, center=false);
        }
        // Axle bore through the whole reel + clutch
        translate([0, 0, -epsilon])
            cylinder(h=takeup_h_total + 2*epsilon, d=axle_clearance_dia, center=false);
    }
}

// ============================================================
// 9. Crank assembly — proper hand crank with hub boss, tapered arm (hull),
//     counterweight stub, free-spinning grip parallel to shaft axis.
//     Grip center traces circle of radius crank_throw about shaft axis.
// ============================================================
module crank_assembly() {
    arm_w = crank_arm_w;
    arm_t = crank_arm_t;
    pivot_x = crank_pivot_x;
    pivot_z = crank_pivot_z;
    handle_x = pivot_x + crank_throw;
    s = crank_side; // v23: -1 = arm/grip extend -Y outward from the back wall (was +1 front)
    arm_yc = s * arm_w/2;
    grip_y0 = s * arm_w;
    grip_y1 = grip_y0 + s * grip_len;
    grip_yc = (grip_y0 + grip_y1)/2;

    difference() {
        union() {
            // Tapered arm via hull(boss, end)
            hull() {
                translate([pivot_x - 11, arm_yc, 0])
                    cylinder(h=arm_t, r=7, center=false);
                translate([pivot_x, arm_yc, 0])
                    cylinder(h=arm_t, r=9, center=false);
                translate([handle_x, arm_yc, 0])
                    cylinder(h=arm_t, r=6, center=false);
            }
            // Counterweight stub opposite handle
            translate([pivot_x - 5, -arm_yc, 0])
                cylinder(h=arm_t, r=5, center=false);
            // Hub boss around shaft
            translate([pivot_x, arm_yc, pivot_z])
                rotate([90,0,0])
                    cylinder(h=16, r=7, center=true);
            // Pivot hex shaft
            translate([pivot_x, arm_yc, pivot_z])
                rotate([90,0,0])
                    cylinder(h=hex_shaft_len, r=hex_axle_r, $fn=6, center=true);
            // Handle riser
            translate([handle_x, arm_yc, 0])
                cylinder(h=pivot_z + 5.5, r=5.5, center=false);
            // Grip (free-spinning, tapered, parallel to shaft axis Y)
            hull() {
                translate([handle_x, grip_y0 + s*3, pivot_z])
                    rotate([90,0,0])
                        cylinder(h=10, d=grip_dia, center=true);
                translate([handle_x, grip_yc, pivot_z])
                    rotate([90,0,0])
                        cylinder(h=12, d=grip_dia - 2, center=true);
                translate([handle_x, grip_y1 - s*3, pivot_z])
                    rotate([90,0,0])
                        cylinder(h=10, d=grip_dia - 4, center=true);
            }
            // Grip sphere end caps
            translate([handle_x, grip_y0, pivot_z])
                sphere(r=grip_dia/2, $fn=24);
            translate([handle_x, grip_y1, pivot_z])
                sphere(r=(grip_dia - 4)/2, $fn=24);
        }
        // Lightening hole
        translate([pivot_x + crank_throw/2, arm_yc, -epsilon])
            cylinder(h=arm_t + 2*epsilon, d=6, center=false);
    }
}

// ============================================================
// Animated assembly
// Sign convention (v23: crank drives the ROLLER shaft from the back wall side):
//   drum_angle = -360*$t ANTI-CLOCKWISE about +Y (top surface moves -X/left,
//   viewed +X right, +Z up): picks up RIGHT, carries over top, drops bottom-center
//   roller_angle = +720*$t + gear_mesh_phase CLOCKWISE (driven by drum via
//   40:20 mesh, 2:1; +9° half-pitch so the pinion tooth falls into the drum gap)
//   crank = roller_angle (rigid on the roller shaft, coaxial at roller_axle_x)
//   upper idler = -720*$t (counter-rotates via tape contact)
//   v43 TRUE-MESHED exterior train (all module 2, dist=r1+r2
//   asserted): crank->drum 2:1 interior (40:20, dist 60, phase 9°);
//   drum takeoff D2-20T -> L1a-12T/L1b-36T compound -> L2-10T twister
//   pinion = 6x drum (even flips, sign kept); crank takeoff E0-12T ->
//   8-idler 12T chain -> PC-12T pull layshaft = 1:1 (even flips, sign
//   kept); L1b-36T -> GT-15T -> GJ-15T -> GS-15T reel gear = 2x crank
//   (odd flips, winding sense reversed vs v42). External mesh flips
//   direction each mesh - signs above follow the flip count.
//   pull nip pair spins about Z at +/-roller_angle (same d20 dia as
//   main roller => 1:1 surface speed, the spacing driver; cushioned
//   rubber/silicone sleeve grips firm without crushing); takeup_angle
//   = -1440*$t about the reel axle (core d10 step-up winds the same
//   125.66mm linear tape; slip clutch on the axle slips when full).
//   v40 mounts: BOTTOM = 6-turner + wind-up reel; SIDE = twister ring +
//   pull rollers + drum (axles through the chassis walls); TOP =
//   hopper+shroud + tape input spools.
// At $t=0 geometry equals static layout (plus the 9° mesh phase on the roller).
// ============================================================
module animated_assembly() {
    drum_angle = -360*$t;    // ANTI-CLOCKWISE about +Y
    crank_angle = 720*$t;    // lower roller + crank orbit (CW, opposite drum)
    idler_angle = -720*$t;   // upper idler counter-rotates
    roller_angle = crank_angle + gear_mesh_phase; // mesh-phased roller shaft
    twister_angle = -360*$t*twister_orbits_per_drum; // v37: 6 orbits/drum rev about X
    pull_a_angle = roller_angle;   // v37: nip side A with the roller shaft
    pull_b_angle = -roller_angle;  // v37: nip side B counter-rotates
    takeup_angle = -1440*$t;       // v43: reel gear GS-15T ends odd-flipped vs the drum (-2 = 2x crank, sense reversed vs v42; winds the same 125.66mm linear tape)

    // Chassis
    chassis();

    // Spool cones
    translate([spool_axle_x, wall_thick+1, spool_axle_z])
        rotate([-90,0,0]) single_cone();
    translate([spool_axle_x, chassis_width-wall_thick-1, spool_axle_z])
        rotate([90,0,0]) single_cone();

    // Drum
    translate([drum_axle_x, chassis_width/2, drum_axle_z])
        rotate([0, drum_angle, 0])
            translate([0, 0, -drum_dia/2])
                seed_cartridge(seed_dia, seed_depth);

    // Hopper (v34 OD10: ONE printed piece — right wedge pickup level
    // top z=73, open-top half-pipe 16mm/8mm cover 11->6 with grooves,
    // 2 side joints, closed box, bottom-center hover pipe ID6/OD10 L10
    // at drum x hovering 10 above the lowered lane)
    translate([drum_axle_x, chassis_width/2, drum_axle_z - hopper_axis_z])
        hopper_body();

    // Tape cover shroud (v22: enclosed tunnel WEST of drum, roller nip
    // -> drum exit, world x 58..84). Local frame x 0..len, y centred 0.
    // v24 verified R->L: hopper(~128) > drum(100) > shroud(~71) > roller(40);
    // wall 2.0>=1.2, min_z=0, spool(-6) clears r22 gear (X gap 1.5).
    translate([shroud_x0, chassis_width/2, 0])
        u_channel_shroud();

    // Seed cradle
    translate([plow_start, chassis_width/2 - 12.7, base_thick])
        seed_cradle();

    // Seed tape with center U-fold (v34 OD10: narrow 4 trough,
    // R1.5, 5.5 walls, S-shoulders; v31: forming 37..70 fully west of
    // the drum face + straight full-U transit 70..126 under the drum
    // (13.6 air gap) UNDER the hover pipe (10 gap) to the plow mouth;
    // static in CAD, scrolls in the viewer; single-layer floor, min_z=0).
    translate([tape_x0, chassis_width/2, tape_z])
        seed_tape_bend();

    // Former collar (v28 visual, v31 at the forming exit): stainless
    // transverse shoe with U notch straddling the full-U section at the
    // forming exit (world x ~67, clear of the wheel).
    translate([fold_end - 3, chassis_width/2, tape_z + tape_thick])
        former_collar();

    // Folding plow (v39 REPLACED by the 6-turner/roller former: the
    // seeded tape rolls through the 6 curl east of the drop, world x
    // 126..159, v1-precedent footprint kept; seed lands flat at 100
    // first, then the curl rolls the edges over)
    translate([plow_start, chassis_width/2 - 20, base_thick])
        six_turner();

    // Pull rollers (zoffset=11 compensated in assembly)
    translate([roller_axle_x, chassis_width/2, roller_axle_z])
        rotate([0, roller_angle, 0])
            translate([0, 0, -roller_dia/2])
                knurled_roller(is_lower=true);
    translate([roller_axle_x, chassis_width/2, roller_axle_z + roller_dia + 1.2])
        rotate([0, idler_angle, 0])
            translate([0, 0, -roller_dia/2])
                knurled_roller(is_lower=false);

    // Crank drives the ROLLER shaft (v23): coaxial at roller_axle_x=40 outside
    // the BACK wall (Y=crank_mount_y=-8, grip mirrored -Y), rigid with the lower
    // roller (grip orbits r=crank_throw about the roller axis at [40,-8,60]).
    translate([crank_mount_x, crank_mount_y, roller_axle_z])
        rotate([0, roller_angle, 0])
            translate([-crank_pivot_x, 0, -crank_pivot_z])
                crank_assembly();

    // v37 Thread twister (2 arms orbit the tape axis just east of the
    // plow, binding each seed into the folded pocket; geared 6 orbits
    // per drum rev = one bind per cavity).
    translate([bind_x, chassis_width/2, twister_axle_z])
        rotate([twister_angle, 0, 0])
            thread_twister();

    // v37 Vertical-nip pull pair (spacing driver), v39 CUSHIONED:
    // two vertical-axis rollers stand on the base flanking the finished
    // folded tape at pull_x (side-mounted: top bridge from the chassis
    // walls caps the axles), pinching the closed pocket and pulling it
    // at the same surface speed as the main roller (1:1 d20, spacing
    // preserved). Soft rubber/silicone sleeve grips without crushing.
    translate([pull_x, chassis_width/2 - vpull_off, base_thick])
        rotate([0, 0, pull_a_angle])
            vpull_roller();
    translate([pull_x, chassis_width/2 + vpull_off, base_thick])
        rotate([0, 0, pull_b_angle])
            vpull_roller();

    // v37 Take-up spool (wind-up reel east, BOTTOM mounted), v40 SLIP
    // CLUTCH: reel built along Z is recentred, tilted to axle-Y, spun
    // about its axle by takeup_angle (core d10 step-up winds the same
    // linear tape the pull nip delivers; clutch discs slip when full).
    translate([takeup_x, chassis_width/2, takeup_z])
        rotate([90, 0, 0])
            rotate([0, 0, takeup_angle])
                translate([0, 0, -takeup_h_total/2])
                    takeup_reel();
}

module assemble_all() {
    animated_assembly();
}

// ============================================================
// Diagnostics + part selection (fail-loud else)
// ============================================================
echo(str("v14 MVP: cavities=", num_divots, " roller_dia=", roller_dia,
         " gears=", roller_teeth, "/", drum_teeth,
         " tape/drum_rev(via roller)=", tape_per_drum_rev_roller,
         " spacing(6 cav)=", achieved_spacing,
         " target_spacing=", target_spacing));
echo(str("GEAR CALC: spacing = PI * roller_dia * (drum_teeth/roller_teeth) / cavities = ",
         PI * roller_dia * (drum_teeth / roller_teeth) / num_divots,
         "mm; target 152.4 (6 inch) needs future swap-gears (see GEAR_RATIO.md)."));
if (num_divots == 6) {
    echo(str("NOTE: v14 MVP fixed 6 cavities; wheels interchangeable by hand 1-6mm (cavity size varies, count stays 6)."));
}

if (part_to_render == "all") {
    assemble_all();
} else if (part_to_render == "chassis") {
    chassis();
} else if (part_to_render == "hopper") {
    // v33 printable: standalone export drops to print base min_z=0
    // (local hover-pipe bottom 19.4 -> 0; was 19.9/25.9/26.5);
    // assembly branch above unaffected.
    translate([0, 0, -19.4]) hopper_body();
} else if (part_to_render == "shroud") {
    u_channel_shroud();
} else if (part_to_render == "cartridge") {
    seed_cartridge(seed_dia, seed_depth);
} else if (part_to_render == "cones") {
    spool_cones();
} else if (part_to_render == "plow" || part_to_render == "turner") {
    six_turner(); // v39: "plow" kept as compat alias, "turner" is the clean name (same 6-turner GLB)
} else if (part_to_render == "tape") {
    seed_tape_bend();
} else if (part_to_render == "rollers") {
    pull_rollers();
} else if (part_to_render == "twister") {
    // Rotor centred at origin; lift to print base (min_z=0).
    translate([0, 0, twister_lift]) thread_twister();
} else if (part_to_render == "pull_a") {
    vpull_roller(); // base at z=0 already
} else if (part_to_render == "pull_b") {
    vpull_roller(); // base at z=0 already
} else if (part_to_render == "takeup") {
    takeup_reel(); // built along Z, base at z=0 already
} else if (part_to_render == "crank") {
    crank_assembly();
} else {
    echo(str("ERROR: unknown part_to_render='", part_to_render, "'."));
    cube([1,1,1]);
}
