# REQUIREMENTS — vseedtaper (product summary)

Read this for **what the product must do** (current functionality).  
Version history lives only in **`CHANGELOG.md`** — not here.

Status: living product requirements. Uncommitted until user APPROVE when changed.

## Product
OpenSCAD CAD + static three.js viewer for a **seed-tape making machine** (v2). No build, no tests, no CI, no README. Live preview: `http://localhost:9099/`.

## Core functionality

### Machine (CAD — `seed_tape_machine_v2.scad`)
- Builds the full assembly: chassis, hopper, drum/cartridge, cones, plow (six-turner), tape path + former collar, cradle, twister + twister axle + pedestal, pull rollers a/b + bridge, takeup, crank.
- Drive: crank → drum gear mesh (module 2, fail-loud mesh distance). Twister driven at ratio from crank (viewer signs documented in code).
- Feed path: hopper drop → plow forms/folders tape → twister orients seed pocket → pull/takeup advance tape. Clearances asserted fail-loud on every stack-up.
- CAD conventions: `$fn=60` curves, `tol=0.3` (all clearances derive from `tol`).
- Single-object isolation: changing one part must not silently alter others.
- Fail-loud OpenSCAD asserts for gaps, coplanarity, sweeps, and stack-ups.

### Special GLB exports
- `cone_a` / `cone_b`: `single_cone` ± offset.
- `rollers_lower` / `rollers_upper`: split from fused `pull_rollers()` for independent viewer pivots.

### Viewer (`web/`)
- `PART_DEFS` + per-part pivots + `SCHEME` colors; loads `stl/*.glb` only (never `.stl` in previews).
- Vendored `three.min.js`, `GLTFLoader.js`, `OrbitControls.js` — never CDN-swap.
- Cache bust `?v=N` on GLB/script URLs; bump `ASSET_V` when regenerating assets.
- Animated assembly preview for user review on port **9099** only.
- `web/vNN/` snapshots: only `index.html`, `js/`, `stl/*.glb`.

### Regeneration pipeline
- `./regenerate_glbs.sh`: **`openscad-nightly` only** (manifold, headless, no Xvfb, no 2021.01) + `python3 trimesh` STL→GLB. Missing nightly → fail loud with install hint.
- `web/stl/*.glb` are generated artifacts — rebuild, never hand-edit.

## Frozen / non-negotiable
- Never edit v1 `seed_tape_machine.scad` or `web/backup/` except to restore.
- Port 9099 only; `$fn=60`, `tol=0.3`; nightly-only OpenSCAD.
- Playwright: pool browser, screenshots only under `screenshots/` (max 25, not in git).
- Screenshots are for **reviewer automated review only** — user uses live preview.
- No commit/push without explicit user APPROVE.

## Delivery (how changes ship)
See `AGENTS.md` pipeline: Requirements → plan+analyze (`plan` agent) → implement → reviewer (pool screenshots) + notify user on live preview → max 2 fix loops → user APPROVE → **one** commit (`CHANGELOG.md` version entry + code + snapshot).
