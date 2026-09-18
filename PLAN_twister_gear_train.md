---
status: done
phase: 5
updated: 2026-09-18
---

# Implementation Plan: Orbital Thread Twister with 24:1 Compound Gear Train + 1:1 Bevel Turn

## Goal
Replace the v53 friction-wheel overhead twister drive with a 24:1 compound spur train
along the chassis side plus a final 1:1 bevel turn onto the ring, and upgrade the
twister to a gear-driven hollow ring (18mm bore, dual bobbin spindles).

## Binding User Decision (2026-09-18)
- Ring keeps rotating about the **X axis** (vertical bobbin orbit). Design a **BEVEL
  STAGE** for the Y→X axis turn.
- Overall ratio **~24:1 vs drum**:
  - Stage 1: Green **72T M1.5 → layshaft pinion 12T** (6:1, spur, parallel Y shafts)
  - Stage 2: layshaft gear **48T → countershaft pinion 12T** (4:1, spur, parallel Y shafts)
  - Final: **1:1 bevel turn (20T/20T M1.5)** from countershaft (Y) to ring (X).
- Ring spins **24x drum = 4 revs/seed** (6 cavities). Layshaft spins **-6x drum**
  (opposite sense). 8 cross-wraps per seed (2 bobbins × 4 revs).
- The extra 1:1 bevel stage is REQUIRED: a 12T M1.5 pinion (pitch r9) cannot surround
  the 18mm bore (r9) — tooth roots would break into the bore.
- Preserve ratio intent (24:1, 4 revs/seed, 8 cross-wraps) and tooth counts of the
  ratio stages (72/12/48/12 + 20/20 bevel).

## Geometry (binding layout, verify by calculation + test render)
- **Green72 M1.5** (pitch r54, tip ~55.5) coaxial/fused on drum shaft (axis Y at
  x=100, z=60), gear plane y≈44..50 (thickness 6; clears drum body ≤37.5 and tape
  edge ~42.7). NOTE: Green top reaches z≈115.5, slightly above chassis 110 —
  accepted as an exposed gear (documented deviation, no notch unless collisions prove
  otherwise).
- **Layshaft along Y at (163, 62)**: dist to drum axis sqrt(63²+2²)=63.03 ✓
  (target 63 = 54+9, within tw_tol 0.35). Carries 12T spur (mesh Green, same y plane
  44..50) + 48T spur at a free y plane (to be fixed in code, clear of pull/tube).
- **Countershaft along Y at (163, 17)**: dist to layshaft = 45.0 exact (dx=0,
  dz=45) ✓ (target 45 = 36+9). Carries 12T spur (mesh 48T, same y plane) + 20T
  bevel pinion aimed at apex.
- **Bevel apex at (163, 30, 17)** (intersection of countershaft axis and ring X-axis
  at y=30, z=17). Ring-side 20T M1.5 bevel (pitch r15, root ~13.1, clears 18mm bore
  with ~4mm wall) fused to ring west face; pinion 20T on countershaft. Follow the
  existing v53 apex/offset code pattern (pitch centres ±r_mate from apex along each
  axis; tune apex-x / ring-face offset so the gear pitch centre lands on the ring
  west face — document final numbers here after render).
- Ring stays centred x=172.
- **Collision checks (must resolve in code)**: 48T disc (x 125.5..200.5,
  z 24.5..99.5 plane) vs hopper, pull station x=194, plow top ~22; Green disc
  (x 44.5..155.5, z 4.5..115.5) vs shroud (x 58..84) and hopper; mount posts for
  layshaft/countershaft vs tube path (y=30, z=17) and scroll exit (~159). Resolve
  with mount posts at off-tube y positions.

## Context & Decisions
| Decision | Rationale | Source |
|----------|-----------|--------|
| All new gears module 1.5 | User spec; independent of existing module-2 drive gears | User requirement |
| Ring rotates about X (unchanged) | Binding user decision; vertical bobbin orbit preserved | User decision 2026-09-18 |
| 1:1 bevel turn 20T/20T M1.5 | 12T M1.5 pinion (r9) cannot surround 18mm bore (r9) — roots break into bore | Geometry analysis + user decision |
| Green72T fused on drum shaft (x=100) | Coaxial with drum; plane y44..50 clears drum body and tape | Layout analysis |
| Local tolerance tw_tol=0.35 | User spec for new meshes/bores; global tol=0.3 untouched | User requirement |
| Remove v53 overhead drive entirely | Replaced by side-mounted 24:1 train + bevel turn | User requirement |

## Replaces (v53 overhead drive)
- drum40 → counter10T (4x) → bevel 12T/10T (1.2x) → drop 15T/12T (1.25x) = **6.0x**,
  friction wheel (r3.5) on ring OD. Ring r10/tube2, bore r8, 6 orbits/drum rev.

## Phase 1: Parameters [IN PROGRESS]
- [x] 1.1 New gear-train params (M1.5 pairs, tw_tol=0.35 local): twister_mod=1.5,
      twister_Zg=72, twister_Zp1=12 (6:1), twister_Zg2=48, twister_Zp2=12 (4:1),
      bevel 20T/20T 1:1; pitch radii 54/9/36/9/15/15; cd1=63, cd2=45.
- [x] 1.2 Ring params: bore 18 ID, ring-side bevel 20T, 2 bobbin spindles 6mm dia ×
      14mm 180° apart on front face, 2× 2mm guide eyelets near bore.
- [x] 1.3 Layout positions: Green plane y44..50 on drum shaft; layshaft (163,62)
      Y-span + bearing posts; countershaft (163,17) Y-span + posts; 48T/12T mesh
      y plane; bevel apex (163,30,17).
- [x] 1.4 twister_orbits_per_drum 6 → 24.

## Phase 2: New Modules [PENDING]
- [x] 2.1 spur_gear(): accept module (local addendum=module, dedendum=1.25*module —
      identical for existing M2 gears); raise teeth cap 60→72+ for Green72.
- [x] 2.2 Rewrite thread_twister() → twister_ring(): hollow ring, 18mm clear bore,
      fused 20T bevel on west face, 2 bobbin spindles + 2 guide eyelets.
- [x] 2.3 twister_bracket(): split-collar/slotted, 0.35 clearances, base-mounted,
      coaxial y=30/z=17, window for bevel pinion.
- [x] 2.4 layshaft_gears() + countershaft gears (shafts + spur pairs + bevel pinion).

## Phase 3: Assembly & Animation [PENDING]
- [x] 3.1 animated_assembly(): drum 1x, layshaft -6x, countershaft +24x equiv,
      ring ±24x about X with correct relative senses; remove 6→24 orbits const.
- [x] 3.2 chassis(): mounts/bearings for new shafts; remove v53 wall holes, drop
      pocket, hanger posts, friction parts.
- [x] 3.3 Replace twister cradle posts with bracket geometry.

## Phase 4: Dispatch & Removal [PENDING]
- [x] 4.1 part_to_render: add twister_ring, twister_bracket, layshaft_gears
      (+green_gear/countershaft as needed); drop removed v53 parts.
- [x] 4.2 Remove ALL v53 overhead drive code + asserts (counter/bevel/drop gears,
      friction wheel, shafts, posts, wall holes, pockets).
- [x] 4.3 Assertions: centre distances ±0.35, ratio 24, bore ≥18, bracket
      clearances, bobbin orbit clears bracket.

## Phase 5: Viewer & GLB [PENDING]
- [x] 5.1 regenerate_glbs.sh: new parts in PARTS; remove stale v53 artefacts.
- [x] 5.2 web/index.html PART_DEFS/pivots (drop v53 entries, add new); twister spin
      24x drum (12x crank); ASSET_V bump + ?v= cache.
- [x] 5.3 Serve :9099 + Playwright (pool) live animating preview + snapshots.

## Key Geometry Summary
```
Drum shaft (Y): x=100, z=60
  └─ drum40 (40T M2, existing, y 9..15) UNCHANGED
  └─ Green72 (72T M1.5, pitch r54, y 44..50) NEW, fused, 6:1 takeoff

Layshaft (Y): x=163, z=62, dist to drum 63.03 ✓ (54+9)
  └─ 12T spur M1.5 (y 44..50, mesh Green) → layshaft -6x drum
  └─ 48T spur M1.5 (free y plane, 4:1 takeoff)

Countershaft (Y): x=163, z=17, dist to layshaft 45.0 ✓ (36+9)
  └─ 12T spur M1.5 (mesh 48T) → countershaft +24x equiv
  └─ 20T bevel pinion M1.5 → apex (163,30,17)

Ring (X): centre x=172, axis y=30/z=17, 20T bevel M1.5 west face, 1:1 turn
  └─ ring ±24x about X = 4 revs/seed, 8 cross-wraps (2 bobbins)
```

## Notes
- 2026-09-18: IMPLEMENTED as v69 (commit feat). Final numbers: Green plane
  y46..52 (centre 49, clears shroud wall 45 by 1); 48T/12T plane y16..22
  (centre 19, clears drum40 plane by 1, hopper cheek 22.2 by 0.2 —
  tight, documented); pinion cone_h 4 (top y40, clears Green by 6);
  ring bevel hub-less cone x163..168.5 fused to ring west face 168;
  collar plates x169..171/173..175 (bore 16.85, bridge z34..37, legs
  y11..15/45..49 on feet z4..5.5); countershaft waist r2.5 y22..38
  (clears scroll rim 159.8 by 0.7); layshaft cheek notches in hopper
  (local x63, z58, slip d8.6). Bevel pitch-centre vs ring-face offset:
  ring-gear cone runs apex->168.5 (0.5 fuse into west face 168);
  pinion disc r16.5 threads the collar bore r16.85 (0.35).
  Animation: drum 1x, layshaft -6x, countershaft +24x equiv, ring 24x
  about X (bevel-consistent: twister_angle == cnt_angle).
- 2026-09-18: plan rewritten per binding user decision — X-axis ring kept, 1:1 bevel
  turn replaces the direct 12T-on-ring mesh (bore/root interference). Earlier Y-axis
  all-spur draft (rev 1) superseded.
- Green top z≈115.5 pokes 5.5 above chassis wall 110: accepted exposed gear.
- Bevel pitch-centre vs ring-face offset: final numbers to be fixed in code and
  recorded here after test render.
