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
// shaft tips): plate y78-81 over both axes + 4 pillars fused into the front
// wall (y67-80); A/B shafts run to y80 (tips 2 deep in the d8.6 bores).
// Gears (tops 75) stay 3 below the plate; plate top (81) stays under the arm.
v105_wall_x0 = 132; v105_wall_x1 = 222; // extended plate X span (covers fresh A/I/B bores + east support)
v105_wall_z0 = 26;  v105_wall_z1 = 93;  // plate Z span (covers fresh A/I/B bores + supports)
v105_wall_y0 = 78;  v105_wall_y1 = 81;  // plate Y span (3 = wall_thick)
v105_pillar_x = [137];                    // west pillar keeps the fresh A30 sweep clear
v105_pillar_z = [45, 88];               // pillar Z centres
v105_pillar_s = 6;                      // pillar section (6x6, y67-80)
v105_ext_x = [137];                       // z32 extension pillar X centre
v105_ext_z = 32;                        // z32 extension pillar Z centre
v105_east_pillar_x = 217;                 // same-section top support for the extended plate
v105_east_pillar_z = 88;                 // above the fresh B/I gear bands
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
chassis_x0    = -34; // Step10: west -20 (was -14); east edge chassis_x0+chassis_len=270 (west margin for hopper nose, east +10 for takeup)
chassis_len   = 304; // Step10: 274->304 (west -20 + east +10; east edge 270 seats take-up 238+16=254 + 16 margin)
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
bolt_dia        = 3;
bolt_head_across = 5.5;
nut_trap_depth  = 2.5;

// Step 1 flat floor + Step 2 wall-local M3 interface. Both walls carry
// matching clearance holes/nut traps; no bosses or pilot holes occupy the floor.
wall_screw_x = [chassis_x0 + 20, chassis_x0 + chassis_len - 20];
wall_screw_z = 8;
wall_screw_clearance_d = bolt_dia + 2*tolerance;
wall_screw_nut_r = (bolt_head_across + 2*tolerance) / sqrt(3);
south_wall_bore_y = chassis_width - wall_thick/2;
// Step 6 plow ear A lateral north-wall screw interface.
plow_wall_screw_x = plow_start + 6; // world x=132
plow_wall_screw_z = wall_screw_z;   // world z=8
plow_north_wall_y = wall_thick/2;   // wall center y=1.5
plow_wall_ear_embed = wall_thick;   // ear A extends 3mm into y=0..3 wall

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
tape_x0          = -14;   // Step10 DECOUPLED from chassis_x0 (was =chassis_x0): ribbon start fixed at spool approach; chassis west extends to -34 without dragging tape/dip. tape_len stays 234
// v45 WIND-UP LEADER (forensic fix: the flat ribbon used to run UNDER the
// bare reel core with a ~13 gap and dangle 14 past the reel to 256 while
// the viewer scroll slid it +/-63 per rev). Now the flat ribbon ENDS at
// tape_flat_end (220: east of the nip caps 217, west of the reel flange 222)
// and a narrow leader strip (finished folded-tube width 8) climbs from
// the ribbon top onto the wound pack (pack r8 on core r5 at (238,34)),
// ending fused inside the pack silhouette.
tape_flat_end    = 220;
tape_len         = tape_flat_end - tape_x0;   // 234 (was 222: shifted +12 with stations)
leader_x0        = 218;   // leader start (2 overlap onto the flat ribbon)
leader_x1        = 236.5; // leader end (inside the pack silhouette)
leader_z1        = 41.5; // v87 +15 lift: leader end height (pack bottom 41 + 0.5 bite)
leader_w         = 8;     // leader width (finished folded tube, not full 25.4)
tape_z           = 28;           // v87 +15 lift: transit top 36.4, ribbon top 28.4
tape_n_arc       = 20;           // arc facets per side (smooth like $fn=60 curves)
tape_n_x         = 12;           // taper steps along X (progressive entry->exit)

// ============================================================
// v37 Thread-bind + wind-up (v36 MVP backfill):
// hopper 9 o'clock -> 11-6 channel -> 6 o'clock drop -> thread bind
// -> wind-up. Bind sits just after the plow; take-up sits east of it.
// $fn=60, tol=0.3 kept.
// ============================================================
// ============================================================
bind_x   = plow_end + 25;   // 184: thread orbit station east of the plow (rotor X half 4 -> 180..188, gap 9)
takeup_x = 238;             // wind-up reel east (flange r16 -> 222..254, gap 8.35 to pull east; chassis east 260)
takeup_z = 49;              // v87 +15 lift: reel axle height (flange 33..65: bottom >= 0, top < 125)
assert(takeup_z == 49, "takeup_z must be 49 (+15 lift from 34)");
assert(takeup_x > bind_x, str("wind-up reel must sit east of the bind station: ", takeup_x));
twister_axle_z = tape_z + 4;      // 32: v87 +15 lift: ring centre over the folded pocket (pocket top ~36)
twister_arms = 2;                 // 2 bobbin spindles
twister_wraps_per_seed = 2.0;            // v116 Step 2: B -6x -> 1:1 mitre -> twister -6x (2.0 wraps/seed magnitude)
twister_orbits_per_drum = num_divots * twister_wraps_per_seed; // 12: twister orbits per drum rev (2.0 per cavity)
tw_bore_d = 10;                   // twister bore diameter (tape pocket 7.8 passes through)
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
assert(tape_bend_radius >= 1 && tape_bend_radius <= 6,
       str("tape_bend_radius out of envelope [1,6]: ", tape_bend_radius));
assert(tape_fold_angle > 0 && tape_fold_angle <= 180,
       str("tape_fold_angle out of envelope (0,180]: ", tape_fold_angle));
assert(fold_width/2 + tape_bend_radius + tape_thick <= (paper_width + 2*tolerance)/2,
       str("tape fold must fit the inner half-width 13: ", fold_width/2 + tape_bend_radius + tape_thick));
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
// idler gear (outer ~r11) clears pillar0 (x134-140, z42-48) by >=1:
assert((v115_Ix - 11) - (v105_pillar_x[0]+3) >= 1, "idler gear must clear pillar0");
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
// relief keeps >=1 wall to the tape bore:
assert(tw_relief_r0 - 7.8 >= 1, "relief must keep >=1 wall to the tape bore");
// B shaft east surface (Bx+4) clears the twister toe plane by >=1.5:
assert((v98_Bx + 4) - (tw_apex_x_frame - 22.5 - tw_bev_face*cos(45)) >= 1.5, "B shaft must clear the framed twister toe plane");
// B parts (bottom y54) clear the pedestal/foot top Y edge (Step-8 foot to lane_y+7=41):
assert(v98_B_y0 - (lane_y + 7) >= 1, "B shaft must clear the pedestal foot in y");
// B shaft bottom vs plow exit flare (axis (159,34,32), r10.5 worst case):
assert(sqrt(pow(v98_Bx-159,2)+pow(v98_B_y0-34,2)) - 10.5 >= 1.0, "B shaft must clear the plow exit flare");
// Step 5 outboard wall asserts: A tip 2 deep in the plate bore (78-81);
// B tip stays below the plate (outboard open until the next step):
assert(v97_A_y1 == 83 && v98_B_y1 == 80, "v117: A tip 2 proud of the plate (83); B tip 2 deep in the plate bore (80)");
// gear tops (75) stay 3 below the plate (78):
assert(v97_A30_y1 <= v105_wall_y0 - 2 && v98_B10_y1 <= v105_wall_y0 - 2,
       "A30/B10 must stay below the outboard plate");
// plate top (81) stays under the crank-arm sweep (88):
assert(v105_wall_y1 <= crank_mount_y + crank_arm_gap - 5, "outboard plate must stay below the arm");
// The fresh level crank is relieved through the extended plate by a
// positive hex clearance bore in dt_gearwall().
assert(v105_wall_z1 >= v97_Az + 2, "outboard plate must still cover the fresh A bore");
// west pillars (6x6 at x137, z45/88, y67-80) clear the fresh A30 sweep (r20.75) by >=1:
assert(sqrt(pow((v105_pillar_x[0]+3)-v97_Ax,2)+pow((v105_pillar_z[1]-3)-v97_Az,2)) >= 21.75
    && sqrt(pow((v105_pillar_x[0]+3)-v97_Ax,2)+pow((v105_pillar_z[0]+3)-v97_Az,2)) >= 21.75
    && sqrt(pow((v105_east_pillar_x+3)-v97_Ax,2)+pow((v105_east_pillar_z-3)-v97_Az,2)) >= 21.75
    && sqrt(pow((v105_east_pillar_x-3)-v97_Ax,2)+pow((v105_east_pillar_z+3)-v97_Az,2)) >= 21.75,
       "outboard pillars must clear the A30 sweep");
// plate covers pillars + bores with >=2 edge:
assert(v105_wall_x0 <= v105_pillar_x[0]-3 && v105_wall_x1 >= v105_east_pillar_x+3
    && v105_wall_z0 <= v105_pillar_z[0]-3 && v105_wall_z1 >= v105_pillar_z[1]+3,
       "outboard plate must cover pillars and bores");
// wall bores slip on the r4 shafts:
assert(axle_clearance_dia > 8, "outboard wall bores must slip on the r4 shafts");
// v117 Step 2: plate lowered (z0 26) covers the z32 row — extension
// pillars + re-added B slip bore, each with >=2 plate edge:
assert(v105_wall_x0 + 2 <= v105_ext_x[0] - 3
    && v105_wall_z0 + 2 <= v105_ext_z - 3,
       "outboard plate must cover the extension pillars with >=2 edge");
assert(v105_wall_x0 + 2 <= v98_Bx && v98_Bx <= v105_wall_x1 - 2
    && v105_wall_z0 + 2 <= v98_Bz,
       "outboard plate must cover the B slip bore with >=2 edge");
// B10 (outer r8.25) vs extension pillar corners (140,35)/(184,35):
assert(sqrt(pow(v105_ext_x[0] + 3 - v98_Bx, 2) + pow(v105_ext_z + 3 - v98_Bz, 2)) - 8.25 >= 1,
       "B10 must clear the extension pillars (true-distance)");
// idler gear (outer r11, pillar half-diag 4.3) vs the same corners:
assert(sqrt(pow(v105_ext_x[0] + 3 - v115_Ix, 2) + pow(v105_ext_z + 3 - v115_Iz, 2)) - 11 - 4.3 >= 1,
       "idler gear must clear the extension pillars (true-distance)");
// east extension pillar clears the twister heel pitch x177.5 by >=1:
assert(67 - (lane_y + tw_disc_r) >= 1, "z32 extension pillars must clear the twister radial envelope in Y");
assert(v105_wall_x0 + 2 <= v105_east_pillar_x - 3 && v105_east_pillar_x + 3 <= v105_wall_x1 - 2
     && v105_wall_z0 + 2 <= v105_east_pillar_z - 3, "extended plate must cover the east support pillar");
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
assert((tw_bore_d - 7.8) / 2 >= 1, "tape/bore clearance");
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
// turner_end 159 -> twister 180..188 -> take-up 222..254.
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
// Step 6 plow north-wall interface: centered M3 hole, wall material around it,
// and support kept west of the twister apex and B bevel western envelope.
assert(plow_wall_screw_x == plow_start + 6 && plow_wall_screw_z == wall_screw_z,
       "Step 6: plow wall screw must use world x=132, z=8");
assert(plow_north_wall_y == wall_thick/2 && plow_wall_ear_embed == wall_thick,
       "Step 6: plow ear must engage the north wall through its full 3mm thickness");
assert(bolt_dia + 2*tolerance == 3.6
       && plow_wall_screw_z - (bolt_dia + 2*tolerance)/2 > 0
       && chassis_height - (plow_wall_screw_z + (bolt_dia + 2*tolerance)/2) > 0,
       "Step 6: plow wall M3 clearance must leave wall material above and below");
assert(tw_apex_x_frame - plow_wall_screw_x >= 10,
       "Step 6: plow support must stay >=10mm west of the twister apex");
assert((v98_Bx - 23.75) - plow_wall_screw_x >= 10,
       "Step 6: plow support must stay >=10mm west of the B bevel western envelope");
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
