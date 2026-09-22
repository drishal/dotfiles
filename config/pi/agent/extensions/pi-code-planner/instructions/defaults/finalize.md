# finalize

## Purpose

Verify the complete plan branch as one integrated result, write a durable user-facing summary, and enter the explicit acceptance stage.

## Strict Step Order

1. `verify_plan_branch`
   - Inspect planner git state and confirm all required tasks were merged.
   - Run project-level checks (from project instructions and task evidence) from the worktree path reported by `planner_status`.
   - Record failures, residual risks, and any checks that cannot run locally.
2. `compact_before_doubt`
   - Request planner-controlled compact after integrated checks and before doubt review. This is a forced reset — it runs even when context is small, because its purpose is to clear live confidence from the previous loop, not to relieve the context window.
   - After compaction, call `planner_complete_compact`, then `planner_status`, then continue from persisted artifacts only.
3. `doubt_review`
   - Before asking for acceptance, deliberately doubt the completed result. Reread `goal.md`, `plan.md`, task artifacts, and `verify.md` via `planner_artifact_read` (not the built-in read tool), plus the final worktree diff.
   - Reread `discovery.md` `## Verification Protocol` via `planner_artifact_read`. Every listed command/check is mandatory evidence for `planner_doubt_review`.
   - Treat chat memory from before `compact_before_doubt` as untrusted. Reconstruct the result from artifacts, git state, and focused file reads.
   - Start with a `Possible Errors` list in `metadata.doubtReviewLanguage`. These are suspicions, not bugs yet. Assign every possible error to one risk category: `requirement_mismatch`, `missing_test`, `boundary_case`, `integration_break`, `state_machine_error`, `persistence_error`, `recovery_error`, `wrong_file_scope`, `user_flow_regression`, or `cleanup_or_debug_leftover`.
   - Fill `verificationEvidence` with every command/check from `## Verification Protocol`. Missing evidence means the result is not verified. If any required command failed, was not run, or is unknown, create a `proven_bug` or `needs_probe` finding naming that command, and do not continue to `write_final_summary`.
   - For each possible error, prove it, disprove it, or mark it `needs_probe`. Use `planner_doubt_review`; do not hand-write `verify.md`. A suspected issue is `proven_bug` only after a failing test/command, exact code-path proof, or exact spec contradiction. `needs_probe` findings cannot finish the step — run the probe or downgrade with proof.
   - If `proven_bug` findings exist, write them to `decisions.md`, then return to `planning/read_context` for revision tasks. Do not patch ad hoc in finalize. After returning, continue through `draft_plan`, `split_tasks`, `write_task_files`, execution, and verification again. Do not skip planning because the fix looks small.
   - A finding mentioning placeholder, stub, TODO-only, hardcoded behavior, superficial implementation, missing tests, or unresolved work cannot be closed as `not_a_bug`/`disproven`; it must be `proven_bug` or `needs_probe`.
   - If `spec.json` exists, re-verify its assumptions (`ASM-n`): every gate before this point TRUSTED those boolean leaves on their recorded evidence. Re-run the cited command/measurement where feasible; an assumption that no longer holds becomes a `proven_bug` or `needs_probe` finding. Cross-check that each formalized requirement's acceptance is witnessed by a green behavior/test.
   - If a proven, disproven, or probed finding teaches a reusable workflow lesson, call `planner_skill_create` with `sourceKind=doubt_review` before leaving this step.
   - If no proven bug or probe remains, continue to `write_final_summary`.
4. `write_final_summary`
   - Write `final_summary.md` through `planner_summary_submit`. Use `metadata.humanLanguage` unless the user explicitly requested another language.
   - Include completed scope, changed files, checks, risks, output-branch expectations, and unresolved limitations.
   - If the whole plan produced a reusable verified lesson not already captured, call `planner_skill_create` with `sourceKind=final_summary`.
5. `enter_done` — advance to `done/present_result`.

## Restrictions

- Do not introduce new production behavior during finalize.
- Do not run tests, builds, linters, formatters, or project checks from the original checkout. Use the planner worktree as shell cwd.
- Do not cleanup the worktree or plan files, and do not export the plan result before explicit user acceptance.
- Do not use raw git.
- If checks reveal missing implementation, record the issue and return through the controlled planning flow instead of patching ad hoc.
- During `doubt_review`, assume bugs may remain even if tests pass. Passing checks are evidence, not acceptance. Do not call a finding a bug from suspicion alone (that is `needs_probe`), and do not normalize away placeholders or shallow implementations.

## Evidence Discipline

Treat finalize as an adversarial audit of the whole result.

- Do not trust task-level green checks until the integrated branch is checked against `## Verification Protocol`.
- Do not summarize "all tests passed" unless each required command/check is listed in `verificationEvidence`.
- If the audit finds missing behavior, placeholder logic, stale contracts, or failed/unknown checks, return to planning through the state machine.
- Do not patch from finalize because the fix looks small. Controlled revision work must get plan/tasks/TDD again.

## Doubt Review Proof Rules

Every possible error must be classified:

- `proven_bug`: verified by `reproduced_test`, `reproduced_command`, `code_path_proven`, or `spec_contradiction`; must return to planning.
- `disproven`: dismissed by `disproven_by_test` or `disproven_by_code`; no action.
- `needs_probe`: plausible but not proven; run one focused probe before finishing the step.
- `not_a_bug`: valid behavior or design preference; no action.

Tests are preferred for runtime behavior. Code-path proof is allowed only when the exact path makes the behavior impossible or directly contradicts the approved spec.

## Verification Evidence Rules

`planner_doubt_review` must include `verificationEvidence` for every command/check in `## Verification Protocol`:

- `passed`: only when the command was actually run, or the exact non-shell check was completed with concrete evidence.
- `failed`: must be paired with a `proven_bug` or `needs_probe` finding naming that command.
- `not_run`: must be paired with a `needs_probe` finding unless the user explicitly accepts the missing check later.
- `unknown`: must be paired with a `needs_probe` finding; usually means discovery did not capture enough verification detail.

Do not summarize checks as "all tests passed" unless the protocol commands are listed individually with evidence.

## Doubt Review Method

This step is a verification stage, not a writing exercise. Treat it like TDD for suspected problems:

1. Reconstruct the promise — read the approved goal, current plan, completed task files, final summary if present, and the final diff. Write what the result must do, must not do, and which checks already passed. Trust artifacts and the current worktree, not chat memory.
2. Generate possible errors before deciding — list concrete possible errors under `Possible Errors`, each pointing to a requirement, code path, changed file, missing test, migration risk, or integration boundary. Choose the narrowest category. Exclude vague anxiety and style preferences without product impact.
3. Prove or disprove each — prefer a focused failing test/command for behavior; trace the exact code path for static correctness; quote the exact requirement and contradicting behavior for spec mismatch. If evidence is insufficient, mark `needs_probe` and run one targeted probe before finishing.
4. Decide the route — any `proven_bug` → record in `decisions.md` and finish with target `planning/read_context` (planning then creates revision tasks; do not patch in finalize). If all findings are `disproven`/`not_a_bug`, finish with target `finalize/write_final_summary`.
5. Keep the artifact strict — use only `planner_doubt_review`. Every finding includes `claim`, `specReference`, `codePath`, `verification`, evidence, and `nextAction`. The runtime blocks leaving this step until every `needs_probe` is resolved.

Reward exactness, not bug count. False positives waste revision cycles; false negatives ship broken work. "No proven bugs remain" is a correct outcome when every suspicion was checked and dismissed with evidence.

## Overnight Loop — Autonomous Bug Return

If `doubt_review` produces any `proven_bug` finding, do **not** wait for the user:

1. Write the bugs to `decisions.md`.
2. Call `planner_doubt_review` to close the step with target `planning/read_context`.
3. Immediately advance: planning → execution → finalize again.
4. Notify the user only after the next full finalize cycle completes or when you hit a blocker that requires their input.

The only exceptions are a finding that requires user clarification on genuinely ambiguous requirements, or a `needs_probe` that cannot run locally (e.g., needs production credentials). In those cases, surface the blocker clearly and wait. For everything else: loop. An overnight run that pauses to ask "should I go back to planning?" has failed the contract — the state machine already permits the transition.

## Planner Skill Memory

Use `planner_skill_create` only for verified lessons that should improve future planner sessions — a reusable trigger and workflow such as a stale-context pattern, a recovery proof method, or a class of state-machine mistake. In doubt review, skill creation is expected when the audit exposed a reusable bug-finding method, a repeated false assumption, a missing-test pattern, or a compact hazard. Do not create skills for ordinary project facts or unverified suspicions. Write the body in `metadata.skillLanguage`; the wrapper writes frontmatter and stores the skill, loaded on future planner sessions via Pi `resources_discover`.

## Exit Condition

Finalize is complete only when the integrated plan branch is checked, `final_summary.md` exists, and state enters `done/present_result`.

## Diagnostics

- **Integration regressions:** if final tests fail on the plan branch, check for a merge-conflict regression; rollback the merge, fix in the task branch, and re-merge.
- **Clean diff:** inspect for temporary debug lines, print statements, or scratch files before finalizing. Run lint/format first.
- **Branch sync:** verify the plan branch is up to date with the base branch.

## Optional: mechanical consistency check

During `doubt_review`, close the review with a mechanical check instead of trusting the reasoning chain from earlier steps. Start from the bundled templates: `IMPORT "templates/doubt-review.vrf"` to prove the review itself is complete (claim `FACT doubt_review.review is_complete`, state the bug-hunt outcome as `FACT`/`NOT`, bind the `values` ports honestly), and `IMPORT "templates/ship-gate.vrf"` to prove the branch is deliverable (merges, green tests, clean worktree, and every hazard — migration, public API, dependency changes — stated `FACT` or `NOT`). Model individual suspicions with `ASSUME` (the engine's RETRACT does the backtracking), separate "the code claims" from "I verified" with `BELIEVES`/`KNOWS`, and probe candidate conclusions with `TRY`. A CONFLICT pinpoints the contradictory premises — cite the verdict as evidence in the review, and note that a CONFLICT also hard-blocks `planner_finish_step` for this step until a re-run improves it. The narrow escape (`resolution: "not_applicable"` with a one-line reason) is only for a plan that produced no code to doubt.

Read the `pi-planner-elenchus` skill for the grammar before writing the program. The engine is a SAT checker over **formal logic only** — no arithmetic; encode quantities as named symbolic states, not numbers.

## manual-compact

Preserve `final_summary.md`, project-level verification results, changed-file summary, branch state, known risks, and unresolved limitations. After compaction, call `planner_status`, read the final summary and verify artifacts, then enter done flow.

## auto-compact

Call `planner_status` immediately. Restore the exact finalize step. If it is `compact_before_doubt`, complete the compact before audit work. If it is `doubt_review`, reread `goal.md`, `plan.md`, `discovery.md`, task artifacts, and `verify.md` via `planner_artifact_read`, plus AGENTS.md contracts and focused source files before deciding. Do not export or cleanup until explicit user acceptance is recorded.

## If You Do Not Know What To Do Next

The `planner_finish_step` result names your next step, its goal, and the worktree to work in — follow it. Call `planner_status` only when you need the full step rule or stage instruction, or when you are unsure.
