/*
    v97 composite take-off + v98 second composite — separate printable parts
    (fused clusters). A y49.5..83 (tip through the Step-5 outboard wall);
    B y54..80 at the mitre apex (front-wall bore carries mid, tip 2 deep
    in the v117 gearwall bore); assembly placement in
    seed_tape_machine_v2.scad; viewer pivots in web/index.html.
    Print orientation: applied in regenerate_glbs.sh (trimesh rotate+drop),
    NOT here. $fn=60 inherited; tol via tolerance/epsilon.
    A10 full profile 6 wide (matches the crank face); A30 full profile.
*/

// ---- A composite (axis Y): A10 m2 (mesh crank) + A30 m1.25 fused + shaft r4
module dt_cluster_A() {
    assert(v97_A_y1 - v97_A_y0 == 33.5, "A cluster: shaft span must be 33.5");
    union() {
        // shaft r4 along Y, local y0..33.5 (= assembly y49.5..83, tip through Step-5 wall)
        rotate([-90, 0, 0])
            cylinder(h=33.5, r=4, center=false, $fn=60);
        // A10: band 49..55 (local center 2.5), m2 10T FULL profile, 6 wide (Step 8: matches crank face; v124: pinion thinned 0.8 so crank-A10 has tangential clearance like every other mesh — crank stays full for the approved crank-drum mesh)
        translate([0, (v97_A10_y0 + v97_A10_y1)/2 - v97_A_y0, 0])
            rotate([90, 0, 0])
                spur_gear(teeth=10, module_mm=gear_module, thickness=6,
                          tooth_scale=0.8);
        // A30: band 70..75 (local center 23), m1.25 30T takeoff OUTSIDE wall
        translate([0, (v97_A30_y0 + v97_A30_y1)/2 - v97_A_y0, 0])
            rotate([90, 0, 0])
                spur_gear(teeth=30, module_mm=1.25, thickness=5);
    }
}

// ---- Straight-bevel teeth, canonical frame (v113 mitre pair) ----
// Axis +Z, apex at (0,0,zh+pitch_r), body below apex (45° pitch cone).
// Each tooth = hull of heel (full m1.0 profile) + toe (apex-scaled)
// cylinder pairs, Tredgold-style like dt_bevel_blank, tangential
// thickness h_tan (thin = backlash). Callers orient: twister maps +Z
// to +X-east (apex west); B maps +Z to +Y-up (apex below).
module bev_teeth(n, pitch_r, face, h_tan, phase_deg, mod=1.0) {
    zh = pitch_r; // heel axial (= pitch radius @45°)
    c45 = 0.7071068;
    tx = pitch_r - face*c45; tz = zh + face*c45; // toe toward apex
    AH = pitch_r*1.4142136;
    k = (AH - face)/AH; // apex-distance ratio (toe scale)
    rootd = 0.72*PI*mod; tipd = tooth_arc_frac*PI*mod; // standard profile
    root_c = -(1.25*mod-0.3); tip_c = mod - tipd/2; // profile height datum (blank-exact)
    C = [(pitch_r+tx)/2, 0, (zh+tz)/2]; // tooth centre
    for (i=[0:n-1])
        rotate([0, 0, i*360/n + phase_deg])
            translate(C)
                rotate([0, 45, 0])
                    hull() {
                        translate([face/2, 0, root_c])
                            rotate([0, 90, 0])
                                cylinder(h=h_tan, d=rootd, $fn=12, center=true);
                        translate([face/2, 0, tip_c])
                            rotate([0, 90, 0])
                                cylinder(h=h_tan, d=tipd, $fn=12, center=true);
                        translate([-face/2, 0, root_c*k])
                            rotate([0, 90, 0])
                                cylinder(h=h_tan*k, d=rootd*k, $fn=12, center=true);
                        translate([-face/2, 0, tip_c*k])
                            rotate([0, 90, 0])
                                cylinder(h=h_tan*k, d=tipd*k, $fn=12, center=true);
                    }
}
// ---- Step-2 idler (axis Y): 15T m1.25 spur bridging A30 + B10 + shaft r4
// v116: west two-circle solution (154.30, 48.35). Thin 0.8 teeth (mesh
// forgiveness, v95 precedent); phase applied at assembly (half-pitch).
module dt_idler() {
    assert(v115_I_y1 - v115_I_y0 == 14, "idler cluster: shaft span must be 14");
    union() {
        // shaft r4 along Y, local y0..14 (= assembly y66..80, both wall bores carry it)
        rotate([-90, 0, 0])
            cylinder(h=14, r=4, center=false, $fn=60);
        // idler 15T: band 70..75 (local center 6.5), m1.25 thinned, solid
        // centre fused on the shaft (one printable piece, no hub needed)
        translate([0, (v115_I15_y0 + v115_I15_y1)/2 - v115_I_y0, 0])
            rotate([90, 0, 0])
                spur_gear(teeth=15, module_mm=1.25, thickness=5,
                          tooth_scale=v115_I_thin);
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
// axes (v117: z0 40->26) + 4 pillars + 2 z32 extension pillars fused into
// the front wall; d8.6 slip bores carry A + idler + B (v117 B re-added;
// tips: A y83 proud 2, idler/B y80 deep 2). Own printable part
// (gearwall), absolute CAD coords.
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
            // v117 Step 2: extension pillars (z32 row, same 6x6 section) —
            // fuse the lowered plate into the front wall at the B bore level.
            for (px = v105_ext_x)
                translate([px - v105_pillar_s/2, 67, v105_ext_z - v105_pillar_s/2])
                    cube([v105_pillar_s, 13, v105_pillar_s]);
            // Step 13: one same-section top pillar supports the east plate
            // extension without entering either fresh gear band.
            translate([v105_east_pillar_x - v105_pillar_s/2, 67,
                       v105_east_pillar_z - v105_pillar_s/2])
                cube([v105_pillar_s, 13, v105_pillar_s]);
        }
        // A shaft slip bore (through + epsilon both faces). v115: B bore
        // REMOVED — wall is A-only until the next-step intermediate brings
        // B back out (B at z32 missed the plate z40-93; tip y76 below it).
        // v116 Step 2: idler bore ADDED (plate covers (154.3, 48.35); tip
        // y80 sits 2 deep like A) — wall carries A + idler.
        // v117 Step 2: B bore RE-ADDED — plate now reaches z26 (covers the
        // z32 axis) and the B tip runs to y80 — wall carries A+idler+B.
        // v117 Step-2 fix: bores cut UP through the plate ([-90,0,0] maps
        // +Z to +Y; the old [90,0,0] cut below it and never touched the
        // plate — A/idler bores were decorative since v108; all three
        // fixed together because a slip bore that misses its plate is a
        // bug, not a design choice).
        translate([v97_Ax, v105_wall_y0 - epsilon, v97_Az])
            rotate([-90, 0, 0])
                cylinder(h=(v105_wall_y1 - v105_wall_y0) + 2*epsilon,
                         d=axle_clearance_dia, center=false);
        translate([v115_Ix, v105_wall_y0 - epsilon, v115_Iz])
            rotate([-90, 0, 0])
                cylinder(h=(v105_wall_y1 - v105_wall_y0) + 2*epsilon,
                         d=axle_clearance_dia, center=false);
        translate([v98_Bx, v105_wall_y0 - epsilon, v98_Bz])
            rotate([-90, 0, 0])
                cylinder(h=(v105_wall_y1 - v105_wall_y0) + 2*epsilon,
                         d=axle_clearance_dia, center=false);
        // Fresh crank at z75 passes through the extended plate's y78..81
        // band; keep the existing hex-shaft clearance style explicit.
        translate([crank_axle_x, v105_wall_y0 - epsilon, crank_axle_z])
            rotate([-90, 0, 0])
                cylinder(h=(v105_wall_y1 - v105_wall_y0) + 2*epsilon,
                         r=hex_clearance_r, $fn=6, center=false);
    }
}

// ---- B composite (axis Y): B10 m1.25 (idle, next-step intermediate) + Bbev36 m1.25 + shaft r4
// v113: B repositioned to the mitre apex — Bbev mitre-meshes the twister
// bevel ring 1:1 (apex-down bevel). v115: rim size, same OD as the twister
// (heel pitch y56.5 r22.5, toe y53.7 r19.7). Pair held static until the
// intermediate powers it.
module dt_cluster_B() {
    assert(v98_B_y1 - v98_B_y0 == 26, "B cluster: shaft span must be 26");
    union() {
        // shaft r4 along Y, local y0..26 (= assembly y54..80, front-wall bore carries mid)
        rotate([-90, 0, 0])
            cylinder(h=26, r=4, center=false, $fn=60);
        // B10: band 70..75 (local center 18.5), m1.25 10T thinned (idle for the next step)
        translate([0, (v98_B10_y0 + v98_B10_y1)/2 - v98_B_y0, 0])
            rotate([90, 0, 0])
                spur_gear(teeth=10, module_mm=1.25, thickness=5,
                          tooth_scale=0.8);
        // Bbev36: apex-down mitre teeth (canonical +Z mapped to +Y-up,
        // apex at local y=-20 = assembly 34): heel pitch local y2.5
        // (r22.5), toe local y=-0.3 (r19.7), phase 5 tooth-into-gap, thin 0.8.
        translate([0, 25, 0])
            rotate([90, 0, 0])
                bev_teeth(tw_bev_n, 22.5, tw_bev_face, v113_B_thin, v113_B_phase, tw_bev_mod);
        // Step 4 full-radius backing web behind the nominal heel plane.
        // It overlaps the existing root frustum by 0.3mm and stops before
        // the toe/mesh plane; the shaft and root remain one fused cluster.
        translate([0, 25, 0])
            rotate([90, 0, 0])
                translate([0, 0, B_back_web_z0])
                    cylinder(h=B_back_web_t, r=B_back_web_r, center=false, $fn=60);
        // Existing root cone frustum, now named for the Step 4 overlap assert.
        translate([0, 25, 0])
            rotate([90, 0, 0])
                translate([0, 0, B_root_frustum_z0])
                    cylinder(h=B_root_frustum_z1 - B_root_frustum_z0,
                             r1=B_root_frustum_r0, r2=B_root_frustum_r1,
                             center=false, $fn=60);
    }
}
