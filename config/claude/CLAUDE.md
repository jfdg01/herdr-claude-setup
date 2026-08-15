# Global Claude Instructions

Source of truth for every machine. Lives in `herdr-claude-setup`, symlinked to `~/.claude/CLAUDE.md` — edit here, not there.

## Git Workflow (mandatory)

Every change in a git repo:

1. **Clean `main` first.** `git status` not clean → **STOP, notify user**, touch nothing. Clean → `git checkout main && git pull`.
2. **Own branch:** `git checkout -b feat/<whatever>`. Never work on `main`.
3. **Commit iteratively** on the branch. Read the branch name before every commit — it can move under you between my words. On `main`? Stop and say so.
4. **Review gate — I read every commit before it lands.** Approval is **per commit**, not per branch. Push, hand me the link to the new commit, then **stop and wait**:

   ```bash
   git push -u origin HEAD
   echo "$(gh repo view --json url -q .url)/commit/$(git rev-parse HEAD)"
   ```

   I reply **approved**, or I tell you what to change. Changes → back to step 3, and the fix is a **new commit**: push it and hand me *that* commit's link. Never a compare link — it re-renders what I already read. Loop until no line that will land carries a **no** from me, or no word at all.

   - **Several new commits since my last word?** One link each, oldest first, naming the files each one touches.
   - **A fix that rewrites an already-approved commit:** say so, and offer the full diff. That is the one case where rereading is the point.
   - **A fix on top of a commit I rejected:** name the commit it replaces. That commit needs no yes of its own — step 6 squashes the branch, so a line I rejected reaches no tree I keep. The replacement needs the word. Part of the rejected commit survives into the end state? Name that part, and ask for a word on it alone. Never let it ride on the fix.
   - **Amend, or a commit on top?** Small, local fix → on top. The commit is wrong as a whole → amend it, force-push the branch, hand the new link. Nothing in it was approved, so no reread happens, and a commit on top would hand me a diff of a diff. Test: does the fix read on its own?
   - **Never close onto `main` without that word.** Silence is not approval.
   - **No shortcut skips this.** `fc` and any other "do the whole cycle" alias stops here too.
   - No GitHub remote or no `gh` → give me `git show HEAD | delta -s` instead and still wait.
5. **Restart what still runs the old code.** Approved, and the change does not reach a running process on its own — a server, a daemon, a watcher with no reload — restart it now, before you report. Use the project's own start script when it has one. Then say what you restarted and how you checked it answers. A page still serving the old code is a change I read as broken.
6. **Close onto `main`:** 1 commit → fast-forward; several → squash to one. merge and delete branch. **The commit that closes gets no link.** Its content is what I already approved, so handing it over is a reread with nothing new in it — that is the busy work step 4 exists to stop, not to create. Exception: a conflict you resolved by hand *is* new content and gets its link. Report the close, do not ask about it.
7. Push `main` only if instructed. Next change restarts at step 1.

`main` is always deployable.

**Why step 4 exists:** I went hands-off and the quality rotted. The link is where I get back in. Treat it as the expensive step, not a formality.

**Why per commit:** a compare link grows every time you push a fix, so asking for one change made me reread everything I had already approved. Reviewing costs attention, and rereading spends it on nothing. One commit, one link, one decision.

**Why the line test:** a commit is how lines reach me for one read. It is not a unit of consent. A commit I rejected can never earn a yes — every fix is a new commit — so "loop until every commit is approved" deadlocks. Lines land, SHAs do not.

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
