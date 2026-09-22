# tdd

## Purpose

Use strict tests-first development for every execution task. Production implementation is forbidden until the active task has a written TDD plan and a demonstrated failing, mock, or contract signal.

`tdd.md` is written only through `planner_tdd_submit`. Built-in write/edit cannot modify it. The wrapper assembles the required `##` sections from structured fields and preserves sections you are not updating, so you can fill it incrementally across steps.

## Required Sequence

1. During `write_tdd_plan`, read answered `questions.md`, `decisions.md`, and `task.md` via `planner_artifact_read` (not the built-in read tool), plus existing tests and project test conventions. Call `planner_tdd_submit` with the `preImplementation` fields: the missing-behavior signal, intended production path, success signal, and files that must stay out of scope. Also note behavior under test, arguments/returns/errors/integration points, edge cases, fixtures/mocks, and focused test commands.
2. During `write_tests`, write tests and required harness wiring only. Re-submit `tdd.md` with changed files, intent, and expected signal. If project files changed, commit through `planner_git_commit`.
3. During `run_failing_tests`, execute focused checks and record the exact failing signal via `planner_tdd_submit`.
   - **Test Signal Doubt — mandatory before advancing to `implement_task`:**
     1. Would a trivial implementation (`return null`, empty function, hardcoded value) pass this test? If yes, the test does not prove the missing behavior — rewrite it.
     2. Does the failure message name the missing behavior, or only a missing file/import/module? If only harness bootstrap, add a real behavior assertion first.
     3. Is there any way to make this test green without implementing the requested behavior? If yes, the test is underspecified — add the constraint that blocks the shortcut.
     If any answer is "yes" or "I'm not sure", fix the test before touching production code.
4. Begin production edits only during `implement_task`. Before finishing it, submit the `postImplementation` fields: smallest counterexample, boundary value, opposite case, regression risk, scope check, and action. If the counterexample is real, add a test or explicitly record why it is out of scope. If implementing produced a reusable verified lesson, call `planner_skill_create`.
5. During `contract_check`, call `planner_contract_check`, then `planner_contract_upsert` for every decision (see the watcher rule below). Contract consistency is recorded in AGENTS.md, not in `tdd.md`.
6. During `run_final_tests`, rerun focused tests and required broader integration checks.
7. During `merge_task_to_plan`, submit the `mergeScopeAudit` fields *before* calling `planner_git_merge_task_to_plan` (the merge clears the active task, so the audit must be written first): acceptance-criteria coverage, changed-file scope, commands run, debug cleanup, commit-message fit, and branch-drift check.

## tdd.md Sections (written by planner_tdd_submit)

```md
## Pre-Implementation Proof Contract
- failingSignal: exact failing test/command output, mock/contract failure, or documented reason no local failing signal is possible
- productionPath: files/functions expected to change
- successSignal: exact command or assertion expected to pass after implementation
- outOfScopeFiles: files or areas that must not be changed for this task

## Post-Implementation Counterexample Review
- counterexample: smallest input/user flow/state that could break the fix
- boundaryValue: boundary checked, or explicit reason it is not relevant
- oppositeCase: opposite behavior checked, or explicit reason it is not relevant
- regressionRisk: old behavior that could have been broken
- scopeCheck: whether the implementation stayed inside the task scope
- action: added test, recorded non-goal, or no action with evidence

## Task Merge Scope Audit
- acceptanceCriteriaCovered: task acceptance criteria and evidence
- changedFilesMatchScope: changed files compared with task scope
- testsRun: exact focused and broader commands run
- debugRemoved: temporary logs/probes/scratch files removed
- commitMessageMatchesBehavior: latest planner commit describes behavior, not process
- branchDriftCheck: planner status/git wrapper state showed expected task/plan branch state
```

## Contract Watcher Rule (during contract_check)

For every directory where you edited or created files, ask two questions:

- **Does an AGENTS.md exist at or above that level?** YES → default `upsert_existing`; downgrade to `no_update` only if you can state concretely that the diff introduced zero new domain rules, connection changes, or non-obvious invariants. NO → default `create_new`; downgrade only for a single isolated fix with no new module boundary, integration point, or future-relevant rule. Absence of AGENTS.md is a reason to create one, not to skip.
- **Connection audit:** for each changed component — what calls it, what it imports from, what state it writes that others read. Non-obvious dependencies/invariants belong in AGENTS.md Domain Details (that survives memory wipes; `tdd.md` does not).
- **Level check:** if the nearest AGENTS.md is an overly abstract parent but the changed area is a distinct subdomain, prefer `create_new` at the specific directory.

After each upsert/create, re-read what you wrote: does Domain Details name a concrete caller or dependency? Would a fresh model know less about blast radius without it? Does the Child Index list every subdirectory with its own domain logic (fix the parent if you added a module)? AGENTS.md files touched here are tracked and offered as keep/remove at `/planner-finish`.

## Test Signal Rules

- Run every test, build, and verification command from the worktree path reported by `planner_status`. Never run checks from the original checkout while a plan is active. The rule is toolchain-independent.
- Prefer a real failing test when the missing behavior can execute locally. Use a mock test when an external dependency is unavailable/unsafe; use a contract test for interface, schema, command construction, or integration boundaries. If a test cannot run locally, document why and add the strongest deterministic mock or contract test available.
- A test that passes before implementation without proving the missing behavior is not sufficient.
- A module-not-found / import / file-does-not-exist failure is only a harness/bootstrap signal, not a behavior proof, unless the test already asserts the task behavior.
- Placeholder, stub, fake, TODO-only, or hardcoded implementations do not satisfy green TDD. A deliberately narrow implementation must have tests proving the accepted behavior and a counterexample review naming what remains out of scope.

## Editing Rules

- Test steps may edit any files required for tests, fixtures, mocks, and harness integration.
- Do not change production behavior during `write_tests`, and do not do unrelated cleanup.
- Before finishing the task, inspect the planner-controlled diff and confirm every changed file belongs to the task.

## Evidence Discipline

Treat TDD as the proof engine. Do not trust an implementation until the test signal changes for the intended reason.

- Red must prove missing behavior, not only a missing file/import/bootstrap problem.
- Green must prove the requested behavior, not only that the harness is quiet.
- If a counterexample is plausible, make it a test, record it as a non-goal with evidence, or mark the task blocked.
- Do not add broad tests to feel safer; add the smallest test that can falsify the current claim.

## Doubt / Boundary Coverage

For every behavioral task, choose only the cases that falsify a real acceptance risk before writing production code: the happy path that the task changes; minimum bounds (empty/zero) only when boundaries are part of the behavior; maximum bounds only when the task can plausibly break them; error/danger cases only when the task owns validation/error behavior. No reassurance tests: add a test only when it would fail before the fix or protect a named requirement. Write only the minimum production code to make the tests pass; if you handle a case no test covers, add the test first.

## Optional: mechanical consistency check

At `write_tdd_plan`, prove the TDD plan complete with `planner_elenchus_check` before writing tests. Start from `IMPORT "templates/tdd-gate.vrf"`: claim `FACT tdd_gate.task tdd_ready`, commit to `FACT tdd_gate.task tests_written_first`, state every task kind `FACT` or `NOT` (bugfix, edge cases, concurrency — each true kind derives a duty like `has_repro_test` that you may only assert once it is real), and bind the `values` ports (behaviors enumerated, every behavior has a test, red step specified, tests drive the public surface) honestly. When the task's own logic is a web of interacting conditions, model it too — mutually-exclusive states, "exactly one of", branch/case coverage — so the engine tells you which cases actually falsify the behavior. A CONFLICT hard-blocks `planner_finish_step` until resolved. The narrow escape (`resolution: "not_applicable"` with a one-line reason) is only for a task with no testable runtime surface (pure docs/comments/renames).

Read the `pi-planner-elenchus` skill for the grammar before writing the program; do not guess the DSL. The engine is a three-valued SAT checker over **formal logic only** — no arithmetic, it cannot add, count, or compare magnitudes; encode quantities as named symbolic states (`is_negative`, `over_threshold`), not numbers. Sources and verdicts land under the plan's `elenchus/` dir.

## Planner Skill Memory

`planner_skill_create` is future memory. Use it after a lesson is proven by a failing signal, debug probe, counterexample review, repeated mistake, stale-context recovery, or state-machine/tooling mistake. Create the skill before leaving the step that proved the lesson when it is reusable. Do not create skills for ordinary task summaries, non-generalizing project paths, unverified opinions, or broad advice. Write the body in `metadata.skillLanguage`; the wrapper writes `name`/`description` frontmatter and stores the skill.

## Diagnostics

- **Compilation failures:** fix compiler/lint issues before focusing on the behavior test.
- **No failing signal:** a test that passes before the production code is invalid or testing the wrong path.
- **Bootstrap-only failure:** if the only red signal is missing module/import/file, create the module, then rerun and verify behavior assertions — do not treat "file now exists" as completion.
- **Broken mocks:** if a test hangs, check for unmocked network/database calls.
- **Pivot:** if the implementation looks correct but the test still fails, verify expectations match the method signature; verify files and import paths before blaming the runner.

## manual-compact

Preserve the active task id, `tdd.md` path, failing signal, commands, fixtures, covered edge cases, skipped checks, and final verification state. After compaction, call `planner_status` before continuing.

## auto-compact

Call `planner_status` immediately. Reload `task.md`, `tdd.md`, and focused source files only when needed. Do not skip the failing-test requirement because earlier chat context was compacted.

## If You Do Not Know What To Do Next

The `planner_finish_step` result names your next step, its goal, and the worktree to work in — follow it. Call `planner_status` only when you need the full step rule or stage instruction, or when you are unsure.
