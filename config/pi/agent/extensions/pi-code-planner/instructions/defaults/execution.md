# execution

## Purpose

Execute exactly one active task at a time through tests-first development, implementation, AGENTS.md contract check, mandatory refactor review, final checks, merge, and task compact.

## Context Reload Policy

- At `prepare_task`, call `planner_status`, reread the full `plan.md`, read answered `questions.md` and `decisions.md`, read the selected `task.md`, then inspect `discovery.md` — all via `planner_artifact_read`, not the built-in read tool — and use focused project search only if needed.
- If `task.md` lists a Local Contract Context, call `planner_contract_route/read` before source reads. AGENTS.md files are repository-owned routing memory; higher levels route, nearest levels explain.
- During one task, reread `task.md`, `tdd.md`, `refactor.md` (via `planner_artifact_read`), and focused source files only when the current action needs details not already recorded.
- When starting the next task at `select_next_task`, do not carry live reasoning from the previous one. Call `planner_status`, reread the full `plan.md` via `planner_artifact_read`, inspect task status, then load the next `task.md`.
- After recovery or auto-compact, call `planner_status` before any edit or check.

## Strict Task Lifecycle

1. `prepare_task` — select exactly one pending task; create or switch its task branch with planner git wrappers.
2. `write_tdd_plan` — read task context and write `tdd.md` through `planner_tdd_submit` (`preImplementation` fields). Define test strategy, mocks, fixtures, checks, edge cases, and the expected failing signal. Then enumerate the behavior board with `planner_behavior_upsert`: one `BHV-n` per observable behavior (`happy`/`edge`/`error`/`concurrency`, link the `REQ-n` it exercises), all `planned`. For every behavior whose invariant branches (each `if`/`else`/error path is a distinct case), enumerate those branches as `BR-n` under the behavior (`{id, condition, covered: false}`) — the `tdd_coverage` gate names each untested branch by name, so this is how you prove all conditions are covered, not prose. A behavior with genuinely no branching carries `branches: []`. Built-in edit/write cannot modify `tdd.md`.
3. `write_tests` — write failing, mock, or contract tests before production implementation. As each named failing test lands, flip its behavior `planned→red` via `planner_behavior_upsert` (full list, with `{file, name}`) and flip the branches it drives to `covered: true`. Run `planner_gate_check` with `gate: "tdd_coverage"` — it names every behavior AND every branch still without a red witness, and the step cannot finish until CONSISTENT. Update `tdd.md` via `planner_tdd_submit`. If project files changed, commit through planner git before continuing.
4. `run_failing_tests` — run focused checks and prove tests detect the missing behavior. Record exact command, cwd, and failing signal via `planner_tdd_submit`.
5. `implement_task` — implement only the behavior required by `task.md` and `tdd.md`. Run focused checks, update `tdd.md` (`postImplementation` fields) via `planner_tdd_submit`, and commit through planner git if files changed.
6. `contract_check` — for every directory where you edited or created files: if AGENTS.md exists there or above → default `upsert_existing`; if none exists → default `create_new`. `no_update` requires concrete evidence, not vague confidence. Call `planner_contract_check`, then `planner_contract_upsert` for every upsert/create decision. Add durable domain guidance: connections, call chains, blast radius, non-obvious invariants. Do not store task trivia.
   Then prove the implementation honors the task contract with `planner_elenchus_check` (`resolution: "checked"`): start from `IMPORT "templates/branch-contract.vrf"` — claim `FACT branch_contract.impl matches_contract`, state `FACT`/`NOT branch_contract.impl changes_contract`, bind the `values` ports (branches tested, error paths handled, no dead branch, contract tests green) honestly, and model the changed branching itself with the rule+EXCLUSIVE recipe from the template header. The branch-contract and the `tdd_coverage` gate share ONE branch set: model each `BR-n` you declared on the behavior board as a subject carrying its number (e.g. `br_1` for `BR-1` — elenchus ids take no hyphen), and state the premises that must hold across them. A CONFLICT hard-blocks `planner_finish_step` until resolved. If the task's behavior board declares any branches, the engine MUST run — `resolution: "not_applicable"` is refused, and a `checked` program that omits a declared branch is refused by name. The escape is only for a task whose board declares no branches at all (`branches: []` everywhere).
7. `refactor_task` — challenge the implementation without changing behavior. Write `refactor.md` via `planner_refactor_review` with a concrete KISS review and decisions. Commit through planner git if files changed.
8. `run_final_tests` — run final focused and integration checks from the planner worktree. Flip each passing behavior `red→green` via `planner_behavior_upsert` and run `planner_gate_check` (`gate: "tdd_coverage"`) — every behavior must be green before advancing; going back to `implement_task` for a fix never requires the gate. Record final results and the merge scope audit in `tdd.md` via `planner_tdd_submit` (`mergeScopeAudit` fields).
9. `capture_skill`
   - Review skills already loaded in this session (visible as resources). For each loaded skill relevant to this task, confirm it is still accurate; if outdated or wrong, call `planner_skill_update`.
   - If this task produced a reusable lesson not covered by any existing skill, call `planner_skill_create`.
   - If you updated or created a skill whose body describes a runnable probe, run it now, then call `planner_git_inspect`. If dirty, call `planner_git_discard_changes` immediately — this is mandatory.
   - If no skill action is taken, write an explicit "no skill" note in `decisions.md` with the reason. Skill capture is not optional; a decision must be recorded either way.
10. `merge_task_to_plan` — record the merge scope audit and, while the task context is still live, note in `tdd.md` any component outside task scope that this task touched. Then merge the task branch into the plan branch through the planner wrapper.
11. `select_next_task` — choose `execution/prepare_task` for the next task or `finalize/verify_plan_branch` when execution is complete.

## Atomic Unit Rules

- A commit alone does not finish an atomic unit. After a planner-controlled commit or merge, continue the persisted state-machine step named in the `planner_finish_step` result.
- A dirty worktree is allowed while implementing a running step, but must be resolved before merge boundaries.
- Built-in project write/edit calls are enabled only during `write_tests`, `implement_task`, and `refactor_task`. During `contract_check`, AGENTS.md changes go through `planner_contract_upsert`, not raw write/edit. Planner-managed structured artifacts (`tdd.md`, `goal.md`, `questions.md`) are written only through their submit wrappers.
- Never edit the original checkout while a planner worktree is active. Continue inside the worktree session reported by `planner_status`.
- Run every project command from the worktree path reported by `planner_status` — focused tests, full tests, builds, type checks, linters, formatters, generators, package scripts, compilers, and project-specific verification — regardless of language or tooling. Before recording a successful check, confirm its shell cwd was the planner worktree, not the original checkout.
- Raw git is forbidden. The model chooses task ids only; it never invents merge source or target branches.

## Scope Rules

- Test writing must happen before production behavior changes.
- Do not modify unrelated files. Before finishing a task, inspect the planner-controlled diff and verify scope.
- Refactor is mandatory design review, not formatter/linter output. Passing checks do not prove that no refactor is needed.
- If new required work exceeds the current task, record it as a new task or return to planning.

## Evidence Discipline

Treat every execution step as reversible until artifacts, diff, and checks agree.

- Do not continue from memory after compact, recovery, or a failed wrapper; reload the exact state.
- Do not claim a task is done until `tdd.md`, refactor review, final checks, and task acceptance criteria all agree.
- If a tool call fails, classify the failure before retrying. Repeating a failed action without a new hypothesis is not progress.
- If the implementation drifts beyond task scope, stop and return to planning instead of broadening the task.

## Doubt Checkpoint

Before finishing any execution step, doubt the proof:

- What artifact or command proves this exact step is complete?
- Did the test fail before implementation for the intended reason?
- Did the fix stay inside active task scope?
- Did `contract_check` prove whether AGENTS.md must be updated, and are pending upserts resolved?
- Did refactor review challenge the implementation, not just repeat that checks pass?
- Are temporary debug logs, probes, or scratch files removed before commit?

If doubt remains, run one focused probe or record the risk. Do not add broad tests or unrelated cleanup only to increase confidence.

## Planner Skill Memory

Every task has a dedicated `capture_skill` step. There you must decide: create a new skill, update an existing one, or explicitly record in `decisions.md` why neither is needed.

Good candidates for a new skill: repeated failure patterns, non-obvious debug probes, state-machine mistakes, stale-context issues, exact workflow rules that prevented a real bug. Good candidates for an update: the skill was partially wrong or missing a case proven by this task; the trigger changed; the probe command has a newer form.

A skill may also be created/updated earlier (at any execution step) once the lesson is verified; still confirm at `capture_skill` that the existing skill is accurate. Do not create skills for ordinary implementation notes, task summaries, broad advice, or unproven suspicions. Write the body in `metadata.skillLanguage`; the wrapper writes frontmatter and updates the skill index.

## Fundamental Rule: Uncertainty -> Question

If a task allows more than one interpretation of mechanism or integration approach, or you are uncertain about system boundaries, ask a question — do not guess or code from assumptions.

**Ask when:** it is unclear which mechanism the task uses; unclear which files to touch; unclear what is immutable; or there is risk of breaking the existing architecture. **Do not ask when:** the task is unambiguous, all boundaries are clear, and the mechanism is explicitly defined.

## Diagnostics

- **Locate the error:** on a test failure, extract the exact file path and line; do not rely on summary output. Check exact arguments/outputs at the failing boundary. Confirm commands ran from the planner worktree.
- **Stuck-loop detection:** if 3 attempts to fix a bug hit the same failure, stop. Reread `tdd.md` boundary conditions and verify mocks are not hiding the real bug or returning stale data.
- **Minimal footprint:** modify only files the active task requires; do not polish adjacent code or add speculative helpers/abstractions. Implement only behavior covered by a TDD test.

## manual-compact

Preserve the plan id, active task id, exact branch, current step, task artifact paths, TDD evidence, refactor findings, final checks, open risks, and exact next action. After compaction, call `planner_status`. At `select_next_task`, reload full `plan.md` via `planner_artifact_read` before choosing the next task.

## auto-compact

Call `planner_status` immediately. Do not continue editing from chat memory. Restore the exact task from persisted state, inspect the git gate, then reread the artifacts required by the current step via `planner_artifact_read`. Read source files only when the exact action needs details not present in the artifacts. If scope may have changed, reread full `plan.md` via `planner_artifact_read`.

## If You Do Not Know What To Do Next

The `planner_finish_step` result names your next step, its goal, and the worktree to work in — follow it. Call `planner_status` only when you need the full step rule or stage instruction, or when you are unsure.
