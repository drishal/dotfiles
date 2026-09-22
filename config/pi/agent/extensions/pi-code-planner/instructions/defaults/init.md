# init

## Purpose

Initialize planner control before any project discovery or implementation begins.

The normal entry point is `planner_create_plan` or `/planner-create`. The extension runs init as an internal atomic bootstrap and should leave the persisted position at `intake/draft_goal`. If `planner_status` exposes an init step, follow the exact step rule and do not skip ahead.

## Required Discipline

1. Resolve the opened project root and stable project id.
2. Check whether git is available through planner wrappers.
3. Initialize git only when the repository does not exist and the controlled flow allows it.
4. Prepare project storage, settings, instruction files, and plan artifacts.
5. Resolve the worktree location from effective settings. Do not invent a path.
6. Create exactly one dedicated worktree for the whole plan.
   - For a project-local worktree, the extension writes a repository-local exclude rule for the original checkout and commits it on the plan branch before normal work begins.
7. Enter `intake/draft_goal`.

## Restrictions

- Do not read source code for task understanding during init.
- Do not edit project files.
- Do not create tasks, task branches, or commits.
- Do not run raw git through shell.
- Do not edit `project.json`, `plan.json`, `state.json`, or worktree indexes directly.
- If bootstrap state is inconsistent, call `planner_status` and use recovery guidance.

## Exit Condition

Init is complete only when the plan record exists, the plan worktree exists, the active branch is recorded, and state points to `intake/draft_goal`.

## Evidence Discipline

Treat init as untrusted bootstrap until persisted state proves otherwise.

- Do not say init is healthy from memory or from one file existing.
- Verify the current state through `planner_status` and exact storage paths.
- If bootstrap facts conflict, stop and enter recovery instead of guessing the next stage.
- Do not continue from optimistic assumptions after auto-compact.

## Diagnostics

- **Worktree conflicts:** if worktree creation fails, check for an existing directory of the same name, a dirty repository, or a locked index (`.git/index.lock`).
- **Workspace resolution:** the cwd must be inside the workspace root. Never initialize a plan in `/tmp` or a system directory.
- **State inconsistency:** if plan files exist but no active plan is detected, use recovery tools — do not manually recreate files. Consider `planner_git_init` only when git is uninitialized in the project root.

## auto-compact

An auto-compact during init does not authorize progress. Call `planner_status`, reload the exact persisted init step, and continue only with the wrapper reported by status. Do not inspect source until intake is approved and state explicitly says `discovery/scan_project_structure`.

## If You Do Not Know What To Do Next

The `planner_finish_step` result names your next step, its goal, and the worktree to work in — follow it. Call `planner_status` only when you need the full step rule or stage instruction, or when you are unsure.
