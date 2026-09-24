# CHANGELOG

Version-level changes only. Product requirements live in `REQUIREMENTS.md`.

Status: current entry committed after user APPROVE; older entries historical.

## v127 — 2026-09-24
- Docs/workflow (user APPROVE): AGENTS.md gained mandatory **Step-wise execution workflow** (ordered step queue, continuous chain after "Step N done", fresh-on-HEAD work, rollback+redo on wrong step, purge after each step, ≥3-angle visual review with object isolation, printability/watertight/min-gap gates). Skills section requires `code-philosophy` + `openscad` + `openscad-iterative-modeling` for step-wise CAD (receipt in first progress note). Project-local skills committed: `skills/` (code-philosophy, frontend-philosophy, openscad, openscad-iterative-modeling), `.agents/skills/openscad-iterative-modeling/`, `.opencode/skills/openscad-iterative-modeling/`, `skills-lock.json`. No CAD/GLB/viewer change, no ASSET_V bump. Local snapshot `web/v127/`.

## v124 — 2026-09-23
- Print-ready tooth clearance (user: teeth overlapped on the edges, no manual trimming): A10 was the only full-profile pinion meshing a full-profile gear (crank-A10 both 1.0, zero tangential clearance). Thinned A10 1.0->0.8 (v95 pinion precedent); crank stays full so the approved crank-drum mesh is untouched. Every mesh now has flank clearance: crank-A10 (A10 0.8), A30-idler (idler 0.8), idler-B10 (both 0.8), bevels (0.9/0.8 + asserted tooth-fit). Regen gear_A (forced, watertight TRUE), ASSET_V 87->88. Verify: echo asserts pass, verify_v123 PASSED 0 errors, crank-A10 closeups at 0deg + 2deg both daylight-both-flanks. $fn=60, tol=0.3 kept; no commit (awaiting approval).

## v123 — 2026-09-23
- Step 6 done (user: every gear meshes tooth-into-gap): audit closeups of all 4 meshes (crank-A10, A30-idler, idler-B10, Bbev-twister) — every one interleaves correctly, no tip clashes, no adjustments needed. verify_v123 PASSED, 0 errors. No CAD/GLB change, no ASSET_V bump. $fn=60, tol=0.3 kept.

## v122 — 2026-09-23
- Axle nose manifold rebuild (closes the v121 known issue): east-tip coplanar end-caps (tube/annulus/cap at x197) + stacked nose cylinders caused 219 non-manifold edges (histogram: 151 at the tip, nose itself clean). Fix: tube truncated to x193.5 with a single terminal face; annulus/groove/cap blocks deleted (spent old-snap features); collar inner embedded 0.1; nose rebuilt as one revolved annular profile. Regen twister_axle (forced) — watertight TRUE confirmed by trimesh. ASSET_V 86→87. Verify: echo asserts pass, verify_v118 PASSED (rebuilt nose closeups), 0 errors. $fn=60, tol=0.3 kept.

## v121 — 2026-09-23
- Step 7 done (user: remove Cone A and Cone B, not needed): spool cones out of the assembly + dispatch + viewer (PART_DEFS, ORDER, spoolGroup) + regen script (ALL_GLB, cone_a/b cases); single_cone/spool_cones modules deleted (no callers remain); retired cone GLBs + print STLs deleted (v97 precedent). Spool rod + mounts + params + asserts stay (tape path untouched, feeds from off-machine supply now). No GLB regen needed (deletions only). Verify: echo asserts pass, verify_v98 + verify_v116 PASSED, 0 errors. Known issue carried: twister_axle nose non-manifold (watertight warning on regen — stacked-cylinder joints; rotate_extrude rebuild queued). $fn=60, tol=0.3 kept.

## v120 — 2026-09-23
- Step 5 done (user: twister stays put in X, spins free): collar east 178→178.5 (west running clearance 0.5 to hub face 179); total axial play 1.0 (0.5 snap + 0.5 collar) enforced fail-loud with thrust-overlap assert; bore slip 0.6 kept for free spin. Regen twister_axle (forced), ASSET_V 85→86. Verify: echo asserts pass, axle closeups + verify_v98/v116 PASSED, 0 errors. $fn=60, tol=0.3 kept; no commit (steps continue).

## v119 — 2026-09-23
- Rotation direction fix (user: idler ran opposite Gear A): viewer B/idler signs were flipped by a stale "negated angles" comment — corrected to preserve CAD sign (crank/drum approved mesh proves the convention). Train now alternates correctly: A -2x / idler +4x / B -6x / twister +6x (verified numerically incl. signs). Viewer-only change (no CAD/GLB), no ASSET_V bump. Verify: verify_v98 PASSED with signed ratios, 0 errors. No commit (steps continue).

## v118 — 2026-09-23
- Step 3 done (user: snap-fit twister axle like the Essentra split-shank arrow nose): axle east tip rebuilt — old 3-finger array removed, 2-leg arrow nose (legs at ±Z, 3.5mm gap slots, r9 shoulder ring with west face at x184.5 catching the seated hub east face 184, ~20° lead-in ramp, ogive tip to r5.5, legs root into full tube at x190); old slots truncated to x183 (0.5 ligament to leg roots); plain OD15 tube continues to x197 as insertion guide; groove/cap kept (rotor passes clear). Fail-loud asserts (barb catch 1.2, shoulder clearance 0.5, gap ≥2.5). Regen twister_axle (forced, watertight), ASSET_V 84→85. Verify: echo asserts pass, verify_v118 PASSED (nose solo + assembled snap closeups, 0 errors). $fn=60, tol=0.3 kept; no commit (steps continue).

## v117 — 2026-09-23
- Step 2 done (user: extend outboard wall to support B; idler outboard; cut inboard stubs): wall plate lowered z40→26 + 2 new pillars + B bore re-added (wall carries A+idler+B, tips seated 2 deep); B shaft 45-76→54-80, idler 62-80→66-80, A 47-83→49.5-83 (functionless inboard tails cut). Fixed 2 defects the build surfaced: wall slip bores never cut the plate (wrong rotate sign since v108 — all three fixed together, why: a bore that misses its plate is a bug) + B hub floated into the idler gear (reseated on web). Idler outboard confirmed (tip in wall bore). Regen gear_A/gear_B/gear_I/gearwall (forced, watertight), ASSET_V 83→84. Verify: echo asserts pass, verify_v98 + verify_v116 PASSED, 0 errors. $fn=60, tol=0.3 kept; no commit (steps continue).

## v116 — 2026-09-23
- Step 2 done (user: connect A and B with an intermediate gear): 15T m1.25 idler at (154.30, 48.35) bridging A30↔B10 in the shared band 70-75 (two-circle solve, west solution; east hits the twister). Train now live: crank → A (-2x) → idler (+4x) → B (-6x) → twister (+6x mitre = 2.0 wraps/seed, range floor). Idler shaft y62-80 via front-wall + gearwall bores (wall gains idler bore, A-only→A+idler; B bore stays retired). Thin 0.8 teeth + 12° phase, both meshes visually interleaved. Fixed 1 stray-brace slip (fail-loud). Regen gear_I (new) + chassis + gearwall (forced, watertight), ASSET_V 82→83. Verify: echo asserts pass, verify_v98 PASSED (A-2/B+6/tw+6/0 errors), verify_v116 PASSED (idler mesh closeup, 0 errors). $fn=60, tol=0.3 kept; no commit (steps continue).

## v115 — 2026-09-23
- Rim mitre, same size both sides (user: twister rim OD, same teeth, 45°/45°): 36T m1.25 both (pitch r22.5, outer r23.75 ≈ disc OD46), apex (155,34,32); B at (155,32) with Bbev36 (heel y56.5), shaft y45-76, B10 idle; wall now A-only (B misses the plate until the intermediate); back-cone relief r20-23 trims heel backs. Fixed 2 stray-brace syntax slips + 1 heel-arithmetic assert (fail-loud caught both). Regen twister+gear_B+chassis+gearwall (forced, watertight), ASSET_V 81→82. Verify: echo asserts pass, verify_v115 PASSED (photo-style mesh, 0 errors), verify_v98 PASSED (B static/apex). Pair held static until the intermediate powers it. $fn=60, tol=0.3 kept; no commit (steps continue).

## v114 — 2026-09-23
- 24T rim mitre like the photo (user: more teeth, 45° like the image): twister bevel ring 20→24T m1.0 (heel r12 at the disc face x178.5, apex (166.5,34,32), toes solid over the bore — no more cantilever); Bbev matching 24T (heel y46, hub r7); back-cone relief trims heel backs like real bevels. B station + viewer pivot follow the apex (166.5, 32). Regen twister+gear_B+chassis (forced, watertight), ASSET_V 80→81. Verify: echo asserts pass, verify_v114 PASSED (mesh closeup photo-style interleave, 0 errors), verify_v98 PASSED (B static/apex). Pair held static until the intermediate powers it. $fn=60, tol=0.3 kept; no commit (steps continue).

## v113 — 2026-09-23
- B repositioned to mate the twister (user: mate is Gear B; photo-ref straight bevels): twister carries a photo-style bevel ring (20T m1.0, heel r10 at x177, face 3.5, teeth converging at shared apex (167,34,32), root frustum + back web, turbine-style cantilevered toes over the bore); B axis through the apex (167, 32) with apex-down Bbev20 (heel y44, hub r6, shaft y43-76 via the moved front-wall bore, B10 kept idle in the A30 band); A-mesh OPEN until the next-step intermediate. Shared bev_teeth() module (Tredgold, thin 0.9/0.8 backlash, 9° tooth-into-gap). Back-cone relief r9-13 in the disc face catches the B heel corner (mesh-mandated disc touch); side effect: bevel teeth (toe x174.5) fix the latent spur-teeth-vs-pedestal graze. Watertight (coplanar heel/web Embed fix). Regen twister+gear_B+chassis (forced), ASSET_V 79→80. Verify: echo asserts pass, verify_v113 PASSED (pivots exact, mesh closeup interleaved, 0 errors), verify_v98 PASSED (B now static/apex). Pair held static until the intermediate powers it. $fn=60, tol=0.3 kept; no commit (steps continue).

## v112 — 2026-09-23
- Step 1 done (user: proper spur teeth on the twister, same shape as normal/bevel gears): twister teeth rebuilt from the custom 3-section cube wedge to a true flat-flank trapezoid — 2D profile (root 3.8 / tip land 1.8, thickness at pitch = tooth_arc_frac) extruded axially, straight flanks like the spur_gear teeth. First attempt (hull-of-cylinders) rendered as rounded fingers on the tall-narrow twister teeth — rejected on preview, redone as flat polygon. Envelope unchanged (24T, root r18 / pitch r22.5 / tip r27, x172..179, backs fused into disc). New fail-loud asserts (tip land >=0.8 printable, pitch thickness = tooth_arc_frac). Regen twister (forced), ASSET_V 78→79. Verify: echo-export asserts pass, verify_v112 + verify_v98 PASSED, 0 errors, live preview. $fn=60, tol=0.3 kept; no commit (steps continue).

## v111 — 2026-09-23
- Step 8 done (user: A10 width must match the crank gear): A10 face 4 → 6mm, band 49-55 = exactly the crank plane (was 50.5-54.5); assert tightened to 6mm face. Closeup shows full-width teeth interleaved with the crank teeth. Regen gear_A (forced) + print, ASSET_V 77→78. Verify: verify_v98 PASSED, 0 errors. $fn=60, tol=0.3 kept; no commit.

## v110 — 2026-09-23
- Step-5 correction done (user: shafts must CROSS the outboard wall; cut inboard stubs): A shaft 44-80 → 47-83, B shaft 44-80 → 54-83 (tips ~2 proud outside the 78-81 wall); inboard stubs cut (A below A10, B below bevel, teeth still fused). Bevel lift re-derived absolute (web pinned 61.5-63.5 whatever the origin) after the origin move tripped the old relative assert — caught fail-loud, fixed same run. Viewer part offsets re-derived (pos z = 56 - y0: A 9, B 2) so local-frame parts land on true stations. Regen gear_A/gear_B (forced) + prints, ASSET_V 76→77. Verify: verify_v98 PASSED, closeup shows meshing stack + bare shafts, 0 errors. Step 7 also confirmed done (v109: full-profile A10 teeth interleave tooth-into-gap, no drift). $fn=60, tol=0.3 kept; no commit (steps continue).

## v109 — 2026-09-23
- Step 7 done (user: crank gear not meshing properly with A10): A10 teeth were thinned 20% (tooth_scale 0.8, anti-bind leftover) rattling in the mesh — now full standard profile like the crank gear. Tight closeup shows teeth interleaving tooth-into-gap with even flanks; ratios exact so the mesh can't drift through rotation. Regen gear_A (forced) + print, ASSET_V 75→76. Verify: verify_v98 PASSED, 0 errors. $fn=60, tol=0.3 kept; no commit (steps continue).

## v108 — 2026-09-23
- Step 5 done (user: extra outboard wall for the 30T/10T shafts): new standalone part gearwall — plate y78-81 (x132-192, z40-93) over both axes + 4 pillars (6x6, y67-80) fused into the front wall + d8.6 slip bores; A/B shafts extended to y80 (tips 2 deep in bores). Asserts: tips in bores, gears below plate, plate below arm, plate clears crank shaft, pillars clear A30 sweep, plate coverage, bore slip. New part_to_render branch + ALL_GLB/print_rot + viewer def/order + verify check. Regen gear_A/gear_B/gearwall (forced) + prints, ASSET_V 74→75. Verify: verify_v98 PASSED (gearwall meshes present, ratios exact, 0 errors); front closeup shows plate + pillars with gear teeth peeking over. $fn=60, tol=0.3 kept; no commit (steps continue).

## v107 — 2026-09-23
- Step 4b done (user: hub bump removed, bevel near wall, teeth kept nice): hub cylinder deleted — teeth + flat 2mm web only (shaft pierces the web, backs fuse into it); whole bevel rides up (lift 25.5): teeth 56-62, web top 63.5 (1.5 below wall inner 65). Teeth standard Tredgold form untouched, full thickness (mate gets backlash). Asserts updated (gap ≥5, reach, web-below-wall; hub param/assert retired). Gear file 112→107KB. Regen gear_B (forced) + print, ASSET_V 73→74. Verify: verify_v98 PASSED, closeup shows teeth + bare shaft below, no hub. Step 6 answered by action (thick hub gone; 2mm web is the minimum mount). $fn=60, tol=0.3 kept; no commit (steps continue).

## v106 — 2026-09-23
- Step 4a done (user: B straight under A for the twister spur): B_ang -15 → -90, B now (162.52, 50.29), CD 25.75 kept so A30↔B10 still mesh (direction now straight down). New asserts (B straight below A; bevel clears plow exit flare by y-separation ~2). Chassis bore follows params (regen forced) + print; pivotB + mounts + verify expectation updated. ASSET_V 72→73. Verify: verify_v98 PASSED (pivots, A -2, B +6 exact, 0 errors). $fn=60, tol=0.3 kept; no commit (steps continue).

## v105 — 2026-09-23
- Step 3 done (user: B10 outside the wall to mesh A30): B10 band 59-64 → 70-75 (shares the A30 band, mesh closed outside the wall); bevel↔B10 gap 1 → 12 bare shaft; B shaft 44-68 → 44-76 (tip waits for Step-5 wall). Asserts restored (band coplanarity) + new (B10 outside wall, shaft tip below arm sweep, gap ≥10, B10 clears crank shaft). Regen gear_B (forced) + print, ASSET_V 71→72. Verify: verify_v98 PASSED (A -2, B +6 exact, 0 errors). $fn=60, tol=0.3 kept; no commit (steps continue).

## v104 — 2026-09-23
- Step 2 done (user: A30 outside the chassis wall): A30 band 59-64 → 70-75 (2 clear of wall outer 68); A shaft 44-68 → 44-76 (carries A30, tip waits for Step-5 wall); A10 untouched on the crank plane. Stale inboard asserts updated (shaft-tip/arm-sweep envelope, Step-5 room reserve); B10 coplanarity assert relaxed to width-match until Step 3 re-meshes (mesh between steps is OPEN by plan). Regen gear_A (forced) + print, ASSET_V 70→71. Verify: verify_v98 PASSED, closeup shows A30 outboard. $fn=60, tol=0.3 kept; no commit (steps continue).

## v103 — 2026-09-23
- Step 1 done (user: bevel cone bulky, remove it): solid hub-taper + root cone deleted from dt_bevel_blank; the 20 standard teeth stay exactly as drawn, now hanging from a 2mm back flange (r10, catches every tooth back) tied to the r4 shaft by a short r6 hub — crown style, gullets stand open. New asserts (flange coverage, hub wall). Gear file shrank 117→112KB. Regen gear_B (forced) + print, ASSET_V 69→70. Verify: verify_v98 PASSED (A -2, B +6 exact, 0 errors), closeup shows open teeth + slim hub. $fn=60, tol=0.3 kept; no commit (steps continue).

## v102 — 2026-09-23
- Crank drive fix (user: shaft didn't touch the gear; handle too close to wall): hex shaft 28→58mm, runs arm boss → through front-wall hex hole → full through crank-gear hex bore (tip 1 proud inside, positive drive); arm/grip out 12 so the handle stands 20 off the wall (was 8); counterweight stub removed (floating puck, fused to nothing). Asserts: handle gap ≥20, shaft tip through gear bore. v102b: stub cut confirmed on solo screenshot. Regen crank + print, ASSET_V 68→69. Verify: verify_crank PASSED (mount, drum -0.5x, 0 errors). $fn=60, tol=0.3 kept; no commit (awaiting user orders).

## hopper rev6/rev7 — 2026-09-23
- Hopper rebuild (concurrent track, committed together per user order): rev6 asymmetric smooth taper — +Y/front stock-narrow full length (clears drum 40T gear disc), -Y/back tapers smoothly 7.8→24.5 with no step or seed-trap corners, floor keeps the stock 8° gravity ramp; rev7 carve-clear taper (no mouth slivers). Hull pairs share identical z-spans (planar faces, no twist); fail-loud asserts (taper past carve, floor/cheek containment, bowl wall ≥1.5, nose/wall/gear/cone clears). Mouth/drum interface unchanged. Regen hopper.glb, ASSET_V →63.

## v101 — 2026-09-23
- Standard-form bevel teeth + close coupling (user: blobs had no standard tooth shape; gap to B10 too big): teeth rebuilt Tredgold-style — the repo's own spur profile (trapezoidal flanks, flat tip land, sunk root, same $fn=12 facets) placed full-size on the back cone and hulled to its apex-scaled front copy, so every flank converges at one apex like a real cut bevel; root cone through the same apex gives uniform gullet depth. Bevel bands 44-52 → 50-58 (1mm under B10, was 7mm bare shaft); asserts added (coupling gap, teeth-on-shaft reach) and rebounded (tip r11). Regen gear_B (forced), ASSET_V 66→67. Verify: verify_v98 PASSED, closeup shows true standard teeth matching the spurs. $fn=60, tol=0.3 kept; no commit (awaiting user orders).

## v100 — 2026-09-23
- Smooth round bevel teeth (user: v99 teeth had sharp edges unlike real bevels): each tooth rebuilt as a hull of 8 spheres — tapered prism on the 45° pitch cone with EVERY edge rounded (rounded flanks + tip, fillet-like root), matching the smooth look of the spur gears; same bands/position/clearances, still manifold + printable. Regen gear_B (forced), ASSET_V 65→66. Verify: verify_v98 PASSED, closeup shows smooth professional teeth. $fn=60 (spheres $fn=24), tol=0.3 kept; no commit (awaiting user orders).

## v99 — 2026-09-23
- Professional bevel teeth on Bbev20 (user: old tilted blocks looked amateur): true straight-bevel teeth — tapered prisms lying on the 45° pitch cone, full profile at the back cone shrinking toward the common apex, half-pitch thick minus print clearance; root blank rebuilt as hub taper + tooth-cone so teeth sink in everywhere (manifold, printable). Same interface/bands/position (asserts + teeth-top clear added). Regen gear_B (forced — cache skipped the content change), ASSET_V 64→65. Verify: verify_v98 PASSED, closeup shows clean conical mesh-ready gear. $fn=60, tol=0.3 kept; no commit (awaiting user orders).

## v98 — 2026-09-23
- Second composite under A per user: B[10+bev20] on the crank-gear wall (B10 m1.25 meshes A30 in the same 59-64 band, +6x; fused Bbev20 m1.0 foot below at 44-52 as takeoff for the next stage). B on r25.75 about A at -15° up-east (187.39,69.37, v95-proven clearances); front-wall bore added. Fail-loud asserts (A->B mesh CD, band coplanarity, shaft span, B-shaft/A30 + bevel/A10 true-distances, teeth/pin sweeps, crank-gear/nip/wall-bore clears). Viewer pivotB + exact +6x spin; regen gear_B + chassis; retired nothing. Verify: verify_v98 PASSED (pivots exact, A -2.000, B +6.000, tw 0, drum -0.5, 0 errors). $fn=60, tol=0.3 kept; no commit (awaiting user orders).

## v97 — 2026-09-23
- Gear revert per user (collision in v96 train): stripped corner/Bw/Be/Cpin/C/bars/pedestal; kept ONE composite A[10+30] on the crank-gear wall (crank20 → A10 m2 + fused A30 m1.25 takeoff, -2x, A on r30.75 at -70° down-east so the 30T clears the hopper radially). Twister unpowered/static in preview and CAD animation (next stage TBD). Restored v95-proven A geometry (shaft y44-68, A10 50.5-54.5, A30 59-64, front-wall bore); fail-loud asserts (mesh CD, bands, hopper/wall/nip/wall-bore). Viewer single pivot + exact -2x spin, twister 0x; retired Bw/Be/C/bar GLBs + print STLs deleted; regen list back to gear_A only. Verify: verify_v97 PASSED (pivot exact, A -2.000, tw 0, drum -0.5, 0 errors). $fn=60, tol=0.3 kept; no commit (awaiting user orders).

## v96 — 2026-09-23
- Parallel-plane drive rebuild (overrides v95 train): crank20 → A[10+abev15] (-2x, Y) → TRUE-apex mitre corner (1.25x) → B-west[15] + B-east[bev12] split pair (+2.5x, X, same speed — the A shaft crosses the B line at x148-156 so one solid B shaft cannot pass; caught by fail-loud assert, both pieces bar-supported) → C[12+Cpin10 deep-gullet] (-3.125x, C solved two-circle at (49.92,60.48)) → wedge24 spur finish → twister +7.5x = 2.5 wraps/seed. Retired: v95 idler/D/friction-tire/pedestal (no T-ring, no friction; twister untouched). Wall-to-wall bars bar1 (Bw+C) + barM (Be) + barE (C, C east end exposed for future puller take-off). Parts: A/Bw/Be/C + 3 bars, each own STL + preview toggle; print/ set refreshed, stale v95 gear_B/D/I/tire artifacts deleted. Viewer 4 pivots + exact spins (probe: -2/+2.5/+2.5/-3.125/+7.5, 0 errors), ASSET_V 61 (page now 62 via concurrent hopper rev6). $fn=60, tol=0.3 kept; no commit pre-APPROVE.

## v95 — 2026-09-22
- Twister powered from the hand crank at 2.5 wraps/seed (7.5x/crank, 3 seeds/crank rev unchanged): crank swung up to (152,104.93) on the r60 mesh circle (mesh exact, drum/seed rate untouched); NEW from-crank train crank20 → A[10+30] (-2x) → B[10+bevel10] (+6x) → TRUE-apex mitre corner → C[bevel+15] (-6x) → idler[12+12] (+7.5x, user-approved fill-in) → D[12+r10 wheel] (-7.5x) → friction O-tire tangent to twister disc OD → twister +7.5x. Compounds FUSED per user (one STL per shaft, no press-fit); pinions T≤12 thinned 0.8 (anti-bind); wall-to-wall back rail (B/D/idler bores + B10 slot) + chassis-fused C-idler pedestal (tape-notched, pocket-clear). All positions solved in code, ~50 fail-loud asserts (mesh CDs, contact, product, revs, bands, boxes, radial sweeps). Parts: 7 new STLs (A/B/C/D/I clusters + tire + bar1), each own file + preview toggle; print/ set (25 STLs, oriented flat, min_z=0); viewer 5 pivots + exact spins (probe: -2/+6/-6/+7.5/-7.5/+7.5, 0 errors), ASSET_V 56→57. $fn=60, tol=0.3 kept.

## v93 — 2026-09-22
- Viewer plow/twister bore alignment: plowPivot (126,19,-14)→(126,4,-14), base-fused zero ground clearance (v87 +15 was double-counted — pivot and axis_z both carried it, exit rendered at 47 not 32); twisterPivot (184,29.5,-34)→(184,32,-34), rotor bore coaxial with axle bore. CAD unchanged (axis_z=28 + base 4 = 32 = twister_axle_z, asserts already enforce). No GLB regen, ASSET_V stays 56. Verify: verify_v88 PASSED, plow exit bore 32 = twister bore 32, 0 console errors. Snapshot web/v93/ (GLB only). $fn=60, tol=0.3 kept.

## v92 — 2026-09-22
- Strict no-repeat rule: never the same tool call/action more than 2 times (attempt once, change approach once, then stop + report). Added to AGENTS.md Gotchas+Workflow and subagent-discipline.md. All prior v91 rules kept; no commit pre-APPROVE.

## v91 — 2026-09-22
- Agent instruction updates: plan via `plan` agent (not general); delivery flow max 2 verify/fix loops; fix loop max 2; remove vision-only screenshot rule from subagent-discipline.md; single-object isolation gotcha (no touching other objects without user permission + why). $fn=60, tol=0.3 kept; no commit pre-APPROVE.

## v90 — 2026-09-22
- Drum+crank gear restore: uncomment feed 316-322+360-364, stations 552-555; gear_local_y -24→-16, coplanarity <0.5, Y/Z clearance asserts; regen cartridge+crank; ASSET_V 53→55; viewer text revert; verify_v90 side+front; snapshot web/v90/ (GLB only). $fn=60, tol=0.3 kept; no commit pre-APPROVE.

## v89 — 2026-09-22
- OpenSCAD nightly-only hardening: regenerate_glbs.sh drops 2021.01/Xvfb fallback (requires openscad-nightly, manifold headless, fail loud); skill common.sh find_openscad/check_openscad nightly-only (macOS brew paths removed); SKILL.md prerequisites → nightly install; AGENTS.md Commands+Gotchas updated; REQUIREMENTS Project Location → nightly fact. $fn=60, tol=0.3 kept; no commit pre-APPROVE.

## v88 — 2026-09-22
- Twister + twister axle at least 10mm edge-to-edge east of plow, move adjacents, extend chassis if needed: plow exit (x=159) to twister teeth/mouth (currently 160, 1mm gap) and pedestal/hub must be >=10mm gap; twister station (bind_x), pull, takeup shift east to preserve gaps; chassis_len extend east + twister slot / pull bridge / mount holes follow; asserts updated (tw_mouth_x-plow_end 0.5-2 -> >=10). $fn=60, tol=0.3 kept.

## v87 — 2026-09-22
- Rotor teeth revert: v86 module-2 gear profile back to v85 wedge profile (24 trapezoidal, base 2.6/tip 1.6/depth 7/flank 45/taper 15) in local fused frame (x -12..-5); reason: v86 teeth built in absolute frame floated detached. KEEP: v86 axle rim OD20, axis fix (pivot/BIND_Y 14.5), arrow pins. Frozen: R19/disc r23/OD15/bore10/lane_y/hub r7.8+lip, drum/crank/tape untouched. Verify: manifold+asserts, regen twister, ASSET_V bump, pool screenshots, 0 errors, no code commit pre-APPROVE.

## v86 — 2026-09-22
- Axle mouth solid: bore Ø10 open; tube OD15 x160..184.5 frozen; NEW rim ring x184..187 OD20 (r10) 3mm axial, wall r5..r10, bore-entry chamfer 45°x1.5mm; slots 1.5mm shortened x176..183; lock lip re-cut on rim ID (depth 1mm/width 1.5mm); assert hub ends ≤184. True bevel teeth: module 2, Z=24, PA 20°, pitch r24, cone 45° (1:1 90° future mate), face 7mm, backlash 0.2mm/flank, tip ≥0.8mm, no undercuts, x160..167 root r18 tip r27, clear disc r23 / sweep R32.4 (axial gap asserted). Frozen: R19/disc r23/OD15/bore10/lane_y/hub r7.8+lip, drum/crank/tape untouched. Verify: manifold+asserts, regen twister+axle, ASSET_V bump, pool screenshots, 0 errors, no code commit pre-APPROVE.

## v85 — 2026-09-22
- Twister clean-sheet rebuild: bobbin pins OD6 shaft, visible slot >=2.5mm full length, 45°-chamfered arrow tip OD9-10 (NO true undercuts — FDM printable), twin-prong push-lock like reference photo. Teeth: true bevel profile, trapezoid + angled flanks + back-to-front taper, 18-24T, features >=0.8mm, printable. Axle mouth: full-wall ring, 3 uniform 1.5mm slots, bold barb r9, full annulus face. AXIS FIX: rotor spin axis coaxial with axle tube axis (remove off-axis mount; measured fault rotor world [74.5,19.4,17.8] vs axle [71.5,14.5,21.0]). UNCHANGED: R19 orbit, disc r23, OD15/bore10, lane_y=34, hub bore r7.8+lip, -3x crank drive, tape path.

## v84 — 2026-09-21
- Twister corrections (final numbers): teeth → disc back/west face x166..167 (1 thick, via bevel_gear() 24T M1.5, NON-MESHING placeholder); pedestal shifts x158..162 (mouth 160 inside pedestal zone, fused-base-by-design; 4mm clear of teeth and slot). Bobbin SOLID visuals DELETED (pins + collet lips only); tw_lift 29.5→23.5 (rendered sweep = disc r23; assert tw_lift>=tw_disc_r+0.5); viewer twister pos [0,-23.5,0]; physical Class-15 sweep asserts (R19/orbit/slot/feet) KEPT, marked physical-not-rendered; bob_d/bob_h params kept for asserts. Shroud REMOVED entirely (module + params + assembly + dispatch + regen + viewer + GLB file; snapshots frozen). Snap: 3 fingers @120°, 4 wide, 1.2 thick, x182..185, 1×45° lead-in chamfer + 0.8 barb/30° undercut; gaps pin-tip→snap 2 (≥2), bobbin→snap 0.9 (≥0.5 explicit), snap→pull 1.35 (≥1 explicit), barb-outer 9.5 vs eyelet-inner 11 (≥1). Eyelets: R13, r2 posts x170..185, Ø2 cross-hole near tip (~183); tip-vs-pull 1.35 (≥1 explicit). Plow: NO CAD shift (viewer pivot fix verified good by user); mouth gap stays 1 (assert [0.5,2]). ASSET_V 46→47.

## v83 — 2026-09-21
- Twister redesign spec: static hollow axle (10mm bore, OD 15, tube x160..184, funnel mouth gap 0.5–2 from plow exit x159; west pedestal x162..166 from z0 fused to base; 3 east snap-hook fingers 4/1.6/6, slots 1.2, lip 0.8; twister slides on from east, push-locks). Spinning twister, ratio unchanged (hub bore 15.6 slip-fit; disc r14 x167..171; back-face bevel-tooth BLANK, 24T M1.5 envelope reserved, real mesh later; 2 spindle pins Ø6/hole 6.6 at orbit R10 parallel-X 180° apart; 2 real Class-15 bobbins Ø20.7×11.1 split-collet snap lips; 2 simple thread-guide eyelet posts, tension by wrap angle). Base through-slot x166..183 y8..52 + 4 corner feet 10×10 to z=-8 (bobbin dip clears ≥2); chassis export +8 lift for min_z=0, viewer pivot compensates -8. Overhead drive gears REMOVED from chassis (clean; shape first, gear chain later; no drive source in CAD, documented). Fail-loud asserts every stack-up; $fn=60, tol=0.3; never v1/web-backup. Verify: 0 render errors, viewer ready + 0 console errors + animation + tape-static + bore-open + axle-static, screenshots; reviewer PASS; web/v83 snapshot.
- Corrections (review round 2, all verified): pedestal x161..165 (was 162..166) → 1.0 clearance to slot west edge (166), assert ≥0.5; disc-vs-pedestal rotating gap 2 (165→167) with assert. New rotor lift: disc r14 → min_z=-14 → tw_lift=14 explicit in params, replaces twister_lift (=12) in twister dispatch; viewer twister pos [0,-12,0]→[0,-14,0]; old twister_ring_r/_tube params deleted. Old cradle stubs (chassis.scad ~L173-175, twister_post_h-based) explicitly DELETED with drive removal (inside new tube zone). Chassis viewer pivot: NO change (stays [0,0,0]) — +8 CAD export lift already yields min_z=0 GLB; earlier "-8 pivot" note wrong, withdrawn. twister_arms param KEPT (=2, now counts bobbin spindles); both asserts kept. Bevel-blank envelope: 24T M1.5 visual-only teeth on disc west face, annular r8..13.5, thickness 3 (x164..167). Eyelets: 2 posts r1.5 h6 at orbit R6, 90°/270° (offset from spindles), x171..177, each Ø2 through-hole across top. Snap fingers x182..184 overhang slot east edge (183) by 1mm in X but at z~17 vs slot z0..4 — no interference, no assert (documented).
- Corrections (review round 3): tw_lift 14→20.5 (rotor sweep = orbit 10 + bobbin r 10.35 = 20.35, disc r14 smaller; export min_z=0, assert tw_lift >= tw_orbit + bob_d/2; viewer twister pos [0,-20.5,0]). Assert delete range corrected: DELETE params L473-484 + L489-537; KEEP L485-488 (crank/drum gear-plane checks, unrelated to drive removal). Slot cutout in chassis DIFFERENCE block at ex-drop-pocket site (not union); epsilon spelling. Drop-pocket param line L434 (was miscited L435). Stale stations L362 comment ("overhead-drive parity") deleted in twister rewrite. Hub/pin/eyelet X-layout (collision fixes): hub r10 x167..172 (bearing, 2mm from pedestal); disc r14 x167..170 (t3); pins R10 x170..179.5 (bases fused in disc/hub overlap, free east of x172); bobbins x169.5..180.6; eyelets R6 x170..176 r1.5 (bases fused, free posts east of x172); snap x182..184; new asserts hub-vs-pedestal ≥2, pin-tip-vs-snap ≥2, bobbin-vs-snap ≥1; eyelet-vs-tube overlap fused-base-by-design (documented, no assert). Bevel blank stays NON-MESHING visual placeholder (never inherited as gear math).
- Corrections (review round 4 — bigger bay): fundamental catch — Class-15 bobbin (r10.35) around Ø15 tube needs orbit R≥18.15 → R19 (bobbin inner clears tube by 1.15); small-orbit plans WITHDRAWN (R10/R11 would embed bobbins AND pins in the tube). chassis_width 60→68, lane_y=34 (new param) replaces hardcoded y=30 for all centered geometry; back wall stays 0..3, front wall moves to 65..68; back-plane gear y=12 unchanged. Twister final: tube OD15/bore10; R19; disc r23 x167..170 t3; pins R19 Ø6 x170..179.5; bobbins x169.5..180.6; eyelets R12 x170..176 r1.5 (90°/270°); snap x182..184; X stack-up otherwise unchanged (mouth 160 … pull face 186.35). Sweep outer 29.35 → tw_lift=29.5 (min_z +0.15), viewer twister pos [0,-29.5,0]; slot x166..183 y7..61 through base; feet 12×12 to z=-15 (dip -12.35, clearance 2.65); chassis export +15 lift; bevel blank annulus r16..22 visual-only. Viewer: CAD-y-derived positions shift +4 (viewer_y = CAD_y - 13); ASSET_V 45→46. Absolute-Y audit (grep every hardcoded 30/60/58/57) is part of implementation; gear-train-later plan unchanged.
- Corrections (review round 5): dead-axle shafts drum/takeup/spool *_y1 59→67 + asserts 58..60→66..68 (front wall 65..68); overhead countershaft y1 dies with drive deletion — no shift. Overhead 45.5 items need NO shift — entire overhead section (params/asserts/geometry incl. friction tangency + hanger posts) deleted; deletion list covers them. Front gear mesh preserved: gear_local_y -20→-24 (crank gear 56→52 vs drum 51.95) + assert windows 44..52 re-centered; crank/drum gears STAY (core drive). Plow mount holes py [6,54]→[6,62]. Disc-top assert margin <= 41 (was exact 40). Chassis viewer re-seat: PART_DEF pos [0,0,0]→[0,-15,0] (export +15 lift, viewer compensates; hopper precedent). twister_lift DELETED, tw_lift=29.5 NEW (rename, not alias); withdrawal reworded: R10/R11 withdrawn on bobbin-vs-tube (pins at R11 do clear). Audit grep widened: 59, 54, gear_local_y, shaft_y1, plow-hole literals (plus confirm-zero for deleted overhead/rod/ring symbols).

## v82 — 2026-09-21
- SCAD modular split (behavior-preserving): seed_tape_machine_v2.scad (~2407 lines, 29 modules, zero include/use) into 7 files — scad/params.scad (vars+asserts), scad/gears.scad, scad/chassis.scad, scad/feed.scad, scad/plow.scad, scad/stations.scad, with seed_tape_machine_v2.scad kept as master (part_to_render + assembly + dispatch + includes). Render output guaranteed identical (STL hash proof before/after). Overhead-drive identifiers renamed to plain words (old version-stamped labels removed from code). Twister redesign parked until split is proven unbroken. No geometry change, no viewer change, no ASSET_V bump.

## v81 — 2026-09-21
- Step B (amended): BOTH gears on CRANK/front-wall side — drum 40T stays/moves to FRONT plane (+gear_off, world y≈47.95); crank real 20T sits NEAR THE HANDLE at front plane (world y≈45..51, local y≈-20, hub +Y toward arm) on SHORT hex shaft (hex_shaft_len back to 28, shaft stays centered at arm); NO long through-chassis shaft. Drum still counter-rotates (drum_angle=-360*$t vs crank +720*$t, external mesh, 0.5×). Twister/viewer signs from v81 stand (DRUM_RATIO -0.5, viewer twister -3×). Cartridge EXPORT branch aligned to same front plane (currently builds gear at bottom/back — move to match). Regen crank + cartridge ONLY (chassis holes at x=160 already exist). Verify NoError/mesh (dist 60, y-spans coincide ≈45..51, x-interleave ~4mm)/gear-hub vs front-wall clearance/pivots ±0.15/ratios ±3% signs/0 console errors/animating close-up screenshots of front-side mesh. OUT: v53-train removal HOLD (back-plane counter now meshes air — accepted temporary state, forward ref), plow/shroud/split untouched. ASSET_V 43→44; header v79→v81.
- v81 fix (27cc865): cartridge export gear offset corrected +13.9mm
  (formula now drum_base+drum_len/2+gear_off, gear z 39.36, hub -Z);
  drum mesh phase +4.5° half-pitch in SCAD + viewer DRUM_PHASE;
  ASSET_V 44→45; mesh proven ΔX=60.0000/ΔY≈0/ΔZ≈-0.24,
  interleave 0.58mm, 0 console errors.

## v80 — 2026-09-21
- Step A: six_turner/plow restored verbatim from v66/v67/v68 (commit d1f2a09). Deleted HEAD parametric identifiers (st_x/st_R/st_W/st_H/n_st/fpx/fR/fW/fH/n_fp/plate_t/wall/hook_off/floor_local/curl_cz/curl_strip_pts). Restored scroll_sheet() (45×1.6, steps 35/35) and six_turner() (axis_z=13, mouth_x0=-12 → world 114, ears (132,6)/(153,54)). web/v66/stl/plow.glb proven faithful (4311 verts, bbox/volume identical to fresh d1f2a09 render). ASSET_V stays 43. Twister v53 overhead drive accepted-state (still present, meshing). Parked WIP: crank-20T + counter-rotation in /tmp/opencode/v80_gear_wip.patch.

## v79 — 2026-09-20
- Crank 20T meshes drum 40T at x=160 (center_distance=60), drum gear moved to front plane (+gear_off), rollers removed (upper deleted, lower replaced by crank axle through-shaft), shroud mirrored east (x 116..124, between drum 100 and six_turner 126), hopper stays as one unit. SCAD: crank_axle_x/z params, shroud_x0/x1 computed from drum_axle_x, crank_mount_x=crank_axle_x, pull_rollers() simplified, animated_assembly() crank at x=160. Viewer: crankMount (160,60,-68), shroudPivot (116,0,-30), lower/upper pivots removed, _setRotations + animation loop updated, PART_DEFS/ORDER pruned, ASSET_V 42→43. verify_v79.js PASSED (3 pivots ±0.15mm, 3 ratios ±3% with signs, ASSET_V=43, 0 console errors). 5 GLBs regenerated (chassis, hopper, shroud, cartridge, crank); stale roller GLBs deleted.

## v77 — 2026-09-20
- Twister "Lift all up" build (user: lift tape line, pinion TOP): tape carry line z 13→32, climb ~17→32 between turner exit x=159 and rotor x=176; pull bridge raised z≈49, takeup_z 34→32. Rotor disc centre (176,30,32), disc r22, bore Ø14.2; WEST-face crown 24T M1.5; TOP pinion 12T M1.5 axis Y ≈(176,30,59) mesh dist 27; 2× REAL Class-15 bobbins (Ø20.7×11.1) split-collet snap-fit at orbit 19, 180° apart, bottom z=13 clears base top z=4. Fixed hollow axle Ø10 bore/OD14 cantilevered off back wall, push-lock snap ring front; tape pocket (outer ~7.8) through axle bore. Gear chain target 15 = 4×3×2.5×0.5: drum 40T M2→10T M2→30T/10T M1.5→25T/10T M1.5→pinion 12T→crown 24T; spur stages axis-Y back plane y≈12; compound shaft stations solved in CAD w/ fail-loud cd asserts; chain west of x=165. v53 drive deleted (params/asserts/chassis/wall holes). Viewer ASSET_V 41→42, orbitsPerDrum 6→15, twisterPivot (176,32,−30), tape mesh z=32. Ratios 12-18 user range satisfied.

## v76 — 2026-09-20
- FULL REVERT to v57 configuration. Hollow overlapping-plate six_turner plow restored; v53 overhead gear drive restored (drum-coaxial spur 50T -> parallel counter spur 10T 5x -> Y-bevel 12T -> side X-pinion 10T 1.2x -> friction wheel on twister ring OD, 6.0x at the layshaft = 6 twister orbits per drum rev; drum_teeth 40 / roller_teeth 20; twister ring r10/tube2; ASSET_V 41). seed_tape_machine_v2.scad, web/index.html, regenerate_glbs.sh byte-identical to cffb536 (v57). All 17 v57 GLBs regenerated. v3 artifacts discarded (regenerate_glbs_v3.sh, .regen_cache_v3/, web/folder6_preview.html, web/stl/folder.glb, web/stl/layshaft.glb, "6 folder.stl"). Stale v75 gear GLBs removed (gear_drum, gear_pinion, gear_ring, gear_shaft_a-e, twister_bracket, twister_pinion, folder6_sample). verify_v57.js PASSED (V57_DONE, 5 screenshots); smoke check 0 console errors, orbitsPerDrum=6.

## v75 — 2026-09-19
- Step 4 full gear-driven chain: drum 44T → 5-stage compound spur train → 1:1 bevel miter → ring crown 16T, final total ratio 17.2032× drum (4×1.6³×1.4×1.0×0.75; user range 12-18 ✓; draft 12.288 dropped one 16/10 stage for 14/10). V53 friction/overhead drive surgically removed. Chassis widened 60→64, lengthened 262→278, base pocket slot x=165-181 y=3.5-56.5 z=0-4, ~14mm feet at corners, pull_x 194→196. Twister ring rebuilt: center (173,30,17), ring_r=18.5, tube=8→OD53, bore Ø21 (r10.5), X extent 165-181, Y 3.5-56.5, Z -10-44. Crown gear 16T M1.5 on WEST face, disc r10.5 (draft r14 deviation — bore-limited, clears tape tube), teeth FULL-HEIGHT fix (face_bevel_gear teeth_z/teeth_depth cf. partial teeth vanished under CGAL). Bobbins 2× Class-15 at 90° apart, orbit 16.25 (was 18), EAST face (x=181). Pinion shaft axis X: 12T bevels at (145,49.4,25.04) and (149.5,49.4,25.04), 1mm gap, mesh dist to ring ≈21mm. Gear train ALL axis-Y on back conduit z=32: drum44T M2→11T M2 (cd=55, shaft A 155,32,60), 16/10 ×3 (shafts B 135.5,32,59.79 / C 125.5,32,43.04 / D 145,32,43.04), 14/10 (shaft E 145,32,25.04), bevel E 12T Y→pinion 12T X→crown 0.75. Viewer ASSET_V 55→60, orbitsPerDrum 17.2032, 8 per-shaft pivots + applyGearRotations (A +4, B −6.4, C +10.24, D −16.384, E +22.94, pinion −22.94 rot.x, ring +17.2032 rot.x; gearDrum 1:1 rigid on drum), 8 gear PART_DEFs replace twister/twister_bracket/twister_pinion/gear_train (gear_drum hidden—cartridge renders 44T), rollers visible, web/stl/gear_train.glb deleted. verify_v75.js PASSED (8 pivots ±0.15mm, 7 ratios ±3% signs +,-,+,-,+,-,+, crown cone present, 0 console errors). Build commits: c56b1e5 docs, 56059a4 CAD, b1ed937 viewer/GLBs.

## v74 — 2026-09-19
- Step 3 twister redesign: enlarged ring (r10->15, bore Ø18 for 8mm folded tape, tube=6 wall>=2mm); bevel teeth on west face via bevel_gear() rotate([0,90,0]) full 360 about X (fixes previous rotate([90,0,0]) bug); 2x bobbin spindles 6mm dia x14mm at orbit r12 180deg apart + 2mm guide eyelets near bore; mating bevel pinion M1.5 12T vs 28T ring (~2.3x) at back plane y=12, axes intersect (bind_x,30,17); fail-loud mesh assert dist=r1+r2 ±(tol+0.01); twister_bracket() flat-on-base split-collar/slotted coaxial with scroll exit, 0.35mm clearances, min_z=0; twister_lift=23 (bevel OD margin); twister_orbits_per_drum updated to 18/7 (~2.57x drum); viewer ASSET_V 51->52, twister pivot/ratio updated; verify_v72.js

## v71 — 2026-09-18
- STEP 2 of step-by-step twister redesign (one piece at a time): ONE 11T M2 intermediate pinion at (155,12,60) meshing the 44T drum (cd 55 = (44+11)*2/2 exact, same y=12 plane); spins 4x drum, counter-rotates vs drum (external mesh physics); new twister_pinion_11t part + dispatch + mesh assert + assembly + animation; shaft deferred; viewer pinionPivot/PINION_RATIO 16/11/ASSET_V 51->52; collisions: hopper/tube/chassis clear, v53 counter+countershaft interference FOUND and deferred; STEP 2 ONLY, no further gears

## v70 — 2026-09-18
- STEP 1 of step-by-step twister redesign (one piece at a time): bigger drum gear 44T/roller pinion 16T M2 (pitch r44/r16, cd 60 exact, axles x=100/40 z=60 unchanged); gear_mesh_phase 9->11.25deg, crank 2x->2.75x drum (990*$t, senses kept); v53 step-up assert 6->6.6; viewer DRUM_RATIO 16/44, GEAR_PHASE PI/16, ASSET_V 50->51; NO new gears added

## v69 — 2026-09-18
- Orbital twister 24:1 IMPLEMENTATION (v67/v68 spec built for real): Green72 M1.5 on drum shaft (y44..50) -> layshaft 12T (163,62) -> 48T -> countershaft 12T (163,17) -> 20T/20T bevel (apex 163,30,17) -> twister_ring (bore 18, X axis 172,30,17); twister_bracket split-collar + layshaft_gears/countershaft parts; v53 overhead fully removed; orbits 6->24; viewer ASSET_V 51->52, verify_v69.js

## v68 — 2026-09-18
- Orbital twister 24:1 build (v67 spec): side spur train 72/12 48/12 M1.5 + 20T/20T bevel turn, ring on X 24x drum, twister_ring/bracket/layshaft/countershaft parts, v53 overhead removed, orbits 24, viewer ASSET_V 51, verify_v68.js

## v67 — 2026-09-18
- Orbital twister 24:1 train + 1:1 bevel turn (user: ring stays on X, 72/12 48/12 spurs M1.5 + 20T/20T bevel, 24x drum = 4 revs/seed, 8 wraps; 12T pinion can't surround 18mm bore so bevel stage required): new twister_ring/bracket/shafts, v53 overhead removed, orbits 24, viewer ASSET_V 51, verify_v67.js

## v66 — 2026-09-18
- Twister-aimed mounts (user: hanging in air, fix to chassis + exit facing twister): sheet axis 21->13 (exit bore dead on ring bore world (30,17), CAD-asserted), 2 floor pedestals + straps + 2 ears on chassis M3 holes; single shell (3556); flow re-probed; new down-the-bore align shot; viewer ASSET_V 50, verify_v66.js

## v65 — 2026-09-18
- Clear tape path (user: kept object in the middle obstructs tape flow): deleted the left tab (lay across the trench at the tape-wall lane); plow is the bare scroll_sheet, ONE shell (3011); tape-flow path ray-probed clear at 15 stations mouth->exit; solo mouth/top visual check clean; viewer ASSET_V 49, plow GLB rebuilt, verify_v65.js; open: part has no mount — user to say how it is held

## v64 — 2026-09-18
- Bare spiral plow (user: remove unnecessary objects in/arounds it; check single object from all angles): deleted all wrapper solids (pedestals/straps/ears/post/tray/nose) + the floating right tab (disjoint in every orientation, shell probe proved 2 shells); part is now ONE watertight shell (3210); solo 6-side visual check (mouth/exit/top/bottom/near/far) clean; viewer ASSET_V 48, plow GLB rebuilt, verify_v64.js

## v63 — 2026-09-18
- Exact spiral plow (user: v62 "didn't work well", use spiral code exactly as plow replacement): six_turner = scroll_sheet()/printable_folder() embedded byte-identical (0.5-turn R12 entry -> 1.25-turn R5.5 overlap exit, 45 long, 1.6 wall, user tabs; demo rotate line omitted; $fn=6/20 kept as documented exception) + placement wrapper (mouth world 114 telescoping over transit, exit exactly 159, axis 21) + 2 floor pedestals + straps/ears + tray/nose + tab post; fail-loud exact-use/placement asserts; viewer ASSET_V 47, plow GLB rebuilt, verify_v63.js

## v62 — 2026-09-18
- Tubular scroll folder (user-supplied scroll concept for 25.4mm tape -> 8mm tube): six_turner rebuilt as solid former block 28x33x20 with hull-lofted scroll tunnel (5 stages, open trench dia 25.4 -> shut tube dia 8, axis 14->13, hull on void only) + blind wick bore d4 from top (water-weld); fixed supplied snippet (capped ends -> plates poke past faces; chord roof blocking tall U walls -> open-sky trench); tray/nose/ears/straps kept, footprint world 126..159; fail-loud scroll asserts; viewer ASSET_V 46, plow GLB rebuilt, verify_v62.js

## v60 — 2026-09-17
- U-to-swirl forming plow (user: "6 = U bent transforming to swirl, tape folded round"): six_turner entry rebuilt as open U-channel (wrap 300->180, hook 20->0, no hook/rib at the mouth) winding along 33 to the tight 6-swirl exit (330 + hook 160, dia 9, 1.0 gap kept); 7 stations 180/210/240/270/300/320/330 + hook 0/30/60/90/120/145/160, 17 plates re-interpolated, entry-U/exit-swirl asserts; tray/skid/blade/ears untouched; viewer ASSET_V 44, plow GLB rebuilt

## v59 — 2026-09-17
- Photo-matched 6-folder: flat entry tongue/tray per Top.jpg (was missing in v58): six_turner gains 13.8x16x0.8 flat tray west of the large mouth (local x -14..-0.2, top flush with skid 3.0, 0.3 below bore, mortised into extended skid nose x0->-2, 0.2 clear of cradle, tip world 112 on chassis); v58 shell/hook/gap/ears untouched; viewer ASSET_V 43, plow GLB rebuilt

## v58 — 2026-09-17
- Big-to-small 6-turner (user direction reversal): entry BIG loose 6 dia 21 (R10.5, catches seeded 7.8 U-pocket, bore axis y20/z13 kept) -> exit SMALL tight curled 6 dia 9 (R4.5); 1.0mm daylight gap hook-to-shell full length (never touch); wall 0.8, hollow bore, open slit (wrap 300->330), skid 3.0->8.8 + re-seated side blade, ground-bar mounts via skid (bore-blocking posts deleted); fail-loud exit-dia/gap/taper asserts; viewer ASSET_V 42, plow GLB rebuilt

## v57 — 2026-09-17
- Hollow-loft fix, hull() filled the bore (user: thin-wall six_turner looked SOLID BLOCK + flipped): diagnosed via solo-plow screenshots + GLB volume ~8682 (convex hull of 300deg annular plates includes bore centre); six_turner loft rebuilt as overlapping plates with zero hull on shell/hook/rib (plate_t 1.2->2.2 > 1.925 pitch, 17 plates re-interpolated, union only) — hollow bore, open slit/ends; orientation verified correct with no swap (R grows x0->33 = world 126->159, rigid viewer rot, no mirror); viewer ASSET_V 41, plow GLB rebuilt

## v56 — 2026-09-17
- Thin-wall tapered 6-folder matching cardboard prototype (user: isolated views inaccurate vs Front/Back/Top.jpg, wall = minimum printable): six_turner rebuilt as thin-wall shell only (wall 0.8 single wall, no base plate) — 7-station loft x0..33 entry open-C dia ~12 -> exit flare dia ~21, outer wrap 300-315deg + inner hook to 160deg with 2.5 slit, tail blade + skid flat underside, hollow bore, 2 small 6x6x1 ears to chassis holes (132,6)/(153,54); turner_curl_cz 12->13; viewer relabel + ASSET_V 40, plow GLB rebuilt

## v55 — 2026-09-17
- Hollow 6, center fin deleted per Front/Back/Top.jpg (user: bore must be HOLLOW see-through, no center post): six_turner deletes center fin tongue hull (fin_t0/fin_t1), wedge nose top, root rails inside bore (blocked tape); keeps low flat base + outer side curl wings only (7 stations, left 30->270deg, right 20->180deg), bore hollow see-through full length, no geometry above floor_local in center 60% width except side wings (fail-loud center-probe + see-through asserts); base plate + 4 screw tabs, footprint world x126-159, $fn=60, tol=0.3 kept; viewer relabel + ASSET_V bump, plow GLB rebuilt

## v54 — 2026-09-17
- Asymmetric inner-curl 6-folder (user REJECTS outer pipe/shell again): tape arrives already bent U, inside that U one side wall curls IN deep, other side curls a little LESS, curls advance along length so paper edges roll together into overlapped roll; six_turner rebuilt as SEPARATE screw-mounted object (open base plate/blade + center fin tongue + two asymmetric curling wings, 6-7 stations x0..33, thin walls 1.2-1.6, lead-in chamfers, 2x M3 tabs at old plow holes, no ring, no bore); $fn=60, tol=0.3, manifold, asserts; tape visual only if trivial; viewer relabel + ASSET_V bump, plow GLB rebuilt

## v53 — 2026-09-17
- True 6-profile folder rebuild take 2 (user REJECTS v50 pipe-like closed tube): sample forensics for real (inches x25.4 = 28.0 x 23.6 x 31.9mm open wrap, tall lapping tongue, curled exit roll); six_turner diagnosis (full-ring shell loft + fused tongue = tube with slit) fixed via progressive eccentric tongue lift (entry fused shallow -> exit floating overlap, 1-2mm visible seam gap) + tall tongue-side ramp blade + bigger flare trumpet; exit overlapping roll not a ring; fail-loud seam/burial/footprint asserts; tape untouched; viewer _sixTurner relabel, ASSET_V 37, plow GLB rebuilt

## v52 — 2026-09-17
- Smaller vertical pullers + 9.5mm nip gap (user: gap 9.5, pullers too big): vpull_r 10->7.5 (d20->d15), sleeve 10.15->7.65 (0.15 proud), h 24->20, sleeve_h 16->12, caps/collar d22->d17; param-driven vpull_gap=9.5, vpull_off=sleeve_r+gap/2=12.4 (replaces r+2.0+1.5+0.4+tol); Y 17.6/42.4; spin-compensated drive x4/3 (surface speed kept, 1:1 assert replaced); bridge/cup/pins lowered to the shorter stack (top 27); fail-loud 9.5 gap assert; viewer pivots + PULL_SPIN, ASSET_V 34, pull + chassis GLBs rebuilt, verify_v52.js

## v50 — 2026-09-17
- True 6-profile open folder (user REJECTS v49 pipe: exit ring fully closed): sample forensics for real (inches x25.4 = 28.0 x 23.6mm, open wrap + overlap seam); six_turner rebuilt as U-trough + rising wall + tongue overlapping the top with 1-2mm seam gap open full length (entry shallow curl + flare -> exit deep overlap roll, shut-tube section + R5.6 exit ring deleted); fail-loud seam/overlap/not-closed/footprint asserts; tape untouched; viewer _sixTurner relabel, ASSET_V 35, plow GLB rebuilt, verify_v50.js

## v49 — 2026-09-17
- Gradual-curl 6-folder (user: "6 folder.stl" inspiration only, nicer former): six_turner rebuilt as 7-station hull-loft (same 126..159 footprint/tabs/mount) — open-U entry (slot +-3.9, flare, lead walls) -> U -> C -> overlap -> closed tube from local x27 + exit ring R5.6/bore 3.2 (crown 1.2) with 6 seam tail at exit only; bore tapers 4.6->3.2 (entry dia 9.2 clears 7.8 pocket); curl rails on slot edges (void-trimmed, never blocking); horns/tongue/inner-roll deleted; fail-loud slot/crown/footprint/threading asserts; tape untouched (curls inside hidden steel, documented); viewer _sixTurner relabel, ASSET_V 33, plow GLB rebuilt, verify_v49.js

## v48 — 2026-09-17
- Parallel-spur + perpendicular-pinion twister drive (user: floor-lying gear wrong; wanted parallel gear FROM drum + small perpendicular to twister): deleted v47 upright shaft (100,30) + floor bevels; new drum-coaxial 50T -> parallel counter 10T (5x, Y-Y, dist 60 = sqrt(dx^2+43^2), (~141.85,17), high, bottoms 8/5) + Y-bevel 12T -> X-pinion 10T (1.2x, 90° at I48 (~141.85,30,17)); total 6.0 = 1 bind/seed; high Y countershaft (through-wall 1..59) + clean X stub (cx->172 fused to hub, mid hanger); module 2, teeth [10,60], fail-loud parallel/bevel/interior/min_z (smallest 3, shafts >=14); pull/takeup tape-coupled; animation/ratios/signs/stations/gaps/tape/6-turner untouched, ASSET_V 32, GLBs rebuilt --force, verify_v48.js

## v47 — 2026-09-17
- Bevel twister drive, zero exterior gears (user: remove outside gears, perpendicular bevels + proper ratio): deleted v46 exterior spur farm (DRUM40/C-14T-21T/TW-10T/P2-12T/PULL-20T/J-12T/TU-10T + stubs/bosses/tongue/tube/bridge-hole, wall clean solid); new bevel_gear module + two 90° pairs (drum 20T->vertical 10T = 2x at I_top (100,30,60); vertical 30T->twister 10T = 3x at I_bot (100,30,17); total 6.0 = 1 bind/seed), interior jackshaft + twister shaft fused to hub; pull/takeup tape-coupled (documented, no gears); module 2, teeth [10,60], fail-loud intersection/perp/contact/interior/min_z asserts; animation/ratios/signs/stations/gaps/tape/6-turner untouched, ASSET_V 31, GLBs rebuilt --force, verify_v47.js

## v46 — 2026-09-17
- Shaft-mounted gear train (user: gear setup incorrect, tape/shafts fine): TW-10T rotor-coaxial (172,17, was 7.3 off), PULL-20T on pull-A axle (194,53, was 2.5 off, genuine pin+tube+bridge-hole drive), TU-10T reel-coaxial takeoff via J-12T (shared PP layshaft deleted, P1 deleted, C-14T/21T doubles as pull idler); 8 pieces/3 layshafts, module 2, dist=r1+r2 fail-loud, half-pitch phasing, bored idlers on stub+boss+wall cantilevers, TW tongue 1.5 gap, min_z>=0; ratios/signs/stations/gaps/tape/6-turner untouched, ASSET_V 30, GLBs rebuilt --force, verify_v46.js

## v45 — 2026-09-17
- Forensic tape-path + mount integrity fix (19-angle inspection): D1 viewer tape scroll-dangle removed (static ribbon -14..208, TAPE_LEN 270->222, regression test); D2 wind-up leader added (CAD flat ends 208 + w8 strip 206..224.5 into pack r8, viewer mirrors + _windLeader, fail-loud asserts, min_z=0 watertight); D3 dead axles seat drum/reel/spool + fuse DRUM40/TU (slip fits, buried ends, asserts); D4 twister posts 17->13 (2 rolling gap, analytic graze fix, 1.5..4 window assert); D5 pull mid-collar 12->5.0 local (CAD top 10.5 clears ribbon by 2.5, asserted); ratios/signs/gears/stations/gaps/6-turner untouched, ASSET_V 29, dirty GLBs rebuilt, verify_v45.js

## v44 — 2026-09-17
- Minimal drum-driven gear train (user: too many gears on chassis): crank<->drum 2:1 kept as the ONLY crank connection; everything downstream drives locally from exterior DRUM40 — C-20T/30T compound + TW-10T twister 6x drum, P1/P2-12T + PP-20T pull 1:1 crank, shared PP-axle + TU-10T take-up 2x crank (sense unchanged); 16 pieces/~12 layshafts -> 8 pieces/5 layshafts (E0..PC spine + D2/L1/L2 + GT/GJ/GS removed); module 2, dist=r1+r2 fail-loud, half-pitch phasing, bosses+through-holes, clearances >=6, min_z>=0; ratios/signs unchanged; viewer comments/legend/_gearTrain + ASSET_V 28, GLBs rebuilt; stations/gaps + 6-turner untouched

## v43 — 2026-09-17
- True-meshed gear train (decorative-idler audit fix): CAD exterior train all module 2, every pair dist=r1+r2 fail-loud (plane-A 12T chain E0->PC pull 1:1; D2-20T->L1 12T/36T compound; plane-B L1b->L2-10T twister 6x drum + GT/GJ/GS-15T take-up 2x crank sense-reversed), half-pitch phasing, layshaft bosses+through-holes, min_z=0; takeup_angle +1440t->-1440t; viewer take-up sign flip + meshed comments, ASSET_V 27, GLBs rebuilt; stations/gaps + 6-turner untouched

## v42 — 2026-09-17
- True 6-fold second stage (user clarification: tape ALREADY U-bent by first stage): six_turner reworked 126..159 into U-accept entry + twin edge-curl horns (r2.5) + inner tongue diving crown->bore with inner roll (r2.2, post-cut union) folding 2 U edges inside + necked exit ring (r5.5/bore r3.2) reading as 6 end-on; main bore r4.2+1.2 kept (dia 8.4 clears 7.8), footprint/tabs/stations kept (lip 160.35 -> twister gap 7.65); 5 new asserts; viewer relabel two-stage + _sixTurner stages/entry/exit hooks, ASSET_V 26, GLBs rebuilt

## v41 — 2026-09-17
- 6-turner + gear-only + mounts + clutch build (v39/v40 spec): CAD six_turner (6-curl r6.5/bore r4.2+1.2 offset, plow footprint kept, plow alias + turner branch, mouth 26 after drop) + cushioned pull sleeve (r10.15, 1:1) + take-up slip clutch (discs+spring+nut, h 41) + chassis pull bridge + 2 idler spurs + mount comments + 8 fail-loud asserts; viewer relabel/rubber pull/takeup 20.5/hooks/comments, ASSET_V 25, GLBs rebuilt

## v40 — 2026-09-17
- Mounting layout for all components (bottom: 6-turner+wind-up, side: twister+rollers+drum, top: hopper/shroud/spools); 6-turner positioned after drop point; wind-up slip clutch on reel axle

## v39 — 2026-09-17
- Replace U-plow with 6-shaped turner/roller former (tape with seed passes through 6 curl to roll edges over); twister/pull/wind all crank-driven via gears only (no belts) – crank→drum 2:1 → twister 6× per drum via idler spur → vertical pull 1:1 → wind-up step-up; vertical pull rollers cushioned (soft rubber/silicone) for firm grip without crushing

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
- Tape bend true mimic (tapeubend.png): CAD R 3.0->1.75, fold 12.7->6.0 (HW 3.0), wall 2.0->5.5, N_ARC 12->20, new shoulder R1.5/60° S-kink + N_X 12 taper (0.15->1.0 W->E), double slab removed (single-layer floor), former collar shoe visual; viewer mirrors params, TAPE_LEN 320->180 unified, collar visual, ASSET_V 15

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
