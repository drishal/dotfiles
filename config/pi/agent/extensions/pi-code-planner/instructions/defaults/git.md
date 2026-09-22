# git

## Purpose

Use git as the planner consistency layer without letting the model manipulate branches or commits directly. While a planner plan is active, raw git through shell is forbidden, including read-only raw git commands.

## Public Planner Git Wrappers

- `planner_git_inspect` reads controlled branch, HEAD, dirty state, conflicts, and related git reality.
- `planner_git_init` initializes git only during controlled init.
- `planner_git_commit` stages and commits the current atomic checkpoint.
- `planner_git_create_task_branch` creates or switches the active task branch.
- `planner_git_create_refactor_branch` creates the refactor branch when required.
- `planner_git_merge_refactor_to_task` merges refactor result into the current task.
- `planner_git_merge_task_to_plan` merges the current task into the protected plan branch.

Final export, worktree removal, temporary branch cleanup, planner artifact removal, and Pi JSONL session handoff are intentionally not model tools. After explicit user acceptance, ask the user to run `/planner-finish`.

## Branch Lifecycle

```text
base branch
  -> plan/<plan-id>
    -> task/<plan-id>/<task-id>
      -> refactor/<plan-id>/<task-id>
  -> output/<plan-id>
```

The extension stores the branch registry and merge targets in `state.json`. The model chooses ids only; it never chooses merge source or target branch names manually.

## Worktree Command Invariant

While a planner plan is active, the persisted worktree path reported by `planner_status` (and echoed in each `planner_finish_step` result) is the only project working directory.

- Run every project-scoped shell command from that worktree path, regardless of language, package manager, build system, or script runner. This includes tests, builds, type checks, linters, formatters, code generators, dependency inspection, package scripts, compiler commands, and project-specific verification commands.
- Never run project checks from the original checkout while a planner plan is active.
- If the current shell cwd is unclear, read the exact worktree path from the latest planner result or `planner_status`, and run with that path as cwd.
- Planner artifact reads and writes still use the artifact paths reported by `planner_status`.

## Checkpoint Rules

- Commit only through `planner_git_commit`.
- A dirty worktree is allowed during implementation but must be resolved before merge boundaries.
- Conflicts, unexpected branch changes, missing worktrees, and inconsistent history require recovery inspection.
- External commits trigger recovery inspection, not automatic reset.

## Cleanup Rules

- Refactor branch is deleted after merge into task.
- Task branch is deleted after merge into plan.
- Plan branch is protected from managed child cleanup.
- Worktree removal and final export happen only after explicit user acceptance.

## Restrictions

- Do not run `git` through shell, and do not use aliases, scripts, or indirect commands to bypass the wrappers.
- Built-in project write/edit calls are enabled only for the exact execution steps reported by `planner_status` (`write_tests`, `implement_task`, `refactor_task`). The planner does not infer file roles from names.
- Built-in write/edit cannot modify planner-managed structured artifacts (`goal.md`, `questions.md`, the active task's `tdd.md`); use their submit wrappers instead.
- Do not read planner artifacts (`request.md`, `goal.md`, `discovery.md`, `plan.md`, `questions.md`, `decisions.md`, `verify.md`, `final_summary.md`, and a task's `task.md`/`tdd.md`/`refactor.md`) with the built-in read tool or shell. They live in the extension storage dir outside the worktree, so a worktree-relative path 404s and security/approval extensions that fence the worktree will block the read. Always use `planner_artifact_read` (pass `artifact:` and, for task files, `taskId:` or rely on the active task). Never guess a path for these files.
- Never edit the original checkout while a planner worktree is active. All project changes belong in the persisted worktree path.
- Do not reset, force checkout, abort, delete, or discard changes without explicit user approval through the recovery flow.

## Evidence Discipline

Treat git state as observed data, not memory.

- Do not assume the current branch, worktree, dirty state, or merge target. Read it from planner wrappers/status.
- If branch state differs from the expected planner state, stop and enter recovery instead of fixing with raw git.
- Do not claim a commit or merge contains specific work unless the diff/task artifacts support it.

## Diagnostics

- **Never use raw git:** raw git via bash bypasses the state machine and corrupts planner state. Use only the wrappers above.
- **Branch name conflicts:** branch names follow the lifecycle structure; the model supplies ids only.
- **Worktree incoherence:** if git worktree state disagrees with the planner database, run recovery tools immediately.

## manual-compact

Preserve current branch, HEAD, dirty/conflict status, managed branch registry, merge targets, cleanup obligations, and the exact next wrapper. After compaction, call `planner_status`.

## auto-compact

Call `planner_status` immediately. Inspect git through planner wrappers before resuming. Do not infer current branch or commit from compacted chat history.

## If You Do Not Know What To Do Next

The `planner_finish_step` result names your next step, its goal, and the worktree to work in — follow it. Call `planner_status` only when you need the full step rule or stage instruction, or when you are unsure.
