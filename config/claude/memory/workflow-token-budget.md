---
name: workflow-token-budget
description: "Measured cost per subagent by model — Sonnet $0.88, Opus $3.55, Fable $10.28 — and how to tier a fanout so breadth stays but the bill drops"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 729563f2-43e5-4ad9-a965-6f7af7e17a33
  modified: 2026-07-25T17:41:51.428Z
---

User likes ultracode fanouts (several agents with different views) and wants to
keep that shape. Measured on the 3090 box (1,023 transcripts, **$5,239**):
**main-loop 57%, workflow agents 27%, other subagents 16%** — so 43% of all
spend is the fanout, and essentially none of it ran on a cheap model.

**Measured cost per subagent, by model:**

| model | agents | $/agent |
|---|---|---|
| sonnet-4-6 | 8 | **$0.88** |
| haiku-4-5 | 4 | $1.17 |
| opus-4-8 | 418 | $3.55 |
| opus-5 | 104 | $4.10 |
| fable-5 | 34 | **$10.28** |

**Why:** subagents inherit the main-loop model and session effort unless a
stage overrides them, so a global `opus[1m]` + high effort makes every finder
an Opus agent. The breadth is the value; the uniform tier is not. Fable at
~12x a Sonnet agent is never the right default — the three most expensive
single agents on record were all Fable.

**How to apply:**
- `{model: 'sonnet'}` for finders, scanners, verifiers. Inherited Opus only for
  final synthesis and tie-break judging. Fable only when explicitly asked.
- Effort by kind of work, not by model: `effort: 'high'` on Sonnet reasoning
  agents (cheap enough that the reasoning pays), `effort: 'low'` on mechanical
  stages (grep, collect, transform) where high effort just adds tool calls.
- Keep agent prompts small — measured subagents average 41k context, p90 88k.
  They carry whatever you hand them, on every one of their requests.
- Breadth is capped at 6 agents per fanout by the 3090 `CLAUDE.md` (one
  planning question once cost 51 agents / 2.3M tokens). Within that budget,
  spend it on distinct lenses, not redundant refuters.
- Verify votes stay at 2-3 lenses — that cost is `findings x voters`.
- Never switch the main-loop model to save money: it invalidates the prompt
  cache. Spawn a cheaper subagent instead.

Related: [[compaction-break-even]], [[jetson-context-profile]]
