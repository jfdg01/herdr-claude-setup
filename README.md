# herdr-claude-setup

My terminal + Claude Code workflow, reproducible on a fresh Ubuntu box. Run
`./setup.sh` and get the exact visual + workflow combo I settled on.

This repo is the **single source of truth for Claude config across every
machine** (laptop + 3090 box). The config files are *symlinked* out of here,
not copied — so Claude Code's own writes (`/effort`, plugin installs) land in
the repo and `git diff` is the drift detector.

## What it sets up

- **ghostty / herdr** terminal — gruvbox dark theme, agent panel sorted by
  spaces (`config/ghostty/config.ghostty`, `config/herdr/config.toml`). herdr
  is a TUI, so it renders in a host terminal; **JetBrains Mono 14** is set on
  gnome-terminal's default profile and the font ttfs ship in `config/fonts/`.
- **Claude Code CLI** with:
  - a **global `CLAUDE.md`** — git workflow, agent fan-out budget, context &
    token hygiene rules, uv-only Python, md-to-pdf, Godot/Spine pointers.
  - **slash commands** (`config/claude/commands/`) — `/new-doc`, `/open-terminal`.
  - **caveman** + **ponytail** plugins (terse output, laziest-that-works),
    plus `frontend-design`.
  - custom **statusline** — `user@cwd`, model/effort, git branch, token count
    with % to autocompact (read live from `settings.json`, project override
    first), and 5h/weekly usage.
  - **autocompact** tuned: enabled, **110k** window — see the hygiene section
    of `CLAUDE.md` for the measurement behind that number.
  - opus[1m], `medium` effort, `dontAsk` permissions, remote control at startup.
- **claude shell alias** — `--dangerously-skip-permissions --remote-control`
  (`config/shell/aliases.sh`, sourced from `~/.bashrc`).
- **GNOME night-light** — always on, 4000K, dark color-scheme.

## Install

```bash
./setup.sh            # everything applicable to this machine
./setup.sh claude     # only the Claude config (headless boxes, e.g. the 3090)
```

Idempotent — safe to re-run. Any pre-existing real file is backed up to
`<file>.bak-<timestamp>` before being replaced with a symlink. Needs `jq` for
the statusline (`sudo apt install jq`).

## Layout

```
config/ghostty/config.ghostty       -> ~/.config/ghostty/config.ghostty   (symlink, skipped if no ghostty)
config/herdr/config.toml            -> ~/.config/herdr/config.toml        (copy)
config/claude/CLAUDE.md             -> ~/.claude/CLAUDE.md                (symlink)
config/claude/settings.json         -> ~/.claude/settings.json            (symlink)
config/claude/statusline-command.sh -> ~/.claude/statusline-command.sh    (symlink)
config/claude/commands/             -> ~/.claude/commands                  (symlink)
config/claude/hooks/herdr-agent-state.sh -> ~/.claude/hooks/              (copy — herdr owns it)
```

## Notes

- **What is deliberately not tracked:** `~/.claude/projects` (transcripts —
  122M here, 1.2G on the 3090), `plugins/`, `file-history/`, `uploads/`,
  caches, sockets. Tracking the *directory* would be unmanageable; tracking
  these five files is not.
- `settings.json` is byte-identical on every machine. The herdr `SessionStart`
  hook it declares self-guards (`[ "$HERDR_ENV" = 1 ] || exit 0`), so it is a
  no-op on boxes without herdr.
- **Memory is deliberately not tracked.** It is project-scoped, so sharing it
  would only ever cover sessions started in one directory — this repo holds
  purely global config. Memory stays local per machine.
- Paths are absolute (`/home/gara/...`) — edit if your username differs.
- Godot/Spine-specific setup lives separately in
  [spine-godot-setup](https://github.com/jfdg01/spine-godot-setup); this repo
  is project-agnostic.
