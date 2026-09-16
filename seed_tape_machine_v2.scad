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
seed_spacing  = 152;
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

// Circumference for tooth angular spacing
roller_circ_pitch = PI * gear_module;
drum_circ_pitch   = PI * gear_module;
tooth_arc_roller = tooth_arc_frac * roller_circ_pitch;
tooth_arc_drum   = tooth_arc_frac * drum_circ_pitch;

// Kinematics
tape_per_crank_rev = PI * roller_dia;         // ~62.83
drum_rot_per_crank = 0.5;
tape_per_drum_rev  = PI * drum_dia;           // ~157.08
num_divots         = max(1, round(tape_per_drum_rev / seed_spacing)); // =1
achieved_spacing   = tape_per_drum_rev / num_divots;

// ============================================================
// Axle layout (X,Z in OpenSCAD coords: X=tape travel, Z=up)
// Layout: spool(10,65) → drum(100,60) → plow(126+) → roller(160,30)
// Tape path: spool → under drum (cradle) → plow → pull rollers
// Gear mesh: drum_axle_x=100, roller_axle_x=160 → distance=60mm ✓
// ============================================================
drum_axle_x  = 100;
drum_axle_z  = 60;   // ≥ drum_radius + base_thick + clearance = 29.3 ✓
roller_axle_x = 160; // center_distance=60 from drum ✓
roller_axle_z = 60;  // same Z as drum for gear mesh; ≥ roller_outer_dia/2+1=23 ✓
// Gear mesh: drum(100,60) to roller(160,60) → distance=60mm ✓
spool_axle_x  = 10;
spool_axle_z  = 65;  // 120mm max roll OD, height 65mm above base

// ============================================================
// Chassis
// ============================================================
chassis_len   = 200;
chassis_width = 60;
chassis_height = 110;  // > max(spool top=90, drum top=102) + 5 = 107 ✓
base_thick    = 4;
wall_thick    = 3;

// ============================================================
// Plow
// ============================================================
plow_start    = drum_axle_x + drum_radius + 1; // 126
plow_end      = roller_axle_x - 1;
plow_len      = plow_end - plow_start;
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
// Hopper (LEFT 135°→225°)
// ============================================================
hopper_wall     = 2.5;
hopper_flange_thick = 3;
hopper_clearance = 0.3;
hopper_inner_r  = drum_radius + hopper_clearance; // 25.3
hopper_outer_r  = hopper_inner_r + seed_dia + 3;  // 30.8
hopper_axis_z   = drum_axle_z - base_thick;       // 56
wiper_slot      = 1.2;

// ============================================================
// Crank
// ============================================================
crank_throw     = 45;
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
assert(seed_dia > 0 && seed_dia <= 5.0, "seed_dia must be (0,5.0]");
assert(seed_depth > 0 && seed_depth < drum_radius, "seed_depth must be >0 and < drum_radius");
assert(seed_spacing > 10 && seed_spacing < 500, "seed_spacing out of plausible range");
assert(gear_module > 0, "gear_module must be >0");
assert(center_distance == (roller_teeth + drum_teeth) * gear_module / 2,
       str("center_distance must be 60 for 20T/40T module=2, got ", center_distance));
assert(num_divots >= 1 && num_divots <= 20, "num_divots out of range");
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
            cube([chassis_len, chassis_width, base_thick]);
            cube([chassis_len, wall_thick, chassis_height]);
            translate([0, chassis_width - wall_thick, 0])
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
                translate([4, gy, base_thick - 0.15])
                    hull() {
                        cube([12, 6, 1.15]);
                        translate([0, 0, 12]) cube([1.5, 6, 1]);
                    }
                translate([chassis_len - 16, gy, base_thick - 0.15])
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
        translate([0, chassis_width/2, base_thick])
            rotate([0,45,0])
                cube([2.5, chassis_width + 2*epsilon, 2.5], center=true);
        translate([chassis_len, chassis_width/2, base_thick])
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
// 3. Hopper body (LEFT 135°→225°) - flat base at Z=0
// ============================================================
module hopper_body() {
    res_y = drum_width + 2*tolerance;
    cheek_t = hopper_wall;
    cheek_inner = drum_width/2 + tolerance;
    res_len = res_y + 0.3;
    drop_cx = -drum_radius - 7;
    drop_bore = 6;
    drop_bore_h = drop_bore;
    drop_wall = 2;
    drop_outer = drop_bore + 2*drop_wall;
    drop_top_z = hopper_axis_z + hopper_inner_r + 2;
    drop_bot_z = 5;
    hood_r_out = hopper_outer_r;

    difference() {
        union() {
            // Reservoir outer sector
            difference() {
                translate([0, 0, hopper_axis_z])
                    rotate([90,0,0])
                        cylinder(h=res_len, r=hopper_outer_r, center=true);
                translate([-100 - epsilon, -50, -50])
                    cube([100, 100, 150]);
                // 135deg line (LEFT side)
                translate([0, 0, hopper_axis_z])
                    rotate([0,-135,0])
                        translate([-1, -50, 0])
                            cube([101, 100, 60]);
                // 225deg line
                translate([0, 0, hopper_axis_z])
                    rotate([0,-225,0])
                        translate([-1, -50, -60])
                            cube([101, 100, 60]);
            }
            // End caps
            translate([0, 0, hopper_axis_z])
                rotate([0,-135,0])
                    translate([hopper_inner_r - 0.15, -res_y/2, -1.25])
                        cube([hopper_outer_r - hopper_inner_r + 0.3, res_y, 2.5]);
            translate([0, 0, hopper_axis_z])
                rotate([0,-225,0])
                    translate([hopper_inner_r - 0.15, -res_y/2, -1.25])
                        cube([hopper_outer_r - hopper_inner_r + 0.3, res_y, 2.5]);
            // Cheek plates (hug drum flat faces, axial gap = tolerance)
            for (s=[-1,1]) {
                translate([-5, s > 0 ? cheek_inner : -cheek_inner - cheek_t, 0])
                    cube([hopper_outer_r + 7, cheek_t, hopper_axis_z + hopper_outer_r]);
            }
            // Legs
            for (s=[-1,1]) {
                leg_y0 = s > 0 ? cheek_inner : -cheek_inner - cheek_t;
                translate([-5, leg_y0, 3 - 0.15])
                    cube([30, cheek_t, 24]);
            }
            // Foot pads
            translate([-20, -23, 0]) cube([40, 6, 3]);
            translate([-20, 17, 0]) cube([40, 6, 3]);
            // Foot bolts
            for (py=[-20, 20])
                for (px=[-12, 12]) {
                    translate([px, py, 0]) cylinder(h=3, d=bolt_dia, center=false);
                    translate([px, py, 0.5]) cylinder(h=2.5, r=bolt_head_across/sqrt(3), $fn=6, center=false);
                }
            // Rim flange + lid with knob
            cheek_top_z = hopper_axis_z + hopper_outer_r;
            for (s=[-1,1]) {
                rim_y0 = s > 0 ? cheek_inner - 1.5 : -cheek_inner - cheek_t - 1.5;
                translate([-6, rim_y0, cheek_top_z - 0.15])
                    cube([hopper_outer_r + 14, cheek_t + 3, 1.5]);
            }
            translate([-6, -(res_y/2 + cheek_t + 2.5), cheek_top_z + 1.2 - 0.15])
                cube([hopper_outer_r + 14, res_y + 2*cheek_t + 5, 2]);
            translate([14, 0, cheek_top_z + 2.55]) cylinder(h=5.5, d=8, center=false);
            translate([14, 0, cheek_top_z + 8.05]) sphere(r=4.5, $fn=24);
            // Drop tube
            translate([drop_cx - drop_outer/2, -drop_outer/2, drop_bot_z - epsilon])
                cube([drop_outer, drop_outer, drop_top_z - drop_bot_z + epsilon]);
        }
        // Subtractions
        translate([0, 0, hopper_axis_z])
            rotate([90,0,0])
                cylinder(h=res_len + 2*cheek_t + 2*epsilon, r=hopper_inner_r, center=true);
        translate([0, 0, hopper_axis_z])
            rotate([90,0,0])
                cylinder(h=res_y + 2*epsilon, r=hopper_inner_r, center=true);
        translate([0, 0, hopper_axis_z])
            rotate([90,0,0])
                cylinder(h=res_y + 2*cheek_t + 2*epsilon, r=hex_clearance_r, $fn=6, center=true);
        // Wiper slot at ~135deg
        translate([0, 0, hopper_axis_z])
            rotate([0,-135,0])
                translate([hopper_inner_r - 2, -(res_y/2 + cheek_t + epsilon), -wiper_slot/2])
                    cube([8, res_y + 2*cheek_t + 2*epsilon, wiper_slot]);
        // Drop-tube bore
        translate([drop_cx - drop_bore_h/2, -drop_bore_h/2, drop_bot_z - 2*epsilon])
            cube([drop_bore_h, drop_bore_h, drop_top_z - drop_bot_z + 3*epsilon]);
        // Foot bolt holes
        for (py=[-20, 20])
            for (px=[-12, 12]) {
                translate([px, py, -epsilon]) cylinder(h=3 + 2*epsilon, d=bolt_dia + 2*tolerance, center=false);
                translate([px, py, 1]) cylinder(h=2 + epsilon, r=(bolt_head_across + 2*tolerance)/sqrt(3), $fn=6, center=false);
            }
    }
}

// ============================================================
// 4. U-Channel Shroud (RIGHT 60°→270°) - flat base at Z=0
// ============================================================
module u_channel_shroud() {
    r = drum_radius + 1.5; // 26.5 placement radius
    id = shroud_id; // 8mm bore (inner radial dimension)
    wall = 2;
    height = drum_width + 2*tolerance;
    outer_r = r + wall/2;

    translate([0, 0, height/2]) // shift up so min_z=0
    difference() {
        // Partial cylindrical shell via rotate_extrude, swept 60°→270° (210°)
        rotate([0,0,60])
            rotate_extrude(angle=210, convexity=10)
                translate([outer_r, 0, 0])
                    square([wall, height], center=true);
        // Inner bore (ID=8mm)
        translate([0, 0, 0])
            cylinder(r=id/2, h=height+2*epsilon, center=true);
        // Flat foot at bottom (drop port at 270° aligned over tape centerline)
        translate([0, -height/2 - wall, -wall])
            cube([2*outer_r + 10, height + 2*wall, wall]);
    }
}

// ============================================================
// 5. Seed cartridge (drum) with chamfered divot mouths + end flange rings
// ============================================================
module seed_cartridge(sdia = seed_dia, sdepth = seed_depth) {
    assert(sdia > 0 && sdia <= 5.0, "seed_cartridge: seed_dia out of range (0,5]");
    assert(sdepth > 0 && sdepth < drum_radius, "seed_cartridge: seed_depth invalid");
    drum_len = drum_width;
    gear_thick = 6;

    if (part_to_render == "cartridge" || part_to_render == "drum") {
        // VERTICAL orientation for STL export (base at Z=0)
        union() {
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
            for (fz=[0.15, drum_len - 3.25])
                translate([0, 0, fz])
                    difference() {
                        cylinder(h=1.5, d=drum_dia + 3, center=false);
                        translate([0, 0, -epsilon])
                            cylinder(h=1.5 + 2*epsilon, d=drum_dia - 6, center=false);
                    }
            // Drum gear (lightened, 40T)
            translate([0,0, drum_len + gear_thick/2 + drum_len/2 - epsilon])
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
                translate([0, roller_len/2 + gear_thick/2 - epsilon, 0])
                    rotate([90,0,0])
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
    zoffset = 11; // shift up so min_z=0

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
                // Lower: driven gear + hex shaft + collar
                translate([0,0, len - epsilon + gear_thick/2])
                    spur_gear(teeth=roller_teeth, module_mm=gear_module, thickness=gear_thick,
                              bore_flat=hex_axle_flat, is_hex=true,
                              hub_dia=16, hub_len=10, collar_dia=14, collar_len=3);
                translate([0,0, len + gear_thick - epsilon])
                    cylinder(h=14, r=hex_axle_r, $fn=6, center=false);
                translate([0,0, len + gear_thick - epsilon - 1])
                    cylinder(h=1.2, r=6, center=false);
                translate([0,0, len + gear_thick + 4])
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
            if (is_lower)
                translate([0,0, 0.15])
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
                translate([0, len/2 + gear_thick/2 - epsilon, 0])
                    rotate([90,0,0])
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
// Sign convention: drum_angle = 360*$t CLOCKWISE about +Y (viewed +X right, +Z up)
//   lower roller + crank = −720*$t (driven by crank, 2:1 gear ratio from drum)
//   upper idler = +720*$t (counter-rotate via tape contact)
// At $t=0 geometry equals static layout.
// ============================================================
module animated_assembly() {
    drum_angle = 360*$t;     // CLOCKWISE about +Y
    crank_angle = -720*$t;   // lower roller + crank orbit
    idler_angle = 720*$t;    // upper idler counter-rotates

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

    // Hopper (LEFT 135-225°)
    translate([drum_axle_x, chassis_width/2, drum_axle_z - hopper_axis_z])
        hopper_body();

    // U-Channel Shroud (RIGHT 60-270°) - zoffset=height/2 compensated
    translate([drum_axle_x, chassis_width/2, drum_axle_z])
        translate([0, 0, drum_radius + 1.5 - (drum_width + 2*tolerance)/2])
            u_channel_shroud();

    // Seed cradle
    translate([plow_start, chassis_width/2 - 12.7, base_thick])
        seed_cradle();

    // Folding plow
    translate([plow_start, chassis_width/2 - 20, base_thick])
        folding_plow();

    // Pull rollers (zoffset=11 compensated in assembly)
    translate([roller_axle_x, chassis_width/2, roller_axle_z])
        rotate([0, crank_angle, 0])
            translate([0, 0, -roller_dia/2])
                knurled_roller(is_lower=true);
    translate([roller_axle_x, chassis_width/2, roller_axle_z + roller_dia + 1.2])
        rotate([0, idler_angle, 0])
            translate([0, 0, -roller_dia/2])
                knurled_roller(is_lower=false);

    // Crank orbiting lower roller axle (grip center traces circle of radius crank_throw)
    translate([roller_axle_x, chassis_width+8, roller_axle_z])
        rotate([0, crank_angle, 0])
            translate([-crank_pivot_x, 0, -crank_pivot_z])
                crank_assembly();
}

module assemble_all() {
    animated_assembly();
}

// ============================================================
// Diagnostics + part selection (fail-loud else)
// ============================================================
echo(str("Params: roller_dia=", roller_dia, " drum_dia=", drum_dia,
         " center_distance=", center_distance,
         " tape_per_rev=", tape_per_drum_rev,
         " num_divots=", num_divots,
         " achieved_spacing=", achieved_spacing));
if (num_divots == 1) {
    echo(str("NOTE: seed_spacing (", seed_spacing, "mm) ≈ tape_per_drum_rev (", tape_per_drum_rev, "mm) so num_divots=1."));
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
