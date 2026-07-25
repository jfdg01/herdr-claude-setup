# open-terminal

Open a new terminal window running an arbitrary command (defaults to a plain shell).
When launching `claude`, always appends `--remote-control` and
`--dangerously-skip-permissions` so the new session is remotely accessible and runs
without permission prompts.

Optionally, the current agent can compose and pass a **context message** that becomes
the first prompt in the new Claude session — useful when you want the new terminal to
immediately pick up a task from the current conversation.

## Usage

```
/open-terminal                                  # plain bash shell in cwd
/open-terminal --dir /some/path                 # plain bash shell in given dir
/open-terminal claude                           # claude (remote-control + skip-perms)
/open-terminal claude --dir /some/path          # claude starting in given dir
/open-terminal claude --model haiku             # claude on haiku
/open-terminal claude --model opus              # claude on opus
/open-terminal claude "do this task"            # claude with initial message (quoted)
/open-terminal claude --model sonnet "do X"     # claude on sonnet with initial message
/open-terminal claude --dir /p --model haiku "do X"  # dir + model + message
/open-terminal htop                             # any non-claude command (no flags added)
```

## How it works

Claude runs this shell command:

```bash
DISPLAY=${DISPLAY:-:0} gnome-terminal -- bash -c "cd <dir> && <your command>; exec bash" &
```

- `DISPLAY=${DISPLAY:-:0}` — ensures the X11 display variable is set even when called
  from a non-interactive shell.
- `cd <dir> &&` — changes to the requested directory before running the command.
  When no `--dir` is given, defaults to the current working directory (`$PWD`).
- `; exec bash` — keeps the window open with a live shell after the command exits.
- `&` — detaches so Claude's tool call returns immediately.

If `gnome-terminal` is not found, fall back in order: `xterm`, `konsole`, `kitty`,
`alacritty`. Report which one was used.

## Steps

1. **Parse `$ARGUMENTS`:**
   - Extract `--dir <path>` if present; default to `$PWD` (the current working directory).
   - If no remaining args → command is `bash`, no initial message.
   - Otherwise, the first token is the command name.
   - If the command is `claude`:
     - Extract any `--model <value>` flag if present.
     - Treat any remaining non-flag text as the **initial message**.
   - If the command is not `claude` → use the raw remaining arguments as-is.

2. **Build the command string:**
   - For `claude`: always add `--remote-control --dangerously-skip-permissions`.
     Add `--model <value>` if specified.
     If an initial message was provided, append it as a **positional argument**
     (shell-quoted): `claude --remote-control --dangerously-skip-permissions "the message"`.
   - For non-claude commands: use as-is.

3. **Launch:**
   ```bash
   DISPLAY=${DISPLAY:-:0} gnome-terminal -- bash -c "cd <dir> && <cmd>; exec bash" &
   ```
   Where `<dir>` is the resolved directory (absolute path).

4. **Confirm** to the user: report the full command string used (so they can see the
   initial message and flags), the working directory, and note the session is accessible
   via Remote Control from claude.ai/code or the Claude mobile app.

## Agent context-passing (key feature)

When the user says something like *"open a terminal that continues this job"* or
*"open a terminal to finish the setup"*, the current agent should:

1. **Compose a self-contained context message** that gives the new session everything
   it needs: what was accomplished so far, the exact next step(s), relevant file paths,
   commands to run, and any constraints or caveats from the current conversation.
2. **Pass it as the initial message** so the new Claude session starts immediately
   working rather than waiting for user input.

Example constructed command:
```
claude --remote-control --dangerously-skip-permissions "We were setting up llama.cpp on the Jetson (ssh jetson). The build completed but we haven't run the benchmark yet. Please run: ssh jetson 'cd ~/llama.cpp && ./llama-bench -m models/llama-3.2-3b-q4_k_m.gguf' and append the results to results/2026-06-15-setup/README.md following the format in CLAUDE.md."
```

The message should be **complete enough that the new session needs no further
clarification** — treat it like a hand-off note to a colleague who wasn't in the room.
