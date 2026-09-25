/**
 * base16-theme — use a base16/base24 scheme YAML directly as a pi theme.
 *
 * Put any tinted-theming or stylix scheme in ~/.pi/agent/themes/ as
 * <name>.yaml (or .yml) and select it with `"theme": "<name>"`. pi only reads
 * JSON themes, so this extension writes <name>.json next to each YAML. It runs
 * at extension-load time, which is before pi applies the theme setting, so a
 * new scheme works on the very first launch; /reload regenerates after edits.
 *
 * Both scheme layouts are accepted: tinted-theming's (`system`/`name` plus a
 * `palette:` block) and the legacy flat base16 one (top-level baseXX keys).
 * base24 schemes use base10-base17; plain base16 schemes derive what they lack.
 *
 * The UI accent defaults to base09 (orange). A scheme can override it with a
 * top-level `accent: base0D` line, which other base16 tools ignore.
 *
 * Never clobbers: an existing <name>.json is rewritten only when it is a
 * regular file with this generator's exact layout. A symlink (dotfiles,
 * home-manager) or a hand-written theme of the same name is left alone and
 * reported instead.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";

const AGENT_DIR = process.env.PI_CODING_AGENT_DIR ?? `${process.env.HOME}/.pi/agent`;
const THEMES_DIR = path.join(AGENT_DIR, "themes");
const SCHEMA_URL =
	"https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
const BUILTIN_THEMES = new Set(["dark", "light"]);

/** Semantic slot -> var name. Scheme-independent. */
const SEMANTIC_COLORS: Record<string, string> = {
	accent: "accent",
	border: "border",
	borderAccent: "accent",
	borderMuted: "borderMuted",
	success: "green",
	error: "red",
	warning: "yellow",
	muted: "muted",
	dim: "dim",
	text: "text",
	thinkingText: "muted",
	selectedBg: "selectedBg",
	scrollbarThumb: "selectedBg",
	userMessageBg: "userMessageBg",
	userMessageText: "text",
	customMessageBg: "customMessageBg",
	customMessageText: "text",
	customMessageLabel: "purple",
	toolPendingBg: "toolPendingBg",
	toolSuccessBg: "toolSuccessBg",
	toolErrorBg: "toolErrorBg",
	toolTitle: "accentBright",
	toolOutput: "muted",
	mdHeading: "accentBright",
	mdLink: "cyan",
	mdLinkUrl: "muted",
	mdCode: "accentBright",
	mdCodeBlock: "text",
	mdCodeBlockBorder: "border",
	mdQuote: "muted",
	mdQuoteBorder: "accent",
	mdHr: "borderMuted",
	mdListBullet: "accent",
	toolDiffAdded: "green",
	toolDiffRemoved: "red",
	toolDiffContext: "muted",
	syntaxComment: "#6b7280",
	syntaxKeyword: "pink",
	syntaxFunction: "accentBright",
	syntaxVariable: "blue",
	syntaxString: "green",
	syntaxNumber: "orange",
	syntaxType: "cyan",
	syntaxOperator: "text",
	syntaxPunctuation: "muted",
	thinkingOff: "muted",
	thinkingMinimal: "dim",
	thinkingLow: "blue",
	thinkingMedium: "accent",
	thinkingHigh: "accentBright",
	thinkingXhigh: "#4db9cd",
	thinkingMax: "cyan",
	bashMode: "green",
};

type Palette = Record<string, string>;

/** Line-based reader: scheme files are a flat map of baseXX -> hex. */
function parseScheme(text: string): { pal: Palette; accent?: string } {
	const pal: Palette = {};
	let accent: string | undefined;
	for (const line of text.split(/\r?\n/)) {
		const m = /^\s*(base[0-9a-fA-F]{2})\s*:\s*["']?#?([0-9a-fA-F]{6})\b/.exec(line);
		if (m) {
			pal[m[1].toLowerCase()] = `#${m[2].toLowerCase()}`;
			continue;
		}
		const a = /^accent\s*:\s*["']?(base[0-9a-fA-F]{2})\b/.exec(line);
		if (a) accent = a[1].toLowerCase();
	}
	return { pal, accent };
}

const rgb = (h: string) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16));
const hex = (c: number[]) =>
	`#${c.map((v) => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, "0")).join("")}`;
/** Blend a toward b by t (0..1). */
const mix = (a: string, b: string, t: number) => {
	const y = rgb(b);
	return hex(rgb(a).map((x, i) => x + (y[i] - x) * t));
};

function buildVars(pal: Palette, accentKey: string): Record<string, string> {
	const b00 = pal.base00;
	const b05 = pal.base05;
	if (!b00 || !b05) throw new Error("scheme is missing base00/base05");
	const g = (k: string, fallback: string) => pal[k] ?? fallback;

	const b07 = g("base07", b05);
	const b01 = g("base01", mix(b00, b05, 0.08));
	const b02 = g("base02", mix(b00, b05, 0.16));
	const b03 = g("base03", mix(b00, b05, 0.34));
	const b04 = g("base04", mix(b00, b05, 0.62));
	const accent = pal[accentKey] ?? pal.base0d ?? b05;
	const purple = g("base0e", b05);

	return {
		// ground ladder: bg -> panel -> surface -> raised -> border
		bg: b00,
		panel: b01,
		surface: mix(b01, b02, 0.6),
		surfaceRaised: b02,
		// base03 is the comment colour and reads as heavy chrome against base00;
		// sit the border between selection and comment instead.
		border: mix(b02, b03, 0.5),
		borderMuted: b02,
		// accents
		accent,
		accentBright: mix(accent, b07, 0.3),
		purple,
		pink: g("base17", purple), // base24 bright purple
		cyan: g("base0c", b05),
		blue: g("base0d", b05),
		green: g("base0b", b05),
		red: g("base08", b05),
		yellow: g("base0a", b05),
		orange: g("base09", g("base0a", b05)),
		// ink
		text: b05,
		muted: b04,
		dim: b03,
		// message / tool grounds: base16 has no tinted backgrounds, so these are
		// the base ground pulled a little toward the status hue.
		selectedBg: b02,
		userMessageBg: b01,
		toolPendingBg: mix(b00, b01, 0.7),
		toolSuccessBg: mix(b00, g("base0b", b05), 0.14),
		toolErrorBg: mix(b00, g("base08", b05), 0.14),
		customMessageBg: mix(b00, purple, 0.12),
	};
}

const VAR_KEYS = Object.keys(buildVars({ base00: "#000000", base05: "#ffffff" }, "base09")).sort().join();
const canon = (o: Record<string, unknown>) =>
	JSON.stringify(Object.keys(o).sort().map((k) => [k, o[k]]));
const COLORS_CANON = canon(SEMANTIC_COLORS);

/** True when the JSON has exactly this generator's layout (so it is safe to rewrite). */
function isGenerated(file: string): boolean {
	try {
		const json = JSON.parse(fs.readFileSync(file, "utf-8"));
		return (
			typeof json?.vars === "object" &&
			typeof json?.colors === "object" &&
			Object.keys(json.vars).sort().join() === VAR_KEYS &&
			canon(json.colors) === COLORS_CANON
		);
	} catch {
		return false;
	}
}

/** Convert every themes/*.yaml|yml. Returns human-readable problems, if any. */
function generateThemes(): string[] {
	const problems: string[] = [];
	let entries: string[];
	try {
		entries = fs.readdirSync(THEMES_DIR);
	} catch {
		return problems; // no themes dir yet: nothing to do
	}
	const seen = new Set<string>();

	for (const file of entries.sort()) {
		const ext = path.extname(file);
		if (ext !== ".yaml" && ext !== ".yml") continue;
		const name = path.basename(file, ext);
		const src = path.join(THEMES_DIR, file);
		const out = path.join(THEMES_DIR, `${name}.json`);

		if (seen.has(name)) {
			problems.push(`${file}: another scheme already produced "${name}"`);
			continue;
		}
		seen.add(name);
		if (BUILTIN_THEMES.has(name)) {
			problems.push(`${file}: "${name}" is a built-in theme name; rename the file`);
			continue;
		}

		let json: string;
		try {
			const { pal, accent } = parseScheme(fs.readFileSync(src, "utf-8"));
			const theme = {
				$schema: SCHEMA_URL,
				name,
				vars: buildVars(pal, accent ?? "base09"),
				colors: SEMANTIC_COLORS,
			};
			json = `${JSON.stringify(theme, null, "\t")}\n`;
		} catch (err) {
			problems.push(`${file}: ${err instanceof Error ? err.message : String(err)}`);
			continue;
		}

		try {
			let stat = fs.lstatSync(out, { throwIfNoEntry: false });
			// A dangling link (e.g. a theme JSON since dropped from dotfiles)
			// points at nothing; replacing it cannot lose anything.
			if (stat?.isSymbolicLink() && !fs.existsSync(out)) stat = undefined;
			if (stat?.isSymbolicLink()) {
				problems.push(`${file}: ${name}.json is a symlink (managed elsewhere); not overwritten`);
				continue;
			}
			if (stat && !isGenerated(out)) {
				problems.push(`${file}: ${name}.json is a hand-written theme; not overwritten`);
				continue;
			}
			if (stat && fs.readFileSync(out, "utf-8") === json) continue;

			const tmp = `${out}.tmp`;
			fs.writeFileSync(tmp, json, "utf-8");
			fs.renameSync(tmp, out);
		} catch (err) {
			problems.push(`${file}: ${err instanceof Error ? err.message : String(err)}`);
		}
	}
	return problems;
}

export default function (pi: ExtensionAPI) {
	// Synchronous and at load time on purpose: pi resolves the theme setting
	// after extensions load, so the JSON must already exist on disk by then.
	const problems = generateThemes();
	if (problems.length === 0) return;

	pi.on("session_start", async (event, ctx) => {
		if (event.reason !== "startup" && event.reason !== "reload") return;
		if (ctx.hasUI) ctx.ui.notify(`base16-theme:\n  ${problems.join("\n  ")}`, "warning");
		else console.error(`[base16-theme] ${problems.join("; ")}`);
	});
}
