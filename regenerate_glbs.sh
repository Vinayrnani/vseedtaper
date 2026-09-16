#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="/home/ubuntu/projects/vseedtaper"
SCAD_SRC="$SCRIPT_DIR/seed_tape_machine_v2.scad"
STL_DIR="$SCRIPT_DIR/web/stl"
TMPDIR=$(mktemp -d /tmp/openscad_XXXXXX)

cleanup() {
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

echo "=== Regenerating all GLB files for seed tape machine v2 ==="

# Create temp scad files by copying original and replacing part_to_render
# This avoids the -D flag issue with xvfb-run

make_scad() {
    local part="$1"
    local out="$2"
    sed "s/part_to_render = \"all\"/part_to_render = \"$part\"/" "$SCAD_SRC" > "$out"
}

# Main parts - sed replaces part_to_render = "all" with the desired value
make_scad "chassis" "$TMPDIR/chassis.scad"
make_scad "hopper" "$TMPDIR/hopper.scad"
make_scad "shroud" "$TMPDIR/shroud.scad"
make_scad "cartridge" "$TMPDIR/cartridge.scad"
make_scad "plow" "$TMPDIR/plow.scad"
make_scad "crank" "$TMPDIR/crank.scad"
make_scad "cones" "$TMPDIR/cones.scad"
make_scad "rollers" "$TMPDIR/rollers.scad"

# cone_a: single_cone at origin
# Replace part_to_render and remove the if/else block at bottom, add single_cone() call
sed "s/part_to_render = \"all\"/part_to_render = \"cone_a\"/" "$SCAD_SRC" | \
    sed '/^if (part_to_render == "all") {$/,/^}$/d' > "$TMPDIR/cone_a.scad"
echo "single_cone();" >> "$TMPDIR/cone_a.scad"

# cone_b: single_cone translated by [50, 0, 0]
sed "s/part_to_render = \"all\"/part_to_render = \"cone_b\"/" "$SCAD_SRC" | \
    sed '/^if (part_to_render == "all") {$/,/^}$/d' > "$TMPDIR/cone_b.scad"
echo "translate([50, 0, 0]) single_cone();" >> "$TMPDIR/cone_b.scad"

echo "Temp files created in $TMPDIR"

echo ""
echo "=== Step 1: Exporting STL files with xvfb-run + openscad ==="

export_part() {
    local part="$1"
    echo "  Exporting $part..."
    xvfb-run -a openscad -o "$TMPDIR/${part}.stl" "$TMPDIR/${part}.scad" 2>&1 || echo "  WARNING: $part may have failed"
}

export_part "chassis"
export_part "hopper"
export_part "shroud"
export_part "cartridge"
export_part "plow"
export_part "crank"
export_part "cones"
export_part "rollers"
export_part "cone_a"
export_part "cone_b"

echo ""
echo "=== Step 2: Converting STL to GLB with trimesh ==="

convert_to_glb() {
    local part="$1"
    if [ -f "$TMPDIR/${part}.stl" ]; then
        echo "  Converting $part.stl -> $STL_DIR/${part}.glb"
        python3 -c "
import trimesh
m = trimesh.load('$TMPDIR/${part}.stl')
m.export('$STL_DIR/${part}.glb')
print('  Done: $STL_DIR/${part}.glb')
" 2>&1
    fi
}

convert_to_glb "chassis"
convert_to_glb "hopper"
convert_to_glb "shroud"
convert_to_glb "cartridge"
convert_to_glb "plow"
convert_to_glb "crank"
convert_to_glb "cones"
convert_to_glb "rollers"
convert_to_glb "cone_a"
convert_to_glb "cone_b"

echo ""
echo "=== Verification ==="
ls -lh "$STL_DIR"/*.glb 2>/dev/null | awk '{print $5, $9}'

echo ""
echo "=== Done ==="
