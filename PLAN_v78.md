# v78 Implementation Plan — Crank to Twist-Gear End + Hopper Mouth Left

## Summary
Move the crank from the back wall (x=40, Y=-8) to the front wall (x=100, Y=68) so it's coaxial with the drum, and mirror the hopper wedge about the Y axis so the seed box mouth points LEFT (west). Flip all rotation signs to match the new viewing orientation.

## Verified Current State

| Item | Current Value | Source |
|------|--------------|--------|
| crank_mount_x | roller_axle_x = 40 | seed_tape_machine_v2.scad:204 |
| crank_mount_y | -8 (back wall) | seed_tape_machine_v2.scad:205 |
| crank_side | -1 (grip extends -Y) | seed_tape_machine_v2.scad:206 |
| crank_pivot_x | 5 (arm_w/2) | seed_tape_machine_v2.scad:211 |
| crank_pivot_z | ~8.47 | seed_tape_machine_v2.scad:212 |
| Hopper wedge x range | 14..83 (+X side) | seed_tape_machine_v2.scad:1139 |
| Cover arc | 120..270° | seed_tape_machine_v2.scad:1257-1258 |
| drum_angle (SCAD) | -360*$t | seed_tape_machine_v2.scad:2231 |
| crank_angle (SCAD) | +720*$t | seed_tape_machine_v2.scad:2232 |
| twister_orbits_per_drum | 6 | seed_tape_machine_v2.scad:304 |
| crankMount (viewer) | (40, 60, 8) | web/index.html:332 |
| drumPivot.rotation.z | crankAngle * DRUM_RATIO | web/index.html:644 |
| twisterPivot.rotation.x | -3 * crankAngle | web/index.html:645 |
| ASSET_V | 41 | web/index.html:667 |

## Phase 1 — seed_tape_machine_v2.scad Edits

### 1a. Crank parameters (lines 203-212)
- `crank_mount_x = drum_axle_x; // 100: coaxial with drum (was roller_axle_x=40)`
- `crank_mount_y = chassis_width + 8; // 68: outside FRONT wall (was -8 back)`
- `crank_side = +1; // v78: grip extends +Y outward front (was -1 back)`

### 1b. Crank asserts (lines 629-632)
- `assert(crank_mount_x == drum_axle_x, ...)` (was == roller_axle_x)
- `assert(crank_mount_y == chassis_width + 8, ...)` (was == -8)
- `assert(crank_side == +1, ...)` (was == -1)

### 1c. Hopper wedge mirror (lines 1139, 1200-1260)
The hopper is positioned at drum center (local [0,0,hopper_axis_z]). The wedge currently extends +X (east, toward x=83 world). Mirror about Y axis = flip X coordinates.

**Coordinate transform** (about local x=0, which is world x=100):
- x_new = -x_old
- y, z unchanged

**Changes:**
- Line 1139: `x0 = -83; x_tip = -14;` (was 14, 83 — mirrored)
- Lines 1200-1207 (cheek plates): swap x0/x_tip references for the mirrored wedge; the hull cubes use -x_tip and -x0
- Lines 1210-1213 (floor slab): `tilt_pivot` X flips sign: `tilt_pivot = [-25, 0, 56];` (was [25,0,56])
- Line 1211: `rotate([0, LOW_TILT, 0])` (was -LOW_TILT — mirror of tilt)
- Lines 1222-1228 (side-closure fins): arc start angle flips: `rotate([0, 0, -120])` and `rotate_extrude(angle=92)` starting from -120 (mirrored arc 120..212 → -120..-212)
- Lines 1234-1235 (closed nose): x flips: `translate([-85, ...])` (was [78,...])
- Lines 1241-1243 (root-top gussets): x flips
- Lines 1255-1260 (retention cover arc): `rotate([0, 0, -120])` `rotate_extrude(angle=150)` (mirrored 120..270 → -120..-270)
- Lines 1279-1282 (trough void): `translate([-3, ...])` `cube([48,...])` positioned from -x
- Line 1144: `tilt_pivot = [-25, 0, 56]`
- Line 1146: `floor_lx1 = (tilt_pivot[0] - (-84.5))/cos(LOW_TILT)` — recompute for mirrored geometry

**Collision check** (mirrored wedge footprint x -83..-14 → world 117..186):
- Gear shroud x 58..84: CLEAR (117 > 84) ✓
- Forming chute x 37..70: CLEAR (117 > 70) ✓
- Pull roller x=40: CLEAR (117 > 40) ✓
- **No collision adjustments needed.**

### 1d. Chassis crank hole (lines 1021-1025)
The existing roller axle holes at x=40 through both walls remain. The crank now mounts at x=100 (drum axle). The drum already has hex holes at x=100 through both walls (lines 1026-1030). The crank uses a hex shaft — it goes through the existing drum hex hole on the front wall. **No new chassis holes needed** — the drum hex hole at front wall (y=chassis_width-wall_thick) already exists.

However, we need to verify the crank hex shaft can pass through the front wall hex hole. The drum hex hole is hex_clearance_r radius; the crank hex shaft is hex_axle_r. These should be compatible (clearance > shaft). Add an assert if not already present.

### 1e. Drum rotation direction flip (line 2231)
- `drum_angle = 360*$t;` (was -360*$t — sign flipped for new orientation)
- This makes the drum rotate CW when viewed from +X (which is now the "right" end where the crank is).

### 1f. Crank assembly in animated_assembly (lines 2304-2310)
The crank is now at the drum axle (x=100), not the roller axle (x=40). Update:
- `translate([crank_mount_x, crank_mount_y, drum_axle_z])` (was roller_axle_z)
- `rotate([0, drum_angle, 0])` (was roller_angle — crank is now coaxial with drum)
- `translate([-crank_pivot_x, 0, -crank_pivot_z])` (unchanged)

### 1g. Version bump
- Update version comment at top of file to v78
- Bump any version marker

## Phase 2 — web/index.html Edits

### 2a. crankMount position (line 332)
- `crankMount.position.set(100, 60, -68);` (was (40, 60, 8))
- OpenSCAD (100, 68, 60) → viewer M-frame: (100, 60, -68)

### 2b. _setRotations (lines 640-649)
Since the crank is now coaxial with the drum (both at x=100), the crank spinner and drum pivot rotate together. The sign convention changes because we view from the other end.

```javascript
window._setRotations = function(crankAngle) {
    drumPivot.rotation.z = crankAngle * DRUM_RATIO;       // drum same ratio, sign flipped vs old
    crankSpinner.rotation.z = crankAngle;                   // v78: coaxial with drum (was -crankAngle - GEAR_PHASE)
    lowerPivot.rotation.z = -crankAngle - GEAR_PHASE;      // roller at x=40 unchanged
    upperPivot.rotation.z = crankAngle;                     // idler unchanged
    twisterPivot.rotation.x = 3 * crankAngle;              // v78: sign flipped (was -3)
    pullAPivot.rotation.y = PULL_SPIN * (2 * crankAngle + GEAR_PHASE);
    pullBPivot.rotation.y = -PULL_SPIN * (2 * crankAngle + GEAR_PHASE);
    takeupPivot.rotation.z = -2 * crankAngle;              // v78: sign flipped (was +2)
};
```

**Rationale for sign flips:**
- Drum: SCAD drum_angle changed from -360t to +360t, so viewer drum rotation sign flips
- Twister: driven by drum, sign follows drum
- Takeup: sign follows tape direction which follows roller (roller unchanged, but the overall tape path viewing direction changes)
- Crank: now coaxial with drum, so crankAngle (not -crankAngle)
- Roller/idler/pull: remain at x=40, their local physics unchanged

### 2c. ASSET_V (line 667)
- `var ASSET_V = 42; // v78: crank moved to front-right (drum-coaxial), hopper mirrored west, GLBs regenerated`

### 2d. Legend (lines 143-155)
Add line: `v78: Crank handle RIGHT (front, near twist gears); seed box mouth LEFT (west).`

### 2e. Comments (lines 176-186)
Update crank_mount_x/y comments to reflect new values.

## Phase 3 — Regenerate GLBs
```bash
./regenerate_glbs.sh chassis hopper cartridge crank rollers
```
5 parts: chassis (crank hole moved), hopper (mirrored), cartridge (drum rotation direction), crank (new mount position), rollers (unchanged but regen for hash freshness).

## Phase 4 — REQUIREMENTS.md
- Commit current untracked web/v53..v73 snapshot folders first
- Bump Version: v77 → v78
- Add v78 changelog entry

## Phase 5 — web/v78/ Snapshot
Copy web/index.html, web/js/, web/stl/*.glb into web/v78/

## Phase 6 — Verify
- Model verify_v78.js on verify_v75.js pattern
- Check crankMount pivot at (100, 60, -68)
- Check drum/crank/twister rotation signs
- ASSET_V = 42
- 0 console errors
- Screenshots: crank end (right/front), hopper mouth (left)

## Phase 7 — Commit + Push
