# pi agent setup

Runbook for recreating the pi coding-agent configuration on this machine.
Follow it top to bottom. It assumes the dotfiles repo is checked out at
`~/dotfiles` and NixOS + Home Manager are already applied.

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
- **uv / uvx** — used by two MCP servers (`argus`, `nixos`). Install via
  `pipx install uv` or the standalone installer; ensure `uvx` is on `PATH`.
- **CLI tools the seeded memory rules assume:** `gh` (GitHub CLI),
  `obscura` (Rust headless browser, see below).

### SearXNG (optional — extra backend for the `argus` web-search MCP server)

`argus` does **not** require SearXNG — it auto-routes to the cheapest/free
search providers on its own and works out of the box. You only need to wire
up SearXNG if one is **already running** somewhere and you want `argus` to use
it as a backend. Discover the real URL — don't hard-code a port.

```bash
# 1. Any docker container with "searx" in its name? Parse the host-side port
#    from its published mapping (`<hostport>->8080` or `->8080/tcp`).
docker ps --format '{{.Names}}\t{{.Ports}}' 2>/dev/null | grep -i searx
# 2. Native NixOS searx.service? Its port is `server.port` in
#    NixOS/hosts/common/searx.nix (this repo — default here is 8888).
grep -E '^\s*server\.port' ~/dotfiles/NixOS/hosts/common/searx.nix 2>/dev/null
# 3. Probe the candidate ports SearXNG is most likely on (8888 NixOS, 8080
#    upstream, 48431 / 4000 common docker maps). Pick the first that returns 200.
for p in 8888 8080 48431 4000; do
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 2 "http://127.0.0.1:$p" 2>/dev/null || true)
  [ "$code" = "200" ] && echo "searx reachable on :$p" && break
done
```

- If SearXNG is reachable (docker container shows up, a port returns `200`,
  or `searx.nix` declares a `server.port`), set `ARGUS_SEARXNG_ENABLED=true`
  and `ARGUS_SEARXNG_BASE_URL=http://127.0.0.1:<discovered-port>` in the
  `argus` block of `mcp.json` (step 5). Use the **discovered** port — not a
  guessed one — so `argus` actually reaches the running instance.
- If **nothing is running** (or you just don't care), **skip this entirely** —
  leave the `ARGUS_SEARXNG_*` env vars out of `mcp.json`. `argus` runs fine
  without them. The NixOS config lives at `NixOS/hosts/common/searx.nix` if
  you ever want to enable it as a system service later.

## 1. Install pi

```bash
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
pi --version     # expect 0.80.x or newer
```

`--ignore-scripts` is the documented install flag (pi needs no lifecycle
scripts). The binary ends up at `~/.node_modules/bin/pi`. If pi is already
installed and `pi --version` shows 0.80.x+, skip to step 2.

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
| `mcp.json`                             | MCP server definitions                     | Yes (step 5)  |
| `npm/`                                 | npm extension install dir + `package.json` | Auto (step 6) |
| `extensions/skill-manage.ts`           | Local self-improvement extension           | Yes (step 7)  |
| `skills/`                              | User-global skills (`SKILL.md` per dir)    | Yes (step 7)  |
| `memories/MEMORY.md`                   | Always-in-prompt agent memory              | Yes (step 8)  |
| `mcp-cache.json`, `mcp-npx-cache.json` | Auto-generated MCP tool caches             | Auto          |
| `sessions/`, `trust.json`, `pi-acp/`   | Runtime state                              | Auto          |

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
  "theme": "gruvbox-material-hard",
  "lastChangelogVersion": "0.80.2",
  "packages": [
    "npm:pi-zentui",
    "npm:pi-mcp-adapter",
    "npm:@spences10/pi-lsp",
    "npm:@howaboua/pi-skill-skill-creator",
    "npm:pi-mono-ask-user-question",
    "npm:pi-mono-auto-fix",
    "npm:pi-mono-btw",
    "npm:pi-mono-context",
    "npm:pi-mono-multi-edit",
    "npm:@amaster.ai/pi-memory"
  ],
  "pi-memory": {
    "memoryCharLimit": 6000,
    "userCharLimit": 2000
  },
  "quietStartup": false
}
```

- `packages` is the list of extensions pi auto-installs into `~/.pi/agent/npm/`
  on startup (and via `pi install <pkg>`). See step 6.
- `pi-memory` sets the char budgets for the always-in-prompt `MEMORY.md` /
  `USER.md` (the `memory_add` / `memory_read` tools). Keep them tight — the
  content is injected into every turn.

### Custom theme

The theme referenced above (`gruvbox-material-hard`) ships in this repo at
`config/pi/themes/gruvbox-material-hard.json`. Install it:

```bash
mkdir -p ~/.pi/agent/themes
cp ~/dotfiles/config/pi/themes/gruvbox-material-hard.json ~/.pi/agent/themes/
```

It implements the **Gruvbox Material Hard Dark** palette — a warm, earthy
dark theme with muted greens, oranges, and reds. The file defines all 51 pi
theme tokens and uses variable references (defined in `vars`) for
maintainability. To switch at runtime, edit `settings.json`'s `"theme"` value
or use `/settings` inside pi — and since the theme file is under `~/.pi/agent/themes/`,
pi hot-reloads edits to the active theme file automatically.

> **Why not `"theme": "dark"`?** The built-in `dark` theme is a generic blue-on-black
> fallback. The `gruvbox-material-hard` theme is the preferred look for this
> setup: it matches the terminal color scheme, reduces blue-light glare, and
> uses a curated palette that was built for the Gruvbox Material vim
> colorscheme this machine already uses.

## 5. MCP servers (`mcp.json`)

Write `~/.pi/agent/mcp.json`. STDIO servers use `command` + `args` (+ optional
`env`); HTTP servers use `url`. `lifecycle: "lazy"` spawns on first use (good
for stateless clients); `"keep-alive"` keeps the process alive (for stateful
daemons). The server list loads at session start — new entries need a pi
restart (or `/reload`) to appear.

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"],
      "lifecycle": "keep-alive"
    },
    "grep_app": {
      "url": "https://mcp.grep.app",
      "lifecycle": "lazy"
    },
    "argus": {
      "command": "uvx",
      "args": ["--from", "argus-search[mcp]", "argus", "mcp", "serve"],
      "lifecycle": "lazy"
    },
    "mnemosyne": {
      "command": "<path-to-hermes-venv>/bin/mnemosyne",
      "args": ["mcp"],
      "env": {
        "MNEMOSYNE_DATA_DIR": "<path-to-mnemosyne-data>",
        "MNEMOSYNE_EMBEDDING_API_URL": "<embedding-endpoint>/v1",
        "MNEMOSYNE_EMBEDDING_API_KEY": "<embedding-api-key>",
        "MNEMOSYNE_EMBEDDING_MODEL": "Qwen3-Embedding-8B",
        "MNEMOSYNE_EMBEDDING_DIM": "4096",
        "MNEMOSYNE_EMBEDDINGS_VIA_API": "true"
      },
      "lifecycle": "keep-alive"
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

**Before writing that block, apply these conditionals:**

- **`mnemosyne` — ask the user; don't guess.** This server is cross-session
  memory, shared with the Hermes agent (both agents read/write one SQLite DB).
  Its config is **not** in this guide, but can usually be **sourced from an
  existing install** rather than pasted by hand. Do **not** write the `<...>`
  placeholders verbatim — pi would try to exec
  `<path-to-hermes-venv>/bin/mnemosyne` and the server would fail to start.

  **First, detect what's already on the machine:**

  ```bash
  # Hermes install? (venv binary + .env + shared data dir)
  ls ~/.hermes/hermes-agent/venv/bin/mnemosyne ~/.hermes/.env ~/.hermes/mnemosyne/data 2>/dev/null
  # OpenClaw install carrying mnemosyne config? (check its env/config files)
  ls ~/.openclaw 2>/dev/null
  grep -rilE 'MNEMOSYNE|embedding' ~/.openclaw 2>/dev/null | head
  ```

  **Then use `ask_user_question` to ask the user:**

  - Q1 (radio): "Set up the `mnemosyne` cross-session memory MCP server?"
    → `Yes` / `No, skip it`
  - Q2 (radio, only if Q1 = Yes **and** more than one source was detected
    above): "Source its config from?" → `Hermes` (if `~/.hermes/.env` exists)
    / `OpenClaw` (if detected) / `Fresh data dir`

  **Act on the answer:**

  - **No, skip** → delete the entire `mnemosyne` entry from `mcp.json`. Done.
  - **Hermes** → fill the block from the existing Hermes install (no
    secret-pasting). The values are fully discoverable:
    - `command` = `~/.hermes/hermes-agent/.venv/bin/mnemosyne`
      (check `.venv/` vs `venv/` — the Hermes venv may use either name)
    - `args` = `["mcp"]`, `lifecycle` = `"keep-alive"`
    - On NixOS, add `"env": { "LD_LIBRARY_PATH":
"/run/current-system/sw/share/nix-ld/lib" }` — mnemosyne's
      libstdc++ dependency resolves differently outside the nix-shell.
    - If the `mnemosyne-hermes` plugin package is installed (`uv pip show
mnemosyne-hermes` succeeds in the Hermes venv), embedding is handled
      automatically through Hermes' `memory_provider` plugin system — no
      `MNEMOSYNE_EMBEDDING_*` env vars needed. Verify with `hermes mnemosyne
stats` (check that `dense_score > 0` in recall results).
    - If using mnemosyne standalone (no Hermes plugin), source
      `MNEMOSYNE_DATA_DIR`, `MNEMOSYNE_EMBEDDING_API_URL`,
      `MNEMOSYNE_EMBEDDING_API_KEY`, `MNEMOSYNE_EMBEDDING_MODEL`,
      `MNEMOSYNE_EMBEDDING_DIM`, and `MNEMOSYNE_EMBEDDINGS_VIA_API` from
      `~/.hermes/.env` (if present) or ask the user for an embedding endpoint.

    This points pi at the **same** SQLite DB Hermes uses, so pi and Hermes
    share one memory store.

  - **OpenClaw** → discover the `MNEMOSYNE_*` env from OpenClaw's config
    (its `.env` / settings) and fill the block the same way; `command` is
    OpenClaw's `mnemosyne` binary if it ships one, else the Hermes venv
    binary. If OpenClaw turns out to have no mnemosyne config, fall back to
    the Hermes or Fresh path.
  - **Fresh data dir** → set `MNEMOSYNE_DATA_DIR` to a new path (e.g.
    `~/.pi/agent/mnemosyne/data`). You still need an embedding endpoint + key:
    ask the user for `MNEMOSYNE_EMBEDDING_API_URL` and
    `MNEMOSYNE_EMBEDDING_API_KEY`. If they don't have one, omit mnemosyne.

- **`argus` — add SearXNG env if it's running.** The template above omits `env`
  (argus auto-routes to free providers without it). If the SearXNG check in
  the Prerequisites section found a reachable URL — i.e. you got `server.port`
  in `NixOS/hosts/common/searx.nix`, a docker `searx` container on
  `0.0.0.0:<port>->8080`, or a `200` from one of the probe ports — add an
  `env` block to the `argus` entry using the **discovered** port:

  ```json
  "env": {
    "ARGUS_SEARXNG_ENABLED": "true",
    "ARGUS_SEARXNG_BASE_URL": "http://127.0.0.1:<discovered-port>"
  }
  ```

  If SearXNG is not running, leave `argus` as shown (no `env`).

**What each server does / what it needs:**

| Server      | Type  | Needs                                                                                                                                      |
| ----------- | ----- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `context7`  | STDIO | Nothing (public npx package, library docs).                                                                                                |
| `grep_app`  | HTTP  | Nothing (public, code search).                                                                                                             |
| `argus`     | STDIO | `uvx`. Web search; auto-routes to free providers. Add SearXNG env (see Prerequisites) only if one is already running.                      |
| `mnemosyne` | STDIO | Cross-session memory (shared with Hermes). Config is sourced interactively — see the conditional above (Hermes / OpenClaw / fresh / skip). |
| `obscura`   | STDIO | The `obscura` Rust binary on `PATH`. Headless browser / page render.                                                                       |
| `nixos`     | STDIO | `uvx`. Query nixpkgs / NixOS options.                                                                                                      |

> `mnemosyne`'s values are machine-specific (venv path, data dir, embedding
> endpoint + key). Don't commit real values — source them interactively per
> the conditional above, and never write the `<...>` placeholders verbatim.

## 6. Extensions (npm packages)

Already listed under `packages` in `settings.json` (step 4). On startup pi
installs missing entries into `~/.pi/agent/npm/` and updates
`~/.pi/agent/npm/package.json`. To install/update explicitly:

```bash
pi install npm:pi-zentui          # one package
pi update --extensions             # update all installed extensions
```

What they are:

- `pi-zentui` — TUI theme/components.
- `pi-mcp-adapter` — MCP integration adapter.
- `@spences10/pi-lsp` — LSP diagnostics/hover/definition tools.
- `@howaboua/pi-skill-skill-creator` — ships the `skill-creator` skill.
- `pi-mono-ask-user-question` — interactive question tool.
- `pi-mono-auto-fix` — auto-fix loop.
- `pi-mono-btw` — side-channel notes.
- `pi-mono-context` — context management.
- `pi-mono-multi-edit` — multi-file edit tool.
- `@amaster.ai/pi-memory` — the `memory_*` tools backing `MEMORY.md`/`USER.md`.

## 7. Skills + local extension

Skills are `SKILL.md` files. pi loads them from (in order) `.pi/skills/`,
`.agents/skills/` (project, walking up parents), then `~/.pi/agent/skills/`
and `~/.agents/skills/` (user-global). User-global is what we seed here.

There is also one **local TypeScript extension**,
`extensions/skill-manage.ts`, that gives pi the dynamic skill-creation loop
this config relies on. Install it in the same pass.

```bash
mkdir -p ~/.pi/agent/skills ~/.agents/skills ~/.pi/agent/extensions
```

### 7a. Local extension — `skill-manage.ts` (the self-improvement loop)

Copy the vendored extension into pi's global extensions dir:

```bash
cp ~/dotfiles/config/pi/extensions/skill-manage.ts ~/.pi/agent/extensions/
```

What it does (one self-contained file, no npm deps):

- Registers a **`skill_manage`** tool the LLM can call to
  create / patch / edit / delete skills and their supporting
  `references/` / `templates/` / `scripts/` / `assets/` files. New skills go
  to `~/.pi/agent/skills/<category?>/<name>/` and get a
  `.pi-provenance.json` sidecar (`created_by: "agent"`) so agent-created
  skills stay distinguishable from hand-written ones. Every write runs an
  inline efficiency check (frontmatter parse, kebab-case, description length,
  forbidden trigger-selection headings in the body, plain-scalar quoting,
  dangling `references/`/`scripts/`/`assets/` paths).
- The `skill_manage` tool description guides the agent to **prefer patches
  over creation** and to **confirm with the user before creating** — no
  autonomous skill creation.
- Adds a user-triggered **`/skill-review`** command that injects a
  conservative review prompt asking the agent to audit the session and
  codify anything worth saving (preferring patches over new skills, never
  creating without confirmation). The review prompt is a port of the Hermes
  Agent background-review prompt, including the _do-not-capture_ rules
  (env-dependent failures, negative tool claims, transient errors — they rot
  into self-imposed refusals) and the 4-step update preference order
  (patch-loaded → patch-umbrella → add-support-file → class-level-skill).
- Automatic nudging is **disabled by default** (`NUDGE_INTERVAL = 0`) —
  Pi only reviews on explicit `/skill-review`. No silent/autonomous prompts.
- Adds a **`/learn <anything>`** command — gather from a dir, URL, pasted
  notes, or "what I just did", then author one skill via `skill_manage`.
  Adapted from Hermes' `/learn` command.
- Adds a **`/skills-show`** command — lists discovered skills with a `+`
  marker for agent-created ones (uses `ctx.ui.select` so it's harmless in
  background/print modes — fires the picker only if you actually call it).

This is the actionable counterpart to the `skill-creator` skill from step 6:
that skill is the **authoring guide** (writing-quality rules, references
split, efficiency posture); this extension is the **actor** (a registered
tool with trigger guidance baked into its description so the model does not
have to load a SKILL.md first). Both coexist and reinforce each other.

> The `skill-manage.ts` file uses `StringEnum` from `@earendil-works/pi-ai`
> and `Type` from `typebox` — both are bundled in pi's `node_modules` and
> resolved at load time, so the extension needs no `npm install` of its own.
> It loads via `jiti` (pi's TypeScript loader) — no build step.

### 7b. User-global skills

- **`mnemosyne-memory`** → `~/.pi/agent/skills/mnemosyne-memory/SKILL.md`.
  **Source: vendored in this repo at
  `config/pi/skills/mnemosyne-memory/SKILL.md`** — copy from there. (Don't
  grab `~/.hermes/.../mnemosyne-hermes/SKILL.md` — that's a _different_ skill
  for the Hermes agent, and `~/.hermes` won't exist on a fresh machine.)
  Teaches the agent when to use `mnemosyne_remember` / `mnemosyne_recall`.
- **`obscura`** → `~/.pi/agent/skills/obscura/SKILL.md`. **Source: vendored
  in this repo at `config/pi/skills/obscura/SKILL.md`** — copy from there.
  (Don't rely on `/tmp/obscura/...` — that's an ephemeral path the binary
  regenerates after first run and won't exist on a fresh machine.) Teaches
  CDP / page-render usage.
- **`skill-creator`** → no manual copy; exposed by the
  `@howaboua/pi-skill-skill-creator` npm extension (step 6). It's the
  authoring-quality reference skill — the actual `skill_manage` _tool_
  comes from the local extension in 7a, so the model can create skills even
  if it never reads this SKILL.md.
- **`find-skills`, `hindsight-docs`, `microsoft-foundry`** →
  `~/.agents/skills/` (cross-agent convention). Install on demand via the
  `find-skills` skill; not required for a baseline setup.

Copy the two vendored skills:

```bash
cp -r ~/dotfiles/config/pi/skills/mnemosyne-memory ~/.pi/agent/skills/
cp -r ~/dotfiles/config/pi/skills/obscura          ~/.pi/agent/skills/
```

If a skill ships inside a package/venv, copy just the `SKILL.md` (and any
referenced sibling files) into the target dir — pi reads the file directly.

### ⚠️ Restart pi before steps 8–10

Extensions (step 6 + 7a) and MCP servers (step 5) load at pi **startup**,
not mid-session. You've just written `settings.json` and `mcp.json` and
dropped `skill-manage.ts` into `~/.pi/agent/extensions/` during this
session, so the `@amaster.ai/pi-memory` and `skill-manage` extensions and
the MCP servers are **not yet loaded** in the current session — `memory_add`
and `skill_manage` won't exist as tools and `/mcp` will show nothing until
you restart. Exit pi and relaunch it, then continue from step 8.

## 8. Seed memory

`~/.pi/agent/memories/MEMORY.md` is the agent's always-in-prompt memory,
exposed via the `memory_add` / `memory_read` / `memory_replace` /
`memory_remove` tools (provided by the `@amaster.ai/pi-memory` extension from
step 6). It's char-limited, so keep it to short rules + key facts only — not
task logs.

After the restart above (so the `@amaster.ai/pi-memory` extension is loaded
and `memory_add` is available), use `memory_add` to seed the three entries
below (one call per entry). **Don't hand-edit `MEMORY.md`**
— the tool writes the `§` entry delimiters itself, and hand-editing risks
breaking the format. From here the agent can add, edit (`memory_replace`), or
remove entries as needed.

**Entry 1 — tool-usage rules** (one `memory_add` call with this content):

```
# Rules

## Web access

- Search the web with the `argus` MCP server. Never `curl`/`wget`/`python requests` a search engine or hand-roll a scraper.
- Open, render, or interact with a webpage with the `obscura` MCP server (or `obscura fetch`/`obscura serve` from the CLI). Never `curl`/`python requests` a page URL — they fail on JS-rendered and bot-protected pages.
- argus discovers URLs and facts; obscura renders and interacts.

## GitHub

- Browse GitHub with the `gh` CLI (`gh repo view`, `gh issue`, `gh pr`, etc.) instead of scraping github.com in the browser.

## Memory

- Use Mnemosyne for normal durable memories (preferences, decisions, project state, prior work); `mnemosyne_remember` stores and `mnemosyne_recall` retrieves.
- Use `MEMORY.md`/`USER.md` only for core rules/facts that must be present in every prompt; keep them tiny.
```

**Entry 2 — pi MCP server config note** (one `memory_add` call):

```
pi MCP servers: configured in `~/.pi/agent/mcp.json` under `mcpServers`. pi has native MCP support (no adapter needed). STDIO servers use `command`+`args` (+optional `env`); HTTP servers use `url`. `lifecycle`: `"lazy"` (spawn on first use, good for stateless API clients) or `"keep-alive"` (persistent). Server list is loaded at session start — new entries need a pi restart (or `/reload`) to appear in the `mcp` gateway. Verify a STDIO server works with a JSON-RPC `initialize`+`tools/list` handshake over the process stdin/stdout.
```

**Entry 3 — `memory_replace` footgun** (one `memory_add` call):

```
memory_replace footgun: `oldText` only *selects* the entry; `newContent` replaces the **entire entry**, not the matched substring. Passing just the changed fragment as `newContent` truncates the entry to that fragment. Always pass the full intended entry text as `newContent`. If unsure, use `memory_remove` + `memory_add` instead.
```

Verify with `memory_read` — you should see all three entries.

## 9. Secrets checklist (user-provided)

These are **not** in this repo and must be supplied before first run:

- [ ] `~/.pi/agent/models.json` — provider API keys (you set this up, step 2).
- [ ] `~/.pi/agent/auth.json` — created automatically by `/login`.
- [ ] `mcp.json` → `mnemosyne` — decided via the interactive ask in step 5
      (skip, or source from Hermes/OpenClaw, or fresh). If sourced from
      Hermes, all values come from `~/.hermes/.env` + the fixed venv/data
      paths — no secret-pasting needed.
- [ ] SearXNG reachable for `argus`'s `env` block (optional — see the
      SearXNG check in Prerequisites; if none running, just omit the env,
      `argus` still works without it).
- [ ] `obscura` binary on `PATH`; `uvx` on `PATH`.

## 10. Verify

```bash
pi                       # launches; no config errors
# inside pi:
/mcp                     # lists every server you configured, each "connected"
# tools from context7, grep_app, argus, obscura, nixos should appear;
# mnemosyne appears only if you had its secrets and kept the block (step 5)
```

Then check the memory tools are live (`memory_read`; `mnemosyne_recall`
only if the mnemosyne server is configured) and that an extension tool like
`ask_user_question` or the LSP tools resolve. If a STDIO MCP server shows
disconnected, run its `command` + `args` manually to see the startup error,
and confirm `env`/`PATH`/secrets are set.

Confirm the self-improvement loop (step 7a) is live:

- The **authoritative** check is the `skill_manage` tool, since
  `registerTool` and both `registerCommand` calls (`/learn`, `/skills-show`)
  run in the same extension factory — if `skill_manage` resolves, the whole
  extension loaded. Run the smoke test (single line):

  ```
  Call skill_manage action="create" name="zz-setup-smoketest" content="---
  name: zz-setup-smoketest
  description: "Use when smoke-testing skill_manage installation. Delete me."
  ---
  # Smoke test

  Placeholder created during SETUP verification.
  " and paste the result; then call skill_manage action="delete" name="zz-setup-smoketest" absorbed_into="" to clean it up.
  ```

  Expect the create to write the skill under
  `~/.pi/agent/skills/zz-setup-smoketest/` and return an efficiency-check
  report, and the delete to remove it and record the absorption to
  `~/.pi/agent/skills/.skill_archives.json`. If pi says the tool is missing,
  re-check the file landed at `~/.pi/agent/extensions/skill-manage.ts` and
  that you restarted pi after step 7a.

- `/learn` and `/skills-show` are **user-typed slash commands**, not
  LLM-callable tools, so don't expect the model to see them in its own command
  inventory — open pi interactively and type `/` <kbd>tab</kbd> (or run
  `/commands`); both should appear there. `/learn <anything>` authors a new
  skill from a dir/URL/pasted notes/"what I just did"; `/skills-show` lists
  discovered skills (a `+` marks agent-created ones).
