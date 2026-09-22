# discovery

## Purpose

Become familiar with the project before planning. Keep this stage cheap for a local model: discover AGENTS.md local contracts first, inspect the project tree, read only the files needed for the approved goal, and summarize useful findings in `discovery.md`.

## Strict Step Order

1. `scan_project_structure`
   - Read `goal.md` with `planner_artifact_read` (`artifact: "goal"`) for normal `/planner-create` plans, not the built-in read tool.
   - If `planner_status` reports `creationMethod: improve`, this is a discovery-first plan: do not treat empty `goal.md` as a blocker and do not read `request.md` as the source goal. Use repository evidence to discover a bounded self-improvement goal, then return to `intake/draft_goal` after discovery.

   **AGENTS.md First Gate — before reading any project file or running any shell command:**
   1. Call `planner_contract_scan` to discover all AGENTS.md/context files.
   2. If scan returns 0 paths: skip routing entirely and proceed to project tree inspection. Do not call `planner_contract_route` or `planner_contract_read`.
   3. If scan returns 1+ paths: call `planner_contract_route` with the goal's target paths to select the relevant chain.
   4. Call `planner_contract_read` for every contract in the selected chain, root to nearest.
   5. **Depth stop rule:** stop reading deeper when any is true — the nearest contract's Child Index is `(none)` (it is a leaf); no child domain in the Child Index matches the goal's primary changed area; or the nearest contract's Purpose already fully covers the goal scope.
   6. Read a child contract only when the child domain explicitly covers the goal's primary implementation area. Do not read children "just to be safe."
   7. If a contract turns out to be the wrong domain, call `planner_contract_route` again with a more specific target or a sibling path.
   8. After reading the relevant chain, use the `Read First` files listed in the nearest contract before broad source reads.

   - Treat AGENTS.md as the only writable/canonical planner memory format. Treat non-AGENTS context files as read-only guidance; copy any durable rule into the nearest AGENTS.md via `planner_contract_upsert`.
   - Inspect the project tree with read-only shell commands after the contract map is processed. Read only the manifests, entrypoints, tests, configuration, and source files needed for the requested work.
   - Write `discovery.md` through `planner_discovery_submit`: pass the `body` (architecture, relevant paths, conventions, risks, uncertainty) plus a `verificationProtocol` list. The wrapper renders a well-formed `## Verification Protocol` section, which is required before this step can finish.
   - In `verificationProtocol`, record exact test, lint, build, and format commands with required working directory and important flags. If a command is not discoverable, record an `unknown` entry and ask the missing setup question in `discovery/write_questions`.
   - If no useful AGENTS.md exists and discovery proves meaningful architectural zones, create initial root/domain contracts through `planner_contract_upsert`. Do not create one in every folder.
   - If `planner_contract_upsert` changes AGENTS.md files during discovery, commit them through `planner_git_commit` before finishing `scan_project_structure`.
2. `write_questions`
   - Call `planner_questions_submit` with evidence-based unresolved questions and explicit assumptions.
   - If the project is empty or lacks test/lint/build conventions, ask how to set up testing: framework, test command, lint command, formatter, and required flags. If conventions exist but discovery could not prove exact commands or flags, ask only for the missing ones.
   - If questions exist, show them to the user verbatim, wait for answers, then call `planner_questions_resolve`.
   - If no questions remain, call `planner_questions_submit` with `hasOpenQuestions: false` and state that explicitly.
3. `enter_planning`
   - For normal `/planner-create` plans, advance to `planning/read_context`.
   - For `/planner-improve` plans (`creationMethod: improve`), finish with target `intake/draft_goal` so the model can write `goal.md` from discovery findings and ask for approval.

## Restrictions

- Do not implement production code or tests.
- Do not read the whole repository by default.
- Do not skip AGENTS.md routing when contract files exist. They are local architecture memory, not optional docs.
- Do not read child contracts unless the child domain directly covers the goal's primary changed area.
- Do not panic when AGENTS.md files are absent. Run the scan, confirm 0 paths, then proceed with normal tree inspection. Absence is not an error — but for project file changes in a project with no writable AGENTS.md, create the initial meaningful contract.
- Do not create AGENTS.md for every directory; a contract belongs only where it prevents future agents from reading irrelevant code or breaking a durable rule.
- Do not build or maintain a file-by-file symbol index.
- Run project-scoped shell commands from the worktree path reported by `planner_status`.
- Do not use raw git.

## Exit Condition

Discovery is complete when `discovery.md` contains enough context for planning, includes `## Verification Protocol`, required user questions are answered or explicitly absent, and the configured discovery compact boundary finishes.

## Evidence Discipline

Treat every discovery conclusion as suspect until it has a path, command, contract, or source citation.

- Do not infer behavior from filenames, comments, package names, or previous chat memory alone.
- If AGENTS.md or imported context files route to a domain, read the routed chain before broad source inspection.
- If verification commands are unknown, say unknown and ask or record the gap; do not invent a test/lint/build command.
- If a project is empty or lacks conventions, ask how verification should work before planning implementation.

## Doubt Checkpoint

Before finishing discovery, doubt the context:

- Did you record exact test, lint, build, and format commands with working directory and flags?
- If the project is empty or conventions are missing, did you ask how testing and checks should be set up?
- Are source findings backed by paths and evidence, not filenames or comments alone?
- Are open questions truly resolved, or only postponed?

If doubt remains, update `discovery.md`/`questions.md` or ask focused questions. Do not plan from vague project memory.

## Fundamental Rules

These rules are shared planner philosophy; discovery is where they are first applied.

### Rule 1: System Boundaries

Before reading any file, separate **internal** (files inside the project you can read and edit) from **external** (host mechanisms, external APIs, runtime environments, servers, models, browsers, file systems outside the project root).

You do not write external code; you use or call external mechanisms. If a task requires an action performed by an external mechanism, the solution is in HOW to call it, not in rewriting its code. If the task says "make X happen" and X is performed externally, find the integration point where the project can ASK the external mechanism to do X.

### Rule 2: Mechanism vs Outcome

Every requirement has an **outcome** (what should happen) and a **mechanism** (how it happens). Investigate, do not guess. When a task describes an outcome, do not jump to "I need to write code." First ask: is there already a mechanism in the project (hooks, events, handlers, scheduler)? Is there an external mechanism (host API, ready integration)? Do you need new code, or just to connect to an existing mechanism? Code is the last option, not the first.

### Rule 3: Doubt and Logical Deduction

Never assume documentation, comments, or naming are accurate. Trust only what you can prove via real code, runtime execution, and tests. Assume you are missing critical details until you verify them, and state uncertainties explicitly. If you see `A` calling `B`, find `B`'s definition and verify its behavior — do not guess from the name.

### Rule 4: Map Input/Output Boundaries

To understand any module, map its boundaries first: **inputs** (what triggers it; what data/events/config it receives, and from where) and **outputs** (what it produces; side effects, state changes, return values, file writes, events). Once the input/output protocol is clear, the internal logic becomes predictable. Never analyze a module in isolation.

### Rule 5: Pivot When Stuck

If a task stays blocked, do not retry the same approach. Being stuck signals a wrong assumption. Map what was done, identify where reality diverged from expectations, then pivot: simplify, change direction, or backtrack to a known working state.

### Rule 6: Extreme KISS

Write only the minimum code required for the goal. Reuse existing utilities, helpers, and classes found during discovery instead of rewriting them. Avoid speculative abstractions, factories, and patterns unless explicitly requested.

## Optional: mechanical consistency check

Before finishing the scan, prove the discovery is honest with `planner_elenchus_check`. Start from `IMPORT "templates/discovery-gaps.vrf"`: claim `FACT discovery_gaps.discovery is_complete`, state each environment hazard `FACT` or `NOT` (external services, generated code), and bind the `values` ports (entry points mapped, build/test commands known, conventions recorded, unknowns written down) honestly — a port you cannot set true is a gap to close, not to guess. Put every unverified assumption on record as a `BELIEVES planner ...` line so it cannot masquerade as knowledge. A WARNING or UNDERDETERMINED verdict names exactly the missing fact — that is your cue to re-read the relevant code and record it in `discovery.md`. The narrow escape (`resolution: "not_applicable"` with a one-line reason) is only for a project already discovered by an earlier plan with nothing structural changed.

Read the `pi-planner-elenchus` skill for the grammar before writing the program. The engine is a SAT checker over **formal logic only** — no arithmetic; encode quantities as named symbolic states, not numbers.

## manual-compact

Preserve the approved goal, `discovery.md`, relevant paths, commands, open questions, and the exact current planner step. After compaction, call `planner_status`.

## auto-compact

Call `planner_status` immediately. Read `discovery.md` via `planner_artifact_read` and continue the persisted step. Read additional source files only when the current context is insufficient.

## If You Do Not Know What To Do Next

The `planner_finish_step` result names your next step, its goal, and the worktree to work in — follow it. Call `planner_status` only when you need the full step rule or stage instruction, or when you are unsure.
