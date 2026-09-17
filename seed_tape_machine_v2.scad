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
// v54: the outer-shell params below are REFERENCE ONLY (shell deleted).
// turner_curl_cz stays the live datum: the wing curl-axis height.
turner_curl_r = 6.5;              // v54 reference only (no shell)
turner_curl_bore = 4.2;           // v54 reference only (no bore)
turner_curl_off = 1.2;            // v54 reference only (no bore offset)
turner_curl_cz = 12;              // curl axis height above the turner base (v54 live datum)

// ============================================================
// v53 OVERHEAD twister drive (user: duplicate drum gear + bottom
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
// Centres: C_Y = I53 - r_x*Y = (cx,35.5,44);
// C_X = I53 + r_y*X = (cx+12,45.5,44).
// Pull/takeup stay tape-coupled (no gears, documented, zero
// exterior clutter). Stations/gaps untouched (turner lip 160.35 ->
// twister gap 7.65, gaps >= 5). Speeds (rev per crank rev):
// crank +1, drum -0.5, counter +2.0 (about Y), twister -3 (about X),
// pull +4/3 (about Z, tape-coupled), takeup +2 (about Y, tape/clutch).
// vpull cushioned (v39): soft rubber/silicone sleeve visual over the
// steel core (v52 OD stays ~d15 => 4/3 spin keeps surface speed), firm grip without crushing.
// ============================================================
// v53 OVERHEAD take-off (duplicate 50T DELETED; takeoff reuses the
// EXISTING drum40 gear, y 9..15 back plane). Module 2 single,
// teeth all in [10,60]. Ratio (40/10)*(12/10)*(15/12) = 6.0.
drive53_mod = 2;
// Stage 1 (parallel spur Y-Y): drum40 (r40 at (100,60)) -> overhead
// counter 10T (r10) at (cx,44): dist = 50 = 40+10, same Y plane.
cnt53_Zc = 10;
cnt53_rd = gear_module*drum_teeth/2;   // 40 (existing drum40, reused)
cnt53_rc = drive53_mod*cnt53_Zc/2;     // 10
cnt53_cz = 44;   // overhead: bottom 44-12=32 clears tape top 22 by 10
cnt53_cx = drum_axle_x + sqrt(pow(cnt53_rd + cnt53_rc, 2) - pow(drum_axle_z - cnt53_cz, 2)); // ~147.37
cnt53_y = 12;    // mesh plane = drum40 gear plane (back, y 9..15)
cnt53_y0 = 1; cnt53_y1 = 59;  // hidden in wall/block bores, never exterior
spur53_t = 6;
// Stage 2 (90deg bevel, overhead): Y 12T (r12, countershaft) ->
// X 10T (r10, high layshaft) at I53 = (cx,45.5,44): 12/10 = 1.2x.
bev53_Zy = 12; bev53_Zx = 10;
bev53_ry = drive53_mod*bev53_Zy/2;   // 12
bev53_rx = drive53_mod*bev53_Zx/2;   // 10
apex53_x = cnt53_cx; apex53_y = 45.5; apex53_z = 44;
bev53_CYy = apex53_y - bev53_rx;   // (cx,35.5,44), body toward -Y
bev53_CXx = apex53_x + bev53_ry;   // (cx+12,45.5,44), body toward +X
bev53_t = 6;
// High side layshaft (spinner X at y=45.5,z=44: apex -> drop).
hi53_y = 45.5; hi53_z = 44;
hi53_x0 = cnt53_cx; hi53_x1 = 183;
hi53_r = 2.5;
// Stage 3 (spur drop X-X at x=181, thin pair t=4): high 15T (r15)
// -> low 12T (r12): dz = 27 = 15+12, 15/12 = 1.25x.
drop53_x = 181; drop53_t = 4;
drop53_Zh = 15; drop53_Zl = 12;
drop53_rh = drive53_mod*drop53_Zh/2;   // 15
drop53_rl = drive53_mod*drop53_Zl/2;   // 12
// Low side layshaft (spinner X at y=45.5,z=17: 165..183, carries
// the drop-low gear + the v51 friction wheel at x=175).
lo53_y = 45.5; lo53_z = 17;
lo53_x0 = 165; lo53_x1 = 183;
lo53_r = 2.5;
fric53_r = 3.5; fric53_t = 4;
fric53_x = 175; // wheel centre (face beside the ring east face, kept)
// Hanger posts (static brackets, base-fused, tops meet shaft
// bottoms, no pierce; Y-beside the tape like v51).
hi53_post_x = 163; hi53_post_top = hi53_z - hi53_r; // 41.5
lo53_post_x = 167; lo53_post_top = lo53_z - lo53_r; // 14.5
// v51 hollow-rotor rods: 2 rod-like bobbin holders 180 apart on the ring
// (rods parallel X at orbit radius 9.5, bobbins ride the rods).
rod51_orbit = 9.5; rod51_r = 1.2; rod51_h = 10;
bob51_r = 2.5; bob51_h = 6;
// Drop pocket under the low drop gear (spinning 12T outer bottom
// 17-14=3 dips below the base top 4; pocket floor at 2 leaves 1.0
// rolling clearance, base keeps a 2mm print floor, v51 precedent).
drop53_pock_z0 = 2; // pocket floor (base keeps 0..2 solid, still prints flat)
// Tape-top reference for the >=5 overhead-clearance asserts.
tape53_top = 22; // transit/pocket top ~21.2 + margin
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
assert(roller_axle_z >= roller_outer_dia/2 + 1, str("roller_axle_z must clear base: need >= ", roller_outer_dia/2+1, " got ", roller_axle_z));
assert(drum_axle_z >= drum_radius + base_thick + tolerance, str("drum_axle_z must clear cradle+tape: need >= ", drum_radius+base_thick+tolerance, " got ", drum_axle_z));
assert(abs(sqrt(pow(roller_axle_x - drum_axle_x,2)+pow(roller_axle_z - drum_axle_z,2)) - center_distance) < 0.5,
       str("gear center distance must be ~60mm, got ", sqrt(pow(roller_axle_x-drum_axle_x,2)+pow(roller_axle_z-drum_axle_z,2))));
// v53 OVERHEAD drive (drum40 takeoff, no duplicate, no low bevels):
// single module 2 + exact 6.0 at the low shaft + parallel mesh
// dist=r1+r2 + true 90deg bevel + spur drop + side friction on
// the ring OD (nothing coaxial). Zero exterior, zero floor gears.
assert(drive53_mod == 2 && gear_module == 2, "v53: drive must stay single module 2");
assert(cnt53_Zc >= 10 && cnt53_Zc <= 60 && bev53_Zy >= 10 && bev53_Zy <= 60
    && bev53_Zx >= 10 && bev53_Zx <= 60 && drop53_Zh >= 10 && drop53_Zh <= 60
    && drop53_Zl >= 10 && drop53_Zl <= 60, "v53: drive teeth must stay in [10,60]");
assert((drum_teeth/cnt53_Zc)*(bev53_Zy/bev53_Zx)*(drop53_Zh/drop53_Zl) == 6, "v53: step-up must be exactly 6x ((40/10)*(12/10)*(15/12))");
// Stage-1 mesh: centre distance = r_drum40 + r_counter (same Y plane).
assert(abs(sqrt(pow(cnt53_cx - drum_axle_x, 2) + pow(cnt53_cz - drum_axle_z, 2)) - (cnt53_rd + cnt53_rc)) <= tolerance + 0.01, "v53: drum40->counter mesh must satisfy dist=r1+r2 (50)");
assert(cnt53_y == 12, "v53: counter must share the drum40 gear plane (back, y 9..15)");
// Bevel axes intersect at the overhead apex + perpendicular (Y vs X).
assert(apex53_x == cnt53_cx && apex53_z == cnt53_cz, "v53: apex must sit on the Y countershaft (cx,44)");
assert(apex53_y == hi53_y && apex53_z == hi53_z, "v53: apex must sit on the high layshaft (45.5,44)");
assert(bev53_CYy == apex53_y - bev53_rx && apex53_x == cnt53_cx, "v53: Y bevel centre must be r_x off apex (cx,35.5,44)");
assert(bev53_CXx == apex53_x + bev53_ry && apex53_y == hi53_y, "v53: X pinion centre must be r_y off apex (cx+12,45.5,44)");
assert(sqrt(pow(bev53_CYy-apex53_y,2)) == bev53_rx, "v53: Y pitch cone must touch apex");
assert(sqrt(pow(bev53_CXx-apex53_x,2)) == bev53_ry, "v53: X pitch cone must touch apex");
// Drop mesh: vertical centre distance = rh+rl (parallel X-X shafts).
assert(hi53_z - lo53_z == drop53_rh + drop53_rl, "v53: drop mesh must satisfy dz=rh+rl (27=15+12)");
assert(hi53_y == lo53_y, "v53: drop shafts must share Y (45.5)");
assert(hi53_x0 <= drop53_x && drop53_x + drop53_t/2 <= hi53_x1, "v53: drop-high must ride the high shaft");
assert(lo53_x0 <= drop53_x - drop53_t/2 && drop53_x <= lo53_x1, "v53: drop-low must ride the low shaft");
// Overhead clearance: every bevel/counter/drop-high bottom >= tape top + 5.
assert(cnt53_cz - (cnt53_rc + 2) - tape53_top >= 5, "v53: counter bottom must clear the tape by >=5 (32 vs 22)");
assert(apex53_z - (bev53_ry + 2) - tape53_top >= 5, "v53: Y bevel bottom must clear the tape by >=5 (30 vs 22)");
assert(apex53_z - (bev53_rx + 2) - tape53_top >= 5, "v53: X pinion bottom must clear the tape by >=5 (32 vs 22)");
assert(hi53_z - (drop53_rh + 2) - tape53_top >= 5, "v53: drop-high bottom must clear the tape by >=5 (27 vs 22)");
// v51 hollow rotor: rods clear the bore, bobbins clear the tape
// corners (pocket half 3.9 x half-height 4 -> corner r 5.59), bobbins
// stay inside the ring OD envelope (export lift/min_z kept).
assert(rod51_orbit - rod51_r >= 8, "v51: holder rods must clear the ring bore (middle stays empty)");
assert(rod51_orbit - bob51_r > 5.6, "v51: bobbins must clear the tape corners on every orbit");
assert(rod51_orbit + bob51_r <= twister_ring_r + twister_ring_tube, "v51: bobbins must stay inside the ring OD envelope");
// v53 friction drive (kept v51 geometry): wheel touches the ring OD
// (tangent), rides the low shaft mid-span, stays interior, clears
// the cradle post top.
assert(sqrt(pow(lo53_y-30,2) + pow(lo53_z-twister_axle_z,2)) == (twister_ring_r + twister_ring_tube) + fric53_r, "v53: friction wheel must touch the ring OD (15.5 = 12+3.5)");
assert(lo53_x0 <= fric53_x && fric53_x <= lo53_x1, "v53: friction wheel must ride the low shaft span");
assert(lo53_y - fric53_r >= 0 && lo53_y + fric53_r <= 60, "v53: friction wheel must stay interior (y 42..49)");
assert(lo53_z - fric53_r > twister_post_h, "v53: friction wheel must clear the cradle post top (13.5 vs 13)");
assert(fric53_x - fric53_t/2 >= bind_x && fric53_x - fric53_t/2 <= bind_x + 2, "v53: friction wheel face must meet the ring east face");
// Interior (zero exterior gears) + min_z.
assert(cnt53_y >= 0 && cnt53_y <= 60 && apex53_y >= 0, "v53: drive must be interior (zero exterior gears)");
assert(drop53_x - drop53_t/2 >= 0 && drop53_x + drop53_t/2 <= 248, "v53: drop pair must stay inside the chassis");
assert(lo53_z - (drop53_rl + 2) >= 0, "v53: drop-low must keep min_z>=0 (17-14=3)");
assert(lo53_z - lo53_r >= 0, "v53: low shaft must keep min_z above 0 (14.5)");
assert(hi53_z - hi53_r >= 0, "v53: high shaft must keep min_z above 0 (41.5)");
assert(cnt53_cz - axle_dia/2 >= 0, "v53: countershaft must keep min_z above 0 (40)");
// Shafts supported: countershaft hidden in wall bores; layshafts ride posts.
assert(cnt53_y0 >= 0 && cnt53_y0 <= 2, "v53: countershaft must start hidden in the back wall bore (0..2)");
assert(cnt53_y1 >= 58 && cnt53_y1 <= 60, "v53: countershaft must end hidden in the front block bore");
assert(hi53_x0 == apex53_x && hi53_x1 == drop53_x + drop53_t/2, "v53: high shaft must run apex->drop east face");
assert(lo53_x0 <= lo53_post_x && lo53_post_x <= lo53_x1, "v53: low post must stand under the low shaft");
assert(hi53_x0 <= hi53_post_x && hi53_post_x <= hi53_x1, "v53: high post must stand under the high shaft");
assert(hi53_post_top == hi53_z - hi53_r, "v53: high post top must meet the shaft bottom");
assert(lo53_post_top == lo53_z - lo53_r, "v53: low post top must meet the shaft bottom");
assert(hi53_post_top >= 0 && lo53_post_top >= 0, "v53: posts must stand on the base");
assert(hi53_y - 2 > 34 && lo53_y - 2 > 34, "v53: posts stay beside the tape (never over it)");
assert(lo53_z - (drop53_rl + 2) > drop53_pock_z0 + tolerance, "v53: drop-low bottom must clear the pocket floor (3 vs 2, rolling clearance)");
assert(axle_clearance_dia/2 > axle_dia/2, "v48: bores must slip on shafts (free spin, no fuse)");
// Drop-gear air gaps to neighbours (thin spinning pair, fail-loud;
// station envelopes + edge gaps >=5 untouched).
assert(drop53_x - drop53_t/2 - (bind_x + 5) >= 1, "v53: drop gears must clear the rod sweep (179 vs 177)");
assert((pull_x - vpull_sleeve_r) - (drop53_x + drop53_t/2) >= 2, "v53: drop gears must clear the pull station (183 vs 186.35)");
// v48 pull support: static pins base-fused, tops hidden in caps
// (no drive tube, no gear — tape-coupled nip, zero exterior gears).
assert(drop53_x - drop53_t/2 - (bind_x + 5) >= 1, "v53: drop gears must clear the rod sweep (179 vs 177)");
assert((pull_x - vpull_sleeve_r) - (drop53_x + drop53_t/2) >= 2, "v53: drop gears must clear the pull station (183 vs 186.35)");
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
            // v53 OVERHEAD twister drive (v51 hollow kept: ZERO coaxial
            // parts, ZERO exterior gears, NO belts, NO floor gears, NO
            // duplicate takeoff): back wall is clean solid. EXISTING
            // drum40 (axis Y, back plane y 9..15) -> overhead counter
            // 10T (axis Y, same plane y=12, dist 50 = 40+10) at
            // (~147.37,12,44) = 4x, high above the tape (bottom 32);
            // Y-bevel 12T (same high countershaft, axis Y) -> X-pinion
            // 10T (high layshaft, axis X) = 1.2x at I53 (cx,45.5,44),
            // Y vs X 90deg, both bottoms >= 30 (overhead); thin 15T/12T
            // spur drop (parallel X-X, dz=27, 1.25x at x=181, bottoms
            // 27/3, low one pocketed) -> low layshaft + side friction
            // wheel (r3.5) touching the ring OD (slip after) = 6x at
            // the low shaft. One high Y countershaft (cx,44, y 1..59,
            // through-wall) + high/low X layshafts (y=45.5, z=44/17)
            // + 2 hanger posts replace the v51 low apex works.
            // Pull/takeup are tape-coupled (no gears): static pins
            // support both roller ends; bridge kept SOLID (no tube
            // hole); cup B kept (bored).
            // Counter spur (axis Y, back plane y=12: meshes the
            // existing drum40 gear; bored, slips on the high
            // countershaft; overhead, never near the tape).
            translate([cnt53_cx, cnt53_y, cnt53_cz])
                rotate([90, 0, 0])
                    spur_gear(teeth=cnt53_Zc, module_mm=drive53_mod, thickness=spur53_t, bore_dia=axle_dia);
            // Y-bevel (apex at I53, axis Y, body toward -Y; bored, same
            // high countershaft as the counter spur, overhead).
            translate([apex53_x, apex53_y, apex53_z])
                rotate([90, 0, 0])
                    bevel_gear(teeth=bev53_Zy, module_mm=drive53_mod, thickness=bev53_t, bore_dia=axle_dia);
            // X-pinion (apex at I53, axis X, body toward +X along the
            // high layshaft; bored, slips on it).
            translate([apex53_x, apex53_y, apex53_z])
                rotate([0, 90, 0])
                    bevel_gear(teeth=bev53_Zx, module_mm=drive53_mod, thickness=bev53_t, bore_dia=axle_dia);
            // Apex-contact note: mating pitch cones meet only at the
            // shared apex point (single-point visual mesh, as real
            // bevels); parallel spur pairs mesh tooth-into-gap
            // (dist=r1+r2 asserted above).
            // High countershaft (spinner along Y at (cx,44), carries
            // the counter spur + Y-bevel; ends hidden in wall bores).
            translate([cnt53_cx, (cnt53_y0 + cnt53_y1)/2, cnt53_cz])
                rotate([90, 0, 0])
                    cylinder(h=cnt53_y1 - cnt53_y0, r=axle_dia/2, center=true);
            // High side layshaft (spinner along X at y=45.5,z=44,
            // apex -> drop; overhead, bore stays empty).
            translate([(hi53_x0 + hi53_x1)/2, hi53_y, hi53_z])
                rotate([0, 90, 0])
                    cylinder(h=hi53_x1 - hi53_x0, r=hi53_r, center=true);
            // Spur drop pair (thin t=4, parallel X-X at x=181:
            // high 15T -> low 12T, dz=27=15+12).
            translate([drop53_x, hi53_y, hi53_z])
                rotate([0, 90, 0])
                    spur_gear(teeth=drop53_Zh, module_mm=drive53_mod, thickness=drop53_t, bore_dia=axle_dia);
            translate([drop53_x, lo53_y, lo53_z])
                rotate([0, 90, 0])
                    spur_gear(teeth=drop53_Zl, module_mm=drive53_mod, thickness=drop53_t, bore_dia=axle_dia);
            // Low side layshaft (spinner along X at y=45.5,z=17,
            // 165..183, carries drop-low + friction wheel).
            translate([(lo53_x0 + lo53_x1)/2, lo53_y, lo53_z])
                rotate([0, 90, 0])
                    cylinder(h=lo53_x1 - lo53_x0, r=lo53_r, center=true);
            // Friction wheel (spinner fused on the low shaft at x=175,
            // face beside the ring east face, rim tangent to the ring
            // OD: hollow rolling cradle drive, nothing in the middle).
            translate([fric53_x, lo53_y, lo53_z])
                rotate([0, 90, 0])
                    cylinder(h=fric53_t, r=fric53_r, center=true);
            // Hanger posts under both layshafts (static brackets fused
            // to the base, beside the tape; tops meet the shaft
            // bottoms, bearing holes slip).
            difference() {
                translate([hi53_post_x - 2, hi53_y - 2, 0])
                    cube([4, 4, hi53_post_top]);
                translate([hi53_post_x, hi53_y, hi53_post_top])
                    rotate([0, 90, 0])
                        cylinder(h=4 + 2*epsilon, d=axle_clearance_dia, center=true);
            }
            difference() {
                translate([lo53_post_x - 2, lo53_y - 2, 0])
                    cube([4, 4, lo53_post_top]);
                translate([lo53_post_x, lo53_y, lo53_post_top])
                    rotate([0, 90, 0])
                        cylinder(h=4 + 2*epsilon, d=axle_clearance_dia, center=true);
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
        // v53 high-countershaft wall holes (through-wall support at (cx,44)).
        for (side=[0,1]) {
            translate([cnt53_cx, side*(chassis_width-wall_thick)+wall_thick/2, cnt53_cz])
                rotate([90,0,0])
                    cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        }
        // v48: NO idler stubs fuse into the back wall (zero exterior
        // gears) — the wall keeps full section everywhere. The solid
        // pull bridge needs no hole (tape-coupled nip, no drive tube).
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
        // v53 drop pocket under the low 12T drop gear (spinning steel
        // bottom 3 vs base top 4: pocket 2..5 gives 1.0 rolling gap,
        // base keeps a 2mm print floor, min_z=0 kept elsewhere).
        translate([drop53_x - 4, lo53_y - 4, drop53_pock_z0 - epsilon])
            cube([8, 8, (base_thick + 1) - drop53_pock_z0 + 2*epsilon]);
        // Lightening cutouts in walls (v48: zero exterior gears, so
        // the back wall is clean solid everywhere; cutout kept high
        // at z64, clear of the interior spur pair at y=45 and the
        // high Y countershaft / side layshaft at z17 (all interior).
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
// 7. 6-FOLDER ASYMMETRIC INNER-CURL, v54 (user REJECTS every
// outer pipe/shell: "tape arrives already bent U; inside that U
// ONE side wall curls IN, OTHER side curls a little LESS, curls
// advance so paper edges roll together into overlapped roll").
// NO tube, NO shell, NO ring, NO bore. The part is a SEPARATE
// open object that sits INSIDE the tape U: an open base
// plate/blade + center fin tongue + two asymmetric curling
// wings, all base-fused into ONE printable solid, screw-mounted
// to the chassis on the old plow M3 holes.
// Local frame like the old plow: x 0..turner_len (33, world
// 126..159), y 0..40 (tape centre cy=20), z 0..top, min_z=0.
// 7 stations, per-side curl angle + radius interpolated to 17 fine
// plates (~2.06 apart, hull-bridged; steps small so the walls stay
// thin and read as curls, not domes):
//   x:        0    5.5   11   16.5   22   27.5   33
//   L span:  30    75  120   165   210   245   270 (deep in-curl)
//   L r:    3.5   3.3   3.1   2.9   2.7   2.6   2.5
//   R span:  20    45   75   105   135   160   180 (shallow)
//   R r:    3.5   3.4   3.2   3.0   2.8   2.6   2.5
// Left (+Y) starts as a small in-turned lip and winds to a 270deg
// in-roll; right (-Y) starts near-flat and winds to 180deg; at the
// exit the two roll tips nest (~2.7 apart) so the paper edges roll
// TOGETHER overlapped. Wing roots ride full-length support rails
// (also the U-wall guides); the center fin tongue rises
// progressively into the roll zone; a wedge nose gives entry
// lead-in chamfers.
// part_to_render "plow" (compat) and "turner" both render this.
// ============================================================
// Annular-sector strip for one curl plate, pre-mapped so
// rotate([0,90,0]) + linear_extrude lays it as a plate across X:
// angle a gives y_part = r*cos(a), z_part = r*sin(a). Left (+Y)
// sweeps a0=0 -> a1=span (up/in/down); right (-Y) sweeps
// a0=180 -> a1=180-span (mirror). Spans stay < 300 (open).
function curl_strip_pts(r_in, r_out, a0, a1, n) = concat(
    [for (i=[0:n]) [-r_out*sin(a0+(a1-a0)*i/n), r_out*cos(a0+(a1-a0)*i/n)]],
    [for (i=[n:-1:0]) [-r_in*sin(a0+(a1-a0)*i/n), r_in*cos(a0+(a1-a0)*i/n)]]);

module six_turner() {
    tw = 40;                        // v1-precedent width kept (old plow_w)
    cy = tw/2;                      // 20: tape centre
    curl_cz = 12;                   // wing curl-axis height (v39 datum kept)
    wall = 1.4;                     // wing/fin wall (printable 1.2-1.6 band)
    wing_off = 1.8;                 // wing arc centres at cy+-1.8
    rail_in = 4.2;                  // root-rail inner faces at cy+-4.2
    rail_top = 12.3;                // rails bed the wing roots (root ribbons at z=12)
    fin_t0 = 9.5;                   // center-fin entry top (progressive rise)
    fin_t1 = 13;                    // center-fin exit top (reaches the roll zone)
    nose_top = 8.5;                 // nose block top (stays under the paper floor)
    // THE station table: per-side curl span (deg) + radius.
    st_x = [0, 5.5, 11, 16.5, 22, 27.5, 33];
    st_spanL = [30, 75, 120, 165, 210, 245, 270];
    st_rL = [3.5, 3.3, 3.1, 2.9, 2.7, 2.6, 2.5];
    st_spanR = [20, 45, 75, 105, 135, 160, 180];
    st_rR = [3.5, 3.4, 3.2, 3.0, 2.8, 2.6, 2.5];
    n_st = len(st_x);
    // Fine wing plates: the 7-station table interpolated to 17
    // plates (~2.06 apart, 1.2 thick, hull-bridged). Steps are small
    // so the hull web stays thin — the wings read as curls, not domes.
    fpx = [0, 2.0625, 4.125, 6.1875, 8.25, 10.3125, 12.375, 14.4375,
        16.5, 18.5625, 20.625, 22.6875, 24.75, 26.8125, 28.875, 30.9375, 31.8];
    fspanL = [30, 46.88, 63.75, 80.62, 97.5, 114.38, 131.25, 148.12,
        165, 181.88, 198.75, 214.38, 227.5, 240.62, 251.25, 260.62, 270];
    frL = [3.5, 3.425, 3.35, 3.275, 3.2, 3.125, 3.05, 2.975,
        2.9, 2.825, 2.75, 2.688, 2.65, 2.613, 2.575, 2.538, 2.5];
    fspanR = [20, 29.38, 38.75, 48.75, 60, 71.25, 82.5, 93.75,
        105, 116.25, 127.5, 138.12, 147.5, 156.88, 165, 172.5, 180];
    frR = [3.5, 3.462, 3.425, 3.375, 3.3, 3.225, 3.15, 3.075,
        3.0, 2.925, 2.85, 2.775, 2.7, 2.625, 2.575, 2.538, 2.5];
    n_fp = len(fpx);
    bx = [6, turner_len - 6];       // tab bolts (old plow pattern)
    by = [-4, tw + 4];              // tab bolts across
    plan_ang = atan(((paper_width - 8)/2)/turner_len);
    floor_local = tape_z + tape_thick - base_thick; // 9.4: paper floor in turner frame
    assert(turner_len > 15, str("six_turner: turner_len must exceed 15, got ", turner_len));
    assert(curl_cz == turner_curl_cz, "six_turner: curl axis must keep the v39 datum (12)");
    assert(wall >= 1.2 && wall <= 1.6, str("six_turner: walls must stay printable (1.2-1.6), got ", wall));
    assert(n_st == 7, str("six_turner: need 7 forming stations, got ", n_st));
    assert(st_x[0] == 0 && st_x[n_st-1] == turner_len,
        "six_turner: stations must span local x0..33 (world 126..159)");
    assert(st_spanL[0] <= 40 && st_spanR[0] <= 40,
        "six_turner: entry must start as small lip/flat (spans <=40deg)");
    assert(st_spanL[0] < st_spanL[1] && st_spanL[1] < st_spanL[2] && st_spanL[2] < st_spanL[3]
        && st_spanL[3] < st_spanL[4] && st_spanL[4] < st_spanL[5] && st_spanL[5] < st_spanL[6],
        "six_turner: left curl must advance monotonically (gradual roll-together)");
    assert(st_spanR[0] < st_spanR[1] && st_spanR[1] < st_spanR[2] && st_spanR[2] < st_spanR[3]
        && st_spanR[3] < st_spanR[4] && st_spanR[4] < st_spanR[5] && st_spanR[5] < st_spanR[6],
        "six_turner: right curl must advance monotonically (gradual roll-together)");
    assert(st_rL[0] > st_rL[1] && st_rL[1] > st_rL[2] && st_rL[2] > st_rL[3]
        && st_rL[3] > st_rL[4] && st_rL[4] > st_rL[5] && st_rL[5] > st_rL[6]
        && st_rR[0] > st_rR[1] && st_rR[1] > st_rR[2] && st_rR[2] > st_rR[3]
        && st_rR[3] > st_rR[4] && st_rR[4] > st_rR[5] && st_rR[5] > st_rR[6],
        "six_turner: curl radii must tighten progressively toward the exit");
    assert(st_spanL[n_st-1] >= 255 && st_spanL[n_st-1] <= 285,
        "six_turner: left exit must be a ~270deg deep in-roll");
    assert(st_spanR[n_st-1] >= 165 && st_spanR[n_st-1] <= 195,
        "six_turner: right exit must be a ~180deg shallow in-roll");
    assert(st_spanL[n_st-1] - st_spanR[n_st-1] >= 60,
        "six_turner: curls must stay asymmetric (deep vs shallow differ >=60deg)");
    assert(st_spanL[n_st-1] < 300 && st_spanR[n_st-1] < 300,
        "six_turner: NO enclosing ring — spans stay open (<300deg, never a tube)");
    assert(sqrt(pow(wing_off + st_rL[n_st-1]*cos(st_spanL[n_st-1]) + wing_off
        - st_rR[n_st-1]*cos(180 - st_spanR[n_st-1]), 2)
        + pow(st_rL[n_st-1]*sin(st_spanL[n_st-1])
        - st_rR[n_st-1]*sin(180 - st_spanR[n_st-1]), 2)) < 4,
        "six_turner: exit roll tips must nest (<4 apart) so edges roll together overlapped");
    assert(rail_in - (fold_width/2 + tape_bend_radius + tape_thick) >= tolerance,
        "six_turner: root rails must clear the tape U walls (inner face outside sheet+tol)");
    assert(wing_off + st_rL[0] >= rail_in && wing_off + st_rL[0] <= rail_in + 2,
        "six_turner: entry lips must land over the rails (root bed)");
    assert(curl_cz - st_rL[n_st-1] >= floor_local - 0.1,
        "six_turner: deep roll tip must not stab the trough floor");
    assert(curl_cz + st_rL[0] <= 18,
        "six_turner: entry lips must fit under the pocket walls");
    assert(fin_t1 > curl_cz && fin_t0 < fin_t1,
        "six_turner: center fin must rise progressively into the roll zone");
    assert(nose_top < floor_local,
        "six_turner: nose must stay under the paper floor (lead-in, no touch)");
    assert(n_fp == 17, "six_turner: need 17 fine wing plates");
    assert(fpx[0] >= 0 && fpx[n_fp-1] + 1.2 <= turner_len,
        "six_turner: wing plates must stay in footprint");
    assert(fspanL[0] == st_spanL[0] && fspanL[n_fp-1] == st_spanL[n_st-1]
        && fspanR[0] == st_spanR[0] && fspanR[n_fp-1] == st_spanR[n_st-1]
        && frL[0] == st_rL[0] && frL[n_fp-1] == st_rL[n_st-1]
        && frR[0] == st_rR[0] && frR[n_fp-1] == st_rR[n_st-1],
        "six_turner: fine plates must match the station table at both ends");
    assert(bx[0] == 6 && bx[1] == turner_len - 6
        && bx[0] + plow_start == 132 && bx[1] + plow_start == 153,
        "six_turner: mount holes must hit the chassis M3 holes (world 132/153, old plow pattern)");
    assert(chassis_width/2 - 20 == 10 && by[0] + 10 == 6 && by[1] + 10 == 54,
        "six_turner: mount holes must hit the chassis M3 holes across (world 6/54)");
    // No bore, no slot, no ring: the voids below are ONLY the M3
    // clearance holes. Wings/fin/nose/rails unite on the base plate;
    // wing plates share into consecutive hulls, roots bed in the
    // rails — one solid.
    union() {
        difference() {
            union() {
                // Base plate/blade (bottom mount, min_z=0)
                cube([turner_len, tw, base_thick]);
                // Low converging entry guides (funnel 25.4 -> ~8)
                translate([0, cy - paper_width/2 - 1, base_thick])
                    rotate([0, 0, plan_ang])
                        cube([turner_len + 2, 2, 6]);
                translate([0, cy + paper_width/2 + 1 - 2, base_thick])
                    rotate([0, 0, -plan_ang])
                        cube([turner_len + 2, 2, 6]);
                // Root rails: U-wall guides outside + wing root beds
                // (roots embed 0.3, fused full length).
                for (s=[-1,1])
                    translate([0, cy + s*rail_in - (s > 0 ? 0 : 2), base_thick - epsilon])
                        cube([turner_len, 2, rail_top - base_thick + epsilon]);
                // Center fin tongue (progressive rise into the roll zone).
                hull() {
                    translate([2, cy - 0.7, base_thick - epsilon])
                        cube([4, 1.4, fin_t0 - base_thick + epsilon]);
                    translate([27, cy - 0.7, base_thick - epsilon])
                        cube([6, 1.4, fin_t1 - base_thick + epsilon]);
                }
                // Wedge nose: entry lead-in chamfers (plan taper + rise).
                hull() {
                    translate([0, cy - 3.5, base_thick - epsilon])
                        cube([0.8, 7, 5.5 - base_thick + epsilon]);
                    translate([4, cy - 2.5, base_thick - epsilon])
                        cube([2, 5, nose_top - base_thick + epsilon]);
                }
                // Curling wings: hull-loft between fine plates, per side.
                // Left (+Y) sweeps 0->span (deep); right (-Y) sweeps
                // 180->180-span (shallow mirror). Plates share into
                // consecutive hulls; roots bed in the rails full length.
                for (k=[0:n_fp-2]) {
                    hull() {
                        translate([fpx[k], cy + wing_off, curl_cz])
                            rotate([0, 90, 0])
                                linear_extrude(height=1.2)
                                    polygon(curl_strip_pts(frL[k] - wall, frL[k], 0, fspanL[k], 24));
                        translate([fpx[k+1], cy + wing_off, curl_cz])
                            rotate([0, 90, 0])
                                linear_extrude(height=1.2)
                                    polygon(curl_strip_pts(frL[k+1] - wall, frL[k+1], 0, fspanL[k+1], 24));
                    }
                    hull() {
                        translate([fpx[k], cy - wing_off, curl_cz])
                            rotate([0, 90, 0])
                                linear_extrude(height=1.2)
                                    polygon(curl_strip_pts(frR[k] - wall, frR[k], 180, 180 - fspanR[k], 24));
                        translate([fpx[k+1], cy - wing_off, curl_cz])
                            rotate([0, 90, 0])
                                linear_extrude(height=1.2)
                                    polygon(curl_strip_pts(frR[k+1] - wall, frR[k+1], 180, 180 - fspanR[k+1], 24));
                    }
                }
                // Mounting tabs (old plow pattern: chassis M3 holes line up)
                for (tx=[2, turner_len - 10]) {
                    translate([tx, -8, 0]) cube([8, 8.15, 3]);
                    translate([tx, tw - 0.15, 0]) cube([8, 8.15, 3]);
                }
                // Tab bolts visual
                for (bxi=[0:1])
                    for (byy=[by[0], by[1]]) {
                        translate([bx[bxi], byy, 0]) cylinder(h=3, d=bolt_dia, center=false);
                        translate([bx[bxi], byy, 3 - epsilon]) cylinder(h=2.5, r=bolt_head_across/sqrt(3), $fn=6, center=false);
                    }
            }
            // Tab bolt clearance holes (M3 + tol)
            for (bxi=[0:1])
                for (byy=[by[0], by[1]])
                    translate([bx[bxi], byy, -epsilon])
                        cylinder(h=3 + 2*epsilon, d=bolt_dia + 2*tolerance, center=false);
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
    assert(twister_arms == 2, "thread_twister: must carry exactly 2 holders");
    assert(rod51_orbit - rod51_r >= 8, "thread_twister: middle must stay empty (rods clear the bore)");
    assert(rod51_orbit + bob51_r <= twister_ring_r + twister_ring_tube, "thread_twister: bobbins must stay in the ring envelope");
    union() {
        // Outer guide ring in the YZ plane (axis X): rotate_extrude
        // ring about Z then tilt so its axis lies along X.
        rotate([0, 90, 0])
            rotate_extrude(convexity=10)
                translate([twister_ring_r, 0, 0])
                    square([twister_ring_tube*2, twister_ring_tube*2], center=true);
        // v51: NO hub, NO arms to the centre (middle stays empty for
        // the tape). 2 rod-like bobbin holders 180 apart: rods
        // parallel to X fused through the ring, thread bobbins ride
        // the rods and orbit with the rotor, clear of the bore.
        for (k=[0:twister_arms-1])
            rotate([k*180, 0, 0]) {
                translate([0, rod51_orbit, 0])
                    rotate([0, 90, 0])
                        cylinder(h=rod51_h, r=rod51_r, center=true);
                translate([0, rod51_orbit, 0])
                    rotate([0, 90, 0])
                        cylinder(h=bob51_h, r=bob51_r, center=true);
            }
    }
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
// Sign convention (v23: crank drives the ROLLER shaft from the back wall side):
//   drum_angle = -360*$t ANTI-CLOCKWISE about +Y (top surface moves -X/left,
//   viewed +X right, +Z up): picks up RIGHT, carries over top, drops bottom-center
//   roller_angle = +720*$t + gear_mesh_phase CLOCKWISE (driven by drum via
//   40:20 mesh, 2:1; +9° half-pitch so the pinion tooth falls into the drum gap)
//   crank = roller_angle (rigid on the roller shaft, coaxial at roller_axle_x)
//   upper idler = -720*$t (counter-rotates via tape contact)
//   v53 OVERHEAD twister drive (zero exterior gears, module 2,
//   asserted): crank->drum 2:1 interior (40:20, dist 60, phase 9°);
//   EXISTING drum40 -> overhead counter 10T (4x, back plane y=12,
//   dist 50, high) -> Y-bevel 12T -> high X-pinion 10T (1.2x, 90°
//   at I53, overhead) -> thin 15T/12T drop (1.25x at x=181) = 6x
//   at the low shaft (1 bind per seed, 6 cavities). Flips keep the twister sign
//   (animation: twister -3x crank = 6x drum at 0.5x crank).
//   Pull nip pair spins about Z at +/-roller_angle*vpull_spin (tape-coupled
//   4/3 vs the main roller, v52 d15 dia => same surface speed,
//   the spacing driver; cushioned rubber/silicone sleeve grips firm
//   without crushing); takeup_angle
//   = -1440*$t about the reel axle (tape-tension wind-up, core d10
//   base speed winds the same 125.66mm linear tape; slip clutch on
//   the axle slips when full). No belts, no exterior gears.
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
    pull_a_angle = roller_angle*vpull_spin;   // v52: nip side A spin-compensated 4/3 (same surface speed)
    pull_b_angle = -roller_angle*vpull_spin;  // v52: nip side B counter-rotates 4/3
    takeup_angle = -1440*$t;       // v48: tape-tension wind-up (no take-up gears — exterior TU removed): base speed -2 = 2x crank (sense unchanged vs v43-v47; winds the same 125.66mm linear tape)

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

    // v37 Thread twister (v51 HOLLOW: ring + 2 rod bobbin holders
    // orbit the tape axis just east of the plow, binding each seed
    // into the folded pocket; side friction drive, 6x at the
    // layshaft, viewer kinematic -3x about X).
    translate([bind_x, chassis_width/2, twister_axle_z])
        rotate([twister_angle, 0, 0])
            thread_twister();

    // v37 Vertical-nip pull pair (spacing driver), v39 CUSHIONED:
    // two vertical-axis rollers stand on the base flanking the finished
    // folded tape at pull_x (side-mounted: top bridge from the chassis
    // walls caps the axles), pinching the closed pocket and pulling it
    // at the same surface speed as the main roller (v52 d15 at 4/3 spin, spacing
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
