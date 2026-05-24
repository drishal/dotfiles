# Pi Setup Guide

This document is a **self-contained, machine-executable** setup guide.
A fresh pi instance should be able to read this file and configure everything.

## Prerequisites (Do These Manually First)

Before running the automated setup, ensure:

1. **pi is installed** — `npm i -g @earendil-works/pi-coding-agent`
2. **At least one provider is authenticated** — pi needs a working model to run the setup.
   Use whichever is available on this machine:
   - `pi --provider openai-codex` (Codex / OpenAI — `OPENAI_API_KEY` env or `pi auth openai-codex`)
   - `pi --provider anthropic` (Claude — `ANTHROPIC_API_KEY` env or `pi auth anthropic`)
   - `pi --provider google` (Gemini — `GEMINI_API_KEY` env)
   - Custom provider via env vars (see instructions.txt for local model servers)
3. **Node.js 20+** and **npm** available
4. **git** available (for skill installation)

## Step 1: Discover Available Models

Run `pi --list-models` and capture the output. This tells you what providers
and models are available on this machine.

## Step 2: Assign Models to Roles

### Role Definitions

These roles are fixed across all machines. The model IDs change, but the
role semantics don't.

| Role | Purpose | Needs | Tier | Thinking |
|------|---------|-------|------|----------|
| oracle | Complex reasoning, architecture decisions | reasoning | best | high |
| planner | Task decomposition, planning | reasoning | best | high |
| worker | Code generation, file edits | coding | mid | medium |
| reviewer | Code review, quality checks | reasoning | high | high |
| scout | Quick lookups, cheap operations | coding | fast | off |
| researcher | Research, documentation lookup | reasoning | mid | medium |
| context-builder | Context gathering, file reading | coding | fast | off |
| delegate | Orchestrating other agents | reasoning | best | high |

> **Note:** If you're unfamiliar with a model's capabilities, check the web
> for its benchmarks, reasoning support, and context window before assigning it.
> Don't guess — a wrong assignment (e.g., putting a non-reasoning model in a
> reasoning role) significantly degrades pi's performance.

### Assignment Rules

Given the output of `pi --list-models`, assign models using these rules:

1. **For tier:best roles** (oracle, planner, delegate):
   - Pick the strongest **reasoning** model available
   - Preference order by capability: models with larger context windows > more max output > reasoning support
   - Cost is not a concern for tier:best
   - If multiple reasoning models exist, prefer the one with the best benchmark reputation
   - **Always set 2 fallback models** (second-best reasoning, third-best reasoning)

2. **For tier:high roles** (reviewer):
   - Pick a strong reasoning model, can be slightly weaker than tier:best
   - If only one reasoning model exists, reuse it
   - Set 2 fallbacks

3. **For tier:mid roles** (worker, researcher):
   - Pick a solid coding/reasoning model — balanced between quality and speed
   - If a dedicated coder model exists (name contains "coder", "codex"), prefer it for worker
   - For researcher, prefer a reasoning model that's not the most expensive
   - Set 2 fallbacks

4. **For tier:fast roles** (scout, context-builder):
   - Pick the cheapest/fastest model available
   - Mini/flash/haiku/small models preferred
   - Non-reasoning models are fine here (thinking is off anyway)
   - If only large models exist, pick the cheapest one
   - Set 2 fallbacks

5. **Default provider and model**:
   - Set `defaultProvider` and `defaultModel` to the oracle model's provider and id
   - This ensures pi starts with the strongest model by default

### Model Assignment Template

Generate the `subagents.agentOverrides` section following this structure.
Every model ID must use `provider/id` format:

```json
{
  "oracle": {
    "model": "<provider>/<best-reasoning-model>",
    "thinking": "high",
    "fallbackModels": ["<provider>/<2nd-reasoning>", "<provider>/<3rd-reasoning>"]
  },
  "planner": {
    "model": "<provider>/<best-or-2nd-reasoning>",
    "thinking": "high",
    "fallbackModels": ["<provider>/<reasoning>", "<provider>/<reasoning>"]
  },
  "worker": {
    "model": "<provider>/<best-coder-or-mid-reasoning>",
    "thinking": "medium",
    "fallbackModels": ["<provider>/<alt>", "<provider>/<alt>"]
  },
  "reviewer": {
    "model": "<provider>/<strong-reasoning>",
    "thinking": "high",
    "fallbackModels": ["<provider>/<reasoning>", "<provider>/<reasoning>"]
  },
  "scout": {
    "model": "<provider>/<cheapest-fastest>",
    "thinking": "off",
    "fallbackModels": ["<provider>/<alt-cheap>", "<provider>/<alt-cheap>"]
  },
  "researcher": {
    "model": "<provider>/<mid-reasoning>",
    "thinking": "medium",
    "fallbackModels": ["<provider>/<reasoning>", "<provider>/<reasoning>"]
  },
  "context-builder": {
    "model": "<provider>/<cheapest-fastest>",
    "thinking": "off",
    "fallbackModels": ["<provider>/<alt-cheap>", "<provider>/<alt-cheap>"]
  },
  "delegate": {
    "model": "<provider>/<best-reasoning>",
    "thinking": "high",
    "fallbackModels": ["<provider>/<2nd-reasoning>", "<provider>/<3rd-reasoning>"]
  }
}
```

## Step 3: Write settings.json

**Important: Merge with existing settings, do not overwrite.**

If `~/.pi/agent/settings.json` already exists, read it first and merge your
changes into it. Specifically for the `packages` array:

- **Keep** any packages already present in the existing file
- **Append** any packages from the base list below that are not already present
- **Do not duplicate** entries (e.g., if `npm:pi-mcp-adapter` is already there,
  don't add it again)

Base packages list (add any that are missing from the existing file):

```
npm:pi-mcp-adapter
npm:pi-web-access
npm:pi-subagents
npm:pi-mono-ask-user-question
npm:pi-mono-auto-fix
npm:pi-mono-btw
npm:pi-mono-clear
npm:pi-mono-context
npm:pi-mono-context-guard
npm:pi-mono-linear
npm:pi-mono-loop
npm:pi-mono-multi-edit
npm:pi-mono-review
npm:pi-mono-sentinel
npm:pi-mono-simplify
npm:pi-mono-status-line
npm:pi-mono-team-mode
npm:pi-mono-usage
npm:pi-lsp-extension
```

Write `~/.pi/agent/settings.json` with the merged result:

```json
{
  "defaultThinkingLevel": "high",
  "defaultProvider": "<resolved-from-step-2>",
  "defaultModel": "<resolved-from-step-2>",
  "packages": ["<merged-packages-array>"],
  "subagents": {
    "agentOverrides": {
      "<resolved-assignments-from-step-2>"
    }
  }
}
```

## Step 4: Install Extensions

### LSP Configuration

Write `~/.pi/agent/extensions/lsp/config.json`:

```json
{
  "lsp": {
    "typescript": {
      "command": ["typescript-language-server", "--stdio"],
      "extensions": [".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".mts", ".cts"]
    },
    "rust": {
      "command": ["rust-analyzer"],
      "extensions": [".rs"]
    }
  }
}
```

Add more language servers as needed based on what's installed on this machine.
Common additions:
- Python: `{"command": ["pylsp"], "extensions": [".py"]}`
- Go: `{"command": ["gopls"], "extensions": [".go"]}`
- C/C++: `{"command": ["clangd"], "extensions": [".c", ".cpp", ".h", ".hpp"]}`

## Step 5: Install Packages

Run npm install to set up all extension packages:

```bash
cd ~/.pi/agent/npm && npm install
```

Pi auto-generates `package.json` from the `packages` list in settings.json
and installs them.

## Step 6: Install Skills

Install skills from their git sources:

```bash
pi skill install github:microsoft/azure-skills microsoft-foundry
pi skill install github:vectorize-io/hindsight hindsight-docs
pi skill install github:vercel-labs/skills find-skills
```

## Step 7: Configure MCP Servers

MCP servers are configured via pi's mcp-adapter extension. The current setup
uses Context7 for documentation lookup. It auto-installs via npx on first use,
so no manual setup is needed.

The MCP server config is stored in pi's internal cache and auto-managed.
Just use pi normally and it connects on demand.

## Step 8: Configure Web Search

Write `~/.pi/web-search.json`:

```json
{
  "workflow": "none",
  "curatorTimeoutSeconds": 20
}
```

## Step 9: Authenticate Providers

These MUST be done manually — tokens cannot be copied between machines:

- **OpenAI Codex**: Run `pi auth openai-codex` (opens browser OAuth)
- **Linear**: Run `pi linear auth` (prompts for personal API key)
- **Other providers**: Set the appropriate env var (e.g., `ANTHROPIC_API_KEY`,
  `GEMINI_API_KEY`, `DEEPSEEK_API_KEY`, etc.)

## Step 10: Verify Setup

Run these commands to verify everything is working:

1. `pi --list-models` — should show all expected models
2. `pi -p "What model are you?"` — should respond with the default model
3. `pi` (interactive) — launch and check that extensions load without errors
4. `/model` in interactive mode — verify model switching works
5. Test a skill: ask pi to use context7 or linear to verify integrations

## Quick Setup Command

Once providers are authenticated, the entire setup can be driven by:

```bash
pi --model <strongest-available-model> -p @SETUP.md "Follow this setup guide. Start from Step 1 and complete all steps sequentially. Use the tools available to you to write files and run commands."
```

Replace `<strongest-available-model>` with the best model shown by
`pi --list-models` on this machine.

### Minimal Setup (One Provider Only)
- If only one provider with one model is available, all roles use that model
- Fallbacks can be omitted or set to the same model
- This works but you lose the cost optimization of tier:fast roles
