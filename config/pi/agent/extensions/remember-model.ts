/**
 * remember-model — persist the last user-selected model + thinking level to a
 * machine-local state file (model-state.json) and re-apply it on startup.
 *
 * Why not settings.json: settings.json is synced to dotfiles. Model picks
 * change constantly and must not produce dotfile commits. This extension
 * moves that churn into ~/.pi/agent/model-state.json (never synced) and
 * re-applies the saved pick on every non-resume session start.
 *
 * - `model_select` source "set" | "cycle"  → persist provider+model
 *   (source "restore" is a launch-time replay; skipped to avoid churn)
 * - `thinking_level_select`                → persist level + per-model pin
 *   (the pin is re-applied whenever that model is selected again)
 * - `session_start` startup|new|reload     → re-apply the saved pick
 *   ("resume"/"fork" are skipped: the session's own model history replays
 *   itself and should win over the last global pick)
 *
 * settings.json holds no model keys at all. Pi applies its built-in default
 * for the first moments after boot; this extension switches to the
 * remembered pick right after.
 *
 * Caveat: pi's own Ctrl+S inside the /model or /thinking picker still writes
 * defaultModel/defaultThinkingLevel back into settings.json. Prefer Enter to
 * confirm a pick. If those keys ever reappear in settings.json, delete them
 * once — this extension does not fight pi's settings manager.
 *
 * No state of its own; reads/writes ~/.pi/agent/model-state.json only.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";

const AGENT_DIR = process.env.PI_CODING_AGENT_DIR ?? `${process.env.HOME}/.pi/agent`;
const STATE_PATH = path.join(AGENT_DIR, "model-state.json");

type ThinkingLevelParam = Parameters<ExtensionAPI["setThinkingLevel"]>[0];

interface ModelState {
	provider?: string;
	model?: string;
	/** Global fallback thinking level. */
	thinkingLevel?: ThinkingLevelParam;
	/** Per-model thinking pins, keyed "provider/modelId". */
	modelThinkingLevels?: Record<string, ThinkingLevelParam>;
}

function readState(): ModelState {
	try {
		if (!fs.existsSync(STATE_PATH)) return {};
		return JSON.parse(fs.readFileSync(STATE_PATH, "utf-8")) as ModelState;
	} catch (err) {
		const msg = err instanceof Error ? err.message : String(err);
		console.error(`[remember-model] failed to read model-state.json: ${msg}`);
		return {};
	}
}

/**
 * Merge-patch model-state.json with an atomic temp-file + rename so a crash
 * mid-write cannot leave a truncated file.
 */
function patchState(patch: ModelState): void {
	try {
		const current = readState();
		const next: ModelState = { ...current, ...patch };

		// Deep-merge modelThinkingLevels so a per-model pin does not wipe
		// pins for other models.
		if (patch.modelThinkingLevels || current.modelThinkingLevels) {
			next.modelThinkingLevels = {
				...current.modelThinkingLevels,
				...patch.modelThinkingLevels,
			};
		}

		const tmp = `${STATE_PATH}.tmp`;
		fs.writeFileSync(tmp, JSON.stringify(next, null, 2) + "\n", "utf-8");
		fs.renameSync(tmp, STATE_PATH);
	} catch (err) {
		const msg = err instanceof Error ? err.message : String(err);
		console.error(`[remember-model] failed to persist model-state.json: ${msg}`);
	}
}

/** Coalesce rapid events into one write so switching models isn't write-spammy. */
let pendingTimer: ReturnType<typeof setTimeout> | undefined;
let pendingPatch: ModelState = {};

function schedulePatch(patch: ModelState): void {
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
		patchState(toWrite);
	}, 250);
}

/** True while session_start is re-applying the saved pick, so the events our
 * own setModel/setThinkingLevel calls trigger don't get re-persisted. */
let restoring = false;

export default async function (pi: ExtensionAPI) {
	pi.on("session_start", async (event, ctx) => {
		// resume/fork: the session replays its own model changes; leave them be.
		if (event.reason === "resume" || event.reason === "fork") return;

		const state = readState();
		if (!state.provider || !state.model) return;

		const target = ctx.modelRegistry.find(state.provider, state.model);
		if (!target) {
			console.error(
				`[remember-model] saved model ${state.provider}/${state.model} not found; keeping pi's default`,
			);
			return;
		}

		restoring = true;
		try {
			const ok = await pi.setModel(target);
			if (!ok) {
				console.error(
					`[remember-model] could not restore ${state.provider}/${state.model} (auth not configured?)`,
				);
				return;
			}

			// Per-model pin wins over the global remembered level.
			const key = `${state.provider}/${state.model}`;
			const level = state.modelThinkingLevels?.[key] ?? state.thinkingLevel;
			if (level) pi.setThinkingLevel(level);
		} finally {
			restoring = false;
		}
	});

	pi.on("model_select", async (event) => {
		if (restoring) return;
		// "restore" = launch-time replay; re-saving would be a no-op plus churn.
		if (event.source === "restore") return;

		const { provider, id } = event.model;
		schedulePatch({ provider, model: id });

		// Apply this model's pinned thinking level on switch, so the level
		// follows the model mid-session too, not only after a restart.
		// Include the not-yet-flushed debounced patch, not just what's on disk.
		const pins = { ...readState().modelThinkingLevels, ...pendingPatch.modelThinkingLevels };
		const pin = pins[`${provider}/${id}`];
		if (pin && pin !== pi.getThinkingLevel()) {
			restoring = true;
			try {
				pi.setThinkingLevel(pin);
			} finally {
				restoring = false;
			}
		}
	});

	pi.on("thinking_level_select", async (event, ctx) => {
		if (restoring) return;
		const level = event.level;

		// Persist as the global default…
		const patch: ModelState = { thinkingLevel: level };

		// …and as a per-model pin when a model is already active, so the level
		// follows the model across sessions.
		const model = ctx.model;
		if (model) {
			const key = `${model.provider}/${model.id}`;
			patch.modelThinkingLevels = { [key]: level };
		}

		schedulePatch(patch);
	});
}
