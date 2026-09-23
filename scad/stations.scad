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
// v37 Thread-bind + vertical pull + wind-up (v36 MVP backfill).
// Allowed modules only; $fn=60 inherited; tol=0.3 clearances.
// - thread_twister(): HOLLOW rotor CENTRED at origin, axis along X:
//   hub sleeve (outer r10, bore 15.6) + disc (r23) + non-meshing
//   visual bevel-blank teeth (placeholder only, never gear math) +
//   2 spindle pins (orbit R19, 180 apart) + 2 bobbin visuals on
//   the pins + 2 eyelet posts (orbit R12, 90/270 offset).
//   Assembly spins it about X at [bind_x, lane_y, twister_axle_z]
//   by twister_angle.
// - vpull_roller(): ONE vertical-axis nip roller, base at z=0
//   (body d15 h20 + caps/collar, min_z=0 in export AND assembly):
//   pair stands on the base flanking the finished folded tape at
//   [pull_x, lane_y +/- vpull_off], spins about Z (4/3 vs main
//   roller, smaller dia => same surface speed => spacing preserved).
// - takeup_reel(): wind-up reel built along Z for flat printing
//   (bottom flange 0..3 + core r5 0..31 + top flange 28..31,
//   min_z=0); assembly recentres, tilts to axle-Y, spins about
//   the axle by takeup_angle (4 rev per $t = same linear tape).
// ============================================================
module thread_twister() {
    assert(twister_arms == 2, "thread_twister: must carry exactly 2 spindles");
    difference() {
        union() {
            // Hub sleeve: outer r10, bore 15.6 (local x -5..0 = abs 179..184)
            translate([-5, 0, 0])
                rotate([0, 90, 0])
                    difference() {
                        cylinder(h=5, r=10, center=false, $fn=60);
                        translate([0, 0, -epsilon])
                            cylinder(h=5 + 2*epsilon, r=15.6/2, center=false, $fn=60);
                    }
            // Disc: r23, local -5..-2 = abs 179..182
            translate([-5, 0, 0])
                rotate([0, 90, 0])
                    difference() {
                        cylinder(h=3, r=23, center=false, $fn=60);
                        translate([0, 0, -epsilon])
                            cylinder(h=3 + 2*epsilon, r=15.6/2, center=false, $fn=60);
                    }
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
            translate([16, 0, 0])
                rotate([0, -90, 0])
                    bev_teeth(tw_bev_n, 22.5, tw_bev_face, tw_bev_thin, tw_bev_phase, tw_bev_mod);
            // Root cone frustum under the teeth (canonical z22..25.3 mapped,
            // embedded 0.3 into the web for manifold union):
            translate([16, 0, 0])
                rotate([0, -90, 0])
                    translate([0, 0, 21.7])
                        cylinder(h=3.6, r1=21.1, r2=18.2, center=false, $fn=60);
            // Back web solid r24 (canonical z18.6..22.5 mapped; embedded 0.3
            // into the tooth heels; bore + relief cut it in the difference):
            translate([16, 0, 0])
                rotate([0, -90, 0])
                    translate([0, 0, 18.6])
                        cylinder(h=3.9, r=24, center=false, $fn=60);
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
        // Central bore through hub sleeve + disc (tape path)
        translate([-8, 0, 0])
            rotate([0, 90, 0])
                cylinder(h=16, r=15.6/2, center=false, $fn=60);
        // v113 back-cone relief: annulus (r9-13, abs tw_relief_x0..x1)
        // in the disc west face — catches the B heel corner (standard
        // bevel back-cone relief; keeps >=1 wall to the bore).
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
    // fused with tube (x172..197, OD15, Ø10 through-bore) + collar (r9 x176.5..178)
    // + groove in hub bore (r9 x193.5..196) + full annulus wall (r5..7.5 x186..197) with 3 tapered slots.
    // v87 +15 lift: tube centre twister_axle_z=32, tube bottom 24.5 meets pedestal top 24.5.
    assert(twister_axle_z == 32, "twister_axle: bore centre must be 32 (tape_z 28 + 4)");
    assert(24.5 == twister_axle_z - 7.5, "twister_axle: pedestal top must meet lifted tube bottom (32-7.5)");
    difference() {
        union() {
            // Pedestal: x170..174, y lane_y-5..lane_y+5, z0..24.5 (fused)
            translate([tw_ped_x0, lane_y - 5, 0])
                cube([4, 10, 24.5], center=false);
            translate([0, lane_y, twister_axle_z]) {
                // Tube: x172..197, OD15, Ø10 through-bore
                translate([tw_mouth_x, 0, 0])
                    rotate([0, 90, 0])
                        cylinder(h=25, r=15/2, center=false, $fn=60);
                // Funnel flare at mouth x172 (flared entry for tape threading)
                translate([tw_mouth_x, 0, 0])
                    rotate([0, 90, 0])
                        cylinder(h=3, r1=12, r2=15/2, center=false, $fn=60);
                // Static collar ring r9 x176.5..178 (fused on tube exterior)
                translate([tw_collar_x0, 0, 0])
                    rotate([0, 90, 0])
                        difference() {
                            cylinder(h=tw_collar_x1-tw_collar_x0, r=tw_collar_r, center=false, $fn=60);
                            translate([0, 0, -epsilon])
                                cylinder(h=tw_collar_x1-tw_collar_x0+2*epsilon, r=15/2, center=false, $fn=60);
                        }
                // Full annulus wall x186..197: r5..7.5 (2.5mm solid wall over r5 bore)
                // Single 360° ring — NOT per-finger — keeps it chunky-solid
                translate([tw_finger_base_x0, 0, 0])
                    rotate([0, 90, 0])
                        linear_extrude(height=tw_finger_base_x1-tw_finger_base_x0)
                            difference() {
                                circle(r=7.5, $fn=60);
                                circle(r=5, $fn=60);
                            }
                // 3 barb fingers @120°: ramp r7.5→r9 + barb r9 + tip r9→r7
                for (i=[0:tw_finger_n-1])
                    rotate([i*120, 0, 0]) {
                        // Ramp section x181..182: r7.5 → r9 (protruding ramp)
                        translate([tw_finger_ramp_x0, 0, 0])
                            rotate([0, 90, 0])
                                hull() {
                                    linear_extrude(height=epsilon)
                                        intersection() {
                                            circle(r=15/2, $fn=60);
                                            rotate([-tw_finger_angle/2, 0, 0])
                                                square([15, 15]);
                                        }
                                    translate([0, 0, tw_finger_ramp_x1-tw_finger_ramp_x0-epsilon])
                                        linear_extrude(height=epsilon)
                                            intersection() {
                                                circle(r=tw_finger_barb_r, $fn=60);
                                                rotate([-tw_finger_angle/2, 0, 0])
                                                    square([15, 15]);
                                            }
                                }
                        // Barb section x182..183.5: r9 (flat locking shoulder)
                        translate([tw_finger_barb_x0, 0, 0])
                            rotate([0, 90, 0])
                                linear_extrude(height=tw_finger_barb_x1-tw_finger_barb_x0)
                                    intersection() {
                                        circle(r=tw_finger_barb_r, $fn=60);
                                        rotate([-tw_finger_angle/2, 0, 0])
                                            square([15, 15]);
                                    }
                        // Tip taper x183.5..185: r9 → r7
                        translate([tw_finger_tip_x0, 0, 0])
                            rotate([0, 90, 0])
                                hull() {
                                    linear_extrude(height=epsilon)
                                        intersection() {
                                            circle(r=tw_finger_barb_r, $fn=60);
                                            rotate([-tw_finger_angle/2, 0, 0])
                                                square([15, 15]);
                                        }
                                    translate([0, 0, tw_finger_tip_x1-tw_finger_tip_x0-epsilon])
                                        linear_extrude(height=epsilon)
                                            intersection() {
                                                circle(r=tw_finger_tip_r, $fn=60);
                                                rotate([-tw_finger_angle/2, 0, 0])
                                                    square([15, 15]);
                                            }
                                }
                    }
            }
        }
        // Through-bore Ø10 (full tube length)
        translate([0, lane_y, twister_axle_z])
            translate([tw_mouth_x, 0, 0])
                rotate([0, 90, 0])
                    cylinder(h=25 + 2*epsilon, r=5, center=false, $fn=60);
        // Hub bore groove r9 x193.5..196 (recess in bore wall)
        translate([0, lane_y, twister_axle_z])
            translate([tw_groove_x0, 0, 0])
                rotate([0, 90, 0])
                    difference() {
                        cylinder(h=tw_groove_x1-tw_groove_x0, r=tw_groove_r, center=false, $fn=60);
                        translate([0, 0, -epsilon])
                            cylinder(h=tw_groove_x1-tw_groove_x0+2*epsilon, r=5, center=false, $fn=60);
                    }
        // Annular cap face at tip: r5..r7 ring x184.5..185 (1mm face, bore Ø10 through)
        translate([0, lane_y, twister_axle_z])
            translate([tw_cap_x0, 0, 0])
                rotate([0, 90, 0])
                    difference() {
                        cylinder(h=tw_cap_x1-tw_cap_x0, r=tw_cap_r1, center=false, $fn=60);
                        translate([0, 0, -epsilon])
                            cylinder(h=tw_cap_x1-tw_cap_x0+2*epsilon, r=tw_cap_r0, center=false, $fn=60);
                    }
        // 3 uniform through-slots at 60°, 180°, 300° (radial cuts through annulus)
        // Width 1.5mm uniform x176..185, radial r4..r8
        translate([0, lane_y, twister_axle_z])
            for (g=[0:tw_finger_n-1])
                rotate([g*120 + 60, 0, 0])
                    hull() {
                        translate([tw_slot_x0, -tw_slot_w0/2, -tw_slot_r1])
                            cube([epsilon, tw_slot_w0, 2*tw_slot_r1]);
                        translate([tw_slot_x1-epsilon, -tw_slot_w1/2, -tw_slot_r1])
                            cube([epsilon, tw_slot_w1, 2*tw_slot_r1]);
                    }
        // Mouth chamfer: 0.5mm lead-in at x174 (bore r5 → annulus r7.5)
        translate([0, lane_y, twister_axle_z])
            translate([tw_finger_base_x0, 0, 0])
                rotate([0, 90, 0])
                    cylinder(h=0.5, r1=5, r2=7.5, center=false, $fn=60);
    }
}

module vpull_roller() {
    assert(vpull_sleeve_r <= 7.8, "vpull_roller: cushion sleeve must stay ~d15 (4/3 spin)");
    difference() {
      union() {
        cylinder(h=vpull_h, r=vpull_r, center=false);
        // v39 CUSHIONED nip (soft rubber/silicone sleeve visual over the
        // steel core: firm grip without crushing the seed pocket; viewer
        // paints it dark rubber). OD stays ~d15 (sleeve proud 0.15, caps
        // r8.5 still dominate the envelope) => 4/3 spin keeps surface speed.
        translate([0, 0, (vpull_h - vpull_sleeve_h)/2])
            cylinder(h=vpull_sleeve_h, r=vpull_sleeve_r, center=false);
        // Cushion grip ribs (shallow visual rings on the sleeve)
        for (k=[0:5])
            translate([0, 0, (vpull_h - vpull_sleeve_h)/2 + 2 + k*(vpull_sleeve_h - 4)/5])
                difference() {
                    cylinder(h=0.8, r=vpull_sleeve_r + 0.3, center=false);
                    translate([0, 0, -epsilon])
                        cylinder(h=0.8 + 2*epsilon, r=vpull_sleeve_r - 0.2, center=false);
                }
        // Diamond knurl band (visual grip, shallow so OD stays ~15)
        for (k=[0:11]) {
            t = k/11;
            zpos = 4 + t*(vpull_h - 8);
            rotate([0, 0, k*30])
                translate([vpull_r - 0.5, 0, zpos])
                    cube([1.2, 2.0, 2.6], center=true);
        }
        translate([0, 0, vpull_h])
            difference() {
                cylinder(h=3, d=17, center=false);
                translate([0, 0, -epsilon])
                    cylinder(h=3 + 2*epsilon, d=axle_clearance_dia, center=false);
            }
        // v45: mid collar rides LOW (centre vpull_collar_z=5.0 local, CAD top
        // 4+5+1.5=10.5: clears the ribbon base tape_z=13 by 2.5; was 12
        // with top 13.5+4 grazing into the tape). Top cap (20..23) is above
        // the tape zone; sleeve/rib grip at the nip is intended (soft).
        translate([0, 0, vpull_collar_z])
            difference() {
                cylinder(h=3, d=17, center=true);
                translate([0, 0, 0])
                    cylinder(h=3 + 2*epsilon, d=axle_clearance_dia, center=true);
            }
      }
      // Axle bore through body + caps
      translate([0, 0, -epsilon])
          cylinder(h=vpull_h + 3 + 2*epsilon, d=axle_clearance_dia, center=false);
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
            // Crank gear (20T) at front plane, meshes drum 40T
            translate([pivot_x, gear_local_y, pivot_z])
                rotate([-90,0,0])
                    spur_gear(teeth=roller_teeth, module_mm=gear_module, thickness=gear_thick,
                              bore_flat=hex_axle_flat, is_hex=true, hub_dia=20, hub_len=8, lightened=true);
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
//   twister_angle = 360*$t*twister_orbits_per_drum (v95: 15 orbits/drum rev = 2.5 wraps/seed, driven +7.5x by the D friction wheel below).
//   pull nip pair spins about Z at ±roller_angle*vpull_spin (tape-coupled
//   4/3 vs the main roller, v52 d15 dia => same surface speed).
//   takeup_angle = -1440*$t about the reel axle.
//   v79: rollers REMOVED; crank carries the 20T pinion at x=160.
// ============================================================
