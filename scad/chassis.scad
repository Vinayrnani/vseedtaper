module south_wall() {
    south_y = chassis_width - wall_thick; // 65: inner mating face
    rib_x0 = 190.5; rib_x1 = 196.5; rib_z1 = 12;
    difference() {
        union() {
            // Step 2 removable SOUTH gear-mount wall, y=65..68.
            translate([chassis_x0, south_y, 0])
                cube([chassis_len, wall_thick, chassis_height]);
            for (spec=[[drum_axle_x,   drum_axle_z,   bb_height_drum,   1],
                       [crank_axle_x,  crank_axle_z,  bb_height_roller, 1],
                       [spool_axle_x,  spool_axle_z,  bb_height_spool,  0]])
                bearing_block(spec[0], spec[1], spec[2], spec[3]==1, chassis_width);
            bearing_block(takeup_x, takeup_z, bb_height_spool, false, chassis_width);
            // South-side tie rib and corner gussets stay attached to the removable wall.
            translate([rib_x0, south_y - 18, 0])
                cube([rib_x1 - rib_x0, 18, rib_z1]);
            for (gy=[chassis_width - 6]) {
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
        // South-wall axle/gear bores.
        translate([spool_axle_x, south_wall_bore_y, spool_axle_z])
            rotate([90,0,0]) cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        translate([takeup_x, south_wall_bore_y, takeup_z])
            rotate([90,0,0]) cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        translate([crank_axle_x, south_wall_bore_y, crank_axle_z])
            rotate([90,0,0]) cylinder(h=wall_thick+2*epsilon, r=hex_clearance_r, $fn=6, center=true);
        translate([drum_axle_x, south_wall_bore_y, drum_axle_z])
            rotate([90,0,0]) cylinder(h=wall_thick+2*epsilon, r=hex_clearance_r, $fn=6, center=true);
        translate([v97_Ax, south_wall_bore_y, v97_Az])
            rotate([90,0,0]) cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        translate([v98_Bx, south_wall_bore_y, v98_Bz])
            rotate([90,0,0]) cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        translate([v115_Ix, south_wall_bore_y, v115_Iz])
            rotate([90,0,0]) cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        // Step 2 M3 interface: wall clearance and outer-face nut trap.
        for (sx=wall_screw_x) {
            translate([sx, south_wall_bore_y, wall_screw_z])
                rotate([90,0,0]) cylinder(h=wall_thick+2*epsilon, d=wall_screw_clearance_d, center=true);
            translate([sx, chassis_width, wall_screw_z])
                rotate([90,0,0]) cylinder(h=nut_trap_depth+epsilon, r=wall_screw_nut_r, $fn=6, center=false);
        }
        // Existing south-side Step-13 M3 wall screws at x192/195, z7.
        for (sx=[192, 195]) {
            translate([sx, south_wall_bore_y, 7])
                rotate([90,0,0]) cylinder(h=wall_thick+2*epsilon, d=bolt_dia+2*tolerance, center=true);
            translate([sx, chassis_width, 7])
                rotate([90,0,0]) cylinder(h=nut_trap_depth+epsilon, r=(bolt_head_across+2*tolerance)/sqrt(3), $fn=6, center=false);
        }
        // South-wall lightening cutout.
        translate([90, south_y - epsilon, 18])
            cube([30, wall_thick+2*epsilon, 22]);
    }
}

module chassis() {
    // Step 1: chassis floor is the exposed planar slab at z=0..4.
    difference() {
        union() {
            translate([chassis_x0, 0, 0])
                cube([chassis_len, chassis_width, base_thick]);
            translate([chassis_x0, 0, 0])
                cube([chassis_len, wall_thick, chassis_height]);
            // Wall-local M3 interface holes are cut below; the floor stays flat.
            // NORTH-side bearing blocks; south-side blocks move to south_wall().
            for (spec=[[drum_axle_x,   drum_axle_z,   bb_height_drum,   1],
                       [crank_axle_x,  crank_axle_z,  bb_height_roller, 1],
                       [spool_axle_x,  spool_axle_z,  bb_height_spool,  0]])
                bearing_block(spec[0], spec[1], spec[2], spec[3]==1, 0);
            bearing_block(takeup_x, takeup_z, bb_height_spool, false, 0);
            // v97: no wall-to-wall drive bars (composite take-off only).
            // v45 DEAD AXLES (static bars, slip-fit through bores/holes):
            // drum hex through-shaft (fuses into the solid v48 drum spur,
            // slip in the drum/interior-gear hex bores + wall/block hex
            // holes — the drum stays free to spin); take-up round shaft
            // (slip in the reel/wall/block round bores); spool round
            // shaft (slip in cone hex holes + wall/block bores, ends hidden
            // in the block bores). Ends buried/hidden, never coplanar.
            // v87 +15: drum 75, takeup rod 49, cone rod (spool) 80.
            translate([drum_axle_x, (drum_shaft_y0 + drum_shaft_y1)/2, drum_axle_z])
                rotate([90, 0, 0])
                    cylinder(h=drum_shaft_y1 - drum_shaft_y0, r=hex_axle_r, $fn=6, center=true);
            translate([takeup_x, (takeup_shaft_y0 + takeup_shaft_y1)/2, takeup_z])
                rotate([90, 0, 0])
                    cylinder(h=takeup_shaft_y1 - takeup_shaft_y0, r=axle_dia/2, center=true);
            translate([spool_axle_x, (spool_shaft_y0 + spool_shaft_y1)/2, spool_axle_z])
                rotate([90, 0, 0])
                    cylinder(h=spool_shaft_y1 - spool_shaft_y0, r=axle_dia/2, center=true);
        }
        // NORTH-wall axle bores; south-wall bores are in south_wall().
        translate([spool_axle_x, wall_thick/2, spool_axle_z])
            rotate([90,0,0]) cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        translate([takeup_x, wall_thick/2, takeup_z])
            rotate([90,0,0]) cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        // Matching wall-local M3 interface in the north wall; south-wall holes are in south_wall().
        for (sx=wall_screw_x) {
            translate([sx, wall_thick/2, wall_screw_z])
                rotate([90,0,0]) cylinder(h=wall_thick+2*epsilon, d=wall_screw_clearance_d, center=true);
            translate([sx, 0, wall_screw_z])
                rotate([-90,0,0]) cylinder(h=nut_trap_depth+epsilon, r=wall_screw_nut_r, $fn=6, center=false);
        }
        // Step 6 plow ear A lateral screw aligns with the north wall hole.
        translate([plow_wall_screw_x, plow_north_wall_y, plow_wall_screw_z])
            rotate([90,0,0]) cylinder(h=wall_thick+2*epsilon, d=bolt_dia+2*tolerance, center=true);
        translate([plow_wall_screw_x, 0, plow_wall_screw_z])
            rotate([-90,0,0]) cylinder(h=nut_trap_depth+epsilon, r=wall_screw_nut_r, $fn=6, center=false);
        // NORTH-wall crank and drum hex bores; south-wall bores are in south_wall().
        translate([crank_axle_x, wall_thick/2, crank_axle_z])
            rotate([90,0,0]) cylinder(h=wall_thick+2*epsilon, r=hex_clearance_r, $fn=6, center=true);
        translate([drum_axle_x, wall_thick/2, drum_axle_z])
            rotate([90,0,0]) cylinder(h=wall_thick+2*epsilon, r=hex_clearance_r, $fn=6, center=true);
        // Step 13: A composite round shaft bore (r4 shaft -> d8.6) through the north wall.
        // A cantilevers from the front-wall bore (demo loads).
        // B composite bore alongside (same mount, r4 shaft -> d8.6).
        translate([v97_Ax, wall_thick/2, v97_Az])
            rotate([90,0,0]) cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        translate([v98_Bx, wall_thick/2, v98_Bz])
            rotate([90,0,0]) cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        translate([v115_Ix, wall_thick/2, v115_Iz])
            rotate([90,0,0]) cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        // Existing north-side Step-13 M3 wall screws remain at x192/195, z7.
        for (sx=[192, 195]) {
            translate([sx, wall_thick/2, 7])
                rotate([90,0,0]) cylinder(h=wall_thick+2*epsilon, d=bolt_dia+2*tolerance, center=true);
            translate([sx, 0, 7])
                rotate([90,0,0]) cylinder(h=nut_trap_depth+epsilon, r=(bolt_head_across+2*tolerance)/sqrt(3), $fn=6, center=false);
        }
        // Ear B keeps the unchanged vertical base screw at world (153,62).
        translate([plow_start + plow_len - 6, 62, base_thick/2])
            cylinder(h=base_thick + 2*epsilon, d=bolt_dia + 2*tolerance, center=true);
        translate([plow_start + plow_len - 6, 62, -epsilon])
            cylinder(h=nut_trap_depth + epsilon,
                     r=(bolt_head_across + 2*tolerance)/sqrt(3), $fn=6, center=false);
        // NORTH-wall lightening cutout; south-wall cutout is in south_wall().
        translate([56, -epsilon, 64])
            cube([24, wall_thick+2*epsilon, 22]);
    }
}

// ============================================================
// 2. Spool cones (tapered, 15-45mm OD) - flat base at Z=0
// ============================================================
