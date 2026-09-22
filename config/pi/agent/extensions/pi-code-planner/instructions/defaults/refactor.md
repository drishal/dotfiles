# refactor

## Purpose

Challenge and improve the current task implementation after production code is committed. Refactor changes structure, clarity, naming, duplication, or integration quality without changing requested behavior.

KISS does not mean avoiding advanced language features. Traits, interfaces, generics, macros, and other abstractions are valid when the current task needs them. KISS means every abstraction, branch, type, helper, and extension point must justify its existence through the current behavior or existing project design. Do not add flexibility for imagined future work.

## Required Process

1. Read `task.md`, `tdd.md`, existing `refactor.md`, and focused source files only when needed.
2. Inspect the current task-branch diff through planner wrappers.
3. Question the implementation actively:
   - Can any helper, abstraction, branch, conversion, or validation path be removed or made clearer?
   - Is any code duplicated, speculative, over-generalized, or implemented for future use rather than the current task?
   - Does the implementation match existing project conventions and confirmed user decisions?
   - Are signatures and effects still as small and explicit as possible?
   - If you think no refactor is needed, what concrete diff fact proves that changing it would make the code worse?
4. Call `planner_refactor_review` with concrete review fields and every required category review. The wrapper writes `refactor.md` in the required format. A passing test, linter, formatter, or build is not a refactor review.
5. Apply only behavior-preserving changes.
6. Run focused tests from the worktree path reported by `planner_status` after each meaningful refactor group.
7. Commit through planner wrappers if files changed, and update task artifacts when the refactor changes relevant implementation details.
8. If the review proves a reusable refactor/debugging lesson, a repeated mistake, a stale-context pattern, or a category-specific audit method, call `planner_skill_create` with `sourceKind=refactor` before leaving this step.

## Restrictions

- Do not add new scope or weaken tests to make refactor pass.
- Do not change public API unless the active task explicitly requires it.
- Do not perform speculative cleanup outside the active task.
- Do not claim refactor is unnecessary merely because tests, a linter, or a formatter pass. Tool output is evidence, not design review.
- Do not run project tests, builds, formatters, or other verification from the original checkout. Use the planner worktree as shell cwd.
- If a behavior change is required, stop and return to planning or create a new task.
- Do not use raw git.

## Exit Condition

Refactor is complete only when `refactor.md` passes the structured review gate, checks pass, the diff stays within task scope, and changed files are committed.

## Evidence Discipline

Treat refactor as hostile review of the actual diff, not a style ritual.

- Do not write "no refactor needed" until each category has concrete evidence.
- Passing tests, formatters, or linters do not prove naming, coupling, control flow, or abstraction are acceptable.
- If a cleanup would change behavior or expand scope, record it as deferred instead of smuggling it into refactor.
- If the diff reveals missing behavior or missing tests, return to TDD/planning rather than hiding it under refactor.

## refactor.md Format (written by planner_refactor_review)

Do not hand-write this file. Pass semantic fields to the tool and let the wrapper write these exact level-two headings, each filled with concrete observations from the active task diff.

```md
# Refactor Review

## Changed Surface
- Files:
- Behavior touched:
- Public API touched:

## Complexity
- Unnecessary abstraction:
- Over-generalization:
- Simpler alternative considered:

## Duplication
- New duplication:
- Existing duplication touched:
- Decision:

## Naming And Boundaries
- Confusing names:
- Module/API boundary issues:
- Scope leaks:

## Edge Cases
- Validation/error handling:
- State consistency:
- Regression risk:

## Category Review
### duplication
- status: ok | issue | not_applicable
- evidence:
- action:

### naming
- status: ok | issue | not_applicable
- evidence:
- action:

### control_flow
- status: ok | issue | not_applicable
- evidence:
- action:

### abstraction_level
- status: ok | issue | not_applicable
- evidence:
- action:

### hidden_coupling
- status: ok | issue | not_applicable
- evidence:
- action:

### error_handling
- status: ok | issue | not_applicable
- evidence:
- action:

### test_clarity
- status: ok | issue | not_applicable
- evidence:
- action:

### debug_leftovers
- status: ok | issue | not_applicable
- evidence:
- action:

### scope_creep
- status: ok | issue | not_applicable
- evidence:
- action:

## Refactor Decision
Decision: changed | kept

## Changes Applied
- ...

## Why Kept
- ...
```

If `Decision: changed`, `## Changes Applied` must describe the behavior-preserving edits. If `Decision: kept`, `## Why Kept` must explain why changing the actual diff would make the code worse or add unnecessary complexity. Do not write generic claims such as "tests pass" or "code is already good".

Every category must be reviewed exactly once. Use `status: issue` when a behavior-preserving improvement is needed; use `status: not_applicable` only with concrete evidence explaining why that category does not apply to the active diff.

## Doubt Checkpoint

Refactor doubt is mandatory but bounded:

- Find one concrete simplification opportunity, or one concrete reason each tempting change should be rejected.
- Do not refactor unrelated code to satisfy doubt, and do not invent abstractions to look thoughtful.
- Do not treat tool success as design proof.

## Planner Skill Memory

Create a planner skill only when refactor review finds a transferable rule that future tasks should reuse, such as a recurring boundary mistake, a hidden coupling pattern, or a reliable simplification method. Do not create a skill for "no refactor needed" or a one-off project detail. Use `metadata.skillLanguage` for the body; keep the Pi skill `description` trigger-specific.

## Diagnostics

- **Behavior changes:** refactoring must not change external behavior. A test failing after refactor means this rule was violated.
- **Dead code & lint:** remove old/dead paths cleanly; run formatting/linting after refactor to catch unused imports.
- **Recovery:** if a refactor attempt breaks tests and cannot be easily fixed, revert to the clean task-branch HEAD. Refactor in small steps, committing after each successful one.

## manual-compact

Preserve active task id, refactor intent, changed files, checks, commit, and any deferred cleanup. After compaction, call `planner_status` before continuing.

## auto-compact

Call `planner_status` immediately. Reload `task.md`, `tdd.md`, and `refactor.md`. Confirm whether refactor changes were committed before resuming.

## If You Do Not Know What To Do Next

The `planner_finish_step` result names your next step, its goal, and the worktree to work in — follow it. Call `planner_status` only when you need the full step rule or stage instruction, or when you are unsure.
