/**
 * litellm-auto — auto-discover chat models from a litellm proxy `/v1/model/info`.
 *
 * Registers provider "litellm" with every chat model, using the real
 * `max_model_len` as `contextWindow`. Models whose `max_model_len` is null
 * fall back to 131072.
 *
 * ── Fast startup ───────────────────────────────────────────────────────────
 * pi loads extensions **sequentially** and awaits each factory, so every
 * millisecond spent here delays every extension loaded after it. The factory
 * therefore does the bare minimum: read a small JSON cache, register, return
 * (~1ms warm — verify with `PI_TIMING=1 PI_STARTUP_BENCHMARK=1 pi`).
 *
 *   - The model list is cached at ~/.pi/agent/litellm-models-cache.json and
 *     registered straight from disk, so there is no network on the hot path.
 *   - The freshness check is deferred to the next macrotask on an unref'd
 *     timer, keeping undici's lazy init and the request kickoff (~25ms cold)
 *     off the factory entirely.
 *   - That check is skipped outright when the cache is younger than
 *     LITELLM_CACHE_TTL_MS or when pi is offline, and the cache file is
 *     rewritten only when the discovered list actually changed.
 *   - Every request is bounded by LITELLM_TIMEOUT_MS, so an unreachable
 *     gateway can no longer stall a cold start indefinitely.
 *
 * Sorting uses plain string comparison rather than `localeCompare`: the first
 * `localeCompare` call in a process initialises ICU and costs ~8ms, which is
 * most of a warm startup budget. Snapshot ordering only has to be stable.
 *
 * /reload-local forces a fresh fetch (ignoring the TTL), updates the cache,
 * re-registers, and reports what changed. Use it after adding/removing
 * deployments on the gateway without restarting pi.
 *
 * ── Precedence (models.json wins) ──────────────────────────────────────────
 * This extension owns the model *list*; per-model *field* overrides live in
 * ~/.pi/agent/models.json under `providers.litellm.modelOverrides`. Per the pi
 * docs, `modelOverrides` are applied on top of extension-registered models, so
 * anything you set there (contextWindow, maxTokens, reasoning, compat, …)
 * takes priority over the auto-discovered value.
 *
 *   // ~/.pi/agent/models.json
 *   {
 *     "providers": {
 *       "litellm": {
 *         "modelOverrides": {
 *           "<model-id>": { "maxTokens": 20000 },
 *           "<other-model-id>": { "contextWindow": 131072 }
 *         }
 *       }
 *     }
 *   }
 *
 * Do NOT put a `models` array under `litellm` in models.json — that would
 * conflict with this extension's registered list. Use `modelOverrides` only.
 *
 * ── Config (env vars, all optional) ────────────────────────────────────────
 *   LITELLM_BASE_URL      default ~/.pi/secrets/litellm.url (gitignored)
 *   LITELLM_API_KEY       default ~/.pi/secrets/litellm.key (gitignored)
 *   LITELLM_PROVIDER      default "litellm"  (must match settings.json defaultProvider)
 *   LITELLM_CACHE_PATH    default ~/.pi/agent/litellm-models-cache.json
 *   LITELLM_CACHE_TTL_MS  default 1800000 (30m). Skip the background refresh
 *                         while the cache is younger than this. 0 = always refresh.
 *   LITELLM_TIMEOUT_MS    default 4000. Per-request abort deadline.
 *   LITELLM_VERBOSE       set to 1 to log the full model list, not just counts.
 *   PI_OFFLINE            set by pi's --offline; suppresses all discovery.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { readFile, rename, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";

const SECRETS_DIR = join(homedir(), ".pi", "secrets");
/** Read a trimmed one-line value from ~/.pi/secrets (gitignored). */
async function readSecret(name: string): Promise<string | undefined> {
	try {
		const value = (await readFile(join(SECRETS_DIR, name), "utf8")).trim();
		return value || undefined;
	} catch {
		return undefined;
	}
}

/** Where pi keeps its own config; honours the env override. */
function agentDir(): string {
	return process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");
}

/**
 * The API key pi itself resolved for `provider`, straight out of auth.json.
 *
 * This is the credential pi authenticates inference with, so reading it here
 * keeps discovery and inference on one key by construction. The alternative —
 * a private copy under ~/.pi/secrets — silently rots the moment the gateway
 * key is rotated: pi keeps working (auth.json is updated by `/login`) while
 * discovery 401s on every startup against the stale copy.
 *
 * pi has `ModelRegistry.getApiKeyForProvider()`, but it is not reachable from
 * an extension — the ExtensionAPI surface is the `register…`, `get…`, `on`
 * and `send…` families, with no models or auth handle — so reading the file
 * is the supported-enough path. Shape is
 * `{ "<provider>": { "key": "...", "type": "api-key" } }`; OAuth providers
 * use `access`/`refresh` instead and are deliberately not handled, since a
 * LiteLLM gateway is an API-key provider.
 */
async function readAuthKey(provider: string): Promise<string | undefined> {
	try {
		const raw = await readFile(join(agentDir(), "auth.json"), "utf8");
		const entry = JSON.parse(raw)?.[provider];
		const key = typeof entry === "string" ? entry : entry?.key ?? entry?.apiKey;
		if (typeof key !== "string" || !key.trim()) return undefined;
		return await resolveKeyField(key.trim());
	} catch {
		return undefined;
	}
}

/** `!command` results, cached for the process like pi caches its own. */
const commandKeyCache = new Map<string, string | undefined>();

/**
 * Resolve an auth.json `key` the way pi does (docs/providers.md → Key
 * Resolution), so pointing pi at a secret manager does not quietly break
 * discovery:
 *
 *   "!op read 'op://vault/item/credential'"   → run it, use stdout
 *   "$LITELLM_KEY" / "${LITELLM_KEY}"          → environment interpolation
 *   "$$literal" / "$!literal"                  → escaped `$` / `!`
 *   anything else                              → literal
 *
 * Reading the raw field instead would send `!op read …` as the bearer token.
 * A literal key — the common case — costs nothing here.
 */
async function resolveKeyField(value: string): Promise<string | undefined> {
	if (value.startsWith("$$")) return `$${value.slice(2)}` || undefined;
	if (value.startsWith("$!")) return `!${value.slice(2)}` || undefined;

	if (value.startsWith("!")) {
		const cmd = value.slice(1);
		if (commandKeyCache.has(cmd)) return commandKeyCache.get(cmd);
		let out: string | undefined;
		try {
			const { execFile } = await import("node:child_process");
			const { promisify } = await import("node:util");
			const run = promisify(execFile);
			// A hanging secret helper must not hang startup; discovery is
			// already deferred off the hot path but the timeout is cheap.
			const { stdout } = await run(process.env.SHELL || "/bin/sh", ["-c", cmd], {
				timeout: 10_000,
				maxBuffer: 1 << 20,
			});
			out = stdout.trim() || undefined;
		} catch {
			out = undefined;
		}
		commandKeyCache.set(cmd, out);
		return out;
	}

	// Interpolate $VAR / ${VAR} anywhere in the value; an unset variable makes
	// the whole value unresolved, matching pi.
	if (value.includes("$")) {
		let unresolved = false;
		const interpolated = value.replace(
			/\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)/g,
			(_m, braced: string | undefined, bare: string | undefined) => {
				const env = process.env[(braced ?? bare) as string];
				if (env === undefined) unresolved = true;
				return env ?? "";
			},
		);
		return unresolved ? undefined : interpolated.trim() || undefined;
	}

	return value;
}
const DEFAULT_PROVIDER = "litellm";
const FALLBACK_CONTEXT_WINDOW = 131072;
const DEFAULT_MAX_TOKENS = 32000;
const DEFAULT_CACHE_TTL_MS = 30 * 60_000;
const DEFAULT_TIMEOUT_MS = 4000;

// /v1/model/info payload shape (only the fields we read).
interface ModelInfoEntry {
	model_name: string;
	litellm_params: {
		model?: string;
		custom_llm_provider?: string;
		reasoning_effort?: string | null;
		extra_body?: {
			chat_template_kwargs?: {
				thinking?: boolean | null;
				enable_thinking?: boolean | null;
				reasoning_effort?: string | null;
			} | null;
		} | null;
	};
	model_info: {
		max_model_len?: number | null;
		/** Gateway's own multimodal flag; absent on deployments that omit it. */
		supports_vision?: boolean | null;
		/** "chat" | "embedding" | "rerank" | …; null on many deployments. */
		mode?: string | null;
	} | null;
}

interface ModelInfoResponse {
	data?: ModelInfoEntry[];
}

type DiscoveredModel = {
	id: string;
	name: string;
	reasoning: boolean;
	// pi thinking levels -> reasoning_effort values sent to the gateway. Entries
	// for "xhigh"/"max" are what make those levels appear in the /thinking
	// picker (getSupportedThinkingLevels only shows them when mapped explicitly).
	thinkingLevelMap?: Partial<Record<
		"off" | "minimal" | "low" | "medium" | "high" | "xhigh" | "max",
		string | null
	>>;
	input: ("text" | "image")[];
	cost: { input: number; output: number; cacheRead: number; cacheWrite: number };
	contextWindow: number;
	maxTokens: number;
	compat: { maxTokensField: "max_tokens" };
};

type DiscoveryResult = {
	models: DiscoveredModel[];
	skipped: string[];
	source: string;
};

type CacheFile = {
	version: 1;
	fetchedAt: string;
	source: string;
	models: DiscoveredModel[];
	skipped: string[];
};

/* Read a positive-integer env var, falling back when unset or malformed. */
function envInt(name: string, fallback: number): number {
	const raw = process.env[name];
	if (raw === undefined) return fallback;
	const n = Number(raw);
	return Number.isFinite(n) && n >= 0 ? n : fallback;
}

function isOffline(): boolean {
	const raw = (process.env.PI_OFFLINE ?? "").toLowerCase();
	return raw === "1" || raw === "true" || raw === "yes";
}

// Substrings that mark a model as non-chat (embeddings / rerankers / retrieval).
const NON_CHAT_PATTERNS = [/embed/i, /rerank/i, /\bbge\b/i, /retriev/i, /sentence/i];

/*
 * No models are excluded by default: every chat model the gateway advertises
 * gets registered, and whether a deployment is actually healthy is decided at
 * runtime by trying it.
 *
 * This used to carry a hand-curated list of stale aliases and rate-limited
 * backends. That list was wrong the moment the gateway changed, had to be
 * re-probed by hand to stay true, and — being a map of which deployments exist
 * and which are unhealthy — was the only thing keeping this file out of
 * version control.
 *
 * The mechanism stays for ad-hoc use: LITELLM_EXCLUDE="a,b" (comma-separated,
 * case-insensitive against the model id, `*` is a wildcard) hides models for
 * one machine without editing this file. LITELLM_INCLUDE_DEAD=1 bypasses even
 * that.
 */
const EXCLUDED_MODELS: string[] = [];

/*
 * Build the exclusion matchers: escape regex metacharacters, then restore `*`.
 * Compiled once and memoised — discover() may run several times per process.
 */
let excludeCache: RegExp[] | null = null;
function excludePatterns(): RegExp[] {
	if (excludeCache) return excludeCache;
	const extra = (process.env.LITELLM_EXCLUDE ?? "")
		.split(",")
		.map((s) => s.trim())
		.filter(Boolean);
	excludeCache = [...EXCLUDED_MODELS, ...extra].map(
		(pattern) =>
			new RegExp(
				`^${pattern.replace(/[.*+?^${}()|[\]\\]/g, "\\$&").replace(/\\\*/g, ".*")}$`,
				"i",
			),
	);
	return excludeCache;
}

/*
 * Full thinking-level surface exposed to the /thinking picker.
 *
 * Per pi docs (docs/models.md → Thinking Level Map): a reasoning model shows
 * off..high by default, but "xhigh" and "max" ONLY appear when the model
 * declares them in thinkingLevelMap (see getSupportedThinkingLevels in
 * pi-ai: xhigh/max are hidden unless mapped explicitly). The gateway is an
 * OpenAI-compatible router that forwards reasoning_effort verbatim, so each
 * level maps to its own name — including the OpenAI-style "xhigh" effort.
 */
const FULL_THINKING_LEVEL_MAP = {
	minimal: "minimal",
	low: "low",
	medium: "medium",
	high: "high",
	xhigh: "xhigh",
	max: "max",
} as const;

/*
 * Capabilities come from the gateway, never from the model name.
 *
 * This file used to carry regex lists of model families that reason or accept
 * images. Those were guesses that went stale whenever a deployment changed,
 * and they encoded which models this particular gateway runs — the one thing
 * that made the file unshareable. /v1/model/info already answers both
 * questions, so the lists are gone.
 *
 * Where the gateway is silent the answer is "no", and the fix belongs in one
 * of two places, both outside this file:
 *
 *   - the gateway, by setting `supports_vision` or `enable_thinking` on the
 *     deployment — which fixes it for every client, not just pi; or
 *   - ~/.pi/agent/models.json under `providers.<name>.modelOverrides`, which
 *     wins over anything registered here (see the header).
 */

function detectVision(entry: ModelInfoEntry): boolean {
	return entry.model_info?.supports_vision === true;
}

function detectReasoning(entry: ModelInfoEntry): boolean {
	const kwargs = entry.litellm_params?.extra_body?.chat_template_kwargs;
	// Either spelling of the thinking toggle counts as an opt-in, and a
	// configured reasoning_effort implies the deployment accepts one.
	if (kwargs?.thinking === true || kwargs?.enable_thinking === true) return true;
	return (
		entry.litellm_params?.reasoning_effort != null ||
		kwargs?.reasoning_effort != null
	);
}

/*
 * Chat vs. embedding/rerank. The gateway's own `mode` is authoritative when
 * set, but it is null on most deployments here, so the name patterns remain as
 * a fallback. They match model *kinds* (embed/rerank/retrieval), not specific
 * models, so nothing gateway-specific lives in them — set `mode` on a
 * deployment and the fallback stops mattering for it.
 */
function isChatModel(entry: ModelInfoEntry): boolean {
	const mode = entry.model_info?.mode;
	if (typeof mode === "string" && mode.length > 0) return mode === "chat";

	const name = (entry.model_name || "").toLowerCase();
	const underlying = (entry.litellm_params?.model || "").toLowerCase();
	return !NON_CHAT_PATTERNS.some((re) => re.test(name) || re.test(underlying));
}

function toModelConfig(entry: ModelInfoEntry): DiscoveredModel {
	const id = entry.model_name;
	const contextWindow =
		entry.model_info?.max_model_len ?? FALLBACK_CONTEXT_WINDOW;
	const reasoning = detectReasoning(entry);
	// The gateway exposes no max_output_tokens; cap at ~1/4 of the window.
	// Override per-model via models.json `modelOverrides` when needed.
	const maxTokens = Math.min(DEFAULT_MAX_TOKENS, Math.floor(contextWindow / 4));

	return {
		id,
		name: id,
		reasoning,
		thinkingLevelMap: reasoning ? FULL_THINKING_LEVEL_MAP : undefined,
		input: (detectVision(entry) ? ["text", "image"] : ["text"]) as ("text" | "image")[],
		cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
		contextWindow,
		maxTokens,
		compat: {
			// vLLM/litellm uses the OpenAI field name, not max_completion_tokens.
			maxTokensField: "max_tokens" as const,
		},
	};
}

async function fetchJson<T>(
	url: string,
	apiKey: string,
	timeoutMs: number,
): Promise<{ ok: true; data: T } | { ok: false; error: string }> {
	try {
		// Bounded so a black-holed gateway cannot hang a cold start (which is
		// awaited) or leave a background request dangling for the session.
		const res = await fetch(url, {
			headers: { Authorization: `Bearer ${apiKey}` },
			signal: timeoutMs > 0 ? AbortSignal.timeout(timeoutMs) : undefined,
		});
		if (!res.ok) throw new Error(`HTTP ${res.status} ${res.statusText}`);
		return { ok: true, data: (await res.json()) as T };
	} catch (err) {
		const msg = err instanceof Error ? err.message : String(err);
		const timedOut = err instanceof Error && err.name === "TimeoutError";
		return { ok: false, error: timedOut ? `timed out after ${timeoutMs}ms` : msg };
	}
}

/** Fetch both endpoints, union them, apply chat/exclusion filters. */
async function discover(
	root: string,
	apiKey: string,
	timeoutMs: number,
): Promise<{ ok: true; result: DiscoveryResult } | { ok: false; error: string }> {
	// /v1/model/info carries rich metadata (max_model_len, underlying model,
	// thinking toggle). /v1/models is the OpenAI-standard id list and may expose
	// deployments the admin endpoint hides (team/passthrough models such as
	// a quantised variant). Union them: info entries win on metadata, /v1/models-only
	// ids are registered with inferred fields and a fallback context window.
	const [infoResult, modelsResult] = await Promise.all([
		fetchJson<ModelInfoResponse>(`${root}/model/info`, apiKey, timeoutMs),
		fetchJson<{ data?: { id: string }[] }>(`${root}/models`, apiKey, timeoutMs),
	]);

	if (!infoResult.ok && !modelsResult.ok) {
		return {
			ok: false,
			error:
				`model discovery failed ` +
				`(model/info: ${infoResult.error}; models: ${modelsResult.error})`,
		};
	}

	const byName = new Map<string, ModelInfoEntry>();
	for (const entry of infoResult.ok ? infoResult.data.data ?? [] : []) {
		if (entry.model_name) byName.set(entry.model_name, entry);
	}
	if (modelsResult.ok) {
		for (const m of modelsResult.data.data ?? []) {
			if (m.id && !byName.has(m.id)) {
				byName.set(m.id, {
					model_name: m.id,
					litellm_params: { model: m.id },
					model_info: { max_model_len: null },
				});
			}
		}
	}

	const excluded = process.env.LITELLM_INCLUDE_DEAD === "1" ? [] : excludePatterns();
	const skipped: string[] = [];

	const models = [...byName.values()]
		.filter(isChatModel)
		.map(toModelConfig)
		.filter((m) => Boolean(m.id))
		.filter((m) => {
			if (!excluded.some((re) => re.test(m.id))) return true;
			skipped.push(m.id);
			return false;
		});

	if (models.length === 0) {
		return { ok: false, error: "no chat models discovered" };
	}

	const source = `${infoResult.ok ? "model/info" : ""}${infoResult.ok && modelsResult.ok ? "+" : ""}${modelsResult.ok ? "models" : ""}`;
	return { ok: true, result: { models, skipped, source } };
}

/*
 * Stable snapshot key for change detection: id-sorted model list.
 * Deliberately NOT localeCompare — the first ICU-backed comparison in a process
 * costs ~8ms, and this runs on the startup path. Byte order is stable, which is
 * all a change-detection key needs.
 */
function snapshotKey(models: DiscoveredModel[]): string {
	return JSON.stringify(
		[...models]
			.sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
			.map((m) => [m.id, m.reasoning, m.thinkingLevelMap, m.input, m.contextWindow, m.maxTokens]),
	);
}

function ageLabel(iso: string | undefined): string {
	const t = iso ? Date.parse(iso) : NaN;
	if (!Number.isFinite(t)) return "unknown age";
	const mins = Math.round((Date.now() - t) / 60000);
	if (mins < 1) return "just now";
	if (mins < 90) return `${mins}m ago`;
	const hours = Math.round(mins / 60);
	if (hours < 48) return `${hours}h ago`;
	return `${Math.round(hours / 24)}d ago`;
}

/** Milliseconds since the cache was fetched, or Infinity if unknown. */
function cacheAgeMs(iso: string | undefined): number {
	const t = iso ? Date.parse(iso) : NaN;
	return Number.isFinite(t) ? Date.now() - t : Number.POSITIVE_INFINITY;
}

export default async function (pi: ExtensionAPI) {
	const baseUrl = process.env.LITELLM_BASE_URL ?? (await readSecret("litellm.url")) ?? "";
	const providerId = process.env.LITELLM_PROVIDER ?? DEFAULT_PROVIDER;
	// auth.json before secrets/: pi rewrites auth.json on `/login`, so it is
	// the one copy that cannot go stale. secrets/litellm.key stays as a
	// fallback for a machine that has the gateway but has never logged in.
	const apiKey =
		process.env.LITELLM_API_KEY ??
		(await readAuthKey(providerId)) ??
		(await readSecret("litellm.key")) ??
		"";
	const root = baseUrl.replace(/\/+$/, "");
	const cachePath =
		process.env.LITELLM_CACHE_PATH ?? join(agentDir(), "litellm-models-cache.json");
	const ttlMs = envInt("LITELLM_CACHE_TTL_MS", DEFAULT_CACHE_TTL_MS);
	const timeoutMs = envInt("LITELLM_TIMEOUT_MS", DEFAULT_TIMEOUT_MS);
	const verbose = process.env.LITELLM_VERBOSE === "1";

	let registeredKey: string | null = null;
	let registeredIds: Set<string> | null = null;
	let cachedKey: string | null = null;
	let cachedAt: string | undefined;
	let refreshInFlight: Promise<string> | null = null;

	const register = (result: DiscoveryResult, note: string) => {
		pi.registerProvider(providerId, {
			baseUrl,
			apiKey,
			api: "openai-completions",
			models: result.models,
		});
		registeredKey = snapshotKey(result.models);
		registeredIds = new Set(result.models.map((m) => m.id));
		// Silent on success. This ran on every `pi` invocation — including
		// `pi --help` and `pi --list-models` — announcing a provider that
		// nothing had asked about, and it is the first thing on screen at
		// startup. No other provider narrates its own registration. Failures
		// still speak up (see the refresh/error paths below), which is the
		// half that was ever actionable.
		// LITELLM_VERBOSE=1 brings it back, with the full id(window) listing.
		if (verbose) {
			console.log(
				`[litellm-auto] registered ${result.models.length} models from ${baseUrl} ` +
					`(${result.source}${note ? `, ${note}` : ""})` +
					`: ${result.models.map((m) => `${m.id}(${m.contextWindow})`).join(", ")}` +
					(result.skipped.length
						? ` — skipped ${result.skipped.length}: ${result.skipped.join(", ")}`
						: ""),
			);
		}
	};

	const writeCache = async (result: DiscoveryResult): Promise<void> => {
		const cache: CacheFile = {
			version: 1,
			fetchedAt: new Date().toISOString(),
			source: result.source,
			models: result.models,
			skipped: result.skipped,
		};
		const tmp = `${cachePath}.tmp`;
		await writeFile(tmp, JSON.stringify(cache, null, "\t"));
		await rename(tmp, cachePath);
		cachedAt = cache.fetchedAt;
		cachedKey = snapshotKey(result.models);
	};

	/** Fetch fresh, re-register on change, update cache. Returns a summary line. */
	const refresh = async (
		announce: (msg: string, type: "info" | "warning" | "error") => void,
	): Promise<string> => {
		const fetched = await discover(root, apiKey, timeoutMs);
		if (!fetched.ok) {
			const msg = `[litellm-auto] refresh failed: ${fetched.error} — keeping ${registeredKey ? "current list" : "no registration"}`;
			console.error(msg);
			announce(msg, "error");
			return msg;
		}
		const fresh = fetched.result;
		const freshKey = snapshotKey(fresh.models);

		// Only touch the disk when the list actually moved. Rewriting an
		// identical 5KB file on every startup buys nothing.
		if (freshKey !== cachedKey) {
			await writeCache(fresh).catch((err) =>
				console.error(`[litellm-auto] cache write failed: ${err instanceof Error ? err.message : err}`),
			);
		}

		if (registeredKey !== null && freshKey === registeredKey) {
			const msg = `[litellm-auto] ${fresh.models.length} models unchanged (${fresh.source})`;
			if (verbose) console.log(msg);
			announce(msg, "info");
			return msg;
		}
		const added: string[] = [];
		const removed: string[] = [];
		if (registeredIds !== null) {
			const prev = registeredIds;
			const next = new Set(fresh.models.map((m) => m.id));
			for (const id of next) if (!prev.has(id)) added.push(id);
			for (const id of prev) if (!next.has(id)) removed.push(id);
		}
		const hadRegistration = registeredKey !== null;
		register(fresh, cachedAt ? "refreshed" : "discovered");
		const change = !hadRegistration
			? ""
			: added.length || removed.length
				? ` (+${added.join(", ") || "-"}${removed.length ? `; -${removed.join(", ")}` : ""})`
				: " (fields changed)";
		const msg = `[litellm-auto] ${fresh.models.length} models updated from ${fresh.source}${change}`;
		if (hadRegistration) console.log(msg);
		announce(msg, "info");
		return msg;
	};

	/* Coalesce concurrent refreshes so /reload-local can never double-fetch. */
	const startRefresh = (
		announce: (msg: string, type: "info" | "warning" | "error") => void,
	): Promise<string> => {
		if (!refreshInFlight) {
			refreshInFlight = refresh(announce).finally(() => {
				refreshInFlight = null;
			});
		}
		return refreshInFlight;
	};

	// 1) Fast path: register from cache immediately — no network on the hot path.
	let hasCache = false;
	try {
		const raw = JSON.parse(await readFile(cachePath, "utf-8")) as CacheFile;
		if (Array.isArray(raw?.models) && raw.models.length > 0) {
			cachedAt = raw.fetchedAt;
			register(
				{ models: raw.models, skipped: raw.skipped ?? [], source: raw.source ?? "cache" },
				`cached ${ageLabel(raw.fetchedAt)}`,
			);
			cachedKey = registeredKey;
			hasCache = true;
		}
	} catch {
		// No cache / unreadable / corrupt → cold start below.
	}

	// 2) Discovery.
	//
	// Cold start (no cache): await it, so the provider exists before the factory
	// returns — pi may resolve the default model right after startup. Bounded by
	// timeoutMs so an unreachable gateway degrades instead of hanging.
	//
	// Warm start: defer to the next macrotask on an unref'd timer. The factory
	// returns without paying undici's first-call init, and a short-lived
	// invocation (`pi --help`, `--list-models`) exits without touching the
	// network at all. A changed list re-registers when the refresh lands.
	// Startup has no UI to notify; refresh() already writes to the console
	// itself, so announcing here would just double every line.
	const announceStartup = () => {};
	const offline = isOffline();
	if (!hasCache) {
		if (offline) {
			console.error(
				"[litellm-auto] offline and no cache — provider not registered; " +
					"run without --offline once to populate the model list",
			);
		} else {
			await startRefresh(announceStartup);
		}
	} else if (!offline && (ttlMs === 0 || cacheAgeMs(cachedAt) >= ttlMs)) {
		const timer = setTimeout(() => {
			void startRefresh(announceStartup).catch(() => {});
		}, 0);
		timer.unref?.();
	} else if (verbose) {
		console.log(
			`[litellm-auto] refresh skipped (${offline ? "offline" : `cache under ${Math.round(ttlMs / 60000)}m TTL`})`,
		);
	}

	// 3) /reload-local — force fresh fetch + cache update, report changes.
	pi.registerCommand("reload-local", {
		description: "Re-fetch litellm model list, update cache, re-register provider",
		handler: async (_args, ctx) => {
			// Drain any in-flight background refresh first so this always fetches
			// fresh rather than returning a result that predates the command.
			if (refreshInFlight) await refreshInFlight.catch(() => {});
			await startRefresh((m, type) => ctx.ui.notify(m, type));
		},
	});
}
