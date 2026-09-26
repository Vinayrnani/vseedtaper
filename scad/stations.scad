module knurled_roller(is_lower=true) {
    len = roller_len;
    dia = roller_dia;
    gear_thick = 6;
    // v21: lower roller prints gear-DOWN (hub points down, away from body) so
    // the viewer mount ([0,0,34.95]/Rx180) lands the gear on the BACK plane
    // (world Y~12, same as the v20 drum gear). Shaft bottom sits at Z=0, so
    // the lower stack needs a taller lift (19.95 vs 11).
    zoffset = is_lower ? 19.95 : 0; // v27 printable: upper was 11 (floated 11mm, min_z=11); 0 puts body/caps/collars on base min_z=0. Lower keeps 19.95 (gear-down stack bottoms at 0).

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
                // v23: gear stays on BACK side (-Y, world Y~12, same plane as
                // drum gear). Shaft moved to the BACK too (outboard of the gear,
                // toward the crank now outside the back wall at Y=-8): hex shaft
                // tip at -(len/2+gear_thick-epsilon)-14 meets the gear outer face,
                // passing through the gear hex bore into the body. Mirrors the
                // vertical export stack (shaft below gear). Front (+Y) has no shaft.
                translate([0, -(len/2 + gear_thick/2 - epsilon), 0])
                    rotate([-90,0,0])
                        spur_gear(teeth=roller_teeth, module_mm=gear_module, thickness=gear_thick,
                                  bore_flat=hex_axle_flat, is_hex=true,
                                  hub_dia=16, hub_len=10, collar_dia=14, collar_len=3);
                translate([0, -(len/2 + gear_thick - epsilon) - 14, 0])
                    rotate([-90,0,0])
                        cylinder(h=14, r=hex_axle_r, $fn=6, center=false);
                translate([0, -(len/2 + gear_thick - epsilon) - 1.2, 0])
                    rotate([-90,0,0])
                        cylinder(h=1.2, r=6, center=false);
                translate([0, -(len/2 + gear_thick + 4) - 3, 0])
                    rotate([-90,0,0])
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
    // v79: upper roller REMOVED; lower roller becomes the crank axle at x=160
    // (20T gear meshes drum 40T). Only the lower roller body is exported.
    knurled_roller(is_lower=true);
}

// ============================================================
// v37 Thread-bind + wind-up (v36 MVP backfill).
// Allowed modules only; $fn=60 inherited; tol=0.3 clearances.
// - thread_twister(): HOLLOW rotor CENTRED at origin, axis along X:
//   hub sleeve (outer r10, bore 15.6) + disc (r23) + non-meshing
//   visual bevel-blank teeth (placeholder only, never gear math) +
//   2 spindle pins (orbit R19, 180 apart) + 2 bobbin visuals on
//   the pins + 2 eyelet posts (orbit R12, 90/270 offset).
//   Assembly spins it about X at [bind_x, lane_y, twister_axle_z]
//   by twister_angle.
// - takeup_reel(): wind-up reel built along Z for flat printing
//   (bottom flange 0..3 + core r5 0..31 + top flange 28..31,
//   min_z=0); assembly recentres, tilts to axle-Y, spins about
//   the axle by takeup_angle (4 rev per $t = same linear tape).
// ============================================================
module thread_twister() {
    assert(twister_arms == 2, "thread_twister: must carry exactly 2 spindles");
    difference() {
        union() {
            // Hub sleeve: outer r10 (local x -5..0 = abs 179..184). v143: the
            // r15.6 bore is NOT cut here - the single open-axis bore in the
            // outer difference below already clears it, and cutting the same
            // r7.8 wall a second and third time left coincident cylindrical
            // faces that manifold triangulated into degenerate faces.
            translate([-5, 0, 0])
                rotate([0, 90, 0])
                    cylinder(h=5, r=10, center=false, $fn=60);
            // Disc: r23, local -5..-2 = abs 179..182 (bore: see the hub note)
            translate([-5, 0, 0])
                rotate([0, 90, 0])
                    cylinder(h=3, r=23, center=false, $fn=60);
            // v113 straight-bevel ring (photo-style: teeth on a 45° cone
            // converging at the shared apex, Tredgold form like the B
            // bevel). v115: rim size, same OD as the twister disc — 36T
            // m1.25 true mitre with Bbev36: heel pitch circle (local -6.5
            // = abs 177.5, r22.5) at the disc face, toe (local -9.3 =
            // abs 174.7, r19.7) solid over the bore. Root frustum + back
            // web back the teeth; back-cone relief (difference) trims the
            // heel backs like real bevels and catches the B heel corner.
            // Disc/hub/pins/eyelets below UNCHANGED.
            // Local x: hub east=0 (abs 184), apex local -29 (abs 155).
            translate([tw_bev_blank_x_off, 0, 0])
                rotate([0, -90, 0])
                    bev_teeth(tw_bev_n, 22.5, tw_bev_face, tw_bev_thin, tw_bev_phase, tw_bev_mod);
            // Root cone frustum under the teeth (canonical z22..25.3 mapped,
            // embedded 0.3 into the web for manifold union):
            translate([tw_bev_blank_x_off, 0, 0])
                rotate([0, -90, 0])
                    translate([0, 0, tw_bev_blank_z_rootcone])
                        cylinder(h=tw_bev_blank_h_rootcone, r1=tw_bev_blank_r_rootcone_heel,
                                 r2=tw_bev_blank_r_rootcone_toe, center=false, $fn=60);
            // Back web solid r24 (canonical z18.6..22.5 mapped; embedded 0.3
            // into the tooth heels; the v142 open-axis bore + relief cut it in
            // the difference, leaving an annulus r7.8..r24 that still backs the
            // blank end to end):
            translate([tw_bev_blank_x_off, 0, 0])
                rotate([0, -90, 0])
                    translate([0, 0, tw_bev_blank_z_web])
                        cylinder(h=tw_bev_blank_h_web, r=tw_bev_blank_r_web, center=false, $fn=60);
            // 2 spindle pins: r3, orbit R19, 180 apart, arrow push-lock tips
            for (k=[0:twister_arms-1])
                rotate([k*180, 0, 0]) {
                    // Pin body (cylinder along x)
                    translate([-2, 19, 0])
                        rotate([0, 90, 0])
                            cylinder(h=9.5, r=3, center=false, $fn=60);
                    // Arrow push-lock tip: 45° chamfer barb r3→r5 over 2mm
                    // + flat shoulder 1mm + centered slot 2.5mm full length
                    translate([5.5, 19, 0]) {
                        difference() {
                            union() {
                                // 45° chamfer cone: r3→r5 over 2mm (45° angle)
                                rotate([0, 90, 0])
                                    cylinder(h=2, r1=3, r2=tw_pin_tip_r, center=false, $fn=60);
                                // Flat shoulder: ring r5→r3, 1mm step face
                                translate([2, 0, 0])
                                    rotate([0, 90, 0])
                                        difference() {
                                            cylinder(h=1, r=tw_pin_tip_r, center=false, $fn=60);
                                            translate([0, 0, -epsilon])
                                                cylinder(h=1+2*epsilon, r=3, center=false, $fn=60);
                                        }
                            }
                            // Centered slot: 2.5mm wide, full pin length, through diameter
                            translate([0, -tw_pin_slot_w/2, -10])
                                cube([10, tw_pin_slot_w, 20], center=false);
                        }
                    }
                }
            // 2 eyelet posts: r2 h15 at orbit R13, 90/270 offset
            // from spindles, local -2..+13 = abs 182..197
            for (offset=[90, 270])
                rotate([offset, 0, 0]) {
                    translate([-2, 13, 0])
                        rotate([0, 90, 0])
                            cylinder(h=15, r=2, center=false, $fn=60);
                }
        }
        // v142: central bore, OPEN END TO END on the twister's own axis. It
        // spans the whole on-axis material (blank toe at tw_bore_x0 through
        // the rotor east face at tw_bore_x1) with the file's standard epsilon
        // overshoot at both ends, so the bevel blank's solid toe can no longer
        // cap the axle's path (pre-v142 the bore stopped 1.3mm short of it).
        translate([tw_bore_x0 - bind_x, 0, 0])
            rotate([0, 90, 0])
                translate([0, 0, -epsilon])
                    cylinder(h=tw_bore_len + 2*epsilon, r=tw_hub_bore/2, center=false, $fn=60);
        // v113 back-cone relief: annulus (tw_relief_r0..tw_relief_r1 = 20..23,
        // abs tw_relief_x0..x1) in the disc west face — catches the B heel
        // corner (standard bevel back-cone relief). It sits far OUTBOARD of
        // the hub bore, not near it: a stale "r9-13" comment here once sent a
        // diagnosis hunting for a nonexistent 1.2 mm ring beside the bore.
        // Local x: hub east=0 (abs 184).
        translate([tw_relief_x0 - 184, 0, 0])
            rotate([0, 90, 0])
                difference() {
                    cylinder(h=tw_relief_x1 - tw_relief_x0, r=tw_relief_r1, center=false, $fn=60);
                    translate([0, 0, -epsilon])
                        cylinder(h=tw_relief_x1 - tw_relief_x0 + 2*epsilon, r=tw_relief_r0, center=false, $fn=60);
                }
        // Ø2 cross-hole near top of each eyelet post (~x=183)
        for (offset=[90, 270])
            rotate([offset, 0, 0]) {
                translate([11, 13, 0])
                    rotate([0, 90, 0])
                        cylinder(h=4, r=1, center=true, $fn=60);
            }
    }
}

module twister_axle() {
    // Absolute coordinates: pedestal (x170..174, y lane_y±5, z0..24.5)
    // fused with tube (x172..193.5, OD15, Ø10 through-bore) + collar (r9 x176.5..178.5)
    // + one external +Z C-slot (source x178.5..188.5, r5..10.3).
    // Source +X maps to final west after reflection. The 4mm extension moves
    // the retaining nose/flex gaps with the slot so the slot cannot cut through it.
    // v122: east-tip snap fingers and old hub-groove/cap geometry removed;
    // the two ±Y 3.5mm nose flex gaps remain the only nose cuts.
    // v87 +15 lift: tube centre twister_axle_z=32, tube bottom 24.5 meets pedestal top 24.5.
    assert(twister_axle_z == 32, "twister_axle: bore centre must be 32 (tape_z 28 + 4)");
    assert(24.5 == twister_axle_z - 7.5, "twister_axle: pedestal top must meet lifted tube bottom (32-7.5)");
    // Step-8 root foot envelope (westward flare skirt x166..174, y27..41, z0..6):
    // east face flush with the pedestal (keeps the bevel-toe gap); top z6 stays
    // 15 below the plow-flare bound (z21.5); clears the static collar (176.5).
    assert(166 + 8 == tw_ped_x1, "Step-8 foot must end flush with pedestal east face");
    assert((twister_axle_z - 10.5) - 6 >= 15, "Step-8 foot top must stay 15 below the plow-flare bound");
    assert(tw_collar_x0 - 174 >= 2, "Step-8 foot must clear the static collar");
    difference() {
        union() {
            // Pedestal: x170..174, y lane_y-5..lane_y+5, z0..24.5 (fused)
            translate([tw_ped_x0, lane_y - 5, 0])
                cube([4, 10, 24.5], center=false);
            // Step-8 root foot: westward flare skirt x166..174, y27..41, z0..6
            // (fused to pedestal + base; top ducks 15 under the plow flare).
            translate([166, lane_y - 7, 0])
                cube([8, 14, 6], center=false);
            // Step-3a fused two-axis Γ support: source X169..175, wall to axle
            // center and axle center to floor; the Y31..34/Z29..32 overlap is
            // intentional fused material. No separate bracket or central fastener.
            translate([twister_support_x0, twister_support_wall_y0, twister_support_wall_z0])
                cube([twister_support_x1 - twister_support_x0,
                      twister_support_wall_y1 - twister_support_wall_y0,
                      twister_support_wall_z1 - twister_support_wall_z0], center=false);
            translate([twister_support_x0, twister_support_floor_y0, twister_support_floor_z0])
                cube([twister_support_x1 - twister_support_x0,
                      twister_support_floor_y1 - twister_support_floor_y0,
                      twister_support_floor_z1 - twister_support_floor_z0], center=false);
            translate([0, lane_y, twister_axle_z]) {
                // Tube: source x172..197.5, OD15, Ø10 through-bore.
                // Source +X maps to final west; the 4mm extension is derived
                // from tw_tube_west_extension and the moved nose remains inside.
                translate([tw_mouth_x, 0, 0])
                    rotate([0, 90, 0])
                        cylinder(h=tw_tube_len, r=15/2, center=false, $fn=60);
                // Static collar ring r9 x176.5..178.5 (fused on tube exterior;
                // inner r7.4 embeds 0.1 into the tube OD — kills the
                // coincident-skin seam, invisible outside)
                translate([tw_collar_x0, 0, 0])
                    rotate([0, 90, 0])
                        difference() {
                            cylinder(h=tw_collar_x1-tw_collar_x0, r=tw_collar_r, center=false, $fn=60);
                            translate([0, 0, -epsilon])
                                cylinder(h=tw_collar_x1-tw_collar_x0+2*epsilon, r=15/2 - 0.1, center=false, $fn=60);
                        }
                // (v122: old full-annulus end wall deleted — its end caps at
                // x197 coincided with the tube/cap caps (non-manifold); the
                // nose solid + tube carry the tip now.)
                // v122 Step-3 manifold rebuild: ONE solid of revolution for the
                // whole nose profile (stacked face-touching cylinders broke
                // watertightness). Annular profile (bore stays open): tube
                // r7.5 -> shoulder r9 (catch) -> ramp -> ogive tip r5.5.
                // Profile base embeds 1 into the tube; gap slots below split
                // it into 2 flex legs at ±Z.
                translate([tw_lock_x0 - 1, 0, 0])
                    rotate([0, 90, 0])
                        rotate_extrude($fn=60)
                            polygon(points=[
                                [tw_bore_d/2, 0],
                                [tw_axle_od/2, 0],
                                [tw_axle_od/2, 1],
                                [tw_lock_barb_r, 1],
                                [tw_lock_barb_r, 2],
                                [7, 4],
                                [tw_lock_tip_r, 6.5],
                                [tw_bore_d/2, 6.5]]);
            }
        }
        // Step-3a local pilots: M3 threads into the fused support; the matching
        // chassis holes are the only mating clearances and have no nut traps.
        translate([twister_support_anchor_source_x[0], twister_support_wall_pilot_y0, twister_support_wall_anchor_z])
            rotate([-90, 0, 0])
                cylinder(h=twister_support_wall_pilot_y1 - twister_support_wall_pilot_y0,
                         d=twister_support_wall_pilot_d, center=false, $fn=60);
        translate([twister_support_anchor_source_x[1], twister_support_floor_anchor_y, twister_support_floor_pilot_z0])
            cylinder(h=twister_support_floor_pilot_z1 - twister_support_floor_pilot_z0,
                     d=twister_support_floor_pilot_d, center=false, $fn=60);
        // Through-bore Ø10 extends west through the complete support slice.
        translate([0, lane_y, twister_axle_z])
            translate([twister_support_x0, 0, 0])
                rotate([0, 90, 0])
                    cylinder(h=tw_tube_x1 - twister_support_x0 + 2*epsilon, r=5, center=false, $fn=60);
        // One external C-slot: it starts at the bore boundary (r5) and
        // opens to r10.3, clearing the hub OD20 by 0.3mm radially. The
        // 10mm axial span backs the 5mm hub with 5mm total play; +Z keeps
        // it clear of the two ±Y nose flex gaps.
        translate([0, lane_y, twister_axle_z])
            rotate([tw_slot_ang, 0, 0])
                translate([tw_slot_x0, tw_slot_r0, -tw_slot_w/2])
                    cube([tw_slot_len, tw_slot_r1 - tw_slot_r0, tw_slot_w]);
        // Intentional two-leg nose flex gaps, derived from the moved nose;
        // cut radially toward ±Y from y=4.5 with z-width tw_gap_w.
        translate([0, lane_y, twister_axle_z])
            for (s = [0, 180])
                rotate([s, 0, 0])
                    translate([tw_lock_flex_x0, 4.5, -tw_gap_w/2])
                        cube([tw_lock_flex_x1 - tw_lock_flex_x0, 20, tw_gap_w], center=false);
    }
}

module takeup_reel() {
    assert(clutch_disc_r < takeup_flange_r, "takeup_reel: clutch must stay inside flange envelope");
    difference() {
        union() {
            cylinder(h=takeup_flange_t, r=takeup_flange_r, center=false);
            cylinder(h=takeup_core_h + takeup_flange_t, r=takeup_core_r, center=false);
            translate([0, 0, takeup_core_h])
                cylinder(h=takeup_flange_t, r=takeup_flange_r, center=false);
            // Wound-tape pack visual (finished tape coils on the core)
            translate([0, 0, takeup_flange_t])
                cylinder(h=takeup_core_h - takeup_flange_t, r=takeup_core_r + 3, center=false);
            // v40 SLIP CLUTCH on the axle (visual clutch discs 31..41):
            // pressure disc + friction disc (the slip interface: fast when
            // the reel is empty, slips when full as the pack diameter
            // grows) + spring + hex nut. Discs r8 < flange r16 so the
            // station X envelope (210..242) is unchanged; the geared base
            // ratio stays takeup_angle = -1440*$t (2x crank, sense reversed), the clutch
            // absorbs the diameter change mechanically (see viewer comment
            // + GEAR_RATIO.md; animation keeps the geared base speed).
            translate([0, 0, takeup_core_h + takeup_flange_t])
                cylinder(h=clutch_disc_t, r=clutch_disc_r, center=false);
            translate([0, 0, takeup_core_h + takeup_flange_t + clutch_disc_t])
                cylinder(h=clutch_disc_t, r=clutch_disc_r, center=false);
            translate([0, 0, takeup_core_h + takeup_flange_t + 2*clutch_disc_t])
                cylinder(h=clutch_spring_h, r=4.5, center=false);
            translate([0, 0, takeup_core_h + takeup_flange_t + 2*clutch_disc_t + clutch_spring_h])
                cylinder(h=clutch_nut_h, r=5, $fn=6, center=false);
        }
        // Axle bore through the whole reel + clutch
        translate([0, 0, -epsilon])
            cylinder(h=takeup_h_total + 2*epsilon, d=axle_clearance_dia, center=false);
    }
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
    s = crank_side; // +1 = arm/grip outboard of the FRONT wall (world +Y)
    arm_yc = s * (arm_w/2 + crank_arm_gap); // v102: handle stands 20 off the wall
    grip_y0 = arm_yc + s * arm_w/2; // v102: grip starts at the arm outer face
    grip_y1 = grip_y0 + s * grip_len;
    grip_yc = (grip_y0 + grip_y1)/2;
    // gear_local_y from params: world y=52: crank_mount_y(76)-24 (front, gear spans y 49..55)
    gear_thick = 6;           // matching drum/roller gear thickness

    difference() {
        union() {
            // Tapered arm via hull(boss, end)
            hull() {
                translate([pivot_x - 11, arm_yc, 0])
                    cylinder(h=arm_t, r=7, center=false);
                translate([pivot_x, arm_yc, 0])
                    cylinder(h=arm_t, r=9, center=false);
                translate([handle_x, arm_yc, 0])
                    cylinder(h=arm_t, r=6, center=false);
            }
            // (v102b: counterweight stub REMOVED — floating puck, fused to
            // nothing, read as a loose piece hanging on the shaft.)
            // Hub boss around shaft
            translate([pivot_x, arm_yc, pivot_z])
                rotate([90,0,0])
                    cylinder(h=16, r=7, center=true);
            // Pivot hex shaft (v102: 58mm — arm boss, through the front-wall
            // hex hole, full through the crank-gear hex bore; shifted 16
            // inboard so the tip stands 1 proud inside the gear: -28..+30)
            translate([pivot_x, arm_yc - s*16, pivot_z])
                rotate([90,0,0])
                    cylinder(h=hex_shaft_len, r=hex_axle_r, $fn=6, center=true);
            // Crank gear (20T) at front plane, meshes drum 40T AND the A10.
            // v140: the phase goes in as spur_gear(tooth_phase=...) so it turns
            // the TEETH only. It must NOT be wrapped around this call: the
            // module is drawn under rotate([-90,0,0]), so a wrapper turns the
            // hex bore too, and 15 deg is not a multiple of the 60 deg a $fn=6
            // hex has - the flats move off the (unrotated) hex shaft and the
            // bore buries 11.03 mm3 of it, 0.167mm deep at worst.
            // crank_mesh_phase is 0 and the constant stays wired anyway: the
            // drum 40T mesh in the SAME y band only clears at 0, so the whole
            // crank<->A10 phase is carried by v97_A_phase on the A cluster,
            // which is an assembly-time rotation. See params.scad for the
            // measurement table. Zero teeth turned here also keeps the printed
            // crank byte-identical to HEAD.
            translate([pivot_x, gear_local_y, pivot_z])
                rotate([-90,0,0])
                    spur_gear(teeth=roller_teeth, module_mm=gear_module, thickness=gear_thick,
                              bore_flat=hex_axle_flat, is_hex=true,
                              hub_dia=crank_gear_hub_dia, hub_len=crank_gear_hub_len, lightened=true,
                              tooth_phase=crank_mesh_phase);
            // Handle riser
            translate([handle_x, arm_yc, 0])
                cylinder(h=pivot_z + 5.5, r=5.5, center=false);
            // Grip (free-spinning, tapered, parallel to shaft axis Y)
            hull() {
                translate([handle_x, grip_y0 + s*3, pivot_z])
                    rotate([90,0,0])
                        cylinder(h=10, d=grip_dia, center=true);
                translate([handle_x, grip_yc, pivot_z])
                    rotate([90,0,0])
                        cylinder(h=12, d=grip_dia - 2, center=true);
                translate([handle_x, grip_y1 - s*3, pivot_z])
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
        translate([pivot_x + crank_throw/2, arm_yc, -epsilon])
            cylinder(h=arm_t + 2*epsilon, d=6, center=false);
    }
}

// ============================================================
// Animated assembly
// Sign convention (v79: crank at x=160, 20T meshes drum 40T at x=100):
//   crank_angle = 720*$t (2:1 vs drum, CW about +Y).
//   drum_angle = -360*$t (external mesh counter-rotation, 0.5× crank).
//   twister_angle = twister_rev*crank_angle (1:1 mitre, opposite crank).
//   takeup_angle = -1440*$t about the reel axle.
//   v79: rollers REMOVED; crank carries the 20T pinion at x=160.
// ============================================================
