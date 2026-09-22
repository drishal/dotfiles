import { Type } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import {
	analyzeCompactionRecovery,
	analyzeLatestAssistantStall,
	messageText,
	shouldRecoverStalledAssistantTurn,
	userRequestsSimpleContinuation,
} from "./analysis.ts";
import type { CompactionRecoveryAnalysis } from "./analysis.ts";
import { branchBeforeCompaction, findMostRecentActiveLoop, isOverflowCompaction, latestLeafCompactionId, messageRole } from "./loop-state.ts";
import {
	ASSISTANT_IDLE_DELAY_MS,
	buildWatchdogNudgePrompt,
	MAX_ASSISTANT_IDLE_RECOVERIES_PER_STREAK,
	MESSAGE_TYPE_WATCHDOG_NUDGE,
	RECOVERY_DELAY_MS,
	WATCHDOG_ANSWER_TOOL,
} from "./model.ts";
import type { WatchdogNudgeDetails, WatchdogNudgeRequest } from "./model.ts";
import { appendTrackingLog, loadTrackingConfig, makeTrackingEvent, trackingLogPath, type TrackingEvent, type TrackingSource } from "./tracking.ts";

function registerWatchdogMessageRenderer(pi: ExtensionAPI): void {
	pi.registerMessageRenderer<WatchdogNudgeDetails>(MESSAGE_TYPE_WATCHDOG_NUDGE, (message, _options, theme) => {
		const details = message.details;
		if (!details || details.kind !== "watchdog_nudge") return undefined;

		const target = details.loop ? ` · ${details.loop}${details.iteration ? ` iter ${details.iteration}` : ""}` : "";
		const text = theme.fg("warning", "✦ watchdog nudge ") + theme.fg("muted", `${details.title}${target}`);
		return {
			render: () => [text],
			invalidate: () => {},
		};
	});
}

export function registerCompactionContinue(pi: ExtensionAPI): void {
	let enabled = true;
	let pendingTimer: ReturnType<typeof setTimeout> | undefined;
	let pendingAssistantIdleTimer: ReturnType<typeof setTimeout> | undefined;
	let lastRecoveredCompactionId: string | undefined;
	let lastPreCompactionAnalysis: CompactionRecoveryAnalysis | undefined;
	let assistantIdleRecoveryStreak = 0;
	let hadToolResultSinceLastUser = false;
	let trackingEnabled = false;
	let trackingAppendSessionEntries = true;
	let trackingLogEnabled = true;
	let trackingLoadedPaths: string[] = [];
	let trackingDiagnostics: string[] = [];
	let trackingMaxRecentEvents = 20;
	const recentEvents: TrackingEvent[] = [];

	registerWatchdogMessageRenderer(pi);

	function refreshTrackingConfig(ctx: ExtensionContext): void {
		const loaded = loadTrackingConfig(ctx);
		trackingEnabled = loaded.config.enabled;
		trackingAppendSessionEntries = loaded.config.appendSessionEntries;
		trackingLogEnabled = loaded.config.log;
		trackingLoadedPaths = loaded.paths;
		trackingDiagnostics = loaded.diagnostics;
		trackingMaxRecentEvents = loaded.config.maxRecentEvents;
	}

	function rememberEvent(event: TrackingEvent): void {
		recentEvents.push(event);
		if (recentEvents.length > trackingMaxRecentEvents) recentEvents.splice(0, recentEvents.length - trackingMaxRecentEvents);
		if (trackingLogEnabled) appendTrackingLog(event);
	}

	function recordEvent(customType: string, event: TrackingEvent): void {
		if (!trackingEnabled) return;
		if (trackingAppendSessionEntries) pi.appendEntry(customType, event);
		rememberEvent(event);
	}

	function recordCandidate(
		ctx: ExtensionContext,
		source: TrackingSource,
		data: { recoveryKind?: string; reason: string; loop?: string; iteration?: number; compactionId?: string },
	): void {
		recordEvent(
			"compaction-continue:watchdog-candidate",
			makeTrackingEvent(ctx, {
				kind: "watchdog_candidate",
				source,
				recoveryKind: data.recoveryKind,
				reason: data.reason,
				loop: data.loop,
				iteration: data.iteration,
				compactionId: data.compactionId,
			}),
		);
	}

	function recordSkip(
		ctx: ExtensionContext,
		data: { source: TrackingSource; skipReason: string; recoveryKind?: string; reason: string; loop?: string; iteration?: number; compactionId?: string },
	): void {
		recordEvent(
			"compaction-continue:watchdog-skip",
			makeTrackingEvent(ctx, {
				kind: "watchdog_skip",
				source: data.source,
				skipReason: data.skipReason,
				recoveryKind: data.recoveryKind,
				reason: data.reason,
				loop: data.loop,
				iteration: data.iteration,
				compactionId: data.compactionId,
			}),
		);
	}

	pi.registerTool({
		name: "compaction_continue_state",
		label: "Compaction Continue State",
		description: "Inspect compaction-continue watchdog status and recent passive tracking events.",
		parameters: Type.Object({}),
		async execute(_toolCallId, _params, _signal, _onUpdate, ctx) {
			refreshTrackingConfig(ctx);
			const activeLoop = findMostRecentActiveLoop(ctx);
			const payload = {
				enabled,
				assistantIdleRecoveryStreak,
				lastRecoveredCompactionId,
				activeLoop,
				tracking: {
					enabled: trackingEnabled,
					appendSessionEntries: trackingAppendSessionEntries,
					log: trackingLogEnabled,
					loadedPaths: trackingLoadedPaths,
					diagnostics: trackingDiagnostics,
					maxRecentEvents: trackingMaxRecentEvents,
					logPath: trackingLogPath(),
				},
				recentEvents,
			};
			return { content: [{ type: "text", text: JSON.stringify(payload, null, 2) }], details: payload };
		},
	});

	pi.registerTool({
		name: WATCHDOG_ANSWER_TOOL,
		label: "Watchdog Answer",
		description: "Record whether a watchdog nudge found the previous task already complete. This self-check does not itself continue or stop work.",
		parameters: Type.Object({
			done: Type.Boolean({ description: "True when the prior task or loop is already complete; false when unfinished in-scope work remains." }),
			confidence: Type.Optional(Type.Union([Type.Literal("high"), Type.Literal("medium"), Type.Literal("low")], { description: "Confidence in this watchdog self-check." })),
			note: Type.Optional(Type.String({ description: "Short optional note about why the work is or is not done." })),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			refreshTrackingConfig(ctx);
			const activeLoop = findMostRecentActiveLoop(ctx);
			const payload = makeTrackingEvent(ctx, {
				kind: "watchdog_answer",
				done: params.done === true,
				confidence: typeof params.confidence === "string" ? params.confidence : undefined,
				note: typeof params.note === "string" ? params.note : undefined,
				loop: activeLoop?.name,
				iteration: activeLoop?.iteration,
			}) as Extract<TrackingEvent, { kind: "watchdog_answer" }>;
			recordEvent("compaction-continue:watchdog-answer", payload);
			return { content: [{ type: "text", text: `Recorded watchdog answer: ${payload.done ? "done" : "not done"}.` }], details: payload };
		},
	});

	function updateStatus(ctx: ExtensionContext): void {
		const state = enabled ? ctx.ui.theme.fg("success", "on") : ctx.ui.theme.fg("error", "off");
		ctx.ui.setStatus("compaction-continue", `${ctx.ui.theme.fg("muted", "watchdog:")}${state}`);
	}

	function clearAssistantIdleTimer(): void {
		if (pendingAssistantIdleTimer) clearTimeout(pendingAssistantIdleTimer);
		pendingAssistantIdleTimer = undefined;
	}

	function canSendNudge(ctx: ExtensionContext): boolean {
		return enabled && ctx.isIdle() && !ctx.hasPendingMessages();
	}

	function sendNudge(ctx: ExtensionContext, request: WatchdogNudgeRequest): void {
		recordEvent(
			"compaction-continue:watchdog-nudge",
			makeTrackingEvent(ctx, {
				kind: "watchdog_nudge",
				source: request.details.recoveryKind === "assistant-stall" ? "assistant-stall" : "compaction",
				recoveryKind: request.details.recoveryKind,
				reason: request.details.reason,
				loop: request.details.loop,
				iteration: request.details.iteration,
				compactionId: request.details.compactionId,
			}),
		);
		ctx.ui.notify(request.notification, "info");
		pi.sendMessage(
			{
				customType: MESSAGE_TYPE_WATCHDOG_NUDGE,
				content: request.content,
				display: true,
				details: request.details,
			},
			{ triggerTurn: true },
		);
	}

	function scheduleRecovery(compactionId: string, ctx: ExtensionContext, seedAnalysis?: CompactionRecoveryAnalysis): void {
		if (pendingTimer) clearTimeout(pendingTimer);

		pendingTimer = setTimeout(() => {
			pendingTimer = undefined;

			const activeLoop = findMostRecentActiveLoop(ctx);
			const analysis = analyzeCompactionRecovery(branchBeforeCompaction(ctx, compactionId), {
				hasActiveLoop: Boolean(activeLoop),
				isOverflow: isOverflowCompaction(ctx, compactionId),
			});
			const recovery = analysis.shouldRecover ? analysis : seedAnalysis?.shouldRecover ? seedAnalysis : undefined;
			if (!recovery) return;

			const recoveryKind = recovery.kind ?? "overflow";
			const loop = activeLoop?.name ?? recovery.ralph?.prompt?.loop;
			const iteration = activeLoop?.iteration || recovery.ralph?.prompt?.iteration;
			recordCandidate(ctx, "compaction", { recoveryKind, reason: recovery.reason, loop, iteration, compactionId });
			if (!enabled) {
				recordSkip(ctx, { source: "compaction", skipReason: "disabled", recoveryKind, reason: recovery.reason, loop, iteration, compactionId });
				return;
			}
			if (lastRecoveredCompactionId === compactionId) {
				recordSkip(ctx, { source: "compaction", skipReason: "already-recovered", recoveryKind, reason: recovery.reason, loop, iteration, compactionId });
				return;
			}
			if (!canSendNudge(ctx)) {
				recordSkip(ctx, { source: "compaction", skipReason: "not-idle-or-pending", recoveryKind, reason: recovery.reason, loop, iteration, compactionId });
				return;
			}

			lastRecoveredCompactionId = compactionId;
			const title = recoveryKind === "ralph" ? "Unresolved Ralph loop after compaction" : "Context overflow compaction finished";
			sendNudge(ctx, {
				content: buildWatchdogNudgePrompt(Boolean(loop)),
				details: {
					kind: "watchdog_nudge",
					recoveryKind,
					title,
					reason: recovery.reason,
					loop,
					iteration,
					compactionId,
				},
				entry: {
					compactionId,
					kind: recovery.kind,
					loop,
					iteration,
					reason: recovery.reason,
					timestamp: new Date().toISOString(),
				},
				notification:
					recoveryKind === "ralph"
						? "Compaction left an unresolved Ralph loop idle; sending watchdog nudge."
						: "Context overflow compaction finished; sending watchdog nudge.",
			});
		}, RECOVERY_DELAY_MS);
	}

	function scheduleAssistantIdleRecovery(ctx: ExtensionContext, reason: string): void {
		clearAssistantIdleTimer();
		pendingAssistantIdleTimer = setTimeout(() => {
			pendingAssistantIdleTimer = undefined;
			const activeLoop = findMostRecentActiveLoop(ctx);
			const loop = activeLoop?.name;
			const iteration = activeLoop?.iteration;
			recordCandidate(ctx, "assistant-stall", { recoveryKind: "assistant-stall", reason, loop, iteration });
			if (!enabled) {
				recordSkip(ctx, { source: "assistant-stall", skipReason: "disabled", recoveryKind: "assistant-stall", reason, loop, iteration });
				return;
			}
			if (!canSendNudge(ctx)) {
				recordSkip(ctx, { source: "assistant-stall", skipReason: "not-idle-or-pending", recoveryKind: "assistant-stall", reason, loop, iteration });
				return;
			}
			if (assistantIdleRecoveryStreak <= 0 || assistantIdleRecoveryStreak > MAX_ASSISTANT_IDLE_RECOVERIES_PER_STREAK) {
				recordSkip(ctx, { source: "assistant-stall", skipReason: "streak-cap", recoveryKind: "assistant-stall", reason, loop, iteration });
				return;
			}

			sendNudge(ctx, {
				content: buildWatchdogNudgePrompt(Boolean(loop)),
				details: {
					kind: "watchdog_nudge",
					recoveryKind: "assistant-stall",
					title: "Assistant turn appears stalled",
					reason,
					loop,
					iteration,
				},
				entry: {
					kind: "assistant-stall",
					loop,
					iteration,
					reason,
					streak: assistantIdleRecoveryStreak,
					timestamp: new Date().toISOString(),
				},
				notification: "Assistant turn appears stalled after promising to continue; sending watchdog nudge.",
			});
		}, ASSISTANT_IDLE_DELAY_MS);
	}

	function reportStatus(args: string, ctx: ExtensionContext): void {
		const value = args.trim().toLowerCase();
		if (value === "on" || value === "enable") enabled = true;
		else if (value === "off" || value === "disable") enabled = false;

		refreshTrackingConfig(ctx);
		updateStatus(ctx);
		const activeLoop = findMostRecentActiveLoop(ctx);
		ctx.ui.notify(
			`Compaction continue: ${enabled ? "enabled" : "disabled"}${
				activeLoop ? `\nActive loop: ${activeLoop.name} (iteration ${activeLoop.iteration})` : "\nNo active loop detected"
			}\nAssistant stall watch: ${enabled ? "armed" : "disabled"}${assistantIdleRecoveryStreak > 0 ? `\nCurrent stall streak: ${assistantIdleRecoveryStreak}` : ""}\nPassive tracking: ${trackingEnabled ? "enabled" : "disabled"}${trackingLoadedPaths.length > 0 ? `\nTracking config: ${trackingLoadedPaths.join(", ")}` : ""}`,
			"info",
		);
	}

	pi.registerCommand("compaction-continue", {
		description: "Toggle/status for watchdog nudges after idle compactions and stalled continuation turns",
		handler: async (args, ctx) => reportStatus(args, ctx),
	});

	pi.registerCommand("ralph-compact-watchdog", {
		description: "Deprecated alias for /compaction-continue",
		handler: async (args, ctx) => reportStatus(args, ctx),
	});

	pi.on("session_before_compact", async (event, ctx) => {
		lastPreCompactionAnalysis = analyzeCompactionRecovery(event.branchEntries, {
			hasActiveLoop: Boolean(findMostRecentActiveLoop(ctx)),
			isOverflow: false,
		});
	});

	pi.on("session_compact", async (event, ctx) => {
		if (!enabled) return;
		const activeLoop = findMostRecentActiveLoop(ctx);
		const analysis = analyzeCompactionRecovery(branchBeforeCompaction(ctx, event.compactionEntry.id), {
			hasActiveLoop: Boolean(activeLoop),
			isOverflow: isOverflowCompaction(ctx, event.compactionEntry.id),
		});
		if (!analysis.shouldRecover && !lastPreCompactionAnalysis?.shouldRecover) return;
		scheduleRecovery(event.compactionEntry.id, ctx, lastPreCompactionAnalysis);
	});

	pi.on("message_end", async (event) => {
		if (messageRole(event.message) !== "user") return;
		hadToolResultSinceLastUser = false;
		if (!userRequestsSimpleContinuation(messageText(event.message))) {
			assistantIdleRecoveryStreak = 0;
			clearAssistantIdleTimer();
		}
	});

	pi.on("tool_result", async (_event) => {
		hadToolResultSinceLastUser = true;
		assistantIdleRecoveryStreak = 0;
		clearAssistantIdleTimer();
	});

	pi.on("turn_end", async (event, ctx) => {
		if (messageRole(event.message) !== "assistant") return;
		if (!shouldRecoverStalledAssistantTurn(event.message, { hadToolResultSincePreviousUser: hadToolResultSinceLastUser })) {
			assistantIdleRecoveryStreak = 0;
			clearAssistantIdleTimer();
			return;
		}
		assistantIdleRecoveryStreak += 1;
		scheduleAssistantIdleRecovery(ctx, "assistant-promised-continuation");
	});

	pi.on("session_start", async (_event, ctx) => {
		refreshTrackingConfig(ctx);
		updateStatus(ctx);
		recentEvents.length = 0;
		hadToolResultSinceLastUser = false;

		const compactionId = latestLeafCompactionId(ctx);
		if (enabled && compactionId) {
			const analysis = analyzeCompactionRecovery(branchBeforeCompaction(ctx, compactionId), {
				hasActiveLoop: Boolean(findMostRecentActiveLoop(ctx)),
				isOverflow: isOverflowCompaction(ctx, compactionId),
			});
			if (analysis.shouldRecover) scheduleRecovery(compactionId, ctx, analysis);
		}

		const stallAnalysis = analyzeLatestAssistantStall(ctx.sessionManager.getBranch());
		if (enabled && stallAnalysis.shouldRecover) {
			assistantIdleRecoveryStreak = Math.max(assistantIdleRecoveryStreak, stallAnalysis.streak);
			scheduleAssistantIdleRecovery(ctx, stallAnalysis.reason ?? "assistant-promised-continuation");
		}
	});

	pi.on("session_shutdown", async () => {
		if (pendingTimer) clearTimeout(pendingTimer);
		pendingTimer = undefined;
		clearAssistantIdleTimer();
	});
}
