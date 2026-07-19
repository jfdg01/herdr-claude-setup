#!/usr/bin/env bash
# Gruvbox dark ANSI palette for gnome-terminal — matches herdr's [theme] dark_name = "gruvbox".
# herdr is a TUI: it renders through the host terminal's 16 ANSI colors, so the
# theme name alone isn't enough. Applied to the default profile.
set -euo pipefail

P=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")
[ -n "$P" ] || { echo "SKIP: no gnome-terminal default profile"; exit 0; }
base="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$P/"

gsettings set "$base" use-theme-colors false
gsettings set "$base" background-color '#282828'
gsettings set "$base" foreground-color '#ebdbb2'
gsettings set "$base" bold-color-same-as-fg true
gsettings set "$base" palette "['#282828', '#cc241d', '#98971a', '#d79921', \
'#458588', '#b16286', '#689d6a', '#a89984', '#928374', '#fb4934', '#b8bb26', \
'#fabd2f', '#83a598', '#d3869b', '#8ec07c', '#ebdbb2']"

echo "gnome-terminal default profile -> gruvbox dark palette"
