# REQUIREMENTS — vseedtaper (product summary)

Read this for **what the product must do** (current functionality).  
Version history lives only in **`CHANGELOG.md`** — not here.

Status: living product requirements. Uncommitted until user APPROVE when changed.

## Product
OpenSCAD CAD + static three.js viewer for a **seed-tape making machine** (v2). No build, no tests, no CI, no README. Live preview: `http://localhost:9099/`.

## Core functionality

### Machine (CAD — `seed_tape_machine_v2.scad`)
- Builds the full assembly: chassis, hopper, drum/cartridge, plow (six-turner), tape path + former collar, cradle, twister (free spin, no X drift) + static twister axle + support, pull rollers a/b + bridge, takeup, crank. Tape feeds from off-machine supply (spool cones removed v121; spool rod stays).
- The whole chassis extends 30 mm east at the take-up end while its west edge stays at X=-34, changing its length from 304 to 334 mm and its east edge from X=270 to X=300. The floor, fixed north wall, and removable south wall extend together.
- The take-up is at CAD (274,50), near the extended chassis east edge; its flange is exactly 10 mm from the X=300 chassis edge. Flat tape remains unchanged through X=220; only the wind-up leader endpoint and its pack attachment metadata change, ending at (272.5,42.5) inside the radius-8 pack. Take-up rotation remains -2× crank speed. The existing tape path, gears, gearwall, plow, pull, and take-up remain unchanged; the only hopper addition is the pair of thick support bosses described below.
- Drive: crank → drum gear mesh (module 2, fail-loud mesh distance); crank shaft runs through the crank-gear bore, handle stands 20 off the wall. Live train: crank20 → A[10+30] (-2x) → idler 15T (+4x) → B[10+bev36] (-6x) → twister bevel 36T (+6x = 2.0 wraps/seed) via 45° mitre at apex (155,34,32). The outboard has four distinct screwable wall supports with inside-driven M3 interfaces; its plate extends east to X234 and down to Z20, carrying A + idler + B tips (2 deep); functionless inboard shaft stubs are cut. Seed rate unchanged at 3 seeds/crank rev.
- Feed path: hopper drop → plow forms/folders tape → twister orients seed pocket → pull/takeup advance tape. Clearances asserted fail-loud on every stack-up.
- A separate printed U guide sits under the seed-exit pipe. Its floor is 0.3 mm above the current flat tape, its rail inner faces are 2 mm from the Ø11.4 pipe OD, and its floor-to-pipe-bottom gap is 10.7 mm.
- The guide uses one separate right bracket printed twice and mirrored left/right. Each bracket uses two M2x8 socket-head screws, with deliberate M2 interfaces: Ø2.4 clearance holes, 4.4 mm-AF nut traps 1.7 mm deep, and at least 1 mm of surrounding material.
- Two thick bosses are fused into the hopper structural material, never into the 1.2 mm pipe wall; the bosses and both brackets clear the pipe, funnel, tape, drum, flange, and each other. The guide, right bracket, and left bracket each have their own viewer control, and the procedural duplicate is removed.
- The seed tape folds once, under the seed dropper, instead of near a roller: it runs flat to X81, folds over X81..91 into a full U, and stays a stable U to X100 where the seeds drop in. From X100 to X114 the U closes into a rolled packet (bore 7.1 mm, outer 7.9 mm, wrapping far enough to lap 28° over itself, so no slit is left), and a constant packet runs from X114 to X220. The packet's size comes from the 25.4 mm paper width, not from the seed, so the six-turner exit stays at its 8.6 mm clear bore and the pipeline cannot be narrowed further to chase a smaller seed. The six-turner's exit throat is re-tapered to that 8.6 mm bore, because its previous 3.15 mm throat no tape could pass.
- A new printed part, the U-former, is a bolted die the tape forms through: it sits at world X81..91, uses one M2x6 screw per side with a counterbored head and a hex nut trap in the bracket pad it bolts to, and is printed rotated 90° about X so it needs no support. Second accepted M2 deviation from the `m2_min_surrounding = 1.0` rule (the first being the M2 hardware values themselves, above): the hex nut trap cut into the bracket pad leaves 0.76 mm of material at the CORNERS in X (the Z corners give 1.06 mm, and the flats carry 1.1 mm), because the pad was widened in Z only. The nut loads on its flats, where the 1.1 mm wall is what carries the load; the corners are not structural, they only stop the pocket from splitting the pad circumferentially. The drop pipe widens to ID 9.0 / OD 11.4 so a real ~3 mm seed falls through freely. The existing U guide gains a fused seed cap — a lid over the U that stops seeds jumping back out — sitting 0.9 mm above the U top and stopping 0.4 mm below the pipe.
- The gears, plow, take-up, chassis, drum, and the guide/bracket/boss arrangement are unchanged. General machine stack clearances use `tol=0.3`; the specified M2 values are the documented researched exception.
- Plow mounting uses vertical underside screws at world (132,9) and (153,62); the long wall-reaching support is not used.
- The static twister axle uses a minimal fused Γ support whose wall and floor legs meet at the axle center, with local wall/floor M3 pilots; no Z7 support interfaces remain, and the south rib remains.
- The take-up-facing east funnel flare at source X172..175 is absent; the main OD15/ID10 tube remains straight and open at that end. The west/hopper-facing retaining nose is unchanged, with an r5.5 tip, r9 shoulder/barb, C-slot, and two flex legs.
- CAD conventions: `$fn=60` curves and `tol=0.3` for general machine stack clearances; the specified M2 values are the documented researched exception.
- Single-object isolation: changing one part must not silently alter others.
- Fail-loud OpenSCAD asserts for gaps, coplanarity, sweeps, and stack-ups.

### Special GLB exports
- Removed v121: spool cones (tape feeds from off-machine supply).
- `rollers_lower` / `rollers_upper`: split from fused `pull_rollers()` for independent viewer pivots.

### Viewer (`web/`)
- `PART_DEFS` + per-part pivots + `SCHEME` colors; loads `stl/*.glb` only (never `.stl` in previews).
- Every part has its own preview toggle (one checkbox per part id, auto-created).
- Vendored `three.min.js`, `GLTFLoader.js`, `OrbitControls.js` — never CDN-swap.
- Cache bust `?v=N` on GLB/script URLs; bump `ASSET_V` when regenerating assets.
- Animated assembly preview for user review on port **9099** only.
- `web/vNN/` snapshots: only `index.html`, `js/`, `stl/*.glb`.

### Printable parts (`print/`)
- Every object has its own separate `.stl` file (one per part, oriented flat, `min_z=0`); parts assemble into the full machine (fused shaft clusters, wall-bore cantilevers, rail + pedestal supports; demo-load overhangs documented in code).
- `print/*.stl` are generated artifacts — rebuild via `./regenerate_glbs.sh`, never hand-edit.

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
