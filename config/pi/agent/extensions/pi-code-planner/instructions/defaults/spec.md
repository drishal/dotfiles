# spec

## Purpose

Turn the approved goal plus discovery context into a checkable specification — the single source of truth every later stage traces back to. You author the structured spec; a deterministic compiler turns it into VRF and the elenchus engine verifies it. You never hand-write gate VRF in this stage.

## Context Reload

At `spec/draft_requirements`, load context in this order:

1. Call `planner_status`.
2. Read `goal.md`, `discovery.md`, and `decisions.md` via `planner_artifact_read`.
3. Use `planner_contract_route/read` for applicable AGENTS.md chains before extra source reads.

## Strict Step Order

1. `draft_requirements`
   - Call `planner_spec_submit` with the full structured spec: `requirements`, `nonGoals`, `constraints`, `assumptions`. The wrapper validates everything and writes `spec.json` + `spec.md` atomically; do not write these files by hand.
   - Every requirement gets a stable id `REQ-<n>`, a statement, a human acceptance criterion, a priority (`must`/`should`/`could`), and `inScope`.
   - For each requirement, formalize it: set `acceptanceAtom` to a lowercase snake_case VRF atom (e.g. `invalid_input_rejected`) that later work will have to prove.
   - The one narrow escape — the **freedom valve**: when a requirement is genuinely inexpressible as a boolean web (taste, "the UX feels calm", real arithmetic, open-ended judgment), omit `acceptanceAtom` and record `deferral.rationale` explaining why. An omission without a rationale is rejected. Over-formalizing the inexpressible is itself a defect, not diligence.
   - Numbers never enter the spec's logic. Compute the predicate yourself and assert it as an assumption — a boolean leaf with an `atom` (e.g. `latency_within_budget`) and a `statement` citing the evidence (what you measured or ran). An assumption without evidence is rejected.
   - Record what the user declared out of scope as `nonGoals` — coverage will never demand a task for them.
2. `elicit_gaps`
   - Turn every open gap into concrete questions via `planner_questions_submit`; resolve answers with `planner_questions_resolve` into `decisions.md`. The gaps reported by the verifier — not your own guesses — are the interview script.
   - After answers arrive, update the spec with another `planner_spec_submit` call.
3. `verify_spec`
   - Call `planner_gate_check` with `gate: "spec_consistency"`. It compiles `spec.json` to VRF deterministically, runs the elenchus engine, and writes the verdict to `coverage.md`.
   - Iterate until the verdict is **CONSISTENT**. Anything else blocks this step: a CONFLICT names contradictory requirements — fix the spec, never delete a valid requirement to force green; a WARNING/UNDERDETERMINED names the unaddressed requirement or the missing decision — formalize it, defer it with a rationale, or route it back to `elicit_gaps` as a question.
4. `finish_spec` — advance to `planning/read_context`. The gate refuses to advance until the latest spec check is CONSISTENT.

## Restrictions

- Do not edit production files or write tests.
- Do not write `spec.json`, `spec.md`, or any `.vrf` by hand — `planner_spec_submit` and `planner_gate_check` are the only writers here.
- Do not invent requirements the user never asked for; unclear scope is a question, not an assumption.
- Do not rely on chat memory; the spec on disk is the memory that survives compaction.

## Evidence Discipline

- A requirement's statement describes observable behavior, not implementation ("invalid input returns a typed error", not "add a try/catch").
- Replace adjectives with checkable claims. "Fast" is not a requirement; `latency_within_budget` backed by a measured assumption is.
- Every assumption cites how it was established. If you have not verified it, it is a question for `elicit_gaps`, not an assumption.

## Exit Condition

The spec stage is complete only when `planner_gate_check` reports CONSISTENT, every in-scope requirement is either formalized or deferred with a recorded rationale, all questions are resolved, and the spec compact finishes.

## manual-compact

Preserve the requirement ids and statements, non-goals, constraints, assumption atoms with their evidence, the latest gate verdict, and open questions. After compaction, call `planner_status`, then reread `spec.md` via `planner_artifact_read` before continuing.

## auto-compact

Call `planner_status` immediately and restore the exact spec step. Reread `spec.md` (and `coverage.md` if `verify_spec` already ran) via `planner_artifact_read`. Do not regenerate requirements from chat history — the persisted `spec.json` is the source of truth.

## If You Do Not Know What To Do Next

The `planner_finish_step` result names your next step, its goal, and the worktree to work in — follow it. Call `planner_status` only when you need the full step rule or stage instruction, or when you are unsure.
