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
            // Hub sleeve: outer r10, bore 15.6 (local x -5..0 = abs 167..172)
            translate([-5, 0, 0])
                rotate([0, 90, 0])
                    difference() {
                        cylinder(h=5, r=10, center=false, $fn=60);
                        translate([0, 0, -epsilon])
                            cylinder(h=5 + 2*epsilon, r=15.6/2, center=false, $fn=60);
                    }
            // Disc: r23, local -5..-2 = abs 167..170
            translate([-5, 0, 0])
                rotate([0, 90, 0])
                    difference() {
                        cylinder(h=3, r=23, center=false, $fn=60);
                        translate([0, 0, -epsilon])
                            cylinder(h=3 + 2*epsilon, r=15.6/2, center=false, $fn=60);
                    }
            // Non-meshing visual bevel-blank teeth: 24 boxes in annulus
            // r16..22, local x -1.5..+1.5 east of disc face; -8 is z-offset of ring centre (placeholder only,
            // never gear math — viewer paints them as visual texture)
            for (i=[0:23]) {
                rotate([i*15, 0, 0])
                    translate([0, 19, -8])
                        cube([3, 4, 3], center=true);
            }
            // 2 spindle pins: r3, orbit R19, 180 apart, local -2..+7.5 = abs 170..179.5
            for (k=[0:twister_arms-1])
                rotate([k*180, 0, 0]) {
                    translate([-2, 19, 0])
                        rotate([0, 90, 0])
                            cylinder(h=9.5, r=3, center=false, $fn=60);
                    // Bobbin visual: r10.35 h11.1 centred on pin, local -2.5..+8.6 = abs 169.5..180.6
                    translate([-2.5, 19, 0])
                        rotate([0, 90, 0])
                            cylinder(h=11.1, r=10.35, center=false, $fn=60);
                    // Collet lip ring at pin tip
                    translate([7.5, 19, 0])
                        rotate([0, 90, 0])
                            difference() {
                                cylinder(h=1.2, r=4.5, center=false, $fn=60);
                                translate([0, 0, -epsilon])
                                    cylinder(h=1.2 + 2*epsilon, r=3.1, center=false, $fn=60);
                            }
                }
            // 2 eyelet posts: r1.5 h6 at orbit R12, 90/270 offset
            // from spindles, local -2..+4 = abs 170..176
            for (offset=[90, 270])
                rotate([offset, 0, 0]) {
                    translate([-2, 12, 0])
                        rotate([0, 90, 0])
                            cylinder(h=6, r=1.5, center=false, $fn=60);
                }
        }
        // Central bore through hub sleeve + disc (tape path)
        translate([-8, 0, 0])
            rotate([0, 90, 0])
                cylinder(h=16, r=15.6/2, center=false, $fn=60);
        // Ø2 cross-hole near top of each eyelet post
        for (offset=[90, 270])
            rotate([offset, 0, 0]) {
                translate([4, 12, 0])
                    rotate([0, 90, 0])
                        cylinder(h=2, r=1, center=false, $fn=60);
            }
    }
}

module twister_axle() {
    // Absolute coordinates: pedestal (x161..165, y lane_y±5, z0..9.5)
    // fused with tube (x160..184, OD15, Ø10 through-bore) + snap fingers (x182..184).
    difference() {
        union() {
            // Pedestal: x161..165, y lane_y-5..lane_y+5, z0..9.5 (fused)
            translate([161, lane_y - 5, 0])
                cube([4, 10, 9.5], center=false);
            translate([0, lane_y, twister_axle_z]) {
                // Tube: x160..184, OD15, Ø10 through-bore
                translate([160, 0, 0])
                    rotate([0, 90, 0])
                        cylinder(h=24, r=15/2, center=false, $fn=60);
                // Funnel flare at mouth x160 (flared entry for tape threading)
                translate([160, 0, 0])
                    rotate([0, 90, 0])
                        cylinder(h=3, r1=12, r2=15/2, center=false, $fn=60);
                // 3 snap fingers at x182..184: cantilever hooks with 1.2 slots
                // and 0.8 barb lips, 120° apart around the tube end
                for (i=[0:2])
                    rotate([i*120, 0, 0]) {
                        // Finger body (4 wide, 6 long, 1.6 thick radial)
                        translate([182, 7.5, 0])
                            cube([6, 4, 1.6], center=true);
                        // Barb lip (0.8 thick, protruding inward)
                        translate([184, 6.8, 0])
                            cube([1.5, 2, 0.8], center=true);
                    }
            }
        }
        // Through-bore Ø10 (full tube length)
        translate([0, lane_y, twister_axle_z])
            translate([160, 0, 0])
                rotate([0, 90, 0])
                    cylinder(h=24 + 2*epsilon, r=5, center=false, $fn=60);
        // Snap finger slots (1.2 wide gaps between hooks)
        translate([0, lane_y, twister_axle_z])
            for (i=[0:2])
                rotate([i*120, 0, 0]) {
                    translate([182, 5, -0.6])
                        cube([6, 1.2, 1.2], center=false);
                }
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
    s = crank_side; // v23: -1 = arm/grip extend -Y outward from the back wall (was +1 front)
    arm_yc = s * arm_w/2;
    grip_y0 = s * arm_w;
    grip_y1 = grip_y0 + s * grip_len;
    grip_yc = (grip_y0 + grip_y1)/2;
    gear_local_y = -24;      // world y=44: 68-24 (front, gear spans y 41..47)
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
            // Counterweight stub opposite handle
            translate([pivot_x - 5, -arm_yc, 0])
                cylinder(h=arm_t, r=5, center=false);
            // Hub boss around shaft
            translate([pivot_x, arm_yc, pivot_z])
                rotate([90,0,0])
                    cylinder(h=16, r=7, center=true);
            // Pivot hex shaft (28mm, centred at arm_yc)
            translate([pivot_x, arm_yc, pivot_z])
                rotate([90,0,0])
                    cylinder(h=hex_shaft_len, r=hex_axle_r, $fn=6, center=true);
            // 20T crank gear, front plane world y 45..51, meshes drum 40T (dist 60)
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
//   twister_angle = 360*$t*twister_orbits_per_drum (visual spin only; real gears in a later version).
//   pull nip pair spins about Z at ±roller_angle*vpull_spin (tape-coupled
//   4/3 vs the main roller, v52 d15 dia => same surface speed).
//   takeup_angle = -1440*$t about the reel axle.
//   v79: rollers REMOVED; crank carries the 20T pinion at x=160.
// ============================================================
