# git-commit

## Purpose

Generate concise planner-controlled commit and merge messages. This file controls message style only. It never changes branch lifecycle, merge targets, or permission rules.

## Commit Message Rules

- Use imperative mood and keep the subject concise and specific.
- Describe the completed atomic checkpoint, not the implementation process.
- Prefer one clear subject line; mention the task or behavior when it improves clarity.
- Do not include raw model reasoning, temporary uncertainty, or verbose test logs.
- Do not use vague subjects such as `update files`, `fix stuff`, `changes`, or `wip`.
- Do not claim tests passed unless checks were actually run.
- Use `metadata.commitLanguage` from `planner_status` for human-readable text unless repository conventions or explicit user instructions override it. Conventional type prefixes (`feat:`, `fix:`, `test:`) are technical tokens, not translatable text.

## Suggested Subjects

```text
test: cover <behavior>
feat: implement <behavior>
fix: handle <edge case>
refactor: simplify <component>
docs: record <decision>
```

Use the repository's existing convention when discoverable. Project append instructions may override language, prefix style, scope style, merge subject style, and team conventions.

## Merge Messages

- Refactor -> task: identify the behavior-preserving cleanup.
- Task -> plan: identify the completed atomic task.
- Plan -> output: use a conventional commit subject and a short body in `metadata.commitLanguage`. Include the plan title/id, output branch, and a concise summary of completed behavior. Do not use a vague one-line "merge result" message.

## Restrictions

- Never call raw `git commit`.
- Never choose merge branches from this document.
- Never rewrite history to polish messages automatically.

## Evidence Discipline

Treat commit text as an audit artifact.

- The subject and body must describe the actual diff, not the planner process alone.
- If checks were skipped, failed, or unknown, say so in the allowed artifact before committing; do not imply success in the commit body.
- Merge/export commits must summarize completed behavior from `plan.md`, task artifacts, and final verification, not a generic acceptance phrase.
- If the diff and task record disagree, resolve that mismatch before writing the commit.

## Diagnostics

- **Empty commits:** if a commit fails, confirm tracked files actually changed.
- **Locked index:** if the git index is locked, identify the holding process and advise the user or wait.
- **Wrong branch:** if you committed to the wrong branch, use planner git wrappers to inspect HEAD; do not attempt force pushes.
- Use the `planner_git_inspect` wrapper to confirm staged/modified/untracked state.

## auto-compact

After auto-compact, call `planner_status`. Use this style only when the current stage explicitly allows a planner commit or merge wrapper.

## If You Do Not Know What To Do Next

The `planner_finish_step` result names your next step, its goal, and the worktree to work in — follow it. Call `planner_status` only when you need the full step rule or stage instruction, or when you are unsure.
