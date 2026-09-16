#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="/home/ubuntu/projects/vseedtaper"
SCAD_SRC="$SCRIPT_DIR/seed_tape_machine_v2.scad"
STL_DIR="$SCRIPT_DIR/web/stl"
CACHE_DIR="$SCRIPT_DIR/.regen_cache"
TMPDIR=$(mktemp -d /tmp/openscad_XXXXXX)

cleanup() {
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

# Usage: ./regenerate_glbs.sh [--force] [part ...]
#   --force   ignore skip-unchanged cache, regenerate everything selected
#   part ...  optional subset of the 12 GLB names to (re)generate;
#             default is all parts. Valid names:
#             chassis hopper shroud cartridge plow crank cones rollers
#             cone_a cone_b rollers_lower rollers_upper
FORCE=0
FILTER=()
for arg in "$@"; do
    if [ "$arg" = "--force" ]; then
        FORCE=1
    else
        FILTER+=("$arg")
    fi
done

ALL_GLB="chassis hopper shroud cartridge plow crank cones rollers cone_a cone_b rollers_lower rollers_upper"
if [ "${#FILTER[@]}" -gt 0 ]; then
    for p in "${FILTER[@]}"; do
        case " $ALL_GLB " in
            *" $p "*) ;;
            *) echo "Unknown part: $p (valid: $ALL_GLB)" >&2; exit 1 ;;
        esac
    done
    WANT="${FILTER[*]}"
else
    WANT="$ALL_GLB"
fi

# GLB name -> temp scad basename (rollers_lower/upper come from rlow_s/rup_s singles)
scad_base_for() {
    case "$1" in
        rollers_lower) echo "rlow_s" ;;
        rollers_upper) echo "rup_s" ;;
        *) echo "$1" ;;
    esac
}

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

# rollers_lower/upper: SINGLE vertical rollers for separate viewer pivots
# (pull_rollers() exports both fused; the viewer mounts them independently)
sed "s/part_to_render = \"all\"/part_to_render = \"rollers\"/" "$SCAD_SRC" | \
    sed '/^if (part_to_render == "all") {$/,/^}$/d' > "$TMPDIR/rlow_s.scad"
echo "knurled_roller(is_lower=true);" >> "$TMPDIR/rlow_s.scad"
sed "s/part_to_render = \"all\"/part_to_render = \"rollers\"/" "$SCAD_SRC" | \
    sed '/^if (part_to_render == "all") {$/,/^}$/d' > "$TMPDIR/rup_s.scad"
echo "knurled_roller(is_lower=false);" >> "$TMPDIR/rup_s.scad"

echo "Temp files created in $TMPDIR"

mkdir -p "$STL_DIR" "$CACHE_DIR"

# --- Skip-unchanged cache: sha256 of each part's temp scad ---
# Any shared-geometry edit changes every hash (conservative full regen);
# untouched re-runs skip everything in seconds. Use --force to bypass.
DIRTY=()
SKIPPED=()
for glb in $WANT; do
    base="$(scad_base_for "$glb")"
    cur="$(sha256sum "$TMPDIR/${base}.scad" | cut -d' ' -f1)"
    echo "$cur" > "$TMPDIR/${base}.hash.new"
    if [ "$FORCE" -eq 0 ] && [ -f "$CACHE_DIR/${glb}.sha256" ] && [ -f "$STL_DIR/${glb}.glb" ] \
        && cmp -s "$CACHE_DIR/${glb}.sha256" "$TMPDIR/${base}.hash.new"; then
        SKIPPED+=("$glb")
    else
        DIRTY+=("$glb")
    fi
done

echo ""
echo "=== Cache: ${#DIRTY[@]} dirty, ${#SKIPPED[@]} up-to-date (use --force for full regen) ==="
if [ "${#SKIPPED[@]}" -gt 0 ]; then
    echo "  Skipped: ${SKIPPED[*]}"
fi
if [ "${#DIRTY[@]}" -eq 0 ]; then
    echo "  Nothing to do - all requested parts up-to-date."
    echo ""
    echo "=== Verification ==="
    ls -lh "$STL_DIR"/*.glb 2>/dev/null | awk '{print $5, $9}'
    echo ""
    echo "=== Done ==="
    exit 0
fi
echo "  Dirty: ${DIRTY[*]}"

JOBS="$(nproc)"

echo ""
echo "=== Step 1: Exporting STL files with xvfb-run + openscad (-P$JOBS) ==="

export_part() {
    local base="$1"
    echo "  Exporting $base..."
    xvfb-run -a openscad -o "$TMPDIR/${base}.stl" "$TMPDIR/${base}.scad" 2>&1 || echo "  WARNING: $base may have failed"
}
export TMPDIR
export -f export_part

DIRTY_BASES=()
for glb in "${DIRTY[@]}"; do
    DIRTY_BASES+=("$(scad_base_for "$glb")")
done
printf "%s\n" "${DIRTY_BASES[@]}" | xargs -r -P "$JOBS" -I{} bash -c 'export_part "$@"' _ {}

echo ""
echo "=== Step 2: Converting STL to GLB with trimesh (-P$JOBS) ==="

convert_to_glb() {
    local glb="$1"
    local base
    case "$glb" in
        rollers_lower) base="rlow_s" ;;
        rollers_upper) base="rup_s" ;;
        *) base="$glb" ;;
    esac
    if [ -f "$TMPDIR/${base}.stl" ]; then
        echo "  Converting $base.stl -> $STL_DIR/${glb}.glb"
        STL_IN="$TMPDIR/${base}.stl" GLB_OUT="$STL_DIR/${glb}.glb" python3 -c "
import trimesh, os
m = trimesh.load(os.environ['STL_IN'])
m.export(os.environ['GLB_OUT'])
print('  Done: ' + os.environ['GLB_OUT'])
" 2>&1
    fi
}
export STL_DIR
export -f convert_to_glb scad_base_for

printf "%s\n" "${DIRTY[@]}" | xargs -r -P "$JOBS" -I{} bash -c 'convert_to_glb "$@"' _ {}

# Refresh cache hashes for successfully regenerated parts only
for glb in "${DIRTY[@]}"; do
    base="$(scad_base_for "$glb")"
    if [ -f "$STL_DIR/${glb}.glb" ]; then
        cp "$TMPDIR/${base}.hash.new" "$CACHE_DIR/${glb}.sha256"
    else
        echo "  WARNING: $STL_DIR/${glb}.glb missing - cache not updated for $glb"
    fi
done

echo ""
echo "=== Verification ==="
ls -lh "$STL_DIR"/*.glb 2>/dev/null | awk '{print $5, $9}'

echo ""
echo "=== Done ==="
