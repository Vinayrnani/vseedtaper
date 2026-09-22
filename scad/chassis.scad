module chassis() {
    difference() {
        union() {
            translate([chassis_x0, 0, 0])
                cube([chassis_len, chassis_width, base_thick]);
            translate([chassis_x0, 0, 0])
                cube([chassis_len, wall_thick, chassis_height]);
            translate([chassis_x0, chassis_width - wall_thick, 0])
                cube([chassis_len, wall_thick, chassis_height]);
            // Track rails
            rail_thick = 2;
            rail_len = 200;
            rail_x0 = 10;
            translate([rail_x0, (chassis_width - paper_width)/2 - rail_thick, base_thick - 0.15])
                cube([rail_len, rail_thick, track_depth + 0.15]);
            translate([rail_x0, (chassis_width + paper_width)/2, base_thick - 0.15])
                cube([rail_len, rail_thick, track_depth + 0.15]);
            // Hopper slide rails
            translate([drum_axle_x - 22, 7, base_thick - 0.15])
                cube([44, 8, 6 + 0.15]);
            translate([drum_axle_x - 22, chassis_width - 15, base_thick - 0.15])
                cube([44, 8, 6 + 0.15]);
            // Bearing blocks (pillow-block style)
            for (spec=[[drum_axle_x,   drum_axle_z,   bb_height_drum,   1],
                       [crank_axle_x,  crank_axle_z,  bb_height_roller, 1],
                       [spool_axle_x,  spool_axle_z,  bb_height_spool,  0]])
                for (side=[0,1]) {
                    // v27 printable: fuse blocks to BOTH walls (front y_off=0
                    // -> Y -2..2 overlaps wall 0..3; back y_off=60 -> 58..62
                    // overlaps wall 57..60). Old code ignored side (all at
                    // front, back blocks floated unfused).
                    bearing_block(spec[0], spec[1], spec[2], spec[3]==1,
                                  side == 0 ? 0 : chassis_width);
                }
            // v37 wind-up reel bearing blocks (axle along Y at takeup_x/takeup_z)
            for (side=[0,1])
                bearing_block(takeup_x, takeup_z, bb_height_spool, false,
                              side == 0 ? 0 : chassis_width);
            // v40 MOUNTING LAYOUT (parametric on the station X positions):
            // BOTTOM mount: 6-turner (M3 holes below) + wind-up reel
            //   (take-up bearing blocks above ride the base).
            // SIDE mount: twister ring + pull rollers + drum (axles pass
            //   through the chassis walls: axle holes + blocks below).
            // TOP mount: hopper+shroud (slide rails + sole-flange M3) +
            //   tape input spools (spool blocks feed from above).
            // v40 pull top bridge (side-mount story for the vertical nip):
            // cross bar fused wall-to-wall over the nip at pull_x.
            // v47: SOLID bridge (no tube hole — tape-coupled nip, zero
            // exterior gears); cup B kept (bored) for the static pin B.
            // v52 SHORTER stack (roller top 27): bridge 28, cup 25..28.
            // v87 +15 lift: bridge 43, cup 40..43 (roller top 42).
            translate([pull_x - 2, 0, 43])
                cube([4, chassis_width, 3]);
            translate([pull_x, chassis_width/2 + vpull_off, 40])
                difference() {
                    cylinder(h=3 + epsilon, r=6, center=false);
                    translate([0, 0, -epsilon])
                        cylinder(h=3 + 3*epsilon, d=axle_clearance_dia, center=false);
                }
            // v48 pull support pins (static bars: base-fused, slip-fit
            // in roller bores + cup-B bore; the tape-coupled rotors
            // spin on them — supported both ends, never coplanar).
            translate([pull_x, chassis_width/2 - vpull_off, (pull_pinA_z0 + pull_pinA_z1)/2])
                cylinder(h=pull_pinA_z1 - pull_pinA_z0, r=pull_pin_r, center=true);
            translate([pull_x, chassis_width/2 + vpull_off, (pull_pinB_z0 + pull_pinB_z1)/2])
                cylinder(h=pull_pinB_z1 - pull_pinB_z0, r=pull_pin_r, center=true);
            // v95 merged C-idler pedestal (chassis-fused): base x166-171.5
            // (west of teeth 172) + solid tower x166-169 (no slots: C15/I1
            // start at x170). Feet notch the tape flat (y21.3-46.7 z13-22):
            // feet y9-21 + y47-54, span y21-47 z0-13, columns z22.5+,
            // bridge-high z37-62 (over pocket top 36), tower z58-90 with
            // C bore (47,Bz) + idler bore (Iy,Iz). C overhangs 12 east,
            // idler rides pedestal + bar1 (demo loads, documented).
            translate([v95_ped_x0, 9, 0]) cube([5.5, 12, 22.5]);
            translate([v95_ped_x0, 47, 0]) cube([5.5, 7, 22.5]);
            translate([v95_ped_x0, 21, 0]) cube([5.5, 26, 13]);
            translate([v95_ped_x0, 24, 22.5]) cube([5.5, 18, 35.5]);
            translate([v95_ped_x0, 20, 37]) cube([5.5, 28, 25]);
            difference() {
                translate([v95_ped_x0, 24, 58]) cube([3, 26, 32]);
                // C bore d6.6 along X at (47, Bz)
                translate([v95_ped_x0 - epsilon, 47, v95_Bz])
                    rotate([0, 90, 0])
                        cylinder(h=3 + 2*epsilon, d=6.6, center=false, $fn=60);
                // Idler bore d6.6 along X at (Iy, Iz)
                translate([v95_ped_x0 - epsilon, v95_I_y, v95_I_z])
                    rotate([0, 90, 0])
                        cylinder(h=3 + 2*epsilon, d=6.6, center=false, $fn=60);
            }
            // v45 DEAD AXLES (static bars, slip-fit through bores/holes):
            // drum hex through-shaft (fuses into the solid v48 drum spur,
            // slip in the drum/interior-gear hex bores + wall/block hex
            // holes — the drum stays free to spin); take-up round shaft
            // (slip in the reel/wall/block round bores); spool round
            // shaft (slip in cone hex holes + wall/block bores, ends hidden
            // in the block bores). Ends buried/hidden, never coplanar.
            // v87 +15: drum 75, takeup rod 49, cone rod (spool) 80.
            translate([drum_axle_x, (drum_shaft_y0 + drum_shaft_y1)/2, drum_axle_z])
                rotate([90, 0, 0])
                    cylinder(h=drum_shaft_y1 - drum_shaft_y0, r=hex_axle_r, $fn=6, center=true);
            translate([takeup_x, (takeup_shaft_y0 + takeup_shaft_y1)/2, takeup_z])
                rotate([90, 0, 0])
                    cylinder(h=takeup_shaft_y1 - takeup_shaft_y0, r=axle_dia/2, center=true);
            translate([spool_axle_x, (spool_shaft_y0 + spool_shaft_y1)/2, spool_axle_z])
                rotate([90, 0, 0])
                    cylinder(h=spool_shaft_y1 - spool_shaft_y0, r=axle_dia/2, center=true);
            // v67 chassis feet (4x 12x12 cubes, z=tw_foot_z..0, fused into base overlap 0..1)
            for (fx=[chassis_x0+2, chassis_x0+chassis_len-14])
                for (fy=[4, chassis_width-16])
                    translate([fx, fy, tw_foot_z])
                        cube([12, 12, -tw_foot_z]);
            // Corner gussets via hull() of cubes
            for (gy=[0, chassis_width - 6]) {
                translate([chassis_x0 + 4, gy, base_thick - 0.15])
                    hull() {
                        cube([12, 6, 1.15]);
                        translate([0, 0, 12]) cube([1.5, 6, 1]);
                    }
                translate([chassis_x0 + chassis_len - 16, gy, base_thick - 0.15])
                    hull() {
                        cube([12, 6, 1.15]);
                        translate([10.5, 0, 12]) cube([1.5, 6, 1]);
                    }
            }
        }
        // Axle holes (nominal + 2*tolerance)
        for (side=[0,1]) {
            translate([spool_axle_x, side*(chassis_width-wall_thick)+wall_thick/2, spool_axle_z])
                rotate([90,0,0])
                    cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        }
        for (side=[0,1]) {
            translate([takeup_x, side*(chassis_width-wall_thick)+wall_thick/2, takeup_z])
                rotate([90,0,0])
                    cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        }
        // v79: crank shaft hex hole at x=160 through both walls
        for (side=[0,1]) {
            translate([crank_axle_x, side*(chassis_width-wall_thick)+wall_thick/2, crank_axle_z])
                rotate([90,0,0])
                    cylinder(h=wall_thick+2*epsilon, r=hex_clearance_r, $fn=6, center=true);
        }
        for (side=[0,1]) {
            translate([drum_axle_x, side*(chassis_width-wall_thick)+wall_thick/2, drum_axle_z])
                rotate([90,0,0])
                    cylinder(h=wall_thick+2*epsilon, r=hex_clearance_r, $fn=6, center=true);
        }
        // v95: A/B round shaft bores (r4 shafts -> d8.6) through both walls.
        // A/B cantilever from the front-wall bores (demo loads).
        for (side=[0,1]) {
            translate([v95_Ax, side*(chassis_width-wall_thick)+wall_thick/2, v95_Az])
                rotate([90,0,0])
                    cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        }
        for (side=[0,1]) {
            translate([v95_Bx, side*(chassis_width-wall_thick)+wall_thick/2, v95_Bz])
                rotate([90,0,0])
                    cylinder(h=wall_thick+2*epsilon, d=axle_clearance_dia, center=true);
        }
        // v48: NO idler stubs fuse into the back wall (zero exterior
        // gears) — the wall keeps full section everywhere. The solid
        // pull bridge needs no hole (tape-coupled nip, no drive tube).
        // 45° chamfers on base edges
        translate([chassis_x0, chassis_width/2, base_thick])
            rotate([0,45,0])
                cube([2.5, chassis_width + 2*epsilon, 2.5], center=true);
        translate([chassis_x0 + chassis_len, chassis_width/2, base_thick])
            rotate([0,45,0])
                cube([2.5, chassis_width + 2*epsilon, 2.5], center=true);
        // Plow mounting holes
        for (px=[plow_start + 6, plow_start + plow_len - 6])
            for (py=[6, 62]) {
                translate([px, py, base_thick/2])
                    cylinder(h=base_thick + 2*epsilon, d=bolt_dia + 2*tolerance, center=true);
                translate([px, py, -epsilon])
                    cylinder(h=nut_trap_depth + epsilon,
                             r=(bolt_head_across + 2*tolerance)/sqrt(3), $fn=6, center=false);
            }
        // Hopper rail slots
        translate([drum_axle_x - 20.2, 7 + (8-6.4)/2, base_thick - epsilon])
            cube([40.4, 6.4, 6 + 2*epsilon]);
        translate([drum_axle_x - 20.2, chassis_width - 15 + (8-6.4)/2, base_thick - epsilon])
            cube([40.4, 6.4, 6 + 2*epsilon]);
        // Twister slot cutout (replaces old drop-pocket)
        translate([tw_slot_x0, tw_slot_y0, -epsilon])
            cube([tw_slot_x1-tw_slot_x0, tw_slot_y1-tw_slot_y0, base_thick+2*epsilon]);
        // Lightening cutouts in walls
        translate([56, -epsilon, 64])
            cube([24, wall_thick+2*epsilon, 22]);
        translate([90, chassis_width - wall_thick - epsilon, 18])
            cube([30, wall_thick+2*epsilon, 22]);
    }
}

// ============================================================
// 2. Spool cones (tapered, 15-45mm OD) - flat base at Z=0
// ============================================================
