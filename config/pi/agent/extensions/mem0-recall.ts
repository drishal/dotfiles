/**
 * mem0-recall — compact transcript rendering for mem0's recalled memories.
 *
 * @amaster.ai/pi-memory-mem0 injects its automatic recall as a custom message
 * (customType "mem0-recall", display: true) and registers no renderer, so pi
 * draws it with the default custom-message box: a tinted block with a label,
 * a heading and every memory in full, on every prompt. This registers a
 * renderer for that one message type:
 *
 *   ● Recalled 5 memories                    (collapsed, the default)
 *
 *   ╭─── Recalled 5 memories ──────────────╮  (ctrl+o, framed like neat-render's
 *   │ • Pi does not support native PDF     │   expanded tool rows)
 *   │   input even when the underlying…    │
 *   │ • User works with the pi CLI tool…   │
 *   ╰──────────────────────────────────────╯
 *
 * Only the display changes. The model still receives the full message.
 *
 * Config (env):
 *   MEM0_RECALL=compact  the above (default)
 *   MEM0_RECALL=hide     draw nothing (pi still leaves one blank line)
 *   MEM0_RECALL=full     pi's original box
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";

type Theme = { fg(color: string, text: string): string };

/** mem0 formats each memory as `- (date) [UNTRUSTED MEMORY DATA] "text"`. */
function memoriesOf(content: unknown): string[] {
	const text =
		typeof content === "string"
			? content
			: Array.isArray(content)
				? content
						.filter((c) => c?.type === "text")
						.map((c) => c.text)
						.join("\n")
				: "";
	return text
		.split("\n")
		.filter((line) => line.startsWith("- "))
		.map((line) =>
			line
				.slice(2)
				.replace(/^\(\d{4}-\d{2}-\d{2}\)\s*/, "")
				.replace(/^\[UNTRUSTED MEMORY DATA\]\s*/, "")
				.replace(/^"(.*)"$/, "$1"),
		);
}

class RecallView {
	constructor(
		private readonly memories: string[],
		private readonly expanded: boolean,
		private readonly pad: number,
		private readonly theme: Theme,
	) {}

	render(width: number): string[] {
		const { theme, memories } = this;
		const pad = " ".repeat(this.pad);
		// pi hard-errors on any line wider than it asked for.
		const fit = (s: string) => (visibleWidth(s) > width ? truncateToWidth(s, width) : s);

		const n = memories.length;
		const title = `Recalled ${n} ${n === 1 ? "memory" : "memories"}`;
		const w = width - this.pad;
		if (!this.expanded || n === 0 || w < 16) {
			return [fit(`${pad}${theme.fg("dim", "●")} ${theme.fg("muted", title)}`)];
		}

		// Expanded: the same frame neat-render draws around a ctrl+o tool row,
		// with the count set into the top border.
		const g = (s: string) => theme.fg("dim", s);
		const inner = w - 4; // "│ " + text + " │"
		const label = ` ${title} `;
		const out = [
			pad + g("╭───") + theme.fg("muted", label) + g("─".repeat(Math.max(0, w - 5 - visibleWidth(label)))) + g("╮"),
		];
		const boxed = (text: string) => {
			const t = visibleWidth(text) > inner ? truncateToWidth(text, inner) : text;
			return `${pad}${g("│")} ${t}${" ".repeat(Math.max(0, inner - visibleWidth(t)))} ${g("│")}`;
		};
		for (const memory of memories) {
			// Wrapped lines hang under the text, not under the bullet.
			wrapTextWithAnsi(memory, inner - 2).forEach((line, i) => {
				out.push(boxed(`${i === 0 ? theme.fg("dim", "•") : " "} ${theme.fg("muted", line)}`));
			});
		}
		out.push(pad + g(`╰${"─".repeat(Math.max(0, w - 2))}╯`));
		return out.map(fit);
	}

	invalidate(): void {}
}

export default function (pi: ExtensionAPI) {
	const mode = (process.env.MEM0_RECALL ?? "compact").toLowerCase();
	if (mode === "full") return;

	pi.registerMessageRenderer("mem0-recall", (message, options, theme) =>
		mode === "hide"
			? { render: () => [], invalidate() {} }
			: new RecallView(memoriesOf(message.content), options.expanded, options.outputPad, theme as Theme),
	);
}
