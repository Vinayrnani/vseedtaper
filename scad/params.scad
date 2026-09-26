/*
    Modular Hand-Cranked Seed Tape Machine - v2 Authoritative Spec
    ===========================================================
    v81: crank at x=160 (20T FRONT-plane gear meshes drum 40T, 2:1),
         28mm hex shaft at front, spur_gear in crank,
         rollers removed (upper deleted, lower replaced by crank axle).
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
$fn            = 60;

// ============================================================
// Kinematics / derived parameters (v2)
// ============================================================
gear_module   = 2;
roller_teeth  = 20;
drum_teeth    = 40;
center_distance = (roller_teeth + drum_teeth) * gear_module / 2; // 60
gear_thick    = 6;           // shared spur-gear face thickness (drum/crank)

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
//   drum (100) > spool (-6, far west).
// Gear mesh: crank(160) 20T -> drum(100) 40T, dist=60=center_distance,
//   crank rotates 2:1 vs drum (crank_angle = 2*drum_angle).
//   Drum gear on FRONT plane (y≈47.95) for crank mesh.
// Plow stays EAST of drum (126->159, v1 precedent); tape scroll unchanged.
// v79: rollers REMOVED; crank carries the 20T pinion at x=160, front wall.
// ============================================================
drum_axle_x  = 100;
drum_axle_z  = 75;   // v87 +15 lift: ≥ drum_radius + base_thick + clearance = 29.3 ✓ (was 60)
assert(drum_axle_z == 75, "drum_axle_z must be 75 (+15 lift) — feeds hopper assembly +15");
crank_axle_x = 160;  // Step 13 fresh station: crank at the r60 mesh circle east of drum
crank_axle_z = 75;  // Step 13 fresh station: crank level with drum
assert(abs(sqrt(pow(crank_axle_x - drum_axle_x,2)+pow(crank_axle_z - drum_axle_z,2)) - center_distance) < 0.05,
       str("v95: crank must sit exactly on the r60 mesh circle about the drum, got ",
           sqrt(pow(crank_axle_x-drum_axle_x,2)+pow(crank_axle_z-drum_axle_z,2))));
// v97 composite take-off (user: revert gears, keep ONE composite 10->30 on
// the crank-gear wall): crank20(m2) -> A10(m2) [-2x, Y] +
// fused A30(m1.25) takeoff companion at the fresh Step 13 station.
A_ang = -15.5;  // Step 13 fresh station: A down-east of crank
v97_A_cd = (roller_teeth + 10) * gear_module / 2 + 0.75; // 30.75: crank20 -> A10 m2
v97_Ax = 189.702219;  // Step 13 fresh station
v97_Az = 67.041314;  // Step 13 fresh station
v97_A_y0 = 49.5; v97_A_y1 = 83;      // shaft r4 (stub cut; crosses outboard wall, tip ~2 proud)
v97_A10_y0 = 49; v97_A10_y1 = 55; // A10 m2 6 wide (Step 8: matches crank gear face 49-55)
v97_A30_y0 = 70; v97_A30_y1 = 75;     // A30 m1.25 30T OUTSIDE the wall (Step 2; B10 follows in Step 3)
A_rev = -2; // composite spins -2x crank (external mesh flips)
// v115 rim mitre (user: twister rim OD, same teeth both sides, 45°/45°):
// 36T m1.25 both (pitch r22.5, outer r23.75 ≈ disc OD46). Shared apex FIRST.
tw_apex_x = 155; tw_apex_z = 32;   // source apex before the rigid twister frame
twister_frame_cx = 182.75; twister_frame_cy = 34; twister_frame_cz = 32;  // explicit 180Y frame center
twister_reflect_x = 2 * twister_frame_cx;  // rotor reflection datum: x' = 365.5 - x
twister_axle_x_shift = 6;  // axle-only east correction; rotor datum remains unchanged
twister_axle_reflect_x = twister_reflect_x + twister_axle_x_shift;  // final axle reflection datum: x' = 371.5 - x
twister_support_rib_x0 = 195; twister_support_rib_x1 = 201;  // axle support follows +6mm axle shift
twister_support_m3_x = [196.5, 199.5];  // axle support M3 stations follow +6mm axle shift
// Step-3a source-frame fused Γ support: final world X = 371.5 - source X.
twister_support_x0 = 169; twister_support_x1 = 175;
twister_support_wall_y0 = 3; twister_support_wall_y1 = 34;
twister_support_wall_z0 = 29; twister_support_wall_z1 = 35;
twister_support_floor_y0 = 31; twister_support_floor_y1 = 37;
twister_support_floor_z0 = 4; twister_support_floor_z1 = 32;
twister_support_wall_pilot_d = 2.5; twister_support_floor_pilot_d = 2.5;
twister_support_wall_pilot_y0 = 3; twister_support_wall_pilot_y1 = 13;
twister_support_floor_pilot_z0 = 4; twister_support_floor_pilot_z1 = 10;
twister_support_anchor_source_x = [172, 172];  // wall + floor local M3 anchors
twister_support_anchor_count = len(twister_support_anchor_source_x);
twister_support_wall_anchor_z = 32; twister_support_floor_anchor_y = 34;
twister_support_final_x0 = twister_axle_reflect_x - twister_support_x1;
twister_support_final_x1 = twister_axle_reflect_x - twister_support_x0;
twister_support_wall_anchor_final_x = twister_axle_reflect_x - twister_support_anchor_source_x[0];
twister_support_floor_anchor_final_x = twister_axle_reflect_x - twister_support_anchor_source_x[1];
twister_support_legacy_m3_z = 7;  // retired Step-13 interface, intentionally unused
tw_axle_foot_x0 = 166;  // west edge of the fused printable axle foot
tw_axle_support_x1_reflected = twister_axle_reflect_x - tw_axle_foot_x0;
tw_apex_x_frame = twister_reflect_x - tw_apex_x;  // 210.5 final twister apex
tw_bev_n = 36;                     // same count both sides (true mitre 36/36, 45°/45°)
tw_bev_mod = 1.25;                 // module (rim size)
tw_bev_face = 4;                   // face along generator (toe r19.67 solid over the bore)
tw_bev_thin = 0.9;                 // twister tangential thin (backlash)
v113_B_thin = 0.8;                 // B tangential thin (backlash; v95 pinion-thinning precedent)
tw_bev_phase = 0; v113_B_phase = 5; // tooth-into-gap (half-pitch of 36T): B teeth mesh twister gullets
v113_B_heel_y = 56.5;              // B heel pitch circle (apex 34 + r22.5 @45°)
tw_bev_heel_x = 177.5;             // source twister heel pitch circle
 tw_bev_heel_x_frame = 2 * twister_frame_cx - tw_bev_heel_x; // 188 final frame heel
tw_relief_x0 = 177.7; tw_relief_x1 = 179.5; // back-cone relief annulus (trims heel backs like real bevels, catches B heel corner)
tw_relief_r0 = 20; tw_relief_r1 = 23;
// B station: Y-axis THROUGH the apex (mate-driven, off the A circle).
// B10 stays in the A30 band (idle; next-step intermediate meshes it).
v98_Bx = tw_apex_x_frame; v98_Bz = tw_apex_z;  // Step 13 B/apex station (210.5, 32)
v98_B_y0 = 54; v98_B_y1 = 80;      // shaft r4 (v117: inboard stub cut into the bevel band; tip 2 deep in the gearwall slip bore)
v98_B10_y0 = 70; v98_B10_y1 = 75;  // B10 m1.25 kept (idle for the next step)
// Step 5 outboard support wall (user: extra wall outside carrying the A/B
// shaft tips): plate y78-81 over both axes + four canonical 6x6 supports
// face-touching the removable south wall at y68 and fusing into the plate.
bolt_dia = 3;
bolt_head_across = 5.5;
nut_trap_depth = 2.5;
v105_wall_x0 = 132; v105_wall_x1 = 234; // extended plate X span
v105_wall_z0 = 20;  v105_wall_z1 = 93;  // plate Z span, extended 6mm downward
v105_wall_y0 = 78;  v105_wall_y1 = 81;  // plate Y span
v105_pillar_xz = [[137, 32], [137, 88], [217, 88], [229, 32]];
v105_pillar_y0 = 68; v105_pillar_y1 = 80; // face-touch south wall, fuse into plate
v105_pillar_s = 6; v105_pillar_half = v105_pillar_s/2;
v105_pillar_corner_r = v105_pillar_half * sqrt(2);
v105_pillar_screw_d = bolt_dia + 2*tolerance;
v105_pillar_nut_r = (bolt_head_across + 2*tolerance) / sqrt(3);
v105_nut_trap_floor = 78.45; // v105_wall_y1 - (nut_trap_depth + epsilon)

// Live B bevel support: standard 36T teeth remain unchanged and hang from
// the full-radius Step 4 backing web; the web is behind the nominal heel
// plane and overlaps the root frustum without extending into the toe/mesh.
v98_Bbev_y0 = 52.5; v98_Bbev_y1 = 57.5; // v115 Bbev36 teeth envelope (toe 53.7, heel 56.5 + tip drift; apex-down mitre)
// Step 4 live B backing web: full radius behind the nominal heel plane,
// with a 0.3mm overlap into the existing root frustum.
B_back_web_r = 24;
B_back_web_t = 3;
B_back_web_z0 = 19.3;
B_back_web_z1 = 22.3;
B_root_frustum_z0 = 22;
B_root_frustum_z1 = 25.3;
B_root_frustum_r0 = 21;
B_root_frustum_r1 = 18.2;
B_back_web_y0 = v98_B_y0 + 25 - B_back_web_z1; // assembly Y=56.7
B_back_web_y1 = v98_B_y0 + 25 - B_back_web_z0; // assembly Y=59.7
// Legacy v103/v106 helper parameters remain only for the unused dt_bevel_blank helper.
v106_bev_web_top = 63.5; // legacy helper datum
v106_bev_lift = v106_bev_web_top + 6 - v98_B_y0; // legacy helper datum
v103_bev_flange_r = 10;  // legacy helper only
v103_bev_flange_t = 2;   // legacy helper only
B_rev = -6; // idler-driven train: A -2x, two flips, B -6x crank
twister_rev = -6; // 1:1 mitre preserves B's -6x direction, intentionally reversed twister
// v116 Step-2 idler (user: connect A and B with an intermediate gear):
// 15T m1.25 spur bridging A30 (r18.75) and B10 (r6.25) in the shared band
// 70-75. Two-circle solve: |I-A| = 18.75+9.375+0.75 = 28.875,
// |I-B| = 6.25+9.375+0.75 = 16.375 -> west solution (east hits twister).
// Idler is idler: B = -A.(30/10) = -6x regardless of idler size.
v115_Ix = 211.695428; v115_Iz = 48.331307; // Step 13 fresh idler station
v115_I_y0 = 66; v115_I_y1 = 80;    // shaft r4 (front-wall bore + gearwall bore, tip 2 deep)
v115_I15_y0 = 70; v115_I15_y1 = 75; // idler 15T band (meshes A30 + B10 bands)
v115_I_phase = 12;                 // half-pitch tooth-into-gap (thin teeth + visual verify)
v115_I_thin = 0.8;                 // idler thin (mesh forgiveness; v95 precedent)
I_rev = 4; // idler spins +4x crank (-A.30/15)
spool_axle_x  = -6;  // v22: 10->-6, clears roller back gear (box-level X gap 1.5)
spool_axle_z  = 80;  // v87 +15 lift: 120mm max roll OD, height 80mm above base (was 65)
assert(spool_axle_z == 80, "cone rod (spool_axle_z) must be 80 (+15 lift)");

// ============================================================
// Chassis
// ============================================================
chassis_x0    = -34; // Step 3: west edge X=-34
chassis_len   = 334; // Step 3: length 334 mm, east edge X=300 (+30 mm at east/take-up end)
chassis_width = 68;
lane_y = chassis_width / 2;  // lane center, was hardcoded 30
chassis_height = 125;  // v87 +15: > max(spool top=105, drum top=117) + 5 = 122 ✓ (was 110)
base_thick    = 4;
wall_thick    = 3;

// ============================================================
// Plow (downstream closer, v1 precedent: stays EAST of drum) +
// Fold zone (v31: forming station fully WEST of the drum face so the
// tall U walls never meet the wheel; shallow entry at the roller nip,
// full-U forming exit at x=70, then a straight full-U transit (same
// cross-section, no taper) runs EAST, UNDER
// the drum with air gap, INTO the drop-tube west side inlet at x=93,
// through the bore (seed drops into the moving pocket at x=100) and
// on to the plow mouth at 126 which closes/seals it downstream)
// ============================================================
plow_start    = drum_axle_x + drum_radius + 1; // 126 (east of drum, unchanged)
plow_len      = 33; // v79 FIXED: decoupled from old roller_axle_x.
                     // Plow stays east (v1 precedent).
plow_end      = plow_start + plow_len; // 159
// Step 6: the old U-bend at the roller nip is RETIRED. The flat 25.4 ribbon
// now runs on, and the U is folded exactly once by the new u_former part
// (former_x0..former_x1) far downstream, UNDER the dropper. fold_start,
// fold_end and fold_len are gone: the straight full-U transit is measured
// from the real, self-supporting end of the fold instead of a retired station.
// transit_start / transit_end / transit_len live in the Step 6 block below:
// they are measured from u_stable_end_x, and OpenSCAD evaluates assignments in
// file order, so that station must already exist when they are read.
// (S4) fold_width, tape_bend_radius, tape_fold_angle, tape_fold_wall,
// tape_shoulder_r/ang and tape_n_arc/tape_n_x described that RETIRED fold and
// had no readers left; they are gone with it. The U-former sizes itself from
// the u_* constants below.
track_depth   = 3;

// ============================================================
// Rollers
// ============================================================
roller_len    = 30;
axle_dia      = 8; // 8
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
drum_shaft_y1 = 67;   // hidden in the front drum-block bore
takeup_shaft_y0 = 1;  // hidden in the back wall/block bore (wall 0..3)
takeup_shaft_y1 = 67; // hidden in the front take-up block bore
spool_shaft_y0 = 1;    // hidden in the back spool-block bore
spool_shaft_y1 = 67;   // hidden in the front spool-block bore
// Step 1 flat floor + Step 2 wall-local M3 interface. Both walls carry
// matching clearance holes/nut traps; no bosses or pilot holes occupy the floor.
wall_screw_x = [chassis_x0 + 20, chassis_x0 + chassis_len - 20];
wall_screw_z = 8;
wall_screw_clearance_d = bolt_dia + 2*tolerance;
wall_screw_nut_r = (bolt_head_across + 2*tolerance) / sqrt(3);
south_wall_bore_y = chassis_width - wall_thick/2;
// Step 1 plow underside screw interface.
plow_base_screw_x = plow_start + 6; // world x=132
plow_base_screw_y = 9; // world y=9, inboard of fixed wall inner face y=3

// Bearing block dimensions
bb_len = 14;
bb_wall = 4;
bb_height_roller = 13;
bb_height_drum   = 13;
bb_height_spool  = 10;

// ============================================================
// Hopper (v14 MVP: closed seed box at 9 o'clock, max volume to 10:30;
// horizontal top z=73)
// ============================================================
hopper_wall     = 2.5;
hopper_flange_thick = 3;
hopper_clearance = 0.3;
hopper_inner_r  = drum_radius + hopper_clearance; // 25.3
hopper_outer_r  = hopper_inner_r + seed_dia + 3;  // 30.8
hopper_axis_z   = 56;  // v87 +15 lift: frozen local axis (assembly Z = drum_axle_z - 56 = base_thick + 15; was drum_axle_z - base_thick which tracked and broke body frame)
wiper_slot      = 1.2;
groove_w        = 7;     // inner-face groove width, matches drum cavity track (fits 6mm cavities d6.6)
groove_d        = 0.7;   // v27 printable: 0.8 left only 1.175 wall (<1.2); 0.7 leaves ~1.275, still clears cavity protrusion 0.6
// Step12: drum flange register (female) grooves — hopper ONLY (shroud removed).
// Drum end flanges OD53 r26.5, 1.5 wide at local Y +/-5 (world 29/39).
// Recess EXPLICIT oversize (not tolerance-derived): r26.65 + w1.8.
flange_reg_r = 26.8; // recess radius (flange r26.5 + 0.3 print clearance)
flange_reg_w = 2.1;   // recess width (flange 1.5 + 0.6 oversize)
flange_reg_y = 5;     // groove centre offset local Y +/-5
assert(flange_reg_r - (drum_dia + 3)/2 >= 0.2 && flange_reg_r - (drum_dia + 3)/2 <= 0.4, str("Step12: flange register radial clearance must be in [0.2,0.4] (0.3 print): ", flange_reg_r - (drum_dia + 3)/2));
assert(flange_reg_w - 1.5 >= 0.2, str("Step12: flange register width oversize must be >=0.2: ", flange_reg_w - 1.5));

// ============================================================
// Step 5: U guide / hopper-mounted M2 interface
// ============================================================
// Shared M2 hardware is an intentional exception to the general tol=0.3
// machine clearance.  Keep the values named so every local module can fail
// loudly if a later edit changes a screw seat or span.
m2_nominal_dia       = 2;
m2_clearance_dia     = 2.4;
m2_head_dia          = 3.8;
m2_head_h            = 2;
m2_nut_af            = 4.0;
m2_nut_corner_dia    = 4.32;
m2_nut_h             = 1.6;
m2_trap_af           = 4.4;
m2_trap_depth        = 1.7;
m2_screw_len         = 8;
m2_min_surrounding   = 1;
m2_screw1_axis       = [0, 1, 0];
m2_screw2_axis       = [1, 0, 0];
hopper_export_rebase = 10.5;
guide_export_rebase  = 7;
bracket_export_rebase = 10.5;
export_rebases       = [hopper_export_rebase, guide_export_rebase, bracket_export_rebase];

// Approved guide frame and solids, in hopper-local coordinates.
guide_assembly_t     = [100, 34, 19];
guide_pipe_od        = 11.4; // Step 6: widened for the ~3mm-seed pipe
guide_x0             = -5;
guide_x1             = 5;
guide_y0             = -15.2;
guide_y1             = 15.2;
guide_floor_z0       = 7;
guide_floor_z1       = 8.7;
guide_rail_y0        = 7.7; // Step 6: rail inner face follows the wider pipe OD
guide_rail_y1        = 9.7; // Step 6: 2mm rail, 2mm gap to the pipe
guide_rail_z0        = 9.7;
guide_rail_z1        = 21.4;
guide_bridge_y0      = 7.7; // Step 6: follows the wider pipe OD
guide_bridge_y1      = 15.2;
guide_bridge_z0      = 9.7;
guide_bridge_z1      = 10.4;
guide_foot_y0        = 13;
guide_foot_y1        = 15.2;
guide_foot_z0        = 8.6;
guide_foot_z1        = 9.8;
guide_pad_x          = 3.7;
guide_pad_y0         = 7.7; // Step 6: follows the wider pipe OD
guide_pad_y1         = 11;
guide_pad_z0         = 11.3;
guide_pad_z1         = 18.7;
guide_screw1_x       = 0;
guide_screw1_z       = 15;
guide_screw1_y0      = 6.95;
guide_screw1_y1      = 11.05;
guide_trap_y0        = 9.3;
guide_trap_y1        = 11;

// ============================================================
// Crank (v79: at x=160, 20T gear meshes drum 40T at dist=60)
// Crank carries a 20T spur gear at the FRONT plane that meshes
// the drum's 40T gear. v102: 58mm hex shaft runs from the arm boss
// through the front-wall hex hole and full through the crank-gear
// hex bore (positive drive, 3-point support). Handle stands 20 off
// the front wall (arm inner face world y88 vs wall outer 68).
// grip orbit r=crank_throw=45, $fn=60, tol=0.3 all kept.
// ============================================================
crank_throw     = 45;
crank_mount_x   = crank_axle_x; // v79: 160: meshes drum 40T at dist 60 (was drum_axle_x=100)
crank_mount_y   = chassis_width + 8; // v79: 76: outside FRONT wall (68)
gear_local_y    = -24;       // crank gear local y; world y = crank_mount_y + gear_local_y = 52 (front, spans 49..55)
crank_side      = +1; // v79: grip/arm extend +Y outward front
crank_arm_t     = 4;
crank_arm_w     = 10;
grip_len        = 30;
grip_dia        = 16;
crank_pivot_x   = crank_arm_w / 2; // 5
crank_pivot_z   = crank_arm_t + hex_axle_r - 0.15; // ~8.47
hex_shaft_len   = 58;          // v102: 28+30 — arm boss, wall hole, full through gear bore
crank_arm_gap   = 12;          // v102: arm inner face 20 clear of front-wall outer (was 8)

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
// (S4) The retired fold's own dimensions - fold_width, tape_bend_radius,
// tape_fold_angle, tape_fold_wall, tape_shoulder_r/ang, tape_n_arc/tape_n_x -
// are DELETED: the v34 trough/R1.5/S-kink section they described no longer
// exists. The U of Step 6 is defined only by the u_* block below
// (u_flat_z, u_side_h, the developed-width identity) - nothing here sizes it.
// Assembly: static tape (viewer scrolls it); export standalone min_z=0.
// ============================================================
tape_thick       = 0.4;
tape_x0          = -14;   // Step10 DECOUPLED from chassis_x0 (was =chassis_x0): ribbon start fixed at spool approach; chassis west extends to -34 without dragging tape/dip. tape_len stays 234
// v45 WIND-UP LEADER (forensic fix: the flat ribbon used to run UNDER the
// bare reel core with a ~13 gap and dangle past the reel while the viewer
// scroll slid it +/-63 per rev). Now the flat ribbon ENDS at tape_flat_end
// (220: east of the nip caps 217, west of the reel flange 258) and a narrow
// leader strip (finished folded-tube width 8) climbs from the ribbon top onto
// the wound pack (pack r8 on core r5 at (274,50)), ending at (272.5,42.5)
// inside the pack silhouette.
tape_flat_end    = 220;
tape_len         = tape_flat_end - tape_x0;   // 234 (was 222: shifted +12 with stations)
leader_x0        = 218;   // leader start (2 overlap onto the flat ribbon)
leader_x1        = 272.5; // Step 4: leader endpoint inside the pack silhouette
leader_z1        = 42.5;  // Step 4: leader endpoint inside the pack silhouette
leader_w         = 8;     // leader width (finished folded tube, not full 25.4)
tape_z           = 28;           // v87 +15 lift: transit top 36.4, ribbon top 28.4

// Derived hopper-local references used by the fail-loud interface checks.
guide_tape_z0_local  = tape_z - (drum_axle_z - hopper_axis_z);
guide_tape_z1_local  = guide_tape_z0_local + tape_thick;
guide_pipe_z0_local  = guide_tape_z1_local + 10;
// ============================================================
// Step 6: dropper pipe, the new U under the dropper, its former,
// the guide cap that keeps the seeds in, and the 6-turner handoff.
// The old near-roller bend is gone (see the fold-station block
// above): the flat 25.4 ribbon is folded ONCE here, in the shadow
// of the dropper, then handed to the 6-turner already U-shaped.
// hopper_body() in scad/feed.scad no longer declares its own pipe locals:
// it reads the globals below directly and asserts drop_pipe_od == 11.4, so
// there is nothing shadowing them any more. entry_flare_leg is still the
// feed-side 0.6 lead-in leg; mouth_flare_leg is 0 (plain 1.2 joint ring).
// ============================================================
// --- Dropper pipe: widened so a ~3mm seed passes straight through ---
drop_pipe_id      = 9.0;   // was 7.6: a real ~3mm seed must clear the bore
drop_pipe_od      = 11.4;  // was 10
pipe_bore_r       = 4.5;   // was 3.8: == drop_pipe_id/2
pipe_wall         = 1.2;   // thinnest printable wall, unchanged by design
pipe_od_bottom_z  = 19.4;  // lower OD surface of the pipe (hopper-local z)
entry_flare_leg   = 0.6;   // bore exit 45deg lead-in leg (still >=0.6)
mouth_flare_leg   = 0;     // Step 6: joint ring is a plain 5.7-4.5 = 1.2 wall
                           // (no break leg); the only lead-in left is entry_flare_leg

// --- The new U under the dropper (hopper-local frame) ---
u_flat_z            = 9.2;   // U floor datum (u_centerline_top_z - u_side_h)
u_centerline_bottom_w = 10.4; // flat bottom centreline width (Y +-5.2)
u_side_h            = 7.5;   // vertical wall length from the flat datum
u_centerline_top_z  = 16.7;  // centreline top of the finished U
u_outer_top_z       = 16.9;  // outside top surface of the U walls
// THE REAL SECTION WIDTH. The paper is 25.4 wide and u_side_h of it rises on
// each side, so the floor's outer half width is what is left over; every
// builder (u_former_bar / u_former_wall) reads THIS, never a declared width.
u_floor_outer_w     = paper_width/2 - u_side_h;   // 5.2 (== u_centerline_bottom_w/2)
u_inner_w           = u_centerline_bottom_w - tape_thick; // 10.0  NOMINAL (see note)
u_outer_w           = u_centerline_bottom_w + tape_thick; // 10.8  NOMINAL (see note)
// NOMINAL ONLY: u_inner_w / u_outer_w describe the folded U on paper, but no
// geometry reads them - the formed section is built from u_floor_outer_w and
// u_shape(). Do NOT add an assert that treats them as the built width; assert
// the derived width instead (u_floor_outer_w, below). They are kept only as
// the paper's own nominal figures; the six-turner clearance is no longer
// quoted on them (the old throat check was false - see the EXIT fit check
// further down).
u_flat_end_x        = 81;    // flat sheet ends, fold starts
u_full_x            = 91;    // fold complete, full-depth U
u_stable_end_x      = 114;   // U stable + self-supporting (transit start)

// --- The seed packet roll (the round roll the tape becomes at the turner) ---
// Three sizes, three DIFFERENT owners - do not confuse them:
//   seed_dia_max   the seed itself. Real garden seeds are ~3mm; the old
//                  "8mm seeds" prose (and the 7.6 bore it justified) was
//                  WRONG and is gone.
//   seed_bore_d    the bore of the rolled packet. It is set by the PAPER -
//                  25.4mm of tape rolled up - and NOT by the seed. The user
//                  set the 6-turner EXIT to Ø8.5 ("around 7.5 / 8.5"); the
//                  EXIT is now Ø8.6, still inside that ask, so the packet
//                  must be smaller on radius: outer 7.9 inside an 8.6 throat.
//                  seed_bore_d 7.1 = that 7.9 outer minus one
//                  0.4 paper thickness. DO NOT try to shrink the packet to
//                  chase a smaller seed: the paper, not the seed, sizes it.
//   seed_passage_d the passage the packet travels through - the dropper
//                  bore, which must be at least as big as the packet.
// The EXIT of the six-turner is sized by the TAPE (a closed roll is 7.9
// across the outside), so it must stay >= 7.9 in diameter; that is why
// turner_exit_clear_r below is 4.30 (Ø8.6), not the 1.575 (Ø3.15) the old
// 6.5 taper produced, and why the scroll_sheet taper opens to
// scroll_clear_r(1) = 4.325 (see the scroll_* block further down).
seed_dia_max   = 3.0;         // user-confirmed real seed size
seed_bore_d    = 7.1;         // rolled packet bore
seed_passage_d = 9.0;         // == drop_pipe_id
roll_x0        = 100;         // drop point (seeds fall into the open U)
roll_x1        = 114;         // turner mouth
packet_bore_r  = seed_bore_d/2;                 // 3.55
packet_outer_r = packet_bore_r + tape_thick;    // 3.95  (Ø7.9)
// THE WRAP IS DERIVED, NEVER A HARDCODED 360.
// The 25.4mm strip turns about its own MEAN radius (the centreline radius
// of the paper in the roll), so the wrap it needs is paper_width divided by
// that mean radius:
//   packet_mean_r   = packet_bore_r + tape_thick/2 = 3.55 + 0.2 = 3.75
//   packet_wrap_rad = 25.4 / 3.75 = 6.7733 rad = 388.07 deg
// 388 > 360 by 28.07 deg: the strip laps 28.07 deg (1.84mm) OVER ITS OWN
// START. That overwrap IS the lap - there is no separate "leftover straight
// lap": the leftover after one 2*PI turn (25.4 - 2*PI*3.75 = 1.838) is
// exactly the paper that carries the overwrap, so packet_lap_len is 0 by
// construction and is asserted as such below. This is WHY the old
// packet_wrap_deg = 360 was wrong: a bare 360 at r 3.75 consumes only
// 23.56 of the 25.4 strip and leaves a 1.84mm open slit down the packet.
packet_mean_r   = packet_bore_r + tape_thick/2;          // 3.75
packet_wrap_rad = paper_width / packet_mean_r;           // 6.7733 (388.07 deg)
packet_wrap_deg = packet_wrap_rad * 180/PI;             // derived, never 360
packet_wrap_overlap_deg = packet_wrap_deg - 360;        // 28.07: the lap
packet_lap_len  = paper_width - packet_wrap_rad*packet_mean_r; // 0
// The packet rides on the SAME floor datum as the U it comes out of: its
// axis sits at packet_outer_r = 3.95 above the ribbon base, so the closed
// tube occupies exactly the U's own 7.9mm z envelope (0..7.9) and the morph
// has no vertical step at either end of the roll. See the assert on
// 2*packet_outer_r == u_side_h + tape_thick below.
packet_centre_z = packet_outer_r;                        // 3.95
// --- Morph resolution: 48 cross-section segments, 24 x-stations ----------
// 48 segments is fixed so P_U and P_TUBE are point-for-point lerp-able.
// 24 x-stations over the 14mm roll (100..114) gives 0.5833mm stations.
// The BITE is the overlap each box takes out of its neighbours along the
// cross-section. It is 0.10, NOT 0.02: at 0.02 a slightly bent (morphed) wall
// segment overlapped its neighbour almost coplanarly, the 20:1 sliver could not
// be fused reliably, and the union shed zero-thickness 2-face flakes at the
// first roll station (7 of them). 0.10 is ~19% of a 0.53mm segment - still a
// slight overlap, but a real volume to fuse. It costs 0.003 of packet corner
// radius, which is asserted against the 6-turner throat below.
// The X bite is the same idea along the roll. 0.20 is deliberate margin, not
// a flake fix: the cap stagger below shears a station by 0.047, and 0.20 keeps
// every pair of neighbouring stations overlapping in x by >= m_dx - 0.047.
packet_poly_seg      = 48;
packet_roll_stations = 24;
packet_seg_bite      = 0.10;  // cross-section overlap of neighbouring boxes
packet_x_bite        = 0.20;  // x overlap of neighbouring roll stations
// THE CAP STAGGER - the fix for the last zero-area flake, and the reason the
// roll reads watertight out of the STL. Every box in a station bites
// packet_seg_bite past its neighbour, so at any one end plane the 48 end-cap
// quads OVERLAP each other while sitting in the SAME plane. That coplanar
// overlap is the single boundary OpenSCAD's triangulation cannot resolve: it
// emits a zero-area triangle, and trimesh then reports the whole tape as
// "not watertight" even though OpenSCAD says manifold/NoError. Sweeping both
// cap planes by 0.001 per box (0.047 over the 48) removes the coplanarity and
// the flake with it - verified by isolation: 48 boxes, stagger 0 -> 1 flake,
// stagger 0.0005 -> 0 flakes. 0.047 of end raggedness is far below one
// printer layer, and the run still overlaps its neighbour station in x by at
// least m_dx - 47*0.001, so the chain is never in doubt.
packet_cap_stagger  = 0.001; // per-box x offset of the two cap planes
// The U centreline polyline: down the -Y wall, along the floor, up the +Y
// wall. 48 segments are split 14 / 20 / 14 so that BOTH corners fall exactly
// on a sample point - a uniform arclength split would straddle them and
// bevel the miter off by up to half a station.
u_poly_seg_wall  = 14;
u_poly_seg_floor = 20;
u_wall_cl_y   = u_centerline_bottom_w/2 - tape_thick/2;  // 5.0 wall centreline
u_floor_cl_z  = tape_thick/2;                            // 0.2 floor centreline
u_leg_cl_len  = u_side_h;                                // 7.5
u_floor_cl_len = u_centerline_bottom_w - tape_thick;     // 10.0
u_centreline_len = 2*u_leg_cl_len + u_floor_cl_len;      // 25.0 (see assert)

// --- Guide: rail gap to the widened pipe (named, asserted) ---
guide_pipe_gap   = 2.0;       // rail/bridge inner face to pipe OD

// --- Straight full-U transit, measured from the real fold stations ---
transit_start = u_stable_end_x;  // 114: fold complete, U stable and self-supporting
transit_end   = plow_start;      // 126: transit ends at the plow mouth
transit_len   = transit_end - transit_start; // 12: stable U -> plow mouth (via pipe)

// --- Guide cap: fused into u_guide(), holds the seeds in the pipe ---
guide_cap_x0        = -5;     // spans the existing guide x-envelope
guide_cap_x1        = 5;
guide_cap_y         = 7.9;    // 0.2 overlap onto the rail (never coplanar)
guide_cap_z0        = 17.8;   // 0.9 above the U top, 0.4 below the pipe OD
guide_cap_z1        = 19.0;
guide_cap_hole_d    = 9.2;    // seed passage, must pass the pipe bore
guide_cap_hole_x    = 0;

// --- New U-former part (u_former): forms the U, straddles the guide rail ---
former_x0  = 81;    // matches u_flat_end_x
former_x1  = 91;    // matches u_full_x
former_work_gap  = 0.15;  // work gap to the forming ribbon
former_capture_gap = 2.0; // relaxed capture gap past former_x1
former_capture_x0 = 89;   // == former_x1 - 2
former_ear_x0  = -14.1;   // ear into the widened bracket pad
former_ear_x1  = -8.3;
former_ear_y0  = 9.4;
former_ear_y1  = 11.0;
former_ear_z0  = 10.9;   // widened from 11.2: pad z span 10.9..18.1 (7.2 tall)
former_ear_z1  = 18.1;   // so the M2 hex corner wall reaches 1.0mm (was 0.76)

// --- M2 screws for the former (the guide keeps m2_screw_len = 8) ---
former_screw_len       = 6;    // head 2 + 0.9 + trap 1.7 + 1.4 thread = 6.0
former_screw_x         = -11.2;
former_screw_z         = 14.5;
former_screw_y_head    = 9.4;  // head seats here, shaft runs +Y
former_head_relief_d   = 4.2;  // head pocket, > m2_head_dia 3.8
former_screw_y_trap0   = 12.3; // hex trap
former_screw_y_trap1   = 14.0;
former_screw_y_tip     = 15.4; // head seat + former_screw_len

// --- Bracket pad: the former's M2 mounting pad, REAL MATERIAL in
// u_guide_bracket() (Step 6 B1). 6.6 square, widened from -13.7..-8.7 so the
// 4.4 AF nut trap cut into it (Step 6 B2) keeps m2_min_surrounding = 1.0 of
// pad across its flats (4.4 + 2*1.0 = 6.4 minimum, 6.6 built). The Z span is
// 10.9..18.1 (7.2 tall, deliberately widened from the old 11.2..17.8 = 6.6):
// across the hex's CORNERS the pad must also keep 1.0 of wall, and
// (z1-z0)/2 - (4.4/sqrt(3)) was only 0.76 at 6.6 tall - 1.06 now, and the
// whole point is that it clears the 1.0 FDM floor the assert in
// u_guide_bracket() holds it to. former_screw_z 14.5 is still EXACTLY the
// midpoint of the new span ((10.9+18.1)/2 = 14.5), so widening it moved no
// screw. The trap is centred on the pad: X centre (x0+x1)/2 = -11.2 =
// former_screw_x, Z centre (z0+z1)/2 = 14.5 = former_screw_z.
// pusher_pad_y1 = 14.0 (was 16.0) so the trap follows the Step 5 pattern
// EXACTLY: the hex is open at the pad's outer face and m2_trap_depth deep
// INTO it, i.e. former_screw_y_trap1 == pusher_pad_y1, with 1.3 of closed
// floor below it. A trap buried inside a 5mm pad (12.3..14.0 inside 11..16)
// would be an enclosed void: two shells instead of one and no way to get
// the nut in. The die ear seats on pusher_pad_y0.
pusher_pad_x0 = -14.5;
pusher_pad_x1 = -7.9;
pusher_pad_y0 = 11.0;   // == former_ear_y1: the die ear seats on this face
pusher_pad_y1 = 14.0;   // == former_screw_y_trap1: the trap opens here
pusher_pad_z0 = 10.9;   // == former_ear_z0
pusher_pad_z1 = 18.1;   // == former_ear_z1

// --- 6-turner handoff: the U arrives already formed ---
turner_axis_z       = 32;   // six_turner bore-axis height
turner_mouth_clear_r = 12;  // MOUTH clear radius: sheet wrap radius at 0 turns
turner_exit_clear_r  = 4.30;// EXIT clear radius (Ø8.6): the packet's own throat
                           // The user asked for "around 7.5 / 8.5"; the real
                           // exit bore is Ø8.6, still inside that ask - it has
                           // to be, because the fit is measured from the
                           // TURNER's axis and the packet axis sits 0.05 below
                           // it (packet_exit_ecc below). 4.30 keeps a full
                           // 0.3 gap on the radius; the old 4.25 (Ø8.5) left
                           // only 0.2375, under the 0.3 working clearance.
                           // - was 11.2 (turner_inner_r) which was really the
                           // mouth's inner face, not the exit; the old taper
                           // closed the exit down to 1.575 (Ø3.15), impassable
                           // - was 4.6 (Ø9.2), before the user set the exit to
                           // Ø8.5 to match the real rolled packet
u_center_world_z = 31.95; // U centre height in the assembly frame
// The packet's AXIS, in the assembly frame, is tape_z + packet_centre_z =
// 28 + 3.95 = 31.95. packet_centre_z is deliberately the U's own half
// envelope, so the packet seats inside the U's 0..7.9 box and the morph has
// no vertical step - but that leaves it 0.05 BELOW turner_axis_z (32, pinned
// to twister_axle_z and unable to move). Every exit fit must therefore be
// measured from the TURNER's axis: the true worst corner is
// 3.9625 (built packet) + 0.05, not the nominal 3.95.
packet_exit_ecc = abs(turner_axis_z - (tape_z + packet_centre_z));  // 0.05

// --- scroll_sheet()'s taper: the ONE number that opens the EXIT ------------
// These are the exact numbers the plow-side scroll_sheet() reads, so the
// taper cannot drift from the clearance it is sized for:
//   scroll_base_r(t) = 12 - scroll_exit_taper*t      (mouth r 12 -> exit 8.25)
//   spiral offset    = scroll_spiral_pitch * turns(t) * t
//   turns(t)         = 0.5 + 0.75*t                 (mouth U -> exit 1.25)
//   scroll_clear_r(t)= base_r(t) - spiral offset - thickness/2
//   scroll_clear_r(1)= 8.25 - 2.5*1.25 - 0.8 = 4.325  >= exit pin 4.30
// Solving for the taper X: r_clear(1) = 8.075 - X, so X = 8.075 - 4.30 =
// 3.775 would be the bare minimum; 3.75 is built, leaving 0.025 of margin.
// 4.325 is the mouth-side face of the exit; the packet's own axis is 0.05
// below the turner axis (packet_exit_ecc), so the real gap is
// 4.325 - 3.9625 - 0.05 = 0.3125 - a full 0.3 with the facet to spare.
scroll_base_r0      = 12;    // entry wrap radius (the 24mm U mouth)
scroll_exit_taper   = 3.75;  // X in base_r(t) = 12 - X*t
scroll_spiral_pitch = 2.5;   // radial loss per full turn of the spiral
scroll_entry_turns  = 0.5;   // mouth wrap (the U half-pipe)
scroll_exit_turns   = 1.25;  // exit wrap (1.0 + 0.25 overlap)
function scroll_turns(t)   = scroll_entry_turns + (scroll_exit_turns - scroll_entry_turns)*t;
function scroll_base_r(t)  = scroll_base_r0 - scroll_exit_taper*t;
function scroll_clear_r(t) = scroll_base_r(t) - scroll_spiral_pitch*scroll_turns(t)*t - thickness/2;
// The stations the packet fit is sampled at - the whole turner is checked,
// not just its exit.
packet_exit_check_t = [0, 0.25, 0.5, 0.75, 1];
function scroll_clear_r_min() = min([for (t = packet_exit_check_t) scroll_clear_r(t)]);

// --- Step 6 fail-loud checks (5 Laws: Fail Loud) ---
assert(abs((drop_pipe_od - drop_pipe_id)/2 - pipe_wall) < 0.001
    && pipe_wall == 1.2,
    str("Step 6: dropper pipe wall must stay 1.2: got ", (drop_pipe_od - drop_pipe_id)/2));
assert(pipe_bore_r == drop_pipe_id/2,
    str("Step 6: pipe bore radius must equal the pipe ID/2: ", pipe_bore_r));
assert(abs(pipe_od_bottom_z - guide_pipe_z0_local) < 0.001,
    str("Step 6: pipe OD bottom must stay at the local 19.4 datum: ", pipe_od_bottom_z));
assert(entry_flare_leg >= 0.6,
    str("Step 6: bore exit lead-in leg must stay >=0.6: ", entry_flare_leg));
assert(mouth_flare_leg == 0,
    str("Step 6: the joint ring is a plain wall - no mouth break leg: ", mouth_flare_leg));
// LENGTH CONSERVATION (S1): the sheet is 25.4 wide; the formed U keeps every
// millimetre of it - u_side_h rises on each side and what is left over is the
// floor, u_floor_outer_w on EACH side. Nothing is stretched, nothing is lost.
// (u_floor_outer_w is a HALF width - the same one the builders read from
// paper_width/2 - so the identity is half + one rise == half the sheet.)
assert(abs(u_floor_outer_w + u_side_h - paper_width/2) < 0.001,
    str("Step 6: the developed width must be conserved: floor half ", u_floor_outer_w,
        " + u_side_h ", u_side_h, " != half of paper_width ", paper_width/2));
assert(abs(u_floor_outer_w - u_centerline_bottom_w/2) < 0.001,
    str("Step 6: the derived floor half width must match the 10.4 centreline: ",
        u_floor_outer_w, " vs ", u_centerline_bottom_w/2));
assert(abs(u_centerline_top_z - (u_flat_z + u_side_h)) < 0.001,
    str("Step 6: U centreline top must be the flat datum plus u_side_h: ", u_centerline_top_z));
// The U outer top sits half a paper thickness above the centreline top: the
// wall CENTRELINE runs u_flat_z + u_side_h, its outer face half a thickness
// above that (u_former_wall builds h = u_side_h*u + tape_thick/2 + clearance).
assert(abs(u_outer_top_z - (u_flat_z + u_side_h + tape_thick/2)) < 0.001,
    str("Step 6: U outer top must be half a paper thickness above the centreline top: ",
        u_outer_top_z));
// Tie the NOMINAL widths to the derived geometry, so they cannot drift apart
// (see the NOMINAL note above - they are not what the builders read).
assert(abs(u_outer_w - (2*u_floor_outer_w + tape_thick)) < 0.001
    && abs(u_inner_w - (2*u_floor_outer_w - tape_thick)) < 0.001,
    str("Step 6: the nominal U widths must track the derived floor width: ",
        u_inner_w, "/", u_outer_w));
assert(u_flat_end_x == former_x0 && u_full_x == former_x1 && former_x1 > former_x0,
    str("Step 6: former span must match the fold span 81..91: ", former_x0, "..", former_x1));
assert(u_stable_end_x > u_full_x && u_stable_end_x < transit_end,
    str("Step 6: the U must be stable before the plow mouth: ", u_stable_end_x));
// --- Seed packet roll: the three sizes, and where each one must fit ---
assert(seed_dia <= seed_dia_max,
    str("Step 6: seed_dia must be <= seed_dia_max: ", seed_dia, " > ", seed_dia_max));
assert(packet_bore_r >= seed_dia_max/2 + tolerance,
    str("Step 6: the packet bore must pass the biggest seed with a tolerance gap: need >= ",
        seed_dia_max/2 + tolerance, " got ", packet_bore_r));
assert(seed_passage_d == drop_pipe_id,
    str("Step 6: the seed passage must equal the dropper bore: ", seed_passage_d,
        " vs ", drop_pipe_id));
assert(roll_x0 > u_full_x, "roll must start after the U is complete");
assert(roll_x1 == 114, "roll must finish at the turner mouth");
assert(roll_x0 < roll_x1 && roll_x1 == u_stable_end_x && roll_x1 == transit_start,
    str("Step 6: the roll must run from the drop to the turner mouth: ", roll_x0, "..", roll_x1));
assert(packet_wrap_rad > 2*PI,
    str("Step 6: the derived wrap must exceed a full turn (the packet genuinely closes): ",
        packet_wrap_deg, " deg got ", packet_wrap_rad, " rad vs ", 2*PI));
assert(packet_wrap_overlap_deg > 15,
    str("Step 6: the strip must lap its own start by a real overlap, not 0 deg: ",
        packet_wrap_overlap_deg));
// The straight-lap term is 0 BY CONSTRUCTION (the wrap is derived from the
// paper), and that is the point: the leftover after one 2*PI turn IS the
// overwrap. A nonzero leftover would mean the polyline needs a tangent lap.
assert(abs(packet_lap_len) < 0.001,
    str("Step 6: the straight lap must be absorbed by the derived overwrap: ",
        packet_lap_len));
// The wrap is measured on the MEAN radius of the paper in the roll, never on
// the bore - quoting 360 on the bore radius is what produced a slit packet.
assert(abs(packet_wrap_rad*packet_mean_r - paper_width) < 0.001,
    str("Step 6: the derived wrap must consume exactly the 25.4 strip: ",
        packet_wrap_rad*packet_mean_r, " vs ", paper_width));
assert(abs(packet_mean_r - (packet_bore_r + tape_thick/2)) < 0.001,
    str("Step 6: the wrap must be measured on the paper's MEAN radius: ",
        packet_mean_r));
// The closed packet occupies EXACTLY the U's own z envelope, so the morph has
// no vertical step at either end of the roll and the packet cannot climb
// into the drum.
assert(abs(2*packet_centre_z - (u_side_h + tape_thick)) < 0.001,
    str("Step 6: the packet must sit in the U's own z envelope: 2*",
        packet_centre_z, " = ", 2*packet_centre_z, " vs U height ",
        u_side_h + tape_thick));
// The polyline sample split must add up to the fixed 48 segments, and the U
// centreline must be the paper minus at most one corner mitre.
assert(u_poly_seg_wall*2 + u_poly_seg_floor == packet_poly_seg,
    str("Step 6: the U polyline split must total the fixed segment count: ",
        u_poly_seg_wall*2 + u_poly_seg_floor, " vs ", packet_poly_seg));
assert(abs(u_centreline_len - paper_width) <= tape_thick + 0.001,
    str("Step 6: the U centreline must be the 25.4 strip less one corner mitre: ",
        u_centreline_len, " vs ", paper_width));
// The MEASURED ENVELOPE, read off the actual sampled polyline (this is the
// same measurement the x=120 cross-section probe reports): every sample is a
// CENTRELINE point, so all of them must sit on the mean circle, and the bore
// / outer the built boxes produce is that circle less / plus half a thickness.
assert(abs(packet_poly_env_r_max() - packet_mean_r) < 0.001
    && abs(packet_poly_env_r_min() - packet_mean_r) < 0.001,
    str("Step 6: every packet sample must sit on the mean circle ", packet_mean_r,
        ": got ", packet_poly_env_r_min(), "..", packet_poly_env_r_max()));
assert(abs((packet_poly_env_r_min() - tape_thick/2) - packet_bore_r) < 0.001
    && abs((packet_poly_env_r_max() + tape_thick/2) - packet_outer_r) < 0.001,
    str("Step 6: the sampled packet must measure Ø", 2*packet_bore_r, "/",
        2*packet_outer_r, ": got Ø", 2*(packet_poly_env_r_min() - tape_thick/2),
        "/", 2*(packet_poly_env_r_max() + tape_thick/2)));
// And it must be the same packet at EVERY point of the roll, not just at
// x=114: the morph is monotone in u and the envelope follows u.
// NOTE - packet_exit_ecc is DELIBERATELY absent here, do not "harden" it blindly.
// This is an ENVELOPE guard, not the throat fit: packet_box_env_r_max() is the
// built packet's outermost box corner measured from the PACKET's own axis, and
// scroll_clear_r_min() is the sheet's tightest inner face measured from the
// TURNER's axis. The 0.05 between those two axes is a property of the TURNER
// datum, and it is asserted once, WITH it, in the exit check further down
// (packet_outer_r + packet_exit_ecc <= turner_exit_clear_r - tolerance, and the
// 4.325 - 4.0125 = 0.3125 arithmetic above). Folding it in here as well would
// assert the same physical fact a second time against a limit this check does
// not describe; it would not fail (3.9625 + 0.05 = 4.0125 <= 4.025) but it would
// make this envelope guard read as a second exit-fit check, and lose the point
// of keeping the two separate.
assert(packet_box_env_r_max() <= scroll_clear_r_min() - tolerance,
    str("Step 6: the built packet (box corners included) must pass the 6-turner: need <= ",
        scroll_clear_r_min() - tolerance, " got ", packet_box_env_r_max()));
// The morph is MONOTONIC in x - a roll that unrolls halfway is not a roll.
assert(roll_morph_max_backstep() <= 0,
    str("Step 6: the roll morph must be monotone in x: worst backstep ",
        roll_morph_max_backstep()));
assert(u_shape2(roll_x0) == 0 && u_shape2(roll_x1) == 1,
    str("Step 6: the morph must run 0 at the drop to 1 at the mouth: ",
        u_shape2(roll_x0), " -> ", u_shape2(roll_x1)));
assert(2*seed_bore_d >= 2*seed_dia_max + 2*tolerance,
    str("Step 6: the rolled packet bore must clear the seed: ", seed_bore_d,
        " vs ", seed_dia_max + 2*tolerance));
assert(abs(guide_pipe_gap - (guide_rail_y0 - guide_pipe_od/2)) < 0.001
    && guide_pipe_gap == 2.0,
    str("Step 6: guide rail must sit 2mm off the pipe OD: ", guide_pipe_gap));
assert(abs((guide_cap_y - guide_rail_y0) - 0.2) < 0.001,
    str("Step 6: guide cap must overlap the rail by 0.2 (never coplanar): ", guide_cap_y - guide_rail_y0));
assert(abs((pipe_od_bottom_z - guide_cap_z1) - 0.4) < 0.001,
    str("Step 6: guide cap must stop 0.4 below the pipe OD: ", pipe_od_bottom_z - guide_cap_z1));
assert(abs((guide_cap_z0 - u_outer_top_z) - 0.9) < 0.001,
    str("Step 6: guide cap must clear the U top by 0.9: ", guide_cap_z0 - u_outer_top_z));
assert(guide_cap_hole_d >= drop_pipe_id,
    str("Step 6: guide cap hole must pass the pipe bore: ", guide_cap_hole_d, " < ", drop_pipe_id));
assert(guide_cap_x0 == guide_x0 && guide_cap_x1 == guide_x1 && guide_cap_hole_x == 0,
    "Step 6: guide cap must span the guide x-envelope and be centred on x=0");
assert(former_capture_x0 == former_x1 - 2,
    str("Step 6: former capture notch must start 2mm before former_x1: ", former_capture_x0));
assert(abs((former_screw_y_head + former_screw_len) - former_screw_y_tip) < 0.001,
    str("Step 6: former screw tip must equal head seat + length: ", former_screw_y_tip));
assert(former_screw_len >= m2_head_h + 0.9 + m2_trap_depth + 1.4,
    str("Step 6: former M2 length has no margin left: need >= ", m2_head_h + 0.9 + m2_trap_depth + 1.4, " got ", former_screw_len));
assert(former_head_relief_d > m2_head_dia,
    str("Step 6: former head relief must clear the M2 head: ", former_head_relief_d));
assert(former_screw_y_head < former_screw_y_trap0 && former_screw_y_trap1 < former_screw_y_tip,
    str("Step 6: former M2 stack head < trap < tip must stay positive"));
assert(pusher_pad_x0 <= former_ear_x0 && pusher_pad_x1 >= former_ear_x1
    && pusher_pad_z0 == former_ear_z0 && pusher_pad_z1 == former_ear_z1,
    str("Step 6: the bracket pad must enclose the former ear with 1mm of material"));
assert((pusher_pad_x1 - pusher_pad_x0 - former_head_relief_d)/2 >= 1.0
    && (pusher_pad_z1 - pusher_pad_z0 - former_head_relief_d)/2 >= 1.0,
    str("Step 6: the 4.2 head pocket needs >=1.0mm of pad material each side: ",
        (pusher_pad_x1 - pusher_pad_x0 - former_head_relief_d)/2));
assert(pusher_pad_y0 == former_ear_y1,
    str("Step 6: the pad must start where the former ear ends: ", pusher_pad_y0));
assert(pusher_pad_x0 < former_screw_x && former_screw_x < pusher_pad_x1
    && pusher_pad_z0 < former_screw_z && former_screw_z < pusher_pad_z1
    && former_screw_y_trap0 > pusher_pad_y0
    && former_screw_y_trap1 == pusher_pad_y1,
    "Step 6: the former nut trap must sit inside the pad and break out at its outer face");
// FIT, against the EXIT - not the mouth, and not from the packet's own
// centre. The check that used to sit here compared the MOUTH's inner face
// (11.2) with the U's corner radius (sqrt(5.4^2 + 3.95^2) = 4.51) and passed
// with 6.7 to spare, which read like a generous throat. It measured the wrong
// end: the turner TAPERS, and the end that decides whether the packet gets
// out is the exit. It also measured from the wrong CENTRE: the packet axis
// (world 31.95) sits 0.05 below the turner axis (32), so the worst corner is
// 3.9625 + 0.05 = 4.0125 from the pin, not 3.95. So check the exit, with the
// eccentricity in: a closed roll of 25.4mm of paper at mean r 3.75 is 7.9
// across the outside, and the exit must clear half of that plus the 0.05
// offset plus one 0.3 working clearance (4.325 - 4.0125 = 0.3125).
// SAMPLED ACROSS THE WHOLE TURNER (t = 0, 0.25, 0.5, 0.75, 1), not just at
// the exit: the taper is monotone, so the exit is the binding station, and
// sampling it proves the whole spiral stays open for the packet.
//
// NOTE - the two checks below deliberately compare PACKET radius to SHEET
// radius, both taken about their OWN axis, and deliberately do NOT include
// packet_exit_ecc. Which limit each one uses is the whole point: these are
// "is the sheet wide enough for the closed packet" checks (packet_outer_r 3.95
// + one tolerance against the sheet's inner face, 4.325 at the tightest
// station). The turner-axis-relative fit - the only place the 0.05 eccentricity
// belongs - is asserted once, WITH it, in the exit check below
// (packet_outer_r + packet_exit_ecc <= turner_exit_clear_r - tolerance). Adding
// ecc to these as well would not fail (4.325 >= 3.95 + 0.05 + 0.3 = 4.30) but it
// would duplicate one physical fact across two different limits, and anyone
// tightening the exit pin later would then get two failures from one change
// instead of one.
for (t = packet_exit_check_t)
    assert(scroll_clear_r(t) >= packet_outer_r + tolerance,
        str("Step 6: the 6-turner must pass the closed Ø", 2*packet_outer_r,
            " packet (need >=", packet_outer_r + tolerance, ") at t=", t,
            ": got ", scroll_clear_r(t)));
assert(scroll_clear_r_min() >= packet_outer_r + tolerance,
    str("Step 6: the tightest station of the 6-turner is t=1 at r ",
        scroll_clear_r_min(), ", need >= ", packet_outer_r + tolerance));
assert(scroll_clear_r(0) == turner_mouth_clear_r - thickness/2,
    str("Step 6: the mouth clear radius and the t=0 sheet inner face must agree: ",
        turner_mouth_clear_r, " vs ", scroll_clear_r(0)));
assert(packet_outer_r + packet_exit_ecc <= turner_exit_clear_r - tolerance,
    str("Step 6: the packet outer, measured from the TURNER axis, must leave one tolerance of radial gap in the exit: need <= ",
        turner_exit_clear_r - tolerance, " got ", packet_outer_r + packet_exit_ecc,
        " (packet axis is ", packet_exit_ecc, " below the turner axis)"));
assert(2*turner_exit_clear_r >= 2*packet_outer_r,
    str("Step 6: the 6-turner EXIT must pass the closed Ø", 2*packet_outer_r,
        " packet: got Ø", 2*turner_exit_clear_r));
assert(scroll_clear_r(1) >= turner_exit_clear_r,
    str("Step 6: the built sheet's exit inner face must reach the exit pin: need >= ",
        turner_exit_clear_r, " got ", scroll_clear_r(1)));
assert(turner_mouth_clear_r > turner_exit_clear_r && u_center_world_z < turner_axis_z,
    str("Step 6: 6-turner handoff datums must stay consistent: mouth ", turner_mouth_clear_r,
        " > exit ", turner_exit_clear_r, "; U centre ", u_center_world_z, " < axis ", turner_axis_z));
assert(u_shape(former_x0) == 0 && u_shape(former_x1) == 1
    && abs(u_shape((former_x0 + former_x1)/2) - 0.5) < 0.001,
    str("Step 6: u_shape() must ramp 0 -> 1 across the former span"));

// Approved right bracket solids, before the assembly-side Y mirror.
bracket_plate_x0     = -5;
bracket_plate_x1     = 5;
bracket_plate_y0     = 11;
bracket_plate_y1     = 15;
bracket_plate_z0     = 10.5;
bracket_plate_z1     = 20;
bracket_arm_x0       = -24;
bracket_arm_x1       = 5;
bracket_arm_z0       = 10.5;
bracket_arm_z1       = 12;
bracket_flange_x0    = -26;
bracket_flange_x1    = -23.5;
bracket_flange_y0    = 7.4;
bracket_flange_y1    = 14.6;
bracket_flange_z0    = 10.5;
bracket_flange_z1    = 20;
bracket_screw1_y0    = 11;
bracket_screw1_y1    = 15.05;
bracket_screw2_x0    = -26.05;
bracket_screw2_x1    = -23.45;
bracket_screw2_y     = 11;
bracket_screw2_z     = 15;

// Positive-X source coordinates; hopper_body() mirrors these into the final
// negative-X side inside its existing union/difference.
hopper_boss_x0       = 26;
hopper_boss_x1       = 31.5;
hopper_boss_y0       = 7.4;
hopper_boss_y1       = 14.6;
hopper_boss_z0       = 10.5;
hopper_boss_z1       = 20;
hopper_web_x0        = 28;
hopper_web_x1        = 32;
hopper_web_y0        = 7.8;
hopper_web_y1        = 10.3;
hopper_web_z0        = 19;
hopper_web_z1        = 50;
hopper_boss_screw_x0 = 26.05;
hopper_boss_screw_x1 = 31.55;
hopper_boss_trap_x0  = 29.8;
hopper_boss_trap_x1  = 31.5;
hopper_boss_screw_y  = 11;
hopper_boss_screw_z  = 15;


// M2 constant and assembly assertions.
assert(m2_nominal_dia == 2 && m2_clearance_dia == 2.4
    && m2_head_dia == 3.8 && m2_head_h == 2
    && m2_nut_af == 4 && m2_nut_corner_dia == 4.32 && m2_nut_h == 1.6
    && m2_trap_af == 4.4 && m2_trap_depth == 1.7
    && m2_screw_len == 8 && m2_min_surrounding == 1,
    "Step 5: canonical M2 hardware dimensions must remain exact");
assert($fn == 60 && tolerance == 0.3,
    "Step 5: $fn=60 and general tolerance=0.3 must remain unchanged");
assert(guide_assembly_t == [100, 34, 19]
    && guide_assembly_t[2] == drum_axle_z - hopper_axis_z,
    "Step 5: guide assembly translation must be [100,34,19]");
assert(guide_x0 == -5 && guide_x1 == 5
    && guide_y0 == -15.2 && guide_y1 == 15.2
    && guide_floor_z0 == 7 && guide_floor_z1 == 8.7,
    "Step 5: guide floor envelope must remain exact");
assert(guide_rail_y0 == 7.7 && guide_rail_y1 == 9.7
    && guide_rail_z0 == 9.7 && guide_rail_z1 == 21.4
    && guide_bridge_y0 == 7.7 && guide_bridge_y1 == 15.2
    && guide_bridge_z0 == 9.7 && guide_bridge_z1 == 10.4
    && guide_foot_y0 == 13 && guide_foot_y1 == 15.2
    && guide_foot_z0 == 8.6 && guide_foot_z1 == 9.8,
    "Step 5: guide rail/bridge/foot envelopes must remain exact");
assert(guide_pad_x == 3.7 && guide_pad_y0 == 7.7 && guide_pad_y1 == 11
    && guide_pad_z0 == 11.3 && guide_pad_z1 == 18.7
    && guide_screw1_x == 0 && guide_screw1_z == 15
    && guide_screw1_y0 == 6.95 && guide_screw1_y1 == 11.05
    && guide_trap_y0 == 9.3 && guide_trap_y1 == 11,
    "Step 5: guide screw-pad and M2 trap envelope must remain exact");
assert(abs(guide_pipe_z0_local - 19.4) < 0.001
    && abs((guide_tape_z0_local - guide_floor_z1) - 0.3) < 0.001
    && abs((guide_pipe_z0_local - guide_floor_z1) - 10.7) < 0.001
    && abs((guide_bridge_z0 - guide_tape_z1_local) - 0.3) < 0.001
    && abs((guide_foot_y0 - paper_width/2) - 0.3) < 0.001,
    "Step 5: guide tape/pipe clearances must remain 0.3/10.7/0.3/0.3");
assert(guide_rail_y0 - guide_pipe_od/2 == guide_pipe_gap
    && guide_bridge_y0 - guide_pipe_od/2 == guide_pipe_gap,
    "Step 5/6: guide rails/bridges must remain guide_pipe_gap from the pipe OD");
assert(bracket_plate_x0 == -5 && bracket_plate_x1 == 5
    && bracket_plate_y0 == 11 && bracket_plate_y1 == 15
    && bracket_plate_z0 == 10.5 && bracket_plate_z1 == 20
    && bracket_arm_x0 == -24 && bracket_arm_x1 == 5
    && bracket_arm_z0 == 10.5 && bracket_arm_z1 == 12
    && bracket_flange_x0 == -26 && bracket_flange_x1 == -23.5
    && bracket_flange_y0 == 7.4 && bracket_flange_y1 == 14.6
    && bracket_flange_z0 == 10.5 && bracket_flange_z1 == 20,
    "Step 5: right bracket solids must remain exact");
assert(bracket_screw1_y0 == 11 && bracket_screw1_y1 == 15.05
    && abs((guide_trap_y1 - guide_trap_y0) - m2_trap_depth) < 0.001
    && abs((hopper_boss_trap_x1 - hopper_boss_trap_x0) - m2_trap_depth) < 0.001
    && bracket_screw2_x0 == -26.05 && bracket_screw2_x1 == -23.45
    && bracket_screw2_y == 11 && bracket_screw2_z == 15,
    "Step 5: bracket M2 clearance axes must remain exact");
assert(hopper_boss_x0 == 26 && hopper_boss_x1 == 31.5
    && hopper_boss_y0 == 7.4 && hopper_boss_y1 == 14.6
    && hopper_boss_z0 == 10.5 && hopper_boss_z1 == 20
    && hopper_web_x0 == 28 && hopper_web_x1 == 32
    && hopper_web_y0 == 7.8 && hopper_web_y1 == 10.3
    && hopper_web_z0 == 19 && hopper_web_z1 == 50,
    "Step 5: hopper boss/web source solids must remain exact");
assert(hopper_boss_screw_x0 == 26.05 && hopper_boss_screw_x1 == 31.55
    && hopper_boss_trap_x0 == 29.8 && hopper_boss_trap_x1 == 31.5
    && hopper_boss_screw_y == 11 && hopper_boss_screw_z == 15,
    "Step 5: hopper M2 clearance/trap source cuts must remain exact");
assert(hopper_web_x0 >= hopper_boss_x0
    && hopper_web_x1 - hopper_boss_x0 >= 1
    && hopper_boss_z1 - hopper_web_z0 == 1
    && hopper_web_y0 == drum_width/2 + tolerance
    && hopper_web_y1 == drum_width/2 + tolerance + hopper_wall
    && hopper_web_z1 - 49 == 1,
    "Step 5: hopper webs must overlap boss and structural wall by approved webs");
assert(hopper_boss_x0 - hopper_outer_r/2 >= 1
    && hopper_web_x0 - hopper_outer_r/2 >= 1
    && hopper_boss_screw_y == 11 && hopper_boss_screw_z == 15,
    "Step 5: hopper bosses/webs must clear the pipe envelope");
assert(2*hopper_boss_y0 >= m2_min_surrounding
    && bracket_plate_y1 - bracket_plate_y0 == 4
    && (bracket_flange_y1 - bracket_flange_y0)/2 - m2_clearance_dia/2 >= m2_min_surrounding,
    "Step 5: mirrored boss/bracket separation and screw surrounds must remain >=1mm");
assert(m2_head_dia/2 + m2_min_surrounding <= guide_pad_z1-guide_screw1_z
    && m2_head_dia/2 + m2_min_surrounding <= guide_screw1_z-guide_pad_z0
    && m2_head_dia/2 + m2_min_surrounding <= bracket_plate_z1-bracket_screw2_z
    && m2_head_dia/2 + m2_min_surrounding <= bracket_screw2_z-bracket_plate_z0
    && m2_head_dia/2 + m2_min_surrounding <= bracket_flange_y1-bracket_screw2_y
    && m2_head_dia/2 + m2_min_surrounding <= bracket_screw2_y-bracket_flange_y0,
    "Step 5: M2 head seats must retain >=1mm surrounding material");
assert(abs((bracket_screw1_y1 - guide_screw1_y0) - 8.1) < 0.001
    && abs((bracket_screw2_x1 + hopper_boss_screw_x1) - 8.1) < 0.001
    && m2_screw_len == 8,
    "Step 5: M2 screw spans must cover the 8mm fasteners");
assert(m2_screw1_axis[0] == 0 && m2_screw1_axis[1] == 1 && m2_screw1_axis[2] == 0
    && m2_screw2_axis[0] == 1 && m2_screw2_axis[1] == 0 && m2_screw2_axis[2] == 0
    && m2_screw1_axis[0]*m2_screw2_axis[0]
        + m2_screw1_axis[1]*m2_screw2_axis[1]
        + m2_screw1_axis[2]*m2_screw2_axis[2] == 0,
    "Step 5: M2 screw axes must be perpendicular Y/X axes");
assert(hopper_boss_screw_x0 < hopper_boss_screw_x1
    && bracket_screw2_x0 < bracket_screw2_x1
    && bracket_screw1_y0 < bracket_screw1_y1,
    "Step 5: M2 spans must be positive");
assert(hopper_export_rebase == 10.5
    && guide_export_rebase == 7
    && bracket_export_rebase == 10.5,
    "Step 5: export rebases must remain 10.5/7/10.5");
assert(export_rebases == [10.5, 7, 10.5],
    "Step 5: export rebase order must remain hopper/guide/bracket");

// ============================================================
// v37 Thread-bind + wind-up (v36 MVP backfill):
// hopper 9 o'clock -> 11-6 channel -> 6 o'clock drop -> thread bind
// -> wind-up. Bind sits just after the plow; take-up sits east of it.
// $fn=60, tol=0.3 kept.
// ============================================================
// ============================================================
bind_x   = plow_end + 25;   // 184: thread orbit station east of the plow (rotor X half 4 -> 180..188, gap 9)
takeup_x = 274;             // Step 4: take-up axis X274/Z50; reel flange X258..290
takeup_z = 50;              // Step 4: take-up axis Z50; reel flange Z34..66
assert(takeup_x > bind_x, str("wind-up reel must sit east of the bind station: ", takeup_x));
twister_axle_z = tape_z + 4;      // 32: v87 +15 lift: ring centre over the folded pocket (pocket top ~36)
twister_arms = 2;                 // 2 bobbin spindles
twister_wraps_per_seed = 2.0;            // v116 Step 2: B -6x -> 1:1 mitre -> twister -6x (2.0 wraps/seed magnitude)
twister_orbits_per_drum = num_divots * twister_wraps_per_seed; // 12: twister orbits per drum rev (2.0 per cavity)
tw_bore_d = 10;                   // twister bore diameter (the Ø7.9 packet passes through)
tw_axle_od = 15;                  // axle outer diameter
tw_hub_bore = 15.6;               // hub bore (slip fit on axle)
tw_hub_r = 10;                    // hub radius
tw_hub_x0 = 179;                  // hub west edge
tw_hub_x1 = 184;                  // hub east edge (hub length 5mm)
tw_mouth_x = 172;                 // mouth position
tw_tube_west_extension = 4;        // source +X = final west after reflection
 tw_tube_len = 21.5 + tw_tube_west_extension; // 25.5mm source tube length
 tw_tube_x1 = tw_mouth_x + tw_tube_len;       // 197.5 source tube end
tw_ped_x0 = 170;                  // pedestal west edge
tw_ped_x1 = 174;                  // pedestal east edge (mouth 160 inside zone, fused-base-by-design)
tw_ped_w = 10;                    // pedestal width
tw_disc_r = 23;                   // disc radius
tw_disc_x0 = 179;                 // disc west edge
tw_disc_x1 = 182;                 // disc east edge
tw_orbit = 19;                    // bobbin orbit radius
tw_pin_d = 6;                     // pin diameter
tw_pin_hole = 6.6;                // pin hole diameter (slip fit)
tw_pin_x0 = 182;                  // pin x start
tw_pin_len = 9.5;                 // pin length
bob_d = 20.7;                     // bobbin diameter
bob_h = 11.1;                     // bobbin height
tw_bob_x0 = 182;                  // bobbin x start (west must clear disc face 170)
tw_eye_r = 2;                     // eye radius
tw_eye_h = 6;                     // eye height
tw_eye_orbit = 13;                // eye orbit radius
tw_eye_x0 = 182;                  // eye x position
tw_eye_x1 = 197;                  // eye x endpoint
tw_snap_n = 3;                    // snap count
tw_snap_x0 = 194;                 // snap west edge
tw_snap_x1 = 197;                 // snap east edge
tw_barb = 0.8;                    // barb lip thickness (radial protrusion)
  // One external C-slot: radial from the Ø10 bore boundary to OD20.6.
  // Source +X maps to final west; extending the source high-X end by 4mm
  // lengthens the visible final-west slot while its final-east edge stays fixed.
  tw_slot_west_extension = 4;
  tw_slot_x0 = 178.5;
  tw_slot_x1 = 184.5 + tw_slot_west_extension;
  tw_slot_len = tw_slot_x1 - tw_slot_x0; // 10mm, 5mm total axial play
  tw_slot_w = 1.5;
  tw_slot_ang = 90;
  tw_slot_r0 = 5;                   // starts at the central bore boundary
  tw_slot_r1 = 10.3;                // 0.3mm radial clearance beyond hub r10
  tw_slot_x0_reflected = twister_axle_reflect_x - tw_slot_x1;
  tw_slot_x1_reflected = twister_axle_reflect_x - tw_slot_x0;
  // v118 Step 3: Essentra-style 2-leg split-shank snap arrow nose (east tip)
  tw_lock_n = 2;                    // snap leg count
  tw_lock_base_ang = 90;            // leg centre angle about X (deg, +Z leg)
  tw_lock_arc = 150;                // nominal leg arc width (deg, from gap-slot cuts)
  tw_gap_w = 3.5;                   // leg gap slot width (z-width of each radial cut)
  tw_lock_x0 = 184.5 + tw_slot_west_extension; // moved shoulder/nose start = 188.5
  tw_lock_x1 = 190 + tw_slot_west_extension;   // moved nose tip = 194
  tw_lock_flex_x0 = tw_lock_x0 - 1;            // derived nose flex-gap start
  tw_lock_flex_x1 = tw_lock_x1 + 0.5;          // derived nose flex-gap end
  tw_lock_barb_r = 9;               // shoulder/barb outer radius (catch vs hub bore r7.8)
  tw_lock_tip_r = 5.5;              // lead-in tip radius at nose apex
  tw_shoulder_clr = 0.5;            // axial shoulder-to-seated-hub clearance (assert 0.3..0.8)
  // Back-face teeth: trapezoidal with angled flanks and back-to-front taper
  // (replaces boxy lugs from v67). Tooth axis along X; back face fuses disc west.
  tw_teeth_x0 = 172;                // teeth west edge (front face, tapered tip)
  tw_teeth_x1 = 179;                // teeth east edge (back face, fuse disc west)
  tw_teeth_depth = tw_teeth_x1 - tw_teeth_x0; // 7: axial depth (back-to-front)
  tw_teeth_r0 = 18;                 // teeth root radius (inner)
  tw_teeth_r1 = 22.5;               // teeth pitch radius (outer base)
  tw_teeth_top_r = 27;              // teeth tip radius (outermost)
  tw_teeth_n = 24;                  // tooth count [18,24]
  tw_teeth_base_w = 2.6;            // base tangential width at root (back face)
  tw_teeth_tip_w = 1.6;             // tip tangential width at root (back face)
  tw_teeth_front_base_w = 1.2;      // base tangential width at front face (back-to-front taper)
  tw_teeth_front_tip_w = 0.8;       // tip tangential width at front face (back-to-front taper)
  tw_teeth_flank_ang = 45;          // flank taper angle (radial taper root→tip, degrees)
  tw_teeth_taper_ang = 15;          // back-to-front taper angle (axial narrowing, degrees)
  // Step1-fix flat-flank spur profile (trapezoid polygon extrude): root+tip
  // widths sum to 2x47% of circular pitch, so thickness at pitch (midspan
  // r0..top_r) equals tooth_arc_frac like the spur/bevel gears.
  tw_spur_root_w = 3.8;             // flat-flank root width at r0 (gap 0.9 at root circle)
  tw_spur_tip_w = 1.8;              // flat tip land at top_r (>=0.8 printable)
tw_collar_x0 = 176.5;             // collar west edge (static ring on tube)
tw_collar_x1 = 178.5;              // v120 Step 5: collar east edge (west running clearance 0.5 to hub face 179)
tw_collar_r = 9;                  // collar outer radius
  // flex pockets removed — full tube wall r5..7.5 to x185
  tw_cap_x0 = 196.5;               // cap ring west edge
  tw_cap_x1 = 197;                 // cap ring east edge (1mm face)
  tw_cap_r0 = 5;                   // cap ring inner (bore Ø10 through)
  tw_cap_r1 = 7;                   // cap ring outer (annular face)
  tw_pin_slot_w = 2.5;              // pin axial slot width (arrow push-lock, uniform full length)
  tw_pin_tip_r = 5.0;              // pin arrow tip radius (OD10, 45° chamfer barbs)
  tw_pin_chamfer_ang = 45;         // arrow tip chamfer angle (degrees)
tw_slot_y0 = 4;                   // slot south edge (v83: widened for lane_y=34)
tw_slot_y1 = 64;                  // slot north edge (v83: widened for lane_y=34)
// The chassis base slab is the flat print floor at z=0..4; no downward feet.

tw_lift = 27.5;                   // twister lift (teeth r27 + 0.5 clearance, tops clear z=0)
assert(tw_lift >= tw_teeth_top_r + 0.5, "tw_lift must exceed tw_teeth_top_r + 0.5 (clearance over tooth tips)");
takeup_core_d = 10;               // wind-up core dia (rev = tape / (PI*core_d))
takeup_core_r = takeup_core_d/2;
takeup_flange_r = 16;
takeup_flange_t = 3;
takeup_core_h = 28;
// v40 slip clutch on the take-up axle (handles changing reel diameter:
// fast when empty, slips when full). Stack rides ABOVE the top flange
// in the export frame (print base stays min_z=0): pressure disc +
// friction disc (the slip interface) + spring + hex nut. Disc r8 <
// flange r16 so the Step 4 station X envelope is 266..282.
clutch_disc_r = 8;
clutch_disc_t = 2;
clutch_spring_h = 3;
clutch_nut_h = 3;
clutch_stack = clutch_disc_t + clutch_disc_t + clutch_spring_h + clutch_nut_h; // 10
takeup_h_total = takeup_core_h + takeup_flange_t + clutch_stack; // 41: bottom flange 0..3 + core 0..31 + top 28..31 + clutch 31..41
// v45 leader pack radius (must equal the takeup_reel() wound-pack visual:
// core r5 + 3 = r8 at (takeup_x, takeup_z); the leader ends inside it).
tape_pack_r = takeup_core_r + 3;
assert(takeup_core_d == 10 && tape_pack_r == 8, "Step 4: take-up pack radius must be exactly 8");

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
// (local y20, z13: lane-centred so the Ø7.9 rolled packet threads the
// entry bore; was 12 pre-v56).
turner_curl_r = 6.5;              // v54 reference only (no shell)
turner_curl_bore = 4.2;           // v54 reference only (no bore)
turner_curl_off = 1.2;            // v54 reference only (no bore offset)
turner_curl_cz = 28;              // v87 +15 lift: bore-axis height (lane-centred)

// ============================================================
// TWISTER DRIVE TRAIN (fresh solve; old paper coordinates discarded).
// Path: crank 20T -> drum 40T (existing, front plane y49..55, -0.5x)
//   -> A counter 10T (module 2, +2.0 about Y)
//   -> bevel 12T/10T (module 1.5, corner Y->X, 1.2x, -2.4 about X)
//   -> drop 15T/12T (module 2, 1.25x, +3.0 about X)
//   -> jack 25T/10T (module 1.5, 2.5x, -7.5 about X)
//   -> friction wheel r10 on shaft D rides the twister disc OD
//      (contact R 33 = 23+10, tangent, no backlash).
// Total (40/10)*(12/10)*(15/12)*(25/10) = 4*1.2*1.25*2.5 = 15.0
// per drum rev = 7.5 per crank rev = 2.5 wraps per seed.
// Fresh decisions (why not the old sketch): module 1.5 for bevels +
// jack because a module-2 25T blank (outer 27) would swallow the
// parallel B shaft (CD 27); every mesh carries real backlash
// (0.75 spur, 1.0 bevel offset) so blanks only touch at the mesh
// point: separate STLs print and assemble clean. Custom bevel
// blanks (pitch-cone frustums in drive_train.scad) instead of the
// shared bevel_gear module whose back disc collides with the mate
// shaft. Shafts: A (counter, ||Y: front-wall bore + 2 meshes locate
// it, no pedestal); B/C/D (||X inboard, mesh-located + cross-bar
// bores). Chassis carries: A wall bore + 2 cross bars (bar1
// x148..152 z60..70 bores C+D, bar2 x170..174 z60..72 bore D).
// No outboard parts, no wall windows, nothing else moves.

// --- v97: no corner/drop/pinion numbers (composite only; solved at top) ---
// (v97 composite numbers live at the top, next to the crank.)

// Pull support pins (static bars: base-fused, slip-fit in roller
// bores + cup-B bore; the tape-coupled rotors spin on them).
// cup B kept (bored) for the static pin B (no tube hole v48).

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
// Drum gear radial offset from drum center (front plane): roller_len/2 + gear_thick/2 - epsilon = 17.95
gear_off = roller_len/2 + gear_thick/2 - epsilon;

// ============================================================
// Guard / fail-loud checks (5 Laws: Fail Loud)
// ============================================================
assert(chassis_x0 == -34, "Step 3: chassis_x0 must remain -34");
assert(chassis_len == 334, "Step 3: chassis_len must be 334");
assert(chassis_x0 + chassis_len == 300, "Step 3: chassis east edge must be X=300");
assert(takeup_x == 274, "Step 4: takeup_x must be 274");
assert(takeup_z == 50, "Step 4: takeup_z must be 50");
assert(takeup_x - takeup_flange_r == 258, "Step 4: take-up flange west edge must be X258");
assert(takeup_x + takeup_flange_r == 290, "Step 4: take-up flange east edge must be X290");
assert(takeup_z - takeup_flange_r == 34, "Step 4: take-up flange bottom must be Z34");
assert(takeup_z + takeup_flange_r == 66, "Step 4: take-up flange top must be Z66");
assert(chassis_x0 + chassis_len - (takeup_x + takeup_flange_r) == 10
    && chassis_x0 + chassis_len - (takeup_x + takeup_flange_r) >= tolerance,
    "Step 4: chassis east edge to take-up flange clearance must be exactly 10 mm");
assert(tape_flat_end == 220, "Step 4: tape_flat_end must be 220");
assert(leader_x0 == 218, "Step 4: leader_x0 must be 218");
assert(leader_x1 - takeup_x == -1.5, "Step 4: leader endpoint must be X=-1.5 from take-up centre");
assert(leader_z1 - takeup_z == -7.5, "Step 4: leader endpoint must be Z=-7.5 from take-up centre");
assert(sqrt(pow(leader_x1-takeup_x,2)+pow(leader_z1-takeup_z,2)) <= tape_pack_r,
    "Step 4: leader endpoint must remain inside the wound pack");
assert(tolerance >= 0 && tolerance < 1, "tolerance must be in [0,1)");
assert(paper_width > 0, "paper_width must be >0");
assert(seed_dia > 0 && seed_dia <= seed_dia_max, str("seed_dia must be (0,", seed_dia_max, "] (real seeds are ~3mm; the old 6.0 wheel ceiling is now a named constant)"));
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
// v102: crank handle stands >=20 off the front-wall outer face
// (arm inner face world = crank_mount_y + crank_arm_gap = 88 vs wall 68).
assert(crank_mount_y + crank_arm_gap - chassis_width >= 20,
       str("crank handle must stand >=20 off the front wall, got ",
           crank_mount_y + crank_arm_gap - chassis_width));
// v102: hex shaft tip must pass full through the crank-gear bore
// (shaft spans arm_yc-16 +/- len/2; tip = 48 vs gear inner face 49).
assert(crank_mount_y + crank_arm_w/2 + crank_arm_gap - 16 - hex_shaft_len/2
       <= crank_mount_y + gear_local_y - gear_thick/2,
       "crank shaft tip must reach through the crank-gear bore");
// v81: crank gear world y = crank_mount_y + gear_local_y = 76 + (-24) = 52 (front plane, spans 49..55).
assert(crank_mount_y + gear_local_y >= 49 && crank_mount_y + gear_local_y <= 55,
       "crank gear world y must be ~52 (front plane, gear spans y 49-55)");
// v81: drum gear world y = chassis_width/2 + gear_off = 34 + 17.95 ≈ 51.95 (front plane, matches crank gear within 0.05).
assert(chassis_width/2 + gear_off >= 49 && chassis_width/2 + gear_off <= 55,
       "drum gear world y must be ~52 (front plane, gear spans y 49-55)");
// Coplanarity: crank gear and drum gear must share the front plane (|Δy| < 0.5).
assert(abs((crank_mount_y + gear_local_y) - (chassis_width/2 + gear_off)) < 0.5,
       str("crank/drum gear planes must be coplanar (|Δy|<0.5): crank=", crank_mount_y + gear_local_y,
           " drum=", chassis_width/2 + gear_off));
// Crank-gear vs twister clearance (side projection along X):
// Y: gear near face 49 vs lane 34 → gap 15 >= 10 (primary separation).
// Z: gear bottom 38 vs twister teeth top 44 — overlap in YZ projection is
// absorbed by X separation (crank_x=160 vs bind_x); fail loud if either
// envelope drifts from the audited 6mm side-projection delta.
assert(crank_mount_y + gear_local_y - gear_thick/2 - lane_y >= 10,
       str("crank-gear Y-gap to lane must be >=10 (gear y0 vs lane): ",
           crank_mount_y + gear_local_y - gear_thick/2 - lane_y));
assert(abs((twister_axle_z + tw_teeth_top_r) - (drum_axle_z - (roller_pitch_dia/2 + addendum)) - 6) < 0.5,
       str("side-projection Z: teeth_top - gear_bottom must be ~6 (44-38): teeth_top=",
           twister_axle_z + tw_teeth_top_r, " gear_bottom=",
           drum_axle_z - (roller_pitch_dia/2 + addendum)));
assert(axle_clearance_dia/2 > axle_dia/2, "v48: bores must slip on shafts (free spin, no fuse)");
assert(spool_axle_z == 80, "spool_axle_z must be 80");
assert(chassis_height > max(spool_axle_z + cone_h + bb_height_spool, drum_axle_z + drum_outer_r) + 5,
       str("chassis_height must hold tallest axle + clearance: need > ", max(spool_axle_z+cone_h+bb_height_spool, drum_axle_z+drum_outer_r)+5, " got ", chassis_height));
assert(hopper_inner_r > drum_radius, "hopper_inner_r must exceed drum_radius (clearance >0)");
assert(drum_axle_z - hopper_axis_z == base_thick + 15, str("v87: hopper assembly must sit +15 (translate = base_thick+15): ", drum_axle_z - hopper_axis_z));
assert(plow_len > 15, str("plow_len must exceed 15, got ", plow_len));
assert(tape_thick >= 0.3, str("tape_thick must stay printable (>=0.3, no zero-thickness), got ", tape_thick));
// Step 6 (S4): the old near-roller bend is retired, so its own section asserts
// (fold_start/fold_end/fold_len/fold_width, the tape_bend_radius /
// tape_fold_angle envelope checks and the "full-U transit top vs the drum
// bottom (35)" sum of a cross-section that no longer exists) are DELETED with
// it. The live replacement below states the same clearance from the real Step 6
// numbers. The surviving transit asserts are unchanged and still fail loud.
assert(transit_end == plow_start,
       str("transit must reach the plow mouth: ", transit_end));
assert(transit_start == u_stable_end_x && transit_len == plow_start - u_stable_end_x,
       str("transit must start at the stable U end: ", transit_start, " len ", transit_len));
assert((transit_end - tape_x0) <= tape_len,
       str("transit must fit on the ribbon: need ", (transit_end - tape_x0), " <= ", tape_len));
// The folded U passes under the drum in the hopper frame: its world top is the
// hopper lift (drum_axle_z - hopper_axis_z) plus u_outer_top_z, and it must
// clear the drum's lowest point by 1mm.
assert((drum_axle_z - hopper_axis_z) + u_outer_top_z + 1.0 <= drum_axle_z - drum_radius,
       str("the folded U transit top + 1 must clear the drum bottom: ",
           (drum_axle_z - hopper_axis_z) + u_outer_top_z + 1.0, " vs ",
           drum_axle_z - drum_radius));
assert(tape_x0 + tape_len >= plow_end, str("tape ribbon must reach the plow end: ", tape_x0 + tape_len));
assert(bind_x > plow_end, str("bind station must sit east of the plow end: ", bind_x));
assert(twister_arms == 2, "thread twister must carry exactly 2 thread arms");
assert(tw_spur_tip_w >= 0.8, "twister spur tip land must be >=0.8 (standard-form printable)");
assert(tw_spur_root_w + tw_spur_tip_w - 2*tooth_arc_frac*2*PI*tw_teeth_r1/tw_teeth_n < 0.15, "twister spur thickness at pitch must equal tooth_arc_frac (flat-flank standard form)");
assert(twister_wraps_per_seed >= 2 && twister_wraps_per_seed <= 3, str("wraps per seed must be in [2,3], got ", twister_wraps_per_seed));
assert(twister_orbits_per_drum == num_divots * twister_wraps_per_seed, "twister must orbit wraps-per-seed times per cavity (15 per drum rev, 2.5 binds per seed)");
// v97 composite take-off asserts (mesh + clearances, fail loud):
// crank->A mesh CD exact (pitch + 0.75 backlash prints + assembles):
assert(abs(sqrt(pow(v97_Ax-crank_axle_x,2)+pow(v97_Az-crank_axle_z,2)) - v97_A_cd) < 0.05, "crank->A distance must equal mesh CD 30.75");
assert(A_rev == -2, "composite rev must be -2 per crank rev");
// v113 mitre-mesh asserts (Bbev20 <-> twister bevel ring, fail loud):
// A->B mesh RETIRED (A-mesh OPEN until the next-step intermediate):
assert(B_rev == -6, "B rev must be -6 per crank rev (idler-driven: two flips, 30/10)");
assert(twister_rev == -6, "twister rev must be -6 per crank rev through the 1:1 mitre");
assert(I_rev == 4, "idler rev must be +4 per crank rev (-A.30/15)");
// v116 idler mesh CDs exact (pitch + 0.75 backlash, like A/B):
assert(abs(sqrt(pow(v115_Ix-v97_Ax,2)+pow(v115_Iz-v97_Az,2)) - (18.75+9.375+0.75)) < 0.05, "idler->A distance must equal mesh CD 28.875");
assert(abs(sqrt(pow(v115_Ix-v98_Bx,2)+pow(v115_Iz-v98_Bz,2)) - (6.25+9.375+0.75)) < 0.05, "idler->B distance must equal mesh CD 16.375");
// idler shaft spans hub + gear (front-wall bore + gearwall bore carry it):
assert(v115_I_y0 <= 68 && v115_I_y1 >= v115_I15_y1, "idler shaft must span hub and gear");
// idler gear top (75) stays below the plate (78) and tip below the arm sweep:
assert(v115_I15_y1 <= v105_wall_y0 - 2, "idler gear must stay below the outboard plate");
assert(v115_I_y1 <= crank_mount_y + crank_arm_gap - 5, "idler tip must stay below the crank-arm sweep");
// idler gear vs hopper drum (100,75 r33.8): radial:
assert(sqrt(pow(v115_Ix-100,2)+pow(v115_Iz-75,2)) - 33.8 - 11 >= 1, "idler gear must clear the hopper radially");
// idler gear (bottom y70) clears the B bevel top (57.5) and twister sweep top (55.75):
// (Step 4: the r8 hub remains removed; the live full-radius backing web is
// confined behind the heel plane, while the root frustum carries the teeth.)
assert(v115_I15_y0 >= v98_Bbev_y1 + 2, "idler gear must clear the B bevel top");
assert(v115_I15_y0 - (32+23.75) >= 5, "idler gear must clear the twister sweep");
// idler shaft (r4) vs A30 (r20.75) / B10 (r8.25) / B shaft (r4): true-distance:
assert(28.875 - 20.75 - 4 >= 1, "idler shaft must clear the A30 blank");
assert(16.375 - 8.25 - 4 >= 1, "idler shaft must clear the B10 blank");
assert(sqrt(pow(v115_Ix-v98_Bx,2)+pow(v115_Iz-v98_Bz,2)) - 4 - 4 >= 1, "idler shaft must clear the B shaft");
// idler station inside the walls; gearwall plate covers its bore:
assert(v115_Ix > chassis_x0 && v115_Ix < chassis_x0 + chassis_len && v115_Iz > 0 && v115_Iz < chassis_height, "idler wall bore must sit inside the front wall");
assert(v105_wall_x0 <= v115_Ix && v115_Ix <= v105_wall_x1 && v105_wall_z0 <= v115_Iz && v115_Iz <= v105_wall_z1, "gearwall plate must cover the fresh idler bore");
// B Y-axis through the shared apex (mate-driven station):
assert(v98_Bx == tw_apex_x_frame && v98_Bz == tw_apex_z, "B axis must pass through the final framed mitre apex (210.5, 32)");
// apex on the twister axis (lane_y=34, z=twister_axle_z=32):
assert(tw_apex_z == twister_axle_z, "apex must sit on the twister axis (z=32)");
// mitre 45° heel pitch r22.5 both sides (apex+22.5 along each axis):
assert(tw_bev_heel_x - tw_apex_x == 22.5 && v113_B_heel_y - lane_y == 22.5, "source mitre 45deg heel pitch r22.5 both sides");
// mesh phase tooth-into-gap (half-pitch of 36T; visually verified):
assert(tw_bev_phase == 0 && v113_B_phase == 5, "bevel mesh tooth-into-gap phase");
// tooth-fit with backlash (B tip + tw pitch-width <= circular pitch - 0.2, m1.25):
assert((tooth_arc_frac*PI*tw_bev_mod)*v113_B_thin + ((tooth_arc_frac*PI*tw_bev_mod+0.72*PI*tw_bev_mod)/2)*tw_bev_thin <= PI*tw_bev_mod - 0.2, "mesh tooth-fit with backlash");
// twister toe (heel - face*cos45) clears the pedestal east edge by >=0.3:
assert(tw_bev_heel_x - tw_bev_face*cos(45) - tw_ped_x1 >= 0.3, "source twister bevel toe must clear the pedestal");
// B heel corner (max-x = Bx+23.75) floats inside the back-cone relief with >=0.5 walls:
tw_relief_x0_frame = 2 * twister_frame_cx - tw_relief_x1;
tw_relief_x1_frame = 2 * twister_frame_cx - tw_relief_x0;
assert((v98_Bx - 23.75) - tw_relief_x0_frame >= 0.5 && tw_relief_x1_frame - (v98_Bx - 23.75) >= 0.5, "B heel corner must float inside the framed relief (x)");
assert(tw_relief_r0 <= 22.5 && 22.5 <= tw_relief_r1, "B heel corner must float inside the relief (r)");
// (the old "relief keeps >=1 wall to the 7.8 tape bore" assert is DELETED:
// it certified the retired old fold cross-section - there is no 7.8 tape
// bore on the lane any more, the packet roll is 7.9 across.)
// B shaft east surface (Bx+4) clears the twister toe plane by >=1.5:
assert((v98_Bx + 4) - (tw_apex_x_frame - 22.5 - tw_bev_face*cos(45)) >= 1.5, "B shaft must clear the framed twister toe plane");
// B parts (bottom y54) clear the pedestal/foot top Y edge (Step-8 foot to lane_y+7=41):
assert(v98_B_y0 - (lane_y + 7) >= 1, "B shaft must clear the pedestal foot in y");
// B shaft bottom vs plow exit flare (axis (159,34,32), r10.5 worst case):
assert(sqrt(pow(v98_Bx-159,2)+pow(v98_B_y0-34,2)) - 10.5 >= 1.0, "B shaft must clear the plow exit flare");
// Step 2 outboard wall asserts: canonical four-support layout, face contact,
// continuous screw cavities, and all existing gear/keep-out constraints.
assert(len(v105_pillar_xz) == 4 && v105_pillar_xz == [[137, 32], [137, 88], [217, 88], [229, 32]],
       "Step 2: gearwall must use exactly the four canonical pillar stations");
assert(v105_wall_x0 == 132 && v105_wall_x1 == 234
    && v105_wall_y0 == 78 && v105_wall_y1 == 81
    && v105_wall_z0 == 20 && v105_wall_z1 == 93,
    "Step 2: gearwall plate extents must stay X132..234/Y78..81/Z20..93");
assert(v105_wall_z0 == 20
    && (v98_Bz - 8.25) - v105_wall_z0 >= 2,
    "Step 2: plate bottom Z20 must clear the B10 lower envelope Z23.75 by >=2mm");
assert(v105_pillar_y0 == 68 && v105_pillar_y1 == 80
    && v105_pillar_y0 == south_wall_bore_y + wall_thick/2
    && v105_pillar_y0 >= chassis_width,
    "Step 2: pillars must face-touch the south wall at Y68 without overlap");
assert(v105_pillar_s == 6 && v105_pillar_half == 3
    && (v105_pillar_s - v105_pillar_screw_d)/2 >= 1,
    "Step 2: each pillar must retain >=1mm M3 hole edge web");
assert(v105_nut_trap_floor == v105_wall_y1 - (nut_trap_depth + epsilon)
    && v105_nut_trap_floor == 78.45
    && v105_nut_trap_floor - v105_wall_y0 >= 0.4,
    "Step 2: nut-trap floor must leave the approved 0.45mm plate web");
for (station = v105_pillar_xz) {
    assert(v105_wall_x0 + 2 <= station[0] - v105_pillar_half
        && station[0] + v105_pillar_half <= v105_wall_x1 - 2
        && v105_wall_z0 + 2 <= station[1] - v105_pillar_half
        && station[1] + v105_pillar_half <= v105_wall_z1 - 2,
        "Step 2: every pillar must retain >=2mm plate edge");
    for (sx = [-1, 1]) for (sz = [-1, 1]) {
        corner_x = station[0] + sx*v105_pillar_half;
        corner_z = station[1] + sz*v105_pillar_half;
        assert(sqrt(pow(corner_x-v97_Ax, 2)+pow(corner_z-v97_Az, 2)) >= 21.75,
            "Step 2: every pillar corner must clear A30 by the 21.75mm rule");
        assert(sqrt(pow(corner_x-v98_Bx, 2)+pow(corner_z-v98_Bz, 2)) - 8.25 - v105_pillar_corner_r >= 1,
            "Step 2: every pillar corner must clear B10 by >=1mm");
        assert(sqrt(pow(corner_x-v115_Ix, 2)+pow(corner_z-v115_Iz, 2)) - 11 - v105_pillar_corner_r >= 1,
            "Step 2: every pillar corner must clear idler by >=1mm");
        assert(sqrt(pow(corner_x-crank_axle_x, 2)+pow(corner_z-crank_axle_z, 2)) - hex_clearance_r - v105_pillar_corner_r >= 1,
            "Step 2: every pillar corner must clear the crank hex relief by >=1mm");
        assert(corner_x + 1 <= takeup_x - bb_len/2
            || corner_x - 1 >= takeup_x + bb_len/2
            || corner_z + 1 <= takeup_z - bb_height_spool
            || corner_z - 1 >= takeup_z + 2,
            "Step 2: every pillar corner must clear the takeup bore/block by >=1mm");
    }
}
assert(max([v97_A30_y1, v98_B10_y1, v115_I15_y1]) <= v105_wall_y0 - 3,
    "Step 2: every gear top must stay >=3mm below the plate");
assert(v105_wall_y1 <= crank_mount_y + crank_arm_gap - 5
    && v105_pillar_y1 <= crank_mount_y + crank_arm_gap - 5,
    "Step 2: plate and pillars must stay clear of the crank sweep");
assert(chassis_width/2 + takeup_h_total/2 + 1 <= v105_pillar_y0,
    "Step 2: takeup reel must retain axial Y separation from the pillars");
assert($fn == 60 && tolerance == 0.3 && bolt_dia == 3 && bolt_head_across == 5.5 && nut_trap_depth == 2.5,
    "Step 2: $fn, tolerance, and M3 dimensions must remain unchanged");
// v117 inboard stub cuts land inside their carrier bands:
assert(v97_A_y0 >= 49 && v97_A_y0 <= 50, "A stub cut must end inside the A10 band [49,50]");
assert(v98_B_y0 >= 53 && v98_B_y0 <= 57, "B stub cut must end inside the bevel band [53,57]");
assert(v115_I_y0 >= 65 && v115_I_y0 <= 68, "idler stub cut must end inside the front wall [65,68]");
assert(v98_B10_y0 == v97_A30_y0 && v98_B10_y1 == v97_A30_y1, "B10 must share the A30 band (mesh)");
assert(v98_B10_y0 >= chassis_width + 2, "B10 must sit outside the front wall");
assert(v98_B_y1 <= crank_mount_y + crank_arm_gap - 5, "B shaft tip must stay below the crank-arm sweep");
// Step-3 gap: bevel top (58) -> B10 bottom (70) = 12 bare shaft (was 1):
assert(v98_B10_y0 - v98_Bbev_y1 >= 5, "Step-4b gap bevel->B10 must be >=5");
// B10 (tip r7.5) vs crank hex shaft: true-distance over XZ:
assert(sqrt(pow(v98_Bx-crank_axle_x,2)+pow(v98_Bz-crank_axle_z,2)) - 7.5 - hex_axle_r >= 1,
       "B10 must clear the crank shaft (true-distance)");
// Step 2: A30 sits OUTSIDE the front wall (2 clear), clears the crank hex
// shaft by true distance, and stays below the crank-arm sweep:
assert(v97_A30_y0 >= chassis_width + 2, "A30 must sit outside the front wall");
assert(v97_A_cd - 20 - hex_axle_r >= 1, "A30 must clear the crank shaft (true-distance)");
assert(v97_A30_y1 + 5 <= crank_mount_y + crank_arm_gap, "A30 must clear the crank-arm sweep");
// B shaft spans bevel + B10 (bevel fused via root frustum between, shaft-pierced):
assert(v98_Bbev_y0 <= v98_B_y0 && v98_B_y0 <= v98_Bbev_y1 && v98_B_y1 >= v98_B10_y1, "B shaft must span bevel and B10 (stub cut inside the bevel band)");
// B station vs A cluster (A30 outer r20.75, shaft r4): true-distance:
assert(sqrt(pow(v98_Bx-v97_Ax,2)+pow(v98_Bz-v97_Az,2)) - 20.75 - 4 >= 1, "B must clear the A cluster (true-distance)");
// Bbev36 heel (outer r23.75) vs A10 (r12): true-distance:
assert(sqrt(pow(v98_Bx-v97_Ax,2)+pow(v98_Bz-v97_Az,2)) - 12 - 23.75 >= 1, "B bevel heel must clear the A10 blank by >=1");
// B10 (outer r8.25) vs teeth sweep R27 about (34,32): radial:
assert(sqrt(pow(v98_Bx-34,2)+pow(v98_Bz-32,2)) - 8.25 > 27, "B10 must clear the teeth sweep radially");
// Bbev36 heel (outer r23.75, was stale Bbev20 tip bound r11) vs pin sweep R24: radial:
assert(sqrt(pow(v98_Bx-34,2)+pow(v98_Bz-32,2)) - 23.75 > 24, "B bevel heel must clear the pin sweep radially");
// B10 top (Bz+8.25) vs crank-gear bottom (axle 104.93 - r22): z-clear:
assert(v98_Bz + 8.25 < crank_axle_z - 22, "B10 must stay below the crank-gear sweep");
// Step 4 B backing web: full tooth-envelope support, 0.3mm root overlap,
// behind the nominal heel plane, with wall/B10/shaft clearances.
assert(B_back_web_r == 24 && B_back_web_t == 3, "Step 4: B back-web radius/thickness must be 24/3");
assert(B_back_web_z0 == 19.3 && B_back_web_z1 == 22.3, "Step 4: B back-web canonical placement must be z=19.3..22.3");
assert(abs(B_back_web_y0 - 56.7) < 0.001 && abs(B_back_web_y1 - 59.7) < 0.001,
       "Step 4: B back-web assembly Y must be 56.7..59.7");
assert(abs((B_back_web_z1 - B_back_web_z0) - B_back_web_t) < 0.001,
       "Step 4: B back-web thickness must match its canonical span");
assert(abs((min(B_root_frustum_z1, B_back_web_z1) - max(B_root_frustum_z0, B_back_web_z0)) - 0.3) < 0.001,
       "Step 4: B back-web must overlap the root frustum by exactly 0.3mm");
assert(B_back_web_z1 <= 22.5 && B_back_web_r >= 23.75,
       "Step 4: B back-web must stay behind the heel plane and cover the tooth envelope");
assert(B_back_web_r >= axle_dia/2 + tolerance && B_root_frustum_r0 >= axle_dia/2 + tolerance,
       "Step 4: B back-web/root must clear the shaft envelope");
assert((chassis_width - wall_thick) - B_back_web_y1 >= 5,
       "Step 4: B back-web must clear the Y=65 wall by at least 5mm");
assert(v98_B10_y0 - B_back_web_y1 >= 5,
       "Step 4: B back-web must clear B10/outboard hardware by at least 5mm");
// B10 and the fixed pull nip are separated by their existing Y bands:
// Bbev20 band top (58) vs B10 band (70): Step-3 extended gap (12 bare shaft):
    assert(v98_B10_y0 - v98_Bbev_y1 >= 0.5, "B bevel must sit just under B10");
// Legacy v103/v106 helper parameters are not used by the live B cluster.
// B wall bore inside the front wall:
assert(v98_Bx > chassis_x0 && v98_Bx < chassis_x0 + chassis_len && v98_Bz > 0 && v98_Bz < chassis_height, "B wall bore must sit inside the front wall");
// (twister unpowered in v97: takeoff reserved for the next stage.)
// y-rule (Step 2: shaft runs outboard carrying A30; tip stays 5 below the arm sweep):
assert(v97_A_y1 <= crank_mount_y + crank_arm_gap - 5, "A shaft tip must stay below the crank-arm sweep");
// Fused bands ride the shaft that carries them:
assert(v97_A_y0 <= 50 && v97_A_y1 >= v97_A30_y1, "A shaft must span the stub cut (A10 band 49-55) and A30");
// A10 (4mm face) overlaps the crank-gear front plane 49-55:
assert(v97_A10_y0 >= 49 && v97_A10_y1 <= 55 && (v97_A10_y1 - v97_A10_y0) >= 6, "A10 must mesh the crank-gear plane with 6mm face");
// A30 outside (top 75) leaves room for the Step-5 outboard wall below the arm (88):
assert(v97_A30_y1 <= crank_mount_y + crank_arm_gap - 10, "A30 must leave room for the Step-5 wall");
// A30 (outer r20.75, m1.25) vs hopper (drum (100,75) max r33.8): radial:
assert(sqrt(pow(v97_Ax-100,2)+pow(v97_Az-75,2)) - 20.75 > 33.8, "A30 must clear the hopper radially");
// A30 and the fixed pull nip are separated by their existing Y bands:
// A wall bore inside the front wall:
assert(v97_Ax > chassis_x0 && v97_Ax < chassis_x0 + chassis_len && v97_Az > 0 && v97_Az < chassis_height, "A wall bore must sit inside the front wall");
assert(twister_axle_z + tw_disc_r <= 56, "twister disc top needs margin (55 vs 56)");
// Stack-up asserts (new twister geometry)
assert(tw_mouth_x - plow_end >= 10 && tw_mouth_x - plow_end <= 16, "mouth gap tw_mouth_x-plow_end in [10,16]");
assert(tw_ped_x1 + 0.5 <= tw_slot_x0, "slot edge tw_ped_x1+0.5<=tw_slot_x0");
assert(tw_disc_x0 - tw_ped_x1 >= 2, "disc gap tw_disc_x0-tw_ped_x1>=2");
// disc-in-slot assert removed: disc x167..170 is separate from radial slots x174..185
assert(lane_y - (tw_orbit + bob_d/2) >= tw_slot_y0 && lane_y + (tw_orbit + bob_d/2) <= tw_slot_y1, "sweep-in-slot-Y");
assert((twister_axle_z - tw_orbit - bob_d/2) >= 2, "dip clearance above the flat chassis floor");
// (the old "(tw_bore_d - 7.8)/2 >= 1" tape/bore assert is DELETED: same
// retired 7.8 tape bore - the packet roll is 7.9 across.)
assert(abs(tw_hub_bore - tw_axle_od - 0.6) < 0.001, "hub slip fit");
assert(abs(tw_pin_hole - tw_pin_d - 0.6) < 0.001, "pin slip fit");
assert(tw_hub_x0 - tw_ped_x1 >= 2, "hub-vs-pedestal");
assert(tw_slot_west_extension == 4 && tw_tube_west_extension == 4
    && tw_tube_len == 25.5 && tw_lock_x0 == 188.5 && tw_lock_x1 == 194,
    "Step 7: all west extension/nose/tube dimensions must be the intended 4mm extension");
assert(tw_snap_x0 - (tw_pin_x0 + tw_pin_len) >= 2, "pin-tip-vs-snap");
// Arrow push-lock pin asserts
assert(tw_pin_slot_w >= 2.5, "arrow pin slot width >=2.5mm");
assert(tw_pin_tip_r * 2 >= 9 && tw_pin_tip_r * 2 <= 10, "arrow tip OD 9-10mm");
assert((tw_pin_tip_r * 2 - tw_pin_slot_w) / 2 >= 1.5, "prong min thickness >=1.5mm");
assert(tw_snap_x0 - (tw_bob_x0 + bob_h) >= 0.5, "bobbin-vs-snap");
assert(tw_eye_orbit - tw_eye_r - (tw_axle_od/2 + 1.2 + tw_barb) >= 1, "barb-vs-eyelet");
// Teeth geometry asserts (trapezoidal bevel-profile, back-to-front taper)
assert(tw_teeth_n >= 18 && tw_teeth_n <= 24, str("twister teeth count must be in [18,24], got ", tw_teeth_n));
assert(tw_teeth_x1 == tw_disc_x0, "teeth_x1 must fuse disc west face (by param)");
assert(tw_teeth_depth >= 5 && tw_teeth_depth <= 9, str("twister teeth depth must be in [5,9], got ", tw_teeth_depth));
assert(min(tw_teeth_base_w, tw_teeth_tip_w, tw_teeth_front_base_w, tw_teeth_front_tip_w) >= 0.8,
       str("all tooth feature widths must be >=0.8mm, got min ", min(tw_teeth_base_w, tw_teeth_tip_w, tw_teeth_front_base_w, tw_teeth_front_tip_w)));
assert(tw_teeth_flank_ang >= 30 && tw_teeth_flank_ang <= 60,
       str("flank angle must be in [30,60] degrees, got ", tw_teeth_flank_ang));
assert(tw_teeth_taper_ang >= 5 && tw_teeth_taper_ang <= 20,
       str("back-to-front taper angle must be in [5,20] degrees, got ", tw_teeth_taper_ang));
assert(tw_teeth_x0 <= tw_teeth_x1, "teeth west edge must be <= east edge");
assert(tw_teeth_r0 < tw_teeth_r1 && tw_teeth_r1 < tw_teeth_top_r,
       "teeth radii must be r0 < r1 < top_r");
// Main C-slot fit and retention assertions.
assert(tw_slot_r0 >= tw_bore_d/2, "C-slot inner radius must start at or outside the axle bore");
assert(tw_slot_r1 >= tw_hub_r + 0.3, "C-slot outer radius must clear the hub by 0.3mm");
assert(tw_slot_len == 10, "Step 7: C-slot must be the extended 10mm source span");
assert(tw_slot_len >= tw_hub_x1 - tw_hub_x0, "C-slot axial length must cover the hub");
assert(tw_slot_len - (tw_hub_x1 - tw_hub_x0) == 5, "Step 7: C-slot must provide intended 5mm total axial play");
assert(tw_slot_x0 >= tw_collar_x1, "C-slot must clear the static collar");
assert(tw_slot_x1 == tw_lock_x0, "Step 7: extended C-slot must end at the moved retaining shoulder");
// Rotor and axle have intentionally distinct reflection datums. The rotor
// remains at its pre-correction mesh position while the axle moves east 6mm.
tw_hub_x0_reflected = twister_reflect_x - tw_hub_x1;
tw_hub_x1_reflected = twister_reflect_x - tw_hub_x0;
tw_lock_shoulder_x_reflected = twister_axle_reflect_x - tw_lock_x0;
tw_collar_x0_reflected = twister_axle_reflect_x - tw_collar_x0;
assert(tw_hub_x0_reflected == 181.5 && tw_hub_x1_reflected == 186.5,
    "twister rotor must remain unchanged at hub X181.5..186.5");
assert(tw_slot_x0_reflected == 183 && tw_slot_x1_reflected == 193,
    "east-shifted twister axle C-slot must be X183..193");
assert(tw_slot_x0_reflected <= tw_hub_x1_reflected
    && tw_slot_x1_reflected >= tw_hub_x0_reflected,
    "east-shifted C-slot must retain hub overlap");
assert(tw_lock_shoulder_x_reflected == 183
    && tw_lock_shoulder_x_reflected >= tw_hub_x0_reflected
    && tw_lock_shoulder_x_reflected <= tw_hub_x1_reflected,
    "east-shifted shoulder must remain captured by the unchanged hub span");
assert(tw_slot_x1_reflected - tw_hub_x1_reflected == 6.5,
    "east-shifted slot must retain 6.5mm travel beyond the unchanged hub");
assert(tw_hub_bore > tw_axle_od
    && tw_slot_r1 >= tw_hub_r + tolerance,
    "east-shifted hub/slot must clear the axle tube radially");
assert(tw_collar_x0_reflected - tw_hub_x1_reflected >= tolerance,
    "east-shifted rotor must not collide with the axle collar");
assert(twister_axle_x_shift == 6 && twister_axle_reflect_x == 371.5,
    "axle must carry the requested +6mm east shift");
assert(twister_support_rib_x0 == 195 && twister_support_rib_x1 == 201
    && twister_support_m3_x == [196.5, 199.5],
    "axle support rib/M3 stations must follow the +6mm shift");
assert(tw_axle_support_x1_reflected == 205.5
    && takeup_x - takeup_flange_r - tw_axle_support_x1_reflected >= 10,
    "east-shifted axle support must clear the fixed pull/take-up flange");
assert(tw_slot_ang == 90, "C-slot must stay on +Z, clear of the two ±Y nose flex gaps");
assert(tw_axle_od/2 - tw_slot_r0 >= 2, "axle tube wall at the C-slot root must remain >=2mm");
assert(tw_bore_d/2 == 5, "bore radius must be 5 (Ø10 through-hole)");
// Collar vs disc clearance
assert(tw_disc_x0 - tw_collar_x1 >= 0.5, "collar-vs-disc: disc_x0-collar_x1>=0.5");
// Collar-vs-teeth radial (comment only: collar r9 vs teeth r18, no radial conflict)
// Retaining barb vs eyelet inner radial clearance
assert(tw_eye_orbit - tw_eye_r - tw_lock_barb_r >= 1, "barb-vs-eyelet-inner radial >=1");
  // West play: hub_x0 vs collar_x1
  assert(tw_hub_x0 - tw_collar_x1 >= 0.5 && tw_hub_x0 - tw_collar_x1 <= 1.0, "west play hub_x0-collar_x1 in [0.5,1.0]");
  // v120 Step 5: axial retention with free spin — total play (east snap
  // clearance + west collar clearance) holds the rotor in place in X while
  // the 0.6 diametral bore slip keeps it spinning free. Hub faces 179/184
  // are rotor-code truth (local -5..0 at bind_x 184).
  assert((tw_lock_x0 - tw_hub_x1) + (tw_hub_x0 - tw_collar_x1) == 5,
      "Step 7: moved nose plus collar must provide the intended 5mm total axial play");
  assert(tw_collar_r - tw_hub_bore/2 >= 1.0,
      "v120: collar thrust overlap ring (collar r - hub bore r) must be >=1.0");
  // Cap ring thickness
  assert(tw_cap_x1 - tw_cap_x0 >= 0.49 && tw_cap_x1 - tw_cap_x0 <= 0.51, "cap ring must be ~0.5mm thick");
  // Cap ring radials
  assert(tw_cap_r0 == 5 && tw_cap_r1 == 7, "cap ring inner/outer must be r5..r7");

// v118 Step 3: snap-fit nose lock geometry (fail-loud)
assert(abs(tw_lock_barb_r - tw_hub_bore/2) >= 1.0 && abs(tw_lock_barb_r - tw_hub_bore/2) <= 1.5,
       "v118: barb catch over hub bore must be 1.0..1.5mm (tw_lock_barb_r - tw_hub_bore/2)");
assert(tw_lock_x0 - tw_hub_x1 == tw_slot_west_extension + tw_shoulder_clr,
       "Step 7: moved shoulder must retain the 4mm extension plus nominal shoulder clearance");
assert(tw_lock_x0 - tw_hub_x1 >= 1 && tw_lock_x1 - tw_lock_x0 >= 1,
       "Step 7: moved nose must remain materially clear of the rotating hub sweep");
assert(tw_tube_x1 - tw_lock_x1 >= 3,
       "Step 7: extended tube must retain material beyond the moved nose");
assert(tw_gap_w >= 2.5, "v118: tw_gap_w must be >= 2.5 (leg flex daylight)");
assert(tw_lock_tip_r + tw_gap_w/2 <= tw_axle_od/2 + 1,
       "v118: tip r + half gap must stay within OD/2 + 1 (insertion chamfer budget)");
// Pin tip vs finger base X note (comment only: radial separation >8.7, no conflict)
assert(takeup_x + takeup_flange_r <= chassis_x0 + chassis_len + 4, str("take-up flange must stay ~inside the chassis east edge: ", takeup_x + takeup_flange_r));
assert(spool_axle_x - chassis_x0 >= 20, str("Step10: west margin spool(-6) to west edge must be >=20: ", spool_axle_x - chassis_x0));
assert(chassis_x0 + chassis_len - (takeup_x + takeup_flange_r) >= 10, str("Step10: east margin east edge to takeup flange must be >=10: ", chassis_x0 + chassis_len - (takeup_x + takeup_flange_r)));
assert(takeup_z - takeup_flange_r >= 0, str("take-up flange bottom must stay >= 0: ", takeup_z - takeup_flange_r));
assert(takeup_z + takeup_flange_r <= chassis_height, str("take-up flange top must fit below wall top: ", takeup_z + takeup_flange_r));
assert(tape_x0 + tape_len >= tape_flat_end, str("v45: flat ribbon must reach the leader start: ", tape_x0 + tape_len));
assert(leader_x0 < tape_flat_end, str("v45: leader must overlap the flat ribbon: ", leader_x0));
assert(tape_flat_end <= takeup_x - takeup_flange_r, str("v45: flat ribbon must end before the reel flange (no dangle under/past reel): ", tape_flat_end));
assert(sqrt(pow(leader_x1 - takeup_x, 2) + pow(leader_z1 - takeup_z, 2)) <= tape_pack_r, str("v45: leader end must fuse inside the wound pack: ", sqrt(pow(leader_x1 - takeup_x, 2) + pow(leader_z1 - takeup_z, 2))));
assert(tape_pack_r == takeup_core_r + 3, str("v45: leader pack radius must match the takeup_reel() pack visual: ", tape_pack_r));
// v39/v40 edge-to-edge station gaps (6-turner replaces the plow closer,
// same footprint so the v38 numbers hold; restated on turner_* names):
// turner_end 159 -> twister 180..188 -> take-up 258..290.
// Fail loud, never silent.
assert(turner_start == plow_start && turner_end == plow_end && turner_len == plow_len,
       "v39: 6-turner footprint must equal the plow footprint (compat + clearance inheritance)");
assert(turner_start - drop_x >= 8,
       str("v40: 6-turner mouth must sit a little AFTER the drop point (flat landing first): ", turner_start - drop_x));
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
assert(drum_shaft_y1 >= 66 && drum_shaft_y1 <= 68, str("v45: drum shaft must end hidden in the front block bore: ", drum_shaft_y1));
assert(hex_clearance_r > hex_axle_r, "v45: drum hex bore must slip on the shaft (free spin, no fuse)");
assert(takeup_shaft_y0 >= 0 && takeup_shaft_y0 <= 2, str("v48: take-up shaft must start hidden in the back wall bore (0..2, zero exterior clutter): ", takeup_shaft_y0));
assert(takeup_shaft_y1 >= 66 && takeup_shaft_y1 <= 68, str("v45: take-up shaft must end hidden in the front block bore: ", takeup_shaft_y1));
assert(axle_clearance_dia/2 > axle_dia/2, "v45: reel/wall/block bores must slip on the take-up shaft");
assert(spool_shaft_y0 >= 0 && spool_shaft_y0 <= 2, str("v45: spool shaft must start hidden in the back block bore: ", spool_shaft_y0));
assert(spool_shaft_y1 >= 66 && spool_shaft_y1 <= 68, str("v45: spool shaft must end hidden in the front block bore: ", spool_shaft_y1));
assert(base_thick == 4, "flat chassis floor: base slab must span z=0..4");
// Step-3a fused Γ support invariants: source geometry is intentional and the
// viewer-facing conversion is final X = 371.5 - source X.
assert(twister_axle_reflect_x == 371.5 && twister_support_final_x0 == 196.5
    && twister_support_final_x1 == 202.5
    && twister_support_wall_anchor_final_x == 199.5
    && twister_support_floor_anchor_final_x == 199.5,
    "Step-3a: support source/final X conversion must remain exact");
assert(twister_support_wall_y0 == wall_thick && twister_support_floor_z0 == base_thick,
    "Step-3a: support must contact the fixed wall and floor faces");
assert(twister_support_wall_z1 - twister_support_wall_z0 == 6
    && twister_support_wall_y1 == twister_support_floor_anchor_y
    && twister_support_floor_z1 == twister_support_wall_anchor_z,
    "Step-3a: support legs must meet at the axle center Y34/Z32");
assert(twister_support_wall_pilot_d == 2.5 && twister_support_floor_pilot_d == 2.5
    && twister_support_wall_pilot_y0 == 3 && twister_support_wall_pilot_y1 == 13
    && twister_support_floor_pilot_z0 == 4 && twister_support_floor_pilot_z1 == 10
    && bolt_dia + 2*tolerance == 3.6,
    "Step-3a: local M3 pilot and chassis clearance dimensions must remain exact");
assert(twister_support_x0 < tw_ped_x0 && twister_support_x1 > tw_ped_x1
    && twister_support_floor_y0 <= tw_ped_w/2 + lane_y
    && twister_support_floor_y1 >= lane_y - tw_ped_w/2,
    "Step-3a: support must deliberately overlap the current pedestal/root");
assert(twister_support_x0 < twister_support_x1 && twister_support_final_x0 < twister_support_final_x1,
    "Step-3a: support slice must be a positive source/final envelope");
assert(twister_support_anchor_count == 2
    && twister_support_anchor_source_x == [172, 172]
    && twister_support_wall_anchor_z == twister_axle_z
    && twister_support_floor_anchor_y == lane_y,
    "Step-3a: exactly two local M3 anchors are required");
assert(tw_bore_d == 10 && tw_bore_d < tw_axle_od
    && twister_support_wall_z0 > twister_axle_z - 5
    && twister_support_floor_z1 == twister_axle_z,
    "Step-3a: support must preserve the open Ø10 bore/rotor passage");
assert(twister_support_wall_z0 - (tape_z + tape_thick) >= tolerance,
    "Step-3a: support wall leg must clear the tape top");
assert(twister_support_final_x1 < v98_Bx
    && twister_support_wall_y1 < v97_A_y0
    && twister_support_wall_y1 < v98_B_y0
    && twister_support_wall_y1 < v115_I_y0
    && twister_support_final_x1 < takeup_x - takeup_flange_r,
    "Step-3a: support must clear A/B/idler and take-up envelopes");
assert(twister_support_wall_y1 < 47 && twister_support_floor_z0 >= 0,
    "Step-3a: support must preserve the disconnected south gear-wall rib");
assert(twister_support_m3_x == [196.5, 199.5] && twister_support_legacy_m3_z == 7,
    "Step-3a: obsolete axle-support M3 stations are retired data, not live anchors");
assert($fn == 60 && tolerance == 0.3,
    "Step-3a: $fn60 and tolerance0.3 must remain unchanged");

// Step 2 wall-local interface: matching wall clearance/nut traps, below all
// axle/gear bands, with no screw bosses or pilot holes in the open floor.
assert(wall_screw_x == [chassis_x0 + 20, chassis_x0 + chassis_len - 20],
       "Step 2: wall screw X positions must stay at the two chassis end stations");
assert(wall_screw_x[1] - wall_screw_x[0] >= 200,
       "Step 2: wall screws must be at least 200mm apart");
assert(wall_screw_x[0] > chassis_x0 + 8 && wall_screw_x[1] < chassis_x0 + chassis_len - 8,
       "Step 2: wall screws must stay inside the chassis end margins");
assert(wall_screw_clearance_d == bolt_dia + 2*tolerance && wall_screw_nut_r > bolt_dia/2,
       "Step 2: wall M3 clearance and nut-trap diameters must be consistent");
assert(wall_screw_z < min([spool_axle_z, drum_axle_z, crank_axle_z,
       takeup_z, v97_Az, v98_Bz, v115_Iz, tw_apex_z]),
       "Step 2: wall screws must stay below all axle/gear bands");
assert(nut_trap_depth < wall_thick, "Step 2: wall nut traps must leave a wall web");
assert(south_wall_bore_y > chassis_width - wall_thick && south_wall_bore_y < chassis_width,
       "Step 2: south-wall bearing/gear bores must remain centered in the gear-mount wall");
// Step 1 plow underside interface: exact station, strap/wall clearance,
// and support kept west of the twister apex and B bevel western envelope.
assert(plow_base_screw_x == 132 && plow_base_screw_y == 9,
       "Step 1: plow underside screw must use world (132,9)");
assert((plow_base_screw_y - wall_screw_clearance_d/2) > wall_thick
       && (plow_base_screw_y - wall_screw_nut_r) > wall_thick,
       "Step 1: plow screw hole and nut trap must clear the fixed wall inner face");
assert(((chassis_width/2 - 20) + (-10)) == 4
       && ((chassis_width/2 - 20) + 14) == 28
       && (4 - wall_thick) >= 1.0,
       "Step 1: strap A must span world Y4..28 with a 1.0mm wall gap");
assert(3 - wall_screw_clearance_d/2 >= 1.0
       && ((-5) - (-10) - wall_screw_clearance_d/2) >= 1.0
       && (14 - (-5) - wall_screw_clearance_d/2) >= 1.0,
       "Step 1: strap A must retain 1.0mm X/Y ligaments around the M3 hole");
assert(bolt_head_across <= 6,
       "Step 1: pan head must fit strap A (0.25mm/side accepted)");
assert(tw_apex_x_frame - plow_base_screw_x >= 10,
       "Step 1: plow support must stay >=10mm west of the twister apex");
assert((v98_Bx - 23.75) - plow_base_screw_x >= 10,
       "Step 1: plow support must stay >=10mm west of the B bevel western envelope");
assert(153 == plow_start + 27 && 62 == 14 + 48,
       "Step 1: ear B must retain its world station (153,62)");
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

// Step 6: gentle fold ramp. The S-curve keeps the max wall slope near 20.6
// degrees across the 10mm former span, so the paper is never torn or creased
// sharply. smootherstep(t) = 6t^5 - 15t^4 + 10t^3 on t in [0,1].
function smootherstep(t) = t*t*t*(t*(t*6 - 15) + 10);

// Fold progress along X: 0 = flat ribbon, 1 = full-depth U. Flat before
// former_x0, full after former_x1, smoothstep-eased in between.
function u_shape(X) = (X <= former_x0) ? 0
                    : (X >= former_x1) ? 1
                    : smootherstep((X - former_x0) / (former_x1 - former_x0));

// ============================================================
// The ROLL, as a MORPH of the U section - NOT as a spiral.
// The exact bend pattern of the paper inside the packet is cosmetic; the
// packet ENVELOPE (bore 7.1 / outer 7.9) is what has to be right. So the
// roll is a point-for-point lerp between two centreline POLYLINES with the
// SAME fixed sample count (packet_poly_seg + 1 points):
//   u_poly_point(i)       the existing full U, 25.0 of centreline
//   packet_poly_point(i)  the closed tube, the derived wrap at packet_mean_r
// The strip is then one convex box per cross-section segment per x-station
// (tape_poly_box() in scad/plow.scad): many small convex boxes, never
// hull() (it fattened walls twice in this codebase) and never offset() on a
// 2D section (it produced sliver shells).
// ============================================================

// Fold progress along X for the ROLL: 0 = open full U (seeds still drop in),
// 1 = closed packet. Flat before roll_x0 (the drop), full after roll_x1 (the
// turner mouth), smoothstep-eased in between - the same easing as the U fold,
// so the two ramps have the same wall-slope character.
function u_shape2(X) = (X <= roll_x0) ? 0
                     : (X >= roll_x1) ? 1
                     : smootherstep((X - roll_x0) / (roll_x1 - roll_x0));

// The U centreline sample i (0..packet_poly_seg) in (y, z), local to the
// ribbon. u_poly_seg_wall segments per wall + u_poly_seg_floor along the
// floor puts a sample exactly on each corner, so the miter is not beveled.
function u_poly_point(i) =
      (i <= u_poly_seg_wall)
        ? [-u_wall_cl_y, u_floor_cl_z + u_leg_cl_len - i*u_leg_cl_len/u_poly_seg_wall]
    : (i <= u_poly_seg_wall + u_poly_seg_floor)
        ? [-u_wall_cl_y + (i - u_poly_seg_wall)*u_floor_cl_len/u_poly_seg_floor, u_floor_cl_z]
    : [ u_wall_cl_y, u_floor_cl_z + (i - u_poly_seg_wall - u_poly_seg_floor)*u_leg_cl_len/u_poly_seg_wall];

// The closed packet sample i: the full derived wrap about packet_centre_z.
// DEGREES, not radians, into cos()/sin(): this OpenSCAD (2026.09 nightly) has
// degree-mode trigonometry - cos(90) == 0, which is exactly why the existing
// scroll_sheet() feeds it 0..450. The derivation above stays in RADIANS
// because that is what the 2*PI comparison needs; packet_wrap_deg is the same
// angle in degrees and is the only thing the trig ever sees.
// One chord per segment, so the built tube's outer face is the POLYGON
// through the samples, not the circle - the 0.013 the box-corner check below
// allows for.
function packet_poly_point(i) =
    let (a_deg = i/packet_poly_seg * packet_wrap_deg)
    [ packet_mean_r*cos(a_deg), packet_centre_z + packet_mean_r*sin(a_deg) ];

// The morph itself: same index, both endpoints lerped. The straight tangent
// lap is 0 long (asserted above), so the polyline IS the derived wrap - its
// last 28.07 deg ride on top of its own first turn, which is what seals the
// packet instead of leaving a 1.84mm slit.
function packet_morph_point(i, u) =
    let (a = u_poly_point(i), b = packet_poly_point(i))
    [ a[0] + u*(b[0] - a[0]), a[1] + u*(b[1] - a[1]) ];

// --- the measurement functions the fail-loud checks read -------------------
// Measured off the SAMPLED polyline: the radius of every sample from the
// packet axis. min = bore, max = outer.
function packet_poly_env_r(i) =
    let (p = packet_poly_point(i))
    sqrt(p[0]*p[0] + (p[1] - packet_centre_z)*(p[1] - packet_centre_z));
function packet_poly_env_r_max() = max([for (i = [0:packet_poly_seg]) packet_poly_env_r(i)]);
function packet_poly_env_r_min() = min([for (i = [0:packet_poly_seg]) packet_poly_env_r(i)]);
// Measured off the BUILT boxes, box corners included: a chord of length L
// carries its outer-face corner out to sqrt(r^2 + (L/2 + bite/2)^2), so the
// boxes are fractionally fatter than the sampled circle. THIS is the number
// that has to clear the turner.
function packet_box_seg_len() = packet_wrap_rad*packet_mean_r/packet_poly_seg + packet_seg_bite;
function packet_box_env_r_max() = sqrt(pow(packet_outer_r, 2) + pow(packet_box_seg_len()/2, 2));
// The worst backward step of the morph between neighbouring stations. > 0
// means the roll unrolls somewhere: fail loud.
function roll_morph_max_backstep() = max([for (i = [0:packet_roll_stations - 1])
    u_shape2(roll_x0 + i*(roll_x1 - roll_x0)/packet_roll_stations)
  - u_shape2(roll_x0 + (i + 1)*(roll_x1 - roll_x0)/packet_roll_stations)]);
