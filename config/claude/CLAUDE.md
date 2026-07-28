# Global Claude Instructions

Source of truth for every machine. Lives in `herdr-claude-setup`, symlinked to
`~/.claude/CLAUDE.md` — edit here, not there.

## Git Workflow (mandatory)

Every change in a git repo:

1. **Clean `main` first.** `git status` not clean → **STOP, notify user**, touch
   nothing. Clean → `git checkout main && git pull`.
2. **Own branch:** `git checkout -b feat/<whatever>`. Never work on `main`.
3. **Commit iteratively** on the branch.
4. **Close onto `main`:** 1 commit → fast-forward; several → squash to one. Push,
   delete branch. Next change restarts at step 1.

`main` is always deployable.

## Agent fan-out budget

**Max 6 agents per fan-out**, counted across the whole run, not per stage —
`parallel` nested in `pipeline` multiplies invisibly (one planning question cost
51 agents / 2.3M tokens). Need more? Ask first, or run sequentially.

## Context & Token Hygiene (mandatory)

**Why:** every request re-reads the whole context at cache-read rate. Measured
over 1,023 transcripts (3090 box, 2026-07, $5,239): **$87 per 1k requests** at
25-50k context vs **$164** at 175-200k ≈ **$0.51 per 1k requests per 1k tokens
parked**. Context grows only ~900 tok/request, so compaction is cheap and
*carrying* context is not.

**Window split** (`/context` shows the real numbers):

```
W  =  overhead O  +  33k autocompact reserve  +  messages
```

`O` = system prompt + tools + custom agents + `CLAUDE.md` files + `MEMORY.md` +
skills; paid every request. Working room `R = W − 33k − O`; post-compact base
`B ≈ O + 23k` (138 resets at W=110k; not a fixed fraction of W).

The memory *directory* is not resident — individual files cost zero until
recalled. Jetson 2026-07-26: `~/.claude/CLAUDE.md` 4.1k + project `CLAUDE.md`
5.3k + `MEMORY.md` 936 = 10.3k. `/context` lists deferred tools (16.5k) and MCP
(308) but **excludes them from the total** — read the total, not the row sum.

Reserve is a **flat 33k** (`min(max_output_tokens, 20000) + 13000`), not 30% of
W. Shown as "Autocompact buffer" only when autocompact is on *and* the window
comes from an explicit `autoCompactWindow`; autocompact off → flat 3k "Compact
buffer"; window on `auto` → row hidden.

1. **Never dump raw search output into main context.** Tighten first: `grep -l`
   / `-c` / `head -50`, `Read` with `offset`/`limit`. A 46k dump costs ~4.6k
   *per subsequent request*.
2. **Route open-ended sweeps through a subagent.** "Where is X", "what calls Y",
   "map this directory", "does this pattern appear anywhere" → `Explore` or
   `caveman:cavecrew-investigator`; they return a `file:line` digest, bulk never
   enters main context. Break-even ~7 requests.
3. **`/clear` on task switch, `/compact` only mid-task.** Compaction is cheap
   (~1.4k summary); a stale 100k context is not. Autocompact stays **on** — it
   stops a session drifting to the 1M limit, the most expensive place to be.
4. **Cut overhead before touching `autoCompactWindow`.** A token of `O` removed
   buys a full token of room *and* comes off every bill; a token of window buys
   0.70 and *adds* to the bill. `W` stays **143k** on every box (110k real room
   + 33k reserve; average live context ~74k). Hard floor: below `W = O + 33k`
   every session compacts on turn one (jetson `O` = 32.5k → floor 65.5k), and it
   is unusable well before that. Setting clamps to [100k, 1M]. A box drifted off
   143k → put it back.
5. **Prune memories for staleness, never for size.** Deleting memories saves
   nothing (only `MEMORY.md` is resident). A stale memory costs a session acting
   on a rotted fact — `reference-key-docs` cited `results/` for weeks after it
   became `experiments/`. Audit: every path exists, every ID resolves; delete on
   *wrongness*. Keep project `CLAUDE.md` under ~5k tokens — that one is on every
   request. Don't hunt in skills either: plugins carry `SessionStart` hooks, so
   disabling `caveman`/`ponytail` to reclaim ~840 tok also turns the mode off.
   `Messages` runs ~2× all of `O`, so rule 3 is the real lever.
6. **Pick the subagent model per stage.** Use only `sonnet-5` and `opus-5`.
   Never `fable-5`, never `opus-4-8` — opus-5 beats both. Opus costs several
   times a Sonnet agent per run; check current pricing rather than assuming a
   figure. Sonnet for finders, scanners, verifiers, mechanical stages. Inherited
   Opus for **any stage whose output gates real spend** — plan design, adversarial
   critique, synthesis — not just the last one. Gate on what the stage's output
   authorizes, not its position. Effort `high` on Sonnet reasoning stages, `low`
   on mechanical ones (grep, collect, transform) where high effort only buys
   extra tool calls.
   **In `Workflow` scripts write `{model: 'sonnet', effort: 'low'}` on every
   `agent()` call by default** — omitted `model` means `inherit`, so an
   `opus[1m]` session silently fans out Opus at ~4.7× cost. Raise off the
   default only deliberately. `Workflow`-only rule — plain `Agent` calls
   (Explore, forks, one-off investigators) keep inheriting the session model.
7. **Keep subagent prompts small.** Subagents average 41k context, p90 88k; they
   inherit what you hand them. Across the 14 biggest sessions the split is main
   54% / subagents 46%; in the largest (`jetson/390e9ce7`, $1,620) 45% / 55% —
   228 agents at 70k average, none cheap. Tier models before touching any window
   setting.
8. **Fan out wide, verify narrow.** Spend the 6-agent budget on distinct lenses,
   not redundant refuters. Verification cost is `findings × voters`; 2-3 lenses
   is enough.
9. **Never switch the main-loop model to save money.** The switch invalidates
   the prompt cache and costs more than it saves. Spawn a cheaper subagent.

## Python Projects

**Always `uv`** — env creation, Python version, deps, running scripts. Never
bare `pip`, `python -m venv`, `pyenv`, `virtualenv`, `poetry`, `pipenv`,
`conda`. Never install globally; uv uses project-local `.venv/`. Add `.venv/` to
`.gitignore`. Commit `uv.lock`; deps live in `pyproject.toml`.

Not installed: `curl -LsSf https://astral.sh/uv/install.sh | sh`

```bash
uv init --python 3.12   # pyproject.toml + .python-version
uv venv                 # project-local .venv
uv add <pkg>            # add dep (--dev for dev-only); uv remove to drop
uv sync                 # install/lock from pyproject.toml + uv.lock
uv run <cmd>            # run inside the venv, no activation
```

## Markdown to PDF

Always `md-to-pdf file.md`, never another method. On `PATH` everywhere
(`~/.local/bin/md-to-pdf` -> `~/md-to-pdf/src/md-to-pdf`), runs inside that
repo's own venv.

## Godot + Spine2D + Claude Setup

**Read `~/spine-godot-setup/MANUAL.md` first** on any Godot/Spine/spine-godot
task — installed paths, `godot-new` scaffolder, MCP wiring, version rules.
Domain truths (spine-godot API, MCP gotchas, export pipeline) live in
`~/spine-godot-setup/knowledge/`; read the relevant file before Spine/MCP work
and commit new discoveries there, not in a project's CLAUDE.md.

- Repo: https://github.com/jfdg01/spine-godot-setup (`~/spine-godot-setup`) — `./setup.sh` rebuilds it on any Ubuntu box. Research: `~/spine-godot-setup/RESEARCH.md`.
- Pinned (all Spine major.minor **4.3**): Godot **4.7-stable**, spine-godot runtime **4.3**, Spine editor **4.3.23 Professional** (paid, not redistributable).
- Edition is **Spine Pro** — Pro-only features available: meshes, weights, IK/transform/path/physics constraints, **sliders** (4.3). Verify: `~/Spine/Spine.sh -v` prints version + edition.
- Claude↔Godot = `godot_ai` MCP (hi-godot/godot-ai, HTTP `127.0.0.1:8000/mcp`, needs `uv`, editor open). Claude↔Spine = Spine CLI `~/Spine/Spine.sh` (no MCP). Spine→Godot = 4.3 GDExtension, force reimport.
- Keep Spine editor + exports + spine-godot on **4.3.x**; JSON exports use `.spine-json` (never `.json`), prefer binary `.skel`.
