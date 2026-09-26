/*
    Modular Hand-Cranked Seed Tape Machine - v2 Master
    ====================================================
    Thin master: all geometry lives in six included files.
    Includes (monolith order):
      scad/params.scad    — global variables, kinematics, assertions, helpers
      scad/gears.scad     — hex_hole, round_axle_hole, spur_gear, bevel_gear, hex_bolt, bearing_block
      scad/chassis.scad   — chassis(), south_wall()
      scad/feed.scad      — hopper_body, seed_cartridge, seed_cradle (v121: single_cone/spool_cones removed with the cones)
     scad/plow.scad      — scroll_sheet, six_turner, folding_plow
     scad/stations.scad  — knurled_roller, pull_rollers, thread_twister, takeup_reel, crank_assembly
     scad/drive_train.scad — v97 composite take-off (A[10+30] only)
*/

part_to_render = "all";
animate_assembly = true;

include <scad/params.scad>;
include <scad/gears.scad>;
include <scad/chassis.scad>;
include <scad/feed.scad>;
include <scad/plow.scad>;
include <scad/stations.scad>;
include <scad/drive_train.scad>;

// Step 13: one explicit rigid frame for the twister rotor.
// The axle uses the separate X-only reflection below; its Y/Z support frame
// remains unchanged.
module twister_rigid_frame() {
    translate([twister_frame_cx, twister_frame_cy, twister_frame_cz])
        rotate([0, 180, 0])
            translate([-twister_frame_cx, -twister_frame_cy, -twister_frame_cz])
                children();
}

// The axle is absolute-coordinate geometry. Reflect it in X only about the
// same x datum, preserving its Y/Z support frame and base connection.
module twister_axle_x_reflection() {
    translate([twister_frame_cx, 0, 0])
        mirror([1, 0, 0])
            translate([-twister_frame_cx, 0, 0])
                children();
}

module animated_assembly() {
    drum_angle = -360*$t + 4.5;  // v81: +4.5° half-pitch phase (40T drum) for tooth-into-gap mesh with crank 20T
    crank_angle = 720*$t;   // v79: crank 20T spins 2x drum (CW, meshes drum 40T)
    // v140: NO roller_angle here any more. There is no live drum-mesh phase
    // constant: the drum<->crank mesh phase is drum_angle's baked +4.5 above,
    // and gear_mesh_phase (params.scad) is documentation-only, referenced by
    // nothing. The crank<->A10 mesh phase is crank_mesh_phase (0, baked into
    // the printed crank gear in stations.scad) plus the A-side total
    // v140_A_tooth_phase / v97_A_phase below.
    twister_angle = twister_rev * crank_angle; // Step 3: -6x via the 1:1 mitre, opposite crank
    takeup_angle = -1440*$t;       // v48: tape-tension wind-up

    // Chassis with its removable south gear-mount wall
    chassis();
    south_wall();

    // Static axle uses the unchanged X-only reflection plus its axle-only west shift;
    // it is not in the rotor's 180Y frame.
    translate([twister_axle_x_shift, 0, 0])
        twister_axle_x_reflection() twister_axle();

    // v121 Step 7: spool cones removed (tape feeds from off-machine supply).
    // Spool rod in the chassis stays (mounts + bores untouched).

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

    // Step 6: the U-FORMER (u_former) is a SEPARATE printed part bolted to the
    // hopper brackets at world X 81..91 (hopper-local X -19..-9). It sits in the
    // hopper frame because it bolts to the hopper, not to the guide rails; the
    // rails only pass through its working channel.
    translate([drum_axle_x, chassis_width/2, drum_axle_z - hopper_axis_z])
        u_former();

    // Step 5: approved guide plus one right bracket and its Y mirror.
    translate(guide_assembly_t) u_guide();
    translate(guide_assembly_t) u_guide_bracket();
    translate(guide_assembly_t) mirror([0,1,0]) u_guide_bracket();

    // Seed cradle
    translate([plow_start, chassis_width/2 - 12.7, base_thick + 15])
        seed_cradle();

    // Seed tape with center U-fold (v34 OD10: narrow 4 trough,
    // R1.5, 5.5 walls, S-shoulders; v31: forming 37..70 fully west of
    // the drum face + plain straight transit 70..126 under the drum
    // (13.6 air gap) UNDER the hover pipe (10 gap) to the plow mouth;
    // static in CAD, scrolls in the viewer; single-layer floor, min_z=0).
    translate([tape_x0, chassis_width/2, tape_z])
        seed_tape_bend();

    // Folding plow (v39 REPLACED by the 6-turner/roller former: the
    // seeded tape rolls through the 6 curl east of the drop, world x
    // 126..159, v1-precedent footprint kept; seed lands flat at 100
    // first, then the curl rolls the edges over)
    translate([plow_start, chassis_width/2 - 20, base_thick])
        six_turner();

    // v79: rollers REMOVED; upper/lower roller lines deleted.

    // Crank drives from the fresh level station (160,75) on the r60 mesh circle:
    // 20T gear meshes drum 40T at dist=60. Front wall (Y=68), grip +Y
    // outward. Crank rotates 2x drum (720*$t).
    translate([crank_mount_x, crank_mount_y, crank_axle_z])
        rotate([0, crank_angle, 0])
            translate([-crank_pivot_x, 0, -crank_pivot_z])
                crank_assembly();

    // v97 composite take-off (user: revert gears, ONE composite 10->30):
    // crank20 -> A[10+30] (-2, Y). B at the fresh framed mitre apex (210.5, 32).
    // 15T idler bridges A30 -> B10 (same band 70-75); B -6x,
    // twister -6x via the 1:1 mitre (2.0 wraps/seed magnitude).
    translate([v97_Ax, v97_A_y0, v97_Az])
        rotate([0, A_rev * crank_angle + v97_A_phase, 0])
            dt_cluster_A();
    translate([v98_Bx, v98_B_y0, v98_Bz])
        rotate([0, 180, 0])
            rotate([0, B_rev * crank_angle, 0])
                dt_cluster_B();
    translate([v115_Ix, v115_I_y0, v115_Iz])
        rotate([0, I_rev * crank_angle + v115_I_phase, 0])
            dt_idler();

    // v37 Thread twister (v51 HOLLOW: ring + 2 rod bobbin holders
    // orbit the tape axis just east of the plow, binding each seed
    // into the folded pocket; v97: unpowered, static in preview
    // (composite take-off only, next stage TBD).
    twister_rigid_frame()
        translate([bind_x, chassis_width/2, twister_axle_z])
            rotate([twister_angle, 0, 0])
                thread_twister();

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
    chassis(); // flat base z=0
} else if (part_to_render == "south_wall") {
    south_wall(); // flat base z=0
} else if (part_to_render == "hopper") {
    // v33 printable: standalone export drops to print base min_z=0
    // (local hover-pipe bottom 19.4 -> 0; was 19.9/25.9/26.5);
    // assembly branch above unaffected.
    translate([0, 0, -hopper_export_rebase]) hopper_body();
} else if (part_to_render == "u_guide") {
    translate([0, 0, -guide_export_rebase]) u_guide();
} else if (part_to_render == "u_guide_bracket") {
    translate([0, 0, -bracket_export_rebase]) u_guide_bracket();
} else if (part_to_render == "u_former") {
    // u_former() self-rebases (min Z = 0) inside the module - no extra shift.
    //
    // STEP 6 (B4) PRINT ORIENTATION - WHICH ARTIFACT IS ROTATED, AND WHY:
    //   * This branch feeds BOTH artifacts: web/stl/u_former.glb (the viewer)
    //     and print/u_former.stl (the slicer), from one export. Only the
    //     PRINT one may be rotated: the die is a tunnel (a ~10mm unsupported
    //     roof over a 10x10x8 void) and must lie on its side to print without
    //     support, but the viewer places this GLB in the hopper frame with NO
    //     rotation, so rotating it here would put the die in the wrong place.
    //   * So the rotation lives in regenerate_glbs.sh, in the print_rot table
    //     that only the print/*.stl writer reads: "u_former": RX90 (rotate 90
    //     about X). That makes the print orientation REAL for the artifact the
    //     user slices, and leaves the viewer GLB byte-identical in pose.
    //   * feed.scad's PRINT ORIENTATION note points here. It is a comment plus
    //     a pipeline entry - neither is allowed to be the only thing standing
    //     between the die and a support-free print.
    u_former();
} else if (part_to_render == "cartridge") {
    seed_cartridge(seed_dia, seed_depth);
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
    // Bake the X-only axle reflection into the standalone GLB; the viewer applies
    // the same axle-only west shift at its root-level placement.
    twister_axle_x_reflection() twister_axle();
} else if (part_to_render == "takeup") {
    takeup_reel(); // built along Z, base at z=0 already
} else if (part_to_render == "crank") {
    crank_assembly();
} else if (part_to_render == "gear_A") {
    dt_cluster_A(); // local Y frame (viewer pivot compensates, print rotated flat)
} else if (part_to_render == "gear_B") {
    dt_cluster_B(); // local Y frame (viewer pivot compensates, print rotated flat)
} else if (part_to_render == "gear_I") {
    dt_idler(); // local Y frame (viewer pivot compensates, print rotated flat)
} else if (part_to_render == "gearwall") {
    dt_gearwall(); // absolute CAD coords (viewer: parent root, no offset)
} else {
    echo(str("ERROR: unknown part_to_render='", part_to_render, "'."));
    cube([1,1,1]);
}
