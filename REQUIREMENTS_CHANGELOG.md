# Requirements Change Log

## v38 — 2026-09-17
- Downstream respace (v37 overlap fix): bind 167->172, pull 181->194, take-up 186/28->226/34 (X gaps 9/8/6, centres 32 vs 26+0.3+5=31.3); chassis 214->262 (east 248), tape 220->270, 3 fail-loud gap asserts; viewer pivots/BIND/TAPE_LEN/comment, ASSET_V 24, GLBs rebuilt

## v37 — 2026-09-17
- Thread-bind + vertical pull + wind-up build (v36 spec): CAD thread_twister (167, 2 arms, 6 orbits/drum rev) + vpull pair (181, d20 1:1 spacing driver) + takeup_reel (186/28, core d10) + chassis blocks/posts + tape 220 + 4 part branches + geared assembly + fail-loud asserts + min_z=0; viewer pivots/PART_DEFS/synced animation + procedural thread helices + _twister hooks + tape path comment, ASSET_V 23, all GLBs rebuilt

## v36 — 2026-09-17
- Add thread-wrapping + vertical pull + wind-up to MVP (v15 spec backfill): 2 threads orbit tape after folding plow to bind each seed, vertical nip rollers pull finished tape at constant speed (spacing driver), take-up spool winds finished tape; all geared to drum 6 cavities for 6 inch spacing

## v35 — 2026-09-17
- Thinnest-wall pipe (user-confirmed): drop_pipe_id 6->7.6 (wall 2.0->1.2, OD10 fixed, assert ==1.2; bore +-3.8, X wall 1.2); inner cone r3->r3.8 (wide 16->7.6 throat, ~8.6° half-angle, steep); outer cone kept (wall 1.2->2.0); fold 4/R1.5/walls5.5 kept (outer 7.8<OD10, mouth 7<ID7.6, seed lands in pocket); entry inspection: trimesh proof (carve eats funnel above ~1 over pipe top = short stub into drum mouth, no hang; profile monotonic, no step; throat centred x=100/Y-centred, offset 0<0.5), sharp bore-end rims found catching → 45° lead-in flares (throat r3.8->4.6/h0.8, exit r3.8->4.4/h0.6, legs>=0.6); drop path clear ID7.6; ID7.6 still <8mm seeds (<=6mm only); viewer _dropSeal bore 7.6, ASSET_V 22

## v33 — 2026-09-17
- Option B drop-tape-lower (user-confirmed): tape_z 24->13 (ribbon top 13.4, flange-to-tape 20.1, disc gap 21.6, transit top 21.4); sealed tube replaced by hover round pipe ID10/OD14 L10 (world 23.4..33.4, gap 10, no seal/slots) + tapered groove wide 16->10 throat; shroud roof 34->23 (slot 6.45 kept); hopper child +19.4, TAPE_Z 13, _dropSeal 23.4/13.4, ASSET_V 20

## v32 — 2026-09-17
- Viewer displacement audit fix (CAD untouched): hopper child +25.9->+19.9 (floated +6: tube 29.9 vs 23.9, 5.7 spill gap, cover eccentric to drum; now 0.5 seal overlap, coaxial), tape mesh +0.2 Y (ribbon top 24.4 exact); drum/roller/crank/shroud/fold/transit/plow/spool verified undisplaced; ASSET_V 19, GLBs rebuilt, verify_v32.js proves live mesh placement

## v31 — 2026-09-17
- Fold-under-drum regression fix: forming 37..70 fully west of drum face (was 67..100 merged into wheel), straight full-U transit 70..126 through shroud slot under drum (1.6+ air gap) into drop-tube west inlet, bore to plow mouth; lane 30->24 (transit top 32.6 vs drum 35), tube re-sealed 23.9/24.4, bore 10/outer 14 kept, ASSET_V 18

## v29 — 2026-09-17
- Sealed drop tube (no spill): bore 9->10 (-5..5, 8mm clearance), outer 18->14 (-7..7, 2.0 walls), tube bottom 26.5->25.9 local (world 29.9, 0.5 overlap into ribbon top 30.4); E/W bottom-open tape notches (25.7..26.7) thread the flat ribbon at x=100 (fold lives 126..159), N/S walls seal full-height; drop window to bore 10, hopper export -25.9 (min_z=0, watertight), fail-loud asserts; viewer hopper child +25.9, dropSeed 31.5->30.4, _dropSeal hooks, ASSET_V 16, 13 GLBs rebuilt

## v28 — 2026-09-17
- Tape bend true mimic (tapeubend.png end-on): CAD R 3.0->1.75, fold 12.7->6.0 (HW 3.0), wall 2.0->5.5, N_ARC 12->20, new shoulder R1.5/60° S-kink + N_X 12 taper (0.15->1.0 W->E), double slab removed (single-layer floor), former collar shoe visual; stale v25 NOT-found comment fixed; viewer mirrors params, TAPE_LEN 320->180 unified, collar visual, ASSET_V 15

## v27 — 2026-09-16
- Final printable pass: chassis back bearing blocks fused (y_off, was floating), shroud flanges gain 4xM3 holes, upper roller zoffset 11->0 (min_z=0), hopper export -26.5 to base (viewer +26.5 Y recomp), cover groove 0.8->0.7 (wall >=1.2); tape 0.4 film exempt, cones/rollers sets vs watertight singles noted; viewer collapsible kept, ASSET_V 14, 13 GLBs rebuilt

## v26 — 2026-09-16
- Step 5 collapsible left panel (mobile): single hamburger/close toggle collapses entire panel (CSS slide, body.panel-collapsed); mobile <=768px defaults collapsed, canvas full-width; animation + part-toggle state preserved; localStorage persists choice; no CAD/GLB change (ASSET_V 13, vendored JS local, ?v= untouched)

## v25 — 2026-09-16
- Step 4 tape U-bend (tapeubend.png NOT found in repo//tmp, inferred center-fold): flat 25.4 ribbon + R3/90° U-fold channel (bottom 12.7, 12 facets/side, 2 walls) over plow zone 126..159 at z=30; CAD seed_tape_bend()+tape branch, viewer scrolling flat + static fold in tape toggle, _tapeFold bend proof, ASSET_V 13, 13 GLBs rebuilt

## v24 — 2026-09-16
- Step 3 R->L order proof: hopper (~128) > drum (100) > shroud (~71, 58-84 enclosed tunnel, wall 2.0>=1.2, min_z=0, no floating) > roller+crank (40); spool (-6) verified clear of r22 back gear (X gap 1.5, no move); viewer ASSET_V 12; all 12 GLBs rebuilt

## v23 — 2026-09-16
- Crank to back wall (Step 2 miss fix): crank_mount [40,68,60] front -> [40,-8,60] back (crank_mount_y=-8, crank_side=-1, grip mirrored -Y outward); lower-roller shaft front -> back outboard of pinion (through hex bore, mirrors vertical stack); gear stays back Y~12 + 9° phase; viewer crankMount -> (40,60,8), ASSET_V 11; crank/rollers GLBs rebuilt

## v22 — 2026-09-16
- R-to-L order step 3 of 3: shroud rewritten from legacy stub to parametric tape-cover tunnel west of drum (58-84, centroid ~71, top 34, d10 view ports, min_z=0); spool 10->-6 clears roller back gear (~4.5 real gap, 1.5 box-level), chassis extended west (-14..200, len 214); viewer shroud pivot + ASSET_V 10; all 12 GLBs rebuilt

## v21 — 2026-09-16
- Crank + roller to west side (step 2 of 3): roller_axle_x 160->40 (|100-40|=60 exact), crank coaxial with roller axle, roller pinion flipped to back side with 9° mesh phase (tooth-into-gap, rigid with lower+crank); plow fixed 33 long east of drum (126->159); viewer pivots to x=40, ASSET_V 9; known spool/gear graze left for later layout pass

## v20 — 2026-09-16
- Drum gear to back side (step 1 of 3): seed drum gear front (+18) -> back (-18, world Y~12), hub re-mirrored to stay fused, vertical export gear-down with raised drum; viewer cartridge mount recentered, ASSET_V 8

## v19 — 2026-09-16
- Hopper triangular-gap seal: GAP-A wedge through-slot (cheek/floor divergence x45-78) closed via deepened cheeks + wider/longer floor; GAP-B root-top sliver closed via root gussets to fin band; nose enlarged caps tip, kills coplanar seam; 24 intersection markers prove sealed, mouth/bore/void still open

## v18 — 2026-09-16
- Regen speedups + OpenSCAD upgrade: persistent Xvfb, binstl+q, persistent Python converts, dirty-only temp files; try OBS openscad-nightly (manifold) with loud fallback to 2021.01

## v17 — 2026-09-16
- Hopper mouth fixes (RED/BLUE/PINK): RED diagonal side pads deleted (crossed cavity sweep); BLUE arc side-closure fins r26.5-28.5 30-122deg fuse cheek roots (x14-24) to cover lip, mouth sides closed/middle open gap 1.0; PINK tip sealed watertight (floor to x84, 6-thick nose x78-84 foot 60, void ends x70, 2-wide tip blocks) — single watertight hopper solid

## v16 — 2026-09-16
- Closed bowl tip + sides-only joint (gap back to 1.0), drop plow outlet chamfer (code state before v17; requirements entry recorded retroactively)

## v15 — 2026-09-16
- Actual changes.jpg markups (image read directly, overrides v14 guess, no yellow present): blue drum/bracket interface fit (mouth gap 1.0->0.7, tab/joints widened to seat flush), red support-tab pivot relief (tab slimmed + lifted z66->68), pink tip/wall (apex knife-edged, floor 2.5->3.5, plow outlet chamfer)

## v14 — 2026-09-16
- changes.jpg markup: red blocking rib removed (seed path clear), blue side joints retained (shroud↔hopper support), pink gaps sealed (closed walls), yellow channel grooves matching drum for wheel-to-frame positioning (not seed drive)

## v13 — 2026-09-16
- Refine hopper to closed container, shroud to open 11-6 half-pipe 16mm/8mm, drum 6 cavities, matching grooves, joints

## v12 — 2026-09-16
- Bottom-center drop / 11-to-6 cover rebuild (overrides v11 tube side + cover clocking + wedge tilt): wedge top edge exactly horizontal (73→73); retention cover re-clocked 45..240°→120..270° (top lip 11 o'clock, bottom lip 6 o'clock at tube); drop tube moved left x=67→bottom-center x=100 (bore 7, 5mm guided drop, tape 35→30 under drum, carve-sculpted funnel mouth, no ribs); drum CCW + left crank r=45 unchanged.

## v11 — 2026-09-16
- Right-pickup / left-drop / left-crank rebuild (overrides v10 tube/crank sides): drop tube mirrored from right corner to LEFT (~9 o'clock, bore centre world x=67, fed by cavities via drop window through cover arc); crank moved from roller axle (x=160) to drum-axle left end direct-drive (x=77.5, CCW locked to drum); wedge pickup mouth gap 1.0 unchanged; hopper still one wrap-around object; drum CCW unchanged (picks right, carries over top, drops left).

## v10 — 2026-09-16
- Single wrap-around hopper (overrides v9 hopper/shroud split): shroud arc merged into hopper_body() as left retention cover (45..240°, wall 2, gap 1.5, fused at 1:30 step tab); right wedge + corner drop tube unchanged; separate shroud part removed from viewer (module/branch kept as legacy stub); mirror-check proves viewer not mirrored (wedge toward +X crank side); drum CCW, crank right L-handle r=45 preserved.

## v9 — 2026-09-16
- hopper2.jpg rebuild (overrides v8 hopper/shroud/drop): sharp-point side-view wedge hopper on right (upper wall ~horizontal from 1:30 step, lower floor +8° about 3-o'clock point to apex x=83, open-top trough between triangular cheeks); corner drop tube at 3-o'clock L-step (bore 7x15.6, bottom world z=38, fused into hopper_body, GLB names unchanged); shroud left-only C 45..240° (top squared lip mates hopper step at 1:30); dropSeed animation moved to tube exit (133, 38→35). Assumptions: left dashed crank circle is schematic — crank stays right (roller gear drive preserved); drop fused into hopper GLB (separate drop GLB not added, part names kept).

## v8 — 2026-09-16
- CCW drum + right hopper rebuild (overrides v7 direction/sides): drum anti-clockwise (top moves -X), crank/lower clockwise, upper idler CCW; hopper mirrored to +X right as open wedge (upper lip 1:30, lower lip 3 o'clock tilted up ~7°), mouth tangent gap 1.0; shroud mirrored to left (+60..+240°); bottom 6-o'clock drop; viewer rotation.z signs flipped; crank L-handle kept (r=45).

## v7 — 2026-09-16
- Hopper 10:30-11 rebuild (overrides v6): elongated open-top box trough top-left (-X, away from crank), no cone/chute/lid/joint; wide tangent mouth (~114-157°, gap 1.0) for direct cavity scooping; shroud same thin 180° shell minus tabs, clocked to -60..+120° (lip at 11 o'clock); no viewer transform changes.

## v6 — 2026-09-16
- Hopper/shroud sketch rebuild: open funnel + bottom taper chute (no lid/legs/wiper/drop-tube), 180-deg thin shroud (1.75 gap, no feet/bore), M3 flange joint at 3-o-clock; interfaces (part names, drum [100,60] R25 W15, tape path) unchanged.

## v5 — 2026-09-16
- Parts isolation panel: per-part checkbox + solo (chassis/hopper/shroud/cartridge/cones_a/cones_b/plow/rollers_lower/rollers_upper/crank + tape/seeds), All on/off, visibility-only toggles preserving crank radius 45 animation.

## v4 — 2026-09-16
- Fit-fix: all parts must land inside chassis interior in live preview (no dangling/empty chassis); transforms derived from animated_assembly() + GLB bounds; crank [0,45,0] orbit preserved.

## v3 — 2026-09-16
- Gear-mesh + crank-motion fix: applied Fix D, refined transforms, fixed static grip root cause, regenerated GLBs, verified grip radius 45.0 and all readouts.
