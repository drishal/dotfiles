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
search providers on its own and works out of the box. SearXNG is an optional
backend: only wire it up if the user wants it and can provide the base URL.
Never hard-code or guess a port — use only what the user provides or what the
discovery check below actually finds.

**Ask the user which to use** (via `ask_user_question`): "How should `argus` search?"
- **Free providers (default)** → nothing to configure; skip the rest of this
  section.
- **Provide a SearXNG URL** → the user gives the base URL (e.g.
  `http://127.0.0.1:8888`); set `ARGUS_SEARXNG_ENABLED=true` and
  `ARGUS_SEARXNG_BASE_URL=<provided-url>` in the `argus` block of `mcp.json`
  (step 5).

Only use a URL the user provides, or one confirmed by the discovery check
below — don't guess ports blindly. If the user chose free providers, the
discovery check is unnecessary.

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
  or `searx.nix` declares a `server.port`) **and the user chose SearXNG**, set
  `ARGUS_SEARXNG_ENABLED=true` and
  `ARGUS_SEARXNG_BASE_URL=http://127.0.0.1:<discovered-port>` in the `argus`
  block of `mcp.json` (step 5). Confirm the choice with the user before wiring.
- If **nothing is running** (or the user chose free providers), **skip this
  entirely** — leave the `ARGUS_SEARXNG_*` env vars out of `mcp.json`. `argus`
  runs fine without them. The NixOS config lives at `NixOS/hosts/common/searx.nix`
  if you ever want to enable it as a system service later.

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
| `extensions/`                           | Local TypeScript extensions               | See step 7    |
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
  "theme": "gruvbox-material",
  "packages": [
    "npm:@ff-labs/pi-fff",
    "npm:@howaboua/pi-skill-skill-creator",
    "npm:@narumitw/pi-plan-mode",
    "npm:pi-background-tasks",
    "npm:pi-cache-graph",
    "npm:pi-hashline-edit-pro",
    "npm:pi-lens",
    "npm:pi-mcp-adapter",
    "npm:pi-mono-ask-user-question",
    "npm:pi-mono-auto-fix",
    "npm:pi-mono-btw",
    "npm:pi-mono-context",
    "npm:pi-mono-context-guard",
    "npm:pi-mono-review",
    "npm:pi-simplify",
    "npm:pi-x-search",
    "npm:pi-zentui@0.22.3",
    "npm:pk-pi-hermes-evolve"
  ],
  "defaultThinkingLevel": "xhigh",
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
### Custom theme

Three themes ship in this repo at `config/pi/themes/`: `gruvbox-material.json`
(default), `claude-dark.json`, and `stylix.json`. Install the one you want:

```bash
mkdir -p ~/.pi/agent/themes
cp ~/dotfiles/config/pi/themes/gruvbox-material.json ~/.pi/agent/themes/
```

Each file defines all pi theme tokens. To switch at runtime, edit
`settings.json`'s `"theme"` value or use `/settings` inside pi — and since
theme files live under `~/.pi/agent/themes/`, pi hot-reloads edits to the
active theme file automatically.

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
      "command": "<path-to-mnemosyne-binary>",
      "args": ["mcp"],
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

- **`mnemosyne` — ask the user; don't guess.** Cross-session memory MCP server.
  Mnemosyne is self-configuring: once it has run once (or an existing install is
  present), all of its settings — data dir, embedding endpoint, model, dims — live
  in **its own** `config.yaml` inside its data dir (precedence:
  `config.yaml > env vars > defaults`). The MCP block only needs the binary path.

  **Detect what's already on the machine:**

  ```bash
  # an existing mnemosyne install? (binary on PATH, or inside an agent venv)
  command -v mnemosyne || find ~ -maxdepth 4 -name mnemosyne -type f 2>/dev/null | head -3
  # existing data dir (its config.yaml records the embedding settings)
  ls ~/.mnemosyne 2>/dev/null
  ```

  **Then use `ask_user_question` to ask the user:**

  - Q1 (radio): "Set up the `mnemosyne` cross-session memory MCP server?"
    → `Yes` / `No, skip it`

  **Act on the answer:**

  - **No, skip** → delete the entire `mnemosyne` entry from `mcp.json`. Done.
  - **Yes, existing install** → point `command` at the detected binary.
  - **Yes, fresh** → install mnemosyne (see the upstream repo,
    [mnemosyne-oss/mnemosyne](https://github.com/mnemosyne-oss/mnemosyne)), then
    set embedding config **in mnemosyne's own config**
    (`mnemosyne config set embedding_api_url ...` etc.) or via
    `MNEMOSYNE_EMBEDDING_*` env vars — ask the user for the endpoint/key.
    Keep `mcp.json` free of credentials — mnemosyne's config.yaml is the right home.
- **`argus` — wire the search backend the user chose (see SearXNG note in
  Prerequisites).** The template above omits `env` — that's the **free
  providers** default and needs nothing. If the user chose SearXNG (gave a URL
  or the discovery check found one), add an `env` block to the `argus` entry
  using that URL:

  ```json
  "env": {
    "ARGUS_SEARXNG_ENABLED": "true",
    "ARGUS_SEARXNG_BASE_URL": "http://127.0.0.1:<discovered-port>"
  }
  ```

  If the user chose free providers, leave `argus` as shown (no `env`).

**What each server does / what it needs:**

| Server      | Type  | Needs                                                                                                                                      |
| ----------- | ----- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `context7`  | STDIO | Nothing (public npx package, library docs).                                                                                                |
| `grep_app`  | HTTP  | Nothing (public, code search).                                                                                                             |
| `argus`     | STDIO | `uvx`. Web search; free providers by default, or SearXNG if the user provided a URL (see Prerequisites + conditional above).               |
| `mnemosyne` | STDIO | Cross-session memory. Binary path is machine-specific — see the conditional above. All other settings live in mnemosyne's own config. |
| `obscura`   | STDIO | The `obscura` Rust binary on `PATH`. Headless browser / page render.                                                                       |
| `nixos`     | STDIO | `uvx`. Query nixpkgs / NixOS options.                                                                                                      |

> `mnemosyne`'s `command` is machine-specific. Don't commit real paths — source
> them interactively per the conditional above, and never write the `<...>`
> placeholders verbatim.

## 6. Extensions (npm packages)

Already listed under `packages` in `settings.json` (step 4). On startup pi
installs missing entries into `~/.pi/agent/npm/` and updates
`~/.pi/agent/npm/package.json`. To install/update explicitly:

```bash
pi install npm:pi-zentui          # one package
pi update --extensions             # update all installed extensions
```

What they are:

- `@ff-labs/pi-fff` — fuzzy file finder + frecency-ranked search.
- `@howaboua/pi-skill-skill-creator` — ships the `skill-creator` skill (skill authoring quality guide).
- `@narumitw/pi-plan-mode` — plan mode (decision-ready plans before implementation).
- `pi-background-tasks` — background shell tasks / agents with notifications.
- `pi-cache-graph` — code graph caching (project reports, symbol search).
- `pi-hashline-edit-pro` — hashline-anchored precise file edits.
- `pi-lens` — diagnostics aggregator (LSP, lint, structural rules).
- `pi-mcp-adapter` — MCP server integration (config merging, oauth, `/mcp` panel).
- `pi-mono-ask-user-question` — interactive question tool.
- `pi-mono-auto-fix` — auto-fix loop.
- `pi-mono-btw` — side-channel notes.
- `pi-mono-context` — context management.
- `pi-mono-context-guard` — context protection.
- `pi-mono-review` — code review tooling.
- `pi-simplify` — output simplification.
- `pi-x-search` — X/Twitter search.
- `pi-zentui@0.22.3` — pinned: TUI rendering (pin survives updates; see patches/README if you apply local patches).
- `pk-pi-hermes-evolve` — Hermes-style reflective prompt/self-improvement loop.
## 7. Skills + local extension

Skills are `SKILL.md` files. pi loads them from (in order) `.pi/skills/`,
`.agents/skills/` (project, walking up parents), then `~/.pi/agent/skills/`
and `~/.agents/skills/` (user-global). User-global is what we seed here.

Both user-global skills are pulled from their upstream repos (see 7b) — nothing
skill-related is vendored here. The repo ships one **recipe doc** for a local
TypeScript extension:

- `litellm-auto.md` — the recipe for an optional extension that
  auto-discovers chat models from a self-hosted LiteLLM-compatible gateway
  (`/v1/model/info`) and registers them as a provider. Only relevant if you run
  your own gateway; skip otherwise. The doc contains the full minimal
  implementation, config env vars, hardening notes, and where credentials live.

**Machine-specific local extensions stay out of this repo.** Anything encoding
environment specifics (gateway URLs, deployment names, aliases) is written
directly in `~/.pi/agent/extensions/` on each machine, following the recipe
above. Examples:
- a gateway model-discovery extension (see `extensions/litellm-auto.md`)
- UI/render tweaks tied to a specific pi version
- machine-integration shims (e.g. terminal multiplexer or wrapper-agent
  integrations that talk to local sockets)

### 7b. User-global skills

- **`mnemosyne`** → from the upstream repo,
  **[mnemosyne-oss/mnemosyne](https://github.com/mnemosyne-oss/mnemosyne)** — do
  **not** vendor it here. Clone the repo and copy the memory-usage skill from
  `integrations/zero/skills/mnemosyne/SKILL.md` (agent-generic; teaches the
  `mnemosyne_remember` / `mnemosyne_recall` trigger discipline):

  ```bash
  git clone --depth 1 https://github.com/mnemosyne-oss/mnemosyne /tmp/mnemosyne
  mkdir -p ~/.pi/agent/skills/mnemosyne
  cp /tmp/mnemosyne/integrations/zero/skills/mnemosyne/SKILL.md ~/.pi/agent/skills/mnemosyne/
  rm -rf /tmp/mnemosyne
  ```

  Only relevant if you set up the mnemosyne MCP server (step 5). Note the
  upstream skill's `memory_*` naming section describes the plugin surface —
  the MCP tools are `mnemosyne_*` (the skill's MCP section covers this).
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
- **`skill-creator`** → no manual copy; exposed by the
  `@howaboua/pi-skill-skill-creator` npm extension (step 6). It's the
  authoring-quality reference skill.
- **`find-skills`, `hindsight-docs`, `microsoft-foundry`** →
  `~/.agents/skills/` (cross-agent convention). Install on demand via the
  `find-skills` skill; not required for a baseline setup.

No vendored skills remain — both come from their upstream repos (commands above).


If a skill ships inside a package/venv, copy just the `SKILL.md` (and any
referenced sibling files) into the target dir — pi reads the file directly.

### ⚠️ Restart pi before steps 8–10

Extensions (step 6 + 7) and MCP servers (step 5) load at pi **startup**,
not mid-session. You've just written `settings.json` and `mcp.json` during
this session, so the npm extensions and MCP servers are **not yet loaded** —
`/mcp` will show nothing until you restart. Exit pi and relaunch it, then
continue from step 8.

## 8. Seed memory

If you installed the `@amaster.ai/pi-memory` package (optional add-on, not in
the default package list above), `~/.pi/agent/memories/MEMORY.md` is the
agent's always-in-prompt memory, exposed via `memory_add` / `memory_read` /
`memory_replace` / `memory_remove` tools. It's char-limited — keep it to short
rules + key facts only, not task logs.

To seed it, use `memory_add` (one call per entry). **Don't hand-edit
`MEMORY.md`** — the tool writes the `§` entry delimiters itself, and
hand-editing risks breaking the format.

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

## 9. Checklist (user-provided, outside this repo)

These are **not in this repo** — supply them before first run:

- [ ] `~/.pi/agent/models.json` — provider configuration (you set this up, step 2).
- [ ] `~/.pi/agent/auth.json` — created automatically by `/login`.
- [ ] `argus` search backend — user's choice: **free providers** (default,
      nothing to do) or a **SearXNG base URL** they provide (see the SearXNG
      note in Prerequisites and the `argus` conditional in step 5).
- [ ] `obscura` binary on `PATH`; `uvx` on `PATH`.

## 10. Verify

```bash
pi                       # launches; no config errors
# inside pi:
/mcp                     # lists every server you configured, each "connected"
# tools from context7, grep_app, argus, obscura, nixos should appear;
# mnemosyne appears only if you kept the block (step 5)
```

Then check that an extension tool like `ask_user_question` or the pi-lens
diagnostics tools resolve. If a STDIO MCP server shows disconnected, run its
`command` + `args` manually to see the startup error, and confirm `env`/`PATH`
are set.

Confirm the npm extensions are live: run `pi config` and check the package list
from step 4 shows everything enabled; try a tool provided by one of them (e.g.
`ask_user_question` or the pi-lens diagnostics tools).
