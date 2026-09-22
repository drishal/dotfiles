/**
 * remember-model — persist the last user-selected model + thinking level so
 * the next session starts on it instead of resetting to defaultModel.
 *
 * Pi's `/model` and `/thinking` pickers persist via Ctrl+S into settings.json
 * (defaultModel / defaultThinkingLevel / modelThinkingLevels). When you just
 * select with Enter (no Ctrl+S), the choice applies only to the current
 * session and the next launch reverts to whatever is in settings.json.
 *
 * This extension closes that gap: on every non-restore `model_select` and
 * `thinking_level_select`, it writes the selection back into settings.json,
 * so the next launch restores exactly what you last picked.
 *
 * - `model_select` source "set" | "cycle"  → persist provider+model
 *   (source "restore" is the launch-time restore of an already-saved pick;
 *   re-persisting it would be a no-op but is skipped to avoid write churn)
 * - `thinking_level_select`                → persist level + per-model pin
 *
 * No state of its own; reads/writes ~/.pi/agent/settings.json only.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";

const AGENT_DIR = process.env.PI_AGENT_DIR ?? `${process.env.HOME}/.pi/agent`;
const SETTINGS_PATH = path.join(AGENT_DIR, "settings.json");

interface SettingsShape {
	defaultProvider?: string;
	defaultModel?: string;
	defaultThinkingLevel?: string;
	modelThinkingLevels?: Record<string, string>;
	[key: string]: unknown;
}

/**
 * Merge-patch settings.json with an atomic temp-file + rename so a crash
 * mid-write cannot leave a truncated file.
 *
 * Pi writes settings.json asynchronously through a file lock (proper-lockfile
 * lockfile on the real path). This extension cannot reach that lock from the
 * bundled runtime, so it minimizes the race instead: read-modify-write in one
 * synchronous block, last-writer-wins. Conflicts with pi's own Ctrl+S saves
 * are rare (both touch different keys, and pi deep-merges nested fields), and
 * the writes are debounced below so bursts of model_select/thinking events
 * collapse to a single disk write.
 */
function patchSettings(patch: SettingsShape): void {
	try {
		const current: SettingsShape = fs.existsSync(SETTINGS_PATH)
			? (JSON.parse(fs.readFileSync(SETTINGS_PATH, "utf-8")) as SettingsShape)
			: {};

		const next: SettingsShape = { ...current, ...patch };

		// Deep-merge modelThinkingLevels so a per-model pin does not wipe
		// pins for other models.
		if (patch.modelThinkingLevels && current.modelThinkingLevels) {
			next.modelThinkingLevels = {
				...current.modelThinkingLevels,
				...patch.modelThinkingLevels,
			};
		}

		const tmp = `${SETTINGS_PATH}.tmp`;
		fs.writeFileSync(tmp, JSON.stringify(next, null, 2) + "\n", "utf-8");
		fs.renameSync(tmp, SETTINGS_PATH);
	} catch (err) {
		const msg = err instanceof Error ? err.message : String(err);
		console.error(`[remember-model] failed to persist settings: ${msg}`);
	}
}

/** Coalesce rapid events into one write so switching models isn't write-spammy. */
let pendingTimer: ReturnType<typeof setTimeout> | undefined;
let pendingPatch: SettingsShape = {};

function schedulePatch(patch: SettingsShape): void {
	pendingPatch = {
		...pendingPatch,
		...patch,
		...(patch.modelThinkingLevels || pendingPatch.modelThinkingLevels
			? {
					modelThinkingLevels: {
						...(pendingPatch.modelThinkingLevels ?? {}),
						...(patch.modelThinkingLevels ?? {}),
					},
				}
			: {}),
	};
	if (pendingTimer) return;
	pendingTimer = setTimeout(() => {
		pendingTimer = undefined;
		const toWrite = pendingPatch;
		pendingPatch = {};
		patchSettings(toWrite);
	}, 250);
}

export default async function (pi: ExtensionAPI) {
	pi.on("model_select", async (event) => {
		// "restore" = launch-time replay of the saved default; re-saving would
		// be a no-op and just adds write churn. Persist user-driven changes.
		if (event.source === "restore") return;

		const { provider, id } = event.model;
		schedulePatch({ defaultProvider: provider, defaultModel: id });
	});

	pi.on("thinking_level_select", async (event) => {
		const level = event.level;

		// Persist as the global default…
		const patch: SettingsShape = { defaultThinkingLevel: level };

		// …and as a per-model pin when a model is already active, so the level
		// follows the model across sessions.
		const model = pi.getModel?.();
		if (model) {
			const key = `${model.provider}/${model.id}`;
			patch.modelThinkingLevels = { [key]: level };
		}

		schedulePatch(patch);
	});
}
