# AGENTS.md — vseedtaper

## What this repo is
- OpenSCAD CAD + static three.js viewer. No build, no tests, no CI, no README.
- `seed_tape_machine_v2.scad` (1136 lines) is current. `seed_tape_machine.scad` is v1 — DO NOT MODIFY.
- `web/` = v2 viewer, `web/backup/` = v1 viewer. Only dep: `playwright` (see `package.json`).

## Commands (exact)
- Serve v2: `python3 -m http.server 9099 --directory web`
- Check: `curl -s -o /dev/null -w "%{http_code}" http://localhost:9099/index.html` and `.../backup/index.html`
- Codegen GLBs: `./regenerate_glbs.sh` — needs `xvfb-run -a` + openscad 2021.01 + `python3 trimesh` (STL→GLB).
- Verify viewer: `node verify_*.js` — Playwright headless with `--no-sandbox`.

## Architecture
- CAD: `part_to_render` var selects part; `regenerate_glbs.sh` sed-swaps it per part, exports STL via openscad, converts to GLB via trimesh.
- Special exports: `cone_a`/`cone_b` (single_cone ± offset), `rollers_lower`/`rollers_upper` (split from fused `pull_rollers()` for independent pivots).
- Viewer (`web/index.html`): `PART_DEFS` list + per-part pivots + `SCHEME` color mapping loads `stl/*.glb`.
- `web/js/three.min.js`, `GLTFLoader.js`, `OrbitControls.js` are vendored — never CDN-swap.
- Cache bust via `?v=2` on GLB/script URLs — bump when regenerating.
- `web/stl/*.glb` (+ some `.stl`) are generated artifacts — rebuild, don't hand-edit.

## Gotchas — do not violate
- Never edit v1 scad or `web/backup/` except to restore.
- 10. **Playwright screenshots: `screenshots/` only, never in git, max 25.** Keep all Playwright screenshots in `screenshots/` folder, ensure it is gitignored, and auto-delete oldest files when count exceeds 25.
- Playwright browser reuse: verify scripts use `playwright_pool.js` (one shared browser, idle-kill after 10min). Never `browser.close()` per script — use `pool.releaseBrowser(browser)`. Full teardown only via `node playwright_pool.js stop` (does the pkill); check `node playwright_pool.js status` before starting new session.
- Serve on port 9099 only (iptables rule); don't change port.
- CAD conventions: `$fn=60` for curves, `tol=0.3` (`tolerance`, clearances derive from it) — keep both.

## Workflow (mandatory, condensed from prior AGENTS.md)
- Requirements-first: tune REQUIREMENTS.md before code; every edit bumps version (vN→vN+1) + changelog entry; commit & push before editing requirements.
- Live animating preview for every change + snapshot checks while animating; layman wording to user; short messages; fix loop max 3 iterations then ask; max parallelism, never let browsers pile up.
