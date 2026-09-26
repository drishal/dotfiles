/**
 * neat-render — compact, Claude-Code-shaped transcript chrome for pi.
 *
 * Renders three things:
 *
 *   ╭─π────────────────────────────────────────────╮
 *   │ In a batch, launch a few read/grep commands.  │
 *   ╰──────────────────────────────────────────────╯
 *
 *   ● Batch 3/3 · succeeded · ctrl+o to inspect
 *     ├─ Read ../../AGENTS.md:1-12 · 14 lines
 *     ├─ grep pane=true · 1 result
 *     └─ Bash $ printf 'diagnostic'; pwd · exit 0 · 3 lines
 *
 * ── Why this is a renderer, not a tool wrapper ─────────────────────────────
 * The obvious way to get compact rows is to re-register `read`/`bash` with
 * custom `renderCall`/`renderResult` (this is what @vanillagreen/pi-tool-
 * renderer does). That is unusable here for two reasons: pi hard-errors on the
 * name clash with pi-hashline-edit-pro (`read`) and sudo-session.ts (`bash`),
 * and the wrapper delegates to the *built-in* tool, which would route around
 * hashline's anchored reads and sudo-session's elevation entirely.
 *
 * So nothing here registers, wraps, or deactivates a single tool. It patches
 * the three exported TUI components' `render` methods and reads what the row
 * already knows (`toolName`, `args`, `result`). Tool ownership is untouched,
 * and the compact rows work for every tool — including ones from extensions
 * this file has never heard of.
 *
 * Patches are keyed by `Symbol.for`, so a double install is a no-op and each
 * is reverted on `session_shutdown`.
 *
 * ── Conflicts ─────────────────────────────────────────────────────────────
 * Do NOT run this alongside @pi-kaush/pi-tool-call-markers, @pi-kaush/pi-
 * content-layout, or pi-cc-extensions: all of them patch the same prototypes,
 * and whichever loads last silently wins.
 *
 * ── Config (env) ──────────────────────────────────────────────────────────
 *   NEAT_RENDER=0        disable entirely
 *   NEAT_RENDER_CARD=0   leave user messages alone
 *   NEAT_RENDER_ROWS=0   leave tool rows alone (keeps grouping off too)
 *   NEAT_RENDER_SPLIT=0  one line per call: outcome stays on the call line
 *                        and a running command truncates instead of wrapping
 *   NEAT_RENDER_BATCH=1  restore the `Batch N/N · succeeded` header and the
 *                        ├─/└─ tree connectors (default: plain stacked rows)
 *   NEAT_RENDER_RULES=1  restore the horizontal rules around a run; needs
 *                        NEAT_RENDER_BATCH=1 to be visible
 *   NEAT_RENDER_PULSE=0  static bullet on running rows instead of a pulse
 *   NEAT_RENDER_COMMENTS=0  keep a bash command's leading `# comment`
 *                        lines inline instead of on a dim line above the call
 *   NEAT_RENDER_HIGHLIGHT=0  ctrl+o shows a bash command in pi's single
 *                        colour instead of syntax-highlighted
 *   NEAT_RENDER_FRAME=0  ctrl+o shows pi's tinted box instead of the
 *                        omp-style frame (command / Output / status)
 *   NEAT_RENDER_FOLD_THINKING=0  show fenced code inside thinking verbatim
 *   NEAT_RENDER_INSET=n  left inset for tool rows (default 1, matching pi's
 *                        message output pad; set 0 to hug the left edge)
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { highlightCode, ToolExecutionComponent, UserMessageComponent } from "@earendil-works/pi-coding-agent";
import { Container, truncateToWidth, visibleWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";

const CARD_PATCH = Symbol.for("dr.pi.neatRender.card.v1");
const ROW_PATCH = Symbol.for("dr.pi.neatRender.row.v1");
const GROUP_PATCH = Symbol.for("dr.pi.neatRender.group.v1");

type ThemeLike = {
	fg(slot: string, text: string): string;
	bg(slot: string, text: string): string;
	bold(text: string): string;
	italic?(text: string): string;
};

type ToolRow = {
	toolName?: string;
	args?: Record<string, unknown>;
	expanded?: boolean;
	isPartial?: boolean;
	result?: {
		isError?: boolean;
		content?: Array<{ type?: string; text?: string }>;
		details?: Record<string, unknown>;
	};
};

type RenderFn = (this: unknown, width: number) => string[];
type Patchable = { render: RenderFn; [key: symbol]: unknown };

/** Shared across the three patches; filled in on session_start. */
const state: { theme?: ThemeLike } = {};

const off = (name: string) => process.env[name] === "0";
/** For knobs that default off, so absent means off rather than on. */
const on = (name: string) => process.env[name] === "1";

/**
 * pi renders message content with an output pad of 1, so tool rows have to
 * start at the same column or the transcript reads as two ragged columns.
 */
function inset(): string {
	const n = Number(process.env.NEAT_RENDER_INSET ?? "1");
	return " ".repeat(Number.isFinite(n) && n >= 0 ? Math.min(8, n) : 1);
}

/* ── small helpers ─────────────────────────────────────────────────────── */

function resultText(row: ToolRow): string {
	const parts = row.result?.content;
	if (!Array.isArray(parts)) return "";
	return parts
		.filter((p) => p?.type === "text" && typeof p.text === "string")
		.map((p) => p.text as string)
		.join("\n");
}

/** "1 line", "12 lines". */
function plural(n: number, word: string): string {
	return `${n} ${word}${n === 1 ? "" : "s"}`;
}

function countLines(text: string): number {
	const trimmed = text.replace(/\n+$/, "");
	return trimmed ? trimmed.split("\n").length : 0;
}

function str(v: unknown): string | undefined {
	return typeof v === "string" && v.trim() ? v.trim() : undefined;
}

function num(v: unknown): number | undefined {
	return typeof v === "number" && Number.isFinite(v) ? v : undefined;
}

/** Collapse a path to something readable without losing the tail. */
function shortPath(p: string, cwd = process.cwd()): string {
	let out = p.startsWith(cwd) ? p.slice(cwd.length).replace(/^\/+/, "") : p;
	const home = process.env.HOME;
	if (home && out.startsWith(home)) out = `~${out.slice(home.length)}`;
	const segs = out.split("/");
	return segs.length > 4 ? `…/${segs.slice(-3).join("/")}` : out;
}

function oneLine(s: string, max: number): string {
	const flat = s.replace(/\s+/g, " ").trim();
	return flat.length > max ? `${flat.slice(0, max - 1)}…` : flat;
}

/* ── per-tool row text ─────────────────────────────────────────────────── */

/** A tool row reduced to label + detail + trailing facts. */
type Summary = {
	label: string;
	detail?: string;
	facts: string[];
	/** Text between label and detail. "" gives `Update(path)`; default " ". */
	glue?: string;
	/** Extra lines under the facts line, already split. Diff rows for edits. */
	body?: string[];
	/** Render nothing at all — a batch member that is not the commit. */
	hidden?: boolean;
	/** The model's own remark about the call (a bash command's leading
	 *  `# comment` lines), shown dim on its own line instead of in the detail. */
	note?: string;
};

/**
 * Split a bash command's leading `# comment` lines off the command.
 *
 * Models often narrate inside the command itself ("# check how pi loads
 * extensions ⏎ rg -n …"), which collapses to `$ # check how pi loads…` and
 * pushes the real command off the row. Only the display changes: the tool
 * still runs the command verbatim. A shebang is not a comment, and a command
 * that is nothing but comments is left alone.
 */
function splitLeadingComments(cmd: string, marker = "#"): { note?: string; command: string } {
	const lines = cmd.split("\n");
	const notes: string[] = [];
	let i = 0;
	for (; i < lines.length; i++) {
		const t = lines[i].trim();
		if (t === "" && notes.length > 0) continue;
		if (!t.startsWith(marker) || t.startsWith("#!")) break;
		const text = t.slice(marker.length).replace(/^[#/\s]*/, "");
		if (text) notes.push(text);
	}
	const command = lines.slice(i).join("\n").trim();
	if (!command || notes.length === 0) return { command: cmd };
	return { note: notes.join(" "), command };
}

/** Diff rows shown inline under an edit before the rest is elided. */
const DIFF_PREVIEW_LINES = 8;

/**
 * hashline emits ` anchor│text`, `-anchor│text`, `+anchor│text`. Strip the
 * anchor — it is addressing, not content — and keep the +/-/space marker so
 * the row reads as a diff.
 */
function diffPreview(diff: string): string[] {
	const rows = diff
		.split("\n")
		// A combined batch diff opens with a `batch N:` caption; the row count
		// is already on the stat line above.
		.filter((l) => l.length > 0 && !/^batch \d+:$/.test(l.trim()));
	const out: string[] = [];
	for (const row of rows.slice(0, DIFF_PREVIEW_LINES)) {
		const marker = row[0] === "+" || row[0] === "-" ? row[0] : " ";
		const bar = row.indexOf("│");
		out.push(`${marker} ${bar >= 0 ? row.slice(bar + 1) : row.slice(1)}`);
	}
	if (rows.length > out.length) out.push(`… ${rows.length - out.length} more`);
	return out;
}

/** "Added 35 lines, removed 2 lines" — Claude Code's phrasing. */
function diffStat(added?: number, removed?: number): string | undefined {
	const parts: string[] = [];
	if (added) parts.push(`Added ${added} line${added === 1 ? "" : "s"}`);
	if (removed) parts.push(`removed ${removed} line${removed === 1 ? "" : "s"}`);
	if (parts.length === 0) return undefined;
	return parts.join(", ");
}

const READ_TOOLS = new Set(["read", "read_symbol", "read_enclosing"]);
const SEARCH_TOOLS = new Set([
	"grep", "anchor_grep", "ast_grep_search", "symbol_search", "find", "glob",
]);
const MUTATE_TOOLS = new Set([
	"write", "edit", "replace", "insert", "ast_grep_replace", "undo_last_change",
]);
// Web tools take their subject under a named key, and the generic fallback
// below picks the first scalar *by key order* — which on `{mode, url}` shows
// "answer" and hides the URL entirely. Name them explicitly instead.
const WEB_TOOLS = new Set([
	"web_search", "web_fetch", "fetch_content", "get_search_content", "source_check",
]);

/** Drop the scheme and any trailing slash so a URL fits a row. */
function shortUrl(u: string): string {
	return u.replace(/^https?:\/\//, "").replace(/\/+$/, "");
}

function summarize(row: ToolRow): Summary {
	const name = row.toolName ?? "tool";
	const args = (row.args ?? {}) as Record<string, unknown>;
	const text = resultText(row);
	const lines = countLines(text);

	const path =
		str(args.path) ?? str(args.file_path) ?? str(args.filePath) ??
		str(args.file) ?? str(args.target);

	if (READ_TOOLS.has(name)) {
		let where = path ? shortPath(path) : (str(args.symbol) ?? "");
		const from = num(args.offset) ?? num(args.start_line) ?? num(args.startLine);
		const limit = num(args.limit);
		const to = num(args.end_line) ?? num(args.endLine) ??
			(from !== undefined && limit !== undefined ? from + limit - 1 : undefined);
		if (from !== undefined) where += to !== undefined ? `:${from}-${to}` : `:${from}`;
		return { label: "Read", detail: where, facts: lines ? [plural(lines, "line")] : [] };
	}

	if (name === "bash") {
		const cmd = str(args.command) ?? str(args.cmd) ?? "";
		// Prefer a real exit code when the tool reports one.
		const code = num(row.result?.details?.exitCode) ?? num(row.result?.details?.exit_code);
		const facts: string[] = [];
		// Success is the expected case and the bullet already colours for it,
		// so `exit 0` on every call is a word that never varies. Only a
		// non-zero code — or a failure with no code to report — says anything.
		if (code !== undefined) {
			if (code !== 0) facts.push(`exit ${code}`);
		} else if (!row.isPartial && row.result?.isError) {
			facts.push("failed");
		}
		if (lines) facts.push(plural(lines, "line"));
		const { note, command } = off("NEAT_RENDER_COMMENTS") ? { command: cmd } : splitLeadingComments(cmd);
		return { label: "Bash", detail: `$ ${command}`, facts, note };
	}

	if (name === "eval") {
		// The eval extension: a Python/JavaScript cell. Label by language,
		// show the first line of code (a leading comment goes above the row,
		// as for bash), and the size of what it printed.
		const lang = str(args.language);
		const code = str(args.code) ?? "";
		const { note, command } = off("NEAT_RENDER_COMMENTS")
			? { command: code }
			: splitLeadingComments(code, lang === "js" ? "//" : "#");
		const codeLines = command.split("\n").filter((l) => l.trim());
		const facts: string[] = [];
		if (!row.isPartial && row.result?.isError) facts.push("failed");
		if (lines) facts.push(plural(lines, "line"));
		const ms = num(row.result?.details?.durationMs);
		if (ms !== undefined && ms >= 1000) facts.push(`${(ms / 1000).toFixed(1)}s`);
		return {
			label: lang === "js" ? "JavaScript" : lang === "py" ? "Python" : "eval",
			detail: codeLines.length > 1 ? `${codeLines[0]} …` : codeLines[0],
			facts,
			note,
		};
	}

	if (WEB_TOOLS.has(name)) {
		// A url/query may arrive singular or as a list; show the first and say
		// how many more, so a parallel fan-out is still one readable row.
		const pick = (single: unknown, many: unknown): [string?, number?] => {
			const one = str(single);
			if (one) return [one, 1];
			if (Array.isArray(many)) {
				const first = str(many[0]);
				if (first) return [first, many.length];
			}
			return [undefined, undefined];
		};
		const [url, urlCount] = pick(args.url, args.urls);
		const [query, queryCount] = pick(args.query ?? args.q, args.queries);
		const subject = url ? shortUrl(url) : query;
		const count = url ? urlCount : queryCount;

		const facts: string[] = [];
		// `mode` is the thing that used to masquerade as the subject; it is a
		// modifier, so it belongs with the outcome, not the title.
		const mode = str(args.mode);
		if (mode && mode !== "readable") facts.push(mode);
		if (lines) facts.push(plural(lines, "line"));

		return {
			label: name,
			detail: subject
				? count && count > 1
					? `${subject} +${count - 1} more`
					: subject
				: undefined,
			facts,
		};
	}

	if (SEARCH_TOOLS.has(name)) {
		const q = str(args.pattern) ?? str(args.query) ?? str(args.regex) ?? str(args.name) ?? "";
		const scope = path ? ` in ${shortPath(path)}` : "";
		return {
			label: name === "anchor_grep" ? "grep" : name,
			detail: `${q}${scope}`,
			facts: lines ? [`${lines} ${lines === 1 ? "result" : "results"}`] : [],
		};
	}

	if (MUTATE_TOOLS.has(name)) {
		const d = (row.result?.details ?? {}) as {
			snapshotId?: unknown;
			classification?: unknown;
			diff?: unknown;
			batch?: { last?: unknown };
			metrics?: { added_lines?: unknown; removed_lines?: unknown };
		};

		// hashline groups same-file edits from one assistant message into a
		// batch that validates every member but commits once, on the last
		// call. The earlier members reply "In batch N" with no diff, and
		// their metrics are per-call; the last member carries the combined
		// diff and the combined totals. Rendering all of them turns a single
		// logical edit into a column of near-identical rows, so only the
		// commit is shown.
		const batch = d.batch;
		if (batch && batch.last === false && !row.isPartial) {
			return { label: name, facts: [], hidden: true };
		}

		// hashline's replace/insert identify the file by anchor, so `path` is
		// usually absent from the args. Its snapshotId is
		// `v2|<path>|<ino>|<mtime>|<ctime>|<size>`, which carries the real one.
		const snapPath = (() => {
			const snap = str(d.snapshotId);
			if (!snap) return undefined;
			const parts = snap.split("|");
			return parts.length > 2 ? parts[1] : undefined;
		})();
		const where = path ?? snapPath;

		const added = num(d.metrics?.added_lines);
		const removed = num(d.metrics?.removed_lines);
		const facts: string[] = [];
		let body: string[] | undefined;

		if (row.result?.isError) {
			// A failed edit used to render no facts at all — only a red dot,
			// with nothing saying what went wrong.
			facts.push("failed");
		} else if (str(d.classification) === "noop") {
			facts.push("no change");
		} else {
			const stat = diffStat(added, removed);
			if (stat) facts.push(stat);
			else if (added !== undefined || removed !== undefined) facts.push("no change");
			const diff = str(d.diff);
			if (diff) body = diffPreview(diff);
		}

		// `Update(path)` / `Write(path)`, the way Claude Code names an edit:
		// one verb, the file in parens, and the scale underneath.
		return {
			label: name === "write" ? "Write" : "Update",
			detail: where ? `(${shortPath(where)})` : undefined,
			glue: "",
			facts,
			body,
		};
	}

	// Unknown tool: show the first meaningful scalar argument.
	const firstArg = Object.values(args).map(str).find(Boolean);
	return {
		label: name,
		detail: firstArg,
		facts: lines ? [plural(lines, "line")] : [],
	};
}

/** Max continuation lines a running command's detail may wrap onto. */
const WRAP_LINES = 3;

/* ── in-flight pulse ───────────────────────────────────────────────────── */

/** Half-period of the bullet pulse, in ms. */
const PULSE_MS = 450;
/** Timer handle parked on a component so only one is ever in flight. */
const PULSE_TIMER = Symbol.for("dr.pi.neatRender.pulse.v1");
/** Every live timer, so session shutdown can cancel them. */
const pulseTimers = new Set<ReturnType<typeof setTimeout>>();

/** Which half of the pulse we are in right now. */
function pulseOn(): boolean {
	return Math.floor(Date.now() / PULSE_MS) % 2 === 0;
}

/**
 * Keep a running row repainting so its bullet can pulse.
 *
 * pi repaints on change, not on a clock, so a phase computed from Date.now()
 * would sit frozen on a long tool call — exactly when the feedback matters.
 * ToolExecutionComponent exposes `invalidate()`, so each render of a partial
 * row arms one unref'd timer that invalidates it, and the next render arms
 * the next. The chain stops on its own the moment the row stops being
 * partial, because only a partial row arms a timer.
 *
 * NEAT_RENDER_PULSE=0 turns it off and leaves a static bullet.
 */
function armPulse(component: unknown): void {
	if (off("NEAT_RENDER_PULSE")) return;
	const host = component as {
		invalidate?: () => void;
		[key: symbol]: unknown;
	};
	if (typeof host.invalidate !== "function") return;
	if (host[PULSE_TIMER]) return; // one in flight is enough

	const timer = setTimeout(() => {
		pulseTimers.delete(timer);
		host[PULSE_TIMER] = undefined;
		try {
			host.invalidate?.();
		} catch {
			/* component torn down mid-flight */
		}
	}, PULSE_MS);
	// Never let an animation frame hold the process open.
	(timer as { unref?: () => void }).unref?.();
	pulseTimers.add(timer);
	host[PULSE_TIMER] = timer;
}

function clearPulses(): void {
	for (const t of pulseTimers) clearTimeout(t);
	pulseTimers.clear();
}

/**
 * Word-wrap to `width`, hard-splitting any single token longer than a line
 * (paths and one-liner pipelines routinely are). Stops after `max` lines and
 * marks the cut, so a giant command cannot push the transcript off-screen.
 */
function wrapTo(text: string, width: number, max: number): string[] {
	const flat = text.replace(/\s+/g, " ").trim();
	if (width < 4) return [flat.slice(0, Math.max(1, width))];
	const out: string[] = [];
	let rest = flat;
	while (rest.length > 0 && out.length < max) {
		if (rest.length <= width) {
			out.push(rest);
			rest = "";
			break;
		}
		// Break at the last space that fits; fall back to a hard cut.
		let cut = rest.lastIndexOf(" ", width);
		if (cut <= 0) cut = width;
		out.push(rest.slice(0, cut));
		rest = rest.slice(cut).trimStart();
	}
	if (rest.length > 0 && out.length > 0) {
		const last = out[out.length - 1];
		out[out.length - 1] = `${last.slice(0, Math.max(0, width - 1))}…`;
	}
	return out;
}

/**
 * Render one tool row.
 *
 * Claude Code shows a finished call as the call plus its outcome on an
 * indented `└` continuation:
 *
 *   ● Bash $ ls ~/.pi/agent/extensions/
 *     └ exit 0 · 11 lines
 *
 * A *running* call instead puts the whole command on `└ $`, wrapped rather
 * than truncated, so you can actually read what is executing:
 *
 *   ● Bash · running…
 *     └ $ cd ~/dotfiles/config/pi && cat .gitignore && echo "═══ SIZES ═══"
 *       && find . -type f -newer ../../flake.lock | head -5 …
 *
 * Both callers already indent continuation lines (renderRun pads a lone
 * call by two columns and a batch child by its `│  `/`   ` lead), so extra
 * lines nest correctly with no layout work here.
 *
 * NEAT_RENDER_SPLIT=0 keeps the old single-line form.
 */
/** Lines a row puts above its call line (the `# remark`), per row. */
const LEAD_LINES = new WeakMap<ToolRow, number>();

function rowLines(row: ToolRow, theme: ThemeLike, width: number): string[] {
	const { label, detail, facts, glue, body: extra, hidden, note } = summarize(row);
	if (hidden) return [];
	const sep = theme.fg("dim", " · ");
	const failed = row.result?.isError === true;
	const split = !off("NEAT_RENDER_SPLIT");
	const join = glue ?? " ";

	// pi hard-errors if any rendered line exceeds the width it handed us, so
	// every return below goes through this. Sizing alone is not enough: the
	// label is a tool name of unknown length (`pi_lens_activate_tools` is 22
	// columns), so budgeting the detail against a constant overflows on the
	// long ones.
	const fit = (s: string) => (visibleWidth(s) > width ? truncateToWidth(s, width) : s);

	const running = row.isPartial === true;
	// The model's remark reads first, like a comment above a shell command.
	// It sits in the bullet column (see renderRun), so it heads the call below
	// it instead of trailing the previous row's result.
	const noteLine = note && split
		? (() => {
				const dim = theme.fg("dim", `# ${oneLine(note, Math.max(8, width))}`);
				return [fit(theme.italic ? theme.italic(dim) : dim)];
			})()
		: [];
	LEAD_LINES.set(row, noteLine.length);

	// Running, split mode: the command moves to its own wrapped `└ $` block,
	// so the header carries only the label and status.
	if (running && split && detail) {
		const header = fit(
			`${theme.bold(theme.fg("toolTitle", label))}${sep}${theme.fg("muted", "running…")}`,
		);
		// "└ " then the detail; continuation lines align under the detail.
		const lead = theme.fg("dim", "└ ");
		const body = wrapTo(detail, Math.max(8, width - 2), WRAP_LINES);
		return [
			...noteLine,
			header,
			...body.map((l, i) =>
				fit((i === 0 ? lead : "  ") + theme.fg("syntaxVariable", l)),
			),
		];
	}

	// Whatever still lands on the call line has to be budgeted for before the
	// detail is truncated, or the ellipsis eats the status instead of the path.
	const reserve = running
		? visibleWidth(sep) + visibleWidth("running…")
		: split
			? 0
			: 22;

	let head = theme.bold(theme.fg("toolTitle", label));
	if (detail) {
		// Measure what the label actually took, then give the rest to detail,
		// reserving the joiner's own width.
		const used = visibleWidth(head) + visibleWidth(join);
		head += `${join}${theme.fg("syntaxVariable", oneLine(detail, Math.max(8, width - used - reserve)))}`;
	}

	// A still-running call has no outcome yet; keep it on one line.
	if (running) return [fit(`${head}${sep}${theme.fg("muted", "running…")}`)];

	const paint = (f: string) =>
		theme.fg(failed || /^(failed|exit [1-9])/.test(f) ? "error" : "success", f);

	if (!split) {
		let out = head;
		for (const f of facts) out += sep + paint(f);
		return [fit(out)];
	}

	const out = [...noteLine, fit(head)];
	if (facts.length > 0) {
		out.push(fit(theme.fg("dim", "└ ") + facts.map(paint).join(sep)));
	}
	// Diff rows sit under the stat line, indented past the `└ ` and coloured
	// by their marker so an edit reads as a diff rather than a paragraph.
	for (const line of extra ?? []) {
		const slot = theme.fg(
			line.startsWith("+") ? "toolDiffAdded" : line.startsWith("-") ? "toolDiffRemoved" : "dim",
			line,
		);
		out.push(fit(`  ${slot}`));
	}
	return out;
}

/* ── patch 1: user message card ────────────────────────────────────────── */

function installCard(): Patchable | undefined {
	const proto = UserMessageComponent?.prototype as unknown as Patchable | undefined;
	if (!proto || typeof proto.render !== "function" || proto[CARD_PATCH]) return undefined;
	const original = proto.render;

	proto.render = function (width: number): string[] {
		const theme = state.theme;
		if (!theme || width < 12) return original.call(this, width);

		const inner = Math.max(1, width - 4);
		const body = original.call(this, inner);
		if (body.length === 0) return body;

		const g = (s: string) => theme.fg("success", s);
		const label = theme.fg("error", "π");
		// "╭", "─", "π" and "╮" are one column each, so the fill is width-4.
		// Getting this wrong by one wraps the line and drags the whole box askew.
		const top = g("╭─") + label + g("─".repeat(Math.max(0, width - 4))) + g("╮");
		const bottom = g("╰") + g("─".repeat(Math.max(0, width - 2))) + g("╯");

		const middle = body.map((line) => {
			const pad = Math.max(0, inner - visibleWidth(line));
			return `${g("│")} ${line}${" ".repeat(pad)} ${g("│")}`;
		});
		return [top, ...middle, bottom];
	} as RenderFn;

	proto[CARD_PATCH] = original;
	return proto;
}

/* ── expanded rows: framed, omp-style ──────────────────────────────────── */

type Renderable = { render(width: number): string[] };
/** The parts of pi's ToolExecutionComponent the frame is built from. */
type ToolInternals = {
	contentBox?: { children?: Renderable[] };
	imageComponents?: Renderable[];
	imageSpacers?: Renderable[];
	hasRendererDefinition?(): boolean;
	getRenderShell?(): string;
	formatToolExecution?(): string;
};

const ANSI_RE = /\x1b\[[0-9;?]*[A-Za-z]|\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)/g;
const isBlank = (line: string) => line.replace(ANSI_RE, "").trim() === "";

/** Drop the blank padding lines renderers put above and below their text. */
function trimBlank(lines: string[]): string[] {
	let a = 0;
	let b = lines.length;
	while (a < b && isBlank(lines[a])) a++;
	while (b > a && isBlank(lines[b - 1])) b--;
	return lines.slice(a, b);
}

/**
 * Make each highlighted line carry its own colour.
 *
 * highlightCode colours a token once and splits into lines afterwards, so a
 * token spanning lines — a quoted `node -e '…'` script, a heredoc — opens its
 * colour on the first line and closes it on the last, leaving the lines in
 * between uncoloured once each is drawn on its own. Re-open the colour at the
 * start of each continued line and close it at the end, so every framed line
 * is self-contained (and the border after it keeps its own colour).
 */
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

/**
 * A bash command for the expanded frame: `$ ` then the command syntax-
 * highlighted as bash with pi's own highlighter (the theme's syntax* colours,
 * the same as Markdown code blocks). Continuation lines — heredoc bodies,
 * `\`-continued lines, wrapped long lines — indent under the command.
 * pi's bash renderCall draws the whole command in one colour.
 */
function highlightedCommand(cmd: string, theme: ThemeLike, width: number): string[] {
	let lines: string[];
	try {
		lines = carryColour(highlightCode(cmd, "bash"));
	} catch {
		lines = cmd.split("\n");
	}
	const room = Math.max(8, width - 2);
	const out: string[] = [];
	lines.forEach((line, i) => {
		wrapTextWithAnsi(line, room).forEach((part, j) => {
			out.push((i === 0 && j === 0 ? theme.fg("dim", "$ ") : "  ") + part);
		});
	});
	return out;
}

/**
 * Ctrl+O view of one tool call, framed the way omp draws it:
 *
 *   ╭──────────────────────────────────────────────╮
 *   │ $ strings -n 4 ~/.local/bin/omp | sed -n '…' │
 *   ├─── Output ───────────────────────────────────┤
 *   │   type: "input_text",                        │
 *   ╰─── 40 lines ─────────────────────────────────╯
 *
 * Border colours follow omp's output-block states: dim when done, accent
 * while running, error on failure.
 *
 * pi's own expanded view puts the same content in a tinted box padded by a
 * blank line on every side, and the row bullet landed on that blank line,
 * alone. Here the call and result come straight from the children of pi's
 * content box — the tool's own renderCall/renderResult output, so diffs and
 * syntax colours survive — minus the tint. Images are drawn after the frame
 * rather than inside it, so terminal graphics are not clipped by borders.
 *
 * Returns undefined when the tool draws its own framing (render shell
 * "self"), leaving that one to pi. NEAT_RENDER_FRAME=0 restores pi's box.
 */
function framedLines(comp: unknown, row: ToolRow, theme: ThemeLike, width: number): string[] | undefined {
	const c = comp as ToolInternals;
	const inner = width - 4; // "│ " + text + " │"
	if (inner < 12) return undefined;

	let call: string[];
	let output: string[];
	if (c.hasRendererDefinition?.()) {
		if (c.getRenderShell?.() === "self") return undefined;
		const kids = c.contentBox?.children ?? [];
		if (kids.length === 0) return undefined;
		const [first, ...rest] = kids;
		const cmd = row.toolName === "bash" ? (str(row.args?.command) ?? str(row.args?.cmd)) : undefined;
		call = cmd && !off("NEAT_RENDER_HIGHLIGHT")
			? highlightedCommand(cmd, theme, inner)
			: trimBlank(first.render(inner));
		output = trimBlank(rest.flatMap((k) => k.render(inner)));
	} else {
		// No renderer at all: pi formats the whole call as one text block.
		const text = c.formatToolExecution?.();
		if (!text) return undefined;
		call = [];
		output = trimBlank(text.split("\n"));
	}

	// omp's state colours: quiet when done, accent while running, red on failure.
	const tone = row.isPartial ? "accent" : row.result?.isError ? "error" : "dim";
	const g = (s: string) => theme.fg(tone, s);
	const fit = (s: string) => (visibleWidth(s) > inner ? truncateToWidth(s, inner) : s);
	const boxed = (line: string) => {
		const t = fit(line);
		return `${g("│")} ${t}${" ".repeat(Math.max(0, inner - visibleWidth(t)))} ${g("│")}`;
	};
	/** A border with a label set into it after a 3-dash cap, as omp draws it:
	 *  `├─── Output ───┤`. Fill = width - (corner + cap) - label - corner. */
	const labelled = (left: string, label: string, right: string, color: string) => {
		const l = truncateToWidth(` ${label} `, Math.max(0, width - 5));
		return g(`${left}───`) + theme.fg(color, l) + g("─".repeat(Math.max(0, width - 5 - visibleWidth(l)))) + g(right);
	};

	const out = ["", g(`╭${"─".repeat(width - 2)}╮`)];
	out.push(...call.map(boxed));
	if (output.length > 0) {
		if (call.length > 0) out.push(labelled("├", "Output", "┤", "toolTitle"));
		out.push(...output.map(boxed));
	}
	const { facts } = summarize(row);
	const status = row.isPartial ? ["running…"] : facts;
	out.push(status.length > 0 ? labelled("╰", status.join(" · "), "╯", tone) : g(`╰${"─".repeat(width - 2)}╯`));

	// Images keep pi's own layout, below the frame.
	const images = c.imageComponents ?? [];
	images.forEach((img, i) => {
		const spacer = c.imageSpacers?.[i];
		if (spacer) out.push(...spacer.render(width));
		out.push(...img.render(width));
	});
	return out;
}

/* ── patch 2: compact tool rows ────────────────────────────────────────── */

function installRows(): Patchable | undefined {
	const proto = ToolExecutionComponent?.prototype as unknown as Patchable | undefined;
	if (!proto || typeof proto.render !== "function" || proto[ROW_PATCH]) return undefined;
	const original = proto.render;
	const frame = !off("NEAT_RENDER_FRAME");

	proto.render = function (width: number): string[] {
		const theme = state.theme;
		const row = this as unknown as ToolRow;
		if (!theme) return original.call(this, width);
		if (row.expanded) {
			if (frame) {
				try {
					const framed = framedLines(this, row, theme, width);
					if (framed) return framed;
				} catch {
					// fall through to pi's own expanded view
				}
			}
			return original.call(this, width);
		}
		// Arm the next pulse frame while this call is still in flight.
		if (row.isPartial) armPulse(this);
		try {
			return rowLines(row, theme, width);
		} catch {
			return original.call(this, width);
		}
	} as RenderFn;

	proto[ROW_PATCH] = original;
	return proto;
}

/* ── patch 3: batch grouping ───────────────────────────────────────────── */

/**
 * Container.render is a plain concat of child renders, so it is safe to
 * reimplement: pass everything through untouched except runs of adjacent
 * ToolExecutionComponents, which become one tree-connected block.
 */
function installGrouping(): Patchable | undefined {
	const proto = Container?.prototype as unknown as Patchable | undefined;
	if (!proto || typeof proto.render !== "function" || proto[GROUP_PATCH]) return undefined;
	const original = proto.render;
	const rules = on("NEAT_RENDER_RULES");

	proto.render = function (width: number): string[] {
		const theme = state.theme;
		const kids = (this as { children?: unknown[] }).children;
		if (!theme || !Array.isArray(kids) || kids.length === 0) {
			return original.call(this, width);
		}
		if (!kids.some((k) => k instanceof ToolExecutionComponent)) {
			return original.call(this, width);
		}

		const out: string[] = [];
		for (let i = 0; i < kids.length; ) {
			if (!(kids[i] instanceof ToolExecutionComponent)) {
				const child = kids[i] as { render(w: number): string[] };
				out.push(...child.render(width));
				i += 1;
				continue;
			}
			// Collect the whole adjacent run.
			let end = i;
			while (end < kids.length && kids[end] instanceof ToolExecutionComponent) end += 1;
			const run = kids.slice(i, end) as unknown as ToolRow[];
			out.push(...renderRun(run, theme, width, rules));
			i = end;
		}
		return out;
	} as RenderFn;

	proto[GROUP_PATCH] = original;
	return proto;
}

/**
 * Render a run of adjacent tool calls.
 *
 * Every call — batched or not — gets the same bulleted row, stacked one
 * below the next:
 *
 *   ● Bash $ grep -rniE '(api[_-]?key|secret|token)' .
 *     └ exit 0 · 80 lines
 *   ● Bash $ grep -rniE '(sk-[a-zA-Z0-9]|ghp_)' .
 *     └ exit 0 · 13 lines
 *
 * There is deliberately no `Batch N/N · succeeded` header and no tree
 * connectors. The header repeated on every parallel spawn while saying
 * nothing the rows do not: each row already carries its own status, so an
 * aggregate one is noise. Claude Code collapses the whole run to a dim
 * "Ran 2 shell commands" instead; keeping the rows is the more informative
 * half of that trade, dropping the chrome is the quieter half.
 *
 * NEAT_RENDER_BATCH=1 restores the header and tree connectors.
 * NEAT_RENDER_RULES=1 restores the horizontal rules around a run.
 */
function renderRun(run: ToolRow[], theme: ThemeLike, width: number, rules: boolean): string[] {
	const render = (r: ToolRow, w: number) =>
		(r as unknown as { render(x: number): string[] }).render(w);

	const pad = inset();
	// A running bullet alternates bright/dim so in-flight work reads as alive;
	// both glyphs are one column, so this cannot affect line width.
	const dotFor = (r: ToolRow) =>
		r.isPartial
			? theme.fg(pulseOn() ? "warning" : "dim", "●")
			: theme.fg(r.result?.isError ? "error" : "accent", "●");

	/** One call as a bulleted row; continuation lines align under the text. */
	const bulleted = (r: ToolRow): string[] => {
		// An expanded (ctrl+o) row is a frame — or pi's box — which carries its
		// own chrome. A bullet there sat alone on the box's blank first line.
		if (r.expanded) return render(r, Math.max(8, width - pad.length)).map((l) => (l ? pad + l : l));
		const lines = render(r, Math.max(8, width - pad.length - 2));
		const lead = LEAD_LINES.get(r) ?? 0;
		return lines.map((l, idx) =>
			idx < lead ? `${pad}${l}` : idx === lead ? `${pad}${dotFor(r)} ${l}` : `${pad}  ${l}`,
		);
	};

	if (run.length === 1 || !on("NEAT_RENDER_BATCH")) {
		return run.flatMap(bulleted);
	}

	// ── opt-in legacy chrome ────────────────────────────────────────────────
	const running = run.some((r) => r.isPartial);
	const failed = run.some((r) => r.result?.isError === true);
	const status = running ? "running" : failed ? "failed" : "succeeded";
	const sep = theme.fg("dim", " · ");

	const header =
		`${pad}${theme.fg(running ? "warning" : failed ? "error" : "accent", "●")} ` +
		theme.bold(theme.fg("toolTitle", `Batch ${run.length}/${run.length}`)) +
		sep +
		theme.fg(running ? "warning" : failed ? "error" : "success", status) +
		sep +
		theme.fg("dim", "ctrl+o to inspect");

	const out: string[] = [];
	const rule = () => pad + theme.fg("borderMuted", "─".repeat(Math.max(0, width - pad.length)));
	if (rules) out.push(rule());
	out.push(header);

	run.forEach((child, idx) => {
		const last = idx === run.length - 1;
		const lines = render(child, Math.max(8, width - pad.length - 5));
		const first = LEAD_LINES.get(child) ?? 0;
		lines.forEach((line, li) => {
			const lead =
				li === first
					? pad + theme.fg("dim", last ? "└─ " : "├─ ")
					: pad + theme.fg("dim", li < first || !last ? "│  " : "   ");
			out.push(lead + line);
		});
	});
	if (rules) out.push(rule());
	return out;
}

/* ── wiring ────────────────────────────────────────────────────────────── */

function uninstall(proto: Patchable | undefined, key: symbol): void {
	if (!proto) return;
	const original = proto[key];
	if (typeof original === "function") proto.render = original as RenderFn;
	delete proto[key];
}

const FENCE_RE = /^(\s*)(`{3,}|~{3,})(.*)$/;

/**
 * Elide fenced code out of a thinking block, leaving a trailing ellipsis.
 *
 * A reasoning trace that quotes a config file or a diff buries its own
 * argument: the prose is the part worth reading, and the code is usually
 * something already on screen. Folding it to "…" keeps the trace scannable.
 * Ported from omp's prose-only thinking mode (packages/tui/src/chat/
 * thinking-display.ts), which appends the ellipsis to the preceding line
 * rather than emitting a placeholder, so the result reads as prose trailing
 * off instead of a collapsed region.
 *
 * An unterminated fence — the common case mid-stream — folds too, so the
 * block does not flash open as it arrives. Only the *display* is folded;
 * the transcript, the session file and the model's context are untouched.
 *
 * NEAT_RENDER_FOLD_THINKING=0 shows thinking verbatim.
 */
function foldThinkingFences(md: string): string {
	if (!md || (!md.includes("```") && !md.includes("~~~"))) return md;

	const out: string[] = [];
	let inFence = false;
	let fenceChar = "";
	let fenceLen = 0;
	let elided = false;

	/** Trail the previous non-blank line off, rather than adding a marker. */
	const addEllipsis = (): void => {
		for (let i = out.length - 1; i >= 0; i--) {
			const t = out[i].trimEnd();
			if (t === "") continue;
			if (t.endsWith("...") || t.endsWith("…")) out[i] = t;
			else out[i] = t.endsWith(".") ? `${t.slice(0, -1)}...` : `${t}...`;
			return;
		}
		out.push("...");
	};

	for (const line of md.split("\n")) {
		const m = FENCE_RE.exec(line);
		if (inFence) {
			// A closing fence is the same char, at least as long, alone on the
			// line — so a shorter ``` inside a ```` block does not close it.
			if (m && m[2][0] === fenceChar && m[2].length >= fenceLen && m[3].trim() === "") {
				inFence = false;
				fenceChar = "";
				fenceLen = 0;
			}
			continue;
		}
		if (m) {
			inFence = true;
			fenceChar = m[2][0];
			fenceLen = m[2].length;
			addEllipsis();
			elided = true;
			continue;
		}
		out.push(line);
	}
	return elided ? out.join("\n") : md;
}

export default function (pi: ExtensionAPI) {
	if (off("NEAT_RENDER")) return;

	if (!off("NEAT_RENDER_FOLD_THINKING")) {
		pi.registerMarkdownTransformer((markdown, context) =>
			context.messageType === "assistant-thinking" ? foldThinkingFences(markdown) : markdown,
		);
	}

	const card = off("NEAT_RENDER_CARD") ? undefined : installCard();
	const rows = off("NEAT_RENDER_ROWS") ? undefined : installRows();
	// Grouping composes the row renderer, so it only makes sense with it.
	const group = rows ? installGrouping() : undefined;

	pi.on("session_start", (_event, ctx) => {
		state.theme = ctx.ui.theme as unknown as ThemeLike;
	});

	let released = false;
	pi.on("session_shutdown", () => {
		if (released) return;
		released = true;
		clearPulses();
		uninstall(group, GROUP_PATCH);
		uninstall(rows, ROW_PATCH);
		uninstall(card, CARD_PATCH);
	});
}
