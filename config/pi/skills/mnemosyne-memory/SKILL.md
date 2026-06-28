---
name: mnemosyne-memory
description: "Shared cross-session memory with Hermes via the Mnemosyne MCP server (both agents read/write one SQLite DB). Use when past-session context matters: `mnemosyne_recall` at session start and when the user references prior work/decisions; `mnemosyne_remember` durable facts (decisions, preferences, project state, open questions) when finishing work or before context loss — what you store, Hermes sees, and vice versa. Don't remember trivial output or full files. No reflect loop — recall is the retrieval tool; `mnemosyne_sleep` runs consolidation, not reasoning."
---

# Mnemosyne Memory (shared with Hermes)

This skill wires pi to the same Mnemosyne memory store Hermes uses. **The DB is
shared**: pi and Hermes read/write the same SQLite file, so anything either
agent stores, the other can recall. This is how context survives across
sessions _and_ across agents.

**The single most important rule:** MCP tools are passive — nothing calls them
automatically. If you don't `mnemosyne_remember`, nothing is saved. If you don't
`mnemosyne_recall`, you're working blind to past context (yours _and_ Hermes's).
Treat the triggers in the description as mandatory.

Use Mnemosyne for normal durable memories (preferences, decisions, project state,
prior work). Use `MEMORY.md`/`USER.md` only for core rules/facts that must be
present in every prompt; keep them tiny.

## Connection facts

- **MCP server name:** `mnemosyne` (configured in `~/.pi/agent/mcp.json`, lazy lifecycle). Pi must be restarted or `/reload`ed after editing MCP config because the MCP server list is read at startup.
- **MCP command:** `/home/drishal/.hermes/hermes-agent/.venv/bin/mnemosyne mcp` with `LD_LIBRARY_PATH=/run/current-system/sw/share/nix-ld/lib` on NixOS. Direct calls without that env can produce misleading dependency failures.
- **Hermes private DB:** `~/.hermes/mnemosyne/data/mnemosyne.db` (Hermes memory provider's main SQLite DB).
- **Shared surface DB:** `~/.mnemosyne/data/shared/mnemosyne.db` exposed by `mnemosyne_shared_*` tools for compact cross-agent facts/preferences.
- **Hermes config:** `~/.hermes/config.yaml` has `memory.provider: mnemosyne` and `memory.mnemosyne.shared_surface_read: true`, `auto_sleep: true`, `vector_type: int8`.
- **Hybrid ranking:** vector similarity + FTS5 text rank + importance + optional temporal boost. Tunable per-query via `vec_weight`/`fts_weight`/`importance_weight`/`temporal_weight`.
- **No `reflect`** — unlike Hindsight, there is no agentic reasoning loop. `mnemosyne_recall` is the retrieval tool; `mnemosyne_sleep` runs background consolidation (compression), not synthesis.

If a tool call to `mnemosyne` fails, first verify the MCP command with a JSON-RPC `initialize` + `tools/list` handshake using the env above.

## Core tools

### mnemosyne_remember — store a durable fact

```
mnemosyne_remember(content, importance?, source?, scope?, valid_until?, extract?, extract_entities?, metadata?, veracity?)
```

- `content` (required): the fact itself, concise and self-contained.
- `importance`: 0.0–1.0. Higher = surfaces more often in recall. Default 0.5. Use 0.8+ for core preferences/decisions.
- `source`: content tag — `preference`, `fact`, `insight`, `identity`, `task`. For agent attribution, also set `metadata: {"agent": "pi"}` so Hermes can tell who stored it.
- `scope`: `session` (default) or `global`. Use `global` for cross-project facts.
- `extract`: set `true` to LLM-extract subject-predicate-object triples for graph-aware recall (costs an LLM call). Use for relationship-rich facts.
- `valid_until`: `YYYY-MM-DD` expiry for time-bound facts (e.g. "using branch X until merge").
- Good: "User prefers NixOS + Neovim; pi runs on GLM5 via litellm gateway at 192.168.11.14:8085"
- Bad: "we talked about stuff" / pasting a 200-line file / "fixed the bug" with no detail.

### mnemosyne_recall — retrieve relevant memories

```
mnemosyne_recall(query, limit?, temporal_weight?, vec_weight?, fts_weight?, importance_weight?)
```

- `query` (required): natural-language query describing what you want.
- `limit`: max results. Default 5. Use 10+ for broad context loading.
- `temporal_weight`: 0.0 = ignore recency, 0.2 = mild bias (default-ish), 0.5 = strong recency. Set 0.0 when searching for old decisions.
- Returns ranked results (each has `id`, `content`, `source`, `importance`, `timestamp`). **Read them before acting.**

### mnemosyne_shared_* — compact cross-agent surface

Use `mnemosyne_shared_remember`, `mnemosyne_shared_recall`, `mnemosyne_shared_forget`, and `mnemosyne_shared_stats` for stable facts/preferences that should be deliberately visible across agents through the shared surface DB (`~/.mnemosyne/data/shared/mnemosyne.db`). Prefer shared tools for compact user/system/workflow metadata; use normal `mnemosyne_remember` for richer private episodic memory.

### mnemosyne_sleep — consolidation (use sparingly)

```
mnemosyne_sleep(all_sessions?, dry_run?, force?)
```

- Compresses old working memories into episodic summaries. This is **not** a reasoning tool — it's housekeeping.
- Hermes runs this on a schedule via its plugin hooks. In pi, only call it after a very long session or if recall feels stale. Use `dry_run: true` first to preview.
- Don't run casually — it mutates the shared DB Hermes also reads from.

### mnemosyne_triple_add / mnemosyne_triple_query — knowledge graph

```
mnemosyne_triple_add(subject, predicate, object, valid_from?)
mnemosyne_triple_query(subject?, predicate?, object?)
```

- Structured relationships: `("user", "prefers", "neovim")`, `("project", "uses", "nixos")`.
- Use when a fact is naturally a relationship (not prose). Queryable by pattern.
- `valid_from`: ISO date for temporal facts.

### mnemosyne_invalidate — supersede an outdated memory

```
mnemosyne_invalidate(memory_id, replacement_id?)
```

- Mark a recalled memory as expired/superseded. Pass `replacement_id` to chain old→new.
- Use when a decision changes: don't just add the new fact — invalidate the old one so recall stops surfacing stale info.

### Scratchpad (ephemeral)

- `mnemosyne_scratchpad_write(content)` / `mnemosyne_scratchpad_read()` / `mnemosyne_scratchpad_clear()`
- Temporary notes within a session. Not durable, not recalled. Use for in-progress state that shouldn't pollute the shared memory.

### Browsing

- `mnemosyne_stats()` — working/episodic counts, BEAM tiers. Use to check memory health.
- `mnemosyne_get(memory_id)` — fetch one memory by exact ID (no search). Use when you have an ID from prior recall.
- `mnemosyne_graph_query(seed_id)` / `mnemosyne_graph_link(source_id, target_id, relationship)` — traverse/link the memory graph.

## Decision table

| Situation                                     | Tool                         | Notes                                                                         |
| --------------------------------------------- | ---------------------------- | ----------------------------------------------------------------------------- |
| New session / first request                   | `mnemosyne_recall`           | query = current project + "recent work"; loads context Hermes may have stored |
| User says "remember", "note this", "I prefer" | `mnemosyne_remember`         | importance 0.8+, source=`preference`, metadata `{"agent":"pi"}`               |
| A decision is finalized                       | `mnemosyne_remember`         | importance 0.8+, include rationale + date in content                          |
| User references prior work                    | `mnemosyne_recall`           | do this BEFORE answering                                                      |
| About to compact / end session                | `mnemosyne_remember`         | save open questions, current state, next steps                                |
| Structured relationship (X uses Y)            | `mnemosyne_triple_add`       | graph-queryable later                                                         |
| A decision changed / fact is stale            | `mnemosyne_invalidate`       | pass old memory_id, optionally replacement_id                                 |
| Temporary in-progress note                    | `mnemosyne_scratchpad_write` | not durable, not recalled                                                     |
| Memory feels stale after long session         | `mnemosyne_sleep`            | dry_run first; Hermes usually handles this                                    |
| Trivial output, debug logs, full files        | (nothing)                    | do NOT remember                                                               |

## Anti-patterns (don't do these)

- Don't `mnemosyne_remember` every message — only durable, reusable facts. The DB is shared with Hermes; noise pollutes both agents.
- Don't `mnemosyne_recall` and then ignore the results — actually use them in your answer.
- Don't store pi-ephemeral debugging state in the durable memory — use the scratchpad for that.
- Don't store secrets/API keys in memory (the DB is unencrypted on localhost).
- Don't store full file contents; store the _decision_ or _fact_ about the file.
- Don't run `mnemosyne_sleep` casually — it's consolidation housekeeping that mutates the shared DB. Prefer letting Hermes's scheduled hooks handle it.
- Don't add a new memory that contradicts an existing one without invalidating the old one — `mnemosyne_invalidate` the stale one with a `replacement_id`.

## Recurring workflows → skills

When `mnemosyne_recall` surfaces the same multi-step workflow 2+ times across
sessions (or you catch yourself re-deriving a procedure you've run before),
consider formalizing it into a reusable skill instead of solving it ad hoc again:

1. Confirm it deserves a skill — recurring, recognizable steps, quality improves
   with reuse. Skip one-offs and short troubleshooting turns.
2. Prefer patching a loaded/existing skill when it is wrong, stale, or missing a
   step. Prefer adding `references/` under an existing umbrella over creating a
   new skill directory.
3. Create a new skill only when the user explicitly asked for one, or after
   asking for and receiving confirmation.
4. Load the `skill-creator` skill (`/skill:skill-creator`) and follow its
   methodology (minimal shape, lean quoted frontmatter, trigger-rich description,
   operational body).
5. If a new skill is confirmed, write it to `~/.pi/agent/skills/<name>/SKILL.md`.
6. Run skill-creator's efficiency check on it and fix hard issues before shipping.
7. `mnemosyne_remember` a note that the skill exists (importance 0.7,
   `metadata: {"agent":"pi","skill":true}`) so future sessions — yours or
   Hermes's — reach for it instead of re-deriving.

This closes the loop: mnemosyne detects the pattern → skill-creator formalizes
it → validator gates quality → mnemosyne records that the skill now exists.

## Deep reference

The full Mnemosyne source is at `~/.hermes/hermes-agent/venv/lib/python3.11/site-packages/mnemosyne/`.
The repo (`mnemosyne-oss/mnemosyne`) has docs at `https://github.com/mnemosyne-oss/mnemosyne/tree/main/docs`.
For the 25-tool inventory, run `mnemosyne mcp` and send a `tools/list` request.
