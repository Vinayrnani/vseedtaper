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
  → ONE commit + push (`CHANGELOG.md` entry + code; snapshot stays local, never committed)
```

1. **Requirements + changelog split:** `REQUIREMENTS.md` = **readable product functionality only** (not a version log). Version bumps + per-version change notes go **only** to **`CHANGELOG.md`** (renamed from `REQUIREMENTS_CHANGELOG.md`). Both stay uncommitted until final user APPROVE — never commit/push requirements or changelog alone.
2. **Plan + analyze:** delegate to **`plan` agent only** (never `general`/`scribe`); load `plan-protocol`. Plan agent writes AND analyzes (structure, steps, risks, approval path). Reviewer must APPROVE/REJECT the plan before any implementation. `general` never plans or analyzes plans — docs only.
3. **Implement ONE change at a time.** Live animating preview for the user at `http://localhost:9099/`. Single-object isolation: do not touch other objects without user permission + why. User may review the live preview whenever possible.
4. **Reviewer pass:** screenshots via **pool Playwright** (`playwright_pool.js` + `node verify_*.js`; coder/general runs the scripts, reviewer judges images/code read-only). Screenshots are **only for the reviewer's automated review — never shown to the user**. While screenshots run, if the user can review the live preview, notify them to look.
5. **Fix loop:** on reviewer FAIL → implement again → reviewer again. **Max 2 implement→review cycles**, then **stop and ask the user**. Never a 3rd auto-loop. Never repeat the same tool call/action more than 2 times (same call → same result → stop after 2).
6. **User APPROVE:** present short layman wording + live preview. Reviewer PASS alone never authorizes commit.
7. **ONE commit + push** covering `REQUIREMENTS.md` (only if product functionality changed) + `CHANGELOG.md` (vN entry) + code + ASSET_V bump — only after explicit user APPROVE. Never two commits. Snapshot first (local-only, never committed): copy `web/index.html` + `web/js/` + `web/stl/*.glb` into `web/vNN/` (GLB only, never `.stl`). `web/v*/` is gitignored — snapshots stay on disk for local reference, never in git.

## Step-wise execution workflow (MANDATORY for CAD/feature steps)

Load skills before any step work: `code-philosophy`, `openscad`, `openscad-iterative-modeling` (state `Skills loaded: …` first).

- Implement **step by step**: one step at a time. A step is done only after **implementation → per-step final validation → preview output** for that step; then immediately continue the next queued step.
- User may give steps **at any time**, in any order of message arrival, but execute **strictly in order only** (queue arrivals; never skip ahead).
- If the user gives **no step number** or calls it **`feat:`**, treat it as **another step** (assign the next queue slot / label it as a step).
- **Fresh on current code:** each step’s work builds on live HEAD as new work. Do **not** re-read old changelog entries to redo prior steps; do not “continue” an unfinished old attempt as if it were this step.
- **Incorrect step → rollback:** if the user says a step’s work is wrong, **revert to the state immediately before that step**, then **redo the step from scratch** — no patching/adjusting the bad attempt.
- **Continuous chain:** do **not** wait for a “continue/go” prompt between steps. After “Step N done”, start Step N+1 automatically until the queue is empty. Only stop for a genuine user decision.
- **Purge after each step:** clear tool output/logs from the completed step (screenshots prune via `scripts/cleanup-screenshots.sh`; drop temp helpers/caches for that step) before starting the next.
- **Autonomous visual review:** each step is reviewed with **≥3 different angles/ways** (e.g. iso + side + top/close-up, or live preview + PNG views).
- **Isolation while inspecting:** keep **only the objects this step touched** visible; uncheck/hide others for a clear view — **unless** the step’s requirement needs those other objects in frame.
- **Per-step final validation (every step, not only at the end):** order is **implementation → validation → preview**. Before any preview, run the full validation gate for **that step’s** changes — syntax/asserts (`openscad-nightly`), **printability**, **watertight** mesh where applicable, and **minimum gap for moving** pairs (from `tol=0.3`), plus the visual review after preview. Only then report “Step N done”. Do **not** defer validation to the last step or batch it across steps; each step validates itself before the next starts.

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
- Preview folders (`web/v*/`): only `index.html`, `js/`, `stl/*.glb` — never `.stl` intermediates. Local-only, gitignored — never commit/push.
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
All source (SCAD, JS, HTML, scripts) max ~1000 lines where feasible. Split by responsibility. Behavior-preserving splits with own verify pass. One split = one versioned change (requirements + reviewer PASS + regen if GLBs + local snapshot + commit after APPROVE).

## Prior-code references (approval gate)
Consult git history / `web/vNN/` / old commits ONLY when the request relates to that prior work. Other backward-looking digging needs user approval first. Forward work = live HEAD facts, re-verified by grep — never stale pasted line numbers.

## Parallelism
Maximise parallel execution. Independent work = parallel tool calls + parallel subagents. Sequential only on real dependencies. One owner per task. Coder splits still fully self-contained. Batch independent greps/reads/verifies.

## Skills (mandatory load)
Every subagent loads skills BEFORE work; states `Skills loaded: <names>` in first progress note. No receipt → work not started. Skill load fail → BLOCKED: skill `<name>` failed.
- SCAD/.scad/STL→GLB → `openscad` + `code-philosophy` (order); step-wise CAD/feature work also loads `openscad-iterative-modeling`
- Viewer JS/HTML/CSS → `frontend-philosophy`
- Regen/pool/verify scripts → `code-philosophy`
- Plan / plan-analysis / audit / diff → `plan-protocol` + **`plan` agent only** (never general)
- Review / verify → `code-review`
Reviewer rejects if receipt missing.

## Docs tasks go to general
Docs only: `REQUIREMENTS.md` (product summary), `CHANGELOG.md` (version history), AGENTS.md, commit messages → `general` (NOT `scribe`).
**Planning and plan analysis are NOT docs tasks** — those go to **`plan` agent** with `plan-protocol`. Never send plan work to `general`.
