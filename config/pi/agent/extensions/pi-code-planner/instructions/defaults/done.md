# done

## Purpose

Present the verified plan result, wait for an explicit user decision, then either return to planning for requested changes or export one clean output branch and remove temporary planner state.

## Strict Step Order

1. `present_result`
   - Read `final_summary.md` and present scope, checks, risks, plan branch, worktree path, and output options.
   - If a verified reusable lesson is still missing from the skill library, call `planner_skill_create` before asking for acceptance. Do not create skills for ordinary summaries.
   - After presenting, call `planner_finish_step` immediately to enter `await_user_acceptance`.
2. `await_user_acceptance`
   - Ask the user to accept the result or request changes. Never decide on their behalf.
   - If the user accepts, write in your response text (no tool call): "/planner-finish is a Pi slash command — I cannot invoke it as an LLM. Run it yourself in Pi to export the result." Do not use ask_user or any other tool to ask this.
   - If the user writes what is wrong or requests more work instead of running `/planner-finish`, treat that as a change request: call `planner_finish_step` with target `done/handle_change_request`.
   - `/planner-finish` atomically performs the remaining export, cleanup, and Pi session handoff. Do not try to reproduce that cleanup through model tools.
3. `handle_change_request`
   - Record user feedback in durable artifacts.
   - Append a `## Change Request` section to `decisions.md` with the user's exact requested corrections.
   - Update `plan.md` (via `planner_plan_submit` or edit): add a short `## Change Request Replan` note near the start — the previous implementation is complete, but the user requested follow-up changes — with `### Completed Work` and `### Remaining Work` subsections. Do not rewrite the old plan wholesale or delete prior history.
   - Update `discovery.md` (via `planner_discovery_submit` or edit): add a `## Post-Implementation Snapshot` summarizing what was implemented, current relevant files/branches, known gaps, and why another pass was requested, with `### Completed Work` and `### Remaining Work` subsections.
   - Treat existing task artifacts as completed history. The follow-up planning pass may create new revision tasks for remaining work, but must not reopen completed task IDs.
   - For a plan with `spec.json`: return to `spec/draft_requirements` — the change request amends the SPEC first (add/adjust `REQ-n` via `planner_spec_submit`; the previous version is preserved automatically as `spec.prev.json`), then `verify_spec` and the planning coverage gate re-run, so a requirement can never be dropped silently across versions. Legacy plans (no `spec.json`): return to `planning/read_context` directly. Same plan worktree and branch in both cases.
4. `prepare_output_branch` — internal `/planner-finish` phase: prepare the output branch in the original repository.
5. `merge_or_export_result` — internal `/planner-finish` phase: export the plan branch result.
6. `cleanup_worktree` — internal `/planner-finish` phase: remove the temporary worktree and safe-to-delete managed child branches.
7. `mark_done` — internal `/planner-finish` phase: clear active plan state and mark the result complete.
8. `cleanup_plan_files` — internal `/planner-finish` phase: remove completed plan artifacts only after `mark_done`.

## Acceptance Rules

- `/planner-finish` is an explicit user acceptance command. It may finalize directly after `present_result` or during `await_user_acceptance` when all runtime gates are clean.
- No production edits are allowed in done.
- Change requests preserve the worktree and return to planning. Cleanup requires explicit acceptance.
- During normal work the protected plan branch is never deleted by managed child cleanup. After successful `/planner-finish`, the temporary plan branch is removed because its result is already exported.
- The user keeps exactly one output branch in the original repository and decides whether to merge, rebase, or delete it.
- If the original Pi JSONL session exists, `/planner-finish` returns to it and removes the completed worktree chat. If it is missing, `/planner-finish` warns the user, creates a replacement project-root session, and asks whether to remove the completed worktree chat.
- Raw git is forbidden.

## Evidence Discipline

Treat done as a user-decision gate, not proof that the implementation is correct.

- Do not reinterpret user hesitation as acceptance.
- Do not hide risks or skipped checks from `final_summary.md`.
- If the user reports a problem, preserve completed work and route the change request back through planning.
- Do not cleanup or export until the persisted decision state allows it.

## Change Request Reload

When returning to `planning/read_context`, reread full `plan.md`, `decisions.md`, user feedback, and `discovery.md` via `planner_artifact_read`. Treat the previous implementation as current project context, not a blank project. Preserve completed work, revise the plan only where the change request requires it, then continue toward execution. Existing completed task artifacts remain audit history. Do not repeat tasks under `Completed Work`; create new revision task IDs only for work under `Remaining Work`.

## Planner Skill Memory

`planner_skill_create` is allowed in `present_result` only as a final catch-up for a reusable lesson already verified during execution or finalize. Skills are loaded in future planner sessions via Pi `resources_discover`; they do not replace the done-state acceptance flow.

## auto-compact

Call `planner_status` immediately. Reread `final_summary.md` and the exact persisted decision state. Do not infer acceptance from previous chat context. Only explicit user acceptance authorizes export and cleanup.

## If You Do Not Know What To Do Next

The `planner_finish_step` result names your next step, its goal, and the worktree to work in — follow it. Call `planner_status` only when you need the full step rule or stage instruction, or when you are unsure.
