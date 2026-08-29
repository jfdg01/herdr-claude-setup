# Claude Code: skip permission prompts + enable remote control by default.
# Also pre-trust $PWD, so the "Quick safety check" folder dialog never appears.
# Claude Code reads trust from projects["<dir>"].hasTrustDialogAccepted in
# ~/.claude.json, one key per directory; there is no global switch. Inheritance
# from a parent directory stops at the git repo root, so seed the cwd itself.
# A failed jq leaves the config untouched.
claude() {
  local c=$HOME/.claude.json t=$HOME/.claude.json.trust.tmp
  jq --arg d "$(realpath "$PWD")" '.projects[$d].hasTrustDialogAccepted = true' "$c" > "$t" \
    && chmod 600 "$t" && mv "$t" "$c" || rm -f "$t"
  command claude --dangerously-skip-permissions --remote-control "$@"
}

# Shells spawned by a daemon born in SSH (herdr server) have no DISPLAY, so
# GUI launchers like `code .` exit silently. Point them at the local X session.
[ -z "$DISPLAY" ] && [ -S /tmp/.X11-unix/X0 ] && export DISPLAY=:0
