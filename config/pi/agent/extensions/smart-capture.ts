/**
 * smart-capture — a write gate in front of mem0's automatic capture.
 *
 * pi-memory-mem0's own autoCapture sends a user/assistant pair to the mem0
 * extractor after every prompt, and the extractor stores whatever it finds —
 * plans, one-off debugging state, restated answers. This extension owns
 * capture instead (set `"autoCapture": false` on pi-memory-mem0) and only
 * hands a turn to mem0 when it is worth it:
 *
 *   1. Skip the obvious (free): slash commands, acknowledgements ("ok",
 *      "thanks", "go ahead"), empty or aborted replies.
 *   2. Judge (cheap): one call to the same model mem0 extracts with — "does
 *      this exchange contain a durable fact?" — answered YES or NO. About 100
 *      completion tokens and well under a second on a local gateway.
 *   3. Store: YES goes to mem0 through its own provider, with its own config
 *      (customInstructions, scoping, dedup), so the write is identical to a
 *      normal capture.
 *
 * It judges the whole prompt, once, at agent_end: your message plus the
 * FINAL assistant answer — not the first streamed turn, which is usually
 * "let me check…" in front of a tool call.
 *
 * The provider, settings loader, project scoping and redaction are imported
 * from pi-memory-mem0 itself rather than re-implemented, so the gate writes to
 * exactly the namespace mem0 recalls from and cannot drift from it.
 *
 * Failure policy: if the judge errors or gives no clear answer, the turn is
 * stored anyway (mem0's extractor still filters). If the gate cannot start
 * while mem0's autoCapture is off, it warns — otherwise nothing would be
 * saved at all.
 *
 * Commands:
 *   /mem0gate          status: why it is on/off, judge model, counters
 *   /mem0gate on|off   toggle for this session
 *   /mem0gate last     the most recent decision and why
 *
 * Config (env):
 *   MEM0_GATE=off         disable the gate (turn mem0's autoCapture back on
 *                         if you still want automatic capture)
 *   MEM0_GATE_MODEL=p/id  judge with another model (default: mem0's llm)
 *   MEM0_GATE_DEBUG=1     log each decision to stderr
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { homedir } from "node:os";
import { join } from "node:path";

const SETTINGS_KEY = "pi-memory-mem0";
const AGENT_DIR = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");
const PKG = join(AGENT_DIR, "npm", "node_modules", "@amaster.ai");
// pi loads extensions through jiti rooted in pi's own install, so bare
// "@amaster.ai/..." specifiers do not resolve from ~/.pi/agent/npm. Absolute
// paths do, and they keep working when this file is a symlink into dotfiles.
const MEM0_PROVIDER = join(PKG, "pi-memory-mem0", "dist", "provider.js");
const MEM0_PRIVACY = join(PKG, "pi-memory-mem0", "dist", "privacy.js");
const PI_SETTINGS = join(PKG, "pi-shared", "dist", "settings.js");

/** Judge answers are cheap: ~100 completion tokens. Reasoning
 *  models spend a small budget entirely on thinking and return no content
 *  (64 did exactly that), so leave generous headroom. */
const JUDGE_MAX_TOKENS = 1024;
const JUDGE_TIMEOUT_MS = 20_000;
const SHUTDOWN_WAIT_MS = 10_000;

const JUDGE_SYSTEM = "You gate long-term memory writes for a coding agent. Answer with exactly one word: YES or NO.";
const JUDGE_PROMPT = `Does this exchange contain a DURABLE fact worth remembering in future sessions?

DURABLE: the user's preferences and standing instructions, corrections ("no, use X not Y"), machine/environment setup, project layout or names, decisions the user made, where things live (never secret values).
NOT DURABLE: plans or intentions of the assistant, research in progress, one-off task details, transient debugging state, answers to a passing question, summaries of what was just done, file contents.

<user>
{user}
</user>
<assistant>
{assistant}
</assistant>`;

/** Messages that never carry a durable fact. */
const ACK = /^(ok(ay)?|k|thanks?( you)?|thx|ty|yes|yep|yeah|no|nope|sure|go( ahead)?|continue|proceed|do it|nice|cool|great|perfect|lgtm|done|(hi|hello|hey)( there| all)?)\b[\s!.,]*$/i;

type Registry = {
	find?(provider: string, id: string): { baseUrl?: string; api?: string } | undefined;
	getAll?(): Array<{ provider: string; id: string; baseUrl?: string; api?: string }>;
	getApiKeyForProvider?(provider: string): Promise<string | undefined>;
};
type Provider = { add(messages: unknown[], opts: Record<string, unknown>): Promise<{ results?: unknown[] }> };
type Decision = { verdict: string; reason: string; user: string };

const stats = () => ({ seen: 0, skipped: 0, no: 0, yes: 0, unsure: 0, stored: 0, failed: 0 });

export default function (pi: ExtensionAPI) {
	const g = {
		enabled: (process.env.MEM0_GATE ?? "on").toLowerCase() !== "off",
		debug: process.env.MEM0_GATE_DEBUG === "1",
		/** Why the gate is idle, when it is. */
		idle: "not started" as string | undefined,
		provider: undefined as Provider | undefined,
		redact: (t: string) => t,
		scope: {} as Record<string, string>,
		judge: { url: "", key: "", model: "" },
		pending: Promise.resolve() as Promise<unknown>,
		last: undefined as Decision | undefined,
		stats: stats(),
		epoch: 0,
	};
	let lastUser = "";

	const log = (msg: string) => {
		if (g.debug) console.error(`[smart-capture] ${msg}`);
	};

	pi.on("session_start", async (_event, ctx) => {
		const epoch = ++g.epoch;
		g.provider = undefined;
		g.idle = "starting";
		g.stats = stats();
		g.last = undefined;
		lastUser = "";
		if (!g.enabled) {
			g.idle = "disabled (MEM0_GATE=off)";
			return;
		}
		let config: Record<string, any> = {};
		try {
			const settings = await import(PI_SETTINGS);
			config = settings.loadPiSettings(SETTINGS_KEY, {
				cwd: ctx.cwd,
				projectTrusted: settings.isProjectTrusted(ctx),
			});
			const memoryMode = config.memoryMode ?? "hybrid";
			if (config.autoCapture ?? memoryMode !== "active") {
				// mem0 captures on its own; gating as well would store twice.
				g.idle = 'mem0 autoCapture is on (set "autoCapture": false to gate)';
				return;
			}

			const registry = ctx.modelRegistry as unknown as Registry;
			const resolveProvider = async (name: string) => {
				if (!registry.getApiKeyForProvider) return undefined;
				const model = registry.getAll?.().find((m) => m.provider === name);
				const apiKey = await registry.getApiKeyForProvider(name);
				if (!apiKey && !model) return undefined;
				return {
					...(apiKey ? { apiKey } : {}),
					...(model?.baseUrl ? { baseUrl: model.baseUrl } : {}),
					...(model?.api ? { api: model.api } : {}),
				};
			};
			const [{ createMem0Provider }, privacy] = await Promise.all([
				import(MEM0_PROVIDER),
				import(MEM0_PRIVACY),
			]);
			const provider = (await createMem0Provider({ config, resolveProvider })) as Provider;

			// Judge with mem0's own extraction model unless overridden.
			const [jp, ...jid] = (process.env.MEM0_GATE_MODEL ?? "").split("/");
			const judgeProvider = jid.length ? jp : config.oss?.llm?.provider;
			const judgeModel = jid.length ? jid.join("/") : config.oss?.llm?.config?.model;
			if (!judgeProvider || !judgeModel) throw new Error("no judge model (mem0 oss.llm or MEM0_GATE_MODEL)");
			const target = registry.find?.(judgeProvider, judgeModel)
				?? registry.getAll?.().find((m) => m.provider === judgeProvider);
			const key = await registry.getApiKeyForProvider?.(judgeProvider);
			if (!target?.baseUrl || !key) throw new Error(`judge provider "${judgeProvider}" has no base URL or key`);

			if (epoch !== g.epoch) return; // a newer session_start won
			const base = config.userId?.trim() || process.env.USER || process.env.USERNAME || "default-user";
			g.scope = {
				userId: privacy.scopeMemoryUserId(base, ctx.cwd, config.userIdScope),
				...(config.agentId?.trim() ? { agentId: config.agentId.trim() } : {}),
			};
			g.redact = privacy.redactMemoryText;
			g.judge = { url: `${target.baseUrl.replace(/\/+$/, "")}/chat/completions`, key, model: judgeModel };
			g.provider = provider;
			g.idle = undefined;
		} catch (err) {
			if (epoch !== g.epoch) return;
			g.idle = `init failed: ${err instanceof Error ? err.message : String(err)}`;
			// autoCapture is off, so without the gate nothing is saved at all.
			if (ctx.hasUI) ctx.ui.notify(`mem0gate ${g.idle} — memories are not being saved`, "warning");
			else console.error(`[smart-capture] ${g.idle}`);
		}
	});

	pi.on("input", async (event) => {
		const text = (event as { text?: string }).text?.trim();
		if (text) lastUser = text;
	});

	/** YES / NO / undefined (no clear answer). */
	async function judge(user: string, assistant: string): Promise<boolean | undefined> {
		const res = await fetch(g.judge.url, {
			method: "POST",
			headers: { "Content-Type": "application/json", Authorization: `Bearer ${g.judge.key}` },
			body: JSON.stringify({
				model: g.judge.model,
				temperature: 0,
				max_tokens: JUDGE_MAX_TOKENS,
				messages: [
					{ role: "system", content: JUDGE_SYSTEM },
					{
						role: "user",
						content: JUDGE_PROMPT.replace("{user}", user.slice(0, 2000)).replace(
							"{assistant}",
							assistant.slice(-2000),
						),
					},
				],
			}),
			signal: AbortSignal.timeout(JUDGE_TIMEOUT_MS),
		});
		if (!res.ok) throw new Error(`judge HTTP ${res.status}`);
		const data = (await res.json()) as { choices?: Array<{ message?: { content?: string | null } }> };
		// Only the answer counts: reasoning text mentions both words.
		const words = (data.choices?.[0]?.message?.content ?? "").toUpperCase().match(/\b(YES|NO)\b/g);
		return words ? words[words.length - 1] === "YES" : undefined;
	}

	pi.on("agent_end", async (event) => {
		const user = lastUser;
		lastUser = "";
		if (!g.provider || !user) return;

		// The final answer: the last assistant message that has text.
		const messages = ((event as { messages?: unknown[] }).messages ?? []) as Array<{
			role?: string;
			stopReason?: string;
			content?: unknown;
		}>;
		const final = [...messages].reverse().find((m) => m.role === "assistant" && textOf(m.content));
		const assistant = final ? textOf(final.content) : "";
		g.stats.seen++;

		const skip = user.startsWith("/")
			? "slash command"
			: user.length < 6 || ACK.test(user)
				? "acknowledgement"
				: !assistant
					? "no answer"
					: final?.stopReason === "aborted" || final?.stopReason === "error"
						? `reply ${final.stopReason}`
						: undefined;
		if (skip) {
			g.stats.skipped++;
			g.last = { verdict: "skipped", reason: skip, user };
			log(`skip: ${skip}`);
			return;
		}

		const u = g.redact(user);
		const a = g.redact(assistant);
		let verdict: boolean | undefined;
		try {
			verdict = await judge(u, a);
		} catch (err) {
			log(`judge error: ${err instanceof Error ? err.message : String(err)}`);
		}
		if (verdict === false) {
			g.stats.no++;
			g.last = { verdict: "not stored", reason: "judge: NO", user };
			log("judge: NO");
			return;
		}
		if (verdict === true) g.stats.yes++;
		else g.stats.unsure++;
		g.last = { verdict: "stored", reason: verdict ? "judge: YES" : "judge unsure (fail-open)", user };
		log(g.last.reason);

		const provider = g.provider;
		const scope = g.scope;
		g.pending = g.pending
			.catch(() => {})
			.then(() => provider.add([{ role: "user", content: u }, { role: "assistant", content: a }], scope))
			.then((result) => {
				if ((result?.results?.length ?? 0) > 0) g.stats.stored++;
			})
			.catch((err) => {
				g.stats.failed++;
				console.error(`[smart-capture] store failed: ${err instanceof Error ? err.message : String(err)}`);
			});
	});

	pi.on("session_shutdown", async () => {
		// pi waits on shutdown handlers with no timeout; never hang the exit.
		await Promise.race([g.pending, new Promise((r) => setTimeout(r, SHUTDOWN_WAIT_MS).unref?.())]);
	});

	pi.registerCommand("mem0gate", {
		description: "Smart memory gate: status | on | off | last",
		handler: async (args, ctx) => {
			const sub = (args ?? "").trim().toLowerCase();
			if (sub === "on" || sub === "off") {
				g.enabled = sub === "on";
				ctx.ui.notify(`mem0gate ${g.enabled ? "on" : "off"} for this session`, "info");
				return;
			}
			if (sub === "last") {
				const d = g.last;
				ctx.ui.notify(d ? `${d.verdict} — ${d.reason}\n» ${d.user.slice(0, 160)}` : "no decisions yet this session", "info");
				return;
			}
			const s = g.stats;
			const state = !g.enabled ? "OFF" : g.idle ? `idle: ${g.idle}` : `ON · judge ${g.judge.model}`;
			ctx.ui.notify(
				`mem0gate ${state}\nprompts ${s.seen} · skipped ${s.skipped} · judged no ${s.no} · yes ${s.yes} · unsure ${s.unsure} · stored ${s.stored} · failed ${s.failed}`,
				"info",
			);
		},
	});

	function textOf(content: unknown): string {
		if (typeof content === "string") return content.trim();
		if (!Array.isArray(content)) return "";
		return content
			.filter((c) => c?.type === "text" && typeof c.text === "string")
			.map((c) => c.text)
			.join("\n")
			.trim();
	}
}
