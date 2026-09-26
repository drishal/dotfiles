/**
 * eval — run Python or JavaScript in a persistent kernel, one cell per call.
 *
 * The model otherwise does this through bash — `python - <<'EOF' … EOF`,
 * `node -e '…'` — which re-reads every file and re-imports every library on
 * each call, and renders as one long quoted string. Here each language gets
 * one process for the whole session, so what a cell defines (variables,
 * imports, loaded data, functions) is still there in the next call.
 *
 *   python      runner.py — plain CPython: trailing-expression value, top-level
 *               await, `!cmd` and `%pip install`, tracebacks trimmed to the
 *               cell. Uses `python3` on PATH (EVAL_PYTHON to override).
 *   javascript  kernel.cjs — Node's own REPL evaluator: top-level await,
 *               persistent declarations, require()/import() from the project,
 *               built-in modules as globals.
 *
 * Both kernels start in the session's working directory on first use and stop
 * with the session. A timeout or Esc sends Ctrl+C to the cell; a kernel that
 * does not stop within a few seconds is killed and restarted, and the result
 * says that its state is gone.
 *
 * Modelled on oh-my-pi's `eval` tool (IPython/Bun kernels), minus its agent,
 * tool-bridge and background machinery.
 *
 * Config (env):
 *   EVAL_PYTHON=<path>    interpreter for Python cells (default python3)
 *   EVAL_NODE=<path>      node for JavaScript cells (default: the one running pi)
 *   EVAL_TIMEOUT=<sec>    default cell timeout (default 120; 0 = none)
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { highlightCode } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { type ChildProcess, spawn } from "node:child_process";
import { basename, dirname, join } from "node:path";
import { createInterface } from "node:readline";
import { fileURLToPath } from "node:url";
import { Type } from "typebox";

type Lang = "py" | "js";
const LANG_NAME: Record<Lang, string> = { py: "Python", js: "JavaScript" };
const HIGHLIGHT: Record<Lang, string> = { py: "python", js: "javascript" };

const HERE = dirname(fileURLToPath(import.meta.url));
const DEFAULT_TIMEOUT_S = Number(process.env.EVAL_TIMEOUT ?? 120);
const STARTUP_TIMEOUT_MS = 20_000;
/** Grace period for a cell to stop after Ctrl+C before the kernel is killed. */
const INTERRUPT_GRACE_MS = 3_000;
/** What goes back to the model; the middle of anything longer is dropped. */
const MAX_OUTPUT_CHARS = 30_000;
const UPDATE_EVERY_MS = 200;

function kernelCommand(lang: Lang): [string, string[]] {
	if (lang === "py") return [process.env.EVAL_PYTHON ?? "python3", ["-u", join(HERE, "runner.py")]];
	// process.execPath is node for a normal pi install; fall back to PATH if
	// pi runs as a single-file binary.
	const node = process.env.EVAL_NODE ?? (/^node(\.exe)?$/.test(basename(process.execPath)) ? process.execPath : "node");
	return [node, [join(HERE, "kernel.cjs")]];
}

type Done = { type: "done"; id: number; ok: boolean; value?: string; error?: string };
type CellResult = {
	ok: boolean;
	output: string;
	value?: string;
	error?: string;
	durationMs: number;
};
type Pending = {
	id: number;
	output: string;
	carry: [string, string];
	seen: [boolean, boolean];
	done?: Done;
	started: number;
	resolve: (r: CellResult) => void;
	onOutput?: (output: string) => void;
	settle?: ReturnType<typeof setTimeout>;
};

class Kernel {
	readonly ready: Promise<string>;
	dead = false;
	#proc: ChildProcess;
	#seq = 0;
	#queue: Promise<unknown> = Promise.resolve();
	#pending?: Pending;

	constructor(readonly lang: Lang, cwd: string) {
		const [cmd, args] = kernelCommand(lang);
		this.#proc = spawn(cmd, args, {
			cwd,
			stdio: ["pipe", "pipe", "pipe", "pipe"],
			env: {
				...process.env,
				PYTHONUNBUFFERED: "1",
				PYTHONIOENCODING: "utf-8",
				NODE_NO_WARNINGS: "1",
				FORCE_COLOR: "0",
			},
		});
		const proc = this.#proc;
		this.ready = new Promise<string>((resolve, reject) => {
			const timer = setTimeout(() => reject(new Error(`${LANG_NAME[lang]} kernel did not start within ${STARTUP_TIMEOUT_MS / 1000}s`)), STARTUP_TIMEOUT_MS);
			proc.once("error", (err) => {
				clearTimeout(timer);
				this.dead = true;
				const hint = lang === "py" ? " (set EVAL_PYTHON to a Python 3 interpreter)" : " (set EVAL_NODE)";
				reject(new Error(`cannot start ${cmd}: ${err.message}${hint}`));
			});
			createInterface({ input: proc.stdio[3] as NodeJS.ReadableStream }).on("line", (line) => {
				let msg: { type?: string; runtime?: string } & Partial<Done>;
				try {
					msg = JSON.parse(line);
				} catch {
					return;
				}
				if (msg.type === "ready") {
					clearTimeout(timer);
					resolve(msg.runtime ?? LANG_NAME[lang]);
				} else if (msg.type === "done" && this.#pending?.id === msg.id) {
					this.#pending.done = msg as Done;
					this.#tryFinish();
				}
			});
		});
		this.ready.catch(() => {});
		proc.stdout?.setEncoding("utf8");
		proc.stderr?.setEncoding("utf8");
		proc.stdout?.on("data", (chunk: string) => this.#onData(0, chunk));
		proc.stderr?.on("data", (chunk: string) => this.#onData(1, chunk));
		proc.on("exit", (code, signal) => {
			this.dead = true;
			const p = this.#pending;
			if (p) {
				this.#pending = undefined;
				clearTimeout(p.settle);
				p.resolve({
					ok: false,
					output: p.output,
					error: `${LANG_NAME[lang]} kernel exited (${signal ?? `code ${code}`}) — its state is gone`,
					durationMs: Date.now() - p.started,
				});
			}
		});
	}

	/** Split the sentinel off a stream; remember a possibly split one. */
	#onData(stream: 0 | 1, chunk: string): void {
		const p = this.#pending;
		if (!p) return; // output between cells (background work) is dropped
		const marker = `\u0000EVAL_DONE:${p.id}\u0000`;
		let text = p.carry[stream] + chunk;
		p.carry[stream] = "";
		const at = text.indexOf(marker);
		if (at >= 0) {
			text = text.slice(0, at);
			p.seen[stream] = true;
		} else {
			const zero = text.lastIndexOf("\u0000");
			if (zero >= 0 && text.length - zero < marker.length) {
				p.carry[stream] = text.slice(zero);
				text = text.slice(0, zero);
			}
		}
		if (text) {
			p.output += text;
			p.onOutput?.(p.output);
		}
		this.#tryFinish();
	}

	#tryFinish(): void {
		const p = this.#pending;
		if (!p?.done) return;
		const finish = () => {
			if (this.#pending !== p) return;
			this.#pending = undefined;
			clearTimeout(p.settle);
			p.resolve({
				ok: p.done!.ok,
				output: p.output,
				value: p.done!.value ?? undefined,
				error: p.done!.error ?? undefined,
				durationMs: Date.now() - p.started,
			});
		};
		if (p.seen[0] && p.seen[1]) return finish();
		// The cell closed its own stdout/stderr: do not wait forever.
		p.settle ??= setTimeout(finish, 300);
	}

	/** Run one cell. Cells of one kernel run strictly one after another. */
	exec(code: string, timeoutMs: number, signal: AbortSignal | undefined, onOutput?: (o: string) => void): Promise<CellResult> {
		const run = async (): Promise<CellResult> => {
			await this.ready;
			if (this.dead) throw new Error(`${LANG_NAME[this.lang]} kernel is not running`);
			const id = ++this.#seq;
			return new Promise<CellResult>((resolve) => {
				const p: Pending = {
					id,
					output: "",
					carry: ["", ""],
					seen: [false, false],
					started: Date.now(),
					resolve,
					onOutput,
				};
				this.#pending = p;
				const stop = (why: string) => this.#interrupt(p, why);
				const timer = timeoutMs > 0 ? setTimeout(() => stop(`timed out after ${timeoutMs / 1000}s`), timeoutMs) : undefined;
				const onAbort = () => stop("aborted");
				signal?.addEventListener("abort", onAbort, { once: true });
				const original = p.resolve;
				p.resolve = (r) => {
					clearTimeout(timer);
					signal?.removeEventListener("abort", onAbort);
					original(r);
				};
				this.#proc.stdin?.write(`${JSON.stringify({ id, code })}\n`);
			});
		};
		const next = this.#queue.then(run, run);
		this.#queue = next.catch(() => {});
		return next;
	}

	/** Ctrl+C the cell; kill the kernel if it does not stop in time. */
	#interrupt(p: Pending, why: string): void {
		if (this.#pending !== p) return;
		this.#proc.kill("SIGINT");
		setTimeout(() => {
			if (this.#pending !== p) return;
			this.#pending = undefined;
			p.resolve({
				ok: false,
				output: p.output,
				error: `${why}; the cell did not stop, so the ${LANG_NAME[this.lang]} kernel was restarted — all of its state is gone`,
				durationMs: Date.now() - p.started,
			});
			this.dispose();
		}, INTERRUPT_GRACE_MS).unref?.();
	}

	dispose(): void {
		this.dead = true;
		try {
			this.#proc.stdin?.end();
			this.#proc.kill("SIGKILL");
		} catch {
			// already gone
		}
	}
}

/** Keep the model-facing output bounded: head and tail, middle dropped. */
function bound(text: string): string {
	if (text.length <= MAX_OUTPUT_CHARS) return text;
	const half = Math.floor(MAX_OUTPUT_CHARS / 2);
	const dropped = text.length - 2 * half;
	return `${text.slice(0, half)}\n… [${dropped} characters omitted — print a summary, or write large results to a file] …\n${text.slice(-half)}`;
}

/** highlightCode colours a multi-line token once; re-open it on each line. */
function carryColour(lines: string[]): string[] {
	let open = "";
	return lines.map((line) => {
		const full = open + line;
		open = "";
		for (const m of full.matchAll(/\x1b\[([0-9;]*)m/g)) {
			const code = m[1];
			if (code === "" || code === "0" || code === "39") open = "";
			else if (/^(38;|3[0-7]$|9[0-7]$)/.test(code)) open = m[0];
		}
		return open ? `${full}\x1b[39m` : full;
	});
}

const DESCRIPTION = `Run Python or JavaScript in a persistent kernel: one cell per call, and everything a cell defines (variables, imports, loaded data, functions) is still there in later calls.

Use it instead of \`python -c\`, \`python - <<'EOF'\` or \`node -e\` through bash — for calculations, parsing, data wrangling, exploring JSON/CSV/logs, and multi-step analysis. Load data once, then reuse it; do not re-read files or re-run setup that already succeeded.

- The value of the last expression is shown (as in a REPL); print() for anything else.
- Python: CPython with the packages installed for it; top-level \`await\` works; \`!cmd\` runs a shell command; \`%pip install pkg\` installs into this interpreter.
- JavaScript: Node.js REPL semantics — top-level \`await\`, require()/import() resolve from the working directory, built-in modules (fs, path, os, …) are globals.
- Both start in the working directory. Output is capped at ${MAX_OUTPUT_CHARS} characters — print summaries, not whole datasets.
- On an error, fix and re-run only the failing step: earlier cells already ran.
- \`reset: true\` restarts that language's kernel first (all its state is lost).`;

export default function (pi: ExtensionAPI) {
	const kernels = new Map<Lang, Kernel>();
	/** Languages whose kernel died or was reset this session. */
	const lost = new Set<Lang>();

	const disposeAll = () => {
		for (const k of kernels.values()) k.dispose();
		kernels.clear();
		lost.clear();
	};

	pi.on("session_start", async () => disposeAll());
	pi.on("session_shutdown", async () => disposeAll());

	pi.registerTool({
		name: "eval",
		label: "eval",
		description: DESCRIPTION,
		promptSnippet: "Run Python or JavaScript in a persistent kernel (state survives between calls)",
		promptGuidelines: [
			"Use `eval` rather than `python -c`, `python - <<EOF` or `node -e` in bash for scripts, calculations and data work; its state persists between calls.",
		],
		executionMode: "sequential",
		parameters: Type.Object({
			language: Type.Unsafe<Lang>({
				type: "string",
				enum: ["py", "js"],
				description: '"py" for Python, "js" for JavaScript (Node.js)',
			}),
			code: Type.String({ description: "The cell: one or more statements; the last expression's value is shown." }),
			timeout: Type.Optional(Type.Number({ description: `Seconds before the cell is interrupted (default ${DEFAULT_TIMEOUT_S}; 0 = no limit).` })),
			reset: Type.Optional(Type.Boolean({ description: "Restart this language's kernel before running (all its state is lost)." })),
		}),

		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			const lang: Lang = params.language === "js" ? "js" : "py";
			const notes: string[] = [];

			let kernel = kernels.get(lang);
			if (params.reset && kernel) {
				kernel.dispose();
				kernel = undefined;
				notes.push(`(${LANG_NAME[lang]} kernel reset — earlier state is gone)`);
			} else if (kernel?.dead) {
				kernel = undefined;
				lost.add(lang);
			}
			if (!kernel) {
				if (lost.delete(lang) && !params.reset) notes.push(`(${LANG_NAME[lang]} kernel restarted — earlier state is gone)`);
				kernel = new Kernel(lang, ctx.cwd);
				kernels.set(lang, kernel);
			}

			let last = 0;
			const stream = (output: string) => {
				const now = Date.now();
				if (!onUpdate || now - last < UPDATE_EVERY_MS) return;
				last = now;
				onUpdate({ content: [{ type: "text", text: output.slice(-4000) }], details: { language: lang, partial: true } });
			};

			const timeoutS = params.timeout ?? DEFAULT_TIMEOUT_S;
			const result = await kernel.exec(params.code, Math.max(0, timeoutS) * 1000, signal, stream);
			if (kernel.dead) lost.add(lang);

			const parts = [...notes];
			const output = result.output.replace(/\s+$/, "");
			if (output) parts.push(bound(output));
			if (result.ok && result.value !== undefined) parts.push(`Out: ${bound(result.value)}`);
			if (!result.ok && result.error) parts.push(result.error);
			const text = parts.join("\n") || "(no output)";

			// A failing cell is a tool error, so it renders as one (red row).
			if (!result.ok) throw new Error(text);
			return {
				content: [{ type: "text", text }],
				details: { language: lang, ok: true, durationMs: result.durationMs },
			};
		},

		renderCall(args, theme) {
			const lang: Lang = args.language === "js" ? "js" : "py";
			const head = theme.bold(theme.fg("toolTitle", LANG_NAME[lang])) + (args.reset ? theme.fg("warning", " · reset") : "");
			const code = typeof args.code === "string" ? args.code : "";
			let body: string[];
			try {
				body = code ? carryColour(highlightCode(code, HIGHLIGHT[lang])) : [];
			} catch {
				body = code.split("\n");
			}
			return new Text([head, ...body].join("\n"), 0, 0);
		},

		renderResult(result, options, theme) {
			const block = result.content?.find((c) => c.type === "text");
			const lines = (block?.type === "text" ? block.text : "").split("\n");
			const keep = options.expanded ? lines.length : 12;
			const shown = lines.slice(-keep).map((l) => theme.fg("toolOutput", l));
			if (lines.length > keep) shown.unshift(theme.fg("dim", `… ${lines.length - keep} earlier lines (ctrl+o to expand)`));
			return new Text(shown.join("\n"), 0, 0);
		},
	});
}
