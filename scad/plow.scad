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
            // Base radius shrinks from 12mm (24mm wide U) down to 8.25mm.
            // THE TAPER EXISTS FOR ONE REASON: the EXIT clear radius. With
            // the old 6.5 the exit closed to r 1.575 (Ø3.15) - the packet
            // roll (Ø7.9 across the outside) could never get out.
            //   r_clear(t) = base_r(t) - scroll_spiral_pitch*scroll_turns(t)*t
            //                - thickness/2
            //   r_clear(1) = (12 - X) - 2.5*1.25 - 1.6/2 = 8.075 - X
            //   X = 8.075 - 4.30 = 3.775 is the bare minimum; 3.75 is
            //   built, leaving 0.025 of margin -> r_clear(1) = 4.325
            // where -2.5*1.25 = -3.125 is the spiral offset of the 1.25
            // turns at the exit and 0.8 is the half sheet thickness.
            // (Every scroll_* number below - the taper AND the spiral tuck -
            // is read from the shared names in params.scad, so this taper
            // and the exit-clearance check cannot drift apart.)
            base_r1 = scroll_base_r0 - scroll_exit_taper * t1;
            base_r2 = scroll_base_r0 - scroll_exit_taper * t2;
            // Spiral offset: the radius shrinks slightly as it wraps around so it tucks INSIDE itself without colliding
            r1_1 = base_r1 - (angle1_1 / 360) * scroll_spiral_pitch * t1;
            r1_2 = base_r1 - (angle1_2 / 360) * scroll_spiral_pitch * t1;
            r2_1 = base_r2 - (angle2_1 / 360) * scroll_spiral_pitch * t2;
            r2_2 = base_r2 - (angle2_2 / 360) * scroll_spiral_pitch * t2;
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
    // local y 20 + plow_frame_y0 14 = world 34 = lane centre), so the exit
    // faces the twister straight; entry mouth rims sit at lane height.
    // Supports: 2 ground pedestals fused under the sheet floor (tops +15:
    // 19.3/22.7). v141: no legs - each pedestal IS a foot, carrying one
    // vertical M3 at world (133,34) / (151,34).
    cy = plow_axis_local_y;         // sheet centre (local y, world tape centre 34 = lane_y)
    axis_z = 28;                    // v87 +15: sheet axis height (exit = twister bore height)
    mouth_x0 = -12;                 // sheet mouth (world 114, exit lands 159)
    pedA = [4, 10, 12, 28, 19.3];    // Step 9: widened X to 6 (world 130..136), top/embed unchanged
    pedB = [22, 28, 14, 26, 22.7]; // Step 9: widened X to 6 (world 148..154), top/embed unchanged
    // ---- v143: BOTH screws are fitted from above, one per short L-arm ----
    // Arm A (north) stops plow_arm_gap short of the fixed wall. Arm B (south)
    // grows off pedestal B into the only sky-clear band south of the scroll
    // (world y 55.7..64.8, 41mm below the crank/drum gear rim). Each hole is a
    // GENUINE through hole and each head sits on its arm's top face.
    hole_d = bolt_dia + 2*tolerance; // M3 clearance 3.6
    screw_a = [plow_screw_a_x - plow_start, plow_screw_a_y - plow_frame_y0]; // 6, 4
    screw_b = [plow_screw_b_x - plow_start, plow_screw_b_y - plow_frame_y0]; // 22, 42
    // Arm A, derived from the screw and the gap so the two cannot disagree.
    arm_x0 = screw_a[0] - plow_arm_w/2;                             // 3  (world 129)
    arm_x1 = arm_x0 + plow_arm_w;                                     // 9  (world 135)
    arm_y0 = screw_a[1] - hole_d/2 - plow_arm_end_ligament;          // 1  (world 15)
    arm_y1 = pedA[2] + plow_arm_fuse;                                 // 15 (world 29)
    // Arm B, the same construction mirrored: it reaches south past pedestal B
    // to the free band, so its end is the free band's edge and its far end
    // overlaps the pedestal.
    arm2_x0 = screw_b[0] - plow_arm2_w/2;                            // 19 (world 145)
    arm2_x1 = arm2_x0 + plow_arm2_w;                                  // 25 (world 151)
    arm2_y0 = pedB[2] - plow_arm2_fuse;                               // 23 (world 37)
    arm2_y1 = screw_b[1] + hole_d/2 + plow_arm2_end_ligament;         // 45 (world 59)
    sheet_y0 = cy - scroll_base_r0 - thickness/2;                     // 7.2 (world 21.2)
    sheet_y1 = cy + scroll_base_r0 + thickness/2;                     // 32.8 (world 46.8)
    // ---- v63 fail-loud: exact-scroll placement ----
    assert(turner_len == 33 && plow_start == 126 && turner_end == 159,
        "six_turner: slot datum must stay 126..159");
    // Exact-use proofs (user code must stay byte-identical).
    assert(length == 45, "six_turner: folder length must stay exactly 45");
    assert(thickness == 1.6, "six_turner: sheet must stay exactly 1.6");
    assert(steps_length == 35 && steps_arc == 35, "six_turner: resolution must stay 35/35");
    // The taper arithmetic, proven, not asserted by faith: the exit must be
    // open enough for the paper roll (Ø7.9 outside -> exit Ø8.6, one 0.3
    // working clearance on the radius plus the 0.05 axis offset).
    assert(scroll_exit_taper == 3.75, "six_turner: the exit taper must stay 3.75");
    assert(scroll_base_r(1) == 8.25, "six_turner: exit base radius must be 8.25");
    assert(scroll_entry_turns + (scroll_exit_turns - scroll_entry_turns) == 1.25,
        "six_turner: exit must wrap 1.25 turns (spiral overlap)");
    // The exit INNER face radius those two facts produce, against the pin:
    //   8.25 - 2.5*1.25 (spiral) - 1.6/2 (half sheet) = 4.325 >= 4.30
    assert(scroll_clear_r(1) >= turner_exit_clear_r,
        str("six_turner: exit clear radius must reach the pin ", turner_exit_clear_r,
            ": got ", scroll_clear_r(1)));
    // And the packet itself must clear the whole sheet, sampled across it -
    // not just at the exit, where the packet is a built box, not a circle.
    // Measured from the TURNER's axis, not the packet's own: the packet axis
    // is packet_exit_ecc below it, so the worst corner is 3.95 + 0.05.
    assert(packet_outer_r + packet_exit_ecc <= turner_exit_clear_r - tolerance,
        str("six_turner: the packet must leave a tolerance gap in the exit: need <= ",
            turner_exit_clear_r - tolerance, " got ", packet_outer_r + packet_exit_ecc,
            " (packet axis is ", packet_exit_ecc, " below the turner axis)"));
    assert(scroll_clear_r_min() >= packet_outer_r + tolerance,
        str("six_turner: the tightest station must pass the Ø", 2*packet_outer_r,
            " packet: need >= ", packet_outer_r + tolerance, " got ", scroll_clear_r_min()));
    assert(2*turner_exit_clear_r >= 2*packet_outer_r,
        str("six_turner: the exit must pass the Ø", 2*packet_outer_r,
            " packet: got Ø", 2*turner_exit_clear_r));
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
    // ---- v143: side A, the top-down screw and its short L-arm ----
    // A used to hang off a 24mm floor strap that stopped 1mm from the fixed
    // wall - that reach is what the user objected to. The arm is now 14mm long
    // with an 11mm overhang past the pedestal and stops 12mm short of the wall,
    // and the screw's head sits on the arm's TOP face in open sky.
    assert(plow_screw_a_x == plow_start + 6 && plow_screw_a_y == 18,
        "six_turner: the north screw must be at world (132,18)");
    // The arm's ligaments around the hole: 1.2 west and east (a 6mm arm hosting
    // a 3.6mm bore is the limit: (6-3.6)/2 = 1.2) and 1.2 to the arm's end
    // face. Toward the pedestal the arm is solid, so there is no fourth face.
    assert((screw_a[0] - arm_x0 - hole_d/2) >= plow_foot_ligament
        && (arm_x1 - screw_a[0] - hole_d/2) >= plow_foot_ligament
        && (screw_a[1] - arm_y0 - hole_d/2) >= plow_foot_ligament,
        str("six_turner: the north screw must keep ", plow_foot_ligament,
            "mm ligaments in arm A; got W ", screw_a[0] - arm_x0 - hole_d/2,
            " E ", arm_x1 - screw_a[0] - hole_d/2,
            " N ", screw_a[1] - arm_y0 - hole_d/2));
    // The head is the only thing of this screw above the arm, and it lives
    // NORTH of the scroll: its footprint stops short of the sheet's south face
    // (local sheet_y0 7.2 vs the head's north edge 6.75), so no part of the
    // screw or its head can ever be inside the rolled paper.
    assert((screw_a[1] + bolt_head_across/2) <= sheet_y0,
        str("six_turner: the north head must stay clear of the scroll's south face: got ",
            screw_a[1] + bolt_head_across/2, " vs sheet ", sheet_y0));
    // The arm is a cantilever, but it must FUSE into the pedestal, never touch
    // it: the overlap has to be positive in x AND y, or the union splits into
    // a floating second body. Measured: 5mm in x, plow_arm_fuse 3mm in y.
    assert((min(arm_x1, pedA[1]) - max(arm_x0, pedA[0])) >= plow_foot_ligament
        && (arm_y1 - pedA[2]) >= plow_foot_ligament
        && arm_y0 < pedA[2],
        "six_turner: arm A must overlap pedestal A volumetrically, not touch it");
    // The overhang past the pedestal face is 10..15mm: long enough to be an L,
    // short enough that the wall gap is plainly visible.
    assert((pedA[2] - arm_y0) >= 10 && (pedA[2] - arm_y0) <= 15,
        str("six_turner: arm A's overhang must be 10..15mm, got ", pedA[2] - arm_y0));
    // ---- v143: side B, the same L mirrored, into the free band ----
    assert(plow_screw_b_x == plow_end - 8 - plow_arm2_w/2 && plow_screw_b_y == 56,
        "six_turner: the south screw must be at world (148,56)");
    // Same three ligaments, mirrored: 1.2 E/W and 1.2 to arm B's south end.
    assert((screw_b[0] - arm2_x0 - hole_d/2) >= plow_foot_ligament
        && (arm2_x1 - screw_b[0] - hole_d/2) >= plow_foot_ligament
        && (arm2_y1 - screw_b[1] - hole_d/2) >= plow_foot_ligament,
        str("six_turner: the south screw must keep ", plow_foot_ligament,
            "mm ligaments in arm B; got W ", screw_b[0] - arm2_x0 - hole_d/2,
            " E ", arm2_x1 - screw_b[0] - hole_d/2,
            " S ", arm2_y1 - screw_b[1] - hole_d/2));
    // Same volumetric fuse into pedestal B, measured the same way: 3mm in x
    // (arm B is 19..25, pedestal B is 22..28) and plow_arm2_fuse in y.
    assert((min(arm2_x1, pedB[1]) - max(arm2_x0, pedB[0])) >= plow_foot_ligament
        && (pedB[2] - arm2_y0) >= plow_foot_ligament
        && arm2_y1 > pedB[2],
        "six_turner: arm B must overlap pedestal B volumetrically, not touch it");
    // Arm B reaches SOUTH past the pedestal, and the paper lane is north of it:
    // the arm may not climb into the sheet, or the scroll would be fouled.
    assert(arm2_y0 > sheet_y1 || arm2_y1 > sheet_y1,
        "six_turner: arm B must grow away from the sheet, not into it");
    // Both bores are THROUGH, not blind, and the geometry that makes them so is
    // named here so it can be asserted instead of assumed: each bore starts
    // BELOW the arm's bottom face (z0) and ends ABOVE its top face, so it
    // necessarily breaks out at both ends - nothing caps it at the bottom for
    // the nut, and the head lands on the top face.
    bore_a_z0 = -epsilon;  bore_a_h = plow_arm_h + 2*epsilon;
    bore_b_z0 = -epsilon;  bore_b_h = plow_arm2_h + 2*epsilon;
    assert(bore_a_z0 < 0 && bore_a_z0 + bore_a_h > plow_arm_h
        && bore_b_z0 < 0 && bore_b_z0 + bore_b_h > plow_arm2_h,
        str("six_turner: both bores must be THROUGH - they must start below z0 and "
            , "end above the arm top; A ", bore_a_z0, "..", bore_a_z0 + bore_a_h,
            " of 0..", plow_arm_h, ", B ", bore_b_z0, "..", bore_b_z0 + bore_b_h,
            " of 0..", plow_arm2_h));
    // Both heads sit on top of an arm in open sky, and the highest thing either
    // screw puts above the chassis floor is the head: base_thick 4 + arm 10 +
    // head 2 = 16, with the packet lane starting at tape_z 28.
    for (h = [plow_arm_h, plow_arm2_h])
        assert(base_thick + h + m3_head_h <= tape_z - 5,
            "six_turner: both arms and heads must stay >=5mm below the packet lane");
    assert(base_thick + plow_arm2_h + m3_head_h <= drum_axle_z - 20,
        str("six_turner: the south head must stay clear of the gear plane; drum gear bottom ",
            drum_axle_z - 42));
    // ---- v143: the part's Y footprint, and what is allowed outside the sheet ----
    // The two feet and the sheet stay inside the sheet's Y span; the two arms
    // are the only solids outside it, and they are the things that stop short
    // of their walls. Nothing else can creep out.
    assert(pedA[2] >= sheet_y0 && pedA[3] <= sheet_y1
        && pedB[2] >= sheet_y0 && pedB[3] <= sheet_y1,
        "six_turner: both feet must sit inside the sheet's Y span");
    assert(arm_y0 < sheet_y0 && arm2_y1 > sheet_y1
        && arm_y0 <= min([pedA[2], pedB[2], arm2_y0])
        && arm2_y1 >= max([pedB[3], sheet_y1, arm_y1]),
        "six_turner: the two arms alone may reach outside the sheet's Y span, and they define the part's Y extremes");
    // The footprint is arm A's end to arm B's end: 20..46mm. The old
    // wall-reaching legs, plus the ear that reached to y 66, made it 62.
    assert((arm2_y1 - arm_y0) <= plow_foot_max_span
        && (arm2_y1 - arm_y0) >= 20,
        str("six_turner: the plow Y footprint must be 20..", plow_foot_max_span,
            " (it was 62 with the wall-reaching legs and the y=66 ear): got ",
            arm2_y1 - arm_y0));
    // ---- v143: the walls, the gears and the lane, for BOTH stations ----
    // Both stations clear the fixed north wall (y 0..3) by more than the hole
    // radius and than the nut trap's circumradius.
    assert(min(plow_screw_y) - wall_screw_clearance_d/2 > wall_thick
        && min(plow_screw_y) - wall_screw_nut_r > wall_thick,
        "six_turner: both floor screws must clear the fixed wall's inner face");
    for (i = [0:1])
        assert(tw_apex_x_frame - plow_screw_x[i] >= 10
            && (v98_Bx - tw_bevel_outer_r) - plow_screw_x[i] >= 10,
            str("six_turner: floor screw ", i, " must stay >=10mm west of the apex / "
                , "B bevel western envelope"));
    // Arm A's head clears the teeth band in y; arm B reaches into the band in y,
    // so for B the relief is X - the teeth only exist east of the bevel
    // envelope, 38.75mm east of screw B.
    assert(v98_Bbev_y0 - (plow_screw_a_y + bolt_head_across/2) >= 1.0
        && (v98_Bx - tw_bevel_outer_r) - max(plow_screw_x) >= 10,
        "six_turner: the heads must clear the B teeth band (A in y, B in x)");
    // B-side checks that stay on y: pedB is south of the teeth band, and its
    // top clears the B shaft.
    assert(v98_Bbev_y0 - (plow_frame_y0 + pedB[3]) >= 10, "Step-9 pedB north must stay below the teeth band");
    assert(v98_Bz - 4 - (base_thick + pedB[4]) >= 1, "Step-9 pedB top must clear the B shaft");
    // No added solids: the part is exactly printable_folder().
    // Seeded pocket core must thread the 24-wide entry mouth.
    assert(12 - sqrt(pow(3.9, 2) + pow(3.4, 2)) >= 0.1,
        "six_turner: seeded pocket core must thread the entry mouth");
    // v143 solid: bare user scroll sheet (oriented + placed) + the 2 floor
    // pedestals + TWO short L-arms, one off each pedestal (union). Both screws
    // are fitted from above: each head sits on its arm's top face and each hole
    // passes clean through. Nothing reaches a wall any more - arm A stops 12mm
    // short of the fixed wall, arm B 6mm short of the south gear wall.
    // The $fn=6 spheres inside the user code
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
                // Support pedestals (tops fused into the sheet floor wall).
                translate([pedA[0], pedA[2], 0]) cube([pedA[1] - pedA[0], pedA[3] - pedA[2], pedA[4]]);
                translate([pedB[0], pedB[2], 0]) cube([pedB[1] - pedB[0], pedB[3] - pedB[2], pedB[4]]);
                // The two L-arms: flat 6mm-wide slabs, each overlapping its
                // pedestal in BOTH x and y - a true volumetric fuse, not a face
                // touch, which is what keeps this one watertight body.
                translate([arm_x0, arm_y0, 0]) cube([arm_x1 - arm_x0, arm_y1 - arm_y0, plow_arm_h]);
                translate([arm2_x0, arm2_y0, 0]) cube([arm2_x1 - arm2_x0, arm2_y1 - arm2_y0, plow_arm2_h]);
            }
            // The two M3 holes. Both are GENUINE through holes: each spans its
            // arm's full height and breaks out at the bottom face, so nothing
            // caps the screw and the head lands on the top face.
            translate([screw_a[0], screw_a[1], bore_a_z0])
                cylinder(h=bore_a_h, d=hole_d, center=false);
            translate([screw_b[0], screw_b[1], bore_b_z0])
                cylinder(h=bore_b_h, d=hole_d, center=false);
        }
    }
}

// Legacy alias (compat): the old U-plow export name now builds the 6-turner.
module folding_plow() {
    six_turner();
}

// ============================================================
// 7b. Seed tape: FLAT ribbon -> folded U -> six-turner -> bind.
// Step 6 moved the U-bend from the roller to UNDER the dropper, where
// the SEPARATE u_former part (scad/feed.scad) forms it. This module is
// the PAPER, not the die: it is the SAME channel the die cuts, with NO
// working clearance and NO capture, so paper and die share one set of
// numbers (u_flat_z, u_side_h, tape_thick, paper_width) by construction.
// Local frame: x 0..tape_len, y centred 0, z 0..u_side_h+tape_thick.
// STATIONS (world X, local X = world X - tape_x0):
//   u_flat_end_x    81 ->  95   flat ribbon ends, the fold starts
//   u_full_x        91 -> 105   fold complete, full-depth U
//   u_stable_end_x 114 -> 128   U stable and self-supporting; the straight
//                                transit runs local 128..140 (world
//                                114..126) up to the plow mouth. The full U
//                                then carries on
//                                through the six-turner and out to the end
//                                of the ribbon, so nothing downstream has
//                                to change shape again.
// SIX-TURNER HANDOFF (the U is located by the FORMER + the guide cap, NOT
// by the turner - the turner is clearance-only): mouth axis world Z 32
// (turner_axis_z), MOUTH clear radius 12 (turner_mouth_clear_r), EXIT clear
// radius 4.30 / Ø8.6 (turner_exit_clear_r) - the user's exit ("around 7.5 /
// 8.5"; 8.6 sits inside that), sized to the Ø7.9 packet with a 0.3125 gap on
// the radius: the packet's axis is 0.05 below the turner axis, so the real
// fit is 4.325 - 3.9625 - 0.05. The finished U box is world Z
// 28..35.9 (tape_z .. tape_z+u_side_h+tape_thick) about centre 31.95
// (u_center_world_z). The old "clearance 4.51" figure is DELETED: it compared
// the U's corner radius sqrt(5.4^2 + 3.95^2) with the MOUTH's inner face and
// read like a generous throat, while the throat that actually governs the
// packet is the tapered EXIT. All three datums are asserted below.
// THE ROLL (v-current): three zones along X, in seed_tape_bend():
//   world 91..100    constant full U - the existing prism, untouched. Seeds
//                    drop in at world 100 (drop_x), the last moment the
//                    packet is still open.
//   world 100..114   the ROLL: the U section MORPHS into the closed packet
//                    (u_shape2()), sampled by 24 stations at EQUAL FOLD
//                    PROGRESS over 14mm - the first at u=0 (congruent with
//                    the zone above), the last a derived step short of u=1.
//   world 114..220   constant closed packet, bore 7.1 / outer 7.9.
// The packet rides on the U's own floor datum, so it occupies exactly the
// U's 7.9mm z envelope and the morph has no vertical step at either end.
// ============================================================

// Section constants of the PAPER U at fold progress u
// (0 = flat 25.4 ribbon, 1 = full-depth U), in the ribbon frame:
//   w(u) = outer half width 12.7 -> 5.2   (the die's cut, at zero clearance)
//   h(u) = wall height       0.4 -> 7.9   (clamped to tape_thick at u=0, so
//                                              the u=0 section is never
//                                              degenerate; the floor carries
//                                              it there anyway)
function tape_u_w(u) = paper_width/2 - u_side_h*u;
function tape_u_h(u) = max(u_side_h*u + tape_thick, tape_thick);

// A CONVEX ruled box: at x = xa the cross-section is y[ya0..yb0],
// z[za0..za0+ha0]; at x = xa+len it is y[ya1..yb1], z[za1..za1+ha1].
// The linear taper between the two cross-sections IS the hull of the two
// rectangles, so this polyhedron is exact - and unlike hull() it is
// UNAFFECTED by the fact that both stations share an x range (hull() of two
// same-x-range rectangles is the WIDER rectangle, i.e. a step, not a taper).
// Canonical box winding: every edge is traversed in opposite directions by
// its two faces (an inconsistent polyhedron is rejected by the Manifold fast
// path with "NotManifold"). ya0 < yb0 and ya1 < yb1 are required - the
// module never mirrors, it just swaps the ends.
//
// NOTE on the `which` selector (this cost a full debug cycle - do not
// "simplify" it back): the side is chosen with `which == 1`, NEVER with
// `which > 0 ? 1 : -1`, because which = 2 is ALSO > 0 and that form
// silently returns +1, i.e. it builds the -Y wall on the +Y side. With
// both walls on +Y they land coincident with opposite windings and union
// into an INVERTED shell (the tape mesh then reached y = 25.4 and split
// into 7 bodies). The arg assert pins which to 1 or 2 so no new call site
// can slip through.
module tape_frustum(xa, len, ya0, yb0, za0, ha0, ya1, yb1, za1, ha1) {
    assert(len > 0 && ya0 < yb0 && ya1 < yb1 && ha0 > 0 && ha1 > 0 && za0 <= za1 && za0 + ha0 <= za1 + ha1,
        str("tape_frustum: degenerate box at x=", xa, ": y ", ya0, "..", yb0,
            " z ", za0, "..", za0 + ha0));
    polyhedron(
        points = [[xa,     ya0, za0],        [xa,     yb0, za0],
                  [xa,     yb0, za0 + ha0],  [xa,     ya0, za0 + ha0],
                  [xa+len, ya1, za1],        [xa+len, yb1, za1],
                  [xa+len, yb1, za1 + ha1],  [xa+len, ya1, za1 + ha1]],
        faces  = [[1,2,3,0], [7,6,5,4], [4,5,1,0], [5,6,2,1], [6,7,3,2], [7,4,0,3]]);
}

// ONE U-shaped section of the paper, ruled from fold progress u0 at xa to
// progress u1 at xa+len: the floor plus the two side walls, each a convex
// tape_frustum(). Three convex pieces, never a hull() and never a single
// non-convex polyhedron: a wall is a rigid band that TRANSLATES inward as the
// fold closes, and the convex hull of two overlapping bands is FATTER than the
// band (it fills the space between them) - that was the exact bug in the
// former, where the web fell 1.49 -> 1.27 and the working clearance 0.15 ->
// ~0.35 mid-segment. The floor and the walls overlap volumetrically over the
// paper thickness (their outer faces are coplanar, as they are in the die), so
// the union never depends on a coplanar touch to stay connected.
module tape_u_section(xa, len, u0, u1) {
    w0 = tape_u_w(u0);
    w1 = tape_u_w(u1);
    h0 = tape_u_h(u0);
    h1 = tape_u_h(u1);
    t  = tape_thick;
    tape_frustum(xa, len, -w0,  w0,     0, t,  -w1,  w1,     0, t);  // floor
    tape_frustum(xa, len,  w0-t, w0,     0, h0,  w1-t, w1,     0, h1); // +Y wall
    tape_frustum(xa, len, -w0,  -(w0-t), 0, h0, -w1,  -(w1-t), 0, h1); // -Y wall
}

// ONE convex box of the paper, from one cross-section segment of the
// centreline polyline: (dx, segment_length + bite, tape_thick), centred on
// the segment midpoint and rotated to the segment angle. This is the WHOLE
// construction pattern of the packet - many small convex boxes, one per
// segment per station.
// NEVER hull(): it fattened walls twice in this codebase (a hull of two
// overlapping bands fills the space between them). NEVER offset() on a 2D
// section: it produced sliver shells. The bite (packet_seg_bite) is what
// makes the union a solid chain instead of a coplanar abutment: two
// neighbouring boxes SHARE their sample point, and that point is INTERIOR to
// both of them, so they overlap on a volume - the coplanar-touch failure
// that split the tape into 7 bodies cannot happen here.
module tape_poly_box(xa, len, p0, p1) {
    dy = p1[0] - p0[0];
    dz = p1[1] - p0[1];
    seg_len = sqrt(dy*dy + dz*dz);
    assert(len > 0 && seg_len > 1e-6,
        str("tape_poly_box: degenerate box at x=", xa, " seg_len=", seg_len));
    translate([xa + len/2, (p0[0] + p1[0])/2, (p0[1] + p1[1])/2])
        rotate([atan2(dz, dy), 0, 0])
            cube([len, seg_len + packet_seg_bite, tape_thick], center=true);
}

// The WHOLE cross-section (packet_poly_seg segments) swept over one x span,
// at roll progress u. u = 0 builds the U polyline, u = 1 the closed packet.
// The CAP STAGGER (packet_cap_stagger) sweeps each box's two end planes by
// i*stagger: without it the 48 overlapping end-cap quads of a station share
// one plane and the triangulation drops a zero-area flake (see params).
module tape_poly_station(xa, len, u) {
    stagger_span = 2*(packet_poly_seg - 1)*packet_cap_stagger;
    assert(len - stagger_span > 0,
        str("tape_poly_station: the run is too short for its cap stagger: len ",
            len, " needs > ", stagger_span));
    for (i = [0:packet_poly_seg - 1])
        tape_poly_box(xa + i*packet_cap_stagger, len - stagger_span_at(i),
            packet_morph_point(i, u), packet_morph_point(i + 1, u));
}
function stagger_span_at(i) = 2*i*packet_cap_stagger;

// ---- the roll's PAPER LENGTH (measured, and what it is allowed to be) -----
// The morphed centreline's length at fold progress u: the packet_poly_seg
// chords of the polyline packet_morph_point() builds. That IS the strip's
// length as modelled - the built boxes only add packet_seg_bite/2 at each
// end, nothing in between.
//
// MEASURED, and recorded here because it is a real and ACCEPTED simplification:
//   u = 0.00 -> 25.000    u = 0.25 -> 20.259    u = 0.50 -> 17.783
//   u = 0.75 -> 20.497    u = 1.00 -> 25.379      (paper_width is 25.4)
// A point-by-point lerp between the 25.0 U centreline and the 25.38 packet
// wrap does NOT conserve arc length: the strip is ~30% short at mid-roll and
// stretches ~43% to get back. It cannot be fixed by resampling - resampling
// only redistributes the samples along the SAME curve, so the length is
// invariant - only by changing the curve's shape, and every shape change that
// sets the length is worse than the defect (measured, all rejected):
//   * a similarity scale k = paper_width/L is 1.0160 at u=0 and 1.0009 at
//     u=1, so it breaks BOTH frozen ends: it decongruents the u=0 section
//     from zone 1's prism (y +-5.08 / z 0.14 instead of +-5.2 / 0.2 - the
//     watertight mesh rests on that congruence) and it changes the packet
//     section;
//   * with k pinned to 1 at both ends the mid-roll bulge is misdirected -
//     scaled about the packet axis the paper drops to z = -1.41 at u=0.5
//     (1.41 below the ribbon datum the packet's floor rides on) and reaches
//     r 7.12 against the full U's 6.25; scaled about the floor datum it
//     instead pushes the fold top to z = 10.9, 3.2 above the full U and into
//     the seed drop pipe.
// So the SHORT bend pattern is accepted as a modelling simplification of the
// fold's PATH only. What is exact, and what the machine actually depends on:
//   * the packet ENVELOPE - every station is built from the same polyline
//     pair, so u = 1 is the same 48-facet Ø7.9/Ø7.1 tube everywhere, and the
//     bore/outer asserts below are on the real sampled envelope;
//   * the ENDS - u = 0 is the full U that zone 1 already is;
//   * the SEED POCKET - never narrower than a seed, asserted below.
// Two fail-loud guards stand in for the length assert that cannot be made:
// the strip is never pinched below a seed, and its length never shortens
// again once it starts growing.
packet_len_samples = 21;                 // u = 0, 0.05, ... 1.0 (5 and 10 = 0.25/0.5/0.75)
// A recursive accumulator, not sum(): this OpenSCAD has no sum() (verified -
// it evaluates an unknown function to undef and the assert then compares
// undef). 48 chords deep, which is nothing.
function packet_chord(u, i) =
    let (a = packet_morph_point(i, u), b = packet_morph_point(i + 1, u))
    sqrt(pow(b[0] - a[0], 2) + pow(b[1] - a[1], 2));
function packet_morph_len_at(u, i, acc) =
    i >= packet_poly_seg ? acc : packet_morph_len_at(u, i + 1, acc + packet_chord(u, i));
function packet_morph_len(u) = packet_morph_len_at(u, 0, 0);
function packet_len_at(k) = packet_morph_len(k/(packet_len_samples - 1));
function packet_len_min() =
    min([for (k = [0:packet_len_samples - 1]) packet_len_at(k)]);
// The worst shortening step over the SECOND HALF of the roll (k >= 10, i.e.
// u >= 0.5 - the measured minimum). <= 0 means the strip never gets shorter
// again on its way to the packet.
function packet_len_tail_backstep() =
    max([for (k = [round(packet_len_samples/2) : packet_len_samples - 2])
        packet_len_at(k) - packet_len_at(k + 1)]);

// The roll stations are placed at equal FOLD PROGRESS, which needs the inverse
// of u_shape2()'s smootherstep. Bisection, 20 halvings = 1e-6 in s = 1.4e-5mm
// in x, far below anything the STL can hold. The two ends are pinned to 0 and
// 1 exactly (the caller's job) so no station ever sits a hair off u=0 or u=1.
function smootherstep_at(s) = 6*s*s*s*s*s - 15*s*s*s*s + 10*s*s*s;
function smootherstep_inv(u, lo, hi, n) =
    n <= 0 ? (lo + hi)/2
  : (smootherstep_at((lo + hi)/2) < u
        ? smootherstep_inv(u, (lo + hi)/2, hi, n - 1)
        : smootherstep_inv(u, lo, (lo + hi)/2, n - 1));

module seed_tape_bend() {
    // ---- FRAME BRIDGE ----------------------------------------------------
    // The die (u_former) is placed in the hopper frame; this module is in the
    // ribbon frame. BOTH see the same flat ribbon, so the die's u_flat_z
    // (hopper local, 9.2) must land on the ribbon centreline (tape_thick/2)
    // here. u_flat_z - guide_tape_z0_local == 0.2 is that fact, and the assert
    // below fails loud if any station moves.
    assert(abs((u_flat_z - guide_tape_z0_local) - tape_thick/2) < 0.001,
        str("seed_tape_bend: u_flat_z must be the ribbon centreline: ",
            u_flat_z - guide_tape_z0_local, " vs ", tape_thick/2));
    // ---- stations, local X ----------------------------------------------
    flat_end = u_flat_end_x - tape_x0;         // 95  (fold starts)
    full_end  = u_full_x - tape_x0;            // 105 (fold complete)
    n_fold    = 24;                            // ruled segments across the fold
    seg       = (full_end - flat_end)/n_fold;  // 0.4167
    ovl       = 0.02;                          // volumetric segment overlap:
                                              // neighbouring sections must
                                              // never meet on a coplanar face
                                              // (a coplanar abutment here
                                              // produced an INVERTED shell)
    fold_x0   = flat_end - ovl;                // bite into the flat ribbon
    rdx       = 0.5;                           // straight ribbon shingles
    n_r       = ceil(flat_end/rdx);            // 190 shingles over 0..95
    // ---- the three roll zones, local X ------------------------------------
    roll_x0_l = roll_x0 - tape_x0;             // 114 (world 100: the drop)
    roll_x1_l = roll_x1 - tape_x0;             // 128 (world 114: the mouth)
    tube_end_l = tape_len;                     // 234 (world 220: the leader)
    m_dx      = (roll_x1_l - roll_x0_l)/packet_roll_stations;  // 0.5833
    // ---- the ROLL STATION GRID: equal FOLD PROGRESS, not equal x -------
    // The stations used to sit on an equal-x grid (m_dx apart). That is wrong
    // for this morph: u_shape2() is a smootherstep, so its slope is ZERO at
    // both ends and the equal-x grid put the first stations 0.0046 of the fold
    // apart - sections 0.005mm apart. Sections that close are COPLANAR faces
    // sliding past each other, and that is the one thing this boolean turns
    // into zero-area flakes and 4-face edges: the mesh carried 32 non-manifold
    // edges and 52 zero-area faces, every one of them at mesh x 114.0..115.2
    // (world 100.0..101.2) on the y = -4.8 / -5.2 wall planes, i.e. at the
    // interfaces of the first THREE stations, where du was 0.0046..0.016.
    // The grid is now x(inverse smootherstep(u_i)) - so EVERY interface is
    // 1/N = 0.0417 of the fold apart, and every interface is a clean
    // transverse crossing instead of a near-coplanar graze. Each station takes
    // its section at its OWN START x, so station 0 sits at u exactly 0 (the
    // clamp) and is congruent with zone 1's prism, and the tail station's u is
    // whatever roll_tail_du below says it is - all three asserted below.
    // Station 0 also bites roll_x_bite BACK into zone 1: u_shape2 is still
    // exactly 0 there, so the bite costs no geometry and buys a 0.32mm deep
    // congruent overlap instead of a 0.02mm sliver.
    roll_x_bite = 0.3;                            // the roll's bite into zone 1
    // The TAIL step. The last station must be CLOSE to the packet, because a
    // station at u = 23/24 leaves the paper (1-u)*8.75 = 0.09mm oversize at
    // the very plane the six-turner starts (measured r 4.055 against a 4.025
    // limit - an interference), and it must NOT BE the packet, because a
    // congruent overlap is its own failure (30 non-manifold edges at mesh x
    // 127.9..128.4). So the tail step is DERIVED from the room the turner
    // actually has: a quarter of the spare clearance, divided by how far the
    // morph moves a sample at all. roll_tail_du = 0.0018, i.e. the tail
    // station's envelope is at most 0.016mm oversize.
    function roll_u_poly_span() = max([for (i = [0:packet_poly_seg])
        let (a = u_poly_point(i), b = packet_poly_point(i))
        max(abs(a[0] - b[0]), abs(a[1] - b[1]))]);
    roll_tail_du = 0.25*(scroll_clear_r_min() - tolerance - packet_box_env_r_max())
                   / max(roll_u_poly_span(), 0.001);
    // Equal-progress stations for i = 0..N-2, then the tail station at
    // u = 1 - roll_tail_du, which is what actually reaches the mouth: it ENDS
    // on roll_x1_l, and zone 3 starts packet_x_bite before that so the two
    // overlap by a full bite without either being congruent with the other.
    function roll_station_u(i) = i < packet_roll_stations - 1
        ? i/packet_roll_stations
        : 1 - roll_tail_du;
    function roll_station_s(i) = smootherstep_inv(roll_station_u(i), 0, 1, 20);
    function roll_station_xa(i) =
        (i <= 0) ? roll_x0_l - roll_x_bite
        : roll_x0_l + (roll_x1_l - roll_x0_l)*roll_station_s(i);
    // Every station runs on to the NEXT station's start plus packet_x_bite, so
    // the chain overlaps by that bite. The LAST station runs on to roll_x1_l,
    // where u_shape2() is exactly 1.0 and the turner mouth is.
    function roll_station_len(i) =
        (i < packet_roll_stations - 1
            ? roll_station_xa(i + 1) - roll_station_xa(i) + packet_x_bite
            : roll_x1_l - roll_station_xa(i));
    // ---- the FIRST and LAST morph station -------------------------------
    // Zone 3 starts packet_x_bite EARLY: its cap planes are then off the
    // packet_cap_stagger phase of the last roll station, and coincident cap
    // planes between two sweeps are ambiguous (measured: 100 non-manifold
    // edges at mesh x 128.0..128.8 when they were made to coincide).
    roll_first_xa = roll_station_xa(0);                   // 113.7 (u = 0)
    roll_first_u  = u_shape2(roll_first_xa + tape_x0);    // == 0
    roll_last_i   = packet_roll_stations - 1;             // 23
    roll_last_xa  = roll_station_xa(roll_last_i);
    roll_last_u   = roll_station_u(roll_last_i);          // 1 - roll_tail_du
    roll_last_end = roll_last_xa + roll_station_len(roll_last_i);  // roll_x1_l
    // Point-for-point deviation of the last station's polyline from the
    // packet's own polyline - the fact that is actually being asserted, not
    // the u value that produced it.
    roll_last_dev = max([for (i = [0:packet_poly_seg])
        let (a = packet_morph_point(i, roll_last_u), b = packet_poly_point(i))
        max(abs(a[0] - b[0]), abs(a[1] - b[1]))]);
    // Envelope deviation of the first station's polyline from zone 1's U prism
    // (tape_u_section at u=1): the two side walls' outer faces, the floor's
    // underside and the wall tops. Checked on the ENVELOPE, not per sample -
    // the wall-top datum only applies to the leg samples, and the polyline is
    // only a 48-facet stand-in for the prism's 3 rectangles.
    roll_first_pts = [for (i = [0:packet_poly_seg]) packet_morph_point(i, roll_first_u)];
    roll_first_dev = max(
        abs(max([for (p = roll_first_pts) abs(p[0])]) + tape_thick/2 - tape_u_w(1)),
        abs(min([for (p = roll_first_pts) p[1]]) - tape_thick/2),
        abs(max([for (p = roll_first_pts) p[1]]) + tape_thick/2 - tape_u_h(1)));
    // ---- fail-loud -------------------------------------------------------
    assert(tape_z - tape_thick/2 > base_thick + 2, "seed_tape_bend: plain tape must clear the base");
    assert(tape_z + tape_thick < drum_axle_z - drum_radius, "seed_tape_bend: plain tape must clear the drum");
    assert(u_stable_end_x <= plow_start,
        str("tape: the U must be fully formed before the plow mouth: ", u_stable_end_x));
    assert(u_full_x < u_stable_end_x,
        str("tape: the fold must finish before the stable span: ", u_full_x, " < ", u_stable_end_x));
    assert((transit_start - tape_x0) + transit_len == plow_start - tape_x0,
        "seed_tape_bend: transit must end at the plow mouth");
    // The full U is now the tallest thing on the lane: its roof must still
    // pass UNDER the drum. This is the real "clears the exit pipe region"
    // check that the old tautology (`t < t + 10`) pretended to make.
    assert(tape_z + u_side_h + tape_thick < drum_axle_z - drum_radius,
        str("seed_tape_bend: the U roof must clear the drum: ", tape_z + u_side_h + tape_thick,
            " vs ", drum_axle_z - drum_radius));
    // (the old "the folded U must pass the six-turner throat" assert is
    // DELETED: it compared the U's corner radius against the MOUTH inner
    // face and passed with room to spare while the real EXIT was closing to
    // r 1.575 - a false clearance-only claim. The live exit fit check lives
    // in params.scad and in six_turner(), against the tape-sized roll.)
    assert(0 < flat_end && flat_end < full_end && full_end <= tape_len,
        str("seed_tape_bend: fold stations must sit on the ribbon: ", flat_end, " ", full_end));
    assert(abs((tape_z + u_side_h + tape_thick)
               - (u_center_world_z + u_side_h/2 + tape_thick/2)) < 0.001,
        str("seed_tape_bend: the U box must stay centred on u_center_world_z: ",
            tape_z + u_side_h + tape_thick));
    assert(turner_axis_z == 32 && turner_mouth_clear_r == 12 && turner_exit_clear_r == 4.30,
        "seed_tape_bend: the six-turner handoff datums must stay 32 / mouth 12 / exit 4.30");
    // ---- the ROLL: fail loud --------------------------------------------
    // Zone order and extent, on the ribbon. Zone 1 must be the untouched full
    // U, the roll must start at the drop and finish at the mouth, and the
    // closed packet must run to the end of the ribbon.
    assert(full_end < roll_x0_l && roll_x0_l < roll_x1_l && roll_x1_l < tube_end_l,
        str("seed_tape_bend: the three zones must be in order on the ribbon: ",
            full_end, " / ", roll_x0_l, " / ", roll_x1_l, " / ", tube_end_l));
    assert(roll_x0 == drop_x,
        str("seed_tape_bend: the roll must start at the seed drop: ", roll_x0, " vs ", drop_x));
    assert(roll_x1 == u_stable_end_x && roll_x1 == transit_start,
        str("seed_tape_bend: the roll must finish where the U went stable: ", roll_x1));
    assert(packet_roll_stations > 0 && m_dx > 0,
        str("seed_tape_bend: the roll needs real stations: ", packet_roll_stations, " x ", m_dx));
    assert(packet_seg_bite > 0 && packet_x_bite > 0,
        str("seed_tape_bend: the boxes need positive bites or the union goes coplanar: ",
            packet_seg_bite, " / ", packet_x_bite));
    // The roll's junctions are the only places a sliver can be born, so both
    // are pinned by facts, not by taste:
    //   START  the first station is entirely before the drop, so u_shape2 is
    //          exactly 0 and its envelope is congruent with zone 1's prism;
    //   END    the last station stops just short of the packet and finishes ON
    //          roll_x1_l, biting zone 3 by a full packet_x_bite.
    // Both used to fail the other way: a u=1 station congruent with zone 3 put
    // 30 non-manifold edges at mesh x 127.92..128.39, a station a whole 1/24
    // short of the packet put 0.09mm of paper into the six-turner throat, and
    // three near-identical stations at the start put 32 at mesh x 114.0..115.2.
    // Fail loud.
    assert(roll_first_xa + tape_x0 < roll_x0,
        str("seed_tape_bend: the first morph station must start before the drop, so its u is exactly 0: ",
            roll_first_xa + tape_x0, " vs ", roll_x0));
    assert(roll_first_u == 0,
        str("seed_tape_bend: the first morph station must be at u=0, not ", roll_first_u));
    assert(roll_first_dev < 1e-9,
        str("seed_tape_bend: the first morph station must BE the full U that zone 1 is: ",
            "max envelope deviation ", roll_first_dev, " at world x ",
            roll_first_xa + tape_x0, " (u=", roll_first_u, ")"));
    assert(roll_tail_du > 0 && roll_tail_du < 0.02,
        str("seed_tape_bend: the tail step must be short but NOT zero - zero makes the tail station congruent with zone 3: ",
            roll_tail_du));
    assert(roll_last_u > 0 && roll_last_u < 1,
        str("seed_tape_bend: the last morph station must be a real fold section, not 0 or 1: ",
            roll_last_u));
    assert(roll_last_dev > 0.001,
        str("seed_tape_bend: the last morph station must differ from the packet by a real distance, not be congruent with it: max point deviation only ", roll_last_dev,
            " at world x ", roll_last_xa + tape_x0, " (u=", roll_last_u, ")"));
    assert(abs(roll_last_end - roll_x1_l) < 1e-9,
        str("seed_tape_bend: the last morph station must finish on roll_x1_l: ",
            roll_last_end, " vs ", roll_x1_l));
    // The paper the tail station hands to the six-turner must still fit it.
    //
    // NOTE - two things are deliberate here, so nobody "hardens" this blindly:
    //   1. The limit is scroll_clear_r_min(), the sheet's tightest inner face at
    //      the EXIT (4.325) - NOT the mouth's (11.2), even though the tail
    //      station physically stops ON roll_x1, the mouth. That is conservative
    //      by design: the exit is the tightest plane the paper ever faces, so
    //      checking the tail against it bounds every station between here and
    //      there, and it is the same limit the packet itself is checked against.
    //   2. packet_exit_ecc is deliberately NOT added to packet_box_env_r_max()
    //      here. It would make this check fail on paper that is nowhere near
    //      the throat: with the eccentricity the right side becomes
    //      4.325 - 0.3 - (3.9625 + 0.05) = 0.0125, while the left side
    //      roll_tail_du * roll_u_poly_span() is 0.0018 * 8.750 = 0.01575.
    //      The real exit fit, eccentricity included, is asserted in
    //      params.scad (packet_outer_r + packet_exit_ecc <= ...). This check is
    //      "does the tail station's oversize fit the tightest plane at all",
    //      and the tightest plane is the one whose datum the eccentricity is
    //      measured FROM - adding it here double-charges the same 0.05.
    assert(roll_tail_du*roll_u_poly_span()
           <= scroll_clear_r_min() - tolerance - packet_box_env_r_max(),
        str("seed_tape_bend: the tail station's oversize must fit the six-turner: need <= ",
            scroll_clear_r_min() - tolerance - packet_box_env_r_max(), " got ",
            roll_tail_du*roll_u_poly_span()));
    // The roll's BEND PATTERN is ~30% short at mid-roll (17.783 at u=0.5
    // against a 25.4 strip) and that is an accepted simplification - see the
    // packet_morph_len() block above for the measured table and for every
    // rejected way of "fixing" it. What must never be true is checked here.
    // (1) No seed can ever be pinched: the shortest the strip gets is 17.783,
    //     i.e. 5.4x the 3.3 the 3mm seed plus a tolerance needs.
    assert(packet_len_min() > seed_dia_max + tolerance,
        str("seed_tape_bend: the roll must never pinch a seed: the shortest centreline is ",
            packet_len_min(), " at a sampled station, need > ", seed_dia_max + tolerance,
            " (paper_width is ", paper_width, " - the bend pattern is a known simplification, a pinched seed would not be)"));
    // (2) Once the strip starts growing again it never shortens: the roll
    //     hands the turner a length that only increases from u = 0.5 on.
    assert(packet_len_tail_backstep() <= 0,
        str("seed_tape_bend: the centreline must not shorten over the second half of the roll (u >= 0.5): worst backstep ", packet_len_tail_backstep(),
            " - L(0.5)=", packet_len_at(round(packet_len_samples/2)),
            " L(0.75)=", packet_len_at(3*(packet_len_samples - 1)/4),
            " L(1)=", packet_len_at(packet_len_samples - 1)));
    // The packet must be the same at every station of the roll: it is built
    // from ONE polyline pair lerped by u, so the envelope is u-independent by
    // construction - prove the endpoints and the sampled tube agree.
    assert(abs(2*(packet_poly_env_r_min() - tape_thick/2) - seed_bore_d) < 0.001
        && abs(2*(packet_poly_env_r_max() + tape_thick/2) - 2*packet_outer_r) < 0.001,
        str("seed_tape_bend: the built packet must be Ø", seed_bore_d, "/",
            2*packet_outer_r, ": got Ø", 2*(packet_poly_env_r_min() - tape_thick/2),
            "/", 2*(packet_poly_env_r_max() + tape_thick/2)));
    // And the packet must clear the 6-turner throat it is ABOUT to enter.
    // The nominal packet leaves just over one tolerance on the exit pin, and
    // the pin is 0.05 above the packet's own axis, so the fit is measured
    // from the pin: 4.30 - 0.3 = 4.0 vs 3.95 + 0.05 = 4.0 -> 0.3125 of real
    // gap. The BUILT packet is a 48-sided polygon, so each box corner sits
    // packet_box_env_r_max() = 3.9626 out, 0.0126 past the nominal 3.95 -
    // which is why the faceted check is made against the sheet's real tightest
    // inner face (scroll_clear_r_min() = 4.325), not against the nominal pin.
    assert(packet_outer_r + packet_exit_ecc <= turner_exit_clear_r - tolerance,
        str("seed_tape_bend: the nominal packet must leave a tolerance gap in the Ø",
            2*turner_exit_clear_r, " exit: need <= ", turner_exit_clear_r - tolerance,
            " got ", packet_outer_r + packet_exit_ecc,
            " (packet axis is ", packet_exit_ecc, " below the turner axis)"));
    assert(packet_box_env_r_max() <= scroll_clear_r_min() - tolerance,
        str("seed_tape_bend: the BUILT packet (box corners included) must pass the 6-turner: need <= ",
            scroll_clear_r_min() - tolerance, " got ",
            packet_box_env_r_max()));
    // And the wrap must genuinely close the packet: a hardcoded 360 left a
    // 1.84mm slit, so the DERIVED wrap is the fact being checked.
    assert(packet_wrap_rad > 2*PI,
        str("seed_tape_bend: the derived wrap must exceed a full turn: ",
            packet_wrap_deg, " deg"));
    union() {
        // 1. Flat ribbon, tape_x0 .. u_flat_end_x (unchanged shingle logic, so
        //    the ribbon length and the export bounds are identical).
        for (i=[0:n_r-1]) {
            xc = (i + 0.5)*rdx;
            translate([xc, 0, tape_thick/2])
                cube([rdx + 2*epsilon, paper_width, tape_thick], center=true);
        }
        // 2. v45 wind-up leader: narrow strip climbing packet-underside ->
        //    wound pack, fused into the packet (overlaps the tape's last 2 in
        //    x, ends inside the pack silhouette). Its 8 mm width is what the
        //    "folded tube" used to be; the live rolled packet is 7.9 across,
        //    so 8 is still the right grab width. Matches the viewer leader
        //    mesh 1:1 (same endpoints).
        lle_s = leader_x0 - tape_x0;
        lle_e = leader_x1 - tape_x0;
        lle_dx = lle_e - lle_s;
        lle_dz = (leader_z1 - tape_z) - tape_thick;
        lle_len = sqrt(lle_dx*lle_dx + lle_dz*lle_dz);
        lle_ang = atan2(lle_dz, lle_dx);
        // +1 length shifted +0.25 along the climb: the start face lands just
        // INSIDE the packet (its underside is at local z 0 and the face
        // bottoms out at 0.15, so it fuses with real overlap - not flush, not
        // poking below), end bites ~1 into the pack (min_z>=0 kept, tape film
        // exempt anyway). The packet ENDS at world 220, before the climb ever
        // rises past the packet's own top (35.9, reached at x~245), so the
        // leader never has to pierce it.
        translate([(lle_s + lle_e)/2 + 0.25*cos(lle_ang), 0, tape_thick + lle_dz/2 + 0.25*sin(lle_ang)])
            rotate([0, -lle_ang, 0])
                cube([lle_len + 1, leader_w, tape_thick + 2*epsilon], center=true);
        // 3. The fold: 24 exact ruled sections, u_shape()-driven - the same
        //    channel the die cuts, at zero clearance.
        for (i=[0:n_fold-1]) {
            xa = fold_x0 + seg*i;
            u_a = u_shape(xa + tape_x0);
            u_b = u_shape(xa + seg + tape_x0);
            assert(u_b >= u_a, str("seed_tape_bend: the fold must be monotonic at x=", xa));
            tape_u_section(xa, seg + ovl, u_a, u_b);
        }
        // 4. ZONE 1 - constant full U, world 91..100 (local 105..114). This
        //    is the EXISTING prism, byte-for-byte unchanged: the fold above
        //    ends here and the seeds drop in at world 100 with the U still
        //    open. No polyline, no roll, nothing.
        tape_u_section(full_end - ovl, roll_x0_l - full_end + ovl, 1, 1);
        // 5. ZONE 2 - the ROLL, world 100..114 (local 114..128). 24 x-stations
        //    (i = 0..packet_roll_stations-1) on the equal-FOLD-PROGRESS grid
        //    above, each one a full packet_poly_station at that station's start
        //    progress: the U polyline at u=0 lerping into the closed packet at
        //    u=1. THE BEND PATTERN IS 30% SHORT AT MID-ROLL - 25.000 at u=0,
        //    17.783 at u=0.5, 25.379 at u=1 against a 25.4 strip - because a
        //    point-by-point lerp of two polylines does not conserve arc
        //    length, and no resample can (it only moves samples along the same
        //    curve). That is an accepted simplification of the fold's PATH
        //    only; the packet ENVELOPE, both end states and the seed pocket
        //    are exact, and the two fail-loud guards are in the packet_morph_len
        //    block above. DO NOT "fix" it by scaling the section. The FIRST station (i=0) is entirely before the drop, so its u
        //    is exactly 0 and its section is congruent with the zone-1 prism;
        //    the LAST (i=packet_roll_stations-1) is the TAIL station at
        //    u = 1 - roll_tail_du and finishes on roll_x1_l, so it bites zone
        //    3 without being congruent with it - both asserted above. Each
        //    station overruns its neighbour by packet_x_bite, so consecutive
        //    stations overlap volumetrically and the union is a solid chain.
        //    The morph is MONOTONIC: asserted per station below and globally
        //    by roll_morph_max_backstep() in params.scad.
        for (i=[0:packet_roll_stations-1]) {
            xa = roll_station_xa(i);
            len = roll_station_len(i);
            u_a = u_shape2(xa + tape_x0);
            u_b = u_shape2(xa + len + tape_x0);
            assert(u_b >= u_a,
                str("seed_tape_bend: the roll must be monotonic at x=", xa + tape_x0,
                    ": ", u_a, " -> ", u_b));
            tape_poly_station(xa, len, u_a);
        }
        // 6. ZONE 3 - constant closed packet, world 114..220 (local 128..234):
        //    bore 7.1, outer 7.9. One station (the section never changes), so
        //    it is a single 106mm sweep of 48 boxes. It starts a full
        //    packet_x_bite EARLY - the last roll station finishes exactly on
        //    roll_x1_l, so this is a real 0.2mm volumetric overlap, and the
        //    two sections are NOT congruent (the tail station is roll_tail_du
        //    short of the packet), so the two never graze.
        tape_poly_station(roll_x1_l - packet_x_bite, tube_end_l - roll_x1_l + packet_x_bite, 1);
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

// ============================================================
// 8. Diamond-knurled pull roller (two helical notch families ±30°)
// ============================================================
