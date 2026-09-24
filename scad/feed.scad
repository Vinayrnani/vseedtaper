// v121 Step 7: single_cone/spool_cones deleted with the cones (no callers remain).

// Step 5: separate 10mm U-bend guide. It is attached to the hopper exit
// pipe by its two side cheeks and presses downward above the plain tape.
module u_bend_guide() {
    guide_length = 10;
    guide_press_t = 2;
    guide_rail_w = 2;
    guide_pipe_r = 5;
    guide_rail_inner = guide_pipe_r;
    guide_bore_r = 3.8;
    guide_tape_top_local = tape_z + tape_thick - (drum_axle_z - hopper_axis_z);
    guide_press_z = guide_tape_top_local + tolerance;
    guide_pipe_bottom_local = guide_tape_top_local + 10;
    guide_rail_top = guide_pipe_bottom_local + 2;
    assert(guide_length == 10, "u_bend_guide: guide length must be 10mm");
    assert(guide_press_z - guide_tape_top_local >= tolerance, "u_bend_guide: press face must clear plain tape");
    assert(guide_press_z + guide_press_t < guide_pipe_bottom_local, "u_bend_guide: guide must stay below the pipe bore");
    assert(guide_rail_inner == guide_pipe_r, "u_bend_guide: cheeks must meet the pipe OD");
    assert(guide_bore_r == 3.8 && guide_rail_inner >= guide_bore_r + 1, "u_bend_guide: cheeks must keep the seed bore open");
    assert(guide_rail_top >= guide_pipe_bottom_local + 1, "u_bend_guide: cheeks must overlap the pipe lower wall");
    assert(guide_length == 2*guide_pipe_r, "u_bend_guide: guide must span the pipe station");
    union() {
        // Downward pressing face: its lower face is 0.3mm above the plain tape.
        translate([-guide_length/2, -guide_pipe_r, guide_press_z])
            cube([guide_length, 2*guide_pipe_r, guide_press_t]);
        // Side cheeks touch the pipe at y=+-5 and rise to its lower wall.
        for (s=[-1, 1])
            translate([-guide_length/2, s*guide_rail_inner, guide_press_z])
                cube([guide_length, guide_rail_w, guide_rail_top - guide_press_z]);
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
    drop_pipe_id = 7.6; drop_pipe_od = 10; drop_pipe_len = 10; drop_gap = 10;
    throat_cx = 0;                       // v35: funnel throat centre (local X)
    entry_flare_leg = 0.6;               // v35: bore exit 45deg break leg (>=0.6)
    mouth_flare_leg = 0.8;               // v35: throat entry 45deg break leg (>=0.6)
    pipe_bot_local = tape_z + tape_thick + drop_gap - (drum_axle_z - hopper_axis_z); // 19.4 (v87: frozen hopper_axis_z=56 → drum offset 19)
    pipe_top_local = pipe_bot_local + drop_pipe_len; // 29.4
    tube_x0 = -5; tube_x1 = 5;
    bore_x0 = -3.8; bore_x1 = 3.8;
    tube_z0 = pipe_bot_local; tube_z1 = 52;
    assert(abs(pipe_bot_local - 19.4) < 0.001, "hopper_body: pipe_bot_local must stay 19.4 (export min_z offset)");
    assert(abs(drop_pipe_id - 7.6) < 0.001, "hopper_body: hover pipe ID must be 7.6 (thinnest wall)");
    assert(drop_pipe_od == 10, "hopper_body: hover pipe OD must be 10");
    assert(drop_pipe_len == 10, "hopper_body: hover pipe length must be 10");
    assert(abs((drop_pipe_od - drop_pipe_id)/2 - 1.2) < 0.001, "hopper_body: hover pipe wall must be 1.2 (thinnest printable)");
    assert(abs((bore_x1 - bore_x0) - 7.6) < 0.001, "hopper_body: drop bore must be 7.6");
    assert(tube_x1 - tube_x0 == 10, "hopper_body: drop tube outer must be 10");
    assert(abs((bore_x0 - tube_x0) - 1.2) < 0.001, "hopper_body: drop tube X wall must be 1.2");
    assert(throat_cx == drum_c[0], "hopper_body: funnel throat centre must equal drum drop point x (local 0 = world 100)");
    assert(entry_flare_leg >= 0.6, "hopper_body: bore exit lead-in leg must be >=0.6");
    assert(mouth_flare_leg >= 0.6, "hopper_body: funnel-mouth lead-in leg must be >=0.6");
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
        // v35 drop bore + tapered groove + 45deg lead-ins (no window box, no tape slots):
        // cylindrical ID7.6 bore through the hover pipe + tapered inner
        // cone (r4.6 -> r8, wide 16 -> 7.6 throat, ~8.6deg from vertical)
        // up through the funnel to the drum mouth (fed by the 6 cavities
        // over the top, not by the trough void). Drum carve trims the
        // funnel stub into a smooth drum-conforming mouth (only ~1 survives
        // above the pipe top; the rest is open mouth air by design).
        // Profile is monotonic (no radial step >0.3 anywhere, no overhang
        // in the seed travel direction). Two 45deg breaks: bore-exit flare
        // (r3.8->r4.4 over h0.6, 0.6 flat land left) kills the bottom sharp
        // inner rim; throat entry flare (r3.8->r4.6 over h0.8, leg 0.8>=0.6)
        // breaks the bore-to-cone edge into a self-clearing 45deg lead-in.
        // Pipe hovers 10 above the tape: no notches, no seal overlap.
        // Trough (HW 2.0, outer 7.8 < OD10) stays centred under the bore
        // (bore +-3.8, mouth 7 < ID7.6: seed lands INSIDE the
        // already-folded transit pocket below).
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
