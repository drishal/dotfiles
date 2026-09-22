# neat-render thinking-fold test

Run inside `~/dotfiles`. Each prompt is designed to make the model quote code
*while reasoning*, which is what `NEAT_RENDER_FOLD_THINKING` folds.

Expected: in the thinking block, fenced code disappears and the sentence before
it gains a trailing `...`. Tool rows and the final answer are untouched.

---

## 1. Quote-then-compare (most reliable)

> Read `config/pi/agent/settings.json` and `config/pi/agent/AGENTS.md`.
> While you reason, quote the exact JSON of the `compaction` block and the
> exact Tool Rules section in fenced code blocks, then tell me in one
> sentence whether the thinking level matches what AGENTS.md implies.

## 2. Reason over a diff

> Look at `git diff config/pi/SETUP.md`. In your reasoning, paste the two
> hunks you consider most important as fenced diff blocks before you judge
> them. Then give a one-line verdict.

## 3. Draft-in-thinking

> Draft three different one-line shell commands to count tracked files by
> extension in this repo. Write each candidate as a fenced bash block in your
> reasoning, compare them, then output only the winner.

## 4. Unterminated fence (streaming edge case)

> Think out loud while writing a long Python function that parses
> `config/pi/agent/mcp.json`. Show the function in a fenced block inside your
> reasoning as you build it up, then summarise what it does in one line.

---

## Checks

- Fold on:  `pi`                                  → code gone, prose ends `...`
- Fold off: `NEAT_RENDER_FOLD_THINKING=0 pi`      → code shown verbatim
- Compare the same prompt both ways.

Nothing is lost: the fold is display-only. `ctrl+o` and the session JSONL keep
the full text, and the model's own context is unchanged.
