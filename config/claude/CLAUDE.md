# Global Claude Instructions

Single source of truth for every machine. Lives in `herdr-claude-setup` and is
symlinked to `~/.claude/CLAUDE.md` — edit it here, not there.

## Git Workflow (mandatory)

Mandatory cycle for **any** change (feature/fix/whatever) in a git repo:

1. **Start from a clean `main`.** If `git status` is not clean, **STOP and notify
   the user** — touch nothing. If clean: `git checkout main && git pull`.
2. **Own branch:** `git checkout -b feat/<whatever>`. Never work directly on `main`.
3. **Changes + iterative commits** on the branch (as many as needed, or none if N/A).
4. **Close onto `main`:** 1 commit → fast-forward merge; several → squash into one.
   Then push and delete the branch. A new cycle starts from step 1.

`main` is always deployable.

## Agent fan-out budget

**Max 6 agents per fan-out.** Applies to Workflow scripts and parallel `Agent`
calls alike — count total agents across the whole run, not per stage (a nested
`parallel` inside a `pipeline` multiplies invisibly: one planning question once
cost 51 agents / 2.3M tokens). Need more? Ask first, or run sequentially.

## Context & Token Hygiene (mandatory)

**Why:** every API request re-reads the entire context at the cache-read rate,
and a working session makes thousands of them. Measured across 1,023
transcripts on the 3090 box (2026-07, **$5,239**): cost per request climbs from
**$87 per 1k requests** at 25-50k context to **$164** at 175-200k — about
**$0.51 per 1k requests for every 1k tokens** parked in context. Context grows
only ~900 tokens per request (median), so compaction is cheap and *carrying*
context is not. That single fact drives all the rules below.

**How the window actually splits** (run `/context` to see it for real):

```
W  =  overhead O  +  0.30·W autocompact buffer  +  messages
```

`O` = system prompt + tools + custom agents + **memory files** + skills. It is
paid on every request and is invisible until you look. So working room is
`R = 0.70·W − O`, and the post-compact base is `B ≈ O + 0.21·W`
(138 observed resets; B is *not* a fixed fraction of W and *not* a constant).

1. **Never dump raw search output into main context.** Tighten the command
   first — `grep -l` / `-c` / `head -50` instead of full matches, `Read` with
   `offset`/`limit` instead of whole files. A 46k dump costs ~4.6k *per
   subsequent request*.
2. **Route open-ended sweeps through a subagent.** "Where is X", "what calls
   Y", "map this directory", "does this pattern appear anywhere" → `Explore`
   or `caveman:cavecrew-investigator`. They read the files and return a
   `file:line` digest; the bulk never enters main context. Break-even is ~7
   requests, so this is a win on anything non-trivial.
3. **`/clear` on task switch, `/compact` only mid-task.** Compaction is cheap
   (summary output ~1.4k); carrying a stale 100k context is the expensive
   thing, not resetting it. Autocompact stays **on** — it is the safety net
   that stops a session drifting up to the model's 1M limit, which is the most
   expensive place to be. If it fires so often a session feels unusable, that
   is rule 5 talking, not a reason to disable it.
4. **Cut overhead before touching `autoCompactWindow`.** A token of `O` removed
   buys a full token of room *and* comes off every request's bill; a token of
   window buys only 0.70 of a token and *adds* to the bill. Raising the window
   "to avoid compaction" is a false economy — compaction is cheap. `W` stays
   110k on every box, which puts average live context at ~74k, the top of the
   cheap band. There is also a hard floor: below `W = O / 0.70` a session
   compacts on turn one, forever (jetson `O` = 41.7k → floor **60k**), and it
   gets unusable well before that.
5. **Memory files are overhead, and `/memory` loads the whole directory.**
   Not just `MEMORY.md` — every file in it, relevant or not. On jetson that is
   18 files = **19.9k tokens = 48% of `O`**, re-read on all ~6,300 requests of
   a long session ≈ **$64 for one conversation**. Prune stale memories, keep
   project `CLAUDE.md` under ~5k tokens, and check `/context` when a session
   feels cramped.
6. **Pick the subagent model per stage.** Measured cost per agent: `sonnet-4-6
   $0.88`, `haiku-4-5 $1.17`, `opus-4-8 $3.55`, `opus-5 $4.10`, `fable-5
   $10.28`. Sonnet for finders, scanners and verifiers; inherited Opus only
   for final synthesis and tie-break judging; **Fable only when explicitly
   asked** — it is ~12× a Sonnet agent. Effort: `high` on Sonnet reasoning
   agents, `low` on mechanical stages (grep, collect, transform) where high
   effort only buys extra tool calls.
   **In `Workflow` scripts, write `{model: 'sonnet', effort: 'low'}` on every
   `agent()` call by default** — omitting `model` means `inherit`, so an
   `opus[1m]` session silently fans out Opus agents at ~4.7× the cost, and an
   ultracode run is where that multiplies. Raise a stage off the default only
   deliberately: `effort: 'high'` for a stage that must reason, `model` left
   off (inherit) only for final synthesis or tie-break judging. This is a
   `Workflow`-only rule — plain `Agent` calls (Explore, forks, one-off
   investigators) keep inheriting the session model.
7. **Keep subagent prompts small.** Subagents average 41k context, p90 88k.
   They inherit whatever you hand them; hand them less. **In the long sessions
   the fanout is the majority of the bill, not the conversation:** across the
   14 biggest sessions on record the split is main 54% / subagents 46%, and in
   the single largest (`jetson/390e9ce7`, $1,620) it is 45% / 55% — 228 agents
   at 70k average context, none on a cheap model. Tier the models before
   touching any window setting.
8. **Fan out wide, verify narrow.** Within the 6-agent budget above, spend it
   on distinct lenses, not redundant refuters. Verification cost is
   `findings × voters` and explodes; 2-3 lenses is enough.
9. **Never switch the main-loop model to save money.** A model switch
   invalidates the prompt cache and costs more than it saves. Spawn a cheaper
   subagent instead.

## Python Projects

- **Always use `uv`** for every Python project — environment creation, Python version management, dependency installation, and running scripts. Do **not** use bare `pip`, `python -m venv`, `pyenv`, `virtualenv`, `poetry`, `pipenv`, or `conda`.
- **If `uv` is not installed**, install it first (then carry on):
  ```bash
  curl -LsSf https://astral.sh/uv/install.sh | sh   # or: pipx install uv / brew install uv
  ```
- **Always work inside a project-local virtual environment.** Never install packages globally. uv creates and uses `.venv/` in the project automatically.
- Standard setup for any new Python project:
  ```bash
  uv init --python 3.12        # creates pyproject.toml + .python-version (pins the version)
  uv venv                      # creates the project-local .venv
  uv add <packages>            # adds deps to pyproject.toml AND installs them
  ```
- Day-to-day usage:
  ```bash
  uv add <pkg>                 # add a dependency (use `uv add --dev <pkg>` for dev-only)
  uv remove <pkg>              # remove a dependency
  uv sync                      # install/lock everything from pyproject.toml + uv.lock
  uv run <cmd>                 # run a command/script inside the venv (no manual activation needed)
  ```
- **Track dependencies in `pyproject.toml`** and commit the `uv.lock` lockfile for reproducible installs.
- Add `.venv/` to `.gitignore` if not already present.

## Markdown to PDF Conversion

Always use the `md-to-pdf` launcher to convert `.md` files to PDF. Never use
other methods. It is on `PATH` on every machine (`~/.local/bin/md-to-pdf` ->
`~/md-to-pdf/src/md-to-pdf`) and runs the converter inside that repo's own venv.

```bash
md-to-pdf file.md
```

## Godot + Spine2D + Claude Setup

Reproducible game-dev rig. **Read `~/spine-godot-setup/MANUAL.md` first** on any
Godot/Spine/spine-godot task — it has the installed paths, the `godot-new`
scaffolder, MCP wiring and version rules. Domain truths (spine-godot API, MCP
gotchas, export pipeline) live in `~/spine-godot-setup/knowledge/`; read the
relevant file before Spine/MCP work and commit new discoveries there, not in a
project's CLAUDE.md.

- Repo: https://github.com/jfdg01/spine-godot-setup (`~/spine-godot-setup`) — `./setup.sh` rebuilds it on any Ubuntu box.
- Architecture + integration research: `~/spine-godot-setup/RESEARCH.md`.
- Pinned versions (all Spine major.minor **4.3**): Godot **4.7-stable**, spine-godot runtime **4.3**, Spine editor **4.3.23 Professional** (paid, not redistributable).
- Edition is **Spine Pro**, not Essential — assume Pro-only features are available: meshes, weights, IK/transform/path/physics constraints, and **sliders** (4.3, Pro-only). Verify with `~/Spine/Spine.sh -v`, which prints the version + edition.
- Claude↔Godot = `godot_ai` MCP (hi-godot/godot-ai, HTTP `127.0.0.1:8000/mcp`, needs `uv`, editor must be open). Claude↔Spine = Spine CLI `~/Spine/Spine.sh` (no MCP). Spine→Godot = 4.3 GDExtension, force reimport.
- Rule: keep Spine editor + exports + spine-godot all on **4.3.x**; JSON exports use `.spine-json` (never `.json`), prefer binary `.skel`.
