---
name: compaction-break-even
description: "Measured across 1,023 transcripts — cost per request scales with context size and the post-compact base is ~0.35x the window, so a smaller autoCompactWindow is nearly always cheaper"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 729563f2-43e5-4ad9-a965-6f7af7e17a33
  modified: 2026-07-25T17:42:03.573Z
---

Measured 2026-07-25 across the 3090 box's `~/.claude/projects/**/*.jsonl`
(1,023 transcripts, **$5,239**, 53,405 requests). Supersedes every earlier
estimate in this file — the originals assumed a fixed compaction base and
~10k/turn growth, and both were wrong by an order of magnitude.

**Real parameters** (per API *request* — every tool call is a request that
re-reads the whole context; a user turn is many requests):

- growth per request `g`: **median 912**, mean 1,575, p90 3,449, p99 10,368,
  max 46,735. Bursty tail, small centre.
- post-compact base `B` ≈ **0.35 x W** (138 observed resets: median W=145,862,
  median B=53,004). Not a constant — a bigger window leaves a bigger base.
- compaction summary output ≈ **1.4k**. Effectively free.

**Measured cost by context size of the request:**

| context | $/1k requests |
|---|---|
| 0-25k | $98 |
| 25-50k | **$87** |
| 50-75k | $87 |
| 75-100k | $95 |
| 100-125k | $107 |
| 125-150k | $124 |
| 175-200k | **$164** |

**Why smaller wins:** because `B` scales with `W`, compaction has no meaningful
fixed overhead to amortise, and cost per request is dominated by the
`0.1 x context` cache read. The cheap band is **25-75k of live context**; the
0-25k bucket is *more* expensive because uncached first requests and cache
writes dominate there, so there is a floor — do not chase tiny windows.

**How to apply:** `avg context ≈ 0.675 x W`, so `W = 110k` lands the average at
~74k, the top of the cheap band. That is the setting on both boxes. Raising the
window "to avoid compaction" is a false economy: compaction is cheap, carrying
context is not.

Related: [[workflow-token-budget]], [[jetson-context-profile]]
