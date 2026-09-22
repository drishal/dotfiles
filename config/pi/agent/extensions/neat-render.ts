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
 *   NEAT_RENDER_RULES=0  drop the horizontal rules around a batch
 *   NEAT_RENDER_INSET=n  left inset for tool rows (default 1, matching pi's
 *                        message output pad; set 0 to hug the left edge)
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { ToolExecutionComponent, UserMessageComponent } from "@earendil-works/pi-coding-agent";
import { Container, visibleWidth } from "@earendil-works/pi-tui";

const CARD_PATCH = Symbol.for("dr.pi.neatRender.card.v1");
const ROW_PATCH = Symbol.for("dr.pi.neatRender.row.v1");
const GROUP_PATCH = Symbol.for("dr.pi.neatRender.group.v1");

type ThemeLike = {
	fg(slot: string, text: string): string;
	bg(slot: string, text: string): string;
	bold(text: string): string;
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
type Summary = { label: string; detail?: string; facts: string[] };

const READ_TOOLS = new Set(["read", "read_symbol", "read_enclosing"]);
const SEARCH_TOOLS = new Set([
	"grep", "anchor_grep", "ast_grep_search", "symbol_search", "find", "glob",
]);
const MUTATE_TOOLS = new Set([
	"write", "edit", "replace", "insert", "ast_grep_replace", "undo_last_change",
]);

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
		return { label: "Read", detail: where, facts: lines ? [`${lines} lines`] : [] };
	}

	if (name === "bash") {
		const cmd = str(args.command) ?? str(args.cmd) ?? "";
		// Prefer a real exit code when the tool reports one.
		const code = num(row.result?.details?.exitCode) ?? num(row.result?.details?.exit_code);
		const facts: string[] = [];
		if (code !== undefined) facts.push(`exit ${code}`);
		else if (!row.isPartial) facts.push(row.result?.isError ? "failed" : "exit 0");
		if (lines) facts.push(`${lines} lines`);
		return { label: "Bash", detail: `$ ${cmd}`, facts };
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
		return {
			label: name === "write" ? "Write" : name === "edit" ? "Edit" : name,
			detail: path ? shortPath(path) : undefined,
			facts: row.result?.isError ? [] : ["done"],
		};
	}

	// Unknown tool: show the first meaningful scalar argument.
	const firstArg = Object.values(args).map(str).find(Boolean);
	return {
		label: name,
		detail: firstArg,
		facts: lines ? [`${lines} lines`] : [],
	};
}

/** Render one tool row to a single styled line. */
function rowLine(row: ToolRow, theme: ThemeLike, width: number): string {
	const { label, detail, facts } = summarize(row);
	const sep = theme.fg("dim", " · ");
	const failed = row.result?.isError === true;

	let out = theme.bold(theme.fg("toolTitle", label));
	if (detail) out += ` ${theme.fg("syntaxVariable", oneLine(detail, Math.max(20, width - 28)))}`;
	if (row.isPartial) return `${out}${sep}${theme.fg("muted", "running…")}`;
	for (const f of facts) {
		out += sep + theme.fg(failed || /^(failed|exit [1-9])/.test(f) ? "error" : "success", f);
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

/* ── patch 2: compact tool rows ────────────────────────────────────────── */

function installRows(): Patchable | undefined {
	const proto = ToolExecutionComponent?.prototype as unknown as Patchable | undefined;
	if (!proto || typeof proto.render !== "function" || proto[ROW_PATCH]) return undefined;
	const original = proto.render;

	proto.render = function (width: number): string[] {
		const theme = state.theme;
		const row = this as unknown as ToolRow;
		// Expanded rows keep pi's full output; only the collapsed row is ours.
		if (!theme || row.expanded) return original.call(this, width);
		try {
			return [rowLine(row, theme, width)];
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
	const rules = !off("NEAT_RENDER_RULES");

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

function renderRun(run: ToolRow[], theme: ThemeLike, width: number, rules: boolean): string[] {
	const render = (r: ToolRow, w: number) =>
		(r as unknown as { render(x: number): string[] }).render(w);

	const pad = inset();

	// A lone call needs no batch chrome.
	if (run.length === 1) {
		const r = run[0];
		const dot = theme.fg(
			r.isPartial ? "warning" : r.result?.isError ? "error" : "accent",
			"●",
		);
		const lines = render(r, Math.max(8, width - pad.length - 2));
		return lines.map((l, idx) => (idx === 0 ? `${pad}${dot} ${l}` : `${pad}  ${l}`));
	}

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
		lines.forEach((line, li) => {
			const lead =
				li === 0
					? pad + theme.fg("dim", last ? "└─ " : "├─ ")
					: pad + theme.fg("dim", last ? "   " : "│  ");
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

export default function (pi: ExtensionAPI) {
	if (off("NEAT_RENDER")) return;

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
		uninstall(group, GROUP_PATCH);
		uninstall(rows, ROW_PATCH);
		uninstall(card, CARD_PATCH);
	});
}
