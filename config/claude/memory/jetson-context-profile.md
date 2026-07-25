---
name: jetson-context-profile
description: "The real jetson work lives on the 3090 box and is 82% of all Claude spend ($4,272 of $5,239) — that is where any cost effort belongs"
metadata: 
  node_type: memory
  type: project
  originSessionId: 729563f2-43e5-4ad9-a965-6f7af7e17a33
  modified: 2026-07-25T17:55:33.784Z
---

`~/jetson` **on the 3090 box** (`ssh 3090`, Tailscale 100.103.89.71) is the
dominant workload: **$4,272 of $5,239 total = 82%** of all measured Claude
spend (1,023 transcripts, measured 2026-07-25). The `~/jetson` directory on the
laptop is a near-empty copy — ignore it for cost purposes.

It is a **git repo** there (unlike the laptop copy), so the mandatory git cycle
in `CLAUDE.md` applies. `.claude/settings.local.json` is gitignored (`.gitignore`
line 90) — use that, not `.claude/settings.json`, for any project-local knob.

**Shape of the work:** document- and research-heavy, with autoresearch/loop
harnesses under `~/jetson/.claude/`. Growth is bursty — most requests add a few
hundred tokens, then one doc read adds tens of thousands (max seen 46,735).

**The session the user calls "rework" is `-home-gara-jetson/390e9ce7`** — the
user typed "rework" in it 4x, and `ff914bef` refers to resuming it by that
name. It is also the single most expensive session on record: (96MB) —
6,293 main requests at avg 113,829 context, peak 191,922, **46 compactions**,
plus **228 subagents / 9,547 requests**. Main $731.70 + subagents $888.90 =
**$1,620 for one conversation.** The subagents cost more than the main loop.

**How to apply:**
- No project override is set; the 3090 global `autoCompactWindow: 110000`
  covers it. Do not raise it — see [[compaction-break-even]] for why.
- The leverage is not the window, it is the fanout: tier subagent models
  (see [[workflow-token-budget]]) and keep raw doc reads out of main context.
- A 46k dump in main context is re-read at 0.1x on **every later request**, and
  these sessions run thousands of requests. A subagent digest is paid once.

Related: [[compaction-break-even]], [[workflow-token-budget]]
