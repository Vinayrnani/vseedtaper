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

## Gotchas — do not violate
- **No repeated tool calls / no repeated work (STRICT):** never issue the same tool call, command, grep/read, or other action more than **2 times** with the same result. Attempt once; if it fails or is a no-op, change the approach on the second attempt; after **2 identical attempts** STOP immediately — do not loop, do not re-try a third time — and report the blocker + partial results. Applies to every agent (orchestrator, plan, coder, reviewer, general, vision).
- Never edit v1 scad or `web/backup/` except to restore.
- **Single-object isolation:** when altering one object/part/file, do not touch other objects without user permission — and if a change truly requires touching another object, stop and explain to the user *why* it must be touched (get permission first).
- OpenSCAD: **nightly only** (`openscad-nightly`, manifold headless). Never use `openscad` 2021.01, `xvfb-run`, or any Xvfb fallback — regenerate_glbs.sh fails loud if nightly is missing; keep that behavior.
- 10. **Playwright screenshots: `screenshots/` only, never in git, max 25.** Keep all Playwright screenshots in `screenshots/` folder, ensure it is gitignored, and prune oldest by file modification time (max 25) via `scripts/cleanup-screenshots.sh`.
- Playwright browser reuse: verify scripts use `playwright_pool.js` (one shared browser, idle-kill after 10min). Never `browser.close()` per script — use `pool.releaseBrowser(browser)`. Full teardown only via `node playwright_pool.js stop` (does the pkill); check `node playwright_pool.js status` before starting new session.
  Repo workaround (globals untouched): reviewer judges screenshots+code (read-only); coder/general executes node verify_*.js via pool to produce screenshots for reviewer.
  Coder never interprets images, reviewer never runs shell beyond reading.
- Serve on port 9099 only (iptables rule); don't change port.
- CAD conventions: `$fn=60` for curves, `tol=0.3` (`tolerance`, clearances derive from it) — keep both.
- Preview folders (`web/v*/`) must contain only `index.html`, `js/`, `stl/*.glb` — never commit or keep `.stl` intermediates there; the viewer loads GLB only.

## Workflow (mandatory, condensed from prior AGENTS.md)
- Requirements-first: tune REQUIREMENTS.md before code; every edit bumps version (vN→vN+1) + changelog entry; requirements edits stay uncommitted until final user approval — never commit/push requirements separately.
- Live animating preview for every change + snapshot checks while animating; layman wording to user; short messages; fix loop max 2 iterations then ask; **never repeat the same tool call/action more than 2 times** (same call same result → stop and report after 2); max parallelism, never let browsers pile up.
- **Per-version snapshot:** on every successful version advance (vN→vN+1), copy working `web/index.html` + `web/js/` + `web/stl/*.glb` into `web/vNN/` (GLB only, never `.stl`) before proceeding — keeps a live preview per version at `http://localhost:9099/vNN/`; snapshot stays uncommitted until final user approval.
- NO commit/push without explicit user APPROVE — reviewer PASS alone never authorizes committing.

## Delivery flow (mandatory)
1. Requirements first: capture/tune in REQUIREMENTS.md, bump version (vN→vN+1) + changelog entry; requirements edits stay uncommitted until final user approval — never commit/push requirements separately.
2. Plan the change with the **`plan` agent** (not general/scribe); load `plan-protocol`. A reviewer must APPROVE the plan (APPROVE/REJECT with reasons) before implementation.
3. Implement ONE change at a time: live animating preview + screenshots per change; user visually inspects and confirms before the next change. Single-object isolation: don't touch other objects without user permission + why.
4. Reviewer verifies the implementation against the requirements; on FAIL, redo (max 2 verify/fix loops), then escalate to user. Reviewer PASS alone does NOT authorize committing; code stays uncommitted + live preview + screenshots.
5. No commit/push after reviewer PASS; prepare per-version snapshot web/vNN/ (index.html + js/ + stl/*.glb only) as uncommitted work.
6. Present to user in plain layman wording, short messages.
7. Final rule: ONE single commit + push covering REQUIREMENTS.md (version bump + changelog) + code + web/vNN/ snapshot + ASSET_V bump, ONLY after explicit user APPROVE. Never two separate commits. Never commit/push on reviewer PASS alone.

Condensed: Requirements → plan (`plan` agent, reviewer APPROVE) → implement one change at a time → reviewer verify (max 2 loops) → ONE commit+push only after user APPROVE.

## Delegation to coder (small context)
The `coder` subagent runs on mimo 2.5 with a SMALL context window. Therefore the orchestrator must ALWAYS split implementation work into small sequential self-contained tasks (one file area / one change per task). Each delegated task must include: working directory, exact file path + line hints, the precise old→new change, done criteria, stop conditions (stop before commit unless told), and which files must NOT be touched. Never send coder a multi-phase epic in one task; chain small tasks instead. Reviewer tasks stay read-only and single-scope.

## Modularity (1k lines/file)
Keep ALL code modular — every source file (SCAD, JS, HTML, scripts) max ~1000 lines where feasible. Split by responsibility: web viewer (index.html) splits into modules (e.g. scene setup, part defs, pivots/animation, legend/UI, verify hooks) loaded from web/js/; SCAD splits per-part with shared params; no new monolith growth. Each split must be behavior-preserving (same render output / same viewer behavior) with its own verify pass. One split = one versioned change: requirements entry, reviewer PASS, regen/verify if GLBs affected, web/vNN/ snapshot, commit+push.

## Prior-code references (approval gate)
Agents must consult previous code/snapshots/history (git show, web/vNN/, old commits) ONLY when the user's request relates to that prior work. Any other backward-looking digging (exploring old versions out of curiosity, pulling references for unrelated changes) needs the user's explicit approval first. Forward work always uses live HEAD facts, re-verified by grep — never pasted line numbers from earlier sessions.

## Parallelism (split + parallelise to save time)
Always maximise parallel execution. Independent work runs in parallel — multiple tool calls per block, parallel subagents for independent scopes. Split large work into small self-contained tasks that can run concurrently; go sequential ONLY where a task depends on another's output. One owner per task — never two agents on the same in-flight task; others wait or take different scopes. For coder (small context) each parallel split must still be fully self-contained (own goal, file:line, done criteria). Batch independent greps/reads/verifies; never serialize what can run together.

## Skills (mandatory load)
Every subagent must load skills MANDATORILY before starting work. The orchestrator names the required skill(s) in each task; the worker loads them first and states `Skills loaded: <names>` in its first progress note. No work counts as started until receipt is stated. If skill load fails, stop with BLOCKED: skill <name> failed, don't proceed.
Trigger table (repo-only, globals untouched):
- SCAD/.scad/STL->GLB work -> `openscad` + `code-philosophy` in that order
- Viewer JS/HTML/CSS -> `frontend-philosophy`
- Regen/pool/verify scripts -> `code-philosophy`
- Plan/audit/diff -> `plan-protocol` (planning work is delegated to the **`plan` agent**, not general)
- Review/verify -> `code-review`
Reviewer rejects if receipt missing.

## Docs tasks go to general
All documentation/writing tasks (requirements, changelog, AGENTS.md edits, commit messages) are delegated to the `general` subagent, NOT `scribe`.
**Planning is NOT a docs task** — implementation plans go to the **`plan` agent** with `plan-protocol`.
Rationale: general has full shell/git access and reliably completes pushes; scribe's restricted git caused stalled half-pushes.