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
chassis_x0    = -14; // v22: west edge (was 0); east edge stays chassis_x0+chassis_len=200
chassis_len   = 214; // v22: 200->214, west extension seats the spool bearing at x=-6
chassis_width = 60;
chassis_height = 110;  // > max(spool top=90, drum top=102) + 5 = 107 ✓
base_thick    = 4;
wall_thick    = 3;

// ============================================================
// Plow
// ============================================================
plow_start    = drum_axle_x + drum_radius + 1; // 126 (east of drum, unchanged)
plow_len      = 33; // v21 FIXED: decoupled from roller_axle_x (roller moved west
                    // of drum, so the old roller-based end 39-126 went negative
                    // and tripped the plow_len assert). Plow stays east (v1 precedent).
plow_end      = plow_start + plow_len; // 159
fold_width    = 12.7;
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
shroud_bore     = 8;     // bore fits 8mm seed (drop bore 9 = 8 + 2*tol clearance)
shroud_wall     = 2;     // preserved v12 wall
shroud_gap      = 1.5;   // preserved v12 gap (within 1.5-2 smooth channel, no ribs/steps)
groove_w        = 7;     // inner-face groove width, matches drum cavity track (fits 6mm cavities d6.6)
groove_d        = 0.8;   // groove depth (clears cavity protrusion 0.6)
// v22 tape-cover shroud segment WEST of drum (roller nip -> drum exit).
// World x shroud_x0..shroud_x1 = 58..84 (centroid ~71): drum(100) >
// shroud(~71) > roller(40) R->L. Top (34) stays below the roller gear
// bottom (60-22=38) and the hopper cover bottom lip (~36.4 at x=84).
shroud_x0  = roller_axle_x + 18;  // 58: gear-X overlap <=4, z-separated (top 34 < 38)
shroud_x1  = drum_axle_x - 16;    // 84: tucks to drum tangent, clears cover lip + drop tube (91+)
shroud_len = shroud_x1 - shroud_x0; // 26
shroud_h   = 34;                  // enclosed tunnel height (tape slot 0..32, tape at ~30)

// ============================================================
// Crank (v21: drives the ROLLER shaft, coaxial at roller_axle_x, outside wall)
// ============================================================
crank_throw     = 45;
crank_mount_x   = roller_axle_x; // 40: coaxial with roller axle (was 77.5 drum-left)
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
assert(spool_axle_z == 65, "spool_axle_z must be 65");
assert(chassis_height > max(spool_axle_z + cone_h + bb_height_spool, drum_axle_z + drum_outer_r) + 5,
       str("chassis_height must hold tallest axle + clearance: need > ", max(spool_axle_z+cone_h+bb_height_spool, drum_axle_z+drum_outer_r)+5, " got ", chassis_height));
assert(hopper_inner_r > drum_radius, "hopper_inner_r must exceed drum_radius (clearance >0)");
assert(plow_len > 15, str("plow_len must exceed 15, got ", plow_len));
assert(crank_throw > 20 && crank_throw < 60, str("crank_throw out of envelope (20,60): ", crank_throw));
assert(crank_mount_x == roller_axle_x, str("crank_mount_x must be coaxial with roller axle: ", crank_mount_x));
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
module bearing_block(spec_x, spec_z, spec_height, is_drum=false) {
    bore_r = is_drum ? hex_clearance_r : axle_clearance_dia/2;
    difference() {
        union() {
            translate([spec_x - bb_len/2, -bb_wall/2, spec_z - spec_height])
                cube([bb_len, bb_wall, spec_height]);
            translate([spec_x - bb_len/2, -bb_wall/2, spec_z])
                cube([bb_len, bb_wall, 2]);
            for (sx=[-1,1])
                translate([spec_x + sx*4, -bb_wall/2 - 0.1, spec_z + 1])
                    cylinder(h=2+epsilon, d=bolt_dia+2*tolerance, center=false);
        }
        // Axle bore
        translate([spec_x, -bb_wall/2, spec_z])
            rotate([90,0,0])
                cylinder(h=bb_len+2*epsilon, r=bore_r, center=true);
        // Nut traps
        for (sx=[-1,1])
            translate([spec_x + sx*4, -bb_wall/2 - 1, spec_z + 1])
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
                    byc = side == 0 ? -3 : chassis_width + 3;
                    bearing_block(spec[0], spec[1], spec[2], spec[3]==1);
                }
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
            translate([roller_axle_x, side*(chassis_width-wall_thick)+wall_thick/2, roller_axle_z])
                rotate([90,0,0])
                    cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        }
        for (side=[0,1]) {
            translate([drum_axle_x, side*(chassis_width-wall_thick)+wall_thick/2, drum_axle_z])
                rotate([90,0,0])
                    cylinder(h=wall_thick+2*epsilon, r=hex_clearance_r, $fn=6, center=true);
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
        // Lightening cutouts in walls
        translate([90, -epsilon, 18])
            cube([30, wall_thick+2*epsilon, 22]);
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
//    straight down, bore 9 x 15.6 (fits 8mm seeds), bottom local
//    z=26.5 (world 30.5, 0.5 above tape at 30). Drum carve trims tube
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
    // BOTTOM-CENTER drop tube (v14: 6-o'clock, x=0 = drum centre, bore 9
    // fits 8mm seeds): outer x -9..9 (thick walls saddle-fuse to cover
    // lips after carve trim), bore 9 (-4.5..4.5, 8mm-compatible: v14
    // retains the v13 8mm-seed bore, see commit note), straight down onto tape.
    tube_x0 = -9; tube_x1 = 9;
    bore_x0 = -4.5; bore_x1 = 4.5;
    tube_z0 = 26.5; tube_z1 = 52;
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
            // Drop tube: 4 box walls (double-wall tube, bore = gap between them).
            translate([tube_x0, -(cheek_in + 0.5), tube_z0])
                cube([bore_x0 - tube_x0, 2*(cheek_in + 0.5), tube_z1 - tube_z0]);
            translate([bore_x1, -(cheek_in + 0.5), tube_z0])
                cube([tube_x1 - bore_x1, 2*(cheek_in + 0.5), tube_z1 - tube_z0]);
            for (s = [-1, 1])
                translate([tube_x0, s > 0 ? cheek_in : -y_out, tube_z0])
                    cube([tube_x1 - tube_x0, wall, tube_z1 - tube_z0]);
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
        // Drop window (v14: connects drum surface at 6 o'clock through the
        // cover arc bottom into the CENTER bore top; fed by 6 cavities
        // carried over the top, not by the trough void). Overlaps bore
        // (-4.5..4.5) and drum carve. The drum carve trims the tube top
        // into a smooth drum-conforming funnel mouth (no steps/ledges).
        translate([-4.5, -(cheek_in + 0.5), 29])
            cube([9, 2*(cheek_in + 0.5), 13]);
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
//    flanges; top plate clears the tape (ends open 0..32, tape at ~30);
//    top (34) stays below the roller gear bottom (38) and the hopper
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
    top_t = 2;                                   // top plate 32..34
    port_d = 10;
    port_z = 18;
    difference() {
        union() {
            // Side walls (stand on base, full length/height)
            for (s=[-1,1])
                translate([0, s > 0 ? inner_hw : -outer_hw, 0])
                    cube([shroud_len, wall, shroud_h]);
            // Top plate (ends stay open 0..32 for the tape)
            translate([0, -outer_hw, shroud_h - top_t])
                cube([shroud_len, 2*outer_hw, top_t]);
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
// 7. Folding plow - converges 25.4→12.7, 4×4 wick pocket, flat base
// ============================================================
module folding_plow() {
    plow_w = 40;
    plow_base = base_thick;
    u_len = plow_len/2;
    u_radius = 8;
    plan_ang = atan(((paper_width - fold_width)/2)/plow_len);
    v_wall_thick = 2.5;
    v_wall_height = 10;

    difference() {
        union() {
            cube([plow_len, plow_w, plow_base]);
            // Left converging guide
            translate([0, plow_w/2 - paper_width/2 - 1, plow_base])
                rotate([35,0,0])
                    rotate([0,0,plan_ang])
                        translate([0,0,-2])
                            cube([plow_len + 2, v_wall_thick, v_wall_height+2]);
            // Right converging guide mirrored
            translate([0, plow_w/2 + paper_width/2 + 1 + v_wall_thick, plow_base])
                rotate([-35,0,0])
                    translate([0,0,-2])
                        rotate([0,0,-plan_ang])
                            translate([0,-v_wall_thick,0])
                                cube([plow_len + 2, v_wall_thick, v_wall_height+2]);
            // Mounting tabs
            for (tx=[2, plow_len - 10]) {
                translate([tx, -8, 0]) cube([8, 8.15, 3]);
                translate([tx, plow_w - 0.15, 0]) cube([8, 8.15, 3]);
            }
            // Tab bolts
            for (bx=[6, plow_len - 6])
                for (by=[-4, plow_w + 4]) {
                    translate([bx, by, 0]) cylinder(h=3, d=bolt_dia, center=false);
                    translate([bx, by, 3 - epsilon]) cylinder(h=2.5, r=bolt_head_across/sqrt(3), $fn=6, center=false);
                }
        }
        // U-groove at inlet half
        translate([-epsilon, plow_w/2, plow_base + u_radius - track_depth])
            rotate([0,90,0])
                cylinder(h=u_len+epsilon, r=u_radius, center=false);
        // Wick slot 4×4
        translate([plow_len/2, plow_w/2 + paper_width/2 - 4, plow_base + 2])
            cube([4, 4, 6]);
        // Tab bolt clearance holes
        for (bx=[6, plow_len - 6])
            for (by=[-4, plow_w + 4])
                translate([bx, by, -epsilon])
                    cylinder(h=3 + 2*epsilon, d=bolt_dia + 2*tolerance, center=false);
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
    zoffset = is_lower ? 19.95 : 11; // shift up so min_z=0

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
                // v21: gear on BACK side (-Y, world Y~12, same plane as drum
                // gear). Mirrored rotation so the hub still points away from
                // the body and the collar fuses into it. Shaft stays FRONT
                // (+Y, toward the crank outside the front wall).
                translate([0, -(len/2 + gear_thick/2 - epsilon), 0])
                    rotate([-90,0,0])
                        spur_gear(teeth=roller_teeth, module_mm=gear_module, thickness=gear_thick,
                                  bore_flat=hex_axle_flat, is_hex=true,
                                  hub_dia=16, hub_len=10, collar_dia=14, collar_len=3);
                translate([0, len/2 + gear_thick - epsilon, 0])
                    rotate([90,0,0])
                        cylinder(h=14, r=hex_axle_r, $fn=6, center=false);
                translate([0, len/2 + gear_thick - epsilon - 1, 0])
                    rotate([90,0,0])
                        cylinder(h=1.2, r=6, center=false);
                translate([0, len/2 + gear_thick + 4, 0])
                    rotate([90,0,0])
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
    grip_y0 = arm_w;
    grip_y1 = grip_y0 + grip_len;
    grip_yc = (grip_y0 + grip_y1)/2;

    difference() {
        union() {
            // Tapered arm via hull(boss, end)
            hull() {
                translate([pivot_x - 11, arm_w/2, 0])
                    cylinder(h=arm_t, r=7, center=false);
                translate([pivot_x, arm_w/2, 0])
                    cylinder(h=arm_t, r=9, center=false);
                translate([handle_x, arm_w/2, 0])
                    cylinder(h=arm_t, r=6, center=false);
            }
            // Counterweight stub opposite handle
            translate([pivot_x - 5, -arm_w/2, 0])
                cylinder(h=arm_t, r=5, center=false);
            // Hub boss around shaft
            translate([pivot_x, arm_w/2, pivot_z])
                rotate([90,0,0])
                    cylinder(h=16, r=7, center=true);
            // Pivot hex shaft
            translate([pivot_x, arm_w/2, pivot_z])
                rotate([90,0,0])
                    cylinder(h=hex_shaft_len, r=hex_axle_r, $fn=6, center=true);
            // Handle riser
            translate([handle_x, arm_w/2, 0])
                cylinder(h=pivot_z + 5.5, r=5.5, center=false);
            // Grip (free-spinning, tapered, parallel to shaft axis Y)
            hull() {
                translate([handle_x, grip_y0 + 3, pivot_z])
                    rotate([90,0,0])
                        cylinder(h=10, d=grip_dia, center=true);
                translate([handle_x, grip_yc, pivot_z])
                    rotate([90,0,0])
                        cylinder(h=12, d=grip_dia - 2, center=true);
                translate([handle_x, grip_y1 - 3, pivot_z])
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
        translate([pivot_x + crank_throw/2, arm_w/2, -epsilon])
            cylinder(h=arm_t + 2*epsilon, d=6, center=false);
    }
}

// ============================================================
// Animated assembly
// Sign convention (v21: crank drives the ROLLER shaft from the back-mesh side):
//   drum_angle = -360*$t ANTI-CLOCKWISE about +Y (top surface moves -X/left,
//   viewed +X right, +Z up): picks up RIGHT, carries over top, drops bottom-center
//   roller_angle = +720*$t + gear_mesh_phase CLOCKWISE (driven by drum via
//   40:20 mesh, 2:1; +9° half-pitch so the pinion tooth falls into the drum gap)
//   crank = roller_angle (rigid on the roller shaft, coaxial at roller_axle_x)
//   upper idler = -720*$t (counter-rotates via tape contact)
// At $t=0 geometry equals static layout (plus the 9° mesh phase on the roller).
// ============================================================
module animated_assembly() {
    drum_angle = -360*$t;    // ANTI-CLOCKWISE about +Y
    crank_angle = 720*$t;    // lower roller + crank orbit (CW, opposite drum)
    idler_angle = -720*$t;   // upper idler counter-rotates
    roller_angle = crank_angle + gear_mesh_phase; // mesh-phased roller shaft

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

    // Hopper (v14: ONE printed piece — right wedge pickup level top z=73,
    // open-top half-pipe 16mm/8mm cover 11->6 with grooves, 2 side joints,
    // closed box, bottom-center drop tube at drum x)
    translate([drum_axle_x, chassis_width/2, drum_axle_z - hopper_axis_z])
        hopper_body();

    // Tape cover shroud (v22: enclosed tunnel WEST of drum, roller nip
    // -> drum exit, world x 58..84). Local frame x 0..len, y centred 0.
    translate([shroud_x0, chassis_width/2, 0])
        u_channel_shroud();

    // Seed cradle
    translate([plow_start, chassis_width/2 - 12.7, base_thick])
        seed_cradle();

    // Folding plow
    translate([plow_start, chassis_width/2 - 20, base_thick])
        folding_plow();

    // Pull rollers (zoffset=11 compensated in assembly)
    translate([roller_axle_x, chassis_width/2, roller_axle_z])
        rotate([0, roller_angle, 0])
            translate([0, 0, -roller_dia/2])
                knurled_roller(is_lower=true);
    translate([roller_axle_x, chassis_width/2, roller_axle_z + roller_dia + 1.2])
        rotate([0, idler_angle, 0])
            translate([0, 0, -roller_dia/2])
                knurled_roller(is_lower=false);

    // Crank drives the ROLLER shaft (v21): coaxial at roller_axle_x=40 outside
    // the front wall, rigid with the lower roller (grip orbits r=crank_throw
    // about the roller axis at [40,68,60]).
    translate([crank_mount_x, chassis_width+8, roller_axle_z])
        rotate([0, roller_angle, 0])
            translate([-crank_pivot_x, 0, -crank_pivot_z])
                crank_assembly();
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
    hopper_body();
} else if (part_to_render == "shroud") {
    u_channel_shroud();
} else if (part_to_render == "cartridge") {
    seed_cartridge(seed_dia, seed_depth);
} else if (part_to_render == "cones") {
    spool_cones();
} else if (part_to_render == "plow") {
    folding_plow();
} else if (part_to_render == "rollers") {
    pull_rollers();
} else if (part_to_render == "crank") {
    crank_assembly();
} else {
    echo(str("ERROR: unknown part_to_render='", part_to_render, "'."));
    cube([1,1,1]);
}
