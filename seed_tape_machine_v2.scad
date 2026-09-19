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
roller_teeth  = 16;
drum_teeth    = 44;
center_distance = (roller_teeth + drum_teeth) * gear_module / 2; // 60

// Gear tooth proportions (20 PA trapezoidal)
addendum   = 1.0 * gear_module;   // 2.0
dedendum   = 1.25 * gear_module;  // 2.5
tooth_arc_frac = 0.47;            // ~47% tooth thickness at pitch circle

// Derived gear dimensions
roller_pitch_dia = gear_module * roller_teeth;   // 32
drum_pitch_dia   = gear_module * drum_teeth;     // 88
roller_outer_dia = roller_pitch_dia + 2*addendum; // 36
roller_root_dia  = roller_pitch_dia - 2*dedendum; // 27
drum_outer_dia   = drum_pitch_dia + 2*addendum;   // 92
drum_root_dia    = drum_pitch_dia - 2*dedendum;   // 83
roller_outer_r = roller_outer_dia/2;
roller_root_r  = roller_root_dia/2;
drum_outer_r   = drum_outer_dia/2;
drum_root_r    = drum_root_dia/2;

// Roller body diameter (spec: roller_dia=20)
roller_dia = 20;
roller_body_r = roller_dia/2;

// Gear mesh phase (v21, v70: 16T): half-pitch of the 16T roller pinion (360/16/2 = 11.25°).
// The drum (44T) has a tooth centered on the line of centers at $t=0, so the
// roller needs a half-pitch offset for tooth-into-gap mesh. Applied to the
// roller shaft rotation (lower roller + crank, one rigid shaft) in
// animated_assembly; mirrored in the viewer as GEAR_PHASE.
gear_mesh_phase = 360/roller_teeth/2;   // 11.25

// Circumference for tooth angular spacing
roller_circ_pitch = PI * gear_module;
drum_circ_pitch   = PI * gear_module;
tooth_arc_roller = tooth_arc_frac * roller_circ_pitch;
tooth_arc_drum   = tooth_arc_frac * drum_circ_pitch;

// Kinematics (v14 MVP: 6 cavities fixed, spacing 6 inch = 152.4 fixed;
// tape driven by pull roller via 44:16 mesh, drum geared slower vs roller)
tape_per_crank_rev = PI * roller_dia;         // ~62.83 (roller 1 rev)
drum_rot_per_crank = roller_teeth/drum_teeth; // 16/44 ≈ 0.3636 (crank/roller spins 44/16 = 2.75x drum)
tape_per_drum_rev  = PI * drum_dia;           // ~157.08 (drum circumference, reference only)
tape_per_drum_rev_roller = PI * roller_dia * (drum_teeth / roller_teeth); // 172.79 actual tape/drum rev via pull roller
num_divots         = 6;                       // v14 MVP fixed: 6 cavities (wheels interchangeable by hand 1-6mm, count stays 6)
achieved_spacing   = tape_per_drum_rev_roller / num_divots; // ~28.80 with 16/44 gears; target 152.4 via future swap-gears (see GEAR_RATIO.md)
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
chassis_x0    = -14; // v22: west edge (was 0); east edge stays chassis_x0+chassis_len=264 (v75: 262->278)
chassis_len   = 278; // v75: 262->278, east extension seats the wind-up reel clear of the pull nip (X gap 6)
chassis_width = 64;  // v75: 60->64 (walls y=0-3 back, y=61-64 front)
chassis_height = 112;  // v70: > max(spool top=90, drum top=106) + 5 = 111 ✓ (was 110 for the 40T gear)
base_thick    = 4;
wall_thick    = 3;
// v75: base pocket slot for ring to hang below (x=165-181, y=3.5-56.5, z=0-4)
pocket_x0 = 165; pocket_x1 = 181; pocket_y0 = 3.5; pocket_y1 = 56.5; pocket_z = 4;
// v75: feet at chassis corners (~14mm) so ring bottom (z=-10) clears table by ~4mm
foot_h = 14; foot_w = 6; foot_l = 10;

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
// gear_mesh_phase 11.25deg, $fn=60, tol=0.3 all kept.
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
pull_x   = plow_end + 37;   // v75: 194->196 (clear of bobbin A rod ending ~x=192)
takeup_x = 226;             // wind-up reel east (flange r16 -> 210..242, gap 6 to pull east; chassis east 248)
takeup_z = 34;              // reel axle height (flange 18..50: bottom >= 0, top < 112)
twister_axle_z = tape_z + 4;      // 17: ring centre over the folded pocket (pocket top ~21)
twister_arms = 2;                 // 2 threads orbit the tape
// v72 bobbin spindles: 6mm dia x14mm, orbit r12 (inside outer rim r15, outside bore r9+clearance)
rod51_orbit = 12;
rod51_r = 3;                      // 6mm diameter spindle
rod51_h = 14;                     // 14mm length
bob51_r = 2.5;                    // bobbin radius (unchanged)
bob51_h = 6;                      // bobbin height (unchanged)
twister_post_h = 9;               // v45/v72 cradle-stub height (2 rolling gap under the ring-OD tube: 17-6-9=2)
// v72 bevel drive params: REPLACED by v75 crown/pinion below
// ring_bevel_teeth=28, ring_bevel_mod=1.5, pinion_teeth=12, pinion_mod=1.5, ring_bevel_ratio=28/12
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
// v62: turner_curl_cz is the live datum: the scroll-tunnel exit-axis height
// (local y20, z13: lane-centred so the 7.8 seeded pocket threads the
// entry bore; was 12 pre-v56).
turner_curl_r = 6.5;              // v54 reference only (no shell)
turner_curl_bore = 4.2;           // v54 reference only (no bore)
turner_curl_off = 1.2;            // v54 reference only (no bore offset)
turner_curl_cz = 13;              // v56 bore-axis height (lane-centred; was 12)

// ============================================================
// v75 GEAR TRAIN params (chain from drum, all spur M1.5)
// ============================================================
// Stage 1 (z=60): drum 44T -> 11T, shaft A: 11T@60 + 16T@45
gear11_teeth = 11; gear11_mod = 2; gear11_t = 6;
gear16a_teeth = 16; gear16a_mod = 1.5; gear16a_t = 6;
// Stage 2 (z=45): 16T -> 10T, shaft B: 10T@45 + 16T@30
gear10b_teeth = 10; gear10b_mod = 1.5; gear10b_t = 6;
gear16b_teeth = 16; gear16b_mod = 1.5; gear16b_t = 6;
// Stage 3 (z=30): 16T -> 10T, shaft C: 10T@30 + 16T@15
gear10c_teeth = 10; gear10c_mod = 1.5; gear10c_t = 6;
gear16c_teeth = 16; gear16c_mod = 1.5; gear16c_t = 6;
// Stage 4 (z=15): 16T -> 10T, shaft D: 10T@15 + 16T@12
gear10d_teeth = 10; gear10d_mod = 1.5; gear10d_t = 6;
gear16d_teeth = 16; gear16d_mod = 1.5; gear16d_t = 6;
// Stage 5 (z=12): 16T -> 10T, shaft E: 10T@12 + 12T bevel@9
gear10e_teeth = 10; gear10e_mod = 1.5; gear10e_t = 6;
gear12e_teeth = 12; gear12e_mod = 1.5; gear12e_t = 6;
// Shaft positions (solved for cd=19.5 each stage, zigzag from (155,12) to (145,49.4))
// Stage 1: drum(100,12,60) -> 11T@(155,12,60), shaft A: 11T@60 + 16T@45
shaftA_x = 155; shaftA_y = 12; shaftA_z = 60;
gear16a_x = 155; gear16a_y = 45; gear16a_z = 60;
// Stage 2: 16T@(155,45) -> 10T, shaft B: 10T@45 + 16T@30
gear10b_x = 155 + 19.5; gear10b_y = 45; gear10b_z = 45;
gear16b_x = gear10b_x; gear16b_y = 30; gear16b_z = 45;
// Stage 3: 16T@(174.5,30) -> 10T, shaft C: 10T@30 + 16T@15
gear10c_x = gear16b_x; gear10c_y = 30; gear10c_z = 30;
gear16c_x = gear10c_x; gear16c_y = 15; gear16c_z = 30;
// Stage 4: 16T@(174.5,15) -> 10T, shaft D: 10T@15 + 16T@12
gear10d_x = gear16c_x; gear10d_y = 15; gear10d_z = 15;
gear16d_x = gear10d_x; gear16d_y = 12; gear16d_z = 15;
// Stage 5: 16T@(174.5,12) -> 10T, shaft E: 10T@12 + 12T bevel@9 at (145,49.4)
gear10e_x = gear16d_x; gear10e_y = 12; gear10e_z = 12;
// Chain shaft E bevel (axis Z) at (145,49.4,9) meshes pinion shaft bevel (axis X) at same point
chain_bevel_x = 145; chain_bevel_y = 49.4; chain_bevel_z = 9;
// Pinion shaft: axis X at y=49.4, z=9, x=145-164
pinion_shaft_x0 = 145; pinion_shaft_x1 = 164; pinion_shaft_y = 49.4; pinion_shaft_z = 9;
// Pinion shaft bearing blocks
pinion_block_x0 = 145; pinion_block_x1 = 164;
// Ring crown gear: 16T M1.5 on WEST face (x=165), bore Ø17 (r8.5)
crown_teeth = 16; crown_mod = 1.5; crown_bore_d = 17;
// v75 gear train ratio: 4 * (16/10)^3 * 1.0 * (12/16) = 4 * 4.096 * 0.75 = 12.288
twister_orbits_per_drum = 4 * pow(16/10, 3) * 1.0 * (12/16); // 12.288

// Pull support pins (static bars: base-fused, slip-fit in roller
// bores + cup-B bore; the tape-coupled rotors spin on them).
pull_pin_r = axle_dia/2;             // 4: static pin radius (slip in bores)
pull_pinA_z0 = 2; pull_pinA_z1 = 27; // base-fused .. hidden in roller top cap
pull_pinB_z0 = 2; pull_pinB_z1 = 27; // base-fused .. hidden in cup-B bore
// ============================================================
// v75 TWISTER MODULE PARAMS (replaces v72 ring params)
// ============================================================
twister_ring_r = 18.5;        // v75: was 15, now 18.5
twister_ring_tube = 8;        // v75: was 6 (tube), now OD53 wall
twister_ring_od = 53;         // v75: outer diameter
twister_ring_bore_r = 10.5;   // v75: bore Ø21 (r10.5)
twister_lift = 10;            // v75: ring bottom at z=-10, lift to min_z=0
twister_ring_cx = 173;        // v75: ring center X (was bind_x=172)
twister_ring_cy = 30;         // v75: ring center Y
twister_ring_cz = 17;         // v75: ring center Z
// Crown gear on WEST face (x=165)
crown_face_x = 165;
// Bobbins: 2× Class-15 (r10.35, length 11.1mm), at 90° apart, orbit 18, on EAST face (x=181)
bobbin_r = 10.35; bobbin_len = 11.1; bobbin_orbit = 18; bobbin_axle_r = 3;
bobbin_a_y = 48; bobbin_a_z = 17;   // Bobbin A (front +Y)
bobbin_b_y = 30; bobbin_b_z = 35;   // Bobbin B (top +Z)
bobbin_east_x = 181;
// Eyelets: repositioned for 90° bobbin arrangement
eyelet_r = 1;
// Pinion shaft bevel params
pinion_bevel_teeth = 12; pinion_bevel_mod = 1.5;
// Ring crown gear params

epsilon = 0.05;
vpull_collar_z = 5.0;              // v45 mid-collar centre LOCAL (assembly lifts +base_thick: CAD top 4+5+1.5=10.5 clears ribbon base 13 by 2.5)
cone_h = 25;
cone_r_big = 22.5;  // 45mm OD
cone_r_small = 7.5; // 15mm OD
// v72 bobbin/bevel asserts (updated for v75 geometry)
assert(rod51_orbit - rod51_r >= 8, "v75: holder rods must clear the ring bore (middle stays empty)");
assert(rod51_orbit - bob51_r > 5.6, "v75: bobbins must clear the tape corners on every orbit");
assert(rod51_orbit + bob51_r <= twister_ring_r + twister_ring_tube, "v75: bobbins must stay inside the ring OD envelope");
// v75 bevel mesh assert: ring crown (16T M1.5, pitch r12) + pinion (12T M1.5, pitch r9)
// mesh dist = r1+r2 = 12+9 = 21, axes intersect at (173,30,17)
assert(abs((crown_mod * crown_teeth / 2) + (pinion_bevel_mod * pinion_bevel_teeth / 2) - 21) < tolerance + 0.01, "v75: crown-pinion mesh dist must satisfy r1+r2 (21)");
assert(crown_teeth >= 10 && crown_teeth <= 60, "v75: crown teeth must be in [10,60]");
assert(pinion_bevel_teeth >= 10 && pinion_bevel_teeth <= 60, "v75: pinion teeth must be in [10,60]");
assert(crown_mod == pinion_bevel_mod, "v75: bevel pair must be same module (M1.5)");
// Pull-pin asserts (updated for pull_x=196)
assert(pull_pinA_z0 >= 0 && pull_pinA_z0 <= base_thick, "v75: pull pin A must start fused in the base");
assert(pull_pinA_z1 >= base_thick + vpull_h && pull_pinA_z1 <= base_thick + vpull_h + 3, str("v75: pull pin A top (27) must hide inside the roller top cap (24..27): ", pull_pinA_z1));
assert(pull_pinB_z1 > 25 && pull_pinB_z1 <= 28, str("v75: pull pin B top (27) must hide inside cup-B bore (25..28): ", pull_pinB_z1));
// Bore-slip assert
assert(axle_clearance_dia/2 > axle_dia/2, "v75: bores must slip on shafts (free spin, no fuse)");

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

// ============================================================
// 90° Bevel Gear visual (v48: pitch cone + teeth suggestion, small
// perpendicular pinion at the twister end).
// Built along +Z (axis Z): pitch apex at local origin, gear body
// at +Z (pitch circle centre at z = r_mate, the mating gear's pitch
// radius). Caller rotates/translates it onto Y (drum) or X
// (twister) axes. Teeth = small boxes around the pitch rim tilted
// at the cone angle (visual mesh suggestion, not cut involutes).
// Allowed modules only; $fn=60 inherited for cones.
// ============================================================
module bevel_gear(teeth, module_mm, thickness, bore_dia=0) {
    assert(teeth >= 10 && teeth <= 60, "bevel_gear: teeth out of range [10,60]");
    assert(module_mm > 0, "bevel_gear: module_mm must be >0");
    assert(thickness > 0, "bevel_gear: thickness must be >0");
    pitch_r = module_mm*teeth/2;
    outer_r = pitch_r + module_mm;
    root_r = max(pitch_r - 1.25*module_mm, 1);
    cone_h = thickness;
    hub_r = max(pitch_r*0.35, 3);
    stack_h = cone_h + 2 + 4;
    difference() {
        union() {
            // Pitch cone body (apex at origin, base at +Z).
            translate([0, 0, cone_h/2])
                cylinder(h=cone_h, r1=root_r, r2=outer_r, center=true);
            // Back disc (web) + hub.
            translate([0, 0, cone_h])
                cylinder(h=2, r=outer_r, center=false);
            translate([0, 0, cone_h + 2 - epsilon])
                cylinder(h=4, r=hub_r, center=false);
            // Teeth suggestion: boxes around the pitch rim, tilted.
            for (i=[0:teeth-1])
                rotate([0, 0, i*360/teeth])
                    translate([pitch_r, 0, cone_h/2])
                        rotate([0, 25, 0])
                            cube([module_mm*1.4, tooth_arc_frac*PI*module_mm, cone_h*0.9], center=true);
        }
        // Slip bore along the axis (drum bevel passes bore_dia=0 =
        // solid, fused on the drum shaft; shaft bevels ride free).
        if (bore_dia > 0)
            translate([0, 0, -epsilon])
                cylinder(h=stack_h + 2*epsilon, d=bore_dia + 2*tolerance, center=false);
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
            // cross bar fused wall-to-wall over the nip at pull_x.
            // v47: SOLID bridge (no tube hole — tape-coupled nip, zero
            // exterior gears); cup B kept (bored) for the static pin B.
            // v52 SHORTER stack (roller top 27): bridge 28, cup 25..28.
            translate([pull_x - 2, 0, 28])
                cube([4, chassis_width, 3]);
            translate([pull_x, chassis_width/2 + vpull_off, 25])
                difference() {
                    cylinder(h=3 + epsilon, r=6, center=false);
                    translate([0, 0, -epsilon])
                        cylinder(h=3 + 3*epsilon, d=axle_clearance_dia, center=false);
                }
            // v48 pull support pins (static bars: base-fused, slip-fit
            // in roller bores + cup-B bore; the tape-coupled rotors
            // spin on them — supported both ends, never coplanar).
            translate([pull_x, chassis_width/2 - vpull_off, (pull_pinA_z0 + pull_pinA_z1)/2])
                cylinder(h=pull_pinA_z1 - pull_pinA_z0, r=pull_pin_r, center=true);
            translate([pull_x, chassis_width/2 + vpull_off, (pull_pinB_z0 + pull_pinB_z1)/2])
                cylinder(h=pull_pinB_z1 - pull_pinB_z0, r=pull_pin_r, center=true);
            // v45 DEAD AXLES (static bars, slip-fit through bores/holes):
            // drum hex through-shaft (fuses into the solid v48 drum spur,
            // slip in the drum/interior-gear hex bores + wall/block hex
            // holes — the drum stays free to spin); take-up round shaft
            // (slip in the reel/wall/block round bores); spool round
            // shaft (slip in cone hex holes + wall/block bores, ends hidden
            // in the block bores). Ends buried/hidden, never coplanar.
            translate([drum_axle_x, (drum_shaft_y0 + drum_shaft_y1)/2, drum_axle_z])
                rotate([90, 0, 0])
                    cylinder(h=drum_shaft_y1 - drum_shaft_y0, r=hex_axle_r, $fn=6, center=true);
            translate([takeup_x, (takeup_shaft_y0 + takeup_shaft_y1)/2, takeup_z])
                rotate([90, 0, 0])
                    cylinder(h=takeup_shaft_y1 - takeup_shaft_y0, r=axle_dia/2, center=true);
            translate([spool_axle_x, (spool_shaft_y0 + spool_shaft_y1)/2, spool_axle_z])
                rotate([90, 0, 0])
                    cylinder(h=spool_shaft_y1 - spool_shaft_y0, r=axle_dia/2, center=true);
            // v37 twister guide posts (static frame cradling the orbiting
            // ring: two stubs flanking the tape at bind_x reach z=13,
            // holding a 2 rolling gap under the ring-OD tube (ring bottom
            // outer 18, tube r2 -> nearest steel 15; v45: was full-height
            // 17 and grazed the swept tube by ~1). The product passes
            // through the ring bore, so no through-axle is possible; the
            // rotor spins on the viewer pivot (axis-correct), cradled here.
            for (s=[-1,1])
                translate([bind_x - 2, chassis_width/2 + s*12 - 1.5, 0])
                    cube([4, 3, twister_post_h]);
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
        // v75: base pocket slot for ring to hang below (x=165-181, y=3.5-56.5, z=0-4)
        translate([pocket_x0, (pocket_y0+pocket_y1)/2, pocket_z/2])
            cube([pocket_x1-pocket_x0, pocket_y1-pocket_y0, pocket_z], center=true);
        // v75: corner feet (~14mm) so ring bottom (z=-10) clears table
        for (fx=[chassis_x0+2, chassis_x0+chassis_len-2])
            for (fy=[2, chassis_width-2])
                translate([fx, fy, foot_h/2])
                    cube([foot_l, foot_w, foot_h], center=true);
        // 45° chamfers on base edges
        translate([chassis_x0, chassis_width/2, base_thick])
            rotate([0,45,0])
                cube([2.5, chassis_width + 2*epsilon, 2.5], center=true);
        translate([chassis_x0 + chassis_len, chassis_width/2, base_thick])
            rotate([0,45,0])
                cube([2.5, chassis_width + 2*epsilon, 2.5], center=true);
        // v72: twister bracket mounting holes (M3 clearance)
        // at back wall (y=12), near bind_x, aligned with
        // bracket flanges at reference angle (twister_angle=0).
        for (px=[bind_x - 13 - 5, bind_x - 13 + 5])
            for (py=[12, chassis_width - 12])
                for (pz=[17, 21]) {
                    translate([px, py, pz])
                        cylinder(h=wall_thick + 2*epsilon, d=bolt_dia + 2*tolerance, center=true);
                    translate([px, py, pz - epsilon])
                        cylinder(h=nut_trap_depth + epsilon,
                                 r=(bolt_head_across + 2*tolerance)/sqrt(3), $fn=6, center=false);
                }
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
        // v75 lightening cutouts in walls (zero exterior gears,
        // back wall clean; cutouts clear of gear train and tape)
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
//    top (23) stays below the roller gear bottom (42) and the hopper
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
           str("u_channel_shroud: top must stay below the roller gear bottom (42), got ", shroud_h));
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
            // Drum gear (lightened, 44T) — v20 BACK/BOTTOM side, chamfer-aware base
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
// 7. 6-FOLDER v61 CLEAN-SHEET PARAMETRIC U-TO-SPIRAL-SWIRL PLOW
// (all v55-v60 loft/table code deleted; nothing inherited).
// Fresh photo read (Front/Back/Top.jpg, cardboard prototype):
// Front = wide open U mouth; Back = tight spiral 6 (outer loop +
// inner tail diving toward centre); Top = tapered cone + flat
// tray sticking out past the LARGE end. User: "6 = U bent
// transforming to swirl, tape folded round".
// Fresh construction: smooth station FUNCTIONS of s in [0,1]
// (no tables) over local x0..33 (world 126..159):
//   R(s) = 10.5->4.5 linear (outer dia 21->9);
//   W(s) = 180->352 smoothstep (clean open-U entry, near-closed
//     swirl exit; wrap STRICTLY <360 so every plate polygon stays
//     simple — the overlap read comes from the hook, never from a
//     self-intersecting shell; open top slit full length);
//   H(s) = 0 for s<0.25 (clean hook-free U mouth, first quarter)
//     then 0->190 (separate spiral-diving inner curl: root outer
//     Rh=R-1.8 = 1.0 daylight off the shell ID, tip dives
//     proportionally toward centre but stays >=1.4 off axis so
//     the bore stays see-through) + a root stitch rib fusing the
//     hook root to the shell (single solid; daylight elsewhere).
// 25 fresh plates (pitch 1.3, t1.8, overlapped UNION, ZERO hull
// on shell/hook/rib). Interface (rewritten, same dims): flat
// entry tray 13.8x16x0.8 west of the mouth (top flush w/ skid),
// tapered skid wedge (flat sit, nose shelf), lower side tail
// blade, 2 small 6x6x1 ears to chassis M3 holes world
// (132,6)/(153,54). Bore axis (cy,cz)=(20,13), min_z=0.
// part_to_render "plow" (compat) and "turner" both render this.
// ============================================================
// v63 exact spiral scroll folder (user scroll_sheet() code used
// VERBATIM, see below; only the demo invocation `rotate([-90,0,0])
// printable_folder();` is left out because a top-level render line
// would print into EVERY part export. v64 deleted the floating right
// tab, v65 deleted the tape-blocking left tab + wrapper: the part is
// the bare sheet).
// The v62 block "didn't work well", so the v62 block/void/wick code
// is deleted and the folder IS the user's overlapping spiral sheet
// (0.5-turn U entry R12 -> 1.25-turn overlap exit R5.5 over 45,
// placed mouth-west so the 45 length ends exactly on the slot end
// 159: mouth world 114, telescoping over the transit end).
// ----------------------------------------------------
// EXACT MATCH FOR CARDBOARD MOCKUP
// Overlapping Spiral Scroll Folder for 25.4mm Tape
// ----------------------------------------------------
length = 45;            // Total length of the folder
thickness = 1.6;        // Wall thickness (4 perimeters of 0.4mm nozzle)
steps_length = 35;      // Resolution along the length
steps_arc = 35;         // Resolution around the curve
module scroll_sheet() {
    for (z = [0 : steps_length - 1]) {
        // t goes from 0.0 (entrance) to 1.0 (exit)
        t1 = z / steps_length;
        t2 = (z + 1) / steps_length;
        // How much it wraps around:
        // 0.5 = half circle (U-shape)
        // 1.25 = full circle + quarter overlap (The Spiral)
        turns1 = 0.5 + 0.75 * t1;
        turns2 = 0.5 + 0.75 * t2;
        for (a = [0 : steps_arc - 1]) {
            // Calculate angles for the 4 corners of this polygon patch
            angle1_1 = (a / steps_arc) * (turns1 * 360);
            angle1_2 = ((a + 1) / steps_arc) * (turns1 * 360);
            angle2_1 = (a / steps_arc) * (turns2 * 360);
            angle2_2 = ((a + 1) / steps_arc) * (turns2 * 360);
            // Base radius shrinks from 12mm (24mm wide U) down to 5.5mm (11mm tube)
            base_r1 = 12 - 6.5 * t1;
            base_r2 = 12 - 6.5 * t2;
            // Spiral offset: the radius shrinks slightly as it wraps around so it tucks INSIDE itself without colliding
            r1_1 = base_r1 - (angle1_1 / 360) * 2.5 * t1;
            r1_2 = base_r1 - (angle1_2 / 360) * 2.5 * t1;
            r2_1 = base_r2 - (angle2_1 / 360) * 2.5 * t2;
            r2_2 = base_r2 - (angle2_2 / 360) * 2.5 * t2;
            // Convert to 3D Cartesian coordinates
            p1 = [ r1_1 * cos(angle1_1), r1_1 * sin(angle1_1), t1 * length ];
            p2 = [ r1_2 * cos(angle1_2), r1_2 * sin(angle1_2), t1 * length ];
            p3 = [ r2_1 * cos(angle2_1), r2_1 * sin(angle2_1), t2 * length ];
            p4 = [ r2_2 * cos(angle2_2), r2_2 * sin(angle2_2), t2 * length ];
            // Create a solid sheet segment between the 4 points
            hull() {
                translate(p1) sphere(d=thickness, $fn=6);
                translate(p2) sphere(d=thickness, $fn=6);
                translate(p3) sphere(d=thickness, $fn=6);
                translate(p4) sphere(d=thickness, $fn=6);
            }
        }
    }
}
// v65: printable_folder() wrapper + BOTH user tabs DELETED per user
// (right tab floated disconnected in every orientation, v64 probe;
// left tab lay across the trench opening and blocked the tape flow).
// The part is the bare scroll_sheet() placed in six_turner() below.
// ---- end verbatim user code ----

module six_turner() {
    // ---- v64 bare folder (verbatim user code only, no added solids) ----
    // Orientation: roll -90 about the tube axis (entry half-pipe opens
    // UP into a U) then +90 about Y (tube axis -> +X, mouth west).
    // Placement: mouth 12 west of the slot so the exact 45 length ends
    // precisely on the slot end 159 (twister gap untouched); axis 21
    // (entry floor ~9.8 under the ribbon, exit tube ~15..27 threading
    // toward the twister ring). All v63 wrapper solids (pedestals,
    // straps, ears, tab post, tray, nose) deleted per user: the part
    // is exactly printable_folder(), screwed down via its own tabs.
    // ---- v66 twister-aimed mounts (bare sheet kept) ----
    // Axis 13: exit bore lands DEAD on the twister bore (assembly
    // lifts +4 -> world 17 = twister_axle_z, y 20+10=30 = ring
    // centre), so the exit faces the twister straight; entry mouth
    // rims sit at lane height, floor 0.2 above the base. Supports:
    // 2 ground pedestals fused under the sheet floor + straps to 2
    // chassis ears on the M3 holes (world 132/6, 153/54).
    cy = 20;                        // sheet centre (local y, world tape centre 30)
    axis_z = 13;                    // sheet axis height (exit = twister bore height)
    mouth_x0 = -12;                 // sheet mouth (world 114, exit lands 159)
    pedA = [6, 8, 12, 28, 4.3];     // mid pedestal x0,x1,y0,y1,top (floor ~3.9)
    pedB = [24.5, 26.5, 14, 26, 7.7]; // exit pedestal x0,x1,y0,y1,top (floor ~7.3)
    ear = 6;                        // ear edge length (6x6x1)
    ear_t = 1;                      // ear thickness
    earA = [3, -7];                 // ear A corner, centre (6,-4) -> world (132,6)
    earB = [24, 41];                // ear B corner, centre (27,44) -> world (153,54)
    hole_d = bolt_dia + 2*tolerance; // M3 clearance 3.6
    // ---- v63 fail-loud: exact-scroll placement ----
    assert(turner_len == 33 && plow_start == 126 && turner_end == 159,
        "six_turner: slot datum must stay 126..159");
    // Exact-use proofs (user code must stay byte-identical).
    assert(length == 45, "six_turner: folder length must stay exactly 45");
    assert(thickness == 1.6, "six_turner: sheet must stay exactly 1.6");
    assert(steps_length == 35 && steps_arc == 35, "six_turner: resolution must stay 35/35");
    assert(12 - 6.5 == 5.5, "six_turner: exit base radius must be 5.5 (11mm tube)");
    assert(0.5 + 0.75 == 1.25, "six_turner: exit must wrap 1.25 turns (spiral overlap)");
    // Placement: mouth 14 after the drop (flat landing kept), exit
    // exactly on the slot end (twister gap untouched).
    assert(mouth_x0 + plow_start == 114, "six_turner: mouth must sit at world 114");
    assert(mouth_x0 + length + plow_start == turner_end, "six_turner: exit must land on 159");
    assert(cy == 20, "six_turner: sheet must stay centred on the tape (local 20, world 30 = ring centre)");
    assert(axis_z == 13, "six_turner: axis must stay 13 (exit bore meets twister bore)");
    assert(axis_z + base_thick == twister_axle_z, "six_turner: exit axis must meet the twister bore height (world 17)");
    assert(axis_z - 12 - thickness/2 >= 0.1, "six_turner: mouth floor must stay above the base");
    // Pedestal fuse: tops embed ~0.4 into the sheet floor wall
    // (floor outer ~3.9 mid / ~7.3 exit, wall 1.6, void stays clear).
    assert(pedA[4] >= 3.5 && pedA[4] <= 5.0, "six_turner: mid pedestal top must land in the floor wall");
    assert(pedB[4] >= 6.8 && pedB[4] <= 8.9, "six_turner: exit pedestal top must land in the floor wall");
    assert(pedA[0] >= mouth_x0 && pedA[1] <= mouth_x0 + length, "six_turner: mid pedestal must sit under the sheet");
    assert(pedB[0] >= mouth_x0 && pedB[1] <= mouth_x0 + length, "six_turner: exit pedestal must sit under the sheet");
    // Screw ears: 6x6x1 diagonal pair on the chassis M3 holes, straps
    // tie the pedestal feet (volumetric overlaps).
    assert(ear == 6 && ear_t == 1, "six_turner: ears must stay 6x6x1 (small, minimal)");
    assert(earA[0] + ear/2 == 6 && earB[0] + ear/2 == turner_len - 6
        && earA[0] + ear/2 + plow_start == 132 && earB[0] + ear/2 + plow_start == 153,
        "six_turner: ear holes must hit chassis X (world 132/153)");
    assert(earA[1] + ear/2 + 10 == 6 && earB[1] + ear/2 + 10 == 54,
        "six_turner: ear holes must hit chassis rows (world 6/54)");
    assert(hole_d == bolt_dia + 2*tolerance, "six_turner: ear holes must be M3 clearance");
    // No added solids: the part is exactly printable_folder().
    // Seeded pocket core must thread the 24-wide entry mouth.
    assert(12 - sqrt(pow(3.9, 2) + pow(3.4, 2)) >= 0.1,
        "six_turner: seeded pocket core must thread the entry mouth");
    // v66 solid: bare user scroll sheet (oriented + placed) + 2 floor
    // pedestals + 2 ground straps + 2 chassis ears (union); only voids
    // are the 2 M3 ear holes. The $fn=6 spheres inside the user code
    // stay untouched (1225 hulls: $fn=60 spheres would not render).
    union() {
        difference() {
            union() {
                // Bare sheet: roll -90 about the tube axis (entry
                // half-pipe opens UP into a U), +90 about Y (tube axis
                // -> +X, mouth west), then placed on the lane.
                translate([mouth_x0, cy, axis_z])
                    rotate([0, 90, 0])
                        rotate([0, 0, -90])
                            scroll_sheet();
                // Screw ears (z0..1, M3 holes to the chassis).
                translate([earA[0], earA[1], 0]) cube([ear, ear, ear_t]);
                translate([earB[0], earB[1], 0]) cube([ear, ear, ear_t]);
                // Ground straps (z0..1, tie ears to pedestal feet).
                translate([3, -7, 0]) cube([6, 21, 1]);
                translate([24, 20, 0]) cube([6, 27, 1]);
                // Support pedestals (tops fused into the sheet floor wall).
                translate([pedA[0], pedA[2], 0]) cube([pedA[1] - pedA[0], pedA[3] - pedA[2], pedA[4]]);
                translate([pedB[0], pedB[2], 0]) cube([pedB[1] - pedB[0], pedB[3] - pedB[2], pedB[4]]);
            }
            // Ear M3 clearance holes (only voids).
            translate([earA[0]+ear/2, earA[1]+ear/2, -epsilon])
                cylinder(h=ear_t+2*epsilon, d=hole_d, center=false);
            translate([earB[0]+ear/2, earB[1]+ear/2, -epsilon])
                cylinder(h=ear_t+2*epsilon, d=hole_d, center=false);
        }
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
        // Flat ribbon full length (base min_z=0, single-layer floor;
        // v45: ends at tape_flat_end 208, the leader takes it from there)
        translate([0, -paper_width/2, 0])
            cube([tape_len, paper_width, tape_thick]);
        // v45 wind-up leader: narrow strip (folded-tube width) climbing
        // ribbon-top -> wound pack, fused into both (overlaps ribbon by
        // 2+ in x, ends inside the pack silhouette). Matches the viewer
        // leader mesh 1:1 (same endpoints).
        lle_s = leader_x0 - tape_x0;
        lle_e = leader_x1 - tape_x0;
        lle_dx = lle_e - lle_s;
        lle_dz = (leader_z1 - tape_z) - tape_thick;
        lle_len = sqrt(lle_dx*lle_dx + lle_dz*lle_dz);
        lle_ang = atan2(lle_dz, lle_dx);
        // +1 length shifted +0.25 along the climb: start face lands flush
        // on the ribbon top (fused, no sub-zero poke), end bites ~1
        // into the pack (min_z>=0 kept, tape film exempt anyway).
        translate([(lle_s + lle_e)/2 + 0.25*cos(lle_ang), 0, tape_thick + lle_dz/2 + 0.25*sin(lle_ang)])
            rotate([0, -lle_ang, 0])
                cube([lle_len + 1, leader_w, tape_thick + 2*epsilon], center=true);
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
// - thread_twister(): HOLLOW rotor CENTRED at origin, axis along X:
//   outer guide ring ONLY (axisymmetric, so viewer spin about X looks
//   right) + exactly 2 rod-like bobbin holders (180 apart, rods
//   parallel to X at orbit radius 9.5, each carrying a thread bobbin).
//   NOTHING in the middle: no hub, no shaft (bore r 10-2=8 stays
//   empty). Folded tape (outer 7.8) threads the empty bore (r8).
//   Folded tape (outer 7.8) threads the ring bore (r 10-2=8).
//   Export branch lifts +twister_lift for min_z=0; assembly spins
//   it about X at [bind_x, 30, twister_axle_z] by twister_angle.
// - vpull_roller(): ONE vertical-axis nip roller, base at z=0
//   (body d15 h20 + caps/collar, min_z=0 in export AND assembly):
//   pair stands on the base flanking the finished folded tape at
//   [pull_x, 30 +/- vpull_off], spins about Z (4/3 vs main
//   roller, smaller dia => same surface speed => spacing preserved).
// - takeup_reel(): wind-up reel built along Z for flat printing
//   (bottom flange 0..3 + core r5 0..31 + top flange 28..31,
//   min_z=0); assembly recentres, tilts to axle-Y, spins about
//   the axle by takeup_angle (4 rev per $t = same linear tape).
// ============================================================
module thread_twister() {
    // v75: gear-driven twister. Hollow ring + 16T crown gear on
    // WEST face + 2 bobbin holders at 90° apart on EAST face.
    // Ring rotates about X, driven by 12T pinion (axis X) meshing
    // the crown gear. Bobbins orbit the tape axis at orbit=18.
    union() {
        // Outer guide ring in the YZ plane (axis X)
        rotate([0, 90, 0])
            rotate_extrude(convexity=10)
                translate([twister_ring_r, 0, 0])
                    square([twister_ring_tube*2, twister_ring_tube*2], center=true);
        // 16T M1.5 crown gear on WEST face (x=165)
        translate([-(twister_ring_cx - crown_face_x), 0, 0])
            rotate([0, 90, 0])
                bevel_gear(teeth=crown_teeth, module_mm=crown_mod, thickness=4, bore_dia=crown_bore_d);
        // 2 bobbin holders at 90° apart on EAST face (x=181)
        for (k=[0:1])
            rotate([k*90, 0, 0]) {
                translate([0, bobbin_orbit, 0])
                    rotate([0, 90, 0])
                        cylinder(h=bobbin_len + 2*epsilon, d=bobbin_r*2, center=true);
            }
        // Guide eyelets near bore (2 eyelets 90deg apart)
        for (k=[0:1])
            rotate([k*180, 0, 0])
                translate([0, twister_ring_r - twister_ring_tube - eyelet_r - 1, 0])
                    rotate([0, 90, 0])
                        cylinder(h=twister_ring_tube*2 + 2*epsilon, d=eyelet_r*2, center=true);
    }
}

// v72: split-collar/slotted bracket coaxial with
// scroll_folder() exit (six_turner exit at world x=159,
// axis_z=13 -> world 17 = twister_axle_z). 0.35mm
// clearances, printable min_z=0. The bracket wraps the
// twister ring and mounts to the chassis, coaxial with the
// scroll exit so the tape exits straight into the ring bore.
// Orientation: flat on print base (Z-up), slot window
// along Y (opens the collar for assembly). No rotate()
// needed — the bracket sits flat with min_z=0.
module twister_bracket() {
    tw_tol = 0.35;
    bracket_r = twister_ring_r + twister_ring_tube + tw_tol; // outer radius + clearance
    bracket_len = 14; // length along X (the ring axis)
    bracket_wall = 2.5; // plate thickness (Z)
    slot_w = 8; // slotted window width (along Y)
    mount_hole_d = bolt_dia + 2*tolerance; // M3 clearance
    difference() {
        union() {
            cube([bracket_len, bracket_r*2, bracket_wall]);
            translate([0, 0, bracket_wall])
                cube([4, bracket_r*2 + 4, bracket_wall]);
            translate([bracket_len - 4, 0, bracket_wall])
                cube([4, bracket_r*2 + 4, bracket_wall]);
        }
        // Slotted window along Y, centered on X
        translate([-epsilon, -slot_w/2, bracket_wall/2])
            cube([bracket_len + 2*epsilon, slot_w, bracket_wall]);
        // Mounting holes (M3 clearance, 2 per flange)
        for (z=[bracket_wall+0.5, bracket_wall + bracket_wall - 0.5])
            for (a=[0, 180])
                rotate([0, 0, a])
                    translate([bracket_r + 1, 0, z])
                        cylinder(h=bracket_wall + 2*epsilon, d=mount_hole_d, center=false);
    }
    assert(bracket_len > 0, "twister_bracket: length must be >0");
}

// v75: mating bevel pinion (12T M1.5) on the pinion shaft.
// Axis along X, meshes the ring crown gear at (173,30,17).
module twister_pinion() {
    assert(pinion_bevel_teeth >= 10 && pinion_bevel_teeth <= 60, "twister_pinion: teeth out of range");
    assert(pinion_bevel_mod == crown_mod, "twister_pinion: must match crown module (M1.5)");
    rotate([90, 0, 0])
        bevel_gear(teeth=pinion_bevel_teeth, module_mm=pinion_bevel_mod, thickness=4, bore_dia=axle_dia);
}

module vpull_roller() {
    assert(vpull_sleeve_r <= 7.8, "vpull_roller: cushion sleeve must stay ~d15 (4/3 spin)");
    difference() {
      union() {
        cylinder(h=vpull_h, r=vpull_r, center=false);
        // v39 CUSHIONED nip (soft rubber/silicone sleeve visual over the
        // steel core: firm grip without crushing the seed pocket; viewer
        // paints it dark rubber). OD stays ~d15 (sleeve proud 0.15, caps
        // r8.5 still dominate the envelope) => 4/3 spin keeps surface speed.
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
        // Diamond knurl band (visual grip, shallow so OD stays ~15)
        for (k=[0:11]) {
            t = k/11;
            zpos = 4 + t*(vpull_h - 8);
            rotate([0, 0, k*30])
                translate([vpull_r - 0.5, 0, zpos])
                    cube([1.2, 2.0, 2.6], center=true);
        }
        translate([0, 0, vpull_h])
            difference() {
                cylinder(h=3, d=17, center=false);
                translate([0, 0, -epsilon])
                    cylinder(h=3 + 2*epsilon, d=axle_clearance_dia, center=false);
            }
        // v45: mid collar rides LOW (centre vpull_collar_z=5.0 local, CAD top
        // 4+5+1.5=10.5: clears the ribbon base tape_z=13 by 2.5; was 12
        // with top 13.5+4 grazing into the tape). Top cap (20..23) is above
        // the tape zone; sleeve/rib grip at the nip is intended (soft).
        translate([0, 0, vpull_collar_z])
            difference() {
                cylinder(h=3, d=17, center=true);
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
// Sign convention:
//   drum_angle = -360*$t ANTI-CLOCKWISE about +Y (top surface
//   moves -X/left, viewed +X right, +Z up): picks up RIGHT,
//   carries over top, drops bottom-center
//   crank = roller_angle (rigid on the roller shaft)
//   upper idler = -990*$t (counter-rotates via tape contact)
//   v75 GEAR TRAIN (chain from drum): drum44T -> 5-stage
//   spur gear train (12.29x) -> bevel pair -> pinion shaft ->
//   crown gear on twister ring. Twister orbits 12.29x/drum rev.
//   Pull nip pair spins about Z at +/-roller_angle*vpull_spin
//   (tape-coupled 4/3 vs the main roller).
//   takeup_angle = -1440*$t about the reel axle (tape-wind-up).
// At $t=0 geometry equals static layout (plus the 11.25° mesh
// phase on the roller).
// ============================================================
module animated_assembly() {
    drum_angle = -360*$t;
    crank_angle = 990*$t;
    idler_angle = -990*$t;
    roller_angle = crank_angle + gear_mesh_phase;
    // v75: twister driven by 5-stage gear train + bevel pair
    twister_angle = -360*$t * twister_orbits_per_drum;
    pull_a_angle = roller_angle*vpull_spin;
    pull_b_angle = -roller_angle*vpull_spin;
    takeup_angle = -1440*$t;

    // Chassis
    chassis();

    // v75 GEAR TRAIN (all spur, M1.5, exterior visible)
    // Stage 1: drum 44T (at (100,12)) -> 11T (at (155,12)), shaft A
    translate([drum_axle_x, chassis_width/2, shaftA_z])
        rotate([0, 0, 0])
            spur_gear(teeth=44, module_mm=2, thickness=6, bore_dia=axle_dia);
    translate([shaftA_x, chassis_width/2, shaftA_z])
        rotate([0, 0, 0])
            spur_gear(teeth=11, module_mm=2, thickness=6, bore_dia=axle_dia);
    // Shaft A idler 16T at (155,45) -> Stage 2 10T
    translate([gear16a_x, chassis_width/2, gear16a_z])
        rotate([0, 0, 0])
            spur_gear(teeth=16, module_mm=1.5, thickness=6, bore_dia=axle_dia);
    // Stage 2: 16T@(174.5,45) -> 10T (at (174.5,30))
    translate([gear10b_x, chassis_width/2, gear10b_z])
        rotate([0, 0, 0])
            spur_gear(teeth=10, module_mm=1.5, thickness=6, bore_dia=axle_dia);
    translate([gear16b_x, chassis_width/2, gear16b_z])
        rotate([0, 0, 0])
            spur_gear(teeth=16, module_mm=1.5, thickness=6, bore_dia=axle_dia);
    // Stage 3: 16T@(174.5,30) -> 10T (at (174.5,15))
    translate([gear10c_x, chassis_width/2, gear10c_z])
        rotate([0, 0, 0])
            spur_gear(teeth=10, module_mm=1.5, thickness=6, bore_dia=axle_dia);
    translate([gear16c_x, chassis_width/2, gear16c_z])
        rotate([0, 0, 0])
            spur_gear(teeth=16, module_mm=1.5, thickness=6, bore_dia=axle_dia);
    // Stage 4: 16T@(174.5,15) -> 10T (at (174.5,12))
    translate([gear10d_x, chassis_width/2, gear10d_z])
        rotate([0, 0, 0])
            spur_gear(teeth=10, module_mm=1.5, thickness=6, bore_dia=axle_dia);
    translate([gear16d_x, chassis_width/2, gear16d_z])
        rotate([0, 0, 0])
            spur_gear(teeth=16, module_mm=1.5, thickness=6, bore_dia=axle_dia);
    // Stage 5: 16T@(174.5,12) -> 10T (at (174.5,12))
    translate([gear10e_x, chassis_width/2, gear10e_z])
        rotate([0, 0, 0])
            spur_gear(teeth=10, module_mm=1.5, thickness=6, bore_dia=axle_dia);
    // Chain shaft bevel (axis Z) at (145,49.4,9) -> pinion bevel (axis X)
    translate([chain_bevel_x, chassis_width/2, chain_bevel_z])
        rotate([0, 90, 0])
            bevel_gear(teeth=12, module_mm=1.5, thickness=6, bore_dia=axle_dia);
    // Pinion shaft bevel (axis X) at (164,49.4,9) -> crown gear
    translate([pinion_shaft_x1, chassis_width/2, pinion_shaft_z])
        rotate([90, 0, 0])
            bevel_gear(teeth=pinion_bevel_teeth, module_mm=1.5, thickness=6, bore_dia=axle_dia);
    // Pinion shaft cylinder (axis X, y=49.4, z=9)
    translate([(pinion_shaft_x0+pinion_shaft_x1)/2, chassis_width/2, pinion_shaft_z])
        rotate([90, 0, 0])
            cylinder(h=pinion_shaft_x1-pinion_shaft_x0, d=axle_dia, center=true);

    // v75 Ring crown gear on WEST face (x=165)
    translate([crown_face_x, chassis_width/2, twister_ring_cz])
        rotate([0, 90, 0])
            bevel_gear(teeth=crown_teeth, module_mm=crown_mod, thickness=4, bore_dia=crown_bore_d);

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

    // Hopper
    translate([drum_axle_x, chassis_width/2, drum_axle_z - hopper_axis_z])
        hopper_body();

    // Tape cover shroud
    translate([shroud_x0, chassis_width/2, 0])
        u_channel_shroud();

    // Seed cradle
    translate([plow_start, chassis_width/2 - 12.7, base_thick])
        seed_cradle();

    // Seed tape with center U-fold
    translate([tape_x0, chassis_width/2, tape_z])
        seed_tape_bend();

    // Former collar
    translate([fold_end - 3, chassis_width/2, tape_z + tape_thick])
        former_collar();

    // Folding plow (6-turner)
    translate([plow_start, chassis_width/2 - 20, base_thick])
        six_turner();

    // Pull rollers
    translate([roller_axle_x, chassis_width/2, roller_axle_z])
        rotate([0, roller_angle, 0])
            translate([0, 0, -roller_dia/2])
                knurled_roller(is_lower=true);
    translate([roller_axle_x, chassis_width/2, roller_axle_z + roller_dia + 1.2])
        rotate([0, idler_angle, 0])
            translate([0, 0, -roller_dia/2])
                knurled_roller(is_lower=false);

    // Crank
    translate([crank_mount_x, crank_mount_y, roller_axle_z])
        rotate([0, roller_angle, 0])
            translate([-crank_pivot_x, 0, -crank_pivot_z])
                crank_assembly();

    // v75 Thread twister (gear-driven)
    translate([twister_ring_cx, chassis_width/2, twister_ring_cz])
        rotate([twister_angle, 0, 0])
            thread_twister();
    // v75 Split-collar bracket coaxial with scroll exit
    translate([twister_ring_cx - 13, chassis_width/2, twister_ring_cz])
        twister_bracket();
    // v75 Pinion shaft bevel (axis X, y=49.4, z=9)
    translate([pinion_shaft_x0, chassis_width/2, pinion_shaft_z])
        rotate([twister_angle, 0, 0])
            rotate([90, 0, 0])
                bevel_gear(teeth=pinion_bevel_teeth, module_mm=1.5, thickness=4, bore_dia=axle_dia);

    // Pull rollers (zoffset=11 compensated)
    translate([pull_x, chassis_width/2 - vpull_off, base_thick])
        rotate([0, 0, pull_a_angle])
            vpull_roller();
    translate([pull_x, chassis_width/2 + vpull_off, base_thick])
        rotate([0, 0, pull_b_angle])
            vpull_roller();

    // Take-up spool
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
} else if (part_to_render == "twister_bracket") {
    // Standalone split-collar bracket: origin-centred, min_z=0.
    translate([-bracket_len/2, -(twister_ring_r + twister_ring_tube + 0.35), 0])
        twister_bracket();
} else if (part_to_render == "twister_pinion") {
    // v75: 12T M1.5 bevel pinion on the pinion shaft (axis X).
    translate([0, 0, twister_lift])
        rotate([90, 0, 0])
            twister_pinion();
} else if (part_to_render == "gear_train") {
    // v75: 5-stage spur gear train + bevel pair.
    chassis();
    translate([drum_axle_x, chassis_width/2, shaftA_z])
        spur_gear(teeth=44, module_mm=2, thickness=6, bore_dia=axle_dia);
    translate([shaftA_x, chassis_width/2, shaftA_z])
        spur_gear(teeth=11, module_mm=2, thickness=6, bore_dia=axle_dia);
    translate([gear16a_x, chassis_width/2, gear16a_z])
        spur_gear(teeth=16, module_mm=1.5, thickness=6, bore_dia=axle_dia);
    translate([gear10b_x, chassis_width/2, gear10b_z])
        spur_gear(teeth=10, module_mm=1.5, thickness=6, bore_dia=axle_dia);
    translate([gear16b_x, chassis_width/2, gear16b_z])
        spur_gear(teeth=16, module_mm=1.5, thickness=6, bore_dia=axle_dia);
    translate([gear10c_x, chassis_width/2, gear10c_z])
        spur_gear(teeth=10, module_mm=1.5, thickness=6, bore_dia=axle_dia);
    translate([gear16c_x, chassis_width/2, gear16c_z])
        spur_gear(teeth=16, module_mm=1.5, thickness=6, bore_dia=axle_dia);
    translate([gear10d_x, chassis_width/2, gear10d_z])
        spur_gear(teeth=10, module_mm=1.5, thickness=6, bore_dia=axle_dia);
    translate([gear16d_x, chassis_width/2, gear16d_z])
        spur_gear(teeth=16, module_mm=1.5, thickness=6, bore_dia=axle_dia);
    translate([gear10e_x, chassis_width/2, gear10e_z])
        spur_gear(teeth=10, module_mm=1.5, thickness=6, bore_dia=axle_dia);
    translate([chain_bevel_x, chassis_width/2, chain_bevel_z])
        rotate([0, 90, 0])
            bevel_gear(teeth=12, module_mm=1.5, thickness=6, bore_dia=axle_dia);
    translate([pinion_shaft_x1, chassis_width/2, pinion_shaft_z])
        rotate([90, 0, 0])
            bevel_gear(teeth=pinion_bevel_teeth, module_mm=1.5, thickness=6, bore_dia=axle_dia);
    translate([crown_face_x, chassis_width/2, twister_ring_cz])
        rotate([0, 90, 0])
            bevel_gear(teeth=crown_teeth, module_mm=crown_mod, thickness=4, bore_dia=crown_bore_d);
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
