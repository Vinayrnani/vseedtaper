/*
    v97 composite take-off + v98 second composite — separate printable parts
    (fused clusters). A/B along Y (y44..68); assembly placement in
    seed_tape_machine_v2.scad; viewer pivots in web/index.html.
    Print orientation: applied in regenerate_glbs.sh (trimesh rotate+drop),
    NOT here. $fn=60 inherited; tol via tolerance/epsilon.
    A10 (T<=12) uses tooth_scale=0.8 (anti-bind); A30 full profile.
*/

// ---- A composite (axis Y): A10 m2 (mesh crank) + A30 m1.25 fused + shaft r4
module dt_cluster_A() {
    assert(v97_A_y1 - v97_A_y0 == 24, "A cluster: shaft span must be 24");
    union() {
        // shaft r4 along Y, local y0..24 (= assembly y44..68)
        rotate([-90, 0, 0])
            cylinder(h=24, r=4, center=false, $fn=60);
        // A10: band 50.5..54.5 (local center 8.5), m2 10T thinned
        translate([0, (v97_A10_y0 + v97_A10_y1)/2 - v97_A_y0, 0])
            rotate([90, 0, 0])
                spur_gear(teeth=10, module_mm=gear_module, thickness=4,
                          tooth_scale=0.8);
        // A30: band 59..64 (local center 17.5), m1.25 30T takeoff
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
    ap_z = h + pitch_r; // apex height (tan45 = 1)
    P = [pitch_r, 0, h]; // back-cone pitch point
    Q = P - [0.7071068, 0, -0.7071068]*7.8; // front pitch point (on generator)
    C = (P + Q)/2;
    eb = 1.45; // blank offset below pitch (perp): uniform gullet depth
    Rb_r = pitch_r - eb*0.7071068; Rb_z = h - eb*0.7071068;
    bslope = Rb_r / (ap_z - Rb_z); // root cone through the SAME apex
    union() {
        // hub taper + apex-converging root cone (teeth sink 0.6 everywhere)
        cylinder(h=8, r1=5.5, r2=9.9, center=false, $fn=60);
        translate([0, 0, 6])
            cylinder(h=8.5, r1=bslope*(ap_z-6), r2=bslope*(ap_z-14.5),
                     center=false, $fn=60);
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

// ---- B composite (axis Y): B10 m1.25 (mesh A30) + Bbev20 m1.0 fused + shaft r4
module dt_cluster_B() {
    assert(v98_B_y1 - v98_B_y0 == 24, "B cluster: shaft span must be 24");
    union() {
        // shaft r4 along Y, local y0..24 (= assembly y44..68)
        rotate([-90, 0, 0])
            cylinder(h=24, r=4, center=false, $fn=60);
        // B10: band 59..64 (local center 17.5), m1.25 10T thinned
        translate([0, (v98_B10_y0 + v98_B10_y1)/2 - v98_B_y0, 0])
            rotate([90, 0, 0])
                spur_gear(teeth=10, module_mm=1.25, thickness=5,
                          tooth_scale=0.8);
        // Bbev20: band 50..58 (local top 8), m1.0, 20 standard teeth
        translate([0, v98_Bbev_y1 - v98_B_y0, 0])
            rotate([90, 0, 0])
                dt_bevel_blank(pitch_r=10, back_r=11.5, h=8, phase_deg=0,
                               teeth_n=20);
    }
}
