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
    // Axis 28 (v87 +15 from 13): exit bore lands DEAD on the twister
    // bore (assembly lifts +base_thick=4 -> world 32 = twister_axle_z,
    // y 20+10=34 = ring centre), so the exit faces the twister straight;
    // entry mouth rims sit at lane height. Supports: 2 ground pedestals
    // fused under the sheet floor (tops +15: 19.3/22.7) + straps to 2
    // chassis ears on the M3 holes (world 132/6, 153/62).
    cy = 20;                        // sheet centre (local y, world tape centre 34 = lane_y)
    axis_z = 28;                    // v87 +15: sheet axis height (exit = twister bore height)
    mouth_x0 = -12;                 // sheet mouth (world 114, exit lands 159)
    pedA = [6, 8, 12, 28, 19.3];    // v87 +15: mid pedestal x0,x1,y0,y1,top (floor ~18.9)
    pedB = [24.5, 26.5, 14, 26, 22.7]; // v87 +15: exit pedestal x0,x1,y0,y1,top (floor ~22.3)
    ear = 6;                        // ear edge length (6x6 footprint)
    ear_t = 1;                      // ear flange thickness (stack-up keeps 1)
    mount_h = ear_t + 15;           // v87 +15: ear/strap column height z0..16 (base-fused)
    earA = [3, -11];                // ear A corner, centre (6,-8) -> world (132,6)
    earB = [24, 45];                // ear B corner, centre (27,48) -> world (153,62)
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
    assert(cy == 20, "six_turner: sheet must stay centred on the tape (local 20, world 34 = ring centre)");
    assert(axis_z == 28, "six_turner: axis must stay 28 (exit bore meets twister bore)");
    assert(axis_z + base_thick == twister_axle_z, "six_turner: exit axis must meet the twister bore height (world 32, assembly at base_thick)");
    assert(axis_z == 28 && axis_z + base_thick == 32, "six_turner: +15 lift stack (axis 28 local + base 4 = world 32)");
    assert(axis_z - 12 - thickness/2 >= 0.1, "six_turner: mouth floor must stay above the base");
    // Pedestal fuse: tops embed ~0.4 into the sheet floor wall
    // (floor outer ~18.9 mid / ~22.3 exit, wall 1.6, void stays clear).
    // v87 +15 lift: ped tops +15 (4.3→19.3, 7.7→22.7) to meet lifted axis_z=28.
    assert(pedA[4] >= 18.5 && pedA[4] <= 20.0, "six_turner: mid pedestal top must land in the floor wall");
    assert(pedB[4] >= 21.8 && pedB[4] <= 23.9, "six_turner: exit pedestal top must land in the floor wall");
    assert(abs(pedA[4] - 19.3) < 0.001 && abs(pedB[4] - 22.7) < 0.001,
        "six_turner: pedestal tops must be +15 lift values (19.3 / 22.7)");
    assert(pedA[0] >= mouth_x0 && pedA[1] <= mouth_x0 + length, "six_turner: mid pedestal must sit under the sheet");
    assert(pedB[0] >= mouth_x0 && pedB[1] <= mouth_x0 + length, "six_turner: exit pedestal must sit under the sheet");
    // Screw ears: 6x6x1 diagonal pair on the chassis M3 holes, straps
    // tie the pedestal feet (volumetric overlaps).
    assert(ear == 6 && ear_t == 1, "six_turner: ears must stay 6x6x1 (small, minimal)");
    assert(earA[0] + ear/2 == 6 && earB[0] + ear/2 == turner_len - 6
        && earA[0] + ear/2 + plow_start == 132 && earB[0] + ear/2 + plow_start == 153,
        "six_turner: ear holes must hit chassis X (world 132/153)");
    assert(earA[1] + ear/2 + (chassis_width/2 - 20) == 6 && earB[1] + ear/2 + (chassis_width/2 - 20) == 62,
        "six_turner: ear holes must hit chassis rows (world 6/62)");
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
                // Screw ears (z0..mount_h, M3 holes to the chassis).
                translate([earA[0], earA[1], 0]) cube([ear, ear, mount_h]);
                translate([earB[0], earB[1], 0]) cube([ear, ear, mount_h]);
                // Ground straps (z0..mount_h, tie ears to pedestal feet).
                translate([3, -11, 0]) cube([6, 25, mount_h]);
                translate([24, 20, 0]) cube([6, 25, mount_h]);
                // Support pedestals (tops fused into the sheet floor wall).
                translate([pedA[0], pedA[2], 0]) cube([pedA[1] - pedA[0], pedA[3] - pedA[2], pedA[4]]);
                translate([pedB[0], pedB[2], 0]) cube([pedB[1] - pedB[0], pedB[3] - pedB[2], pedB[4]]);
            }
            // Ear M3 clearance holes (only voids; full mount_h depth).
            translate([earA[0]+ear/2, earA[1]+ear/2, -epsilon])
                cylinder(h=mount_h+2*epsilon, d=hole_d, center=false);
            translate([earB[0]+ear/2, earB[1]+ear/2, -epsilon])
                cylinder(h=mount_h+2*epsilon, d=hole_d, center=false);
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
