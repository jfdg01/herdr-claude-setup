#!/usr/bin/env bash
# Reproducible terminal + Claude Code workflow setup.
# ghostty/herdr terminal (gruvbox) + Claude Code CLI (caveman + ponytail plugins,
# custom statusline, autocompact tuning, global CLAUDE.md) + GNOME night-light.
# Idempotent: safe to re-run.
#
# Usage:
#   ./setup.sh            # everything applicable to this machine
#   ./setup.sh claude     # only the Claude Code config (headless boxes)
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# non-interactive ssh does not pick this up, and claude lives here
export PATH="$HOME/.local/bin:$PATH"
msg() { printf '\n\033[1;34m==>\033[0m %s\n' "$1"; }

# link <repo-relative-source> <absolute-target>
# Symlink, not copy: Claude Code writes to settings.json (e.g. /effort, plugin
# installs), so the writes land in the repo and `git diff` becomes the drift
# detector. Any pre-existing real file is backed up, never silently replaced.
link() {
  local src="$SELF_DIR/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ] && { echo "ok   $dst"; return; }
    rm "$dst"
  elif [ -e "$dst" ]; then
    mv "$dst" "$dst.bak-$(date +%Y%m%d-%H%M%S)"
    echo "backed up existing $dst"
  fi
  ln -s "$src" "$dst"
  echo "link $dst -> $1"
}

do_herdr() {
  msg "Installing herdr config (gruvbox theme)"
  mkdir -p ~/.config/herdr
  cp "$SELF_DIR/config/herdr/config.toml" ~/.config/herdr/config.toml
}

do_ghostty() {
  if ! command -v ghostty >/dev/null && [ ! -d ~/.config/ghostty ]; then
    echo "SKIP: ghostty not installed on this machine"
    return
  fi
  msg "Installing ghostty config"
  link config/ghostty/config.ghostty ~/.config/ghostty/config.ghostty
}

do_fonts() {
  # herdr is a TUI: its font comes from the host terminal.
  msg "Installing JetBrains Mono"
  mkdir -p ~/.local/share/fonts
  cp "$SELF_DIR"/config/fonts/JetBrainsMono*.ttf ~/.local/share/fonts/
  fc-cache -f ~/.local/share/fonts >/dev/null 2>&1 || true
  if command -v gsettings >/dev/null; then
    P=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'") || P=""
    if [ -n "$P" ]; then
      base="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$P/"
      gsettings set "$base" use-system-font false
      gsettings set "$base" font 'JetBrains Mono 14'
      echo "gnome-terminal default profile -> JetBrains Mono 14"
    fi
  fi
}

do_claude() {
  msg "Linking Claude Code config (shared across every machine)"
  link config/claude/CLAUDE.md              ~/.claude/CLAUDE.md
  link config/claude/settings.json          ~/.claude/settings.json
  link config/claude/statusline-command.sh  ~/.claude/statusline-command.sh
  link config/claude/commands               ~/.claude/commands
  chmod +x "$SELF_DIR/config/claude/statusline-command.sh"


  # herdr owns this file and overwrites it on reinstall, so copy rather than
  # link. It self-guards (`[ "$HERDR_ENV" = 1 ] || exit 0`), harmless off-herdr.
  mkdir -p ~/.claude/hooks
  cp "$SELF_DIR/config/claude/hooks/herdr-agent-state.sh" ~/.claude/hooks/
  chmod +x ~/.claude/hooks/herdr-agent-state.sh

  command -v jq >/dev/null || echo "WARN: install jq — the statusline needs it (sudo apt install jq)"

  # settings.json declares the caveman + ponytail marketplaces and enables the
  # plugins; Claude Code fetches them on next launch. Force it now if present.
  if command -v claude >/dev/null; then
    msg "Pre-fetching Claude plugins (caveman, ponytail)"
    claude plugin marketplace add JuliusBrussee/caveman 2>/dev/null || true
    claude plugin marketplace add DietrichGebert/ponytail 2>/dev/null || true
    claude plugin install caveman@caveman ponytail@ponytail 2>/dev/null || \
      echo "NOTE: plugins install on next 'claude' launch via settings.json"
  else
    echo "SKIP: claude CLI not found — plugins load from settings.json on launch"
  fi
}

do_alias() {
  msg "Installing claude alias (~/.bashrc)"
  if ! grep -qF "alias claude=" ~/.bashrc 2>/dev/null; then
    printf '\n# herdr-claude-setup\nsource "%s/config/shell/aliases.sh"\n' "$SELF_DIR" >> ~/.bashrc
    echo "added alias source to ~/.bashrc"
  else
    echo "alias claude already present — left ~/.bashrc alone"
  fi
}

do_gnome() {
  if ! command -v gsettings >/dev/null; then
    echo "SKIP: no gsettings (headless or not GNOME)"
    return
  fi
  msg "Applying night-light + dark theme"
  C=org.gnome.settings-daemon.plugins.color
  gsettings set "$C" night-light-enabled true
  gsettings set "$C" night-light-schedule-automatic false
  gsettings set "$C" night-light-schedule-from 0.0
  gsettings set "$C" night-light-schedule-to 24.0
  gsettings set "$C" night-light-temperature "uint32 4000"
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark
}

case "${1:-all}" in
  claude)  do_claude ;;
  all)     do_herdr; do_ghostty; do_fonts; do_claude; do_alias; do_gnome ;;
  *)       echo "usage: $0 [all|claude]" >&2; exit 2 ;;
esac

msg "Done. Restart the terminal and relaunch claude to pick everything up."
