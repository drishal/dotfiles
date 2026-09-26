# pi agent setup

Runbook for recreating the pi coding-agent configuration on this machine.
Follow it top to bottom. It assumes the dotfiles repo is checked out at
`~/dotfiles` and NixOS + Home Manager are already applied.

> **Fast path.** The tracked config now lives in this repo under
> `config/pi/agent/`, mirroring `~/.pi/agent/` one-for-one, and
> `bootstrap.sh` wires it up:
>
> ```bash
> ~/dotfiles/config/pi/bootstrap.sh --check   # report drift, change nothing
> ~/dotfiles/config/pi/bootstrap.sh           # link config, npm ci, re-patch
> ```
>
> That covers steps 4, 5, 6, 7 and the zentui patch. You still need steps 1–2
> (install pi, set up models) and the machine-specific items in step 9.
> Read on when you want to understand a piece, or are setting up somewhere
> `bootstrap.sh` can't run.
>
> `bootstrap.sh` **symlinks** most config back to this repo, so editing a file
> here edits the live one. Three files are **copied** instead, because pi and
> npm rewrite them in place and a read-only symlink would break
> `pi install` / `npm install`: `settings.json`, `npm/package.json`,
> `npm/package-lock.json`. Those drift silently — `--check` reports when they
> have, and you copy them back by hand.

> **Out of scope: models & API keys.** You (the user) set these up first
> yourself — `pi`, then `/login` for a subscription provider or drop an API
> key into `~/.pi/agent/models.json`, then pick a model with `/model` (or
> Ctrl+L). Nothing below touches `models.json` or `auth.json`. This guide
> covers everything _around_ the models: the install, MCP servers,
> extensions, skills, and the seeded memory.

## Prerequisites

- **Node.js + npm**, with the global npm prefix set to `~/.node_modules`
  (so `npm i -g` lands in `~/.node_modules/lib/node_modules` and binaries
  in `~/.node_modules/bin`, which must be on `PATH`). This is provided by
  the Home Manager shell config.
- **uv / uvx** — used by the `nixos` MCP server. Install via
  `pipx install uv` or the standalone installer; ensure `uvx` is on `PATH`.
- **CLI tools the seeded memory rules assume:** `gh` (GitHub CLI),
  `obscura` (Rust headless browser, see below).

### SearXNG (optional — private search backend for `pi-web-access`)

Web search comes from the `pi-web-access` extension (step 6), not an MCP
server. It works with **no configuration** — Exa MCP serves it keyless. SearXNG
is optional and only worth wiring if you want search that never leaves your
network.

`pi-web-access` reads `web-search.json`, resolved in this order: the dir named
by `PI_CODING_AGENT_DIR`, then `$XDG_CONFIG_HOME/pi/`, then `~/.pi/`, then
`~/.pi/agent/`. Any of those works.

```json
{
  "searxngBaseUrl": "http://127.0.0.1:48431",
  "searchRouting": { "providers": ["searxng", "exa"],
                     "fallbackOn": ["transient", "quota", "network", "invalid-response"] },
  "fetchRouting":  { "providers": ["http", "jina"], "allowRemoteHostedProviders": false },
  "maxInlineContentChars": 30000,
  "ssrf": { "allowLoopback": true, "allowRanges": ["127.0.0.0/8"] }
}
```

> **The `ssrf` block is required for a local SearXNG, and needs both keys.**
> They are separate code paths: `allowLoopback` permits the *hostname*
> `localhost`, while `allowRanges` permits *IP addresses*. A `searxngBaseUrl`
> of `http://127.0.0.1:…` is an IP, so `allowLoopback` alone still fails with
> `Blocked internal address for 127.0.0.1`, and search silently falls back to
> a public provider. Set both.

On NixOS the service is declared at `NixOS/hosts/common/searx.nix`. Three
settings there matter to pi:

- `server.port` — must match `searxngBaseUrl`
- `search.formats` — must include `"json"`, or the API returns HTML only
- `server.limiter = false` — the rate limiter rejects programmatic queries

Verify with `curl "http://127.0.0.1:<port>/search?q=test&format=json"`. If you
are not running SearXNG, omit `searxngBaseUrl` and `ssrf` entirely; routing
falls through to the public providers.

## 1. Install pi

```bash
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
pi --version     # expect 0.86.x or newer
```

`--ignore-scripts` is the documented install flag (pi needs no lifecycle
scripts). The binary ends up at `~/.node_modules/bin/pi`. If pi is already
installed and `pi --version` shows 0.86.x+, skip to step 2.

> **Config location.** Everything below assumes the default `~/.pi/agent/`.
> `PI_CODING_AGENT_DIR` overrides it, and `PI_CODING_AGENT_SESSION_DIR`
> relocates sessions alone. Don't point `PI_CODING_AGENT_DIR` at this repo:
> `auth.json`, `models.json` and `sessions/` resolve off the same root and
> would land in git. That's why `bootstrap.sh` symlinks individual files
> instead.

## 2. Set up your models (you do this, not this guide)

Launch `pi`, run `/login` (subscription) or add an API key to
`~/.pi/agent/models.json`, then `/model`. Confirm a chat works before
continuing — the MCP servers and extensions below are useless without a
working model.

## 3. Directory layout (`~/.pi/agent/`)

pi creates most of this on first run. What matters:

| Path                                   | Purpose                                    | Managed here? |
| -------------------------------------- | ------------------------------------------ | ------------- |
| `models.json`                          | Providers + API keys                       | **No** (you)  |
| `auth.json`                            | OAuth tokens from `/login`                 | **No** (pi)   |
| `settings.json`                        | Global settings, extensions, theme         | Yes (step 4)  |
| `mcp.json`                             | MCP server definitions                     | **No** (yours; suggestions in step 5) |
| `npm/package.json` + `-lock.json`      | Extension manifest (`node_modules` is not tracked — restore with `npm ci`) | Yes (step 6) |
| `extensions/`                           | Local TypeScript extensions               | See step 7    |
| `skills/`                              | User-global skills (`SKILL.md` per dir)    | Yes (step 7)  |
| `themes/`                              | base16/base24 YAML (→ JSON via `base16-theme.ts`) or pi theme JSON | Yes (step 4) |
| `patches/`                             | Local patches into `node_modules` + applier | Yes (step 6b) |
| `zentui.json`, `pi-fff.json`, `subagents.json` | Per-extension config              | Yes (linked)  |
| `AGENTS.md`                            | Global system prompt + MCP routing rules   | Yes (linked)  |
| `mcp-cache.json`, `mcp-npx-cache.json` | Auto-generated MCP tool caches             | Auto          |
| `sessions/`, `trust.json`, `pi-acp/`   | Runtime state                              | Auto          |

`AGENTS.md` is worth calling out: it carries the MCP routing rules that tell
the model which tool to reach for (`web_search`/`web_fetch` for the web,
obscura for pages that need a real browser, grep_app for public code, context7
for library docs, nixos for packages; memory is the mem0 extension, step 8). Without it the
servers are present but rarely chosen well.

## 4. `settings.json` (non-model settings)

Write `~/.pi/agent/settings.json` — but if the file **already exists**
(because the user already ran `/model`), **merge these keys in; do not
overwrite the file**. `/model` writes `defaultProvider` / `defaultModel`
into `settings.json`, and blindly replacing the file wipes the model the
user just configured. Preserve any existing `defaultProvider`,
`defaultModel`, and `auth`-related keys; only add/update the keys below.
The `defaultProvider` / `defaultModel` keys are model-related and are
written by pi on `/model` — leave them out of what you add.

```json
{
  "theme": "gruvbox-material",
  "packages": [
    "npm:@ff-labs/pi-fff",
    "npm:@gamaraan/todos-tool",
    "npm:@narumitw/pi-plan-mode",
    "npm:pi-background-tasks",
    "npm:pi-hashline-edit-pro",
    "npm:pi-lens",
    "npm:pi-mcp-adapter",
    "npm:pi-mono-ask-user-question",
    "npm:pi-mono-auto-fix",
    "npm:pi-mono-btw",
    "npm:pi-mono-context",
    "npm:pi-mono-review",
    "npm:pi-simplify",
    "npm:pi-web-access",
    "npm:pi-x-search",
    "npm:pi-zentui@0.25.0"
  ],
  "defaultThinkingLevel": "max",
  "compaction": {
    "enabled": true,
    "reserveTokens": 45000,
    "keepRecentTokens": 30000
  },
  "markdown": { "mermaid": "final" }
}
```

- `packages` is the list of extensions pi auto-installs into `~/.pi/agent/npm/`
  on startup (and via `pi install <pkg>`). See step 6.

> **`packages` is the only thing that loads an npm extension.** pi's
> `resolve()` iterates this array and nothing else — it never scans
> `node_modules`. A package sitting in `npm/node_modules` but missing from
> `packages` is invisible: not loaded, not updated by `pi update`, but still
> able to wreck npm dependency resolution for the packages you *do* use.
> Keep this list and `npm/package.json` in agreement.
>
> Local extensions are the exception: `~/.pi/agent/extensions/` (and
> `skills/`, `themes/`, `prompts/`) are auto-discovered and load without
> appearing here.
>
> `pi-zentui` is pinned to an exact version on purpose — see step 6b.

### Custom theme

pi itself only reads JSON themes, but you never have to write one: drop any
**base16 or base24 scheme YAML** into `~/.pi/agent/themes/` and select it by
file name.

```bash
mkdir -p ~/.pi/agent/themes
curl -fsSL https://raw.githubusercontent.com/tinted-theming/schemes/spec-0.11/base24/catppuccin-mocha.yaml \
  -o ~/.pi/agent/themes/catppuccin-mocha.yaml
# then: "theme": "catppuccin-mocha" in settings.json, or /settings → Theme
```

`extensions/base16-theme.ts` converts every `themes/<name>.yaml` (or `.yml`)
into `themes/<name>.json` when pi starts and on `/reload`, before pi applies
the theme setting, so a new scheme works on the first launch. (It only shows up
in pi's startup theme list from the second launch on.) Notes:

- Both the tinted-theming layout (`palette:` block) and the legacy flat base16
  layout work. base24 schemes use base10–base17; base16 schemes derive them.
- The UI accent is base09 (orange). Add a top-level `accent: base0D` line to a
  scheme to use another slot.
- The generated JSON is machine-local and never enters this repo. The
  extension only rewrites JSON it generated itself; a hand-written or
  symlinked `<name>.json` of the same name is left alone and reported.
- Edit the YAML, then `/reload`. pi hot-reloads the regenerated JSON.

Themes in this repo (`config/pi/agent/themes/`): `gruvbox-material.yaml`
(default, a copy of `NixOS/home/common/colors/gruvbox-material.yaml`) and the
hand-written `claude-dark.json`. On NixOS, Home Manager also writes the active
stylix scheme to `~/.pi/agent/themes/stylix.yaml`
(`NixOS/home/common/core/pi-theme.nix`); select it with `"theme": "stylix"`.
Stylix is optional; the extension needs nothing but the YAML.

## 5. MCP servers (`mcp.json`) — *suggestions, not a manifest*

> **`mcp.json` is deliberately not tracked in this repo** (`.gitignore`:
> `agent/mcp.json`). Server entries routinely carry inline credentials — an
> API token in `env`, a bearer in a URL — and which servers you want is a
> per-machine choice. What follows is a menu to pick from, not a file to copy.

Write `~/.pi/agent/mcp.json` yourself. STDIO servers use `command` + `args`
(+ optional `env`); HTTP servers use `url`. `lifecycle: "lazy"` spawns on first
use (good for stateless clients); `"keep-alive"` keeps the process alive (for
stateful daemons). The server list loads at session start — new entries need a
pi restart (or `/reload`) to appear.

### Suggested servers

Each is independently useful; take what you need.

| Server | Type | Gives you | Needs |
|---|---|---|---|
| `context7` | STDIO (`npx`) | up-to-date library/framework docs | nothing |
| `grep_app` | HTTP | search public GitHub code | nothing |
| `nixos` | STDIO (`uvx`) | nixpkgs / NixOS options lookup | `uvx` |
| `obscura` | STDIO | drive a real page — navigate, click, forms, JS render | `obscura` on `PATH` |

Web search is **not** on this list: `pi-web-access` (step 6) provides
`web_search` / `fetch_content` as ordinary tools, with local SearXNG tried first.
An MCP search server such as `argus` is redundant alongside it.

> **Credentials belong in `env`, not inline where you can help it.** A token
> written straight into `mcp.json` is why the file is untracked. Prefer
> `"API_TOKEN": "${API_TOKEN}"` env entries exported from your shell, or
> keep the credential in the server's own config file.

> **On `keep-alive` vs `lazy`.** Both appear in the prompt as a single
> `mcp__<server>` namespace proxy — the underlying tools are *not* enumerated,
> so the choice costs roughly one line either way. `keep-alive` keeps the
> process warm (worth it for a stateful daemon); `lazy` spawns on first use.
> Pick on startup latency, not on context.

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"],
      "lifecycle": "lazy"
    },
    "grep_app": {
      "url": "https://mcp.grep.app",
      "lifecycle": "lazy"
    },
    "obscura": {
      "command": "obscura",
      "args": ["mcp"],
      "lifecycle": "keep-alive"
    },
    "nixos": {
      "command": "uvx",
      "args": ["mcp-nixos"],
      "lifecycle": "lazy"
    }
  }
}
```

**What each server does / what it needs:**

| Server      | Type  | Needs                                                                                                                                      |
| ----------- | ----- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `context7`  | STDIO | Nothing (public npx package, library docs).                                                                                                |
| `grep_app`  | HTTP  | Nothing (public, code search).                                                                                                             |
| `obscura`   | STDIO | The `obscura` Rust binary on `PATH`. Headless browser / page render.                                                                       |
| `nixos`     | STDIO | `uvx`. Query nixpkgs / NixOS options.                                                                                                      |

Memory is not an MCP server any more: the mem0 extension (step 8) replaced
mnemosyne here.

## 6. Extensions (npm packages)

Already listed under `packages` in `settings.json` (step 4). On startup pi
installs missing entries into `~/.pi/agent/npm/` and updates
`~/.pi/agent/npm/package.json`. To install/update explicitly:

```bash
pi install npm:pi-zentui          # one package
pi update --extensions             # update all installed extensions
```

What they are:

- `@ff-labs/pi-fff` — fuzzy file + content search, frecency-ranked.
- `@gamaraan/todos-tool` — phased todo tool with reminders and a HUD
  (an Oh-My-Pi-style `todo`; pi ships no todo tool of its own).
- `@narumitw/pi-plan-mode` — Codex-like read-only `/plan` collaboration mode.
- `pi-background-tasks` — durable background shell tasks and read-only
  delegated agents, run as child pi processes.
- `pi-hashline-edit-pro` — hash-anchored read/replace/insert/grep. Every line
  gets a stable 4-char anchor; stale or ambiguous anchors are rejected rather
  than fuzzy-matched. `AGENTS.md` tells the model to prefer these over
  `cat`/`head`/`sed`.
- `pi-lens` — real-time code feedback: LSP, linters, formatters,
  type-checking, structural analysis. Also ships four `pi-lens-*` skills.
  This is the closest thing here to an IDE wired into the agent.
- `pi-mcp-adapter` — MCP integration (config merging, oauth, `/mcp` panel).
  Everything in step 5 depends on it; remove it and all six servers go dark.
- `pi-mono-ask-user-question` — structured multiple-choice questions instead
  of the model guessing.
- `pi-mono-auto-fix` — runs language-appropriate fixers (eslint, black,
  prettier, …) over files touched during a turn.
- `pi-mono-btw` — `/btw` answers a side question while the main agent keeps
  running, without polluting the main thread.
- `pi-mono-context` — prints current context-window usage *without* adding
  that report to future context.
- `pi-mono-review` — reviews GitHub PRs and GitLab MRs.
- `pi-web-access` — `web_search` / `fetch_content`. SearXNG first when configured
  (see Prerequisites), then public providers. GitHub URLs are cloned locally
  rather than scraped, so the agent gets real file contents.
- `pi-simplify` — reviews the **local** working diff for clarity and
  maintainability. Complements `pi-mono-review` rather than overlapping it
  (remote PR vs local diff).
- `pi-x-search` — searches X with verbatim post quotes and resolved URLs.
  Needs xAI auth (`/login` → xAI, or `XAI_API_KEY`). Note it **searches**;
  it cannot fetch a specific X URL — use obscura for that.
- `pi-zentui@0.25.0` — TUI + statusline. **Pinned to an exact version on
  purpose:** pi skips exact npm specs during `pi update`, which is what keeps
  the local patch in step 6b from being silently reverted. Keep the pin in
  both `settings.json` and `npm/package.json` — a caret range in either
  defeats it.
- `@amaster.ai/pi-memory-mem0` — cross-session memory, per project. Needs a
  per-machine config block and two extra npm modules; see step 8.
- `@joemccann/pi-pdf` — 12 PDF tools (text/table extraction, `pdf_to_images`,
  merge/split, forms, OCR, …) plus a `pdf` skill. It runs `python3` from
  `PATH` with no way to point it elsewhere, so that `python3` must have
  `pypdf pdfplumber reportlab` (and `pdf2image pytesseract pypdfium2 Pillow`
  plus `poppler`/`tesseract` for page images and OCR). NixOS has no user
  site-packages (PEP 668), so this machine uses a uv venv at
  `~/.venvs/pi-pdf` and a `~/.local/bin/python3` shim that execs it — which
  makes that venv every shell's `python3`, not just pi's.
### 6b. Local patches (`patches/`) — the silent step

`patches/` holds a patch applied **inside `node_modules/pi-zentui/`**, making
the footer show real token counts (`6.6k/131k`) instead of percentages.

`node_modules/` is deliberately untracked, so a fresh `npm ci` produces
*unpatched* zentui **with no error at all** — you just quietly get the wrong
footer. This is the one step that fails silently, which is why `bootstrap.sh`
runs it automatically.

```bash
cd ~/.pi/agent/npm && npm ci         # restores extensions from the lockfile
~/.pi/agent/patches/apply-zentui-patch.sh          # apply (idempotent)
~/.pi/agent/patches/apply-zentui-patch.sh --check  # status only
```

If `npm ci` refuses with `EUSAGE` (`package.json` and `package-lock.json` out
of sync), run `npm install` once to resync the lockfile, then `npm ci` works
again. Commit the updated lockfile.

After bumping zentui deliberately: `pi install npm:pi-zentui@<new>` replaces
the package and un-patches it, so re-run the applier. If it reports
`CONFLICT`, upstream changed one of the patched files — regenerate the patch
per `patches/README.md`.

## 7. Skills + local extension

Skills are `SKILL.md` files. pi loads them from (in order) `.pi/skills/`,
`.agents/skills/` (project, walking up parents), then `~/.pi/agent/skills/`
and `~/.agents/skills/` (user-global). User-global is what we seed here.

Both user-global skills are pulled from their upstream repos (see 7b) — nothing
skill-related is vendored here. The repo ships one **recipe doc** for a local
TypeScript extension:

- `docs/extensions/litellm-auto.md` — the recipe for an optional extension that
  auto-discovers chat models from a self-hosted LiteLLM-compatible gateway
  (`/v1/model/info`) and registers them as a provider. Only relevant if you run
  your own gateway; skip otherwise. The doc contains the full minimal
  implementation, config env vars, hardening notes, and where credentials live.

**Machine-specific local extensions stay out of this repo.** Anything encoding
environment specifics (gateway URLs, deployment names, aliases) is written
directly in `~/.pi/agent/extensions/` on each machine, following the recipe
above — currently only `litellm-auto.ts` (see `docs/extensions/litellm-auto.md`).

The rest of `extensions/` **is** tracked here and linked by `bootstrap.sh`:

| Extension | Does |
|---|---|
| `neat-render.ts` | Claude-Code-shaped tool rows: two-line call/outcome, wrapped `└ $` for running commands, inline edit diffs, pulsing bullet. Ctrl+O shows each call in an omp-style frame (command, `Output` divider, status in the bottom border) instead of pi's tinted box. Env knobs in its header. |
| `read-guard/` | Trims a `read` only when it would overflow the context window, returning the first 30 lines plus a use-grep-instead directive. From little-coder. Replaced `pi-mono-context-guard`, which capped every read at 120 lines regardless of pressure. |
| `compaction-continue/` | Watchdog that nudges pi to resume when a turn stalls. Upstream is unmaintained since 2026-05; the compaction half it was written for was fixed in pi 0.84.4, the stalled-turn half is still live. |
| `sudo-session.ts` | `/sudo` elevation for the bash tool. |
| `remember-model.ts` | Persists last model + thinking level across sessions in `model-state.json`, and exports that file's `mem0` section (memory models) as the env vars the shared mem0 settings expand. |
| `eval/` | `eval` tool: Python (`runner.py`, plain CPython — `python3` on PATH or `EVAL_PYTHON`) and JavaScript (`kernel.cjs`, Node REPL semantics) in persistent per-session kernels. Last-expression value, top-level await, `!cmd`/`%pip` in Python; Ctrl+C/timeout interrupts a cell, and a kernel that will not stop is restarted. Modelled on omp's `eval`. |
| `smart-capture.ts` | Write gate for mem0: judges each prompt's final answer (YES/NO via mem0's own extraction model) and only then stores it. Needs `"autoCapture": false` on pi-memory-mem0. `/mem0gate` for status. |
| `mem0-recall.ts` | Draws mem0's recall message as one `● Recalled N memories` line (Ctrl+O expands) instead of a full tinted block. `MEM0_RECALL=hide`/`full` in its header. |
| `herdr-agent-state.ts` | Publishes agent state for desktop integrations. |
| `pi-code-planner/` | Planner instruction templates (`instructions/`). |

### 7b. User-global skills

- **`obscura`** → from the upstream repo,
  **[h4ckf0r0day/obscura](https://github.com/h4ckf0r0day/obscura)** — do **not**
  vendor it here. Clone and copy its skill:

  ```bash
  git clone --depth 1 https://github.com/h4ckf0r0day/obscura /tmp/obscura
  mkdir -p ~/.pi/agent/skills/obscura
  cp /tmp/obscura/skills/obscura/SKILL.md ~/.pi/agent/skills/obscura/
  rm -rf /tmp/obscura
  ```

  Teaches CDP / page-render usage. Install it only if you use the obscura MCP
  server (step 5).
- **`pi-lens-*`** (`ast-grep`, `lsp-navigation`, `write-ast-grep-rule`,
  `write-tree-sitter-rule`) → no manual copy; shipped by the `pi-lens` npm
  extension (step 6).
- **`find-skills`, `hindsight-docs`, `microsoft-foundry`, `mcp-scripting`,
  `self-learning`** → `~/.agents/skills/` (cross-agent convention) or from
  their own packages. Install on demand via the `find-skills` skill; not
  required for a baseline setup.
- **`skill-creator`** → previously came from
  `@howaboua/pi-skill-skill-creator`, **removed** from the package list
  (v0.0.5, too immature to carry). Re-add with
  `pi install npm:@howaboua/pi-skill-skill-creator` if you want it back.

The user-global skill that matters here (`obscura`) is vendored under `config/pi/agent/skills/` and linked by `bootstrap.sh`;
the upstream clone commands above are the fallback for a machine without this
repo.


If a skill ships inside a package/venv, copy just the `SKILL.md` (and any
referenced sibling files) into the target dir — pi reads the file directly.

### ⚠️ Restart pi before steps 8–10

Extensions (step 6 + 7) and MCP servers (step 5) load at pi **startup**,
not mid-session. You've just written `settings.json` and `mcp.json` during
this session, so the npm extensions and MCP servers are **not yet loaded** —
`/mcp` will show nothing until you restart. Exit pi and relaunch it, then
continue from step 8.

## 8. Memory (mem0)

Cross-session memory is the `@amaster.ai/pi-memory-mem0` extension, already in
`packages` (step 4). It runs mem0 **in-process** ("embedded" mode) — no
Docker, no server: memories live in three SQLite files under
`~/.pi/agent/memories/`, kept separately per project (per working directory).

- **Gated capture** — mem0's own `autoCapture` is off; `extensions/smart-capture.ts`
  owns capture instead. After each prompt it skips acknowledgements and slash
  commands, asks mem0's extraction model a one-word "durable fact? YES/NO"
  about your message plus the final answer, and only on YES hands the pair to
  mem0 (same provider, scoping and `customInstructions`). A judge error stores
  anyway; if the gate cannot start it warns, since nothing else would save.
  `/mem0gate` shows its decisions; `MEM0_GATE=off` disables it.
- **Automatic recall** — at the start of each session (`recallFrequency:
  "session"`) the `topK: 3` closest memories are added to the conversation as
  untrusted data, not to the system prompt, so prompt caching is unaffected.
- **`mem0_memory` tool** and **`/mem0`** commands (`status`, `search`,
  `profile`, `add`, `delete`) for looking things up or editing by hand.

**Per-machine config.** mem0 needs to know which models to use, and model names
never enter this repo. The `pi-memory-mem0` block in `settings.json` is shared
(it is in this repo) but names no models — it expands environment variables:

```json
"pi-memory-mem0": {
  "mode": "embedded",
  "oss": {
    "llm":      { "provider": "${MEM0_PROVIDER:-litellm}", "config": { "model": "${MEM0_LLM_MODEL}" } },
    "embedder": { "provider": "${MEM0_PROVIDER:-litellm}", "config": { "model": "${MEM0_EMBED_MODEL}" } }
  }
}
```

The values come from the `"mem0"` section of `~/.pi/agent/model-state.json` —
the same per-machine file that remembers your model picks, never linked, synced
or committed (`agent/model-state_example.json` here shows the shape).
`extensions/remember-model.ts` exports it as environment variables when pi
starts, before mem0 reads its settings; a variable already set in your shell
wins. Add it on each machine:

```json
"mem0": {
  "llm": "<fast chat model>",
  "embedder": "<embedding model>",
  "provider": "<pi provider>"
}
```

(`provider` is optional and defaults to `litellm`. Model and thinking-level
writes leave this section alone.)

The provider is any pi provider name — keys and base URLs come from pi's own
registry, so there is nothing else to configure. Pick a fast chat model for
extraction (it runs once per turn) and any OpenAI-compatible embedding model;
the vector size is detected automatically. `bootstrap.sh` prints a NOTE when
`mem0.llm` or `mem0.embedder` is missing.

**Load-time dependencies.** mem0 imports two of its *peer* dependencies as
soon as it loads: `better-sqlite3` (the store) and `pg` (imported even though
the SQLite store never uses it). pi installs packages with peers disabled, so
after a plain `pi install` memory fails with "Mem0 init failed: Cannot find
package". `bootstrap.sh` step 4b loads mem0 and installs whatever it reports
missing, with pi's own npm flags, until it loads. By hand:

```bash
npm install better-sqlite3 pg --prefix ~/.pi/agent/npm --legacy-peer-deps
```

(Plain `npm install` inside `npm/` would also pull in every other package's
peers — hundreds of extra modules.) npm downloads a prebuilt `better-sqlite3`
binary for common platforms; otherwise it compiles, which needs `python3`,
`make` and a C++ compiler.

**Check:** run `/mem0 status`. (Its footer entry is turned off in
`zentui.json` under `extensionStatuses.placements`; set `"mem0"` to `"right"`
to show it again.)

Memories are separate from Hermes's Mnemosyne store by design — each agent
keeps its own.

## 9. Checklist (user-provided, outside this repo)

These are **not in this repo** — supply them before first run:

- [ ] `~/.pi/agent/models.json` — provider configuration (you set this up, step 2).
- [ ] `~/.pi/agent/auth.json` — created automatically by `/login`.
- [ ] `web-search.json` — optional. Only needed for a private SearXNG
      backend; `pi-web-access` works keyless otherwise (see Prerequisites).
- [ ] `~/.pi/agent/mcp.json` — yours to write; suggestions in step 5.
- [ ] `obscura` binary on `PATH`; `uvx` on `PATH`.

## 10. Verify

```bash
pi                       # launches; no config errors
# inside pi:
/mcp                     # lists every server you configured, each "connected"
# tools from whichever servers you configured should appear
/mem0 status             # memory active (step 8)
```

Then check that an extension tool like `ask_user_question` or the pi-lens
diagnostics tools resolve. If a STDIO MCP server shows disconnected, run its
`command` + `args` manually to see the startup error, and confirm `env`/`PATH`
are set.

Confirm the npm extensions are live: run `pi config` and check the package list
from step 4 shows everything enabled; try a tool provided by one of them (e.g.
`ask_user_question` or the pi-lens diagnostics tools).

Also confirm the two things that fail quietly:

```bash
~/dotfiles/config/pi/bootstrap.sh --check          # config drift vs this repo
~/.pi/agent/patches/apply-zentui-patch.sh --check  # expect "already applied"
```

In pi, `/todo` should respond (from `@gamaraan/todos-tool`) and the footer
should read real token counts like `6.6k/131k` — percentages there mean the
zentui patch did not apply.
