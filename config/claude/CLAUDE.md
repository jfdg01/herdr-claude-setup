# Global Claude Instructions

Source of truth for every machine. Lives in `herdr-claude-setup`, symlinked to `~/.claude/CLAUDE.md` — edit here, not there.

## Git Workflow (mandatory)

Every change in a git repo:

1. **Clean `main` first.** `git status` not clean → **STOP, notify user**, touch nothing. Clean → `git checkout main && git pull`.
2. **Own branch:** `git checkout -b feat/<whatever>`. Never work on `main`.
3. **Commit iteratively** on the branch.
4. **Review gate — I read the diff before it lands.** Push the branch and hand me the compare link, then **stop and wait**:

   ```bash
   git push -u origin HEAD
   echo "$(gh repo view --json url -q .url)/compare/main...$(git branch --show-current)"
   ```

   I reply **approved**, or I tell you what to change. Changes → back to step 3, push again, new link. Loop until I say approved.

   - **Never close onto `main` without that word.** Silence is not approval.
   - **No shortcut skips this.** `fc` and any other "do the whole cycle" alias stops here too.
   - No GitHub remote or no `gh` → give me `git diff main..HEAD | delta -s` instead and still wait.
5. **Close onto `main`:** 1 commit → fast-forward; several → squash to one. merge and delete branch.
6. Push `main` only if instructed. Next change restarts at step 1.

`main` is always deployable.

**Why step 4 exists:** I went hands-off and the quality rotted. The link is where I get back in. Treat it as the expensive step, not a formality.

## Agent fan-out budget

**Max 6 agents per fan-out**, counted across the whole run, not per stage — `parallel` nested in `pipeline` multiplies invisibly. Need more? Ask first.

## Naming what I can see

Nothing the reader has not seen may be referenced. Labels, option letters and codenames you invented while reasoning, or that came from a subagent, do not exist for me. Name the thing, not the label.

Relay conclusions in your own words, and gloss any internal term inline on first use.

## Context & Token Hygiene (mandatory)

**Why:** every request re-reads the whole context at cache-read rate. Per measure: compaction is cheap and _carrying_ context is not.

**Window split** (`/context` shows the real numbers):

```
W  =  overhead O  +  33k autocompact reserve  +  messages
```

`O` = system prompt + tools + custom agents + `CLAUDE.md` files + `MEMORY.md` + skills; paid every request. Working room `R = W − 33k − O`; post-compact base `B ≈ O + 23k` (138 resets at W=110k; not a fixed fraction of W).

The memory _directory_ is not resident — individual files cost zero until recalled. `/context` lists deferred tools and MCP but **excludes them from the total** — read the total, not the row sum.

Reserve is a **flat 33k** (`min(max_output_tokens, 20000) + 13000`), not 30% of W. Shown as "Autocompact buffer" only when autocompact is on _and_ the window comes from an explicit `autoCompactWindow`; autocompact off → flat 3k "Compact buffer"; window on `auto` → row hidden.

1. **Never dump raw search output into main context.** Tighten first: `grep -l` / `-c` / `head -50`, `Read` with `offset`/`limit`. A 46k dump costs ~4.6k _per subsequent request_.
2. **Route open-ended sweeps through a subagent.** "Where is X", "what calls Y", "map this directory", "does this pattern appear anywhere" → `Explore`; it returns a `file:line` digest, bulk never enters main context. Break-even ~7 requests.
3. **Prune memories for staleness, never for size.** Deleting memories saves nothing (only `MEMORY.md` is resident). A stale memory costs a session acting on a rotted fact. Audit: every path exists, every ID resolves; delete on _wrongness_. Keep project `CLAUDE.md` under ~5k tokens — that one is on every request. Don't hunt in skills either: plugins carry `SessionStart` hooks, so disabling `caveman`/`ponytail` to reclaim ~840 tok also turns the mode off.
4. **Pick the subagent model per stage.** Use only `sonnet-5` and `opus-5`. Opus costs several times a Sonnet agent per run. Sonnet for finders, scanners, verifiers, mechanical stages. Inherited Opus for **any stage whose output gates real spend** — plan design, adversarial critique, synthesis — not just the last one. Gate on what the stage's output authorizes, not its position. Effort `high` on Sonnet reasoning stages, `low`/`medium` on mechanical ones (grep, collect, transform) where high effort only buys extra tool calls. **In `Workflow` scripts write `{model: 'sonnet', effort: 'low'}` on every `agent()` call by default** — omitted `model` means `inherit`, so an `opus[1m]` session silently fans out Opus at ~4.7× cost. Raise off the default only deliberately. `Workflow`-only rule — plain `Agent` calls (Explore, forks, one-off investigators) keep inheriting the session model unless instructed otherwise.
5. **Fan out wide, verify narrow.** Spend the 6-agent budget on distinct lenses, not redundant refuters. Verification cost is `findings × voters`; 2-3 lenses is enough.

## Python Projects

Applies only to a project that has Python **and** manages dependencies. A project that runs on the stdlib alone, or that must stay dependency-free, needs no environment and no `uv` — do not add one.

Otherwise: **always `uv`** for env creation, Python version, deps, running scripts. Never bare `pip`, `python -m venv`, `pyenv`, `virtualenv`, `poetry`, `pipenv`, `conda`. Never install globally; uv uses project-local `.venv/`. Add `.venv/` to `.gitignore`. Commit `uv.lock`; deps live in `pyproject.toml`.

If not installed curl it.

## Markdown to PDF

Prefer our custom `md-to-pdf file.md`, over another method. On `PATH` everywhere (`~/.local/bin/md-to-pdf` -> `~/md-to-pdf/src/md-to-pdf`), runs inside that repo's own venv.

## Godot + Spine2D + Claude Setup

Working on a Godot / Spine2D / spine-godot project? **ALWAYS read `~/.claude/godot-spine.md` first.** Everything — paths, pinned versions, MCP wiring, export rules — is there.

## On user run commands

When handing a command to the user, `xclip` it to their clipboard as well as showing it to them, don't suggest running with claude's `!` directive since it's faulty.
