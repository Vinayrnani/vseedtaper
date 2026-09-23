/*
    v97 composite take-off + v98 second composite — separate printable parts
    (fused clusters). A y47..83, B y54..83 (tips through the Step-5 outboard wall); assembly placement in
    seed_tape_machine_v2.scad; viewer pivots in web/index.html.
    Print orientation: applied in regenerate_glbs.sh (trimesh rotate+drop),
    NOT here. $fn=60 inherited; tol via tolerance/epsilon.
    A10 full profile 6 wide (matches the crank face); A30 full profile.
*/

// ---- A composite (axis Y): A10 m2 (mesh crank) + A30 m1.25 fused + shaft r4
module dt_cluster_A() {
    assert(v97_A_y1 - v97_A_y0 == 36, "A cluster: shaft span must be 36");
    union() {
        // shaft r4 along Y, local y0..36 (= assembly y47..83, tip through Step-5 wall)
        rotate([-90, 0, 0])
            cylinder(h=36, r=4, center=false, $fn=60);
        // A10: band 49..55 (local center 5), m2 10T FULL profile, 6 wide (Step 8: matches crank face)
        translate([0, (v97_A10_y0 + v97_A10_y1)/2 - v97_A_y0, 0])
            rotate([90, 0, 0])
                spur_gear(teeth=10, module_mm=gear_module, thickness=6,
                          tooth_scale=1.0);
        // A30: band 70..75 (local center 28.5), m1.25 30T takeoff OUTSIDE wall
        translate([0, (v97_A30_y0 + v97_A30_y1)/2 - v97_A_y0, 0])
            rotate([90, 0, 0])
                spur_gear(teeth=30, module_mm=1.25, thickness=5);
    }
}

// ---- TRUE straight bevel gear (axis Z print frame, apex +Z) ----
// Standard tooth form (Tredgold): the SAME trapezoidal hull-of-cylinders
// tooth the repo spur_gear uses (shaped flanks, flat tip land, sunk root)
// placed full-size on the back cone and hulled to its apex-scaled front
// copy — so every flank line converges at the one apex, exactly like a
// real cut bevel. Full thickness (mate TBD gets the backlash). Mitre 45°.
module dt_bevel_blank(pitch_r, back_r, h, phase_deg, teeth_n) {
    assert(teeth_n >= 10 && teeth_n <= 24, "bevel blank: teeth_n must be printable");
    mf = 1.0 / gear_module; // globals are m2-based; this gear is m1.0
    add1 = addendum * mf; ded1 = dedendum * mf;
    tip_d1 = tooth_arc_frac * PI * 1.0;
    rootd1 = 0.72 * PI * 1.0;
    root_c = -(ded1 - 0.3); tip_c = add1 - tip_d1/2; // profile height datum
    k = 0.4485; // front scale (apex convergence over 7.8 face)
    ap_z = h + pitch_r; // apex height (tan45 = 1) — teeth converge here
    P = [pitch_r, 0, h]; // back-cone pitch point
    Q = P - [0.7071068, 0, -0.7071068]*7.8; // front pitch point (on generator)
    C = (P + Q)/2; // tooth-center: hulls span back copy <-> apex-scaled front
    union() {
        // v106 flat web (Step 4b: hub bump REMOVED) — 2mm disc pierced by
        // the shaft; tooth backs fuse into its top, teeth hang below it.
        translate([0, 0, 8 - v103_bev_flange_t])
            cylinder(h=v103_bev_flange_t, r=v103_bev_flange_r, center=false, $fn=60);
        for (i=[0:teeth_n-1])
            rotate([0, 0, i*360/teeth_n + phase_deg])
                translate(C)
                    rotate([0, 45, 0])
                        hull() {
                            translate([3.9, 0, root_c])
                                rotate([0, 90, 0])
                                    cylinder(h=1.0, d=rootd1, $fn=12, center=true);
                            translate([3.9, 0, tip_c])
                                rotate([0, 90, 0])
                                    cylinder(h=1.0, d=tip_d1, $fn=12, center=true);
                            translate([-3.9, 0, root_c*k])
                                rotate([0, 90, 0])
                                    cylinder(h=1.0, d=rootd1*k, $fn=12, center=true);
                            translate([-3.9, 0, tip_c*k])
                                rotate([0, 90, 0])
                                    cylinder(h=1.0, d=tip_c*k, $fn=12, center=true);
                        }
    }
}

// ---- Step-5 outboard support wall (static part): plate y78-81 over both
// axes + 4 pillars fused into the front wall; d8.6 slip bores catch the
// A/B shaft tips (y80). Own printable part (gearwall), absolute CAD coords.
module dt_gearwall() {
    difference() {
        union() {
            // plate
            translate([v105_wall_x0, v105_wall_y0, v105_wall_z0])
                cube([v105_wall_x1 - v105_wall_x0,
                      v105_wall_y1 - v105_wall_y0,
                      v105_wall_z1 - v105_wall_z0]);
            // pillars (y67-80: 1 into the front wall, 2 into the plate)
            for (px = v105_pillar_x) for (pz = v105_pillar_z)
                translate([px - v105_pillar_s/2, 67, pz - v105_pillar_s/2])
                    cube([v105_pillar_s, 13, v105_pillar_s]);
        }
        // A + B shaft slip bores (through + epsilon both faces)
        translate([v97_Ax, v105_wall_y0 - epsilon, v97_Az])
            rotate([90, 0, 0])
                cylinder(h=(v105_wall_y1 - v105_wall_y0) + 2*epsilon,
                         d=axle_clearance_dia, center=false);
        translate([v98_Bx, v105_wall_y0 - epsilon, v98_Bz])
            rotate([90, 0, 0])
                cylinder(h=(v105_wall_y1 - v105_wall_y0) + 2*epsilon,
                         d=axle_clearance_dia, center=false);
    }
}

// ---- B composite (axis Y): B10 m1.25 (mesh A30) + Bbev20 m1.0 fused + shaft r4
module dt_cluster_B() {
    assert(v98_B_y1 - v98_B_y0 == 29, "B cluster: shaft span must be 29");
    union() {
        // shaft r4 along Y, local y0..29 (= assembly y54..83, tip through Step-5 wall)
        rotate([-90, 0, 0])
            cylinder(h=29, r=4, center=false, $fn=60);
        // B10: band 70..75 (local center 28.5), m1.25 10T thinned (Step 3: outside wall, meshes A30)
        translate([0, (v98_B10_y0 + v98_B10_y1)/2 - v98_B_y0, 0])
            rotate([90, 0, 0])
                spur_gear(teeth=10, module_mm=1.25, thickness=5,
                          tooth_scale=0.8);
        // Bbev20: teeth 56..62 near the wall (lift 25.5), m1.0, 20 standard teeth
        translate([0, v106_bev_lift, 0])
            rotate([90, 0, 0])
                dt_bevel_blank(pitch_r=10, back_r=11.5, h=8, phase_deg=0,
                               teeth_n=20);
    }
}
