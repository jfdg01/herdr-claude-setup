# Claude Code: skip permission prompts + enable remote control by default.
alias claude='claude --dangerously-skip-permissions --remote-control'

# Shells spawned by a daemon born in SSH (herdr server) have no DISPLAY, so
# GUI launchers like `code .` exit silently. Point them at the local X session.
[ -z "$DISPLAY" ] && [ -S /tmp/.X11-unix/X0 ] && export DISPLAY=:0
