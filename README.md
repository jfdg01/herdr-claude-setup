# herdr-claude-setup

My terminal + Claude Code workflow, reproducible on a fresh Ubuntu box. Run
`./setup.sh` and get the exact visual + workflow combo I settled on.

## What it sets up

- **herdr** terminal — gruvbox dark theme, agent panel sorted by spaces
  (`config/herdr/config.toml`).
- **Claude Code CLI** with:
  - **caveman** + **ponytail** plugins (terse output, laziest-that-works),
    plus `frontend-design`.
  - custom **statusline** — `user@cwd`, model/effort, git branch, token count
    with % to autocompact, and 5h/weekly usage (`config/claude/statusline-command.sh`).
  - **autocompact** tuned: enabled, 180k window
    (`autoCompactEnabled`, `autoCompactWindow` in `settings.json`).
  - opus[1m], 1M context, `dontAsk` permissions, remote control at startup.
- **claude shell alias** — `--dangerously-skip-permissions --remote-control`
  (`config/shell/aliases.sh`, sourced from `~/.bashrc`).
- **GNOME night-light** — always on, 4000K, dark color-scheme.

## Install

```bash
./setup.sh
```

Idempotent — safe to re-run. Needs `jq` for the statusline
(`sudo apt install jq`).

## Layout

```
config/herdr/config.toml            → ~/.config/herdr/config.toml
config/claude/settings.json         → ~/.claude/settings.json
config/claude/statusline-command.sh → ~/.claude/statusline-command.sh
```

`setup.sh` copies these into place, registers the caveman + ponytail plugin
marketplaces, and applies the night-light gsettings.

## Notes

- `settings.json`'s statusline path is absolute (`/home/gara/...`) — edit if
  your username differs.
- Godot/Spine-specific setup lives separately in
  [spine-godot-setup](https://github.com/jfdg01/spine-godot-setup); this repo
  is project-agnostic.
