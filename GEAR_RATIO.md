# Gear-Ratio Calculator / Spacing Chart (v14 MVP helper)

MVP: spacing fixed **6 inch = 152.4 mm**, tape **1 inch = 25.4 mm** center-fold seed middle,
drum **6 cavities fixed** (wheels interchangeable by hand 1-6 mm, count stays 6).

Formula (pull-roller driven, drum geared slower vs roller):

```
spacing = PI * roller_dia * (drum_teeth / roller_teeth) / cavities
tape_per_drum_rev = PI * roller_dia * (drum_teeth / roller_teeth)
```

Stock gears: roller 20T / drum 40T module 2, roller_dia 20, cavities 6:

```
tape_per_drum_rev = PI * 20 * (40/20) = 125.66 mm
spacing = 125.66 / 6 = 20.94 mm
```

Target 152.4 mm needs future swap-gears (drum much slower vs roller).
Required ratio R = drum_teeth/roller_teeth = spacing * cavities / (PI * roller_dia):

| Target spacing | R needed (roller_dia 20, 6 cav) |
|---|---|
| 3 inch (76.2 mm) | 7.28 |
| 6 inch (152.4 mm, MVP) | 14.55 |
| 9 inch (228.6 mm) | 21.83 |

Future helper: swap-gear sets (or two-stage reduction) to reach R above;
viewer readouts (crank rev / tape mm / drum rev) already expose the live ratio.

## v37 downstream chain (vertical pull + twister + wind-up, all geared to drum)

Stock 20/40T, roller_dia 20, 6 cavities (per $t: crank 720°, drum -360°):

```
twister_angle = -360 * $t * 6          # 6 orbits per drum rev = 1 bind per seed
pull_angle    = +/- (720 * $t + 9°)    # same dia as main roller (d20) => 1:1
                                       # surface speed, spacing driver, spacing unchanged
takeup_angle  = 1440 * $t              # core d10: 4 rev per $t winds 125.66 mm
                                       # = same linear tape the nip delivers
```

- Spacing stays `PI * roller_dia * (drum_teeth/roller_teeth) / 6`
  (pull nip is 1:1 with the main roller, so it neither adds nor removes
  spacing; swap-gear table above still applies for the 152.4 mm target).
- Twister binds once per cavity: orbits/drum-rev (6) == num_divots (6),
  asserted fail-loud in CAD.
- Take-up core d10: revs per crank rev = roller_dia/core_d = 2
  (4 rev per $t); re-size via `takeup_core_d` if the pack diameter changes.

## v38 respace (no ratio change — stations only)

v37 steel overlapped (twister 163..171 touched pull 171..191 at X=171;
take-up 170..202 interpenetrated both). v38 sequential eastward with
>=5 mm steel-to-steel X gaps: plow end 159 -> twister 172 (168..176,
gap 9) -> pull 194 (184..204, gap 8) -> take-up 226/34 (210..242,
gap 6); pull->take-up centres 32 apart vs radii sum 26 + tol 0.3 +
margin 5 = 31.3. Chassis east 200->248 (len 262), tape 220->270
(reaches 242). Angles above unchanged.

## v39/v40 gear-only drive chain (NO belts anywhere)

Crank-drives-everything via spur gears only (idler visuals fused to
the chassis back-wall exterior; live proof = synced animation ratios):

```
crank_angle   = +720 * $t (+ 9° mesh phase)   # crank + lower roller shaft, 1 rev = 1 crank rev
drum_angle    = -360 * $t                     # 40:20 mesh => crank->drum 2:1, drum 0.5x crank
twister_angle = -360 * $t * 6                 # 6 orbits per drum rev via idler spur (1 bind per seed)
pull_angle    = +/- (720 * $t + 9°)           # d20 cushioned nip 1:1 with roller (spacing driver)
takeup_angle  = 1440 * $t                     # core d10 step-up: 2x crank winds the same linear tape
```

- Spacing unchanged: `PI * roller_dia * (drum_teeth/roller_teeth) / 6`
  (cushioned nip is 1:1, sleeve OD ~d20; swap-gear table above still
  applies for the 152.4 mm target).
- 6-turner is passive (no drive — the pull nip drags the seeded tape
  through the 6 curl which rolls the edges over).
- Slip clutch (take-up axle): the geared base ratio stays 2x crank;
  the friction discs slip as the pack diameter grows (fast when empty,
  slips when full), holding tape tension constant without re-gearing.
- Edge-to-edge steel X gaps (fail-loud in CAD): turner end 159 ->
  twister 168..176 (gap 9, actual 7.65 with tab overhang) -> pull
  183..205 incl. caps (gap 7) -> take-up 210..242 (gap 5).

## v47 bevel twister drive, ZERO exterior gears (replaces the v43-v46 spur farm)

User asked: REMOVE outside gears from the chassis wall; connect the
twister to the drum with perpendicular (bevel) gears + proper ratio.

Removed (all exterior spur visuals on the back wall): DRUM40 (40T) +
C-14T/21T compound + TW-10T + P2-12T + PULL-20T + J-12T + TU-10T +
idler stubs + boss rings + TW timing tongue + pull drive tube +
bridge tube-hole. The back wall is clean solid. Kept: the interior
crank<->drum 40:20 2:1 (the ONLY spur pair, inside) + dead axles +
pull support pins + solid pull bridge.

The twister axis runs along the tape (X) at (y=30, z=17); the drum
axis runs transverse (Y) at (x=100, z=60) — skew lines (dz=43), so
no single direct bevel can join them. v47 uses ONE interior vertical
jackshaft at (100,30) + the twister longitudinal shaft (100->172 at
y=30, z=17, fused into the rotor hub) to make TWO true 90° pairs:

```
I_top = [100,30,60] = drum axis (Y) ∩ vertical axis (Z), 90°
  drum bevel Zdb=20 (r20, fused on the drum shaft)
    -> vertical-top Zvt=10 (r10): 20/10 = 2x
I_bot = [100,30,17] = vertical axis (Z) ∩ twister axis (X), 90°
  vertical-bottom Zvb=30 (r30, same shaft as Zvt)
    -> twister bevel Ztw=10 (r10, on the twister shaft): 30/10 = 3x

total = (Zdb/Zvt) * (Zvb/Ztw) = (20/10) * (30/10) = 2 * 3 = 6.0
  = 6 twister orbits per drum rev = 1 bind per seed (6 cavities)
```

- Teeth all in [10,60], single module 2; pitch apices exactly at
  I_top/I_bot; gear centres one mating pitch radius off each apex
  (drum (100,20,60), vtop (100,30,40), vbot (100,30,27), tw
  (130,30,17)); all asserted fail-loud in CAD (intersection +
  perpendicular + ratio + apex contact + interior y>=0 + min_z>=0).
- Animation unchanged (twister -3x crank = 6x drum at 0.5x crank;
  1 bind/seed kept).
- Pull/takeup choice (documented): BOTH exterior spur branches also
  removed — zero clutter wins. The pull nip is tape-coupled 1:1 with
  the main roller (same d20 OD, spacing driver, static pins both
  ends); the take-up winds via tape tension + slip clutch (geared
  base speed kept in animation). No belts anywhere.
- Viewer: train legend rewritten (bevel note), `_gearTrain` carries
  the bevel table + apices; ASSET_V 31.

## v46 shaft-mounted train (replaces the v44/v45 layshaft placements)

Audit faults in v44/v45 (all meshes were numerically dist=r1+r2, but
mechanically misplaced): TW-10T sat 7.3 off the twister rotor
(170,24 vs 172,17) on a bracket fiction; PP-20T sat 2.5 off the nip
(196.46,28.79 vs 194) and dead-ended with no transfer to the
vertical rollers; C/P1/P2/PP/TW had boss visuals but no modeled
axles (floating cantilevers); take-up hung off the shared PP
layshaft instead of taking off a shaft gear.

```
interior: crank20 (40,60) <-> drum40 (100,60): dist 60 = 20+40
  W: crank +1 -> drum -0.5 (2:1, 1 flip, phase 9° half-pitch)

exterior DRUM40 (100,60, rigid on the drum shaft, W -0.5, plane A):
  twister: DRUM40 -> C-in-14T/C-out-21T compound (149.42,38.24,
      dist 54 = 40+14; W_C = +1.4286)
    -> TW-10T pinion (172,17 = bind_x/twister_axle_z, plane B,
      dist 31 = 21+10; wall-fused timing tongue, 1.5 rolling gap
      to the hub)
      W_TW = -3 = 6x drum, drum sign kept (2 flips)
  pull: DRUM40 -> C-in-14T -> P2-12T (173.50,28.43, dist 26 =
      14+12; W -1.6667) -> PULL-20T (194,53, dist 32 = 12+20;
      on the pull-A axle line, drive-tube ring down to the
      roller cap on the shared static pin, W +1 = 1:1 crank,
      3 flips)
  take-up: PULL-20T -> J-12T (225.86,56.00, dist 32 = 20+12;
      W -1.6667) -> TU-10T (226,34, coaxial reel, dist 22 =
      12+10; W +2 = 2x crank, drum sign kept, 5 flips total,
      sense unchanged vs v43/v44)
```

- Teeth check: (40/14)*(21/10) = 6.0 (twister 6x drum);
  40/20 = 2x drum = 1:1 crank (pull, idlers cancel);
  40/10 = 4.0x drum = 2x crank (take-up).
- Gear count: 8 pieces on 3 layshafts (C, P2, J) + 4 shaft gears
  (DRUM40/TW-10T/PULL-20T/TU-10T); v44 P1/PP layshafts deleted
  (C doubles as the pull idler, take-up takes off PULL).
- Same-plane non-mesh clearance verified >= 6mm everywhere
  (closest: C-PULL... now Ca-PULL 12.96, PULL-TU 7.22); plane B
  holds only C-out + TW.
- Bearings: idlers bored (slip 0.3/side) on modeled static stubs
  fused into solid bosses + back wall (cantilever with boss);
  pull-A rotor (roller + tube + gear) spins on the extended
  static pin + in the bridge hole (both-ends support); drum/reel
  keep the v45 dead axles.
- Spacing unchanged (pull nip still 1:1 d20).
- Viewer: pivots/ratios/signs unchanged; ASSET_V 30.

## v45 forensic tape-path + mount fix (no ratio change)

- Tape flat shortened 270->222 (-14..208) + wind-up leader 206..224.5
  into the pack; viewer ribbon static (scroll-dangle removed).
- Dead axles seat drum/reel/spool; twister cradled (gap 2); pull collar
  clears the tape. Angles/ratios/signs above unchanged; pull nip still
  1:1 d20 (spacing driver).

## v44 minimal drum-driven train (replaces the v43 long spine)

User asked for fewer gears on the chassis: everything downstream now
drives locally FROM an exterior drum gear. The crank<->drum 2:1
(dist 60 = 20+40, module 2, phase 9°) is the ONLY crank connection.

```
interior: crank20 (40,60) <-> drum40 (100,60): dist 60 = 20+40
  W: crank +1 -> drum -0.5 (2:1, 1 flip, phase 9° half-pitch)

exterior DRUM40 (100,60, rigid on the drum shaft, W -0.5, plane A):
  twister: DRUM40 -> C-in-20T/C-out-30T compound (159.94,62.71,
      dist 60 = 40+20; W_C = +1)
    -> TW-10T pinion (170,24, plane B, dist 40 = 30+10;
      7.3mm bracket to the rotor at 172,17)
      W_TW = -3 = 6x drum, drum sign kept (2 flips)
  pull: DRUM40 -> P1-12T (141.07,28.10, dist 52 = 40+12;
      W +1.667) -> P2-12T (164.77,24.34, dist 24 = 12+12;
      W -1.667) -> PP-20T layshaft (196.46,28.79, dist 32;
      2.5 off the nip, W +1 = 1:1 crank, 3 flips)
  take-up: PP-20T (shared axle, doubles as idler) -> TU-10T
      (226,34, coaxial reel, dist 30 = 20+10; W -2 = 2x crank,
      drum sign kept, 4 flips total, sense unchanged vs v43)
```

- Teeth check: (40/20)*(30/10) = 6.0 (twister 6x drum);
  40/20 = 2x drum = 1:1 crank (pull, idlers cancel);
  (40/20)*(20/10) = 4.0x drum = 2x crank (take-up).
- Gear count: 8 pieces on 5 layshafts (was 16 / ~12 in v43:
  E0..PC 9-chain + D2 + L1a/L1b + L2 + GT/GJ/GS all removed).
- Same-plane non-mesh clearance verified >= 6mm everywhere
  (closest: C-P2 6.67); plane B holds only C-out + TW.
- Spacing unchanged (pull nip still 1:1 d20).
- Viewer: pivots/ratios/signs unchanged; ASSET_V 28.

## v43 true-meshed exterior train (audit + fix, replaces decorative idlers)

BEFORE (v39-v42 audit): only crank20<->drum40 truly meshed
(dist 60 = 20+40, module 2, phase 9°). Idler1 20T at (110,60):
dist to drum 10 vs needed 60 (overlap -50), to crank 70 vs needed
40 (gap +30) — fused to the back wall, meshes nothing. Idler2 12T
at (183,17): nearest gear >60 away — decorative. Twister/pull/
take-up had animation ratios but no gears, no mesh phase, no
through-axles. Modules all 2 (ok), but center distances wrong.

AFTER (all module 2, pitch r = T, outer r = T+2; dist err 0.00):

```
interior: crank20 (40,60) <-> drum40 (100,60): dist 60 = 20+40
  W: crank +1 -> drum -0.5 (2:1, 1 flip, phase 9° half-pitch)

plane A (back-wall outer y -8..-2), all 12T (r12, MeshD 24):
  E0 (40,60) -> H1 (52.97,39.81) -> R0 (56,16) -> (80,16) ->
  (104,16) -> (128,16) -> (152,16) -> H3 (166.73,34.94) ->
  PC (190.22,30, pull layshaft, 4mm off the nip at 194)
  every hop dist 24.00 = 12+12; W_PC = +1 (8 flips, 1:1 crank)

drum takeoff D2-20T (100,60, rigid on drum shaft, W -0.5):
  D2 -> L1a-12T/L1b-36T compound (130.91,51.72): dist 32 = 20+12
  W_L1 = +0.8333

plane B (back-wall inner y -16..-10):
  L1b-36T -> L2-10T twister pinion (166.05,22.03): dist 46 = 36+10
    W = -3 = 6x drum, same sign (2 flips); layshaft 6mm off the
    twister rotor (172,17), rigid transfer bracket
  L1b-36T -> GT-15T (178.83,69.16): dist 51 = 36+15; W = -2
  GT-15T -> GJ-15T (205.94,56.31): dist 30 = 15+15; W = +2
  GJ-15T -> GS-15T (226,34, coaxial with the reel axle): dist 30
    W = -2 = 2x crank, sense reversed vs v42 (3 flips)
```

- Teeth check: (20/12)*(36/10) = 6.0 (twister 6x drum);
  (20/12)*(36/15)*(15/15)*(15/15) = 4.0x drum = 2x crank.
- Same-plane non-mesh clearance verified >= 6mm everywhere;
  coaxial compounds share centres across planes A/B.
- Spacing unchanged (pull nip still 1:1 d20).
- Viewer: twister/pull pivots + ratios unchanged; take-up sign
   flipped (+2x viewer sense = CAD -1440t); ASSET_V 27.

## v42 true 6-fold second stage (no ratio change — turner geometry only)

- FIRST stage still makes the U (forming 37..70 + transit 70..126);
  seed drops at x=100 into the OPEN U-pocket (lands flat first).
- SECOND stage (6-turner 126..159, passive, no drive): entry U-accept
  channel (x 0..12) takes the seeded U-section, twin edge-curl horns
  (r2.5 at cy+-4.2, x 6..20) + inner tongue diving crown->bore with an
  inner roll (r2.2, x 12..26 inside the bore) fold the 2 U edges
  INSIDE into an overlapping roll, exit ring (r5.5/bore r3.2) necks it
  near-closed — end-on cross-section reads as 6 (outer curl + inner
  tongue), not a plain round tube. Main bore r4.2 (dia 8.4) still
  clears the 7.8 pocket; footprint/tabs/posts/stations unchanged, so
  all X gaps above hold (turner lip to 160.35 -> twister gap 7.65).
- Angles/ratios above unchanged; pull nip still drags the tape
  through the curl (spacing driver 1:1).
