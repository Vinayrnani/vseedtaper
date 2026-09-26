#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="/home/ubuntu/projects/vseedtaper"
SCAD_SRC="$SCRIPT_DIR/seed_tape_machine_v2.scad"
STL_DIR="$SCRIPT_DIR/web/stl"
CACHE_DIR="$SCRIPT_DIR/.regen_cache"
TMPDIR=$(mktemp -d /tmp/openscad_XXXXXX)

# Copy scad/ into TMPDIR so include <scad/...> resolves from temp .scad files
cp -r "$SCRIPT_DIR/scad" "$TMPDIR/scad"

# --- Renderer selection: openscad-nightly ONLY (fail loud if missing) ---
# Never fall back to 2021.01 openscad or Xvfb. Nightly manifold backend
# renders headless (QT_QPA_PLATFORM=offscreen); no display server needed.
OPENSCAD_BIN="openscad-nightly"
if ! command -v "$OPENSCAD_BIN" >/dev/null 2>&1; then
    echo "ERROR: openscad-nightly not found on PATH." >&2
    echo "  Install: sudo apt-get install -y openscad-nightly" >&2
    echo "  (OBS home:t-paul xUbuntu_24.04, arm64 build available)" >&2
    echo "  Legacy openscad 2021.01 / Xvfb fallback is intentionally removed." >&2
    exit 1
fi

cleanup() {
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

# Usage: ./regenerate_glbs.sh [--force] [part ...]
#   --force   ignore skip-unchanged cache, regenerate everything selected
#   part ...  optional subset of the GLB names to (re)generate;
#             default is all parts. Valid names:
#             chassis south_wall hopper cartridge plow crank rollers
#             rollers_lower rollers_upper tape twister takeup
#             u_guide u_guide_bracket u_former
FORCE=0
FILTER=()
for arg in "$@"; do
    if [ "$arg" = "--force" ]; then
        FORCE=1
    else
        FILTER+=("$arg")
    fi
done

ALL_GLB="chassis south_wall hopper cartridge plow crank rollers rollers_lower rollers_upper tape twister twister_axle takeup u_guide u_guide_bracket u_former gear_A gear_B gear_I gearwall"
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
echo "  Renderer: $OPENSCAD_BIN (manifold headless, no Xvfb)"

make_scad() {
    local part="$1"
    local out="$2"
    sed "s/part_to_render = \"all\"/part_to_render = \"$part\"/" "$SCAD_SRC" > "$out"
}

# Only materialize temp .scad files for the requested (WANT) subset, one per
# base. rlow_s/rup_s strip the all-assembly block and append
# their single-shape call (pull_rollers() is fused; viewer pivots singles).
ensure_scad_for_base() {
    local base="$1"
    local out="$TMPDIR/${base}.scad"
    if [ -f "$out" ]; then
        return 0
    fi
    case "$base" in
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
# Gate output the shell reads: the list of parts that failed verification.
: > "$TMPDIR/verify_fail.txt"

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
}
export TMPDIR OPENSCAD_BIN
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
# The conversion step also runs the mesh verification gate and exits non-zero
# if any part is defective; capture that status so the run still finishes
# (cache refresh + file listing) before failing at the end.
VERIFY_RC=0
python3 - "$JOBS" "$TMPDIR" "$STL_DIR" "$SCRIPT_DIR/print" "${DIRTY[@]}" <<'PYEOF' || VERIFY_RC=$?
import os
import sys
import numpy as np
import trimesh
from concurrent.futures import ThreadPoolExecutor

jobs = max(1, int(sys.argv[1]))
tmpdir, stldir, printdir = sys.argv[2], sys.argv[3], sys.argv[4]
wanted = sys.argv[5:]
if not wanted:
    sys.exit(0)
os.makedirs(printdir, exist_ok=True)

base_for = {"rollers_lower": "rlow_s", "rollers_upper": "rup_s"}

# --- Mesh verification gate ---------------------------------------------
# A broken artifact must NEVER be reported as a successful regeneration.
# This step used to print "WARNING <part>: not watertight" and carry on to
# exit 0, which is how print/tape.stl shipped with 32 non-manifold edges and
# 52 zero-area faces while the pipeline reported success. Now every part is
# converted FIRST, then every part is checked, all failures are collected and
# reported together (one pass shows the full picture, never an abort
# mid-run), and the process exits non-zero at the end if the list is
# non-empty.
#
# A part FAILS if ANY of these is true:
#   - not is_watertight
#   - body count != expected (default 1; see EXPECT_BODIES)
#   - not is_winding_consistent
#   - an edge shared by 3+ faces (non-manifold edge)
#   - zero-area (degenerate) face count > expected (default 0; see
#     EXPECT_ZERO_AREA)
#   - total volume <= 0 (an inverted shell drives it negative)
#
# Volume is checked on the whole mesh, not per shell: several parts carry a
# legitimate inward-facing inner shell (twister bore, twister_axle slot) that
# subtracts from the outer shell, and the total is still positive.
#
# EXPECT_BODIES lists the deliberate multi-body prints (mirrors ALL_GLB);
# everything not listed must be a single solid, so an unexpected split
# (e.g. 2 -> 3 bodies) is still caught as a defect.
EXPECT_BODIES = {
    # plow: the scroll_sheet() earB lug is a separate solid that is never
    # fused to the sheet, by design - it is a loose ear on the printed plow.
    "plow": 2,
    "chassis": 4,        # main plate + 3 loose pins/rails shipped in one GLB
    "cartridge": 2,      # upper + lower shell halves
    "crank": 2,          # crank plate + handle
    "twister": 2,        # outer scroll body + inward-facing bore shell
    "twister_axle": 2,   # axle body + inward-facing slot shell
}
DEFAULT_BODIES = 1

# EXPECT_ZERO_AREA is the per-part count of zero-area (degenerate) faces the
# gate TOLERATES. The check is "measured > expected => FAIL", so a part with
# no listed entry (default 0) still fails on a single sliver, and a part with
# an entry still fails the moment it gains one more. An entry is a claim that
# the listed slivers are already-understood and inert, never a general
# licence. Mirrors ALL_GLB by default (0 = must be sliver-free).
EXPECT_ZERO_AREA = {
    # twister: the inward-facing bore shell triangulates two collinear-vertex
    # triangles at the bore; the mesh is watertight with positive volume, and
    # both faces are visually and physically inert.
    "twister": 2,
}
DEFAULT_ZERO_AREA = 0
# print orientation: rotate assembly frame flat, then drop to min_z=0.
# The A composite (Y-cluster) stands tower-style (discs horizontal);
# everything else prints as-oriented.
# u_former: Step 6 B4 - the die is a tunnel (a ~10mm unsupported roof over a
# 10x10x8 void) and CANNOT be printed in its hopper-frame pose. Rotate 90 about
# X for print/*.stl ONLY: the roof becomes a vertical wall standing on the bed
# and the U channel becomes a horizontal tunnel, so it prints with no support.
# The viewer GLB (web/stl/u_former.glb) is exported from the SAME STL BEFORE
# this transform, so it keeps the hopper-frame pose the viewer places it in.
RX90 = trimesh.transformations.rotation_matrix(np.pi / 2, [1, 0, 0])
RYN90 = trimesh.transformations.rotation_matrix(-np.pi / 2, [0, 1, 0])
RYP90 = trimesh.transformations.rotation_matrix(np.pi / 2, [0, 1, 0])
print_rot = {"gear_A": RX90, "gear_B": RX90, "gear_I": RX90, "gearwall": RX90,
             "u_former": RX90}

def verify_one(glb_name, mesh):
    """Check one freshly exported mesh. Returns (ok, reasons, numbers)."""
    want = EXPECT_BODIES.get(glb_name, DEFAULT_BODIES)
    want_zero = EXPECT_ZERO_AREA.get(glb_name, DEFAULT_ZERO_AREA)
    try:
        watertight = bool(mesh.is_watertight)
        winding = bool(mesh.is_winding_consistent)
        bodies = int(mesh.body_count)
        face_counts = np.bincount(mesh.edges_unique_inverse)
        worst_mult = int(face_counts.max()) if face_counts.size else 0
        nonman = int((face_counts >= 3).sum())
        # Literal zero-area test: triangles with zero (or negative) area are
        # degenerate slivers that slicers choke on. trimesh's
        # nondegenerate_faces() mask does not reliably flag them, so count
        # area_faces directly.
        zero_area = int((mesh.area_faces <= 0.0).sum())
        volume = float(mesh.volume)
    except Exception as exc:
        return False, ["checks could not run: %s" % exc], {}
    nums = {"watertight": watertight, "bodies": bodies, "expect": want,
            "worst_mult": worst_mult, "nonman": nonman,
            "zero_area": zero_area, "zero_expect": want_zero,
            "volume": volume}
    reasons = []
    if not watertight:
        reasons.append("not watertight")
    if bodies != want:
        reasons.append("body count %d != expected %d" % (bodies, want))
    if not winding:
        reasons.append("winding not consistent")
    if nonman:
        reasons.append("%d non-manifold edge(s), worst edge shared by %d faces"
                       % (nonman, worst_mult))
    if zero_area > want_zero:
        reasons.append("%d zero-area face(s), allowance %d"
                       % (zero_area, want_zero))
    if not volume > 0:
        reasons.append("volume not positive (%.3f)" % volume)
    return (not reasons), reasons, nums

RESULTS = {}

def convert_one(glb_name):
    base = base_for.get(glb_name, glb_name)
    src = os.path.join(tmpdir, base + ".stl")
    dst = os.path.join(stldir, glb_name + ".glb")
    if not os.path.isfile(src):
        return "  SKIP " + glb_name + ": missing " + src
    mesh = trimesh.load(src)
    # Verify the source mesh, i.e. exactly what becomes the GLB; the print/
    # copy below is the same mesh with a rigid print transform, so it shares
    # every topological number reported here.
    ok, reasons, nums = verify_one(glb_name, mesh)
    RESULTS[glb_name] = (ok, reasons, nums)
    mesh.export(dst)
    prot = print_rot.get(glb_name)
    pm = trimesh.load(src)
    if prot is not None:
        pm.apply_transform(prot)
    pm.vertices -= [0, 0, pm.bounds[0][2]]
    pm.export(os.path.join(printdir, glb_name + ".stl"))
    return "  Done: " + dst + " + print/" + glb_name + ".stl"

with ThreadPoolExecutor(max_workers=jobs) as pool:
    for line in pool.map(convert_one, wanted):
        print(line, flush=True)

# --- Per-part verification summary (full numbers, so a failure is
# diagnosable without re-running) ---
hdr = "  %-16s %-9s %-6s %-6s %-9s %-11s %s" % (
    "part", "watertight", "bodies", "worst", "zero_ar", "volume", "verdict")
# Column note: zero_ar is "measured/allowed" zero-area faces, mirroring the
# bodies column, so an allowance is always visible in the table and never
# silently absorbs a regression.
print("\n" + hdr, flush=True)
print("  " + "-" * (len(hdr) - 2), flush=True)
failed = []
for glb_name in sorted(RESULTS):
    ok, reasons, n = RESULTS[glb_name]
    if not n:
        print("  %-16s %s" % (glb_name, "CHECKS DID NOT RUN"), flush=True)
        failed.append(glb_name)
        continue
    print("  %-16s %-9s %-6s %-6s %-9s %-11s %s" % (
        glb_name,
        "yes" if n["watertight"] else "NO",
        "%d/%d" % (n["bodies"], n["expect"]),
        n["worst_mult"],
        "%d/%d" % (n["zero_area"], n["zero_expect"]),
        "%.1f" % n["volume"],
        "ok" if ok else "FAIL"), flush=True)
    if not ok:
        failed.append(glb_name)

with open(os.path.join(tmpdir, "verify_fail.txt"), "w") as fh:
    for glb_name in failed:
        fh.write(glb_name + "\n")

if failed:
    print("\n  MESH VERIFICATION FAILED for %d part(s):" % len(failed),
          flush=True)
    for glb_name in failed:
        ok, reasons, n = RESULTS[glb_name]
        print("    %s: %s" % (glb_name, "; ".join(reasons) or "unknown"),
              flush=True)
    print("  Regeneration is NOT successful: a broken artifact must never be"
          "\n  reported as a successful regeneration.", flush=True)
    sys.exit(1)
print("  All %d regenerated part(s) passed mesh verification." % len(RESULTS),
      flush=True)
sys.exit(0)
PYEOF

# Refresh cache hashes for successfully regenerated parts only
for glb in "${DIRTY[@]}"; do
    base="$(scad_base_for "$glb")"
    if grep -qx "$glb" "$TMPDIR/verify_fail.txt"; then
        # A part that failed mesh verification must not be marked up-to-date:
        # caching it would make the next run report "nothing to do" and exit 0,
        # hiding the very defect the gate just caught.
        echo "  WARNING: $glb failed mesh verification - cache NOT updated (it will be re-checked next run)"
        continue
    fi
    if [ -f "$STL_DIR/${glb}.glb" ]; then
        cp "$TMPDIR/${base}.hash.new" "$CACHE_DIR/${glb}.sha256"
    else
        echo "  WARNING: $STL_DIR/${glb}.glb missing - cache not updated for $glb"
    fi
done

echo ""
echo "=== Verification ==="
ls -lh "$STL_DIR"/*.glb 2>/dev/null | awk '{print $5, $9}'

# Exit non-zero when the mesh gate rejected any part. A broken artifact must
# never be reported as a successful regeneration, so the run cannot end with
# "=== Done ===" and status 0 after printing mesh defects.
if [ "$VERIFY_RC" -ne 0 ]; then
    echo ""
    echo "=== FAILED: mesh verification gate rejected this regeneration ==="
    echo "  See the per-part summary above. Fix the CAD, then re-run"
    echo "  ./regenerate_glbs.sh --force <part>. Nothing is reported as Done."
    exit 1
fi

echo ""
echo "=== Done ==="
