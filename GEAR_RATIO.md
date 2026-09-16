# Gear-Ratio Calculator / Spacing Chart (v13 MVP helper)

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
