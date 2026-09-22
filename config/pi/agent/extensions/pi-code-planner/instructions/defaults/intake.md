# intake

## Purpose

Turn the user's raw request into an explicit approved goal before reading project source. Intake protects the planner from implementing an inferred title or an ambiguous task.

## Strict Step Order

1. `draft_goal`
   - Read `request.md` with `planner_artifact_read` (`artifact: "request"`), not the built-in read tool — it lives outside the worktree. Then draft the `goal.md` content in your own words: requested outcome, current assumptions, non-goals, and constraints.
   - Do not invent project-specific questions before reading project evidence.
   - Call `planner_goal_submit` with the full goal markdown, proposed title, and short planner-list description. The wrapper writes `goal.md`; built-in write/edit cannot.
   - Use `metadata.titleLanguage` from `planner_status` for the title unless the user explicitly requests another language. The title is user-facing and may contain Unicode; it is not the stable branch-safe `planId`.
   - Do not inspect project source.
2. `await_goal_approval`
   - Show the user the full generated `goal.md` content (the `planner_goal_submit` result includes it for review).
   - Explain that `plan.md` is written later, during `planning/draft_plan`, after discovery and evidence-based questions.
   - Ask whether the goal and proposed title are approved or need revision.
   - If revision is requested, call `planner_goal_submit` again with the revised goal markdown and title, then ask again.
   - Enter discovery only after explicit approval.

## Restrictions

- Do not inspect project source, manifests, tests, or implementation files.
- Do not implement code or write tests.
- Do not create tasks.
- Do not infer approval from silence.
- Do not use raw git.

## Exit Condition

Intake is complete only after `goal.md` reflects the user's intent and the user explicitly approves it.

Evidence-based clarification questions belong to `discovery/write_questions`, after the model has indexed the project. Intake may ask the user only when the requested outcome itself is too ambiguous to normalize.

## Evidence Discipline

Treat the normalized goal as a hypothesis until the user explicitly approves it.

- Do not inflate the user's request into implementation details.
- Do not hide assumptions inside confident wording.
- If the goal depends on facts that require source evidence, record them as assumptions and leave them for discovery.
- Approval must be explicit; silence, momentum, or previous chat tone is not approval.

## Doubt Checkpoint

Before finishing an intake step, doubt the normalized goal:

- Did `goal.md` preserve the user's actual request rather than a convenient nearby task?
- Are assumptions, non-goals, and constraints explicit enough for later review?
- Is approval explicit, or are you inferring it from silence?

If doubt remains, revise `goal.md` or ask one concrete intake question. Do not enter discovery on an inferred goal.

## Diagnostics

- **Underspecified outcomes:** if the request lacks concrete metrics ("make it faster", "fix bugs"), do not guess. Draft `goal.md` with explicit, testable criteria and confirm with the user.
- **Assumptions vs facts:** list technical assumptions under a dedicated header in `goal.md`; treat any unconfirmed assumption as a risk.
- **Scope creep:** define Non-Goals clearly so the model does not wander into unrelated code.
- **Rejected goal:** do not argue. Ask for specific feedback, rewrite, re-submit. Never move to discovery without a signed-off `goal.md`.

## auto-compact

Call `planner_status` immediately. Read `request.md` and `goal.md` via `planner_artifact_read`, then resume the exact intake step. Do not begin discovery without explicit approval.

## If You Do Not Know What To Do Next

The `planner_finish_step` result names your next step, its goal, and the worktree to work in — follow it. Call `planner_status` only when you need the full step rule or stage instruction, or when you are unsure.
