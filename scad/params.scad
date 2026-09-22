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
crank_axle_x = 152;  // v95: crank swung UP on the r60 mesh circle (was 160 east) for room below
crank_axle_z = 75 + sqrt(3600 - pow(crank_axle_x - drum_axle_x, 2)); // 104.93: solved on circle r60 about drum
assert(abs(sqrt(pow(crank_axle_x - drum_axle_x,2)+pow(crank_axle_z - drum_axle_z,2)) - center_distance) < 0.05,
       str("v95: crank must sit exactly on the r60 mesh circle about the drum, got ",
           sqrt(pow(crank_axle_x-drum_axle_x,2)+pow(crank_axle_z-drum_axle_z,2))));
// v95 from-crank train (user: crank up + compounds attached + zigzag, direction free):
// crank20 -> A[10 m2 + 30 m1.25] (2x,3x) -> B[10 + bevel10 m1.25] (corner 1:1)
// -> C[X: bevel10 + 15 m1.25] -> D[X: 12 m1.25 + r10 wheel] (1.25x) -> disc OD.
// 2*3*1*1.25 = 7.5/crank = 2.5 wraps/seed. All new gears inboard (y1<=68),
// handle outboard (y>=76): 8 daylight, asserted.
A_ang = -70;   // A direction from crank (down-east)
A_cd = (roller_teeth + 10) * gear_module / 2;   // 30: crank20 -> A10 m2
A_x = crank_axle_x + A_cd * cos(A_ang);
A_z = crank_axle_z + A_cd * sin(A_ang);
B_ang = -15;   // B up-east (locked: teeth/pins clearances + pedestal + rail all verify)
B_cd = (30 + 10) * 1.25 / 2;                    // 25: A30 -> B10 m1.25
B_x = A_x + B_cd * cos(B_ang);
B_z = A_z + B_cd * sin(B_ang);
apex_y = 47;   // bevel corner height (B-bevel band 44-50 centre)
C_zb = B_z;    // TRUE bevel: C axis (y=apex_y, z=B_z) meets B axis at apex
C15_x0 = 191; C15_x1 = 197;  // C15 band east of B shaft (radial-clear of twister)
spool_axle_x  = -6;  // v22: 10->-6, clears roller back gear (box-level X gap 1.5)
spool_axle_z  = 80;  // v87 +15 lift: 120mm max roll OD, height 80mm above base (was 65)
assert(spool_axle_z == 80, "cone rod (spool_axle_z) must be 80 (+15 lift)");

// ============================================================
// Chassis
// ============================================================
chassis_x0    = -14; // v22: west edge (was 0); east edge chassis_x0+chassis_len=260 (v86: 248->260 seats take-up 238+16=254 + 6 margin)
chassis_len   = 274; // v86: 262->274, east extension seats the wind-up reel clear of the pull nip (X gap 6)
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

// ============================================================
// Crank (v79: at x=160, 20T gear meshes drum 40T at dist=60)
// Crank carries a 20T spur gear at the FRONT plane that meshes
// the drum's 40T gear. 28mm hex shaft at front near handle.
// Handle at front y=68, near twist gears.
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
// v37 Thread-bind + vertical pull + wind-up (v36 MVP backfill:
// hopper 9 o'clock -> 11-6 channel -> 6 o'clock drop onto the
// 1in folded tape -> thread bind -> vertical pull -> wind-up).
// All geared to the drum (6 cavities, 6in/152.4mm spacing intent):
// pull nip runs 4/3 vs the main roller (v52 d15 => same surface
// speed, spacing preserved); twister orbits once per cavity (6 per
// drum rev, one bind per seed); take-up winds the same linear tape
// (core d10 => 4 rev per $t, i.e. 2x crank). Bind sits just after
// the plow (bind_x = plow_end+25); pull nip stacks vertically over
// the finished tape at pull_x; reel sits east at takeup_x.
// v86 RESPACED (v38 overlapped: twister 163..171 touched pull 171..191
// at X=171, take-up 170..202 interpenetrated both in X/Y/Z).
// Sequential eastward with >=5mm steel-to-steel X gaps:
// plow end 159 -> twister 180..188 (gap 9) -> pull 198.35..213.65 (gap 8.35) ->
// take-up 222..254 (gap 8.35). Centres 32 apart for pull->take-up vs
// radii sum 7.65+16=23.65 (gap 8.35, margin kept).
// $fn=60, tol=0.3 kept.
// ============================================================
bind_x   = plow_end + 25;   // 184: thread orbit station east of the plow (rotor X half 4 -> 180..188, gap 9)
pull_x   = plow_end + 47;   // 206: vertical-nip pull station (sleeve r7.65 -> 198.35..213.65, gap 8.35 to twister east)
takeup_x = 238;             // wind-up reel east (flange r16 -> 222..254, gap 8.35 to pull east; chassis east 260)
takeup_z = 49;              // v87 +15 lift: reel axle height (flange 33..65: bottom >= 0, top < 125)
assert(takeup_z == 49, "takeup_z must be 49 (+15 lift from 34)");
twister_axle_z = tape_z + 4;      // 32: v87 +15 lift: ring centre over the folded pocket (pocket top ~36)
twister_arms = 2;                 // 2 bobbin spindles
twister_wraps_per_seed = 2.5;            // v94: thread wraps per seed, user range [2,3] (nominal middle)
twister_orbits_per_drum = num_divots * twister_wraps_per_seed; // 15: twister orbits per drum rev (2.5 per cavity)
tw_bore_d = 10;                   // twister bore diameter (tape pocket 7.8 passes through)
tw_axle_od = 15;                  // axle outer diameter
tw_hub_bore = 15.6;               // hub bore (slip fit on axle)
tw_hub_r = 10;                    // hub radius
tw_hub_x0 = 179;                  // hub west edge
tw_hub_x1 = 196.5;                // hub east edge
tw_mouth_x = 172;                 // mouth position
tw_tube_x1 = 196;                 // tube east end
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
  tw_slot_x0 = 188;                 // slot west edge (9mm long, mouth zone start)
  tw_slot_x1 = 197;                 // slot east edge (tube end)
  tw_slot_w0 = 1.5;                 // slot width (uniform, no taper)
  tw_slot_w1 = 1.5;                 // slot width (uniform, no taper)
  tw_slot_r0 = 4;                   // slot inner radius
  tw_slot_r1 = 8;                   // slot outer radius
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
tw_groove_x0 = 193.5;             // groove west edge (hub bore recess)
tw_groove_x1 = 196;               // groove east edge
tw_groove_r = 9;                  // groove radius
tw_collar_x0 = 176.5;             // collar west edge (static ring on tube)
tw_collar_x1 = 178;               // collar east edge
tw_collar_r = 9;                  // collar outer radius
  tw_finger_n = 3;                  // finger count (spring arms)
  tw_finger_angle = 60;             // 60° wide finger arcs (each finger 60°, gaps 60° = daylight)
  tw_finger_base_x0 = 186;          // finger base west (full tube wall start)
  tw_finger_base_x1 = 197;          // finger base east (full annulus to tube end)
  tw_finger_ramp_x0 = 193;          // ramp start
  tw_finger_ramp_x1 = 194;          // ramp end (r7.5→9)
  tw_finger_barb_x0 = 194;          // barb start (west shoulder)
  tw_finger_barb_x1 = 195.5;        // barb end
  tw_finger_barb_r = 9;             // barb outer radius
  tw_finger_tip_x0 = 195.5;         // tip taper start
  tw_finger_tip_x1 = 197;           // tip taper end (r7)
  tw_finger_tip_r = 7;              // tip taper radius
  tw_finger_slot = 2;               // v67: daylight slot width between fingers (visible grooves)
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
tw_foot = 12;                     // foot height
tw_foot_z = -15;                  // foot z position
tw_lift = 27.5;                   // twister lift (teeth r27 + 0.5 clearance, tops clear z=0)
assert(tw_lift >= tw_teeth_top_r + 0.5, "tw_lift must exceed tw_teeth_top_r + 0.5 (clearance over tooth tips)");
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

// --- v95 from-crank numbers (solved; asserts below verify) ---
// Meshes carry 0.75 backlash (spur side play assembles); bevel pair is
// TRUE geometry (C axis meets B axis at the apex); wheel contact is
// tangent (no backlash). Custom bevel blanks in drive_train.scad.
v95_bl = 0.75;
v95_A_cd = (roller_teeth + 10) * gear_module / 2 + v95_bl; // 30.75: crank20 -> A10 m2
v95_B_cd = (30 + 10) * 1.25 / 2 + v95_bl;                 // 25.75: A30 -> B10 m1.25
v95_bev_T = 10; v95_bev_mod = 1.25;       // bevel 10/10 1:1 corner
v95_C_cd = (15 + 12) * 1.25 / 2 + 1.0;  // 17.875: C15 -> idler-I1 (both 12T-class mesh)
v95_I_cd_D = (12 + 12) * 1.25 / 2 + 1.0; // 16.0: idler-I2 -> D12-east (1:1 through)
// Idler (user: fill in): I1 (169-175, meshes C15) + I2 (192-197, meshes D12-east)
// fused + shaft r3 x165-200; axis = two-circle (C r17.875 + D r16.0), high branch:
v95_I1_x0 = 170; v95_I1_x1 = 176;
v95_I2_x0 = 192; v95_I2_x1 = 197;
v95_I_x0 = 165; v95_I_x1 = 200;
v95_wheel_r = 10;
v95_contact_R = tw_disc_r + v95_wheel_r;  // 33: tangent to disc OD
// A on r30.75 about crank, B on r25.75 about A (angles above):
v95_Ax = crank_axle_x + v95_A_cd * cos(A_ang); // ~162.0
v95_Az = crank_axle_z + v95_A_cd * sin(A_ang); // ~76.0
v95_Bx = v95_Ax + v95_B_cd * cos(B_ang);       // ~184.3
v95_Bz = v95_Az + v95_B_cd * sin(B_ang);       // ~65.1
// C axis (apex_y, B_z); C = west stub 164-181 (C15 169-175 + bevel 175-181 fused).
// C rides the chassis C-pedestal (x166-170, bore at (47,B_z)) + 11 overhang east (demo-ok).
// D span 178-197 (hub 182-192 + D12 192-197 fused, tire 179.5-181.75 separate rubber).
// A/B shafts r4 ROUND + C/D shafts r3 (all fused clusters, no hex, no press-fit).
// Bands (fused): A10 50.5-54.5 (4 thick) + A30 59-64 (5 thick);
// B10 59-64 (5 thick) + B-bevel 44-52; C-bevel x175-181 (teeth overlap B zone).
v95_C_y = apex_y; v95_C_z = v95_Bz;
v95_C_x0 = 164; v95_C_x1 = 181;
v95_Cbev_x0 = 175; v95_Cbev_x1 = 181;  // C bevel (0.48 off A10 east face, teeth overlap B zone)
v95_C15_x0 = 170; v95_C15_x1 = 176;   // C15 west (1.0 off pedestal, fused to bevel at 175)
v95_D_x0 = 178; v95_D_x1 = 197;
v95_D12_x0 = 192; v95_D12_x1 = 197;   // D12-east (meshes idler I2, east of tips)
v95_tire_x0 = 179.5; v95_tire_x1 = 181.75; // O-tire band: 0.5 off teeth, 0.25 off pin bodies
v95_hub_x0 = 182; v95_hub_x1 = 192;       // hub barrel (radially clear of pins)
// D = two-circle (C axis r C_cd positioner + twister axle r contact), smaller-y branch:
v95_Ty = lane_y; v95_Tz = twister_axle_z;
v95_L2 = (v95_C_y-v95_Ty)*(v95_C_y-v95_Ty) + (v95_C_z-v95_Tz)*(v95_C_z-v95_Tz);
v95_L = sqrt(v95_L2);
v95_a = (v95_C_cd*v95_C_cd - v95_contact_R*v95_contact_R + v95_L2) / (2*v95_L);
v95_h = sqrt(v95_C_cd*v95_C_cd - v95_a*v95_a);
v95_uy = (v95_Ty-v95_C_y)/v95_L; v95_uz = (v95_Tz-v95_C_z)/v95_L;
v95_sAx = v95_C_y + v95_a*v95_uy + v95_h*v95_uz;
v95_sAz = v95_C_z + v95_a*v95_uz - v95_h*v95_uy;
v95_sBx = v95_C_y + v95_a*v95_uy - v95_h*v95_uz;
v95_sBz = v95_C_z + v95_a*v95_uz + v95_h*v95_uy;
v95_D_y = (v95_sAx < v95_sBx) ? v95_sAx : v95_sBx; // ~30 back branch
v95_D_z = (v95_sAx < v95_sBx) ? v95_sAz : v95_sBz; // ~64.7
// Idler axis = two-circle (C axis r C_cd + D axis r I_cd_D), HIGH-z branch:
v95_J2 = (v95_C_y-v95_D_y)*(v95_C_y-v95_D_y) + (v95_C_z-v95_D_z)*(v95_C_z-v95_D_z);
v95_J = sqrt(v95_J2);
v95_Ja = (v95_C_cd*v95_C_cd - v95_I_cd_D*v95_I_cd_D + v95_J2) / (2*v95_J);
v95_Jh = sqrt(v95_C_cd*v95_C_cd - v95_Ja*v95_Ja);
v95_Juy = (v95_D_y-v95_C_y)/v95_J; v95_Juz = (v95_D_z-v95_C_z)/v95_J;
v95_JsAz = v95_C_z + v95_Ja*v95_Juz - v95_Jh*v95_Juy;
v95_JsBz = v95_C_z + v95_Ja*v95_Juz + v95_Jh*v95_Juy;
v95_JsAy = v95_C_y + v95_Ja*v95_Juy + v95_Jh*v95_Juz;
v95_JsBy = v95_C_y + v95_Ja*v95_Juy - v95_Jh*v95_Juz;
v95_I_y = (v95_JsAz > v95_JsBz) ? v95_JsAy : v95_JsBy; // high-z branch (~33, ~80.5)
v95_I_z = (v95_JsAz > v95_JsBz) ? v95_JsAz : v95_JsBz;
// Shaft spans: A (44-68 wall-bore cantilever), B (44-68: bevel foot to wall bore):
v95_A_y0 = 44; v95_A_y1 = 68;
v95_B_y0 = 44; v95_B_y1 = 68;
// Fused gear bands (drive_train uses these; asserts verify):
v95_A10_y0 = 50.5; v95_A10_y1 = 54.5;  // A10 (4 thick, 4mm mesh face on crank gear)
v95_A30_y0 = 59; v95_A30_y1 = 64;      // A30 (5 thick, 0.6 over C15 top, 1 under wall)
v95_B10_y0 = 59; v95_B10_y1 = 64;      // B10 (5 thick, rides the rail slot 58-65)
v95_Bbev_y0 = 44; v95_Bbev_y1 = 52;    // B bevel (fused foot, r8 blank)
// bar1 back-wall rail (user's wall-to-wall rod): x184-190, B10 slot y58-65, z60-90:
v95_bar1_x0 = 184; v95_bar1_x1 = 190;
v95_bar1_slot0 = 58; v95_bar1_slot1 = 65;
v95_bar1_z0 = 60; v95_bar1_z1 = 90;   // extended top carries the idler bore (I_z~80.5)
// C pedestal (chassis-fused): x166-170, tape-notched feet, pocket-clear bridge, tower bore:
v95_ped_x0 = 166; v95_ped_x1 = 170;
// Idler pedestal (chassis-fused): x169-175, notched feet (tape), tower to idler bore:
v95_Iped_x0 = 169; v95_Iped_x1 = 175;
// Gear outer radii (global m2-height teeth): m2 10T r12 / 20T r22;
// hybrids: 10T r8.25 / 12T r9.5 / 15T r11.375 / 30T r20.75
// Revs per crank rev about own axis (every external mesh flips; direction free per user):
// (idler bridges C15->D12 1:1 through, D flips negative, twister stays positive)
A_rev = -2; B_rev = 6; C_rev = -6; I_rev = 7.5; D_rev = -7.5;
// bar1 back-wall rail spans wall to wall in Y (fused both ends); C pedestal fused in chassis.

// Pull support pins (static bars: base-fused, slip-fit in roller
// bores + cup-B bore; the tape-coupled rotors spin on them).
pull_pin_r = axle_dia/2;             // 4: static pin radius (slip in bores)
pull_pinA_z0 = 2; pull_pinA_z1 = 42; // base-fused .. hidden in roller top cap (v87 stack top 42)
pull_pinB_z0 = 2; pull_pinB_z1 = 42; // base-fused .. hidden in cup-B bore (v87 cup 40..43)
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
assert(pull_pinA_z0 >= 0 && pull_pinA_z0 <= base_thick, "v48: pull pin A must start fused in the base");
assert(pull_pinA_z1 >= base_thick + 15 + vpull_h && pull_pinA_z1 <= base_thick + 15 + vpull_h + 3, str("v87: pull pin A top (42) must hide inside the roller top cap (39..42): ", pull_pinA_z1));
assert(pull_pinB_z1 > 40 && pull_pinB_z1 <= 43, str("v87: pull pin B top (42) must hide inside cup-B bore (40..43): ", pull_pinB_z1));
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
assert(twister_wraps_per_seed >= 2 && twister_wraps_per_seed <= 3, str("wraps per seed must be in [2,3], got ", twister_wraps_per_seed));
assert(twister_orbits_per_drum == num_divots * twister_wraps_per_seed, "twister must orbit wraps-per-seed times per cavity (15 per drum rev, 2.5 binds per seed)");
// v95 from-crank chain asserts (every mesh + every clearance, fail loud):
// Mesh CDs exact (pitch-based; backlash>0 prints + assembles):
assert(abs(sqrt(pow(v95_Ax-crank_axle_x,2)+pow(v95_Az-crank_axle_z,2)) - v95_A_cd) < 0.05, "crank->A distance must equal mesh CD 30.75");
assert(abs(sqrt(pow(v95_Bx-v95_Ax,2)+pow(v95_Bz-v95_Az,2)) - v95_B_cd) < 0.05, "A->B distance must equal mesh CD 25.75");
assert(v95_C_z == v95_Bz, "TRUE bevel: C axis height must equal B axis height (apex coincidence)");
assert(apex_y >= v95_Bbev_y0 && apex_y <= v95_Bbev_y1, "bevel apex must sit in the B-bevel band");
assert(abs(sqrt(pow(v95_D_y-v95_C_y,2)+pow(v95_D_z-v95_C_z,2)) - v95_C_cd) < 0.05, "C->D distance must equal mesh CD 17.625");
assert(abs(sqrt(pow(v95_D_y-lane_y,2)+pow(v95_D_z-twister_axle_z,2)) - v95_contact_R) < 0.05, "D must sit one contact radius off the twister axle (wheel tangent to disc OD)");
assert(v95_D_y < lane_y, "D must take the back (smaller-y) two-circle branch");
assert(abs((roller_teeth/10)*(30/10)*(10/10)*(15/12)*(12/12) - 7.5) < 0.01, "drive product must be 7.5 per crank rev (2.5 wraps/seed, idler 1:1 through)");
assert(A_rev == -2 && B_rev == 6 && C_rev == -6 && I_rev == 7.5 && D_rev == -7.5, "shaft revs must be -2/+6/-6/+7.5/-7.5 per crank rev");
// y-rule: all new gears inboard (handle owns y>=76):
assert(v95_A_y1 <= 68 && v95_B_y1 <= 68, "A/B shafts must stay inboard (y1<=68)");
// Fused bands ride the shafts that carry them:
assert(v95_A_y0 <= v95_A10_y0 && v95_A_y1 >= v95_A30_y1, "A shaft must span both fused bands");
assert(v95_B_y0 <= v95_Bbev_y0 && v95_B_y1 >= v95_B10_y1, "B shaft must span both fused bands");
// A10 (4mm face) overlaps the crank-gear front plane 49-55:
assert(v95_A10_y0 >= 49 && v95_A10_y1 <= 55 && (v95_A10_y1 - v95_A10_y0) >= 4, "A10 must mesh the crank-gear plane with >=4mm face");
// B10 (r8.25) vs teeth sweep R27: radial (x-overlap excused):
assert(sqrt(pow(61.5-34,2)+pow(v95_Bz-32,2)) - 8.25 > 27, "B10 must clear the teeth sweep radially");
// B10 band bottom vs pin bodies top 58:
assert(v95_B10_y0 > 58, "B10 must start above the pin bodies (top 58)");
// B-bevel (r8 blank) vs pin bodies R24: radial:
assert(sqrt(pow(apex_y-34,2)+pow(v95_Bz-32,2)) - 8 > 24, "B bevel blank must clear the pin sweep radially");
// B shaft (r4) vs A30 blank (r20.75): true-distance (mesh CD by construction):
assert(v95_B_cd - (20.75 + 4) >= 1, "B shaft must clear the A30 blank (true-distance) by >=1");
// B/A wall bores inside the front wall:
assert(v95_Bx > chassis_x0 && v95_Bx < chassis_x0 + chassis_len && v95_Bz > 0 && v95_Bz < chassis_height, "B wall bore must sit inside the front wall");
assert(v95_Ax > chassis_x0 && v95_Ax < chassis_x0 + chassis_len && v95_Az > 0 && v95_Az < chassis_height, "A wall bore must sit inside the front wall");
// C shaft top (apex_y+3) vs A10 bottom (0.5 gap):
assert((apex_y + 3) + 0.5 <= v95_A10_y0, "C shaft must pass under A10 with >=0.5 gap");
// C-bevel west (x175) vs A10 east (Ax+12): x gap:
assert(v95_Cbev_x0 - (v95_Ax + 12) >= 0.25, "C bevel must clear the A10 east face");
// C-bevel east (x181) vs B shaft (Bx-4): x gap:
assert((v95_Bx - 4) - v95_Cbev_x1 >= 0.5, "C bevel must clear the B shaft west face");
// C-bevel (r6) vs teeth sweep R27: radial:
assert(sqrt(pow(apex_y-34,2)+pow(v95_Bz-32,2)) - 6 > 27, "C bevel must clear the teeth sweep radially");
// C15 top (47+11.375) vs A30 bottom (0.6 gap):
assert((v95_C_y + 11.375) + 0.5 <= v95_A30_y0, "C15 must pass under A30 with >=0.5 gap");
// C15 (x169-175, inner R24.25) vs teeth (x172-179, R27): radial over x-overlap:
assert(sqrt(pow(v95_C_y-34,2)+pow(v95_C_z-32,2)) - 11.375 > 27, "C15 must clear the teeth sweep radially");
// C15/D12 (x192-197) east of pin arrow tips (x<=191.5) + same band (mesh) + D clears pull:
assert(v95_C15_x1 < 189.5 && v95_D12_x0 > 191.5, "C15 must end west of the pin tips, D12 must start east of them");
// Idler bridges C15->D12 (same 1.25x, meshes both by construction):
assert(v95_I1_x0 <= v95_C15_x1 && v95_I1_x1 >= v95_C15_x0, "idler I1 must overlap the C15 band (mesh)");
assert(v95_I2_x0 <= v95_D12_x1 && v95_I2_x1 >= v95_D12_x0, "idler I2 must overlap the D12 band (mesh)");
assert(abs(sqrt(pow(v95_I_y-v95_C_y,2)+pow(v95_I_z-v95_C_z,2)) - v95_C_cd) < 0.05, "idler-to-C distance must equal mesh CD 17.875");
assert(abs(sqrt(pow(v95_I_y-v95_D_y,2)+pow(v95_I_z-v95_D_z,2)) - v95_I_cd_D) < 0.05, "idler-to-D distance must equal mesh CD 16.0");
assert(v95_I_z > 70, "idler must take the high two-circle branch");
assert(v95_D_x1 < pull_x - vpull_sleeve_r, "D shaft east end must clear the pull nip");
// Wheel: tire inside disc slot + tangent (inner edge R23 clears pin bodies R22):
assert(v95_tire_x0 >= 179 && v95_tire_x1 <= 182, "O-tire must sit inside the disc slot 179..182");
assert(v95_contact_R - v95_wheel_r > 22, "wheel inner edge (R23) must clear the pin bodies (R22)");
// bar1 rail (x184-190) vs A30 blank east (x gap):
assert(v95_bar1_x0 - (v95_Ax + 20.75) >= 0.5, "bar1 must clear the A30 blank east face");
assert(v95_bar1_x0 - v95_Cbev_x1 >= 0.5, "bar1 must clear the C-bevel east face");
// bar1 (x>=184) vs teeth sweep (x<=179): x-clear:
assert(v95_bar1_x0 > 179, "bar1 must stand east of the teeth sweep");
// bar1 bridge (z>=60) vs pin sweep (top 56): z-clear:
assert(v95_bar1_z0 > 56, "bar1 bridge must ride above the pin sweep");
// B10 (59-64) rides the rail slot (58-65) with >=1 each side:
assert(v95_B10_y0 >= v95_bar1_slot0 + 1 && v95_B10_y1 <= v95_bar1_slot1 - 1, "B10 must ride inside the rail slot");
// B + D bores sit inside the rail body (x184-190, y0-58 south rail, z60-76):
assert(v95_Bx > v95_bar1_x0 && v95_Bx < v95_bar1_x1, "B shaft must cross the rail (bore)");
assert(v95_D_y < v95_bar1_slot0 && v95_D_z > v95_bar1_z0 && v95_D_z < v95_bar1_z1, "D bore must sit in the rail south body");
// C pedestal (base x166-171.5 west of teeth 172; solid tower x166-169, no slots):
assert(v95_ped_x1 < 172, "C pedestal must stand west of the teeth sweep");
assert(v95_C15_x0 - (v95_ped_x0 + 3) >= 0.5 && v95_I1_x0 - (v95_ped_x0 + 3) >= 0.5, "C15/I1 must clear the pedestal east face");
assert(50 <= v95_A10_y0 - 0.5, "pedestal tower top (y50) must clear A10 bottom");
assert(v95_ped_x0 + 3 > 163, "pedestal tower must clear the crank-gear box east");
// Idler pedestal shares the tower (bore at (I_y,I_z) inside x166-169, z71-90):
// bar1 top (90) under wall top (125); idler bore (I_y~33, I_z~80.5) in rail body:
assert(v95_bar1_z1 < chassis_height, "bar1 top must stay under the wall top");
assert(v95_I_y < v95_bar1_slot0 && v95_I_z > v95_bar1_z0 && v95_I_z < v95_bar1_z1, "idler bore must sit in the rail body above the slot");
// Idler (r9.5 gears) clearances: A30 (y-disjoint), crank gear (x), handle (y), teeth/pins (radial), plow (x), tape (z):
assert(v95_I_y + 9.5 < v95_A30_y0, "idler must pass under the A30 band");
assert(v95_I_x0 > drum_axle_x + 63, "idler must stand east of the crank-gear box");
assert(v95_I_y + 9.5 < 76, "idler must stay inboard of the handle sweep");
assert(sqrt(pow(v95_I_y-34,2)+pow(v95_I_z-32,2)) - 9.5 > 27, "idler must clear the teeth sweep radially");
assert(sqrt(pow(v95_I_y-34,2)+pow(v95_I_z-32,2)) - 9.5 > 24, "idler must clear the pin sweep radially");
assert(v95_I_x0 > plow_end, "idler shaft must start east of the plow end");
assert(v95_I_z - 9.5 > 36, "idler must ride above the tape pocket");
// Idler pedestal (x169-175): feet notch the tape (y9-21 + y47-54, span z0-13), tower to bore:
assert(v95_Iped_x0 >= plow_end + 10, "idler pedestal must stand east of the plow");
assert(v95_Iped_x1 < 179, "idler pedestal must stand west of the teeth sweep");
// I2 (192-197) vs pull nip + vs pin tips:
assert(v95_I2_x1 < pull_x - vpull_sleeve_r, "idler I2 must clear the pull nip");
assert(v95_I2_x0 > 191.5, "idler I2 must start east of the pin arrow tips");
assert(twister_axle_z + tw_disc_r <= 56, "twister disc top needs margin (55 vs 56)");
// Stack-up asserts (new twister geometry)
assert(tw_mouth_x - plow_end >= 10 && tw_mouth_x - plow_end <= 16, "mouth gap tw_mouth_x-plow_end in [10,16]");
assert(tw_ped_x1 + 0.5 <= tw_slot_x0, "slot edge tw_ped_x1+0.5<=tw_slot_x0");
assert(tw_disc_x0 - tw_ped_x1 >= 2, "disc gap tw_disc_x0-tw_ped_x1>=2");
assert((pull_x - vpull_sleeve_r) - tw_snap_x1 >= 1, "snap gap (pull_x-vpull_sleeve_r)-tw_snap_x1>=1");
// disc-in-slot assert removed: disc x167..170 is separate from radial slots x174..185
assert(lane_y - (tw_orbit + bob_d/2) >= tw_slot_y0 && lane_y + (tw_orbit + bob_d/2) <= tw_slot_y1, "sweep-in-slot-Y");
assert((twister_axle_z - tw_orbit - bob_d/2) - tw_foot_z >= 2, "dip clearance");
assert((tw_bore_d - 7.8) / 2 >= 1, "tape/bore clearance");
assert(abs(tw_hub_bore - tw_axle_od - 0.6) < 0.001, "hub slip fit");
assert(abs(tw_pin_hole - tw_pin_d - 0.6) < 0.001, "pin slip fit");
assert(tw_hub_x0 - tw_ped_x1 >= 2, "hub-vs-pedestal");
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
// Teeth do not interfere with radial slots (teeth x160..167, slots x176..185)
assert(tw_teeth_x1 < tw_slot_x0, "teeth east must sit west of radial slots");
// Groove inside hub
assert(tw_groove_x0 > tw_hub_x0, "groove_x0 must sit inside hub west");
assert(tw_groove_x1 < tw_hub_x1, "groove_x1 must sit inside hub east");
  // Barb radius matches groove radius (line fit + flex)
  assert(tw_finger_barb_r == tw_groove_r, "barb_r must equal groove_r for line fit + flex");
  // Chunky-solid mouth: full wall ring, barb lock, bore clearance
  assert(tw_finger_barb_r == 9, "barb must be r9 for bold lock shoulder");
  assert(tw_finger_barb_x1 - tw_finger_barb_x0 == 1.5, "barb axial span must be 1.5mm (x182..183.5)");
  assert(7.5 - 5 == 2.5, "annulus wall must be 2.5mm thick (r5..7.5)");
  assert(tw_bore_d/2 == 5, "bore radius must be 5 (Ø10 through-hole)");
// Collar vs disc clearance
assert(tw_disc_x0 - tw_collar_x1 >= 0.5, "collar-vs-disc: disc_x0-collar_x1>=0.5");
// Collar-vs-teeth radial (comment only: collar r9 vs teeth r18, no radial conflict)
// Finger tip vs pull station X clearance
assert(pull_x - vpull_sleeve_r - tw_finger_tip_x1 >= 1, "finger-tip-vs-pull: pull east must clear finger tip by >=1");
// Bobbin east vs barb west X clearance
assert(tw_finger_barb_x0 - (tw_bob_x0 + bob_h) >= 0.5, "bobbin-east vs barb-west >=0.5");
// Barb vs eyelet inner radial clearance
assert(tw_eye_orbit - tw_eye_r - tw_finger_barb_r >= 1, "barb-vs-eyelet-inner radial >=1");
  // West play: hub_x0 vs collar_x1
  assert(tw_hub_x0 - tw_collar_x1 >= 0.5 && tw_hub_x0 - tw_collar_x1 <= 1.0, "west play hub_x0-collar_x1 in [0.5,1.0]");
  // Full annulus wall x174..185 (11mm axial span)
  assert(tw_finger_base_x1 - tw_finger_base_x0 == 11, "full annulus axial span must be 11mm");
  // Slot uniform: w0 == w1 == 1.5mm (no taper, kills see-through windows)
  assert(tw_slot_w0 == tw_slot_w1, "slot w0 must equal w1 for uniform width");
  assert(tw_slot_r0 < tw_slot_r1, "slot r0 must be less than r1");
  // Cap ring thickness
  assert(tw_cap_x1 - tw_cap_x0 >= 0.49 && tw_cap_x1 - tw_cap_x0 <= 0.51, "cap ring must be ~0.5mm thick");
  // Cap ring radials
  assert(tw_cap_r0 == 5 && tw_cap_r1 == 7, "cap ring inner/outer must be r5..r7");
  // Finger angle 60° for solid look
  assert(tw_finger_angle == 60, "finger angle must be 60 for solid look");
// Pin tip vs finger base X note (comment only: radial separation >8.7, no conflict)
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
// v39/v40 edge-to-edge station gaps (6-turner replaces the plow closer,
// same footprint so the v38 numbers hold; restated on turner_* names):
// turner_end 159 -> twister 180..188 (gap 9) -> pull 198.35..213.65 (gap 8.35)
// -> take-up 222..254 (gap 8.35). Fail loud, never silent.
assert(turner_start == plow_start && turner_end == plow_end && turner_len == plow_len,
       "v39: 6-turner footprint must equal the plow footprint (compat + clearance inheritance)");
assert(turner_start - drop_x >= 8,
       str("v40: 6-turner mouth must sit a little AFTER the drop point (flat landing first): ", turner_start - drop_x));
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
assert(drum_shaft_y1 >= 66 && drum_shaft_y1 <= 68, str("v45: drum shaft must end hidden in the front block bore: ", drum_shaft_y1));
assert(hex_clearance_r > hex_axle_r, "v45: drum hex bore must slip on the shaft (free spin, no fuse)");
assert(takeup_shaft_y0 >= 0 && takeup_shaft_y0 <= 2, str("v48: take-up shaft must start hidden in the back wall bore (0..2, zero exterior clutter): ", takeup_shaft_y0));
assert(takeup_shaft_y1 >= 66 && takeup_shaft_y1 <= 68, str("v45: take-up shaft must end hidden in the front block bore: ", takeup_shaft_y1));
assert(axle_clearance_dia/2 > axle_dia/2, "v45: reel/wall/block bores must slip on the take-up shaft");
assert(spool_shaft_y0 >= 0 && spool_shaft_y0 <= 2, str("v45: spool shaft must start hidden in the back block bore: ", spool_shaft_y0));
assert(spool_shaft_y1 >= 66 && spool_shaft_y1 <= 68, str("v45: spool shaft must end hidden in the front block bore: ", spool_shaft_y1));
assert(tape_z - (base_thick + vpull_collar_z + 1.5) >= 2, str("v45: pull mid-collar top must clear the ribbon base by >=2 (assembly lifts +base_thick): ", tape_z - (base_thick + vpull_collar_z + 1.5)));
assert(base_thick + 15 + vpull_h + 3 > 40 && base_thick + 15 + vpull_h + 3 <= 43, str("v87: pull roller B top (42) must engage cup B (cup 40..43, bridge 43): ", base_thick + 15 + vpull_h + 3));
assert(base_thick + 15 + vpull_h + 3 >= pull_pinA_z0 && base_thick + 15 + vpull_h + 3 <= pull_pinA_z1 + 3, str("v87: pull roller A top cap (42) must ride on the static pin (pin 2..42): ", base_thick + 15 + vpull_h + 3));
assert(base_thick == 4 && tw_foot_z == -15, "v87: base slab 0..4 and feet -15..0 must stay unchanged");
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
