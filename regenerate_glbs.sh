#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="/home/ubuntu/projects/vseedtaper"
SCAD_SRC="$SCRIPT_DIR/seed_tape_machine_v2.scad"
STL_DIR="$SCRIPT_DIR/web/stl"
CACHE_DIR="$SCRIPT_DIR/.regen_cache"
TMPDIR=$(mktemp -d /tmp/openscad_XXXXXX)

# --- Renderer selection (parsed once at the boundary) ---
# Prefer openscad-nightly (manifold backend, headless, no X needed).
# Fall back to 2021.01 openscad on persistent Xvfb :99. Fail loud if neither.
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
    echo "  Upgrade command: sudo apt-get install -y openscad-nightly" >&2
    echo "  (OBS home:t-paul xUbuntu_24.04, arm64 build available)" >&2
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

# Single persistent Xvfb for the legacy path only (nightly needs no X).
# NOTE: per-part `xvfb-run -a` removed (it forked an X server per part).
# If xvfb-run is ever needed again, use tuned flags:
#   xvfb-run -a -w 0 -s "-screen 0 800x600x24 -nolisten tcp"
if [ "$NEED_XVFB" -eq 1 ]; then
    command -v Xvfb >/dev/null 2>&1 || {
        echo "ERROR: Xvfb not found but legacy openscad needs it." >&2
        exit 1
    }
    Xvfb :99 -screen 0 800x600x24 -nolisten tcp &
    XVFB_PID=$!
    sleep 1
    kill -0 "$XVFB_PID" 2>/dev/null || {
        echo "ERROR: Xvfb :99 failed to start (stale lock? try: rm -f /tmp/.X99-lock)." >&2
        exit 1
    }
    export DISPLAY=:99
fi

# Usage: ./regenerate_glbs.sh [--force] [part ...]
#   --force   ignore skip-unchanged cache, regenerate everything selected
#   part ...  optional subset of the 12 GLB names to (re)generate;
#             default is all parts. Valid names:
#             chassis hopper shroud cartridge plow crank cones rollers
#             cone_a cone_b rollers_lower rollers_upper tape
#             twister pull_a pull_b takeup
FORCE=0
FILTER=()
for arg in "$@"; do
    if [ "$arg" = "--force" ]; then
        FORCE=1
    else
        FILTER+=("$arg")
    fi
done

ALL_GLB="chassis hopper shroud cartridge plow crank cones rollers cone_a cone_b rollers_lower rollers_upper tape twister twister_bracket twister_pinion pull_a pull_b takeup gear_train"
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
        gear_train) echo "gear_train" ;;
        *) echo "$1" ;;
    esac
}

echo "=== Regenerating all GLB files for seed tape machine v2 ==="
echo "  Renderer: $OPENSCAD_BIN (nightly=$USE_NIGHTLY)"

make_scad() {
    local part="$1"
    local out="$2"
    sed "s/part_to_render = \"all\"/part_to_render = \"$part\"/" "$SCAD_SRC" > "$out"
}

# Only materialize temp .scad files for the requested (WANT) subset, one per
# base. cone_a/cone_b/rlow_s/rup_s strip the all-assembly block and append
# their single-shape call (pull_rollers() is fused; viewer pivots singles).
ensure_scad_for_base() {
    local base="$1"
    local out="$TMPDIR/${base}.scad"
    if [ -f "$out" ]; then
        return 0
    fi
    case "$base" in
        cone_a)
            sed "s/part_to_render = \"all\"/part_to_render = \"cone_a\"/" "$SCAD_SRC" | \
                sed '/^if (part_to_render == "all") {$/,/^}$/d' > "$out"
            echo "single_cone();" >> "$out"
            ;;
        cone_b)
            sed "s/part_to_render = \"all\"/part_to_render = \"cone_b\"/" "$SCAD_SRC" | \
                sed '/^if (part_to_render == "all") {$/,/^}$/d' > "$out"
            echo "translate([50, 0, 0]) single_cone();" >> "$out"
            ;;
        rlow_s)
            sed "s/part_to_render = \"all\"/part_to_render = \"rollers\"/" "$SCAD_SRC" | \
                sed '/^if (part_to_render == "all") {$/,/^}$/d' > "$out"
            echo "knurled_roller(is_lower=true);" >> "$out"
            ;;
        rup_s)
            sed "s/part_to_render = \"all\"/part_to_render = \"rollers\"/" "$SCAD_SRC" | \
                sed '/^if (part_to_render == "all") {$/,/^}$/d' > "$out"
            echo "knurled_roller(is_lower=false);" >> "$out"
            ;;
        gear_train)
            sed "s/part_to_render = \"all\"/part_to_render = \"gear_train\"/" "$SCAD_SRC" > "$out"
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
            || echo "  WARNING: $base export failed (both backends)"
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
# NOTE: converts run after the export barrier (all STLs ready). Overlapping
# converts with exports was considered but skipped: marginal gain for 12
# parts, extra failure modes; the barrier keeps failures loud and simple.
python3 - "$JOBS" "$TMPDIR" "$STL_DIR" "${DIRTY[@]}" <<'PYEOF'
import os
import sys
import trimesh
from concurrent.futures import ThreadPoolExecutor

jobs = max(1, int(sys.argv[1]))
tmpdir, stldir = sys.argv[2], sys.argv[3]
wanted = sys.argv[4:]
if not wanted:
    sys.exit(0)

base_for = {"rollers_lower": "rlow_s", "rollers_upper": "rup_s"}

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
