#!/usr/bin/env bash
# Reproducible terminal + Claude Code workflow setup.
# herdr terminal (gruvbox) + Claude Code CLI (caveman + ponytail plugins,
# custom statusline, autocompact tuning) + GNOME night-light.
# Idempotent: safe to re-run.
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
msg() { printf '\n\033[1;34m==>\033[0m %s\n' "$1"; }

# ---- 1. herdr terminal config (theme + ui) ----
msg "Installing herdr config (gruvbox theme)"
mkdir -p ~/.config/herdr
cp "$SELF_DIR/config/herdr/config.toml" ~/.config/herdr/config.toml

# ---- 2. Claude Code settings + custom statusline ----
msg "Installing Claude Code settings + statusline"
mkdir -p ~/.claude
cp "$SELF_DIR/config/claude/settings.json" ~/.claude/settings.json
cp "$SELF_DIR/config/claude/statusline-command.sh" ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
# statusline needs jq
command -v jq >/dev/null || echo "WARN: install jq — statusline needs it (sudo apt install jq)"

# settings.json declares the caveman + ponytail marketplaces and enables the
# plugins; Claude Code fetches them on next launch. Force it now if the CLI is here.
if command -v claude >/dev/null; then
  msg "Pre-fetching Claude plugins (caveman, ponytail)"
  claude plugin marketplace add JuliusBrussee/caveman 2>/dev/null || true
  claude plugin marketplace add DietrichGebert/ponytail 2>/dev/null || true
  claude plugin install caveman@caveman ponytail@ponytail 2>/dev/null || \
    echo "NOTE: plugins install on next 'claude' launch via settings.json"
else
  echo "SKIP: claude CLI not found — install it, plugins load from settings.json on launch"
fi

# ---- 3. claude shell alias ----
msg "Installing claude alias (~/.bashrc)"
if ! grep -qF "alias claude=" ~/.bashrc 2>/dev/null; then
  printf '\n# herdr-claude-setup\nsource "%s/config/shell/aliases.sh"\n' "$SELF_DIR" >> ~/.bashrc
  echo "added alias source to ~/.bashrc"
else
  echo "alias claude already present — left ~/.bashrc alone"
fi

# ---- 4. GNOME night light (warm, always on) ----
if command -v gsettings >/dev/null; then
  msg "Applying night-light + dark theme"
  C=org.gnome.settings-daemon.plugins.color
  gsettings set "$C" night-light-enabled true
  gsettings set "$C" night-light-schedule-automatic false
  gsettings set "$C" night-light-schedule-from 0.0
  gsettings set "$C" night-light-schedule-to 24.0
  gsettings set "$C" night-light-temperature "uint32 4000"
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark
else
  echo "SKIP: no gsettings (not GNOME) — night-light unchanged"
fi

msg "Done. Restart herdr and relaunch claude to pick everything up."
