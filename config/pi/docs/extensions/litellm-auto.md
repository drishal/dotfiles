# litellm-auto: auto-discovering models from a LiteLLM proxy

This extension ships **per-machine** (gitignored at `agent/extensions/litellm-auto.ts`)
because it encodes private gateway details: deployment aliases, dead endpoints,
reasoning/vision quirks. This doc is the public recipe for rebuilding it.

## What it does

- Calls the LiteLLM proxy's `/v1/model/info` endpoint.
- Registers **every chat model** as a pi provider named after `LITELLM_PROVIDER`
  (default `litellm`), so `/model` lists them all with real context windows.
- Uses `max_model_len` as `contextWindow`; falls back to a constant when null.
- Caches the discovered list to `~/.pi/agent/litellm-models-cache.json` and
  registers from disk at startup — zero network on the hot path (~1ms warm).
- Refreshes in the background on an unref'd timer, skipping the fetch while the
  cache is younger than a TTL or pi is offline (`--offline`).
- Adds a `/reload-local` command to force a fresh fetch without restarting pi.

## Why an extension instead of `models.json`

`models.json` needs every model hand-written. `/v1/model/info` already knows
each deployment's context window, so discovery stays correct as models are
added/removed on the gateway. Keep `models.json` (if present) to
**`modelOverrides` only** — a `models` array there would conflict.

## Minimal implementation

```typescript
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";

const SECRETS_DIR = join(homedir(), ".pi", "secrets");

async function readSecret(name: string): Promise<string | undefined> {
  try {
    const value = (await readFile(join(SECRETS_DIR, name), "utf8")).trim();
    return value || undefined;
  } catch {
    return undefined;
  }
}

export default async function (pi: ExtensionAPI) {
  // resolution order: env var > secrets file (gitignored)
  const baseUrl =
    process.env.LITELLM_BASE_URL ?? (await readSecret("litellm.url")) ?? "";
  const apiKey =
    process.env.LITELLM_API_KEY ?? (await readSecret("litellm.key")) ?? "";
  const providerId = process.env.LITELLM_PROVIDER ?? "litellm";
  const root = baseUrl.replace(/\/+$/, "");

  const info = await fetch(`${root}/model/info`, {
    headers: { Authorization: `Bearer ${apiKey}` },
  }).then((r) => r.json());

  const models = (info.data ?? [])
    .filter((e: any) => e.model_info?.max_model_len !== 0)
    .map((e: any) => ({
      id: e.model_name,
      name: e.model_name,
      api: "openai-completions" as const,
      reasoning: /* see notes */ true,
      // Expose every thinking level (incl. xhigh/max) in pi's /thinking picker.
      // xhigh and max are only shown when mapped explicitly (docs/models.md).
      thinkingLevelMap: { minimal: "minimal", low: "low", medium: "medium",
        high: "high", xhigh: "xhigh", max: "max" },
      input: ["text"] as ("text" | "image")[],
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      contextWindow: e.model_info?.max_model_len ?? 131072,
      maxTokens: 32000,
      compat: { maxTokensField: "max_tokens" as const },
    }));

  pi.registerProvider(providerId, {
    baseUrl,
    apiKey,
    api: "openai-completions",
    models,
  });
}
```

Drop this at `~/.pi/agent/extensions/litellm-auto.ts` — pi auto-discovers it.
The full version adds caching, TTL, timeouts, and `/reload-local`; see the
"hardening" list below.

## Configuration

| Env var                | Purpose                                                                       |
| ---------------------- | ----------------------------------------------------------------------------- |
| `LITELLM_BASE_URL`     | Gateway root, e.g. `https://gateway.internal/v1` — or the secrets file        |
| `LITELLM_API_KEY`      | Bearer token — or the secrets file                                            |
| `LITELLM_PROVIDER`     | Provider id pi registers under (must match `settings.json` `defaultProvider`) |
| `LITELLM_EXCLUDE`      | Comma-separated deployment-name globs to hide (`*` wildcard supported)        |
| `LITELLM_CACHE_TTL_MS` | Skip background refresh while the cache is younger (default 30m)              |
| `LITELLM_TIMEOUT_MS`   | Per-request abort deadline (default 4000)                                     |
| `LITELLM_VERBOSE`      | `1` logs the full model list                                                  |

Secrets: put the URL and key in `~/.pi/secrets/litellm.url` / `litellm.key`
(gitignored, `chmod 600`). The extension reads them as fallback after env vars.

## Hardening for a real deployment

- **Cache-first startup.** Register from the cache synchronously; refresh async.
  Extensions load sequentially, so blocking on the network delays every
  extension after yours.
- **Write the cache atomically** (write `.tmp`, then `rename`) and only when the
  model list actually changed (compare a JSON snapshot key).
- **Bound every request** with an AbortController so an unreachable gateway
  can't stall startup.
- **Skip `localeCompare`** in sorting — first call initialises ICU (~8ms). Plain
  string comparison is enough for stable ordering.
- **`/reload-local` command** via `pi.registerCommand` for re-fetching after
  gateway changes without a restart.

## Inference-quality heuristics (generic, not deployment-specific)

`/v1/model/info` doesn't expose reasoning or vision flags. Workarounds that
worked well:

- **Reasoning:** the gateway's `chat_template_kwargs.thinking` flag only tells
  you whether an explicit thinking toggle is _sent_ — it's `null` for models
  that reason by default. Match the underlying model name
  (`litellm_params.model`, not the human `model_name` label) against public
  reasoning-capable families, and treat `no_think` / abliteration markers in
  the name as opt-outs.
- **Vision:** infer from the underlying model family the same way; public
  multimodal families only.
- **Field naming:** some inference servers expect the OpenAI `max_tokens` field,
  not `max_completion_tokens` — set `compat.maxTokensField` accordingly.
- **Dead aliases:** hide upstream-removed or rate-limited deployments via
  `LITELLM_EXCLUDE` (env) rather than hardcoding them, so the file stays generic.
