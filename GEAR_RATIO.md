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
