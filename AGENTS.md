# AGENTS.md — vseedtaper

## What this repo is
- OpenSCAD CAD + static three.js viewer. No build, no tests, no CI, no README.
- `seed_tape_machine_v2.scad` (current v2 scad at HEAD, verify with wc -l) is current. `seed_tape_machine.scad` is v1 — DO NOT MODIFY.
- `web/` = v2 viewer, `web/backup/` = v1 viewer. Only dep: `playwright` (see `package.json`).

## Commands (exact)
- Serve v2: `python3 -m http.server 9099 --directory web`
- Check: `curl -s -o /dev/null -w "%{http_code}" http://localhost:9099/index.html` and `.../backup/index.html`
- Codegen GLBs: `./regenerate_glbs.sh` — needs `openscad-nightly` only (manifold, headless, NO Xvfb / NO openscad 2021.01) + `python3 trimesh` (STL→GLB). If nightly is missing, install `sudo apt-get install -y openscad-nightly` and fail loud — never fall back.
- Verify viewer: `node verify_*.js` — Playwright headless with `--no-sandbox`.

## Architecture
- CAD: `part_to_render` var selects part; `regenerate_glbs.sh` sed-swaps it per part, exports STL via openscad, converts to GLB via trimesh.
- Special exports: `cone_a`/`cone_b` (single_cone ± offset), `rollers_lower`/`rollers_upper` (split from fused `pull_rollers()` for independent pivots).
- Viewer (`web/index.html`): `PART_DEFS` list + per-part pivots + `SCHEME` color mapping loads `stl/*.glb`.
- `web/js/three.min.js`, `GLTFLoader.js`, `OrbitControls.js` are vendored — never CDN-swap.
- Cache bust via `?v=2` on GLB/script URLs — bump when regenerating.
- `web/stl/*.glb` (+ some `.stl`) are generated artifacts — rebuild, don't hand-edit.

## Delivery pipeline (MANDATORY — only path)

```
Requirements
  → plan+analyze (`plan` agent)
  → implement (one change)
  → reviewer screenshots (pool Playwright) + live preview (notify user to look if possible)
  → [if FAIL: implement again → reviewer again]  max 2 fix loops, then ASK USER
  → user APPROVE
  → ONE commit + push (`CHANGELOG.md` entry + code + snapshot)
```

1. **Requirements + changelog split:** `REQUIREMENTS.md` = **readable product functionality only** (not a version log). Version bumps + per-version change notes go **only** to **`CHANGELOG.md`** (renamed from `REQUIREMENTS_CHANGELOG.md`). Both stay uncommitted until final user APPROVE — never commit/push requirements or changelog alone.
2. **Plan + analyze:** delegate to **`plan` agent only** (never `general`/`scribe`); load `plan-protocol`. Plan agent writes AND analyzes (structure, steps, risks, approval path). Reviewer must APPROVE/REJECT the plan before any implementation. `general` never plans or analyzes plans — docs only.
3. **Implement ONE change at a time.** Live animating preview for the user at `http://localhost:9099/`. Single-object isolation: do not touch other objects without user permission + why. User may review the live preview whenever possible.
4. **Reviewer pass:** screenshots via **pool Playwright** (`playwright_pool.js` + `node verify_*.js`; coder/general runs the scripts, reviewer judges images/code read-only). Screenshots are **only for the reviewer's automated review — never shown to the user**. While screenshots run, if the user can review the live preview, notify them to look.
5. **Fix loop:** on reviewer FAIL → implement again → reviewer again. **Max 2 implement→review cycles**, then **stop and ask the user**. Never a 3rd auto-loop. Never repeat the same tool call/action more than 2 times (same call → same result → stop after 2).
6. **User APPROVE:** present short layman wording + live preview. Reviewer PASS alone never authorizes commit.
7. **ONE commit + push** covering `REQUIREMENTS.md` (only if product functionality changed) + `CHANGELOG.md` (vN entry) + code + `web/vNN/` snapshot + ASSET_V bump — only after explicit user APPROVE. Never two commits. Snapshot first: copy `web/index.html` + `web/js/` + `web/stl/*.glb` into `web/vNN/` (GLB only, never `.stl`), uncommitted until APPROVE.

## Gotchas — do not violate
- **No repeated tool calls / no repeated work (STRICT):** never the same tool call, command, grep/read, or action more than **2 times** with the same result. Attempt once; change approach on the second attempt; after **2 identical attempts** STOP — no third try — report blocker + partial results. Applies to every agent (orchestrator, plan, coder, reviewer, general).
- Never edit v1 scad or `web/backup/` except to restore.
- **Single-object isolation:** altering one object/part/file → do not touch others without user permission; if required, stop and explain *why* first.
- OpenSCAD: **nightly only** (`openscad-nightly`, manifold headless). Never `openscad` 2021.01, `xvfb-run`, or Xvfb fallback — `regenerate_glbs.sh` fails loud if nightly missing; keep that.
- **Playwright screenshots:** `screenshots/` only, never in git, max 25, prune via `scripts/cleanup-screenshots.sh`.
- **Screenshots → reviewer automated review only.** User does NOT need screenshots — never send them; user inspects **live preview** at `http://localhost:9099/`.
- Playwright pool: `playwright_pool.js` (one browser, idle-kill 10min). Never `browser.close()` per script — `pool.releaseBrowser(browser)`. Teardown only `node playwright_pool.js stop`; check `node playwright_pool.js status` first. Repo split (globals untouched): coder/general runs verify scripts → reviewer judges screenshots+code read-only. Coder never interprets images; reviewer never runs shell beyond reading.
- Serve on port 9099 only (iptables); don't change port.
- CAD: `$fn=60` curves, `tol=0.3` (clearances derive from it) — keep both.
- Preview folders (`web/v*/`): only `index.html`, `js/`, `stl/*.glb` — never `.stl` intermediates.
- NO commit/push without explicit user APPROVE — reviewer PASS alone never authorizes committing.

## Role matrix
| Role | Does | Does not |
|------|------|----------|
| `plan` | Write + analyze plans (`plan-protocol`) | Edit files, code, commit |
| `general` | Docs only: `REQUIREMENTS.md`, `CHANGELOG.md`, AGENTS, commit msgs | Plan/analyze plans; interpret screenshots |
| `coder` | Small scoped code edits; run `verify_*.js` via pool | Interpret images; commit; plan |
| `reviewer` | Judge screenshots + code (read-only); APPROVE/REJECT | Run shell beyond reading; commit; give user screenshots |
| User | Live preview @ :9099, final APPROVE | — |

## Delegation to coder (small context)
`coder` = small context. Orchestrator splits into small sequential self-contained tasks (one file area / one change). Each task: working dir, exact file path + line hints, old→new change, done criteria, stop conditions (stop before commit unless told), files NOT to touch. Never a multi-phase epic. Reviewer tasks = read-only, single-scope.

## Modularity (1k lines/file)
All source (SCAD, JS, HTML, scripts) max ~1000 lines where feasible. Split by responsibility. Behavior-preserving splits with own verify pass. One split = one versioned change (requirements + reviewer PASS + regen if GLBs + snapshot + commit after APPROVE).

## Prior-code references (approval gate)
Consult git history / `web/vNN/` / old commits ONLY when the request relates to that prior work. Other backward-looking digging needs user approval first. Forward work = live HEAD facts, re-verified by grep — never stale pasted line numbers.

## Parallelism
Maximise parallel execution. Independent work = parallel tool calls + parallel subagents. Sequential only on real dependencies. One owner per task. Coder splits still fully self-contained. Batch independent greps/reads/verifies.

## Skills (mandatory load)
Every subagent loads skills BEFORE work; states `Skills loaded: <names>` in first progress note. No receipt → work not started. Skill load fail → BLOCKED: skill `<name>` failed.
- SCAD/.scad/STL→GLB → `openscad` + `code-philosophy` (order)
- Viewer JS/HTML/CSS → `frontend-philosophy`
- Regen/pool/verify scripts → `code-philosophy`
- Plan / plan-analysis / audit / diff → `plan-protocol` + **`plan` agent only** (never general)
- Review / verify → `code-review`
Reviewer rejects if receipt missing.

## Docs tasks go to general
Docs only: `REQUIREMENTS.md` (product summary), `CHANGELOG.md` (version history), AGENTS.md, commit messages → `general` (NOT `scribe`).
**Planning and plan analysis are NOT docs tasks** — those go to **`plan` agent** with `plan-protocol`. Never send plan work to `general`.
