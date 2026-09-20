#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="/home/ubuntu/projects/vseedtaper"
SCAD_SRC="$SCRIPT_DIR/seed_tape_machine_v3.scad"
STL_DIR="$SCRIPT_DIR/web/stl"
CACHE_DIR="$SCRIPT_DIR/.regen_cache_v3"
TMPDIR=$(mktemp -d /tmp/openscad_v3_XXXXXX)

OPENSCAD_BIN=""
USE_NIGHTLY=0
NEED_XVFB=0
if command -v openscad-nightly >/dev/null 2>&1; then
    OPENSCAD_BIN="openscad-nightly"
    USE_NIGHTLY=1
elif command -v openscad >/dev/null 2>&1; then
    OPENSCAD_BIN="openscad"
    NEED_XVFB=1
else
    echo "ERROR: neither openscad-nightly nor openscad found on PATH." >&2
    exit 1
fi

XVFB_PID=""
cleanup() {
    if [ -n "$XVFB_PID" ] && kill -0 "$XVFB_PID" 2>/dev/null; then
        kill "$XVFB_PID" 2>/dev/null || true
    fi
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

if [ "$NEED_XVFB" -eq 1 ]; then
    command -v Xvfb >/dev/null 2>&1 || {
        echo "ERROR: Xvfb not found but legacy openscad needs it." >&2
        exit 1
    }
    Xvfb :99 -screen 0 800x600x24 -nolisten tcp &
    XVFB_PID=$!
    sleep 1
    kill -0 "$XVFB_PID" 2>/dev/null || {
        echo "ERROR: Xvfb :99 failed to start." >&2
        exit 1
    }
    export DISPLAY=:99
fi

# v3 parts: chassis, cartridge, hopper, rollers, crank, folder, twister
# Also need: rollers_upper (upper idler), layshaft
FORCE=0
FILTER=()
for arg in "$@"; do
    if [ "$arg" = "--force" ]; then
        FORCE=1
    else
        FILTER+=("$arg")
    fi
done

ALL_GLB="chassis cartridge hopper rollers crank folder twister rollers_upper layshaft"
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

scad_base_for() {
    case "$1" in
        rollers_upper) echo "rup_s_v3" ;;
        layshaft) echo "layshaft_v3" ;;
        *) echo "$1" ;;
    esac
}

echo "=== Regenerating all GLB files for seed tape machine v3 ==="
echo "  Renderer: $OPENSCAD_BIN (nightly=$USE_NIGHTLY)"

make_scad() {
    local part="$1"
    local out="$2"
    sed "s/part_to_render[[:space:]]*=[[:space:]]*\"all\"/part_to_render = \"$part\"/" "$SCAD_SRC" > "$out"
}

ensure_scad_for_base() {
    local base="$1"
    local out="$TMPDIR/${base}.scad"
    if [ -f "$out" ]; then return 0; fi
    case "$base" in
        rup_s_v3)
            sed "s/part_to_render[[:space:]]*=[[:space:]]*\"all\"/part_to_render = \"rollers\"/" "$SCAD_SRC" | \
                sed '/^if (part_to_render == "all") {$/,/^}$/d' > "$out"
            echo "knurled_roller(has_crank_mount=false);" >> "$out"
            ;;
        layshaft_v3)
            sed "s/part_to_render[[:space:]]*=[[:space:]]*\"all\"/part_to_render = \"chassis\"/" "$SCAD_SRC" | \
                sed '/^if (part_to_render == "all") {$/,/^}$/d' > "$out"
            echo "rotate([0, 90, 0]) cylinder(h=85, d=6);" >> "$out"
            echo "bevel_gear_pair_90();" >> "$out"
            ;;
        *)
            make_scad "$base" "$out"
            ;;
    esac
}

for glb in $WANT; do
    ensure_scad_for_base "$(scad_base_for "$glb")"
done

echo "Temp files created in $TMPDIR"
mkdir -p "$STL_DIR" "$CACHE_DIR"

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
echo "=== Cache: ${#DIRTY[@]} dirty, ${#SKIPPED[@]} up-to-date ==="
if [ "${#SKIPPED[@]}" -gt 0 ]; then echo "  Skipped: ${SKIPPED[*]}"; fi
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
echo "=== Step 1: Exporting STL files with $OPENSCAD_BIN (-P$JOBS) ==="

export_part() {
    local base="$1"
    echo "  Exporting $base..."
    if [ "$USE_NIGHTLY" -eq 1 ]; then
        if env -u DISPLAY QT_QPA_PLATFORM=offscreen "$OPENSCAD_BIN" \
            --backend=manifold --export-format binstl -q \
            -o "$TMPDIR/${base}.stl" "$TMPDIR/${base}.scad" 2>&1; then
            return 0
        fi
        echo "  WARNING: manifold failed for $base, retrying with cgal" >&2
        env -u DISPLAY QT_QPA_PLATFORM=offscreen "$OPENSCAD_BIN" \
            --backend=cgal --export-format binstl -q \
            -o "$TMPDIR/${base}.stl" "$TMPDIR/${base}.scad" 2>&1 \
            || echo "  WARNING: $base export failed"
    else
        "$OPENSCAD_BIN" --export-format binstl -q \
            -o "$TMPDIR/${base}.stl" "$TMPDIR/${base}.scad" 2>&1 \
            || echo "  WARNING: $base may have failed"
    fi
}
export TMPDIR OPENSCAD_BIN USE_NIGHTLY
export -f export_part

DIRTY_BASES=()
for glb in "${DIRTY[@]}"; do
    DIRTY_BASES+=("$(scad_base_for "$glb")")
done
printf "%s\n" "${DIRTY_BASES[@]}" | xargs -r -P "$JOBS" -I{} bash -c 'export_part "$@"' _ {}

echo ""
echo "=== Step 2: Converting STL to GLB (single persistent python, $JOBS workers) ==="
python3 - "$JOBS" "$TMPDIR" "$STL_DIR" "${DIRTY[@]}" <<'PYEOF'
import os
import sys
import trimesh
from concurrent.futures import ThreadPoolExecutor

jobs = max(1, int(sys.argv[1]))
tmpdir, stldir = sys.argv[2], sys.argv[3]
wanted = sys.argv[4:]
if not wanted: sys.exit(0)

base_for = {"rollers_upper": "rup_s_v3", "layshaft": "layshaft_v3"}

def convert_one(glb_name):
    base = base_for.get(glb_name, glb_name)
    src = os.path.join(tmpdir, base + ".stl")
    dst = os.path.join(stldir, glb_name + ".glb")
    if not os.path.isfile(src):
        return "  SKIP " + glb_name + ": missing " + src
    mesh = trimesh.load(src)
    mesh.export(dst)
    return "  Done: " + dst

with ThreadPoolExecutor(max_workers=jobs) as pool:
    for line in pool.map(convert_one, wanted):
        print(line, flush=True)
PYEOF

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
