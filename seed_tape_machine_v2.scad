/*
    Modular Hand-Cranked Seed Tape Machine - v2 Master
    ====================================================
    Thin master: all geometry lives in six included files.
    Includes (monolith order):
      scad/params.scad    — global variables, kinematics, assertions, helpers
      scad/gears.scad     — hex_hole, round_axle_hole, spur_gear, bevel_gear, hex_bolt, bearing_block
      scad/chassis.scad   — chassis()
      scad/feed.scad      — single_cone, spool_cones, hopper_body, seed_cartridge, seed_cradle
      scad/plow.scad      — scroll_sheet, six_turner, folding_plow
      scad/stations.scad  — seed_tape_bend, former_collar, knurled_roller, pull_rollers, thread_twister, vpull_roller, takeup_reel, crank_assembly
*/

part_to_render = "all";
animate_assembly = true;

include <scad/params.scad>;
include <scad/gears.scad>;
include <scad/chassis.scad>;
include <scad/feed.scad>;
include <scad/plow.scad>;
include <scad/stations.scad>;

module animated_assembly() {
    drum_angle = -360*$t + 4.5;  // v81: +4.5° half-pitch phase (40T drum) for tooth-into-gap mesh with crank 20T
    crank_angle = 720*$t;   // v79: crank 20T spins 2x drum (CW, meshes drum 40T)
    roller_angle = crank_angle + gear_mesh_phase; // mesh-phased crank gear
    twister_angle = 360*$t*twister_orbits_per_drum; // v37: 6 orbits/drum rev about X
    pull_a_angle = roller_angle*vpull_spin;   // v52: nip side A spin-compensated 4/3
    pull_b_angle = -roller_angle*vpull_spin;  // v52: nip side B counter-rotates 4/3
    takeup_angle = -1440*$t;       // v48: tape-tension wind-up

    // Chassis
    chassis();

    // Static twister axle (absolute coords, no transform — pedestal + tube + snap fingers)
    twister_axle();

    // Spool cones (v87 +15: spool_axle_z=80)
    translate([spool_axle_x, wall_thick+1, spool_axle_z])
        rotate([-90,0,0]) single_cone();
    translate([spool_axle_x, chassis_width-wall_thick-1, spool_axle_z])
        rotate([90,0,0]) single_cone();

    // Drum
    translate([drum_axle_x, chassis_width/2, drum_axle_z])
        rotate([0, drum_angle, 0])
            translate([0, 0, -drum_dia/2])
                seed_cartridge(seed_dia, seed_depth);

    // Hopper (v34 OD10: ONE printed piece — right wedge pickup level
    // top z=73, open-top half-pipe 16mm/8mm cover 11->6 with grooves,
    // 2 side joints, closed box, bottom-center hover pipe ID6/OD10 L10
    // at drum x hovering 10 above the lowered lane)
    // v87 +15 lift: hopper_axis_z frozen at 56 → translate Z = drum_axle_z - 56 = 19 = base_thick+15
    translate([drum_axle_x, chassis_width/2, drum_axle_z - hopper_axis_z])
        hopper_body();

    // Seed cradle
    translate([plow_start, chassis_width/2 - 12.7, base_thick + 15])
        seed_cradle();

    // Seed tape with center U-fold (v34 OD10: narrow 4 trough,
    // R1.5, 5.5 walls, S-shoulders; v31: forming 37..70 fully west of
    // the drum face + straight full-U transit 70..126 under the drum
    // (13.6 air gap) UNDER the hover pipe (10 gap) to the plow mouth;
    // static in CAD, scrolls in the viewer; single-layer floor, min_z=0).
    translate([tape_x0, chassis_width/2, tape_z])
        seed_tape_bend();

    // Former collar (v28 visual, v31 at the forming exit): stainless
    // transverse shoe with U notch straddling the full-U section at the
    // forming exit (world x ~67, clear of the wheel).
    translate([fold_end - 3, chassis_width/2, tape_z + tape_thick])
        former_collar();

    // Folding plow (v39 REPLACED by the 6-turner/roller former: the
    // seeded tape rolls through the 6 curl east of the drop, world x
    // 126..159, v1-precedent footprint kept; seed lands flat at 100
    // first, then the curl rolls the edges over)
    translate([plow_start, chassis_width/2 - 20, base_thick])
        six_turner();

    // v79: rollers REMOVED; upper/lower roller lines deleted.

    // Crank drives from x=160 (v79): 20T gear meshes drum 40T at dist=60.
    // Front wall (Y=68), grip +Y outward. Crank rotates 2x drum (720*$t).
    translate([crank_mount_x, crank_mount_y, drum_axle_z])
        rotate([0, crank_angle, 0])
            translate([-crank_pivot_x, 0, -crank_pivot_z])
                crank_assembly();

    // v37 Thread twister (v51 HOLLOW: ring + 2 rod bobbin holders
    // orbit the tape axis just east of the plow, binding each seed
    // into the folded pocket; side friction drive, 6x at the
    // layshaft, viewer kinematic -3x about X).
    translate([bind_x, chassis_width/2, twister_axle_z])
        rotate([twister_angle, 0, 0])
            thread_twister();

    // v37 Vertical-nip pull pair (spacing driver), v39 CUSHIONED:
    // two vertical-axis rollers stand on the base flanking the finished
    // folded tape at pull_x (side-mounted: top bridge from the chassis
    // walls caps the axles), pinching the closed pocket and pulling it
    // at the same surface speed as the main roller (v52 d15 at 4/3 spin, spacing
    // preserved). Soft rubber/silicone sleeve grips without crushing.
    translate([pull_x, chassis_width/2 - vpull_off, base_thick + 15])
        rotate([0, 0, pull_a_angle])
            vpull_roller();
    translate([pull_x, chassis_width/2 + vpull_off, base_thick + 15])
        rotate([0, 0, pull_b_angle])
            vpull_roller();

    // v37 Take-up spool (wind-up reel east, BOTTOM mounted), v40 SLIP
    // CLUTCH: reel built along Z is recentred, tilted to axle-Y, spun
    // about its axle by takeup_angle (core d10 step-up winds the same
    // linear tape the pull nip delivers; clutch discs slip when full).
    // v87 +15 lift: takeup_z=49 (axis rod follows)
    translate([takeup_x, chassis_width/2, takeup_z])
        rotate([90, 0, 0])
            rotate([0, 0, takeup_angle])
                translate([0, 0, -takeup_h_total/2])
                    takeup_reel();
}

module assemble_all() {
    animated_assembly();
}

// ============================================================
// Diagnostics + part selection (fail-loud else)
// ============================================================
echo(str("v14 MVP: cavities=", num_divots, " roller_dia=", roller_dia,
         " gears=", roller_teeth, "/", drum_teeth,
         " tape/drum_rev(via roller)=", tape_per_drum_rev_roller,
         " spacing(6 cav)=", achieved_spacing,
         " target_spacing=", target_spacing));
echo(str("GEAR CALC: spacing = PI * roller_dia * (drum_teeth/roller_teeth) / cavities = ",
         PI * roller_dia * (drum_teeth / roller_teeth) / num_divots,
         "mm; target 152.4 (6 inch) needs future swap-gears (see GEAR_RATIO.md)."));
if (num_divots == 6) {
    echo(str("NOTE: v14 MVP fixed 6 cavities; wheels interchangeable by hand 1-6mm (cavity size varies, count stays 6)."));
}

if (part_to_render == "all") {
    assemble_all();
} else if (part_to_render == "chassis") {
    translate([0, 0, 15]) chassis(); // feet z=-15 → min_z=0
} else if (part_to_render == "hopper") {
    // v33 printable: standalone export drops to print base min_z=0
    // (local hover-pipe bottom 19.4 -> 0; was 19.9/25.9/26.5);
    // assembly branch above unaffected.
    translate([0, 0, -19.4]) hopper_body();
} else if (part_to_render == "cartridge") {
    seed_cartridge(seed_dia, seed_depth);
} else if (part_to_render == "cones") {
    spool_cones();
} else if (part_to_render == "plow" || part_to_render == "turner") {
    six_turner(); // v39: "plow" kept as compat alias, "turner" is the clean name (same 6-turner GLB)
} else if (part_to_render == "tape") {
    seed_tape_bend();
} else if (part_to_render == "rollers") {
    pull_rollers();
} else if (part_to_render == "twister") {
    // Export pose: translate only (no bobbin-down rotate; bobbins not rendered)
    translate([0, 0, tw_lift]) thread_twister();
} else if (part_to_render == "twister_axle") {
    // Static axle (absolute coords, no transform needed for export).
    twister_axle();
} else if (part_to_render == "pull_a") {
    vpull_roller(); // base at z=0 already
} else if (part_to_render == "pull_b") {
    vpull_roller(); // base at z=0 already
} else if (part_to_render == "takeup") {
    takeup_reel(); // built along Z, base at z=0 already
} else if (part_to_render == "crank") {
    crank_assembly();
} else {
    echo(str("ERROR: unknown part_to_render='", part_to_render, "'."));
    cube([1,1,1]);
}
