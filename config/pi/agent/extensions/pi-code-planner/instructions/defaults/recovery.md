# recovery

## Purpose

Recover safely after a crash, manual git changes, a missing worktree, a wrong branch, conflicts, or inconsistent planner storage.

Recovery is inspection-first. It must never perform destructive repair without explicit user approval.

## Strict Step Order

1. `read_state` — read `project.json`, the active `plan.json`, and the active `state.json`.
2. `inspect_git` — use planner inspection wrappers to read worktree path, branch, HEAD, dirty state, conflicts, and managed-branch existence.
3. `compare_expected_actual` — compare actual git reality with persisted branch, worktree, and merge targets.
4. `classify_recovery` — classify missing worktree, wrong branch, dirty worktree, external commit, manual checkout, history rewrite, conflict, or missing files.
5. `ask_user_if_destructive` — ask the user before reset, delete, force checkout, abort, discard, or any destructive repair.
6. `repair_or_resume` — apply only approved repair, or resume into an explicit valid non-recovery stage and step.

## Recovery Rules

- Use `planner_recovery_inspect` before proposing action.
- Until recovery confirms the persisted worktree path, do not run project tests, builds, generators, or verification commands. After resume, run them only from the worktree path reported by `planner_status`.
- Do not run raw git, and do not hide external changes.
- Missing project context is not a reason to reset git. Rebuild a bounded overview when needed.
- A clean external commit is not automatically an error. Inspect the actual branch and resume only when persisted state is coherent.
- Conflicts, missing worktrees, and missing state block normal flow.
- If the original project directory is missing, tell the user clearly and use only documented best-effort cleanup paths.
- Persisted state and planner git wrappers remain the source of branch and merge targets.
- If recovery follows a stuck compact, treat the stuck report as evidence, not a negative state. Reset tone: one hypothesis, one smallest falsifying probe, one observed fact, then continue or ask the user.

## Resume Reload

After recovery resume:

1. Call `planner_status`.
2. Read the exact stage instruction bundle.
3. Reread full `plan.md` via `planner_artifact_read` when scope, task ordering, branch history, or user feedback may have changed.
4. Reload the active `task.md`, `tdd.md`, summaries (via `planner_artifact_read`), and focused source files only when needed after resuming execution.
5. Continue only after the git recovery gate is clear.

## Evidence Discipline

Treat recovery as state reconstruction, not continuation of a remembered plan.

- Do not trust chat memory, branch names, or previous summaries until persisted state and git state agree.
- Do not mark recovery complete while conflicts, dirty state, or cleanup obligations remain unexplained.
- If the next action is unclear, prefer one smallest state probe over narrative reasoning.
- If the probe contradicts the expected state, use recovery guidance instead of forcing the old path.

## Diagnostics

- **No progress during recovery:** normal planner wrappers are blocked until the git discrepancy is resolved.
- **Root cause:** read the recovery inspection report and decide whether the issue is a missing worktree, a manual checkout, or corrupted JSON.
- **Destructive acts:** never run reset or delete without asking the user. Resolution flow: inspect with `planner_recovery_inspect`, follow the classification suggestions, then resume to a safe stage/step via `planner_recovery_resume`.

## Optional: mechanical consistency check

At `repair_or_resume`, before applying a repair, prove the decision sound with `planner_elenchus_check`. Start from `IMPORT "templates/recovery-state.vrf"`: claim `FACT recovery_state.repair safe_to_apply`, settle the repair kind (`is destructive` / `is non_destructive` — a destructive repair additionally requires a REAL `FACT recovery_state.user approved_destructive`), and bind the `values` ports (cause identified, expected state read, actual state inspected, minimal repair) honestly. Model competing failure-cause hypotheses with `ASSUME` — the engine's RETRACT list does the backtracking and names the guess to drop. A CONFLICT with its CORE names the exact premises to blame, turning a vague stall into a concrete fix, and hard-blocks `planner_finish_step` until resolved. The narrow escape (`resolution: "not_applicable"` with a one-line reason) is only for a recovery that found nothing to repair. This never replaces `planner_recovery_inspect`/`planner_recovery_resume` and never touches git — it only proves the logic.

Read the `pi-planner-elenchus` skill for the grammar before writing the program. The engine is a SAT checker over **formal logic only** — no arithmetic; encode quantities as named symbolic states, not numbers.

## auto-compact

Call `planner_status` immediately. Do not assume recovery was completed. Reload persisted state, rerun recovery inspection, and wait for explicit user approval before destructive repair.

## If You Do Not Know What To Do Next

The `planner_finish_step` result names your next step, its goal, and the worktree to work in — follow it. Call `planner_status` only when you need the full step rule or stage instruction, or when you are unsure.
