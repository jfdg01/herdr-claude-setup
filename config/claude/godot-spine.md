# Godot + Spine2D + Claude Setup

Read this whenever the task touches Godot, Spine2D, or spine-godot. Lives in `herdr-claude-setup`, symlinked to `~/.claude/godot-spine.md` — edit it there, not at the symlink.

## Read order

1. **`~/spine-godot-setup/MANUAL.md` first** — installed paths, the `godot-new` scaffolder, MCP wiring, version rules.
2. **`~/spine-godot-setup/knowledge/`** — domain truths (spine-godot API, MCP gotchas, export pipeline). Read the relevant file before Spine/MCP work.
3. **`~/spine-godot-setup/RESEARCH.md`** — architecture + integration research, when the why matters.

Commit new discoveries to `~/spine-godot-setup/knowledge/`, not to a project's CLAUDE.md.

## Repo

https://github.com/jfdg01/spine-godot-setup (`~/spine-godot-setup`) — `./setup.sh` rebuilds the rig on any Ubuntu box.

## Pinned versions

All Spine major.minor is **4.3**. Godot **4.7-stable**, spine-godot runtime **4.3**, Spine editor **4.3.23 Professional** (paid, not redistributable). Keep editor + exports + spine-godot on **4.3.x** — a mismatch fails at import, not at build.

## Edition

**Spine Pro**, not Essential. Assume Pro-only features are available: meshes, weights, IK/transform/path/physics constraints, and **sliders** (4.3, Pro-only). Verify with `~/Spine/Spine.sh -v`, which prints version + edition.

## Integration map

- Claude ↔ Godot = `godot_ai` MCP (hi-godot/godot-ai, HTTP `127.0.0.1:8000/mcp`, needs `uv`, editor must be open).
- Claude ↔ Spine = Spine CLI `~/Spine/Spine.sh`. No MCP.
- Spine → Godot = 4.3 GDExtension, force reimport after export.

## Export rules

JSON exports use `.spine-json`, never `.json`. Prefer binary `.skel`.
