/*
    v95 from-crank gear train — separate printable parts (fused clusters).
    Frames: Y-clusters built along Y at (0, y0..y1, 0); X-clusters along X
    at (x0..x1, 0, 0); bar1 absolute. Assembly placement in
    seed_tape_machine_v2.scad; viewer pivots in web/index.html.
    Print orientation: applied in regenerate_glbs.sh (trimesh rotate+drop),
    NOT here. $fn=60 inherited; tol via tolerance/epsilon.
    Pinions T<=12 use tooth_scale=0.8 (anti-bind); big gears 1.0.
*/

// ---- A cluster (axis Y): A10 m2 (mesh crank) + A30 m1.25 fused + shaft r4
module dt_cluster_A() {
    assert(v95_A_y1 - v95_A_y0 == 24, "A cluster: shaft span must be 24");
    union() {
        // shaft r4 along Y, local y0..24 (= assembly y44..68)
        rotate([-90, 0, 0])
            cylinder(h=24, r=4, center=false, $fn=60);
        // A10: band 50.5..54.5 (local center 8.5), m2 10T thinned
        translate([0, (v95_A10_y0 + v95_A10_y1)/2 - v95_A_y0, 0])
            rotate([90, 0, 0])
                spur_gear(teeth=10, module_mm=gear_module, thickness=4,
                          tooth_scale=0.8);
        // A30: band 59..64 (local center 17.5), m1.25 30T
        translate([0, (v95_A30_y0 + v95_A30_y1)/2 - v95_A_y0, 0])
            rotate([90, 0, 0])
                spur_gear(teeth=30, module_mm=1.25, thickness=5);
    }
}

// ---- custom bevel blank (axis Z print frame): frustum + 10 flank teeth ----
module dt_bevel_blank(pitch_r, back_r, h, phase_deg) {
    union() {
        cylinder(h=h, r1=back_r, r2=back_r - h*0.45, center=false, $fn=60);
        for (i=[0:9])
            rotate([0, 0, i*36 + phase_deg])
                translate([pitch_r - 0.5, 0, h*0.45])
                    rotate([0, -28, 0])
                        cube([3.2, 1.5, 4.2], center=true);
    }
}

// ---- B cluster (axis Y): B10 m1.25 + bevel foot fused + shaft r4
module dt_cluster_B() {
    union() {
        // shaft r4 along Y, local y0..24 (= assembly y44..68)
        rotate([-90, 0, 0])
            cylinder(h=24, r=4, center=false, $fn=60);
        // B10: band 59..64 (local center 17.5), m1.25 10T thinned
        translate([0, (v95_B10_y0 + v95_B10_y1)/2 - v95_B_y0, 0])
            rotate([90, 0, 0])
                spur_gear(teeth=10, module_mm=1.25, thickness=5,
                          tooth_scale=0.8);
        // B bevel: band 44..52 (local 0..8, blank z0-8 maps to y0..-8: shift +8)
        translate([0, v95_Bbev_y1 - v95_B_y0, 0])
            rotate([90, 0, 0])
                dt_bevel_blank(pitch_r=6.25, back_r=8, h=8, phase_deg=0);
    }
}

// ---- C cluster (axis X): shaft r3 + C15 + C bevel fused
module dt_cluster_C() {
    assert(v95_C_x1 - v95_C_x0 == 17, "C cluster: shaft span must be 17");
    union() {
        // shaft r3, local x0..17 (= assembly x164..181)
        rotate([0, 90, 0])
            cylinder(h=17, r=3, center=false, $fn=60);
        // C15: band 169..175 (local center 8), m1.25 15T
        translate([(v95_C15_x0 + v95_C15_x1)/2 - v95_C_x0, 0, 0])
            rotate([0, 90, 0])
                spur_gear(teeth=15, module_mm=1.25, thickness=6);
        // C bevel: band 175..181 (local 11..17), blank r6, teeth phased 18 (interleave)
        translate([v95_Cbev_x0 - v95_C_x0, 0, 0])
            rotate([0, 90, 0])
                dt_bevel_blank(pitch_r=6.25, back_r=6, h=6, phase_deg=18);
    }
}

// ---- D cluster (axis X): shaft r3 + hub r8 + D12 fused
module dt_cluster_D() {
    assert(v95_D_x1 - v95_D_x0 == 19, "D cluster: shaft span must be 19");
    union() {
        // shaft r3, local x0..19 (= assembly x178..197)
        rotate([0, 90, 0])
            cylinder(h=19, r=3, center=false, $fn=60);
        // hub barrel r8: 182..192 (local 4..14)
        translate([v95_hub_x0 - v95_D_x0, 0, 0])
            rotate([0, 90, 0])
                cylinder(h=v95_hub_x1 - v95_hub_x0, r=8, center=false, $fn=60);
        // D12: band 192..197 (local center 16.5), m1.25 12T thinned
        translate([(v95_D12_x0 + v95_D12_x1)/2 - v95_D_x0, 0, 0])
            rotate([0, 90, 0])
                spur_gear(teeth=12, module_mm=1.25, thickness=5,
                          tooth_scale=0.8);
    }
}

// ---- O-tire (separate rubber part, axis X at origin, torus R8.875/tube 1.125)
module dt_tire() {
    rotate([0, 90, 0])
        rotate_extrude(convexity=4, $fn=60)
            translate([8.875, 0, 0])
                circle(r=1.125, $fn=24);
}

// ---- Idler cluster (axis X): shaft r3 + I1 + I2 fused
module dt_cluster_I() {
    assert(v95_I_x1 - v95_I_x0 == 35, "idler cluster: shaft span must be 35");
    union() {
        // shaft r3, local x0..35 (= assembly x165..200)
        rotate([0, 90, 0])
            cylinder(h=35, r=3, center=false, $fn=60);
        // I1: band 169..175 (local center 7), m1.25 12T thinned
        translate([(v95_I1_x0 + v95_I1_x1)/2 - v95_I_x0, 0, 0])
            rotate([0, 90, 0])
                spur_gear(teeth=12, module_mm=1.25, thickness=6,
                          tooth_scale=0.8);
        // I2: band 192..197 (local center 29.5), m1.25 12T thinned
        translate([(v95_I2_x0 + v95_I2_x1)/2 - v95_I_x0, 0, 0])
            rotate([0, 90, 0])
                spur_gear(teeth=12, module_mm=1.25, thickness=5,
                          tooth_scale=0.8);
    }
}

// ---- bar1 back-wall rail (absolute coords, static): beam + 3 bores + B10 slot
module dt_bar1() {
    difference() {
        // beam: x184..190, y1..67 (1mm wall seams), z60..90
        translate([v95_bar1_x0, 1, v95_bar1_z0])
            cube([v95_bar1_x1 - v95_bar1_x0, 66, v95_bar1_z1 - v95_bar1_z0],
                 center=false);
        // B10 slot (gear rides through): y58..65, z60..79, full beam width
        translate([v95_bar1_x0 - epsilon, v95_bar1_slot0, v95_bar1_z0 - epsilon])
            cube([v95_bar1_x1 - v95_bar1_x0 + 2*epsilon,
                  v95_bar1_slot1 - v95_bar1_slot0, 79 - v95_bar1_z0 + epsilon],
                 center=false);
        // B bore (r4 shaft -> d8.6) along +Y at (Bx, Bz)
        translate([v95_Bx, 1 - epsilon, v95_Bz])
            rotate([-90, 0, 0])
                cylinder(h=70, d=axle_clearance_dia, center=false, $fn=60);
        // D bore (r3 shaft -> d6.6) along X at (Dy, Dz)
        translate([v95_bar1_x0 - epsilon, v95_D_y, v95_D_z])
            rotate([0, 90, 0])
                cylinder(h=v95_bar1_x1 - v95_bar1_x0 + 2*epsilon, d=6.6,
                         center=false, $fn=60);
        // Idler bore (r3 shaft -> d6.6) along X at (Iy, Iz)
        translate([v95_bar1_x0 - epsilon, v95_I_y, v95_I_z])
            rotate([0, 90, 0])
                cylinder(h=v95_bar1_x1 - v95_bar1_x0 + 2*epsilon, d=6.6,
                         center=false, $fn=60);
    }
}
