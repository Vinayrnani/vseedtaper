// v121 Step 7: single_cone/spool_cones deleted with the cones (no callers remain).

// Step 5: final hopper-mounted U guide. All dimensions are in hopper-local F;
// the assembly places this module at guide_assembly_t = [100,34,19].
module u_guide() {
    assert(abs((guide_tape_z0_local - guide_floor_z1) - 0.3) < 0.001
        && abs((guide_pipe_z0_local - guide_floor_z1) - 10.7) < 0.001
        && abs((guide_bridge_z0 - guide_tape_z1_local) - 0.3) < 0.001
        && abs((guide_foot_y0 - paper_width/2) - 0.3) < 0.001,
        "u_guide: final floor/tape/pipe/bridge/foot clearances must remain exact");
    assert(guide_pipe_od == drop_pipe_od
        && guide_rail_y0 - guide_pipe_od/2 == guide_pipe_gap
        && guide_bridge_y0 - guide_pipe_od/2 == guide_pipe_gap,
        "u_guide: rails and bridges must stay guide_pipe_gap off the (widened) pipe OD");
    difference() {
        union() {
            translate([guide_x0, guide_y0, guide_floor_z0])
                cube([guide_x1-guide_x0, guide_y1-guide_y0, guide_floor_z1-guide_floor_z0]);
            for (s=[-1, 1]) {
                // Keep both sides symmetric by deriving absolute low/high Y
                // limits before creating each positive-length cube.
                rail_y0 = min(s*guide_rail_y0, s*guide_rail_y1);
                rail_y1 = max(s*guide_rail_y0, s*guide_rail_y1);
                bridge_y0 = min(s*guide_bridge_y0, s*guide_bridge_y1);
                bridge_y1 = max(s*guide_bridge_y0, s*guide_bridge_y1);
                foot_y0 = min(s*guide_foot_y0, s*guide_foot_y1);
                foot_y1 = max(s*guide_foot_y0, s*guide_foot_y1);
                pad_y0 = min(s*guide_pad_y0, s*guide_pad_y1);
                pad_y1 = max(s*guide_pad_y0, s*guide_pad_y1);
                assert(rail_y0 == (s > 0 ? guide_rail_y0 : -guide_rail_y1)
                    && rail_y1 == (s > 0 ? guide_rail_y1 : -guide_rail_y0)
                    && bridge_y0 == (s > 0 ? guide_bridge_y0 : -guide_bridge_y1)
                    && bridge_y1 == (s > 0 ? guide_bridge_y1 : -guide_bridge_y0)
                    && foot_y0 == (s > 0 ? guide_foot_y0 : -guide_foot_y1)
                    && foot_y1 == (s > 0 ? guide_foot_y1 : -guide_foot_y0)
                    && pad_y0 == (s > 0 ? guide_pad_y0 : -guide_pad_y1)
                    && pad_y1 == (s > 0 ? guide_pad_y1 : -guide_pad_y0),
                    str("u_guide: rail/bridge/foot/pad spans must be exact Y mirrors: rail ",
                        rail_y0, "..", rail_y1));
                translate([guide_x0, rail_y0, guide_rail_z0])
                    cube([guide_x1-guide_x0, rail_y1-rail_y0, guide_rail_z1-guide_rail_z0]);
                translate([guide_x0, bridge_y0, guide_bridge_z0])
                    cube([guide_x1-guide_x0, bridge_y1-bridge_y0, guide_bridge_z1-guide_bridge_z0]);
                translate([guide_x0, foot_y0, guide_foot_z0])
                    cube([guide_x1-guide_x0, foot_y1-foot_y0, guide_foot_z1-guide_foot_z0]);
                translate([-guide_pad_x, pad_y0, guide_pad_z0])
                    cube([2*guide_pad_x, pad_y1-pad_y0, guide_pad_z1-guide_pad_z0]);
            }
            // Step 6 seed cap: the tape is folded U-shaped by the former, so the
            // seeds are now carried in a pocket BELOW the pipe. This cap is not a
            // floating part - it is part of the bracket-supported guide: it is
            // FUSED onto both rails (0.2 overlap, never a coplanar touch) and
            // stops 0.4 under the pipe OD. It holds the seeds in.
            translate([guide_cap_x0, -guide_cap_y, guide_cap_z0])
                cube([guide_cap_x1-guide_cap_x0, 2*guide_cap_y, guide_cap_z1-guide_cap_z0]);
        }
        // Seed passage through the cap: it is wider than the pipe bore
        // (guide_cap_hole_d >= drop_pipe_id, asserted in params) so the seeds
        // fall from the pipe straight into the forming pocket.
        translate([guide_cap_hole_x, 0, guide_cap_z0 - 1])
            cylinder(h = guide_cap_z1-guide_cap_z0+2, d = guide_cap_hole_d);
        // Each mirrored pad gets its own matching screw clearance and trap.
        for (s=[-1, 1]) {
            screw1_y0 = min(s*guide_screw1_y0, s*guide_screw1_y1);
            screw1_y1 = max(s*guide_screw1_y0, s*guide_screw1_y1);
            trap_y0 = min(s*guide_trap_y0, s*guide_trap_y1);
            trap_y1 = max(s*guide_trap_y0, s*guide_trap_y1);
            assert(screw1_y0 == (s > 0 ? 6.95 : -11.05)
                && screw1_y1 == (s > 0 ? 11.05 : -6.95)
                && trap_y0 == (s > 0 ? 9.3 : -11)
                && trap_y1 == (s > 0 ? 11 : -9.3),
                "u_guide: screw clearance/trap spans must be exact Y mirrors");
            translate([guide_screw1_x, screw1_y0, guide_screw1_z])
                rotate([-90,0,0]) cylinder(h=screw1_y1-screw1_y0,
                    d=m2_clearance_dia, center=false);
            translate([guide_screw1_x, trap_y0, guide_screw1_z])
                rotate([-90,0,0]) cylinder(h=trap_y1-trap_y0,
                    r=m2_trap_af/sqrt(3), $fn=6, center=false);
        }
    }
}

// Step 5: one right printable bracket. The assembly mirrors this module in Y.
module u_guide_bracket() {
    assert(bracket_plate_y1 - bracket_plate_y0 == 4
        && bracket_screw2_y == 11 && bracket_screw2_z == 15
        && abs((guide_trap_y1 - guide_trap_y0) - m2_trap_depth) < 0.001
        && abs((hopper_boss_trap_x1 - hopper_boss_trap_x0) - m2_trap_depth) < 0.001,
        "u_guide_bracket: right bracket datum must remain exact");
    // ---- Step 6 (B1/B2): the former's mounting pad is REAL MATERIAL ----
    // pusher_pad_* used to be a params-only datum: no module built it, so the
    // u_former die was bolted to nothing. The pad is now part of this bracket,
    // and it is what the former's M2 actually threads into - the die's load
    // path is die -> ear -> pad -> arm -> plate -> hopper bosses.
    // The pad overlaps the arm (x bracket_arm_x0..x1, y bracket_plate_y0..y1,
    // z bracket_arm_z0..z1 = 10.5..12) over z 10.9..12 and its whole X span,
    // so the union is volumetric, never a coplanar touch.
    assert(pusher_pad_y0 == bracket_plate_y0
        && pusher_pad_x0 > bracket_arm_x0 && pusher_pad_x1 < bracket_arm_x1
        && pusher_pad_z0 > bracket_arm_z0 && pusher_pad_z0 < bracket_arm_z1
        && pusher_pad_z1 > bracket_arm_z1
        && pusher_pad_y1 <= bracket_plate_y1,
        "u_guide_bracket: the former pad must fuse INTO the arm and stay inside the plate's Y band");
    // The 4.4 AF nut trap (B2) is centred in the pad and must keep the same
    // m2_min_surrounding (1.0) of material the Step 5 traps keep, in X and Z,
    // measured ACROSS THE FLATS - the way a nut trap is quoted (m2_trap_af).
    // The pad is 6.6 X by 7.2 Z (its Z span is pinned to the die ear by
    // pusher_pad_z0/z1 == former_ear_z0/z1), so the hex's across-CORNERS
    // measure (2*r = 5.08) leaves 0.76 at the X corners and 1.06 at the Z
    // corners. X is the governing direction and is the one still short of the
    // 1.0 rule: the pad would have to grow from 6.6 to 7.08 wide to carry 1.0
    // there too. That is a geometry change, so it is stated here instead of
    // hidden, and the floor below stays at what X actually meets.
    trap_flat_half_x = (pusher_pad_x1 - pusher_pad_x0)/2 - m2_trap_af/2;
    trap_flat_half_z = (pusher_pad_z1 - pusher_pad_z0)/2 - m2_trap_af/2;
    trap_corner_half_x = (pusher_pad_x1 - pusher_pad_x0)/2 - 2*(m2_trap_af/sqrt(3))/2;
    trap_corner_half_z = (pusher_pad_z1 - pusher_pad_z0)/2 - 2*(m2_trap_af/sqrt(3))/2;
    trap_corner_floor = 0.75;   // ~2 perimeters at a 0.4 nozzle, local to the
                                 // trap; X (0.76) governs it, Z has 1.06
    assert(abs(former_screw_x - (pusher_pad_x0 + pusher_pad_x1)/2) < 0.001
        && abs(former_screw_z - (pusher_pad_z0 + pusher_pad_z1)/2) < 0.001,
        str("u_guide_bracket: the former nut trap must stay centred in the pad: x ",
            former_screw_x, " z ", former_screw_z));
    assert(trap_flat_half_x >= m2_min_surrounding && trap_flat_half_z >= m2_min_surrounding,
        str("u_guide_bracket: the 4.4 AF former nut trap needs >=1mm of pad across its flats, got ",
            trap_flat_half_x, " in X and ", trap_flat_half_z, " in Z"));
    assert(trap_corner_half_x >= trap_corner_floor && trap_corner_half_z >= trap_corner_floor,
        str("u_guide_bracket: the trap's corner walls are down to ", trap_corner_half_x, "/",
            trap_corner_half_z, " (floor ", trap_corner_floor, ")"));
    // Along Y the trap follows the Step 5 pattern: m2_trap_depth deep and OPEN
    // at the pad's outer face (former_screw_y_trap1 == pusher_pad_y1), with a
    // closed floor below it. A trap that stopped short of the face would be an
    // enclosed void - a second shell and a nut with no way in.
    assert(abs((former_screw_y_trap1 - former_screw_y_trap0) - m2_trap_depth) < 0.001
        && former_screw_y_trap1 == pusher_pad_y1
        && former_screw_y_trap0 - pusher_pad_y0 >= m2_min_surrounding,
        str("u_guide_bracket: the former nut trap must be m2_trap_depth deep, open at the pad face: ",
            former_screw_y_trap1, " vs face ", pusher_pad_y1, ", floor ",
            former_screw_y_trap0 - pusher_pad_y0));
    difference() {
        union() {
            translate([bracket_plate_x0, bracket_plate_y0, bracket_plate_z0])
                cube([bracket_plate_x1-bracket_plate_x0, bracket_plate_y1-bracket_plate_y0,
                      bracket_plate_z1-bracket_plate_z0]);
            translate([bracket_arm_x0, bracket_plate_y0, bracket_arm_z0])
                cube([bracket_arm_x1-bracket_arm_x0, bracket_plate_y1-bracket_plate_y0,
                      bracket_arm_z1-bracket_arm_z0]);
            translate([bracket_flange_x0, bracket_flange_y0, bracket_flange_z0])
                cube([bracket_flange_x1-bracket_flange_x0, bracket_flange_y1-bracket_flange_y0,
                      bracket_flange_z1-bracket_flange_z0]);
            // Step 6 (B1): the former's M2 pad. pusher_pad_y0 == former_ear_y1,
            // so the die ear seats flat on this face; the trap below is cut into
            // this block, so the screw has something to bite into.
            translate([pusher_pad_x0, pusher_pad_y0, pusher_pad_z0])
                cube([pusher_pad_x1-pusher_pad_x0, pusher_pad_y1-pusher_pad_y0,
                      pusher_pad_z1-pusher_pad_z0]);
        }
        // Screw 1 is along Y; screw 2 is perpendicular, along X.
        translate([guide_screw1_x, bracket_screw1_y0, guide_screw1_z])
            rotate([-90,0,0]) cylinder(h=bracket_screw1_y1-bracket_screw1_y0,
                d=m2_clearance_dia, center=false);
        translate([bracket_screw2_x0, bracket_screw2_y, bracket_screw2_z])
            rotate([0,90,0]) cylinder(h=bracket_screw2_x1-bracket_screw2_x0,
                d=m2_clearance_dia, center=false);
        // Step 6 (B2): the former M2 nut trap - the SAME hex pattern the Step 5
        // guide trap uses (r = m2_trap_af/sqrt(3) across a $fn=6 cylinder, so
        // 4.4 across the flats), axis Y, cut from the pad's outer face
        // (former_screw_y_trap1 == pusher_pad_y1) inward over
        // former_screw_y_trap1 - m2_trap_depth. Exactly the Step 5 geometry: one
        // m2_trap_depth deep, open at the face, closed floor under it. The screw
        // arrives from -Y (head seat at former_screw_y_head 9.4), the nut drops
        // into this trap from +Y and lands on the floor at
        // former_screw_y_trap0 12.3, and the shank threads through it.
        translate([former_screw_x, former_screw_y_trap0, former_screw_z])
            rotate([-90,0,0]) cylinder(h=former_screw_y_trap1-former_screw_y_trap0,
                r=m2_trap_af/sqrt(3), $fn=6, center=false);
    }
}

// ============================================================
// Step 6: the U-FORMER (u_former) - the bolted die that folds the flat
// 25.4 ribbon into the U, in the shadow of the dropper pipe.
// FRAME: hopper-local, which is the SAME frame as u_guide() (the hopper and
// the guide are both placed at drum_axle_x = 100, chassis_width/2, and
// drum_axle_z - hopper_axis_z). former_x0/former_x1 are WORLD X (81/91),
// so hopper-local X is former_x0/former_x1 - drum_axle_x = -19..-9.
// ONE printed part, symmetric in Y (the viewer mirrors the single GLB).
// PRINT ORIENTATION: rotate 90 degrees about X before printing, so the die
// arms stand as vertical walls instead of thin horizontal shelves. As built,
// this part is a ~18.8 x 10 tunnel: a ~10mm unsupported roof over a 10 x 10 x
// 8 void, so it CANNOT be printed in its hopper-frame pose without support.
// The rotation is applied to the PRINT/STL artifact only - see the
// part_to_render == "u_former" branch in seed_tape_machine_v2.scad and the
// print_rot entry in regenerate_glbs.sh. The viewer GLB stays in this frame,
// because the viewer places the die in the hopper without any rotation.
// ============================================================

// The BOTTOM BAR of the forming section at fold progress u (0 = flat 25.4
// ribbon, 1 = full-depth U), dilated by gap, swept `len` along +X.
// The clearance is applied ANALYTICALLY - every face moved out by `gap` - and
// NOT with offset(r=gap): offset() rounds the corners into arcs, and those arc
// facets meeting at a station boundary came out of the hull() as zero-volume
// sliver shells, which left the exported STL non-watertight. Same clearance,
// sharp corners (and a sharp pocket corner is what a paper fold wants anyway).
// Mapping to the part: 2D x -> world Y, 2D y -> world Z, extrusion -> world X.
// rotate([0,0,90]) rotate([90,0,0]) is exactly that (x,y,z)_2D -> (z, x, y).
module u_former_bar(u, gap, len) {
    w = paper_width/2 - u_side_h*u;              // 12.7 -> 5.2 outer half width
    d = gap;
    rotate([0,0,90]) rotate([90,0,0])
        linear_extrude(height = len)
            translate([-(w + d), u_flat_z - tape_thick/2 - d])
                square([2*(w + d), tape_thick + 2*d]);
}

// One SIDE WALL of the forming section, as the EXACT ruled surface from fold
// progress u0 to u1 - an 8-point polyhedron, not a hull().
// A hull() cannot be used here: a wall is a rigid band that TRANSLATES inward
// as the fold closes, and the convex hull of two overlapping bands is FATTER
// than the band (it filled the space between them, taking the measured web
// from 1.49 down to 1.27 and the working clearance from 0.15 up to ~0.35
// mid-segment). The polyhedron gives the real ruled surface, so the 0.15
// clearance is 0.15 everywhere. Faces use the canonical OpenSCAD box winding
// (the axis map canon(x,y,z) -> (sweep, width, height) is a cyclic
// permutation, so the winding carries over unchanged). which = 2 is the mirror
// in Y, which flips the handedness, so it gets the opposite winding.
//   which: 1 = +Y wall, 2 = -Y wall.
module u_former_wall(u0, u1, gap, which, xa, len) {
    // Fail loud on a bad index: `which` is a 1 or 2 WALL INDEX, not a sign.
    // Testing it with `> 0` silently put BOTH walls on the +Y side (2 > 0),
    // which made the die channel single-sided in Y - a mirror bug, not a
    // shape bug, so nothing downstream complained.
    assert(which == 1 || which == 2,
        str("u_former_wall: which must name a wall: 1 = +Y wall, 2 = -Y wall; got ",
            which));
    w0 = paper_width/2 - u_side_h*u0;
    w1 = paper_width/2 - u_side_h*u1;
    // A wall shorter than the paper thickness would be a degenerate face set;
    // the bar already carries the floor there, so clamping to tape_thick keeps
    // the cut >= 0.15 clear of the paper everywhere.
    h0 = max(u_side_h*u0 + tape_thick/2, tape_thick) + 2*gap;
    h1 = max(u_side_h*u1 + tape_thick/2, tape_thick) + 2*gap;
    d = gap;
    z0 = u_flat_z - d;
    s = which == 1 ? 1 : -1;                       // +Y wall / -Y wall
    yin0 = s*(w0 - tape_thick - d);
    yout0 = s*(w0 + d);
    yin1 = s*(w1 - tape_thick - d);
    yout1 = s*(w1 + d);
    assert(w0 > tape_thick && w1 > tape_thick && h0 > 0 && h1 > 0 && len > 0,
        str("u_former: degenerate forming wall at x=", xa, ": w ", w0, "->", w1,
            " h ", h0, "->", h1));
    polyhedron(
        points = [[xa,   yin0, z0],    [xa,   yout0, z0],
                  [xa,   yout0, z0+h0],[xa,   yin0,  z0+h0],
                  [xa+len, yin1, z0],  [xa+len, yout1, z0],
                  [xa+len, yout1, z0+h1],[xa+len, yin1, z0+h1]],
        // Consistently wound: every edge is traversed in opposite directions by
        // its two faces (a polyhedron that is not will still be re-oriented by
        // the CGAL backend, but OpenSCAD's Manifold fast path rejects it with
        // "PolySet -> Manifold conversion failed: NotManifold").
        faces  = which == 1
            ? [[1,2,3,0], [7,6,5,4], [4,5,1,0], [5,6,2,1], [6,7,3,2], [7,4,0,3]]
            : [[0,3,2,1], [4,5,6,7], [0,1,5,4], [1,2,6,5], [2,3,7,6], [3,0,4,7]]);
}

// The swept U channel: the cut that forms the paper, plus the 2mm capture.
// Working zone: former_work_gap (0.15) all the way across the fold, 24 exact
// ruled segments (bar by hull - it is concentric, so its hull IS exact - and
// walls by polyhedron). The +0.02 on each length is a deliberate volumetric
// OVERLAP with the next segment, so neighbouring segments never meet on a
// coplanar face (a coplanar abutment here produced an INVERTED shell instead).
// Capture: over the last 2mm (former_capture_x0..former_x1) the cut relaxes to
// former_capture_gap (2mm) so the finished U is held open and the tape is not
// pinched as it leaves the die.
module u_former_channel() {
    lx0 = former_x0 - drum_axle_x;   // -19 (world 81)
    lx1 = former_x1 - drum_axle_x;   //  -9 (world 91)
    n = 24;
    seg = (lx1 - lx0)/n;
    len = seg + 0.02;
    for (i = [0 : n-1]) {
        xa = lx0 + seg*i;
        u_a = u_shape(xa + drum_axle_x);
        u_b = u_shape(xa + seg + drum_axle_x);
        assert(u_b >= u_a, str("u_former: the fold must be monotonic at x=", xa));
        hull() {
            translate([xa, 0, 0]) u_former_bar(u_a, former_work_gap, len);
            translate([xa, 0, 0]) u_former_bar(u_b, former_work_gap, len);
        }
        u_former_wall(u_a, u_b, former_work_gap, 1, xa, len);
        u_former_wall(u_a, u_b, former_work_gap, 2, xa, len);
    }
    // 2mm capture over the last 2mm of the fold (straight prism, no taper).
    cx = former_capture_x0 - drum_axle_x;
    assert(cx > lx0 && cx < lx1,
        str("u_former: the capture must sit inside the fold: ", cx));
    translate([cx, 0, 0]) {
        u_former_bar(1, former_capture_gap, lx1 - cx);
        u_former_wall(1, 1, former_capture_gap, 1, 0, lx1 - cx);
        u_former_wall(1, 1, former_capture_gap, 2, 0, lx1 - cx);
    }
}

// The whole U-former: ONE solid die body with the swept U channel cut through
// it, so the load path runs channel -> die wall -> ear -> M2 -> pad ->
// bracket. Nothing can float and nothing can hinge.
// Section 5: this is a SEPARATE printed part, NOT part of u_guide() - the
// guide is exported/exported-printed on its own and the former on its own. The
// root scad owns the part_to_render branch for it; the placement below is the
// only place the two are related (both at hopper-local Y 0, the die straddling
// the guide rails in Y at former_ear_y0..former_ear_y1).
module u_former() {
    lx0 = former_x0 - drum_axle_x;   // -19: die body west face
    lx1 = former_x1 - drum_axle_x;   //  -9: die body east face
    // DIE-BODY Z LIMITS (chosen from the constants, commented):
    //  fz0 = u_flat_z - tape_thick/2 - former_work_gap - 1
    //      = 7.85 - 1mm of floor UNDER the working channel (channel bottom is
    //      8.85), so the swept cut never breaks out of the bottom face except
    //      in the capture lead-out, and the tape bed stays supported.
    //  fz1 = u_flat_z + u_side_h + tape_thick/2 + former_capture_gap + 1.2
    //      = 20.1, i.e. 1.2 of roof ABOVE the capture ceiling (18.9) rather
    //      than above the working ceiling (17.05). Deliberate: the spec
    //      formula u_flat_z + u_side_h + tape_thick/2 + 1.2 = 18.1 would let
    //      the 2mm capture cut breach the roof, leaving an open-topped
    //      channel. 1.2 above the capture keeps the die closed and watertight
    //      over its whole length (3.05 roof over the working zone).
    fz0 = u_flat_z - tape_thick/2 - former_work_gap - 1;
    fz1 = u_flat_z + u_side_h + tape_thick/2 + former_capture_gap + 1.2;
    // params.scad has no Step-6 rebase yet, so derive it: min_z of the part is
    // fz0, and the export branch translates by -former_export_rebase.
    former_export_rebase = -fz0;
    assert(former_capture_x0 > former_x0 && former_capture_x0 < former_x1,
        str("u_former: the capture must start inside the fold: ", former_capture_x0));
    assert(fz0 < u_flat_z - tape_thick/2 - former_work_gap,
        str("u_former: the die floor must stay under the working channel: ", fz0));
    assert(fz1 > u_flat_z + u_side_h + tape_thick/2 + former_capture_gap,
        str("u_former: the roof must stay over the 2mm capture: ", fz1));
    // Connectivity: at the entry the flat ribbon is wider than the die, so the
    // swept cut severs the body into a floor and a roof THERE ONLY. It is still
    // ONE solid because the channel narrows below the body half-width before
    // the fold ends - assert that, or the part falls into loose slabs.
    assert(paper_width/2 + former_work_gap > former_ear_y0,
        "u_former: the flat entry ribbon is wider than the die; the walls must rise as the fold closes");
    assert((paper_width/2 - u_side_h) + former_capture_gap < former_ear_y0,
        str("u_former: the exit channel must be narrower than the die half-width: ",
            (paper_width/2 - u_side_h) + former_capture_gap, " vs ", former_ear_y0));
    assert(former_ear_x0 >= lx0 && former_ear_z0 >= fz0 && former_ear_z1 <= fz1,
        "u_former: the ear must sit inside the die-body envelope");
    assert(pusher_pad_y0 == former_ear_y1 && pusher_pad_z0 == former_ear_z0,
        "u_former: the ear must still meet the bracket pad face and Z span");
    // The head bears on the COUNTERBORE FLOOR at |Y| = former_ear_y0 -
    // m2_head_h = 7.4 and sits inside that pocket - the pocket is what makes
    // the joint assemble at all (the die body's outer face is a flat 9.4 seat
    // 1.6mm outboard of the pocket, reachable from outside through the 2.4
    // clearance hole). Between the pocket floor and the forming channel wall
    // there must stay >= 1.2mm of web: 1.2 is the print minimum (the project
    // convention, and it is also pipe_wall).
    assert((former_ear_y0 - m2_head_h)
            - (paper_width/2 - u_side_h*u_shape(drum_axle_x + former_screw_x)) >= 1.2,
        str("u_former: the head counterbore must leave >=1.2mm of web to the channel wall: ",
            (former_ear_y0 - m2_head_h)
            - (paper_width/2 - u_side_h*u_shape(drum_axle_x + former_screw_x))));
    assert(former_head_relief_d > m2_clearance_dia
        && former_head_relief_d > m2_head_dia,
        str("u_former: the head relief must be wider than the M2 head and its clearance hole: ",
            former_head_relief_d));
    assert(former_screw_x - m2_clearance_dia/2 > former_ear_x0
        && former_screw_x + m2_clearance_dia/2 < former_ear_x1
        && former_screw_z - m2_clearance_dia/2 > former_ear_z0
        && former_screw_z + m2_clearance_dia/2 < former_ear_z1,
        "u_former: the M2 clearance hole must stay inside the ear");
    translate([0, 0, former_export_rebase])
    difference() {
        union() {
            // Die body: spans the fold, half-width == former_ear_y0 so the ears
            // stand proud on both sides and the M2 load path is real.
            translate([lx0, -former_ear_y0, fz0])
                cube([lx1-lx0, 2*former_ear_y0, fz1-fz0]);
            // M2 ears, both sides, 0.2 volumetric overlap onto the body so the
            // union is never a coplanar touch. Outer face stays at former_ear_y1
            // == pusher_pad_y0 (the pad it is bolted against).
            for (s = [-1, 1])
                translate([former_ear_x0, s > 0 ? former_ear_y0 - 0.2 : -former_ear_y1, former_ear_z0])
                    cube([former_ear_x1-former_ear_x0, former_ear_y1-former_ear_y0+0.2,
                          former_ear_z1-former_ear_z0]);
        }
        // The swept U channel (paper + working clearance + 2mm capture).
        u_former_channel();
        // M2 clearance through both ears, axis Y, mirrored exactly.
        // Head counterbore: INBOARD of each ear, exactly m2_head_h deep, so the
        // M2 head is not buried in solid plastic - it sits in the pocket and
        // bears on the pocket floor at |Y| = former_ear_y0 - m2_head_h. The
        // pocket is coaxial with the clearance hole below, so the shank runs
        // straight out: ear 9.4..11.0 -> pad 11.0..16.0 -> trap 12.3..14.0 ->
        // tip 15.4 (= former_screw_y_head + former_screw_len, unchanged).
        for (s = [-1, 1]) {
            head_y0 = min(s*(former_ear_y0 - m2_head_h), s*former_ear_y0);
            head_y1 = max(s*(former_ear_y0 - m2_head_h), s*former_ear_y0);
            assert(head_y0 == (s > 0 ? former_ear_y0 - m2_head_h : -former_ear_y0)
                && head_y1 == (s > 0 ? former_ear_y0 : -(former_ear_y0 - m2_head_h)),
                str("u_former: the head counterbore must be an exact Y mirror: ",
                    head_y0, "..", head_y1));
            translate([former_screw_x, head_y0, former_screw_z])
                rotate([-90,0,0])
                    cylinder(h = head_y1 - head_y0, d = former_head_relief_d);
        }
        for (s = [-1, 1])
            translate([former_screw_x, s > 0 ? former_ear_y0-1 : -(former_ear_y1+1),
                       former_screw_z])
                rotate([-90,0,0])
                    cylinder(h = former_ear_y1-former_ear_y0+2, d = m2_clearance_dia);
    }
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
    // Asymmetric flare rev6 (SMOOTH TAPER, gravity ramp kept):
    // +Y/FRONT stock-narrow full length (clears drum 40T gear disc).
    // -Y/BACK tapers smoothly 7.8->24.5 (no step, no seed-trap corners);
    // floor keeps the stock 8deg ramp so seeds slide to the mouth.
    // Taper rules that rev3-5 learned the hard way: hull pairs share
    // IDENTICAL z-spans (planar faces, no twist) and tilted boxes use
    // tilt-mapped stations Xt(x) = (x-25)/cos8 (tilt frame sits on pivot).
    X_R0 = 14; X_R1 = 24;                  // +Y hull stations (kept, proven)
    X_T0 = 77; X_T1 = 82;
    y_tip_neg_in = 24.5;                   // -Y inner face at tip
    y_tip_neg_out = y_tip_neg_in + wall;   // 27.0: uniform 2.5 cheek wall
    // +Y/FRONT flare (Step 3b: FULL HEIGHT rebuild): narrow alongside the
    // drum 40T gear X-span, then linear flare past the gear west edge (outer
    // r42 -> edge local 42) with >=2 buffer; tip mirrors -Y for seed volume.
    // Taper rules (rev3-5 + Step-3b lesson): void/floor +Y tapers share the
    // cheek X stations (parallel, never steeper) so the void tracks the wall
    // instead of eating through it; uniform 2.5 wall by construction.
    XF_P0 = 46;                            // flare start (world 54, 4 west of gear edge 58)
    y_tip_pos_in = 24.5;                   // +Y inner face at tip (mirrors -Y)
    y_tip_pos_out = y_tip_pos_in + wall;   // 27.0: uniform 2.5 cheek wall
    block_pos = y_tip_pos_out + 0.6;       // 27.6: nose block +Y half
    Xt_M = (27-25)/cos(LOW_TILT);        // taper starts past carve (r26)
    Xt_M1 = (32-25)/cos(LOW_TILT);       // taper hull-A box end
    Xt_T = (X_T0 - 25)/cos(LOW_TILT);      // tilted station mapping to X_T0
    S_C = (y_tip_neg_in - cheek_in)/(X_T0 - 27);
    S_T = S_C*cos(LOW_TILT);               // tilt-corrected taper slope
    floorTipHalf = (cheek_in + 1.0) + S_T*(Xt_T - Xt_M);
    voidTipHalf = (cheek_in + 0.5) + S_T*(Xt_T - Xt_M);
    Xt_P0 = (XF_P0 - 25)/cos(LOW_TILT);    // +Y flare start, tilt-mapped
    S_PC = (y_tip_pos_in - cheek_in)/(X_T0 - XF_P0); // +Y plan slope (longer run, same rise)
    S_PT = S_PC*cos(LOW_TILT);             // tilt-corrected +Y slope
    floorTipHalfPos = (cheek_in + 1.0) + S_PT*(Xt_T - Xt_P0); // +Y floor tip (25.5, mirrors -Y)
    voidTipHalfPos = (cheek_in + 0.5) + S_PT*(Xt_T - Xt_P0);  // +Y void tip (25.0, mirrors -Y)
    block_neg = y_tip_neg_out + 0.6;       // 27.6: nose block -Y half
    nose_x0 = 75; nose_len = 8;            // nose x75..83 (west tip world 17)
    // Step 4: +Y lug DELETED with the tall wall (no wall left to screw at height).
    lug_neg_y0 = -29.5; lug_neg_y1 = -26.6; // -Y lug: 1.5 off wall bore
    assert(27 > drum_radius + mouth_gap, "hopper flare: taper must start past carve");
    assert(floorTipHalf < y_tip_neg_out, "hopper flare: floor must not pierce cheek outer");
    assert(voidTipHalf < y_tip_neg_out - 1.5, "hopper flare: bowl wall >=1.5");
    assert(floorTipHalfPos < y_tip_pos_out, "hopper flare: +Y floor must not pierce cheek outer");
    assert(voidTipHalfPos < y_tip_pos_out - 1.5, "hopper flare: +Y bowl wall >=1.5");
    assert(block_neg < 31 && block_pos < 31, "hopper flare: nose block must clear chassis walls");
    // +Y flare passes WEST of the drum gear in X (nose x77..82 vs gear
    // edge local 42); fail loud on X-buffer. (Step 4: lug X / lug-top
    // asserts RETIRED with the deleted +Y lug.)
    assert(XF_P0 - (drum_teeth*gear_module/2 + gear_module) >= 2,
           "hopper flare: +Y flare must start 2 west of drum gear edge");
    // (Step 3b: CUT_Z retired — +Y wall rebuilt to full height like -Y.)
    assert(100 - (nose_x0 + nose_len) >= 16.5,
           "hopper flare: nose west must stay clear of spool cone rim");
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
    // Step 6: drop_pipe_id (9.0), drop_pipe_od (11.4), pipe_bore_r (4.5),
    // pipe_wall (1.2), pipe_od_bottom_z (19.4) and mouth_flare_leg (0) now
    // live in params.scad - the locals that used to shadow them are GONE, so
    // the hopper and the guide/former read the same single source of truth.
    drop_pipe_len = 10; drop_gap = 10;
    throat_cx = 0;                       // v35: funnel throat centre (local X)
    entry_flare_leg = 0.6;               // v35: bore exit 45deg break leg (>=0.6)
    pipe_bot_local = tape_z + tape_thick + drop_gap - (drum_axle_z - hopper_axis_z); // 19.4 (v87: frozen hopper_axis_z=56 → drum offset 19)
    pipe_top_local = pipe_bot_local + drop_pipe_len; // 29.4
    tube_x0 = -drop_pipe_od/2; tube_x1 = drop_pipe_od/2;   // -5.7 / 5.7
    bore_x0 = -pipe_bore_r; bore_x1 = pipe_bore_r;        // -4.5 / 4.5
    tube_z0 = pipe_bot_local; tube_z1 = 52;
    assert(abs(pipe_bot_local - 19.4) < 0.001, "hopper_body: pipe_bot_local must stay 19.4 (export min_z offset)");
    assert(abs(drop_pipe_id - 9.0) < 0.001,
        str("hopper_body: hover pipe ID must be 9.0 so 8mm seeds pass: ", drop_pipe_id));
    assert(drop_pipe_od == 11.4, str("hopper_body: hover pipe OD must be 11.4: ", drop_pipe_od));
    assert(drop_pipe_len == 10, "hopper_body: hover pipe length must be 10");
    assert(abs((drop_pipe_od - drop_pipe_id)/2 - 1.2) < 0.001, "hopper_body: hover pipe wall must be 1.2 (thinnest printable)");
    assert(abs((bore_x1 - bore_x0) - 9.0) < 0.001, "hopper_body: drop bore must be 9.0");
    assert(tube_x1 - tube_x0 == drop_pipe_od, "hopper_body: drop tube outer must equal the pipe OD");
    assert(abs((bore_x0 - tube_x0) - pipe_wall) < 0.001, "hopper_body: drop tube X wall must be pipe_wall");
    assert(abs((tube_x1 - bore_x1) - pipe_wall) < 0.001, "hopper_body: pipe wall must match pipe_wall");
    assert(throat_cx == drum_c[0], "hopper_body: funnel throat centre must equal drum drop point x (local 0 = world 100)");
    assert(entry_flare_leg >= 0.6, "hopper_body: bore exit lead-in leg must be >=0.6");
    assert(mouth_flare_leg == 0,
        "hopper_body: funnel-mouth leg is 0 so the joint ring keeps the full 1.2 wall");
    assert(tube_z0 + (drum_axle_z - hopper_axis_z) == tape_z + tape_thick + drop_gap,
           "hopper_body: hover pipe bottom must sit tape_top+10 (no seal)");
    assert(drop_gap >= 10, "hopper_body: hover gap must be >=10");
    assert((drum_axle_z - 26.5) - (tape_z + tape_thick) >= 20,
           "hopper_body: flange-to-tape clearance must be >=20");
    // v16: NO full-width step tab (it sat ON the drum and rubbed). Joint is
    // SIDES ONLY (see 2 SIDE JOINTS below): middle stays open for drum.

    // v78: mirror about Y axis — wedge swings to west (mouth LEFT), bore stays at x=0.
    // Mirrored wedge world x: drum_axle_x + [-83..-14] = [17..86].
    // Collision checks: forming Z~13, pull roller Z~4..28 —
    // all below wedge Z≥49 → no 3D collision despite X overlap.
    mirror([1, 0, 0])
    difference() {
        union() {
            // Cheek plates — ASYMMETRIC: +Y stock-straight (drum-gear side),
            // -Y tapered wide (free side). Mouth/drum interface unchanged.
            // +Y cheek (Step 3b: FULL HEIGHT, mirrors -Y): narrow alongside
            // the drum gear, then linear flare past the gear edge to the nose;
            // wall band z49..73, uniform 2.5 (planar hull, identical z-spans).
            translate([X_R0, cheek_in, cheek_bot_root])
                cube([XF_P0 - X_R0, wall, cheek_top0 - cheek_bot_root]);
            hull() {
                translate([XF_P0, cheek_in, cheek_bot_root])
                    cube([5, wall, cheek_top0 - cheek_bot_root]);
                translate([X_T0, y_tip_pos_out - wall, cheek_bot_root])
                    cube([X_T1 - X_T0, wall, cheek_top0 - cheek_bot_root]);
            }
            // -Y cheek — mouth box (stock section, carve trims flush: zero
            // sliver) + SMOOTH TAPER starting past carve (x27, no seed-trap
            // corners). Hull boxes share IDENTICAL z-spans (planar, no twist).
            translate([X_R0, -(cheek_in + wall), cheek_bot_root])
                cube([33 - X_R0, wall, cheek_top0 - cheek_bot_root]);
            hull() {
                translate([27, -(cheek_in + wall), cheek_bot_root])
                    cube([32 - 27, wall, cheek_top0 - cheek_bot_root]);
                translate([X_T0, -y_tip_neg_out, cheek_bot_root])
                    cube([X_T1 - X_T0, wall, cheek_top0 - cheek_bot_root]);
            }
            // Lower floor slab — stock 8deg RAMP kept (gravity feed): straight
            // mouth box (mouth zone bit-identical to stock) + taper hull
            // starting past carve (shared envelope => parallel to cheek
            // inner, 1.0 bury, never gaps, never pierces).
            translate(tilt_pivot)
                rotate([0, -LOW_TILT, 0])
                    union() {
                        // Straight narrow box runs to Xt_P0+5 (buried inside the
                        // -Y hull where they overlap; feeds the +Y flare start).
                        translate([-20, -floor_half, -floor_thick])
                            cube([Xt_P0 + 5 + 20, 2*floor_half, floor_thick]);
                        hull() {
                            translate([Xt_M, -floor_half, -floor_thick])
                                cube([Xt_M1 - Xt_M, 2*floor_half, floor_thick]);
                            translate([Xt_T, -floorTipHalf, -floor_thick])
                                cube([4, floorTipHalf + floor_half, floor_thick]);
                        }
                        // +Y flare hull (mirrors -Y): narrow start at Xt_P0,
                        // flared tip at Xt_T; -Y edge stays narrow (buried in
                        // the -Y hull), +Y edge flares on the cheek stations.
                        hull() {
                            translate([Xt_P0, -floor_half, -floor_thick])
                                cube([5, 2*floor_half, floor_thick]);
                            translate([Xt_T, -floor_half, -floor_thick])
                                cube([4, floorTipHalfPos + floor_half, floor_thick]);
                        }
                    }
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
            // Closed nose — FULL bowl (Step 3b): -Y wide + +Y wide mirrored,
            // x75..83 (west tip world x>=17 clears spool cone rim 16.5),
            // z53.5..73.5. Foot swallows both floor flare ends + cheek tips.
            translate([nose_x0, -block_neg, 53.5])
                cube([nose_len, block_neg + block_pos, 73.5 - 53.5]);
            // Screwable side lug (-Y only now) at mid-nose height, M3
            // clearance along Y (hole cut below); clears wall bore and
            // spool cone rim. (+Y lug deleted with the tall wall.)
            translate([77, lug_neg_y0, 63])
                cube([5, lug_neg_y1 - lug_neg_y0, 5]);
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
            // Step 5: positive-X hopper bosses, mirrored with the existing hopper.
            // They are structural material only; no pipe-wall hole is added.
            for (boss_y0=[hopper_boss_y0, -hopper_boss_y1])
                translate([hopper_boss_x0, boss_y0, hopper_boss_z0])
                    cube([hopper_boss_x1-hopper_boss_x0,
                          hopper_boss_y1-hopper_boss_y0,
                          hopper_boss_z1-hopper_boss_z0]);
            for (web_y0=[hopper_web_y0, -hopper_web_y1])
                translate([hopper_web_x0, web_y0, hopper_web_z0])
                    cube([hopper_web_x1-hopper_web_x0,
                          hopper_web_y1-hopper_web_y0,
                          hopper_web_z1-hopper_web_z0]);
        }
        // Drum clearance: wide open mouth tangent to drum, mouth_gap radial gap.
        // Lower chin auto-formed by carve retains the seed pool (gap 1.0 < 3mm).
        translate(drum_c)
            rotate([90,0,0])
                cylinder(h=2*y_out + 2*epsilon, r=drum_radius + mouth_gap, center=true);
        // Step12: flange register grooves (female) — drum end flanges OD53
        // r26.5, 1.5 wide at local Y +/-5 (world 29/39, from drum_len/2-2.5).
        // Recess r26.8 w2.1 (0.3 radial + 0.6 width print clearance,
        // EXPLICIT oversize). Full-disc subtraction only removes where
        // hopper solid exists (carve wall + cover band + floor/funnel
        // crossings); existing void is a no-op. Mouth_gap/drum untouched.
        for (fy=[-flange_reg_y, flange_reg_y])
            translate([0, fy, hopper_axis_z])
                rotate([90,0,0])
                    cylinder(h=flange_reg_w, r=flange_reg_r, center=true);
        // Open-top trough void — stock narrow channel behavior at the mouth
        // + smooth taper on tilt-mapped stations (bowl wall uniform 2.0,
        // no step, no seed-trap corners). Ramp-matched: void bottom tracks
        // just under the ramped floor. Reaches into the nose for volume.
        translate(tilt_pivot)
            rotate([0, -LOW_TILT, 0])
                union() {
                    // Straight narrow box runs to Xt_P0+5 (feeds the +Y flare).
                    translate([-20, -(cheek_in + 0.5), -0.5])
                        cube([Xt_P0 + 5 + 20, 2*(cheek_in + 0.5), 30.5]);
                    hull() {
                        translate([Xt_M, -(cheek_in + 0.5), -0.5])
                            cube([Xt_M1 - Xt_M, 2*(cheek_in + 0.5), 30.5]);
                        translate([Xt_T, -voidTipHalf, -0.5])
                            cube([4, voidTipHalf + cheek_in + 0.5, 30.5]);
                    }
                    // +Y void flare (mirrors -Y, same stations as the +Y cheek
                    // so the bowl wall stays uniform instead of eating through).
                    hull() {
                        translate([Xt_P0, -(cheek_in + 0.5), -0.5])
                            cube([5, 2*(cheek_in + 0.5), 30.5]);
                        translate([Xt_T, -(cheek_in + 0.5), -0.5])
                            cube([4, voidTipHalfPos + cheek_in + 0.5, 30.5]);
                    }
                };
        // Side-lug M3 clearance hole (-Y only now, axis Y through the lug).
        translate([79.5, lug_neg_y0 - epsilon, 65.5])
            rotate([-90, 0, 0])
                cylinder(h=(lug_neg_y1 - lug_neg_y0) + 2*epsilon, d=bolt_dia + 2*tolerance, center=false);
        // Step 5 boss screw 2 clearance along X, in positive-X source coordinates.
        for (boss_y=[hopper_boss_screw_y, -hopper_boss_screw_y])
            translate([hopper_boss_screw_x0, boss_y, hopper_boss_screw_z])
                rotate([0,90,0]) cylinder(h=hopper_boss_screw_x1-hopper_boss_screw_x0,
                    d=m2_clearance_dia, center=false);
        // Step 5 boss nut traps, also positive-X source coordinates.
        for (boss_y=[hopper_boss_screw_y, -hopper_boss_screw_y])
            translate([hopper_boss_trap_x0, boss_y, hopper_boss_screw_z])
                rotate([0,90,0]) cylinder(h=hopper_boss_trap_x1-hopper_boss_trap_x0,
                    r=m2_trap_af/sqrt(3), $fn=6, center=false);
        // v35 drop bore + tapered groove + 45deg lead-in (no window box, no tape slots):
        // Step 6: cylindrical ID9.0 bore through the hover pipe (was ID7.6) +
        // tapered inner cone (r4.5 -> r8, wide 16 -> 9.0 throat) up through the
        // funnel to the drum mouth (fed by the 6 cavities over the top, not by
        // the trough void). Drum carve trims the funnel stub into a smooth
        // drum-conforming mouth. Profile is monotonic (no radial step >0.3
        // anywhere, no overhang in the seed travel direction). ONE 45deg break
        // is left: the bore-exit flare (r4.5->r5.1 over h0.6, 0.6 flat land)
        // kills the bottom sharp inner rim. The throat entry flare is gone -
        // mouth_flare_leg is 0, so the joint ring is a plain 1.2 wall.
        // Pipe hovers 10 above the tape: no notches, no seal overlap.
        // Trough (HW 2.0, outer 7.8 < OD11.4) stays centred under the bore
        // (bore +-4.5, i.e. the full ID9.0: the seed drops straight through
        // into the still-open U below, which only starts rolling at X=100).
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
        // Step 6: mouth_flare_leg is 0, so the joint ring is a plain 1.2 wall
        // and there is nothing to flare - skip it instead of cutting a
        // degenerate 0-height sliver. entry_flare_leg (0.6) at the bore exit
        // stays and is the only lead-in left.
        if (mouth_flare_leg > 0)
            translate([throat_cx, 0, pipe_top_local - mouth_flare_leg])
                cylinder(h=mouth_flare_leg + epsilon, r1=drop_pipe_id/2, r2=drop_pipe_id/2 + mouth_flare_leg, center=false);
        // Cover inner-face groove (v14 YELLOW: w7 x d0.8 along 120..270 arc,
        // matches drum 6-cavity track for wheel-to-frame positioning ONLY
        // (NOT seed drive); shallow guide, channel stays smooth).
        translate(drum_c)
            rotate([90, 0, 0])
                rotate([0, 0, 120])
                    rotate_extrude(angle=150, convexity=10)
                        translate([drum_radius + 1.5 + groove_d/2, 0, 0])
                            square([groove_d + epsilon, groove_w], center=true);
        // Floor inner-face groove (v14 YELLOW: central longitudinal guide
        // w7 x d0.8 along tilted floor, matches drum cavity track for
        // wheel-to-frame positioning ONLY, NOT seed drive).
        translate(tilt_pivot)
            rotate([0, -LOW_TILT, 0])
                translate([-9, -groove_w/2, - groove_d])
                    cube([(x_tip + 1) - 16, groove_w, groove_d + epsilon]);
    }
    // v78 collision asserts: mirrored wedge (local x -83..-14, world 17..86)
    // must not reach below Z=49 where obstacles live (tape Z~13, pull Z≤28).
    assert(cheek_bot_root >= 49, "v78: mirrored hopper wedge bottom must stay above obstacles (Z≥49)");
    // Wedge must not extend west beyond the chassis
    assert(x_tip >= -chassis_len + chassis_x0 + 10,
           str("v78: mirrored hopper nose must stay inside chassis (x_tip=", x_tip, ")"));
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
    // v20: drum gear sits on FRONT side of drum (+gear_off from params, world Y~51.95).
    // gear_off shared by both branches so export matches assembly.
    gear_z = gear_thick/2 + 0.6;  // 3.6: gear at bottom of export = FRONT side after viewer Rx(PI) flip
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
            // Drum gear (lightened, 40T) — gear center z=39.5 (drum center 21.55 + gear_off 17.95)
            translate([0,0, drum_base + drum_len/2 + gear_off])
                rotate([180,0,0])
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
                // v79: gear on FRONT side (+gear_off, world y≈51.95); hub points toward the drum.
                translate([0, +gear_off, 0])
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
